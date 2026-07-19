# 17_indirect_other.R
#
# OBJECTIF :
# Imputer aux ménages les accises et droits de douane payés dans leurs achats,
# en complément de la TVA déjà simulée. La dépense TTC est décomposée selon
# l'ordre CAF -> droit de douane -> accise -> TVA, après retrait des marges.
#
# ENTREES :
#   SILVER/01/conso_clean.parquet
#   SILVER/04/fiscal_data_analysis_ready.parquet
#   SILVER/IO_local/current/valuation_bridge_2023.csv
#   01_data_sources/params_indirect_other_2021.xlsx
#
# SORTIES :
#   SILVER/17/indirect_other.parquet
#   TABLES/17/17_01_excise_by_decile.xlsx
#   TABLES/17/17_02_customs_by_decile.xlsx
#   TABLES/17/17_03_kakwani_inference.xlsx
#   TABLES/17/17_04_macro_validation.xlsx
#   TABLES/17/17_05_mapping_diagnostics.xlsx
#   FIGS/fig17_indirect_other_decile.png

indirect_other <- function(paths) {

  message(">>> ETAPE 18 : Accises et droits de douane (TEC CEDEAO)")

  conso_path <- file.path(paths$SILVER, "01", "conso_clean.parquet")
  fiscal_path <- file.path(
    paths$SILVER, "04", "fiscal_data_analysis_ready.parquet"
  )
  valuation_path <- file.path(
    paths$SILVER, "IO_local", "current", "valuation_bridge_2023.csv"
  )
  params_path <- file.path(
    paths$ROOT, "01_data_sources", "params_indirect_other_2021.xlsx"
  )
  for (p in c(conso_path, fiscal_path, valuation_path, params_path)) {
    assert_local_file_exists(p)
  }

  conso <- load_parquet(conso_path)
  fiscal <- load_parquet(fiscal_path)
  valuation <- utils::read.csv(valuation_path, check.names = FALSE)
  excise_params <- readxl::read_excel(params_path, sheet = "accises")
  tec_params <- readxl::read_excel(params_path, sheet = "tec_codpr")
  macro_refs <- readxl::read_excel(params_path, sheet = "macro_refs")

  assert_required_columns(
    conso,
    c(
      "hhid", "hhweight", "milieu", "coicop", "codpr", "depan_w",
      "r_vat_official", "produit"
    ),
    object_name = "conso_clean.parquet"
  )
  assert_required_columns(
    fiscal,
    c(
      "hhid", "grappe", "strata", "hhweight", "pcweight", "decile",
      "quintile", "milieu", "region", "hhsize", "def_spa", "yd_pc",
      "yd_hh", "vat_w_real"
    ),
    object_name = "fiscal_data_analysis_ready.parquet"
  )
  assert_required_columns(
    valuation,
    c(
      "code", "name", "purchaser_total", "trade_margins",
      "transport_margins", "import_taxes", "imports", "domestic_output"
    ),
    object_name = "valuation_bridge_2023.csv"
  )
  assert_required_columns(
    excise_params,
    c(
      "codpr", "groupe", "taux_ad_valorem_equivalent", "include_central"
    ),
    object_name = "params_indirect_other_2021.xlsx/accises"
  )
  assert_required_columns(
    tec_params,
    c("codpr", "bande_tec", "import_share_override"),
    object_name = "params_indirect_other_2021.xlsx/tec_codpr"
  )

  item_mapping <- build_tre_item_mapping(paths$ROOT)
  tre_profile <- valuation |>
    dplyr::transmute(
      code_TRE = code,
      produit_TRE = name,
      marge_part = pmin(
        pmax((trade_margins + transport_margins) / purchaser_total, 0),
        0.80
      ),
      import_share_tre = dplyr::if_else(
        imports + domestic_output > 0,
        imports / (imports + domestic_output),
        0
      ),
      taux_douane_implicite_tre = dplyr::if_else(
        imports > 0, import_taxes / imports, 0
      ),
      import_taxes_tre = import_taxes,
      imports_tre = imports
    )

  hh_rank <- fiscal |>
    dplyr::select(hhid, decile)
  excise_rates <- excise_params |>
    dplyr::transmute(
      codpr = as.integer(codpr),
      groupe_accise = as.character(groupe),
      taux_accise = dplyr::if_else(
        as.logical(include_central),
        dplyr::coalesce(as.numeric(taux_ad_valorem_equivalent), 0),
        0
      ),
      accise_centrale = as.logical(include_central)
    )
  tec_rates <- tec_params |>
    dplyr::transmute(
      codpr = as.integer(codpr),
      bande_tec = dplyr::coalesce(as.numeric(bande_tec), 0),
      import_share_override = as.numeric(import_share_override)
    )

  central_positive <- excise_rates |>
    dplyr::filter(accise_centrale, taux_accise > 0) |>
    dplyr::pull(codpr)
  missing_excisable <- setdiff(central_positive, unique(as.integer(conso$codpr)))
  if (length(missing_excisable) > 0) {
    stop(
      "Postes accisables absents de conso_clean.parquet: ",
      paste(missing_excisable, collapse = ", "),
      call. = FALSE
    )
  }

  items <- conso |>
    dplyr::left_join(hh_rank, by = "hhid") |>
    dplyr::left_join(item_mapping, by = "codpr") |>
    dplyr::left_join(tre_profile, by = "code_TRE") |>
    dplyr::left_join(excise_rates, by = "codpr") |>
    dplyr::left_join(tec_rates, by = "codpr")

  national_exp <- items$depan_w * items$hhweight
  mapping_coverage <- sum(
    national_exp[!is.na(items$code_TRE)], na.rm = TRUE
  ) / sum(national_exp, na.rm = TRUE)
  customs_coverage <- sum(
    national_exp[!is.na(items$bande_tec)], na.rm = TRUE
  ) / sum(national_exp, na.rm = TRUE)
  if (customs_coverage < 0.999999) {
    stop(
      sprintf(
        "Couverture du mapping TEC insuffisante: %.2f%%.",
        100 * customs_coverage
      ),
      call. = FALSE
    )
  }

  items <- items |>
    dplyr::mutate(
      marge_part = dplyr::coalesce(marge_part, 0),
      import_share = dplyr::coalesce(
        import_share_override, import_share_tre, 0
      ),
      import_share = pmin(pmax(import_share, 0), 1),
      bande_tec = dplyr::coalesce(bande_tec, 0),
      groupe_accise = dplyr::coalesce(groupe_accise, "aucune"),
      taux_accise = dplyr::coalesce(taux_accise, 0),
      r_vat = dplyr::coalesce(as.numeric(r_vat_official), 0),
      base_hors_marges = pmax(depan_w * (1 - marge_part), 0),
      taux_douane_effectif = bande_tec * import_share,
      alpha_s2 = dplyr::if_else(
        groupe_accise %in% c("alcool", "tabac"),
        vat_alpha_milieu(coicop, milieu),
        1
      ),
      alpha_s3 = dplyr::if_else(
        groupe_accise %in% c("alcool", "tabac"),
        vat_alpha_decile(coicop, decile),
        1
      ),
      excise_item = base_hors_marges * taux_accise /
        ((1 + taux_accise) * (1 + r_vat)),
      excise_item_s2 = excise_item * alpha_s2,
      excise_item_s3 = excise_item * alpha_s3,
      duty_item = base_hors_marges * taux_douane_effectif /
        (
          (1 + taux_douane_effectif) *
            (1 + taux_accise) *
            (1 + r_vat)
        ),
      total_item = excise_item + duty_item,
      total_item_s2 = excise_item_s2 + duty_item,
      total_item_s3 = excise_item_s3 + duty_item,
      taxes_retrait_naif =
        base_hors_marges * taux_accise / (1 + taux_accise) +
        base_hors_marges * taux_douane_effectif /
          (1 + taux_douane_effectif),
      ecart_double_compte_tva_evite = pmax(
        taxes_retrait_naif - total_item, 0
      )
    )

  tax_columns <- c(
    "excise_item", "excise_item_s2", "excise_item_s3", "duty_item",
    "total_item", "total_item_s2", "total_item_s3",
    "ecart_double_compte_tva_evite"
  )
  if (any(!is.finite(as.matrix(items[, tax_columns])))) {
    stop("Montants non finis détectés dans la décomposition fiscale.",
         call. = FALSE)
  }
  if (any(as.matrix(items[, tax_columns]) < -1e-8)) {
    stop("Montants négatifs détectés dans la décomposition fiscale.",
         call. = FALSE)
  }

  hh_tax <- items |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      excise_hh = sum(excise_item),
      excise_alcohol_hh = sum(excise_item[groupe_accise == "alcool"]),
      excise_tobacco_hh = sum(excise_item[groupe_accise == "tabac"]),
      excise_fuel_hh = sum(excise_item[groupe_accise == "carburants"]),
      excise_non_alcohol_hh = sum(
        excise_item[groupe_accise == "boissons_non_alcoolisees"]
      ),
      excise_cosmetics_hh = sum(
        excise_item[groupe_accise == "cosmetiques"]
      ),
      custom_duty_hh = sum(duty_item),
      excise_hh_s2 = sum(excise_item_s2),
      excise_hh_s3 = sum(excise_item_s3),
      custom_duty_hh_s2 = sum(duty_item),
      custom_duty_hh_s3 = sum(duty_item),
      indirect_other_hh = sum(total_item),
      indirect_other_hh_s2 = sum(total_item_s2),
      indirect_other_hh_s3 = sum(total_item_s3),
      ecart_double_compte_tva_evite_hh = sum(
        ecart_double_compte_tva_evite
      ),
      .groups = "drop"
    )

  hh <- fiscal |>
    dplyr::select(
      hhid, grappe, strata, hhweight, pcweight, decile, quintile, milieu,
      region, hhsize, def_spa, yd_pc, yd_hh, vat_w_real
    ) |>
    dplyr::left_join(hh_tax, by = "hhid")

  household_tax_columns <- setdiff(names(hh_tax), "hhid")
  hh[household_tax_columns] <- lapply(
    hh[household_tax_columns],
    function(x) dplyr::coalesce(x, 0)
  )
  hh <- hh |>
    dplyr::mutate(
      excise_hh_real = excise_hh * def_spa,
      excise_alcohol_hh_real = excise_alcohol_hh * def_spa,
      excise_tobacco_hh_real = excise_tobacco_hh * def_spa,
      excise_fuel_hh_real = excise_fuel_hh * def_spa,
      excise_non_alcohol_hh_real = excise_non_alcohol_hh * def_spa,
      excise_cosmetics_hh_real = excise_cosmetics_hh * def_spa,
      custom_duty_hh_real = custom_duty_hh * def_spa,
      indirect_other_hh_real = indirect_other_hh * def_spa,
      indirect_other_hh_s2_real = indirect_other_hh_s2 * def_spa,
      indirect_other_hh_s3_real = indirect_other_hh_s3 * def_spa,
      eff_excise = excise_hh_real / yd_hh,
      eff_custom_duty = custom_duty_hh_real / yd_hh,
      eff_indirect_other = indirect_other_hh_real / yd_hh,
      yc_pc_vat_indirect_other = yd_pc -
        (vat_w_real + indirect_other_hh_real) / hhsize
    )

  save_parquet(
    hh,
    file.path(paths$SILVER, "17", "indirect_other.parquet")
  )

  # 1. Accises par décile.
  excise_decile <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      n_hh = dplyr::n(),
      menages_payeurs_pct = 100 * stats::weighted.mean(
        excise_hh > 0, hhweight
      ),
      moyenne_hh = stats::weighted.mean(excise_hh, hhweight),
      taux_effectif_pct = 100 * stats::weighted.mean(
        eff_excise, pcweight
      ),
      masse_totale = sum(excise_hh * hhweight),
      masse_alcool = sum(excise_alcohol_hh * hhweight),
      masse_tabac = sum(excise_tobacco_hh * hhweight),
      masse_carburants = sum(excise_fuel_hh * hhweight),
      masse_boissons_non_alcoolisees = sum(
        excise_non_alcohol_hh * hhweight
      ),
      masse_cosmetiques = sum(excise_cosmetics_hh * hhweight),
      .groups = "drop"
    ) |>
    dplyr::mutate(part_masse_pct = 100 * masse_totale / sum(masse_totale))
  export_excel(
    excise_decile,
    file.path(paths$TABLES, "17", "17_01_excise_by_decile.xlsx")
  )

  # 2. Droits de douane par décile.
  customs_decile <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      n_hh = dplyr::n(),
      menages_payeurs_pct = 100 * stats::weighted.mean(
        custom_duty_hh > 0, hhweight
      ),
      moyenne_hh = stats::weighted.mean(custom_duty_hh, hhweight),
      taux_effectif_pct = 100 * stats::weighted.mean(
        eff_custom_duty, pcweight
      ),
      masse = sum(custom_duty_hh * hhweight),
      .groups = "drop"
    ) |>
    dplyr::mutate(part_masse_pct = 100 * masse / sum(masse))
  export_excel(
    customs_decile,
    file.path(paths$TABLES, "17", "17_02_customs_by_decile.xlsx")
  )

  # 3. Progressivité avec bootstrap de plan de sondage.
  hh_inference <- hh |>
    dplyr::mutate(
      excise_pc = excise_hh_real / hhsize,
      customs_pc = custom_duty_hh_real / hhsize,
      indirect_other_pc = indirect_other_hh_real / hhsize
    )
  inference_specs <- tibble::tribble(
    ~indicateur, ~variable, ~seed,
    "Kakwani accises", "excise_pc", 20240918L,
    "Kakwani droits de douane", "customs_pc", 20240919L,
    "Kakwani accises + douane", "indirect_other_pc", 20240920L
  )
  inference <- purrr::pmap_dfr(
    inference_specs,
    function(indicateur, variable, seed) {
      boot <- bootstrap_kakwani(
        hh_inference, variable, "yd_pc", "pcweight",
        cluster_var = "grappe", strata_var = "strata",
        reps = 500, seed = seed
      )
      tibble::tibble(
        indicateur = indicateur,
        estimation = kakwani_index(
          hh_inference[[variable]], hh_inference$yd_pc,
          hh_inference$pcweight
        ),
        ic95_bas = boot$lo,
        ic95_haut = boot$hi,
        ecart_type = boot$sd,
        repetitions_valides = boot$reps_ok,
        methode = boot$method
      )
    }
  )
  export_excel(
    inference,
    file.path(paths$TABLES, "17", "17_03_kakwani_inference.xlsx")
  )

  # 4. Validation macroéconomique.
  simulation_groupes <- tibble::tibble(
    agregat_simulation = c(
      "Accises - alcool", "Accises - tabac", "Accises - carburants",
      "Accises - boissons non alcoolisées", "Accises - cosmétiques",
      "Accises - total", "Droits de douane"
    ),
    simulation_2021_fcfa = c(
      sum(hh$excise_alcohol_hh * hh$hhweight),
      sum(hh$excise_tobacco_hh * hh$hhweight),
      sum(hh$excise_fuel_hh * hh$hhweight),
      sum(hh$excise_non_alcohol_hh * hh$hhweight),
      sum(hh$excise_cosmetics_hh * hh$hhweight),
      sum(hh$excise_hh * hh$hhweight),
      sum(hh$custom_duty_hh * hh$hhweight)
    ),
    reference_2021_fcfa = c(
      sum(macro_refs$reference_2021_fcfa[
        macro_refs$agregat %in% c(
          "Boissons alcoolisées - régime intérieur",
          "Alcools à l'importation"
        )
      ]),
      sum(macro_refs$reference_2021_fcfa[
        macro_refs$agregat %in% c(
          "Tabacs - régime intérieur",
          "Tabacs à l'importation - taxe spéciale"
        )
      ]),
      macro_refs$reference_2021_fcfa[
        macro_refs$agregat == "TSU produits pétroliers"
      ],
      macro_refs$reference_2021_fcfa[
        macro_refs$agregat == "Boissons non alcoolisées - régime intérieur"
      ],
      macro_refs$reference_2021_fcfa[
        macro_refs$agregat == "Autres accises intérieures"
      ],
      sum(macro_refs$reference_2021_fcfa[
        macro_refs$agregat %in% c(
          "Tabacs - régime intérieur",
          "Boissons non alcoolisées - régime intérieur",
          "Boissons alcoolisées - régime intérieur",
          "Alcools à l'importation",
          "Tabacs à l'importation - taxe spéciale",
          "Autres accises intérieures",
          "TSU produits pétroliers"
        )
      ]),
      macro_refs$reference_2021_fcfa[
        macro_refs$agregat == "Droits de douane"
      ]
    ),
    comparabilite = c(
      "Ménages et postes EHCVM identifiables; la référence couvre toutes les ventes et importations.",
      "Le taux micro inclut les taxes sport/sida; la référence d'importation ne reprend que le compte recouvré 71767.",
      "Les achats directs des ménages sont un sous-champ de la TSU, payée aussi par les entreprises et administrations.",
      "Postes de boissons identifiables dans l'EHCVM.",
      "Seulement deux postes cosmétiques; la référence 'autres accises' est plus large.",
      "Somme des références comparables, non cible de calage.",
      "Ménages seulement; la référence couvre toutes les importations. Redevance statistique exclue des deux côtés."
    )
  ) |>
    dplyr::mutate(
      simulation_milliards = simulation_2021_fcfa / 1e9,
      reference_milliards = reference_2021_fcfa / 1e9,
      ratio_simulation_reference_pct =
        100 * simulation_2021_fcfa / reference_2021_fcfa,
      source = dplyr::if_else(
        agregat_simulation == "Droits de douane",
        macro_refs$source[macro_refs$agregat == "Droits de douane"],
        macro_refs$source[1]
      )
    )
  tre_macro <- tibble::tibble(
    indicateur = c(
      "Impôts à l'importation du TRE 2023",
      "Importations du TRE 2023",
      "Taux implicite agrégé du TRE 2023",
      "Couverture consommation -> TRE",
      "Couverture consommation -> TEC",
      "Chevauchement TVA évité par la cascade"
    ),
    valeur = c(
      sum(valuation$import_taxes) / 1000,
      sum(valuation$imports) / 1000,
      sum(valuation$import_taxes) / sum(valuation$imports),
      mapping_coverage,
      customs_coverage,
      sum(
        hh$ecart_double_compte_tva_evite_hh * hh$hhweight
      ) / 1e9
    ),
    unite = c(
      "milliards FCFA", "milliards FCFA", "ratio", "ratio", "ratio",
      "milliards FCFA"
    ),
    comparabilite = c(
      "Ensemble de l'économie 2023; inclut davantage que le droit de douane TEC des ménages.",
      "Ensemble de l'économie 2023.",
      "Import_taxes/imports, tous produits et usages.",
      "Part de dépense pondérée reliée aux 48 produits TRE.",
      "Part de dépense pondérée dotée d'une bande TEC, y compris zéros explicites.",
      "Écart avec un retrait naïf de chaque taxe sans décomposer la TVA et l'ordre légal."
    )
  )
  openxlsx::write.xlsx(
    list(
      simulation_vs_budget = as.data.frame(simulation_groupes),
      tre_et_couverture = as.data.frame(tre_macro),
      references_budgetaires = as.data.frame(macro_refs)
    ),
    file = file.path(paths$TABLES, "17", "17_04_macro_validation.xlsx"),
    overwrite = TRUE
  )
  message(
    "  → exported: ",
    file.path(paths$TABLES, "17", "17_04_macro_validation.xlsx")
  )

  # 5. Concordances, taux implicites et décomposition de la cascade.
  mapping_detail <- items |>
    dplyr::mutate(depense_nationale = depan_w * hhweight) |>
    dplyr::group_by(
      codpr, produit, code_TRE, produit_TRE, groupe_accise, taux_accise,
      bande_tec, marge_part, import_share, taux_douane_implicite_tre
    ) |>
    dplyr::summarise(
      depense_nationale = sum(depense_nationale),
      accise_simulee = sum(excise_item * hhweight),
      douane_simulee = sum(duty_item * hhweight),
      ecart_double_compte_tva_evite = sum(
        ecart_double_compte_tva_evite * hhweight
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      ecart_taux_tre_tec = taux_douane_implicite_tre - bande_tec
    ) |>
    dplyr::arrange(dplyr::desc(depense_nationale))
  coverage_diag <- tibble::tibble(
    indicateur = c(
      "Nombre de postes consommés",
      "Postes accisables centraux attendus",
      "Postes accisables centraux observés",
      "Couverture pondérée TRE (%)",
      "Couverture pondérée TEC (%)",
      "Bande TEC minimale",
      "Bande TEC maximale",
      "Part importée minimale",
      "Part importée maximale"
    ),
    valeur = c(
      dplyr::n_distinct(items$codpr),
      length(central_positive),
      sum(central_positive %in% unique(items$codpr)),
      100 * mapping_coverage,
      100 * customs_coverage,
      min(items$bande_tec, na.rm = TRUE),
      max(items$bande_tec, na.rm = TRUE),
      min(items$import_share, na.rm = TRUE),
      max(items$import_share, na.rm = TRUE)
    )
  )
  cascade_diag <- items |>
    dplyr::summarise(
      depense_ttc_hors_marges = sum(base_hors_marges * hhweight),
      accises = sum(excise_item * hhweight),
      droits_douane = sum(duty_item * hhweight),
      retrait_naif = sum(taxes_retrait_naif * hhweight),
      ecart_double_compte_tva_evite = sum(
        ecart_double_compte_tva_evite * hhweight
      )
    )
  openxlsx::write.xlsx(
    list(
      couverture = as.data.frame(coverage_diag),
      detail_codpr = as.data.frame(mapping_detail),
      cascade_tva = as.data.frame(cascade_diag)
    ),
    file = file.path(
      paths$TABLES, "17", "17_05_mapping_diagnostics.xlsx"
    ),
    overwrite = TRUE
  )
  message(
    "  → exported: ",
    file.path(paths$TABLES, "17", "17_05_mapping_diagnostics.xlsx")
  )

  # Figure : taux effectifs des deux nouveaux instruments.
  figure_data <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      Accises = 100 * stats::weighted.mean(eff_excise, pcweight),
      `Droits de douane` = 100 * stats::weighted.mean(
        eff_custom_duty, pcweight
      ),
      .groups = "drop"
    ) |>
    tidyr::pivot_longer(
      -decile, names_to = "instrument", values_to = "taux_effectif"
    )
  fig17 <- ggplot2::ggplot(
    figure_data,
    ggplot2::aes(
      x = factor(decile), y = taux_effectif, fill = instrument
    )
  ) +
    ggplot2::geom_col(width = 0.75) +
    ggplot2::scale_fill_manual(
      values = c("Accises" = "#D95F02", "Droits de douane" = "#1B9E77")
    ) +
    ggplot2::labs(
      title = "Accises et droits de douane par décile",
      subtitle = "Charge directe en pourcentage du revenu disponible — EHCVM 2021",
      x = "Décile de revenu disponible par tête (D1 = plus pauvre)",
      y = "Taux effectif (%)",
      fill = NULL,
      caption = paste0(
        "TEC CEDEAO, accises 2021 et part importée du TRE national 2023. ",
        "Répercussion intégrale; effets Leontief incorporés non inclus en version 1."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.caption = ggplot2::element_text(size = 7)
    )
  export_fig(
    fig17,
    file.path(paths$FIGS, "fig17_indirect_other_decile.png")
  )

  message(sprintf("  Couverture TRE : %.1f %%", 100 * mapping_coverage))
  message(sprintf("  Couverture TEC : %.1f %%", 100 * customs_coverage))
  message(sprintf(
    "  Masse accises ménages : %.1f milliards FCFA",
    sum(hh$excise_hh * hh$hhweight) / 1e9
  ))
  message(sprintf(
    "  Masse droits de douane ménages : %.1f milliards FCFA",
    sum(hh$custom_duty_hh * hh$hhweight) / 1e9
  ))

  invisible(hh)
}
