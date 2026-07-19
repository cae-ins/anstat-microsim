# 06_01_sensitivity_taxation.R
#
# OBJECTIF :
# Analyse de sensibilite de l'incidence de la TVA aux hypothese alternatives de pass-through effectif,
# fondées sur le cadre de la courbe d'Engel de l'informalite (IEC) de
# Bachas, Gadenne & Jensen (2024, RestUD 91(5)).
#
# TROIS SCENARIOS :
# - Strict  (alpha=1) : pass-through complet, borne superieure theorique
# - S2 (CEI × milieu) : alpha difféencié par COICOP × urbain/rural
# - S3 (CEI × decile) : alpha lineaire selon le rang du decile, par COICOP (profil IEC exogene)
#
# SORTIES :
# - TVA au niveau menage pour chaque scenario
# - Taux de TVA effectif par decile
# - Indices resumés CEQ (Gini, CI, Kakwani, RS) par scenario
# - Intervalles de confiance bootstrap sur Kakwani (500 réplications)
#
# ENTREE :  SILVER/01/conso_clean.parquet   (niveau article)
# SORTIE :  SILVER/06/fiscal_sensitivity_taxation.parquet
#           TABLES/06/06_01_*.xlsx
#
# AUTEUR : Armand Kouakou Djaha, MSc (Stata original)
# Rewrite R : rewrite-r branch

