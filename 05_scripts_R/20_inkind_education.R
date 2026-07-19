# 20_inkind_education.R
# Attribue les dépenses publiques d'éducation aux élèves des établissements
# publics observés dans l'EHCVM. Les budgets sont répartis en coût moyen par
# niveau; les paiements directs des familles sont ensuite retranchés.

inkind_education <- function(paths) {
  message(">>> ETAPE 21 : Services publics d'éducation")

  fiscal_path <- file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  params_path <- file.path(paths$ROOT, "01_data_sources", "params_education_2021.xlsx")
  assert_local_file_exists(fiscal_path)
  assert_local_file_exists(params_path)
  fiscal <- load_parquet(fiscal_path)
  budgets <- readxl::read_excel(params_path, sheet = "budgets")
  method <- readxl::read_excel(params_path, sheet = "methode")

  assert_required_columns(fiscal, c("hhid", "grappe", "strata", "hhweight",
    "pcweight", "decile", "quintile", "milieu", "region", "hhsize",
    "def_spa", "yd_pc", "yd_hh", "zref"), "fiscal")
  assert_required_columns(budgets, c("groupe", "budget_central_fcfa",
    "budget_courant_fcfa", "source", "pages"), "paramètres éducation")

  get_method <- function(name) {
    x <- method$valeur[method$parametre == name]
    if (length(x) != 1L || !is.finite(as.numeric(x))) stop("Paramètre absent : ", name)
    as.numeric(x)
  }
  make_hhid <- function(grappe, menage) as.numeric(grappe) * 100 + as.numeric(menage)
  s02_path <- source_file_path("Datain", "Menage", "s02_me_CIV2021.dta",
                              label = "Module éducation S02")
  s02 <- haven::read_dta(s02_path, col_select = c(
    "grappe", "menage", "individu", "s02q12", "s02q14", "s02q19",
    "s02q20", "s02q21", "s02q22", "s02q23", "s02q24", "s02q25",
    "s02q26", "s02q27"
  )) |>
    dplyr::transmute(
      hhid = make_hhid(grappe, menage), numind = as.numeric(individu),
      frequente = as.integer(s02q12) == 1L,
      niveau = as.integer(s02q14), public = as.integer(s02q19) == 1L,
      frais_inscription = pmax(dplyr::coalesce(as.numeric(s02q20), 0), 0),
      contribution_scolaire = pmax(dplyr::coalesce(as.numeric(s02q21), 0), 0),
      dep22 = pmax(dplyr::coalesce(as.numeric(s02q22), 0), 0),
      dep23 = pmax(dplyr::coalesce(as.numeric(s02q23), 0), 0),
      dep24 = pmax(dplyr::coalesce(as.numeric(s02q24), 0), 0),
      dep25 = pmax(dplyr::coalesce(as.numeric(s02q25), 0), 0),
      dep26 = pmax(dplyr::coalesce(as.numeric(s02q26), 0), 0),
      dep27 = pmax(dplyr::coalesce(as.numeric(s02q27), 0), 0)
    ) |>
    dplyr::mutate(
      groupe = dplyr::case_when(
        niveau %in% c(1L, 2L) ~ "prescolaire_primaire",
        niveau %in% c(3L, 5L) ~ "secondaire_general",
        niveau %in% c(4L, 6L) ~ "secondaire_technique",
        niveau == 7L ~ "postsecondaire_professionnel",
        niveau == 8L ~ "superieur",
        TRUE ~ NA_character_
      ),
      utilisateur_public = dplyr::coalesce(frequente, FALSE) &
        dplyr::coalesce(public, FALSE) & !is.na(groupe),
      frais_centraux = frais_inscription + contribution_scolaire,
      frais_larges = frais_centraux + dep22 + dep23 + dep24 + dep25 + dep26 + dep27
    ) |>
    dplyr::left_join(fiscal |> dplyr::select(hhid, hhweight, def_spa), by = "hhid")

  if (any(is.na(s02$hhweight))) stop("Des élèves ne retrouvent pas leur ménage fiscal.")
  users <- s02 |>
    dplyr::filter(utilisateur_public) |>
    dplyr::group_by(groupe) |>
    dplyr::summarise(
      eleves_enquete = dplyr::n(),
      eleves_ponderes = sum(hhweight, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::right_join(budgets, by = "groupe") |>
    dplyr::mutate(
      eleves_enquete = dplyr::coalesce(eleves_enquete, 0L),
      eleves_ponderes = dplyr::coalesce(eleves_ponderes, 0),
      cout_unitaire_central = as.numeric(budget_central_fcfa) / eleves_ponderes,
      cout_unitaire_courant = as.numeric(budget_courant_fcfa) / eleves_ponderes
    )
  if (any(!is.finite(users$cout_unitaire_central)) || any(users$eleves_ponderes <= 0)) {
    stop("Au moins un niveau budgétaire n'a aucun élève public observé.")
  }

  persons <- s02 |>
    dplyr::left_join(users |> dplyr::select(groupe, cout_unitaire_central,
      cout_unitaire_courant), by = "groupe") |>
    dplyr::mutate(
      education_gross = dplyr::if_else(utilisateur_public,
        cout_unitaire_central, 0, missing = 0),
      education_gross_current = dplyr::if_else(utilisateur_public,
        cout_unitaire_courant, 0, missing = 0),
      education_fees = dplyr::if_else(utilisateur_public, frais_centraux, 0),
      education_fees_all = dplyr::if_else(utilisateur_public, frais_larges, 0),
      education_net = pmax(education_gross - education_fees, 0),
      education_net_current = pmax(education_gross_current - education_fees, 0),
      education_net_all_fees = pmax(education_gross - education_fees_all, 0)
    )

  hh_benefit <- persons |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      education_users = sum(utilisateur_public, na.rm = TRUE),
      education_gross_hh = sum(education_gross, na.rm = TRUE),
      education_fees_hh = sum(education_fees, na.rm = TRUE),
      education_fees_all_hh = sum(education_fees_all, na.rm = TRUE),
      education_net_hh = sum(education_net, na.rm = TRUE),
      education_net_current_hh = sum(education_net_current, na.rm = TRUE),
      education_net_all_fees_hh = sum(education_net_all_fees, na.rm = TRUE),
      .groups = "drop"
    )

  hh <- fiscal |>
    dplyr::select(hhid, grappe, strata, hhweight, pcweight, decile, quintile,
      milieu, region, hhsize, def_spa, yd_pc, yd_hh, zref) |>
    dplyr::left_join(hh_benefit, by = "hhid") |>
    dplyr::mutate(
      dplyr::across(dplyr::starts_with("education_"),
                    ~ dplyr::coalesce(as.numeric(.x), 0)),
      dplyr::across(c(education_gross_hh, education_fees_hh,
        education_fees_all_hh, education_net_hh, education_net_current_hh,
        education_net_all_fees_hh), ~ .x * def_spa, .names = "{.col}_real"),
      education_net_pc_real = education_net_hh_real / hhsize,
      education_gross_pc_real = education_gross_hh_real / hhsize
    )
  if (nrow(hh) != nrow(fiscal) || anyDuplicated(hh$hhid)) stop("Jointure éducation non bijective.")

  allocated <- persons |>
    dplyr::filter(utilisateur_public) |>
    dplyr::group_by(groupe) |>
    dplyr::summarise(
      montant_attribue = sum(education_gross * hhweight),
      frais_directs = sum(education_fees * hhweight),
      benefice_net = sum(education_net * hhweight), .groups = "drop"
    ) |>
    dplyr::right_join(users, by = "groupe") |>
    dplyr::mutate(ecart_budget = montant_attribue - as.numeric(budget_central_fcfa))
  if (any(abs(allocated$ecart_budget) > 2)) stop("Le budget d'éducation n'est pas entièrement réparti.")

  save_parquet(hh, file.path(paths$SILVER, "20", "inkind_education.parquet"))

  incidence <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      population = sum(pcweight), menages_utilisateurs = sum(hhweight * (education_users > 0)),
      montant_brut_milliards = sum(education_gross_hh * hhweight) / 1e9,
      paiements_menages_milliards = sum(education_fees_hh * hhweight) / 1e9,
      benefice_net_milliards = sum(education_net_hh * hhweight) / 1e9,
      benefice_net_moyen_personne = stats::weighted.mean(education_net_pc_real, pcweight),
      .groups = "drop"
    ) |>
    dplyr::mutate(part_benefice_net_pct = 100 * benefice_net_milliards / sum(benefice_net_milliards))

  point <- weighted_conindex(hh$education_net_pc_real, hh$yd_pc, hh$pcweight)
  boot <- bootstrap_survey_statistic(hh, function(d) weighted_conindex(
    d$education_net_pc_real, d$yd_pc, d$pcweight), "pcweight", "grappe", "strata",
    reps = as.integer(get_method("bootstrap_reps")), seed = as.integer(get_method("bootstrap_seed")))
  concentration <- tibble::tibble(
    indicateur = "Coefficient de concentration du bénéfice net d'éducation",
    estimation = point, ic95_bas = boot$lo, ic95_haut = boot$hi,
    repetitions_valides = boot$reps_ok, methode = boot$method
  )
  robustness <- tibble::tibble(
    scenario = c("Budget exécuté total, paiements directs", "Dépenses courantes, paiements directs",
                 "Budget exécuté total, toutes dépenses scolaires"),
    masse_nette_milliards = c(
      sum(hh$education_net_hh * hh$hhweight) / 1e9,
      sum(hh$education_net_current_hh * hh$hhweight) / 1e9,
      sum(hh$education_net_all_fees_hh * hh$hhweight) / 1e9),
    gini_apres = c(
      weighted_gini(hh$yd_pc + hh$education_net_hh_real / hh$hhsize, hh$pcweight),
      weighted_gini(hh$yd_pc + hh$education_net_current_hh_real / hh$hhsize, hh$pcweight),
      weighted_gini(hh$yd_pc + hh$education_net_all_fees_hh_real / hh$hhsize, hh$pcweight))
  )

  export_excel(users, file.path(paths$TABLES, "20", "20_01_users_unit_costs.xlsx"))
  export_excel(incidence, file.path(paths$TABLES, "20", "20_02_incidence_by_decile.xlsx"))
  export_excel(allocated, file.path(paths$TABLES, "20", "20_03_budget_reconciliation.xlsx"))
  export_excel(robustness, file.path(paths$TABLES, "20", "20_04_fees_robustness.xlsx"))
  export_excel(concentration, file.path(paths$TABLES, "20", "20_05_concentration.xlsx"))

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
    ggplot2::labs(title = "Services publics d'éducation par décile",
      subtitle = "Budget exécuté réparti entre les élèves du public, année 2021",
      x = "Décile de niveau de vie", y = "Milliards de FCFA", fill = NULL) +
    ggplot2::theme_minimal(base_size = 11) + ggplot2::theme(legend.position = "bottom")
  export_fig(fig, file.path(paths$FIGS, "fig20_education_decile.png"), width = 10, height = 6)

  message(sprintf("  Dépense brute attribuée : %.2f milliards; bénéfice net : %.2f milliards",
    sum(hh$education_gross_hh * hh$hhweight) / 1e9,
    sum(hh$education_net_hh * hh$hhweight) / 1e9))
  invisible(hh)
}