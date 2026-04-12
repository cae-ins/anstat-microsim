# 05_progressivity.R
#
# OBJECTIVE:
# Measure VAT progressivity with CEQ-style concentration indices.
#
# INDICES:
# - Gini (pre- and post-tax consumption)
# - Concentration index CI(VAT)
# - Kakwani = CI(VAT) - Gini(pre-tax)
# - Reynolds-Smolensky = Gini_after - Gini_before
#
# CURVES:
# - Lorenz curve (grouped, by decile)
# - Concentration curve of VAT (grouped, by decile)
#
# INPUT:  SILVER/04/fiscal_data_analysis_ready.parquet
# OUTPUT: TABLES/05/05_progressivity.xlsx
#         TABLES/05/05_lorenz_grouped_consumption.xlsx
#         TABLES/05/05_concentration_grouped_vat.xlsx
#         SILVER/05/05_progressivity.parquet
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

run_progressivity <- function(paths) {

  message(">>> STEP 5: Progressivity analysis")

  hh <- load_parquet(
    file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  )

  # ── CEQ indices ───────────────────────────────────────────────────────────
  G_market  <- weighted_gini(hh$conso_w,           hh$hhweight)
  G_consump <- weighted_gini(hh$consumable_income,  hh$hhweight)
  C_vat     <- weighted_conindex(hh$vat_w, hh$conso_w, hh$hhweight)
  Kakwani   <- C_vat - G_market
  RS        <- G_consump - G_market

  message("--------------------------------")
  message(sprintf("Gini before  = %.4f", G_market))
  message(sprintf("Gini after   = %.4f", G_consump))
  message(sprintf("C(VAT)       = %.4f", C_vat))
  message(sprintf("Kakwani      = %.4f", Kakwani))
  message(sprintf("Reynolds-S.  = %.4f", RS))
  message("--------------------------------")

  ceq_result <- tibble::tibble(
    scenario    = "baseline",
    description = "VAT system — official rates, strict pass-through",
    g_market    = G_market,
    g_after     = G_consump,
    c_vat       = C_vat,
    kakwani     = Kakwani,
    rs          = RS
  )

  save_parquet(ceq_result,
               file.path(paths$SILVER, "05", "05_progressivity.parquet"))
  export_excel(ceq_result,
               file.path(paths$TABLES, "05", "05_progressivity.xlsx"))

  # ── Lorenz curve (grouped, by decile) ────────────────────────────────────
  lorenz <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      conso_sum = sum(conso_w * hhweight),
      .groups   = "drop"
    ) %>%
    dplyr::arrange(decile) %>%
    dplyr::mutate(
      conso_share     = conso_sum / sum(conso_sum),
      cum_conso_share = cumsum(conso_share),
      pop_share       = dplyr::row_number() / dplyr::n()
    ) %>%
    tibble::add_row(
      decile = 0, conso_sum = 0, conso_share = 0,
      cum_conso_share = 0, pop_share = 0,
      .before = 1
    )

  export_excel(lorenz,
               file.path(paths$TABLES, "05", "05_lorenz_grouped_consumption.xlsx"))

  # ── Concentration curve of VAT (grouped, by decile) ──────────────────────
  concentration <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      vat_sum = sum(vat_w * hhweight),
      .groups = "drop"
    ) %>%
    dplyr::arrange(decile) %>%
    dplyr::mutate(
      vat_share     = vat_sum / sum(vat_sum),
      cum_vat_share = cumsum(vat_share),
      pop_share     = dplyr::row_number() / dplyr::n()
    ) %>%
    tibble::add_row(
      decile = 0, vat_sum = 0, vat_share = 0,
      cum_vat_share = 0, pop_share = 0,
      .before = 1
    )

  export_excel(concentration,
               file.path(paths$TABLES, "05", "05_concentration_grouped_vat.xlsx"))

  invisible(ceq_result)
}
