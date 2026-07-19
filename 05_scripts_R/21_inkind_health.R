# 21_inkind_health.R
# Répartit les dépenses publiques de santé sans utiliser la déclaration
# d'assurance maladie. Le calcul central combine le recours ambulatoire moyen de
# personnes comparables et les hospitalisations publiques observées.

inkind_health <- function(paths) {
  message(">>> ETAPE 22 : Services publics de santé")
  fiscal_path <- file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  params_path <- file.path(paths$ROOT, "01_data_sources", "params_health_2021.xlsx")
  assert_local_file_exists(fiscal_path); assert_local_file_exists(params_path)
  fiscal <- load_parquet(fiscal_path)
  budget_tab <- readxl::read_excel(params_path, sheet = "budget")
  method <- readxl::read_excel(params_path, sheet = "methode")

  get_budget <- function(name) {
    x <- budget_tab$valeur[budget_tab$parametre == name]
    if (length(x) != 1L || !is.finite(as.numeric(x))) stop("Budget absent : ", name)
    as.numeric(x)
  }
  get_method <- function(name) {
    x <- method$valeur[method$parametre == name]
    if (length(x) != 1L || !is.finite(as.numeric(x))) stop("Paramètre absent : ", name)
    as.numeric(x)
  }
  make_hhid <- function(grappe, menage) as.numeric(grappe) * 100 + as.numeric(menage)
  annual_out <- get_method("annualisation_consultation_30_jours")
  annual_fees <- get_method("annualisation_depenses_3_mois")
  min_cell <- get_method("taille_cellule_min")
  budget_central <- get_budget("budget_soins_intrants_central")
  budget_large <- get_budget("budget_programme_sante_total")
  ratio_central <- get_method("poids_hospitalisation_central")
  ratio_low <- get_method("poids_hospitalisation_bas")
  ratio_high <- get_method("poids_hospitalisation_haut")

  ind <- load_raw_dta("ehcvm_individu_CIV2021.dta",
    col_select = c("hhid", "grappe", "menage", "numind", "sexe", "age")) |>
    dplyr::transmute(hhid = as.numeric(hhid), grappe = as.numeric(grappe),
      menage = as.numeric(menage), numind = as.numeric(numind),
      sexe = as.integer(sexe), age = as.numeric(age))
  s03_path <- source_file_path("Datain", "Menage", "s03_me_CIV2021.dta",
                              label = "Module santé S03")
  health <- haven::read_dta(s03_path, col_select = c(
    "grappe", "menage", "individu", "s03q01", "s03q05", "s03q07", "s03q12",
    "s03q13", "s03q14", "s03q15", "s03q17", "s03q18a", "s03q18b", "s03q18c",
    "s03q19", "s03q20", "s03q23", "s03q24"
  )) |>
    dplyr::transmute(
      hhid = make_hhid(grappe, menage), grappe = as.numeric(grappe),
      menage = as.numeric(menage), numind = as.numeric(individu),
      malade_30j = as.integer(s03q01) == 1L,
      consultation_30j = as.integer(s03q05) == 1L,
      prestataire_30j = as.integer(s03q07),
      soins_3m = as.integer(s03q12) == 1L,
      dep13 = pmax(dplyr::coalesce(as.numeric(s03q13), 0), 0),
      dep14 = pmax(dplyr::coalesce(as.numeric(s03q14), 0), 0),
      dep15 = pmax(dplyr::coalesce(as.numeric(s03q15), 0), 0),
      dep17 = pmax(dplyr::coalesce(as.numeric(s03q17), 0), 0),
      dep18a = pmax(dplyr::coalesce(as.numeric(s03q18a), 0), 0),
      dep18b = pmax(dplyr::coalesce(as.numeric(s03q18b), 0), 0),
      dep18c = pmax(dplyr::coalesce(as.numeric(s03q18c), 0), 0),
      hospitalise_12m = as.integer(s03q19) == 1L,
      nombre_hospitalisations = pmax(dplyr::coalesce(as.numeric(s03q20), 0), 0),
      prestataire_hopital = as.integer(s03q23),
      frais_hopital = pmax(dplyr::coalesce(as.numeric(s03q24), 0), 0)
    ) |>
    dplyr::left_join(ind, by = c("hhid", "grappe", "menage", "numind")) |>
    dplyr::left_join(fiscal |> dplyr::select(hhid, hhweight, def_spa, milieu,
      region, decile, yd_pc), by = "hhid") |>
    dplyr::mutate(
      public_outpatient = dplyr::coalesce(malade_30j, FALSE) &
        dplyr::coalesce(consultation_30j, FALSE) & prestataire_30j %in% 1:6,
      public_hospital = dplyr::coalesce(hospitalise_12m, FALSE) &
        nombre_hospitalisations > 0 & prestataire_hopital %in% 1:6,
      public_hospital_stays = dplyr::if_else(public_hospital,
        nombre_hospitalisations, 0),
      observed_public_contacts = as.numeric(public_outpatient) * annual_out,
      outpatient_fees = dplyr::if_else(public_outpatient,
        (dep13 + dep14 + dep15 + dep17 + dep18a + dep18b + dep18c) * annual_fees, 0),
      hospital_fees = dplyr::if_else(public_hospital, frais_hopital, 0),
      age_group = cut(age, breaks = c(-Inf, 4, 14, 24, 44, 64, Inf),
        labels = c("0-4", "5-14", "15-24", "25-44", "45-64", "65+"),
        right = TRUE)
    )
  if (any(is.na(health$hhweight)) || any(is.na(health$age_group))) {
    stop("Certaines personnes ne retrouvent pas leurs caractéristiques ou leur ménage.")
  }

  national_cells <- health |>
    dplyr::group_by(age_group, sexe) |>
    dplyr::summarise(taux_national = stats::weighted.mean(public_outpatient, hhweight),
                     .groups = "drop")
  cells <- health |>
    dplyr::group_by(age_group, sexe, milieu) |>
    dplyr::summarise(
      observations = dplyr::n(), population = sum(hhweight),
      taux_cellule = stats::weighted.mean(public_outpatient, hhweight),
      .groups = "drop") |>
    dplyr::left_join(national_cells, by = c("age_group", "sexe")) |>
    dplyr::mutate(
      taux_retenu = dplyr::if_else(observations >= min_cell, taux_cellule, taux_national),
      source_taux = dplyr::if_else(observations >= min_cell,
                                  "âge-sexe-milieu", "repli âge-sexe national"))

  health <- health |>
    dplyr::left_join(cells |> dplyr::select(age_group, sexe, milieu, taux_retenu,
      source_taux), by = c("age_group", "sexe", "milieu")) |>
    dplyr::mutate(expected_public_contacts = taux_retenu * annual_out)
  if (any(!is.finite(health$expected_public_contacts))) stop("Fréquence de recours non finie.")

  allocate <- function(budget, hospital_ratio, outpatient_contacts) {
    resources <- outpatient_contacts + health$public_hospital_stays * hospital_ratio
    denom <- sum(resources * health$hhweight)
    if (!is.finite(denom) || denom <= 0) stop("Aucune unité de soins à valoriser.")
    unit <- budget / denom
    list(unit = unit,
      outpatient = outpatient_contacts * unit,
      hospital = health$public_hospital_stays * hospital_ratio * unit)
  }
  central <- allocate(budget_central, ratio_central, health$expected_public_contacts)
  pure_use <- allocate(budget_central, ratio_central, health$observed_public_contacts)
  wide_budget <- allocate(budget_large, ratio_central, health$expected_public_contacts)
  low_ratio <- allocate(budget_central, ratio_low, health$expected_public_contacts)
  high_ratio <- allocate(budget_central, ratio_high, health$expected_public_contacts)

  health <- health |>
    dplyr::mutate(
      health_outpatient_gross = central$outpatient,
      health_hospital_gross = central$hospital,
      health_gross = health_outpatient_gross + health_hospital_gross,
      health_fees = outpatient_fees + hospital_fees,
      health_net = pmax(health_gross - health_fees, 0),
      health_net_use = pmax(pure_use$outpatient + pure_use$hospital - health_fees, 0),
      health_net_wide_budget = pmax(wide_budget$outpatient + wide_budget$hospital - health_fees, 0),
      health_net_low_ratio = pmax(low_ratio$outpatient + low_ratio$hospital - health_fees, 0),
      health_net_high_ratio = pmax(high_ratio$outpatient + high_ratio$hospital - health_fees, 0)
    )

  hh_benefit <- health |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      health_expected_users = sum(expected_public_contacts > 0),
      health_observed_outpatient = sum(public_outpatient),
      health_public_hospital_stays = sum(public_hospital_stays),
      health_outpatient_gross_hh = sum(health_outpatient_gross),
      health_hospital_gross_hh = sum(health_hospital_gross),
      health_gross_hh = sum(health_gross), health_fees_hh = sum(health_fees),
      health_net_hh = sum(health_net), health_net_use_hh = sum(health_net_use),
      health_net_wide_budget_hh = sum(health_net_wide_budget),
      health_net_low_ratio_hh = sum(health_net_low_ratio),
      health_net_high_ratio_hh = sum(health_net_high_ratio), .groups = "drop")

  hh <- fiscal |>
    dplyr::select(hhid, grappe, strata, hhweight, pcweight, decile, quintile,
      milieu, region, hhsize, def_spa, yd_pc, yd_hh, zref) |>
    dplyr::left_join(hh_benefit, by = "hhid") |>
    dplyr::mutate(
      dplyr::across(dplyr::starts_with("health_"), ~ dplyr::coalesce(as.numeric(.x), 0)),
      dplyr::across(c(health_outpatient_gross_hh, health_hospital_gross_hh,
        health_gross_hh, health_fees_hh, health_net_hh, health_net_use_hh,
        health_net_wide_budget_hh, health_net_low_ratio_hh, health_net_high_ratio_hh),
        ~ .x * def_spa, .names = "{.col}_real"),
      health_net_pc_real = health_net_hh_real / hhsize,
      health_gross_pc_real = health_gross_hh_real / hhsize)
  if (nrow(hh) != nrow(fiscal) || anyDuplicated(hh$hhid)) stop("Jointure santé non bijective.")

  gross_mass <- sum(health$health_gross * health$hhweight)
  if (abs(gross_mass - budget_central) > 2) stop("Le budget de santé n'est pas entièrement réparti.")
  save_parquet(hh, file.path(paths$SILVER, "21", "inkind_health.parquet"))

  utilization <- cells |>
    dplyr::arrange(age_group, sexe, milieu)
  incidence <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      population = sum(pcweight), recours_public_observe = sum(health_observed_outpatient * hhweight),
      hospitalisations_publiques = sum(health_public_hospital_stays * hhweight),
      montant_brut_milliards = sum(health_gross_hh * hhweight) / 1e9,
      paiements_menages_milliards = sum(health_fees_hh * hhweight) / 1e9,
      benefice_net_milliards = sum(health_net_hh * hhweight) / 1e9,
      benefice_net_moyen_personne = stats::weighted.mean(health_net_pc_real, pcweight),
      .groups = "drop") |>
    dplyr::mutate(part_benefice_net_pct = 100 * benefice_net_milliards / sum(benefice_net_milliards))
  reconciliation <- tibble::tibble(
    scenario = c("Central", "Usage ambulatoire observé", "Budget large",
                 "Hospitalisation poids 5", "Hospitalisation poids 20"),
    budget_reparti_milliards = c(budget_central, budget_central, budget_large,
                                 budget_central, budget_central) / 1e9,
    cout_unite_fcfa = c(central$unit, pure_use$unit, wide_budget$unit,
                        low_ratio$unit, high_ratio$unit),
    poids_hospitalisation = c(ratio_central, ratio_central, ratio_central,
                              ratio_low, ratio_high),
    methode_ambulatoire = c("recours moyen âge-sexe-milieu", "recours observé",
      "recours moyen âge-sexe-milieu", "recours moyen âge-sexe-milieu",
      "recours moyen âge-sexe-milieu"))
  robustness <- tibble::tibble(
    scenario = reconciliation$scenario,
    masse_nette_milliards = c(
      sum(hh$health_net_hh * hh$hhweight), sum(hh$health_net_use_hh * hh$hhweight),
      sum(hh$health_net_wide_budget_hh * hh$hhweight),
      sum(hh$health_net_low_ratio_hh * hh$hhweight),
      sum(hh$health_net_high_ratio_hh * hh$hhweight)) / 1e9,
    gini_apres = c(
      weighted_gini(hh$yd_pc + hh$health_net_hh_real / hh$hhsize, hh$pcweight),
      weighted_gini(hh$yd_pc + hh$health_net_use_hh_real / hh$hhsize, hh$pcweight),
      weighted_gini(hh$yd_pc + hh$health_net_wide_budget_hh_real / hh$hhsize, hh$pcweight),
      weighted_gini(hh$yd_pc + hh$health_net_low_ratio_hh_real / hh$hhsize, hh$pcweight),
      weighted_gini(hh$yd_pc + hh$health_net_high_ratio_hh_real / hh$hhsize, hh$pcweight)))
  point <- weighted_conindex(hh$health_net_pc_real, hh$yd_pc, hh$pcweight)
  boot <- bootstrap_survey_statistic(hh, function(d) weighted_conindex(
    d$health_net_pc_real, d$yd_pc, d$pcweight), "pcweight", "grappe", "strata",
    reps = as.integer(get_method("bootstrap_reps")), seed = as.integer(get_method("bootstrap_seed")))
  concentration <- tibble::tibble(
    indicateur = "Coefficient de concentration du bénéfice net de santé",
    estimation = point, ic95_bas = boot$lo, ic95_haut = boot$hi,
    repetitions_valides = boot$reps_ok, methode = boot$method)

  export_excel(utilization, file.path(paths$TABLES, "21", "21_01_utilization_cells.xlsx"))
  export_excel(incidence, file.path(paths$TABLES, "21", "21_02_incidence_by_decile.xlsx"))
  export_excel(reconciliation, file.path(paths$TABLES, "21", "21_03_budget_reconciliation.xlsx"))
  export_excel(robustness, file.path(paths$TABLES, "21", "21_04_robustness.xlsx"))
  export_excel(concentration, file.path(paths$TABLES, "21", "21_05_concentration.xlsx"))

  fig_data <- incidence |>
    dplyr::select(decile, montant_brut_milliards, paiements_menages_milliards,
                  benefice_net_milliards) |>
    tidyr::pivot_longer(-decile, names_to = "mesure", values_to = "milliards") |>
    dplyr::mutate(mesure = dplyr::recode(mesure,
      montant_brut_milliards = "Dépense publique attribuée",
      paiements_menages_milliards = "Paiements directs des ménages",
      benefice_net_milliards = "Bénéfice net"))
  fig <- ggplot2::ggplot(fig_data, ggplot2::aes(factor(decile), milliards, fill = mesure)) +
    ggplot2::geom_col(position = "dodge", width = 0.78) +
    ggplot2::scale_fill_manual(values = c(
      "Dépense publique attribuée" = "#1F77B4",
      "Paiements directs des ménages" = "#FF7F0E",
      "Bénéfice net" = "#2CA02C")) +
    ggplot2::labs(title = "Services publics de santé par décile",
      subtitle = "Aucune déclaration d'assurance maladie n'entre dans le calcul",
      x = "Décile de niveau de vie", y = "Milliards de FCFA", fill = NULL) +
    ggplot2::theme_minimal(base_size = 11) + ggplot2::theme(legend.position = "bottom")
  export_fig(fig, file.path(paths$FIGS, "fig21_health_decile.png"), width = 10, height = 6)

  message(sprintf("  Dépense brute attribuée : %.2f milliards; bénéfice net : %.2f milliards",
    gross_mass / 1e9, sum(hh$health_net_hh * hh$hhweight) / 1e9))
  invisible(hh)
}