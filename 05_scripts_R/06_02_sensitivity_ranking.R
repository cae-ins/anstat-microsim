# 06_02_sensitivity_ranking.R
#
# OBJECTIVE:
# Sensitivity analysis of VAT incidence to alternative welfare rankings.
# The baseline ranking uses total household consumption. Here we also test:
#   - consumption per capita (conso_pc)
#   - consumption per adult equivalent — FAO scale 1 (conso_ae1)
#   - consumption per adult equivalent — scale 2 (conso_ae2)
#
# OUTPUT:
#   - Effective VAT rates by decile under each ranking × scenario combination
#   - CEQ summary indices (Gini, CI, Kakwani, RS) per ranking × scenario
#
# INPUT:  SILVER/06/fiscal_sensitivity_taxation.parquet
#         DATA/ehcvm_welfare_civ2021.dta
# OUTPUT: TABLES/06/06_02_*.xlsx
#         SILVER/06/06_02_ceq_rankings.parquet
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

run_sensitivity_ranking <- function(paths) {

  message(">>> STEP 6.2: Sensitivity analysis — welfare rankings")

  hh_sens <- load_parquet(
    file.path(paths$SILVER, "06", "fiscal_sensitivity_taxation.parquet")
  )

  # ── Merge welfare variables ───────────────────────────────────────────────
  welfare_data <- haven::read_dta(
    file.path(paths$DATA, "ehcvm_welfare_civ2021.dta"),
    col_select = c("hhid", "eqadu1", "eqadu2", "hgender", "hage",
                   "hmstat", "heduc", "halfa2", "halfa", "hbranch",
                   "pcexp", "zref", "hhsize")
  )

  hh <- hh_sens %>%
    dplyr::left_join(welfare_data, by = "hhid")

  # ── Welfare concepts ──────────────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      conso_pc  = conso_w / hhsize,
      conso_ae1 = conso_w / eqadu1,
      conso_ae2 = conso_w / eqadu2
    )

  # ── Decile rankings ───────────────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      decile_total = weighted_ntile(conso_w,   hhweight, n = 10),
      decile_pc    = weighted_ntile(conso_pc,  hhweight, n = 10),
      decile_ae1   = weighted_ntile(conso_ae1, hhweight, n = 10),
      decile_ae2   = weighted_ntile(conso_ae2, hhweight, n = 10)
    )

  # ── Effective VAT by ranking × scenario ───────────────────────────────────
  for (rank in c("total", "pc", "ae1", "ae2")) {
    dcol <- paste0("decile_", rank)
    out  <- hh %>%
      dplyr::rename(decile = !!dcol) %>%
      dplyr::group_by(decile) %>%
      dplyr::summarise(
        eff_vat_strict = weighted.mean(eff_vat_strict, hhweight),
        eff_vat_s2     = weighted.mean(eff_vat_s2,     hhweight),
        eff_vat_s3     = weighted.mean(eff_vat_s3,     hhweight),
        .groups        = "drop"
      )
    export_excel(out,
                 file.path(paths$TABLES, "06",
                           paste0("06_02_eff_vat_", rank, ".xlsx")))
  }

  # ── CEQ summary per ranking × scenario ────────────────────────────────────
  # For each ranking, VAT burden is scaled to per-unit welfare concept
  rankings <- list(
    total = list(welfare = "conso_w",   divisor = NA),
    pc    = list(welfare = "conso_pc",  divisor = "hhsize"),
    ae1   = list(welfare = "conso_ae1", divisor = "eqadu1"),
    ae2   = list(welfare = "conso_ae2", divisor = "eqadu2")
  )

  ceq_rankings <- purrr::map_dfr(names(rankings), function(rank) {
    r   <- rankings[[rank]]
    wel <- hh[[r$welfare]]

    G_mkt <- weighted_gini(wel, hh$hhweight)

    purrr::map_dfr(c("strict", "s2", "s3"), function(s) {
      vat_raw <- hh[[paste0("vat_", s)]]
      vat_adj <- if (is.na(r$divisor)) {
        vat_raw
      } else {
        vat_raw / hh[[r$divisor]]
      }
      cons_adj <- wel - vat_adj

      G_after <- weighted_gini(cons_adj, hh$hhweight)
      C_vat   <- weighted_conindex(vat_adj, wel, hh$hhweight)

      tibble::tibble(
        ranking  = rank,
        scenario = s,
        g_market = G_mkt,
        g_after  = G_after,
        c_vat    = C_vat,
        kakwani  = C_vat - G_mkt,
        rs       = G_after - G_mkt
      )
    })
  })

  message("\n  CEQ summary by ranking and scenario:")
  print(ceq_rankings)

  save_parquet(ceq_rankings,
               file.path(paths$SILVER, "06", "06_02_ceq_rankings.parquet"))
  export_excel(ceq_rankings,
               file.path(paths$TABLES, "06", "06_02_ceq_rankings.xlsx"))

  invisible(ceq_rankings)
}
