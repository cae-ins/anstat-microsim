# 19_subsidies.R
#
# OBJECTIF ECONOMIQUE
# Mesurer les réductions de prix dont bénéficient les ménages pour
# l'électricité et l'eau. Le carburant est calculé séparément mais n'entre pas
# dans le résultat central faute de prix de parité 2021 auditable.
#
# Le code conserve toujours deux montants :
# - la somme effectivement attribuée au ménage ;
# - la variante de sensibilité qui explicite ce qui changerait avec une
#   définition plus large des bénéficiaires ou un prix de référence différent.

subsidies <- function(paths) {

  message(">>> ETAPE 20 : Réductions de prix sur l'électricité, l'eau et les carburants")

  fiscal_path <- file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  conso_path <- file.path(paths$SILVER, "01", "conso_clean.parquet")
  params_path <- file.path(paths$ROOT, "01_data_sources", "params_subsidies_2021.xlsx")
  for (p in c(fiscal_path, conso_path, params_path)) {
    assert_local_file_exists(p)
  }

  fiscal <- load_parquet(fiscal_path)
  conso <- load_parquet(conso_path)
  electricity_params <- readxl::read_excel(params_path, sheet = "electricite")
  water_params <- readxl::read_excel(params_path, sheet = "eau")
  fuel_params <- readxl::read_excel(params_path, sheet = "carburants")
  method_params <- readxl::read_excel(params_path, sheet = "methode")

  assert_required_columns(
    fiscal,
    c("hhid", "grappe", "strata", "hhweight", "pcweight", "decile",
      "quintile", "milieu", "region", "hhsize", "def_spa", "yd_pc", "yd_hh",
      "zref"),
    "fiscal_data_analysis_ready.parquet"
  )
  assert_required_columns(
    conso, c("hhid", "codpr", "depan_w"), "conso_clean.parquet"
  )

  get_parameter <- function(tab, name) {
    hit <- tab[tab$parametre == name, , drop = FALSE]
    if (nrow(hit) != 1L || !is.finite(as.numeric(hit$valeur[[1]]))) {
      stop("Paramètre absent ou ambigu : ", name, call. = FALSE)
    }
    as.numeric(hit$valeur[[1]])
  }

  make_hhid <- function(grappe, menage) {
    as.numeric(grappe) * 100 + as.numeric(menage)
  }

  utility_codes <- c(202, 208, 209, 304, 332, 333, 334)
  utility_spending <- conso |>
    dplyr::filter(.data$codpr %in% utility_codes) |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      spending_electricity = sum(depan_w[codpr == 334], na.rm = TRUE),
      spending_water_network = sum(depan_w[codpr == 332], na.rm = TRUE),
      spending_water_reseller = sum(depan_w[codpr == 333], na.rm = TRUE),
      spending_fuel = sum(depan_w[codpr %in% c(202, 208, 209, 304)],
                          na.rm = TRUE),
      .groups = "drop"
    )

  s11_path <- source_file_path(
    "Datain", "Menage", "s11_me_CIV2021.dta", label = "Module logement S11"
  )
  s11 <- haven::read_dta(
    s11_path,
    col_select = c("grappe", "menage", "s11q33", "s11q34", "s11q35")
  ) |>
    dplyr::transmute(
      hhid = make_hhid(grappe, menage),
      connected_grid = as.integer(s11q33) %in% c(1L, 2L, 3L),
      electricity_in_rent = as.integer(s11q34) == 1L,
      meter_type = as.integer(s11q35)
    ) |>
    dplyr::distinct(hhid, .keep_all = TRUE)

  hh <- fiscal |>
    dplyr::select(
      hhid, grappe, strata, hhweight, pcweight, decile, quintile, milieu,
      region, hhsize, def_spa, yd_pc, yd_hh, zref
    ) |>
    dplyr::left_join(utility_spending, by = "hhid") |>
    dplyr::left_join(s11, by = "hhid") |>
    dplyr::mutate(
      dplyr::across(
        dplyr::starts_with("spending_"),
        ~ dplyr::coalesce(as.numeric(.x), 0)
      ),
      connected_grid = dplyr::coalesce(connected_grid, FALSE),
      electricity_in_rent = dplyr::coalesce(electricity_in_rent, FALSE)
    )

  if (nrow(hh) != nrow(fiscal) || anyDuplicated(hh$hhid)) {
    stop("La jointure des dépenses d'utilité n'est pas bijective.", call. = FALSE)
  }

  # -----------------------------------------------------------------------
  # Electricité
  # -----------------------------------------------------------------------
  macro_electricity <- get_parameter(
    electricity_params, "subvention_exploitation_2021"
  )
  social_share <- get_parameter(
    electricity_params, "part_abonnes_tarif_social"
  )
  social_share_low <- get_parameter(method_params, "part_sociale_basse")
  social_share_high <- get_parameter(method_params, "part_sociale_haute")
  tariff_social <- get_parameter(
    electricity_params, "tarif_moyen_social_ht"
  )
  tariff_general <- get_parameter(
    electricity_params, "tarif_moyen_general_ht"
  )

  positive_bill <- hh$spending_electricity > 0
  if (!any(positive_bill)) {
    stop("Aucune facture d'électricité positive dans l'enquête.", call. = FALSE)
  }

  social_cut <- weighted_quantile(
    hh$spending_electricity[positive_bill],
    hh$hhweight[positive_bill],
    social_share
  )
  social_cut_low <- weighted_quantile(
    hh$spending_electricity[positive_bill],
    hh$hhweight[positive_bill],
    social_share_low
  )
  social_cut_high <- weighted_quantile(
    hh$spending_electricity[positive_bill],
    hh$hhweight[positive_bill],
    social_share_high
  )

  hh <- hh |>
    dplyr::mutate(
      social_electricity = positive_bill & spending_electricity <= social_cut,
      social_electricity_low =
        positive_bill & spending_electricity <= social_cut_low,
      social_electricity_high =
        positive_bill & spending_electricity <= social_cut_high,
      estimated_kwh = dplyr::if_else(
        social_electricity,
        spending_electricity / tariff_social,
        spending_electricity / tariff_general
      )
    )

  allocate_macro <- function(eligible) {
    base <- hh$estimated_kwh * as.numeric(eligible)
    denominator <- sum(base * hh$hhweight, na.rm = TRUE)
    if (!is.finite(denominator) || denominator <= 0) {
      stop("Impossible d'allouer la réduction de prix électrique.", call. = FALSE)
    }
    macro_electricity * base / denominator
  }

  hh$subsidy_electricity_hh <- allocate_macro(hh$social_electricity)
  hh$subsidy_electricity_hh_low <- allocate_macro(
    hh$social_electricity_low
  )
  hh$subsidy_electricity_hh_high <- allocate_macro(
    hh$social_electricity_high
  )
  # Robustesse : l'aide d'exploitation est une enveloppe sectorielle. Elle est
  # donc aussi répartie entre tous les ménages ayant une facture positive.
  hh$subsidy_electricity_all_users_hh <- allocate_macro(positive_bill)

  # -----------------------------------------------------------------------
  # Eau
  # -----------------------------------------------------------------------
  water_params <- water_params |>
    dplyr::arrange(.data$borne_basse_m3_trimestre)
  annual_upper <- as.numeric(water_params$borne_haute_m3_trimestre) * 4
  annual_lower <- as.numeric(water_params$borne_basse_m3_trimestre) * 4
  water_rates <- as.numeric(water_params$tarif_ttc_fcfa_m3)

  invert_water_bill <- function(amount) {
    out <- numeric(length(amount))
    for (i in seq_along(amount)) {
      remaining <- max(as.numeric(amount[[i]]), 0)
      quantity <- 0
      for (j in seq_along(water_rates)) {
        width <- annual_upper[[j]] - annual_lower[[j]]
        if (!is.finite(width)) {
          quantity <- quantity + remaining / water_rates[[j]]
          remaining <- 0
          break
        }
        block_cost <- width * water_rates[[j]]
        used_cost <- min(remaining, block_cost)
        quantity <- quantity + used_cost / water_rates[[j]]
        remaining <- remaining - used_cost
        if (remaining <= 0) break
      }
      out[[i]] <- quantity
    }
    out
  }

  tariff_water_social <- water_rates[[1]]
  tariff_water_reference <- as.numeric(
    water_params$tarif_reference_fcfa_m3[[1]]
  )
  social_water_volume_annual <- annual_upper[[1]]
  reseller_margin_high <- get_parameter(
    method_params, "marge_revendeur_eau_haute"
  )

  hh <- hh |>
    dplyr::mutate(
      estimated_water_m3 = invert_water_bill(spending_water_network),
      subsidy_water_network_hh =
        pmax(tariff_water_reference - tariff_water_social, 0) *
        pmin(estimated_water_m3, social_water_volume_annual),
      subsidy_water_reseller_hh = 0,
      subsidy_water_reseller_hh_high =
        spending_water_reseller * reseller_margin_high,
      subsidy_water_hh =
        subsidy_water_network_hh + subsidy_water_reseller_hh,
      subsidy_water_hh_high =
        subsidy_water_network_hh + subsidy_water_reseller_hh_high
    )

  # -----------------------------------------------------------------------
  # Carburants
  # -----------------------------------------------------------------------
  fuel_central <- fuel_params |>
    dplyr::filter(.data$scenario == "central")
  fuel_high <- fuel_params |>
    dplyr::filter(.data$scenario == "borne_haute_non_2021")
  pump_price <- mean(as.numeric(fuel_central$prix_pompe_fcfa_litre))
  central_gap <- mean(as.numeric(fuel_central$ecart_fcfa_litre))
  high_gap <- mean(as.numeric(fuel_high$ecart_fcfa_litre))

  hh <- hh |>
    dplyr::mutate(
      estimated_fuel_litres = if (pump_price > 0) {
        spending_fuel / pump_price
      } else {
        rep(0, dplyr::n())
      },
      subsidy_fuel_direct_hh = estimated_fuel_litres * central_gap,
      subsidy_fuel_embedded_hh = 0,
      subsidy_fuel_direct_hh_high = estimated_fuel_litres * high_gap,
      subsidy_fuel_embedded_hh_high = 0,
      subsidy_total_hh =
        subsidy_electricity_hh + subsidy_water_hh +
        subsidy_fuel_direct_hh + subsidy_fuel_embedded_hh,
      subsidy_total_electricity_all_users_hh =
        subsidy_electricity_all_users_hh + subsidy_water_hh +
        subsidy_fuel_direct_hh + subsidy_fuel_embedded_hh,
      subsidy_total_hh_low =
        subsidy_electricity_hh_low + subsidy_water_network_hh,
      subsidy_total_hh_high =
        subsidy_electricity_hh_high + subsidy_water_hh_high +
        subsidy_fuel_direct_hh_high + subsidy_fuel_embedded_hh_high
    ) |>
    dplyr::mutate(
      dplyr::across(
        c(
          subsidy_electricity_hh, subsidy_electricity_hh_low,
          subsidy_electricity_hh_high, subsidy_electricity_all_users_hh,
          subsidy_water_network_hh,
          subsidy_water_reseller_hh, subsidy_water_reseller_hh_high,
          subsidy_water_hh, subsidy_water_hh_high,
          subsidy_fuel_direct_hh, subsidy_fuel_embedded_hh,
          subsidy_fuel_direct_hh_high, subsidy_fuel_embedded_hh_high,
          subsidy_total_hh, subsidy_total_hh_low, subsidy_total_hh_high,
          subsidy_total_electricity_all_users_hh
        ),
        ~ .x * def_spa,
        .names = "{.col}_real"
      ),
      subsidy_total_pc_real = subsidy_total_hh_real / hhsize,
      eff_subsidy = subsidy_total_hh_real / yd_hh
    )

  amount_columns <- grep(
    "^subsidy_.*_hh(_real)?$",
    names(hh), value = TRUE
  )
  if (any(!is.finite(as.matrix(hh[, amount_columns]))) ||
      any(as.matrix(hh[, amount_columns]) < -1e-8)) {
    stop("Une réduction de prix est négative ou non finie.", call. = FALSE)
  }

  electricity_reconciliation <- sum(
    hh$subsidy_electricity_hh * hh$hhweight
  )
  electricity_reconciliation_all_users <- sum(
    hh$subsidy_electricity_all_users_hh * hh$hhweight
  )
  if (abs(electricity_reconciliation - macro_electricity) > 1 ||
      abs(electricity_reconciliation_all_users - macro_electricity) > 1) {
    stop("Le calage électrique ne retrouve pas la masse administrative.",
         call. = FALSE)
  }

  output_columns <- c(
    "hhid", "grappe", "strata", "hhweight", "pcweight", "decile",
    "quintile", "milieu", "region", "hhsize", "def_spa", "yd_pc", "yd_hh",
    "zref", "connected_grid", "electricity_in_rent", "meter_type",
    "spending_electricity", "spending_water_network",
    "spending_water_reseller", "spending_fuel", "social_electricity",
    "estimated_kwh", "estimated_water_m3", "estimated_fuel_litres",
    "subsidy_electricity_hh", "subsidy_electricity_all_users_hh",
    "subsidy_water_network_hh",
    "subsidy_water_reseller_hh", "subsidy_water_hh",
    "subsidy_fuel_direct_hh", "subsidy_fuel_embedded_hh",
    "subsidy_total_hh", "subsidy_total_hh_low", "subsidy_total_hh_high",
    "subsidy_electricity_hh_real", "subsidy_water_network_hh_real",
    "subsidy_water_reseller_hh_real", "subsidy_water_hh_real",
    "subsidy_fuel_direct_hh_real", "subsidy_fuel_embedded_hh_real",
    "subsidy_total_hh_real", "subsidy_total_hh_low_real",
    "subsidy_total_hh_high_real", "subsidy_total_electricity_all_users_hh_real",
    "subsidy_total_pc_real", "eff_subsidy"
  )
  save_parquet(
    hh |>
      dplyr::select(dplyr::all_of(output_columns)),
    file.path(paths$SILVER, "19", "subsidies.parquet")
  )

  # -----------------------------------------------------------------------
  # Rapports
  # -----------------------------------------------------------------------
  incidence <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      menages_ponderes = sum(hhweight),
      beneficiaires_electricite = sum(
        hhweight * (subsidy_electricity_hh > 0)
      ),
      beneficiaires_eau = sum(hhweight * (subsidy_water_hh > 0)),
      electricite_milliards =
        sum(subsidy_electricity_hh * hhweight) / 1e9,
      eau_milliards = sum(subsidy_water_hh * hhweight) / 1e9,
      carburants_milliards =
        sum(subsidy_fuel_direct_hh * hhweight) / 1e9,
      total_milliards = sum(subsidy_total_hh * hhweight) / 1e9,
      moyenne_reelle_par_menage =
        stats::weighted.mean(subsidy_total_hh_real, hhweight),
      taux_effectif_pct =
        100 * stats::weighted.mean(eff_subsidy, pcweight),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      part_total_pct = 100 * total_milliards / sum(total_milliards)
    )

  ranking <- hh |>
    dplyr::mutate(benefit_pc = subsidy_total_pc_real)
  concentration_point <- weighted_conindex(
    ranking$benefit_pc, ranking$yd_pc, ranking$pcweight
  )
  targeting_point <- weighted_gini(
    ranking$yd_pc, ranking$pcweight
  ) - concentration_point
  reps <- as.integer(get_parameter(method_params, "bootstrap_reps"))
  seed <- as.integer(get_parameter(method_params, "bootstrap_seed"))
  concentration_boot <- bootstrap_survey_statistic(
    ranking,
    statistic = function(d) {
      weighted_conindex(d$benefit_pc, d$yd_pc, d$pcweight)
    },
    weight_var = "pcweight",
    cluster_var = "grappe",
    strata_var = "strata",
    reps = reps,
    seed = seed
  )
  concentration <- tibble::tibble(
    indicateur = c(
      "Coefficient de concentration des réductions de prix",
      "Indice de ciblage vers les ménages modestes"
    ),
    estimation = c(concentration_point, targeting_point),
    ic95_bas = c(
      concentration_boot$lo,
      weighted_gini(ranking$yd_pc, ranking$pcweight) -
        concentration_boot$hi
    ),
    ic95_haut = c(
      concentration_boot$hi,
      weighted_gini(ranking$yd_pc, ranking$pcweight) -
        concentration_boot$lo
    ),
    repetitions_valides = concentration_boot$reps_ok,
    methode = concentration_boot$method
  )

  coverage <- tibble::tibble(
    indicateur = c(
      "Ménages avec facture d'électricité",
      "Ménages classés au tarif social dans le calcul central",
      "Seuil annuel de facture du groupe social",
      "Ménages avec facture d'eau du réseau",
      "Ménages avec achat d'eau chez un revendeur",
      "Part de l'aide électrique attribuée exactement"
    ),
    valeur = c(
      sum(hh$hhweight[hh$spending_electricity > 0]),
      sum(hh$hhweight[hh$social_electricity]),
      social_cut,
      sum(hh$hhweight[hh$spending_water_network > 0]),
      sum(hh$hhweight[hh$spending_water_reseller > 0]),
      electricity_reconciliation
    ),
    unite = c(
      "ménages pondérés", "ménages pondérés", "FCFA/an",
      "ménages pondérés", "ménages pondérés", "FCFA/an pondérés"
    ),
    explication = c(
      "Dépense codpr 334 strictement positive.",
      "Les 30 % de clients aux factures les plus faibles, conformément à la part documentée par l'ANARE-CI.",
      "Ce seuil est calculé dans l'enquête avec les poids de ménage.",
      "Dépense codpr 332 strictement positive.",
      "Dépense codpr 333; aucun tarif de réseau ne lui est appliqué au centre.",
      "La somme attribuée aux ménages retrouve la subvention d'exploitation de 8,69 milliards."
    )
  )

  macro_validation <- tibble::tibble(
    composante = c(
      "Electricité", "Eau du réseau", "Eau revendeur",
      "Carburants, scénario central", "Total central"
    ),
    simulation_milliards = c(
      sum(hh$subsidy_electricity_hh * hh$hhweight) / 1e9,
      sum(hh$subsidy_water_network_hh * hh$hhweight) / 1e9,
      sum(hh$subsidy_water_reseller_hh * hh$hhweight) / 1e9,
      sum(hh$subsidy_fuel_direct_hh * hh$hhweight) / 1e9,
      sum(hh$subsidy_total_hh * hh$hhweight) / 1e9
    ),
    reference_milliards = c(8.69, NA, NA, NA, NA),
    comparabilite = c(
      "Calage exact sur la subvention d'exploitation du secteur électrique.",
      "Réduction de prix implicite de la tranche sociale par rapport au tarif domestique; il s'agit d'une subvention croisée, pas d'une dépense budgétaire.",
      "Non valorisée au centre faute de tarif observable du revendeur.",
      "Non valorisé au centre faute de série de prix de parité 2021.",
      "Somme des composantes centrales."
    ),
    source = c(
      "ANARE-CI, Rapport d'activités 2021, p. 46",
      "Grille SODECI 2021 citée dans la source archivée au classeur",
      "EHCVM 2021, codpr 333",
      "DGH 2021: prix à la pompe; prix sans soutien non observable",
      "Calcul du pipeline"
    )
  )

  sensitivity <- tibble::tibble(
    scenario = c(
      "Central", "Électricité répartie entre tous les clients",
      "Borne basse", "Borne haute documentée"
    ),
    definition = c(
      "30 % de clients électriques sociaux; eau du réseau; aucun soutien carburant.",
      "Les 8,69 milliards d'aide d'exploitation sont répartis entre tous les ménages ayant une facture positive, au prorata des kWh estimés.",
      "20 % de clients électriques sociaux; eau du réseau; aucun revendeur ni carburant.",
      "40 % de clients électriques sociaux; marge revendeur de 20 %; écart carburant de 80 FCFA/litre provenant de 2022 et clairement séparé."
    ),
    masse_milliards = c(
      sum(hh$subsidy_total_hh * hh$hhweight) / 1e9,
      sum(hh$subsidy_total_electricity_all_users_hh * hh$hhweight) / 1e9,
      sum(hh$subsidy_total_hh_low * hh$hhweight) / 1e9,
      sum(hh$subsidy_total_hh_high * hh$hhweight) / 1e9
    ),
    gini_apres = c(
      weighted_gini(
        pmax(hh$yd_pc + hh$subsidy_total_hh_real / hh$hhsize, 0),
        hh$pcweight
      ),
      weighted_gini(
        pmax(hh$yd_pc + hh$subsidy_total_electricity_all_users_hh_real / hh$hhsize, 0),
        hh$pcweight
      ),
      weighted_gini(
        pmax(hh$yd_pc + hh$subsidy_total_hh_low_real / hh$hhsize, 0),
        hh$pcweight
      ),
      weighted_gini(
        pmax(hh$yd_pc + hh$subsidy_total_hh_high_real / hh$hhsize, 0),
        hh$pcweight
      )
    )
  )

  export_excel(
    coverage,
    file.path(paths$TABLES, "19", "19_01_parameters_coverage.xlsx")
  )
  export_excel(
    incidence,
    file.path(paths$TABLES, "19", "19_02_incidence_by_decile.xlsx")
  )
  export_excel(
    concentration,
    file.path(paths$TABLES, "19", "19_03_concentration.xlsx")
  )
  export_excel(
    macro_validation,
    file.path(paths$TABLES, "19", "19_04_macro_validation.xlsx")
  )
  export_excel(
    sensitivity,
    file.path(paths$TABLES, "19", "19_05_sensitivity.xlsx")
  )

  figure_data <- incidence |>
    dplyr::select(decile, electricite_milliards, eau_milliards,
                  carburants_milliards) |>
    tidyr::pivot_longer(
      -decile, names_to = "composante", values_to = "milliards"
    ) |>
    dplyr::mutate(
      composante = dplyr::recode(
        composante,
        electricite_milliards = "Électricité",
        eau_milliards = "Eau",
        carburants_milliards = "Carburants"
      )
    )

  fig <- ggplot2::ggplot(
    figure_data,
    ggplot2::aes(x = factor(decile), y = milliards, fill = composante)
  ) +
    ggplot2::geom_col(width = 0.76) +
    ggplot2::scale_fill_manual(
      values = c(
        "Électricité" = "#1F77B4",
        "Eau" = "#2CA02C",
        "Carburants" = "#FF7F0E"
      )
    ) +
    ggplot2::labs(
      title = "Réductions de prix attribuées aux ménages",
      subtitle = "Montants annuels pondérés par décile, scénario central 2021",
      x = "Décile de niveau de vie",
      y = "Milliards de FCFA",
      fill = NULL,
      caption = paste0(
        "L'électricité est calée sur 8,69 milliards de subvention d'exploitation. ",
        "L'eau mesure l'avantage de la tranche sociale. ",
        "Aucun soutien carburant n'est imputé au scénario central."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")

  export_fig(
    fig, file.path(paths$FIGS, "fig19_subsidies_decile.png"),
    width = 10, height = 6
  )

  message(sprintf(
    "  Réductions de prix centrales : %.2f milliards de FCFA",
    sum(hh$subsidy_total_hh * hh$hhweight) / 1e9
  ))

  invisible(hh)
}