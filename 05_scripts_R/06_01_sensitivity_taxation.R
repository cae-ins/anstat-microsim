# 06_01_sensitivity_taxation.R
#
# OBJECTIVE:
# Sensitivity analysis of VAT incidence to alternative effective pass-through
# assumptions, grounded in the Informality Engel Curve (IEC) framework of
# Bachas, Gadenne & Jensen (2024, RestUD 91(5)).
#
# THREE SCENARIOS:
# - Strict  (alpha=1): full pass-through, theoretical upper bound
# - S2 (CEI × milieu): alpha differentiated by COICOP × urban/rural
# - S3 (CEI × decile): alpha linear in decile rank, by COICOP (IEC calibrated)
#
# OUTPUTS:
# - household-level VAT under each scenario
# - effective VAT rates by decile
# - CEQ summary indices (Gini, CI, Kakwani, RS) per scenario
# - Bootstrap confidence intervals on Kakwani (500 reps)
#
# INPUT:  SILVER/01/conso_clean.parquet   (item-level)
# OUTPUT: SILVER/06/fiscal_sensitivity_taxation.parquet
#         TABLES/06/06_01_*.xlsx
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

run_sensitivity_taxation <- function(paths) {

  message(">>> STEP 6.1: Sensitivity analysis — taxation scenarios")

  df <- load_parquet(file.path(paths$SILVER, "01", "conso_clean.parquet"))

  # ── Validation ────────────────────────────────────────────────────────────
  stopifnot(
    !anyNA(df$hhid), !anyNA(df$hhweight),
    !anyNA(df$depan_w), !anyNA(df$r_vat_official),
    !anyNA(df$coicop), !anyNA(df$milieu)
  )

  # Ensure coicop is numeric for join
  df <- df %>%
    dplyr::mutate(coicop_num = as.integer(as.character(coicop)))

  # ── SCENARIO 1: Strict (alpha = 1) ───────────────────────────────────────
  df <- df %>%
    dplyr::mutate(vat_item_strict = depan_w * r_vat_official)

  # ── SCENARIO 2: CEI × milieu urbain/rural ────────────────────────────────
  # Source: Bachas et al. (2024) + World Bank WPS 10703 (2024)
  alpha2_tbl <- tibble::tribble(
    ~coicop_num, ~alpha_rural, ~alpha_urban,
    1L,  0.18, 0.42,   # food/bev       : most informal, strong milieu gap
    2L,  0.55, 0.72,   # alcohol/tobacco: more formal chain
    3L,  0.28, 0.52,   # clothing       : mix formal/informal boutiques
    4L,  0.68, 0.84,   # housing/util.  : utilities near-formal (CIE/SODECI)
    5L,  0.28, 0.48,   # furnishings    : artisanal in rural areas
    6L,  0.38, 0.66,   # health         : private clinics vs traditional
    7L,  0.32, 0.62,   # transport      : informal taxis dominate
    8L,  0.82, 0.94,   # info/comm      : near-fully formal (licensed ops)
    9L,  0.35, 0.58,   # recreation     : small share, mix
    10L, 0.62, 0.78,   # education      : registered schools more urban
    11L, 0.18, 0.52,   # restaurants    : highly informal (maquis, gargotes)
    12L, 0.88, 0.95,   # insurance      : formal by definition
    13L, 0.22, 0.48,   # personal care  : hair salons, barbers — high IEC
    98L, 0.00, 0.00,   # non-consumption
    99L, 0.00, 0.00    # non-consumption
  )

  df <- df %>%
    dplyr::left_join(alpha2_tbl, by = "coicop_num") %>%
    dplyr::mutate(
      is_rural = (as.character(milieu) == "Rural"),
      alpha_2  = dplyr::if_else(is_rural, alpha_rural, alpha_urban),
      vat_item_s2 = alpha_2 * vat_item_strict
    ) %>%
    dplyr::select(-alpha_rural, -alpha_urban, -is_rural)

  # ── SCENARIO 3: CEI × decile (IEC calibrated, Bachas et al. 2024) ────────
  # alpha(coicop, d) = alpha_D1 + (d-1) × slope, capped at 1
  # Slopes reflect Bachas et al. estimate: IEC slope ~-5 to -8 pp per log-doubling

  # First compute household-level consumption for decile assignment
  df <- df %>%
    dplyr::group_by(hhid) %>%
    dplyr::mutate(conso_w_hh = sum(depan_w, na.rm = TRUE)) %>%
    dplyr::ungroup()

  hh_decile <- df %>%
    dplyr::distinct(hhid, conso_w_hh, hhweight) %>%
    dplyr::mutate(decile = weighted_ntile(conso_w_hh, hhweight, n = 10))

  df <- df %>%
    dplyr::left_join(hh_decile %>% dplyr::select(hhid, decile), by = "hhid")

  alpha3_params <- tibble::tribble(
    ~coicop_num, ~alpha_d1, ~slope,
    1L,  0.12, 0.034,   # food/bev       : steepest IEC (D1→0.12, D10→0.42)
    2L,  0.48, 0.024,   # alcohol/tobacco: flatter IEC
    3L,  0.22, 0.030,   # clothing
    4L,  0.62, 0.022,   # housing/util.  : flattest (formal regardless)
    5L,  0.22, 0.028,   # furnishings
    6L,  0.30, 0.040,   # health         : steep (private clinics at top)
    7L,  0.25, 0.038,   # transport      : poor=informal taxis, rich=cars
    8L,  0.78, 0.015,   # info/comm      : near-flat, formal at all deciles
    9L,  0.28, 0.032,   # recreation
    10L, 0.55, 0.025,   # education
    11L, 0.12, 0.038,   # restaurants    : same IEC profile as food/bev
    12L, 0.85, 0.010,   # insurance      : near-formal throughout
    13L, 0.15, 0.034,   # personal care  : steep IEC (informal salons)
    98L, 0.00, 0.000,
    99L, 0.00, 0.000
  )

  df <- df %>%
    dplyr::left_join(alpha3_params, by = "coicop_num") %>%
    dplyr::mutate(
      alpha_3     = pmin(alpha_d1 + (decile - 1) * slope, 1),
      vat_item_s3 = alpha_3 * vat_item_strict
    ) %>%
    dplyr::select(-alpha_d1, -slope)

  # ── Diagnostics: alpha by COICOP × decile ────────────────────────────────
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

  # ── Aggregate to household level ──────────────────────────────────────────
  hh_sens <- df %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(
      hhweight   = dplyr::first(hhweight),
      milieu     = dplyr::first(milieu),
      region     = dplyr::first(region),
      conso_w    = dplyr::first(conso_w_hh),
      decile     = dplyr::first(decile),
      vat_strict = sum(vat_item_strict, na.rm = TRUE),
      vat_s2     = sum(vat_item_s2,     na.rm = TRUE),
      vat_s3     = sum(vat_item_s3,     na.rm = TRUE),
      .groups    = "drop"
    ) %>%
    dplyr::mutate(
      eff_vat_strict = vat_strict / conso_w,
      eff_vat_s2     = vat_s2     / conso_w,
      eff_vat_s3     = vat_s3     / conso_w
    )

  save_parquet(hh_sens,
               file.path(paths$SILVER, "06",
                         "fiscal_sensitivity_taxation.parquet"))

  # ── Effective VAT rates by decile ─────────────────────────────────────────
  rates_by_decile <- hh_sens %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      rate_strict    = weighted.mean(eff_vat_strict, hhweight),
      rate_s2_milieu = weighted.mean(eff_vat_s2,     hhweight),
      rate_s3_iec    = weighted.mean(eff_vat_s3,     hhweight),
      .groups        = "drop"
    )

  export_excel(rates_by_decile,
               file.path(paths$TABLES, "06",
                         "06_01_decile_effective_rates_by_scenario.xlsx"))

  message("  Effective VAT by decile and scenario:")
  print(rates_by_decile)

  # ── CEQ indices per scenario ───────────────────────────────────────────────
  G_market <- weighted_gini(hh_sens$conso_w, hh_sens$hhweight)

  hh_sens <- hh_sens %>%
    dplyr::mutate(
      market_income     = conso_w,
      consumable_strict = conso_w - vat_strict,
      consumable_s2     = conso_w - vat_s2,
      consumable_s3     = conso_w - vat_s3
    )

  scenarios <- list(
    list(s = "strict",        desc = "Alpha=1, full taxation",
         vat = "vat_strict", cons = "consumable_strict"),
    list(s = "s2_milieu",     desc = "CEI x milieu (Bachas 2024 + WB WPS10703)",
         vat = "vat_s2",     cons = "consumable_s2"),
    list(s = "s3_iec_decile", desc = "CEI x decile, IEC calibree (Bachas 2024)",
         vat = "vat_s3",     cons = "consumable_s3")
  )

  ceq_summary <- purrr::map_dfr(scenarios, function(x) {
    G_after <- weighted_gini(hh_sens[[x$cons]], hh_sens$hhweight)
    C_vat   <- weighted_conindex(hh_sens[[x$vat]], hh_sens$conso_w,
                                  hh_sens$hhweight)
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

  message("\n  CEQ summary:")
  print(ceq_summary)

  save_parquet(ceq_summary,
               file.path(paths$SILVER, "06",
                         "06_01_ceq_summary_scenarios.parquet"))

  # ── Bootstrap confidence intervals on Kakwani (500 reps) ─────────────────
  message(">>> Bootstrap CIs on Kakwani (500 reps)...")

  bs_list <- list(
    list(name = "kak_strict", tax = "vat_strict"),
    list(name = "kak_s2",     tax = "vat_s2"),
    list(name = "kak_s3",     tax = "vat_s3")
  )

  bs_results <- purrr::map_dfr(bs_list, function(x) {
    bs <- bootstrap_kakwani(
      data        = hh_sens,
      tax_var     = x$tax,
      welfare_var = "conso_w",
      weight_var  = "hhweight",
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

  # ── Annotate CEQ summary ──────────────────────────────────────────────────
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
