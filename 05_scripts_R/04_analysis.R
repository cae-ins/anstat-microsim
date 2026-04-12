# 04_analysis.R
#
# OBJECTIVE:
# Produce CEQ-style distributive results for VAT incidence.
# Rank households by consumption, compute decile/quintile/milieu/region profiles.
#
# INPUT:  SILVER/03/fiscal_data.parquet
# OUTPUT: TABLES/04/04_*.xlsx
#         SILVER/04/results_by_decile.parquet
#         SILVER/04/fiscal_data_analysis_ready.parquet
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

run_analysis <- function(paths) {

  message(">>> STEP 4: Distributive analysis")

  hh <- load_parquet(file.path(paths$SILVER, "03", "fiscal_data.parquet"))

  # ── Validation ───────────────────────────────────────────────────────────
  stopifnot(
    "Missing hhid"     = !anyNA(hh$hhid),
    "Missing hhweight" = !anyNA(hh$hhweight),
    "Missing conso_w"  = !anyNA(hh$conso_w),
    "Missing vat_w"    = !anyNA(hh$vat_w),
    "conso must be > 0" = all(hh$conso > 0),
    "vat must be >= 0"  = all(hh$vat >= 0)
  )

  # ── Rank households ───────────────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      decile   = weighted_ntile(conso_w, hhweight, n = 10),
      quintile = weighted_ntile(conso_w, hhweight, n = 5)
    )

  # ── Results by decile ─────────────────────────────────────────────────────
  by_decile <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      conso_w  = weighted.mean(conso_w, hhweight),
      vat_w    = weighted.mean(vat_w,   hhweight),
      vat_sum  = sum(vat_w * hhweight),
      .groups  = "drop"
    ) %>%
    dplyr::mutate(vat_share_decile = vat_sum / sum(vat_sum))

  export_excel(by_decile,
               file.path(paths$TABLES, "04", "04_main_results_by_decile.xlsx"))
  save_parquet(by_decile,
               file.path(paths$SILVER, "04", "results_by_decile.parquet"))

  # ── Results by quintile ───────────────────────────────────────────────────
  by_quintile <- hh %>%
    dplyr::group_by(quintile) %>%
    dplyr::summarise(
      conso_w = weighted.mean(conso_w, hhweight),
      vat_w   = weighted.mean(vat_w,   hhweight),
      vat_sum = sum(vat_w * hhweight),
      .groups = "drop"
    ) %>%
    dplyr::mutate(vat_share_quintile = vat_sum / sum(vat_sum))

  export_excel(by_quintile,
               file.path(paths$TABLES, "04", "04_main_results_by_quintile.xlsx"))

  # ── Results by milieu (urban/rural) ──────────────────────────────────────
  by_milieu <- hh %>%
    dplyr::group_by(milieu) %>%
    dplyr::summarise(
      conso_w = weighted.mean(conso_w, hhweight),
      vat_w   = weighted.mean(vat_w,   hhweight),
      vat_sum = sum(vat_w * hhweight),
      .groups = "drop"
    ) %>%
    dplyr::mutate(vat_share_milieu = vat_sum / sum(vat_sum))

  export_excel(by_milieu,
               file.path(paths$TABLES, "04", "04_results_by_milieu.xlsx"))

  # ── Results by region ─────────────────────────────────────────────────────
  by_region <- hh %>%
    dplyr::group_by(region) %>%
    dplyr::summarise(
      conso_w = weighted.mean(conso_w, hhweight),
      vat_w   = weighted.mean(vat_w,   hhweight),
      vat_sum = sum(vat_w * hhweight),
      .groups = "drop"
    ) %>%
    dplyr::mutate(vat_share_region = vat_sum / sum(vat_sum)) %>%
    dplyr::arrange(dplyr::desc(vat_w))

  export_excel(by_region,
               file.path(paths$TABLES, "04", "04_results_by_region.xlsx"))

  # ── Save enriched dataset ─────────────────────────────────────────────────
  save_parquet(hh,
               file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet"))

  message("  Effective VAT by decile:")
  print(
    hh %>%
      dplyr::group_by(decile) %>%
      dplyr::summarise(eff_vat_w = weighted.mean(eff_vat_w, hhweight),
                       .groups = "drop")
  )

  invisible(hh)
}