run_sensitivity_taxation <- function(paths) {

  message(">>> ETAPE 6.1 : Analyse de sensibilite — scenarios de taxation")

  df <- load_parquet(file.path(paths$SILVER, "01", "conso_clean.parquet"))

  # ── Validation ───────────────────────────────────────────────────────────
  stopifnot(
    !anyNA(df$hhid), !anyNA(df$hhweight),
    !anyNA(df$depan_w), !anyNA(df$r_vat_official),
    !anyNA(df$coicop), !anyNA(df$milieu)
  )

  # S'assurer que coicop est numerique pour la jointure
  welfare <- load_raw_dta(
    'ehcvm_welfare_2b_CIV2021.dta',
    col_select = c('hhid', 'pcexp', 'hhsize', 'def_spa', 'def_temp')
  )

  df <- df %>%
    dplyr::left_join(welfare, by = 'hhid') %>%
    dplyr::mutate(coicop_num = as.integer(as.character(coicop)))

  # ── SCENARIO 1 : Strict (alpha = 1) ──────────────────────────────────────
  df <- df %>%
    dplyr::mutate(
      vat_item_strict = depan_w * r_vat_official / (1 + r_vat_official)
    )

  # ── SCENARIO 2 : CEI × milieu urbain/rural ──────────────────────────────
  # Source : Bachas et al. (2024) + World Bank WPS 10703 (2024)
  alpha2_tbl <- vat_alpha_milieu_parameters()

  df <- df %>%
    dplyr::left_join(alpha2_tbl, by = "coicop_num") %>%
    dplyr::mutate(
      is_rural = (as.character(milieu) == "Rural"),
      alpha_2  = dplyr::if_else(is_rural, alpha_rural, alpha_urban),
      vat_item_s2 = alpha_2 * vat_item_strict
    ) %>%
    dplyr::select(-alpha_rural, -alpha_urban, -is_rural)

  # ── SCENARIO 3 : CEI × decile (profil IEC exogene, Bachas et al. 2024) ─────────
  # alpha(coicop, d) = alpha_D1 + (d-1) × slope, cap a 1
  # Les pentes refleter l'estimation de Bachas et al. : pente IEC ~-5 a -8 pp par doublement log

# Calculer d'abord la consommation au niveau menage pour l'assignation des deciles
  df <- df %>%
    dplyr::group_by(hhid) %>%
    dplyr::mutate(conso_w_hh = sum(depan_w, na.rm = TRUE)) %>%
    dplyr::ungroup()

  hh_decile <- df %>%
    dplyr::distinct(hhid, pcexp, hhsize, hhweight) %>%
    dplyr::mutate(
      pcweight = hhweight * hhsize,
      decile = weighted_ntile(pcexp, pcweight, n = 10)
    )

  df <- df %>%
    dplyr::left_join(hh_decile %>% dplyr::select(hhid, decile), by = "hhid")

  alpha3_params <- vat_alpha_decile_parameters()

  df <- df %>%
    dplyr::left_join(alpha3_params, by = "coicop_num") %>%
    dplyr::mutate(
      alpha_3     = pmin(alpha_d1 + (decile - 1) * slope, 1),
      vat_item_s3 = alpha_3 * vat_item_strict
    ) %>%
    dplyr::select(-alpha_d1, -slope)

  # ── Diagnostiques : alpha par COICOP × decile ───────────────────────────
  alpha_diag_decile <- df %>%
    dplyr::group_by(coicop_num, decile) %>%
    dplyr::summarise(
      alpha_2 = weighted.mean(alpha_2, hhweight, na.rm = TRUE),
      alpha_3 = weighted.mean(alpha_3, hhweight, na.rm = TRUE),
      .groups = "drop"
    )
  export_excel(alpha_diag_decile,
               file.path(paths$TABLES, "06",
                         "06_01_alpha_diagnostics_coicop_decile.xlsx"))

  alpha_diag_milieu <- df %>%
    dplyr::group_by(coicop_num, milieu) %>%
    dplyr::summarise(
      alpha_2 = weighted.mean(alpha_2, hhweight, na.rm = TRUE),
      .groups = "drop"
    )
  export_excel(alpha_diag_milieu,
               file.path(paths$TABLES, "06",
                         "06_01_alpha_diagnostics_coicop_milieu.xlsx"))

  # ── Agreger au niveau menage ────────────────────────────────────────────
  alpha_profile_decile <- df %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      alpha_s3_moyen_pondere_depense = stats::weighted.mean(
        alpha_3, depan_w * hhweight, na.rm = TRUE
      ),
      depense_ponderee = sum(depan_w * hhweight, na.rm = TRUE),
      .groups = "drop"
    )
  parameter_notes <- tibble::tibble(
    champ = c("nature", "ancrage", "calage ivoirien", "interprétation", "borne"),
    valeur = c(
      "Profil exogène, non estimé sur l'EHCVM",
      "Bachas, Gadenne et Jensen (2024), courbe d'Engel de l'informalité",
      "Aucune cible administrative ou moment ivoirien n'est imposé",
      "Probabilité conjointe de collecte et de transmission à la vente finale",
      "Le scénario strict alpha=1 est la borne de transmission intégrale"
    )
  )
  openxlsx::write.xlsx(
    list(
      parametres_S2 = as.data.frame(alpha2_tbl),
      parametres_S3 = as.data.frame(alpha3_params),
      matrice_S3 = as.data.frame(vat_alpha_decile_matrix()),
      profil_implicite_decile = as.data.frame(alpha_profile_decile),
      notes = as.data.frame(parameter_notes)
    ),
    file = file.path(paths$TABLES, "06", "06_03_vat_informality_parameters.xlsx"),
    overwrite = TRUE
  )
  hh_sens <- df %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(
      hhweight   = dplyr::first(hhweight),
      grappe     = dplyr::first(grappe),
      milieu     = dplyr::first(milieu),
      region     = dplyr::first(region),
      pcexp      = dplyr::first(pcexp),
      hhsize     = dplyr::first(hhsize),
      def_spa    = dplyr::first(def_spa),
      conso_w    = dplyr::first(conso_w_hh),
      decile     = dplyr::first(decile),
      vat_strict = sum(vat_item_strict, na.rm = TRUE),
      vat_s2     = sum(vat_item_s2,     na.rm = TRUE),
      vat_s3     = sum(vat_item_s3,     na.rm = TRUE),
      .groups    = "drop"
    ) %>%
    dplyr::mutate(
      pcweight = hhweight * hhsize,
      strata = paste(as.character(region), as.character(milieu), sep = '_'),
      yd_pc = pcexp,
      yd_hh = pcexp * hhsize,
      vat_strict_real = vat_strict * def_spa,
      vat_s2_real = vat_s2 * def_spa,
      vat_s3_real = vat_s3 * def_spa,
      vat_strict_pc = vat_strict_real / hhsize,
      vat_s2_pc = vat_s2_real / hhsize,
      vat_s3_pc = vat_s3_real / hhsize,
      eff_vat_strict = vat_strict_real / yd_hh,
      eff_vat_s2     = vat_s2_real / yd_hh,
      eff_vat_s3     = vat_s3_real / yd_hh
    )

  save_parquet(hh_sens,
               file.path(paths$SILVER, "06",
                         "fiscal_sensitivity_taxation.parquet"))

  # ── Taux de TVA effectif par decile ──────────────────────────────────────
  rates_by_decile <- hh_sens %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      rate_strict    = weighted.mean(eff_vat_strict, pcweight),
      rate_s2_milieu = weighted.mean(eff_vat_s2,     pcweight),
      rate_s3_iec    = weighted.mean(eff_vat_s3,     pcweight),
      .groups        = "drop"
    )

  export_excel(rates_by_decile,
               file.path(paths$TABLES, "06",
                         "06_01_decile_effective_rates_by_scenario.xlsx"))

  message("  TVA effective par decile et scenario :")
  print(rates_by_decile)

  # ── Indices CEQ par scenario ──────────────────────────────────────────────
  G_market <- weighted_gini(hh_sens$yd_pc, hh_sens$pcweight)

  hh_sens <- hh_sens %>%
    dplyr::mutate(
      consumable_strict = pmax(yd_pc - vat_strict_pc, 0),
      consumable_s2     = pmax(yd_pc - vat_s2_pc, 0),
      consumable_s3     = pmax(yd_pc - vat_s3_pc, 0)
    )

  scenarios <- list(
    list(s = "strict",        desc = "Alpha=1, taxation complete",
         vat = "vat_strict", cons = "consumable_strict"),
    list(s = "s2_milieu",     desc = "CEI x milieu (Bachas 2024 + WB WPS10703)",
         vat = "vat_s2",     cons = "consumable_s2"),
    list(s = "s3_iec_decile", desc = "CEI x decile, profil IEC exogene (Bachas 2024)",
         vat = "vat_s3",     cons = "consumable_s3")
  )

  ceq_summary <- purrr::map_dfr(scenarios, function(x) {
    G_after <- weighted_gini(hh_sens[[x$cons]], hh_sens$pcweight)
    tax_pc <- paste0(x$vat, '_pc')
    C_vat   <- weighted_conindex(hh_sens[[tax_pc]], hh_sens$yd_pc,
                                  hh_sens$pcweight)
    tibble::tibble(
      scenario    = x$s,
      description = x$desc,
      g_market    = G_market,
      g_after     = G_after,
      c_vat       = C_vat,
      kakwani     = C_vat - G_market,
      rs          = G_after - G_market
    )
  })

  message("\n  Resume CEQ :")
  print(ceq_summary)

  save_parquet(ceq_summary,
               file.path(paths$SILVER, "06",
                         "06_01_ceq_summary_scenarios.parquet"))

  # ── Intervalles de confiance bootstrap sur Kakwani (500 rep) ────────────
  message(">>> IC bootstrap sur Kakwani (500 rep)...")

  bs_list <- list(
    list(name = "kak_strict", tax = "vat_strict"),
    list(name = "kak_s2",     tax = "vat_s2"),
    list(name = "kak_s3",     tax = "vat_s3")
  )

  bs_results <- purrr::map_dfr(bs_list, function(x) {
    tax_pc <- paste0(x$tax, '_pc')
    bs <- bootstrap_kakwani(
      data        = hh_sens,
      tax_var     = tax_pc,
      welfare_var = 'yd_pc',
      weight_var  = 'pcweight',
      cluster_var = 'grappe',
      strata_var  = 'strata',
      reps        = 500
    )
    tibble::tibble(
      scenario = x$name,
      mean     = bs$mean,
      lo_95    = bs$lo,
      hi_95    = bs$hi,
      sd       = bs$sd
    )
  })

  message(sprintf("  Kakwani strict : %.4f [%.4f, %.4f]",
                  bs_results$mean[1], bs_results$lo_95[1], bs_results$hi_95[1]))
  message(sprintf("  Kakwani S2     : %.4f [%.4f, %.4f]",
                  bs_results$mean[2], bs_results$lo_95[2], bs_results$hi_95[2]))
  message(sprintf("  Kakwani S3     : %.4f [%.4f, %.4f]",
                  bs_results$mean[3], bs_results$lo_95[3], bs_results$hi_95[3]))

  export_excel(bs_results,
               file.path(paths$TABLES, "06", "06_01_bootstrap_kakwani.xlsx"))

  # ── Annoter le resume CEQ ─────────────────────────────────────────────────
  ceq_annotated <- ceq_summary %>%
    dplyr::mutate(
      progressive        = as.integer(kakwani > 0),
      regressive         = as.integer(kakwani < 0),
      robust_regressive  = as.integer(max(kakwani) < 0),
      robust_progressive = as.integer(min(kakwani) > 0),
      sign_unstable      = as.integer(min(kakwani) < 0 & max(kakwani) > 0),
      kak_strict_ref     = kakwani[scenario == "strict"],
      delta_kakwani_vs_strict = kakwani - kak_strict_ref
    ) %>%
    dplyr::select(-kak_strict_ref)

  export_excel(ceq_annotated,
               file.path(paths$TABLES, "06",
                         "06_01_ceq_summary_scenarios.xlsx"))
  save_parquet(ceq_annotated,
               file.path(paths$SILVER, "06",
                         "06_01_ceq_summary_scenarios.parquet"))

  invisible(hh_sens)
}
