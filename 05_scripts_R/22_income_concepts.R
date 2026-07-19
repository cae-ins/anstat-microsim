# 22_income_concepts.R
# Assemble les instruments déjà calculés et construit les concepts de revenu CEQ
# ménage par ménage, selon les deux conventions de traitement des pensions.

income_concepts <- function(paths) {
  message(">>> ETAPE 23 : Concepts de revenu CEQ complets")
  files <- c(
    transfers = file.path(paths$SILVER, "18", "transfers.parquet"),
    vat = file.path(paths$SILVER, "13b", "fiscal_data_local_io_current.parquet"),
    other = file.path(paths$SILVER, "17", "indirect_other.parquet"),
    subsidies = file.path(paths$SILVER, "19", "subsidies.parquet"),
    education = file.path(paths$SILVER, "20", "inkind_education.parquet"),
    health = file.path(paths$SILVER, "21", "inkind_health.parquet"))
  invisible(lapply(files, assert_local_file_exists))
  tr <- load_parquet(files[["transfers"]]); vat <- load_parquet(files[["vat"]])
  oth <- load_parquet(files[["other"]]); sub <- load_parquet(files[["subsidies"]])
  edu <- load_parquet(files[["education"]]); hea <- load_parquet(files[["health"]])

  select_unique <- function(x, cols, name) {
    assert_required_columns(x, c("hhid", cols), name)
    y <- x |> dplyr::select(hhid, dplyr::all_of(cols))
    if (anyDuplicated(y$hhid)) stop("Doublons ménage dans ", name)
    y
  }
  base_cols <- c("grappe", "strata", "hhweight", "pcweight", "decile",
    "quintile", "milieu", "region", "hhsize", "def_spa", "yd_pc", "yd_hh",
    "public_transfers_hh_real", "direct_levies_pdi_hh_real",
    "yp_pc_pdi", "yl_pc_pdi", "yn_pc_pdi", "yg_pc_pdi",
    "public_transfers_pgt_hh_real", "direct_levies_pgt_hh_real",
    "yp_pc_pgt", "yn_pc_pgt", "yg_pc_pgt")
  hh <- select_unique(tr, base_cols, "transferts") |>
    dplyr::left_join(select_unique(vat, c("zref", "vat_total_local_strict_real",
      "vat_total_local_s2_real", "vat_total_local_s3_real"), "TVA locale"), by = "hhid") |>
    dplyr::left_join(select_unique(oth, c("indirect_other_hh_real",
      "indirect_other_hh_s2_real", "indirect_other_hh_s3_real"), "accises et douanes"), by = "hhid") |>
    dplyr::left_join(select_unique(sub, c("subsidy_total_hh_real",
      "subsidy_total_hh_low_real", "subsidy_total_hh_high_real"), "réductions de prix"), by = "hhid") |>
    dplyr::left_join(select_unique(edu, c("education_gross_hh_real",
      "education_fees_hh_real", "education_net_hh_real",
      "education_net_current_hh_real", "education_net_all_fees_hh_real"), "éducation"), by = "hhid") |>
    dplyr::left_join(select_unique(hea, c("health_gross_hh_real",
      "health_fees_hh_real", "health_net_hh_real", "health_net_use_hh_real",
      "health_net_wide_budget_hh_real"), "santé"), by = "hhid")
  if (nrow(hh) != nrow(tr) || anyDuplicated(hh$hhid) || anyNA(hh)) {
    stop("L'assemblage des modules n'est pas complet et bijectif.")
  }

  hh <- hh |>
    dplyr::mutate(
      indirect_taxes_hh_real = vat_total_local_s3_real + indirect_other_hh_real,
      indirect_taxes_strict_hh_real = vat_total_local_strict_real + indirect_other_hh_real,
      indirect_taxes_s2_hh_real = vat_total_local_s2_real + indirect_other_hh_s2_real,
      indirect_taxes_full_s3_hh_real = vat_total_local_s3_real + indirect_other_hh_s3_real,
      yc_pc = yd_pc - indirect_taxes_hh_real / hhsize + subsidy_total_hh_real / hhsize,
      yc_pc_no_subsidy = yd_pc - indirect_taxes_hh_real / hhsize,
      yc_pc_strict = yd_pc - indirect_taxes_strict_hh_real / hhsize + subsidy_total_hh_real / hhsize,
      yc_pc_s2 = yd_pc - indirect_taxes_s2_hh_real / hhsize + subsidy_total_hh_real / hhsize,
      yc_pc_full_s3 = yd_pc - indirect_taxes_full_s3_hh_real / hhsize + subsidy_total_hh_real / hhsize,
      yc_pc_subsidy_low = yd_pc - indirect_taxes_hh_real / hhsize + subsidy_total_hh_low_real / hhsize,
      yc_pc_subsidy_high = yd_pc - indirect_taxes_hh_real / hhsize + subsidy_total_hh_high_real / hhsize,
      yf_pc = yc_pc + education_net_hh_real / hhsize + health_net_hh_real / hhsize,
      yf_pc_gross = yc_pc + education_gross_hh_real / hhsize + health_gross_hh_real / hhsize,
      yf_pc_current_education = yc_pc + education_net_current_hh_real / hhsize + health_net_hh_real / hhsize,
      yf_pc_use_health = yc_pc + education_net_hh_real / hhsize + health_net_use_hh_real / hhsize,
      yf_pc_pdi = yf_pc, yf_pc_pgt = yf_pc, yc_pc_pdi = yc_pc, yc_pc_pgt = yc_pc,
      y_fiscal_pc = yc_pc,
      direct_net_effect_pdi_pc = (public_transfers_hh_real - direct_levies_pdi_hh_real) / hhsize,
      direct_net_effect_pgt_pc = (public_transfers_pgt_hh_real - direct_levies_pgt_hh_real) / hhsize)

  tolerance <- 1e-6
  identity <- tibble::tibble(
    identite = c("PDI : disponible", "PDI : brut", "PGT : disponible", "PGT : brut",
                 "Revenu consommable", "Revenu final"),
    ecart_maximum = c(
      max(abs(hh$yd_pc - (hh$yn_pc_pdi + hh$public_transfers_hh_real / hh$hhsize))),
      max(abs(hh$yg_pc_pdi - (hh$yp_pc_pdi + hh$public_transfers_hh_real / hh$hhsize))),
      max(abs(hh$yd_pc - (hh$yn_pc_pgt + hh$public_transfers_pgt_hh_real / hh$hhsize))),
      max(abs(hh$yg_pc_pgt - (hh$yp_pc_pgt + hh$public_transfers_pgt_hh_real / hh$hhsize))),
      max(abs(hh$yc_pc - (hh$yd_pc - hh$indirect_taxes_hh_real / hh$hhsize + hh$subsidy_total_hh_real / hh$hhsize))),
      max(abs(hh$yf_pc - (hh$yc_pc + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize))))
  ) |>
    dplyr::mutate(tolerance = tolerance, valide = ecart_maximum <= tolerance)
  if (!all(identity$valide)) stop("Une identité CEQ n'est pas vérifiée.")

  save_parquet(hh, file.path(paths$SILVER, "22", "all_income_concepts.parquet"))

  concept_vars <- c("yp_pc_pdi", "yn_pc_pdi", "yg_pc_pdi", "yd_pc", "yc_pc", "yf_pc")
  concept_labels <- c("Revenu primaire", "Revenu net de marché", "Revenu brut",
                      "Revenu disponible", "Revenu consommable", "Revenu final")
  concepts <- purrr::map2_dfr(concept_vars, concept_labels, function(v, lab) {
    x <- hh[[v]]
    tibble::tibble(
      concept = lab, variable = v,
      moyenne_ponderee = stats::weighted.mean(x, hh$pcweight),
      gini_avec_plancher_zero = weighted_gini(pmax(x, 0), hh$pcweight),
      taux_pauvrete = stats::weighted.mean(x < hh$zref, hh$pcweight),
      part_population_revenu_negatif = stats::weighted.mean(x < 0, hh$pcweight))
  })
  instruments <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      prelevements_directs_milliards = sum(direct_levies_pdi_hh_real * hhweight) / 1e9,
      paiements_publics_directs_milliards = sum(public_transfers_hh_real * hhweight) / 1e9,
      impots_indirects_milliards = sum(indirect_taxes_hh_real * hhweight) / 1e9,
      reductions_prix_milliards = sum(subsidy_total_hh_real * hhweight) / 1e9,
      education_nette_milliards = sum(education_net_hh_real * hhweight) / 1e9,
      sante_nette_milliards = sum(health_net_hh_real * hhweight) / 1e9,
      .groups = "drop")
  robustness <- tibble::tibble(
    scenario = c("Central", "TVA et autres impôts stricts", "Informalité S2 complète",
                 "Informalité S3 complète", "Sans réductions de prix",
                 "Budgets en nature bruts"),
    revenu_moyen = c(
      stats::weighted.mean(hh$yf_pc, hh$pcweight),
      stats::weighted.mean(hh$yc_pc_strict + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, hh$pcweight),
      stats::weighted.mean(hh$yc_pc_s2 + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, hh$pcweight),
      stats::weighted.mean(hh$yc_pc_full_s3 + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, hh$pcweight),
      stats::weighted.mean(hh$yc_pc_no_subsidy + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, hh$pcweight),
      stats::weighted.mean(hh$yf_pc_gross, hh$pcweight)),
    gini = c(
      weighted_gini(pmax(hh$yf_pc, 0), hh$pcweight),
      weighted_gini(pmax(hh$yc_pc_strict + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, 0), hh$pcweight),
      weighted_gini(pmax(hh$yc_pc_s2 + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, 0), hh$pcweight),
      weighted_gini(pmax(hh$yc_pc_full_s3 + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, 0), hh$pcweight),
      weighted_gini(pmax(hh$yc_pc_no_subsidy + hh$education_net_hh_real / hh$hhsize + hh$health_net_hh_real / hh$hhsize, 0), hh$pcweight),
      weighted_gini(pmax(hh$yf_pc_gross, 0), hh$pcweight)))
  negative <- purrr::map_dfr(c("yp_pc_pdi", "yd_pc", "yc_pc", "yf_pc"), function(v) {
    tibble::tibble(variable = v, menages_negatifs = sum(hh$hhweight * (hh[[v]] < 0)),
      population_negative = sum(hh$pcweight * (hh[[v]] < 0)),
      part_population_pct = 100 * stats::weighted.mean(hh[[v]] < 0, hh$pcweight))
  })
  export_excel(concepts, file.path(paths$TABLES, "22", "22_01_income_concepts.xlsx"))
  export_excel(instruments, file.path(paths$TABLES, "22", "22_02_instruments_by_decile.xlsx"))
  export_excel(identity, file.path(paths$TABLES, "22", "22_03_identity_checks.xlsx"))
  export_excel(robustness, file.path(paths$TABLES, "22", "22_04_robustness.xlsx"))
  export_excel(negative, file.path(paths$TABLES, "22", "22_05_negative_incomes.xlsx"))

  fig_data <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(concept_vars),
      ~ stats::weighted.mean(.x, pcweight)), .groups = "drop") |>
    tidyr::pivot_longer(-decile, names_to = "variable", values_to = "fcfa") |>
    dplyr::mutate(concept = factor(variable, levels = concept_vars, labels = concept_labels))
  palette <- c("Revenu primaire"="#003F5C", "Revenu net de marché"="#2F4B7C",
    "Revenu brut"="#1F77B4", "Revenu disponible"="#2CA02C",
    "Revenu consommable"="#FF7F0E", "Revenu final"="#D62728")
  fig <- ggplot2::ggplot(fig_data, ggplot2::aes(decile, fcfa, color = concept)) +
    ggplot2::geom_line(linewidth = 0.9) + ggplot2::geom_point(size = 1.8) +
    ggplot2::scale_color_manual(values = palette) +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = " ")) +
    ggplot2::labs(title = "Concepts de revenu CEQ par décile",
      subtitle = "Moyennes annuelles par personne, convention PDI",
      x = "Décile de niveau de vie", y = "FCFA par personne", color = NULL) +
    ggplot2::theme_minimal(base_size = 11) + ggplot2::theme(legend.position = "bottom")
  export_fig(fig, file.path(paths$FIGS, "fig22_income_concepts.png"), width = 11, height = 6.5)

  message(sprintf("  Gini disponible %.4f; consommable %.4f; final %.4f",
    weighted_gini(hh$yd_pc, hh$pcweight), weighted_gini(pmax(hh$yc_pc, 0), hh$pcweight),
    weighted_gini(pmax(hh$yf_pc, 0), hh$pcweight)))
  invisible(hh)
}