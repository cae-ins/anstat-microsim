# 05_progressivity.R
#
# OBJECTIF :
# Mesurer la progressivite de la TVA avec les indices de concentration de type CEQ.
#
# INDICES :
# - Gini (consommation pre- et post-taxe)
# - Indice de concentration CI(TVA)
# - Kakwani = CI(TVA) - Gini(pre-tax)
# - Reynolds-Smolensky = Gini_avant - Gini_apres (convention CEQ)
#
# COURBES :
# - Courbe de Lorenz (groupee, par decile)
# - Courbe de concentration de la TVA (groupee, par decile)
#
# ENTREE :  SILVER/04/fiscal_data_analysis_ready.parquet
# SORTIE :  TABLES/05/05_progressivity.xlsx
#           TABLES/05/05_lorenz_grouped_consumption.xlsx
#           TABLES/05/05_concentration_grouped_vat.xlsx
#           SILVER/05/05_progressivity.parquet
#
# AUTEUR : Armand Kouakou Djaha, MSc (Stata original)
# Rewrite R : rewrite-r branch

run_progressivity <- function(paths) {

  message(">>> ETAPE 5 : Analyse de progressivite")

  hh <- load_parquet(
    file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  )

  # ── Indices CEQ ───────────────────────────────────────────────────────────
  G_market  <- weighted_gini(hh$yd_pc, hh$pcweight)
  G_consump <- weighted_gini(pmax(hh$yc_pc_vat, 0), hh$pcweight)
  C_vat     <- weighted_conindex(
    hh$vat_w_real / hh$hhsize, hh$yd_pc, hh$pcweight
  )
  Kakwani   <- C_vat - G_market
  RS        <- G_market - G_consump

  message("--------------------------------")
  message(sprintf("Gini avant   = %.4f", G_market))
  message(sprintf("Gini apres   = %.4f", G_consump))
  message(sprintf("C(TVA)       = %.4f", C_vat))
  message(sprintf("Kakwani      = %.4f", Kakwani))
  message(sprintf("Reynolds-S.  = %.4f", RS))
  message("--------------------------------")

  ceq_result <- tibble::tibble(
    scenario    = "baseline",
    description = "Systeme TVA — taux officiels, pass-through strict",
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

  # ── Courbe de Lorenz (groupee, par decile) ────────────────────────────────
  lorenz <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      conso_sum = sum(yd_pc * pcweight),
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

  # ── Courbe de concentration de la TVA (groupee, par decile) ───────────
  concentration <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      vat_sum = sum((vat_w_real / hhsize) * pcweight),
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
