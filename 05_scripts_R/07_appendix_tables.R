# 07_appendix_tables.R
#
# OBJECTIF :
# Tableaux supplementaires pour l'annexe et la documentation de robustesse.
#
# CONTENU :
# - Profils deciles et quintiles etendus
# - Decomposition de la TVA par categorie COICOP
# - Repartitions regionales et rural/urbain
# - Diagnostiques basiques de qualite des donnees
#
# ENTREE :  SILVER/04/fiscal_data_analysis_ready.parquet
#           SILVER/01/conso_clean.parquet
# SORTIE :  TABLES/07/07_*.xlsx
#
# AUTEUR : Armand Kouakou Djaha, MSc (Stata original)
# Rewrite R : rewrite-r branch

run_appendix_tables <- function(paths) {

  message(">>> ETAPE 7 : Tableaux d'annexe")

  hh <- load_parquet(
    file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  )

  # ── Extended decile profile ───────────────────────────────────────────────
  decile_detail <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      conso_w      = weighted.mean(conso_w,  hhweight),
      vat_w        = weighted.mean(vat_w,    hhweight),
      eff_vat      = weighted.mean(eff_vat_w, hhweight),
      median_conso = weighted_quantile(conso_w, hhweight, 0.50),
      p10_conso    = weighted_quantile(conso_w, hhweight, 0.10),
      p90_conso    = weighted_quantile(conso_w, hhweight, 0.90),
      vat_sum      = sum(vat_w * hhweight),
      .groups      = "drop"
    ) %>%
    dplyr::mutate(vat_share = vat_sum / sum(vat_sum))

  export_excel(decile_detail,
               file.path(paths$TABLES, "07", "07_decile_detailed.xlsx"))

  # ── Extended quintile profile ─────────────────────────────────────────────
  quintile_detail <- hh %>%
    dplyr::group_by(quintile) %>%
    dplyr::summarise(
      conso_w = weighted.mean(conso_w,  hhweight),
      vat_w   = weighted.mean(vat_w,    hhweight),
      eff_vat = weighted.mean(eff_vat_w, hhweight),
      vat_sum = sum(vat_w * hhweight),
      .groups = "drop"
    ) %>%
    dplyr::mutate(vat_share = vat_sum / sum(vat_sum))

  export_excel(quintile_detail,
               file.path(paths$TABLES, "07", "07_quintile_detailed.xlsx"))

  # ── VAT decomposition by COICOP ───────────────────────────────────────────
  conso_item <- load_parquet(
    file.path(paths$SILVER, "01", "conso_clean.parquet")
  ) %>%
    dplyr::mutate(vat_item_w = depan_w * r_vat_official)

  vat_coicop <- conso_item %>%
    dplyr::group_by(coicop) %>%
    dplyr::summarise(
      vat_w   = sum(vat_item_w * hhweight, na.rm = TRUE),
      conso_w = sum(depan_w    * hhweight, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(vat_rate_coicop = vat_w / conso_w)

  export_excel(vat_coicop,
               file.path(paths$TABLES, "07", "07_vat_by_coicop.xlsx"))

  # ── Regional breakdown ────────────────────────────────────────────────────
  region_detail <- hh %>%
    dplyr::group_by(region) %>%
    dplyr::summarise(
      conso_w = weighted.mean(conso_w,   hhweight),
      vat_w   = weighted.mean(vat_w,     hhweight),
      eff_vat = weighted.mean(eff_vat_w, hhweight),
      vat_sum = sum(vat_w * hhweight),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(eff_vat))

  export_excel(region_detail,
               file.path(paths$TABLES, "07", "07_region_detailed.xlsx"))

  # ── Rural/Urban breakdown ─────────────────────────────────────────────────
  milieu_detail <- hh %>%
    dplyr::group_by(milieu) %>%
    dplyr::summarise(
      conso_w      = weighted.mean(conso_w,   hhweight),
      vat_w        = weighted.mean(vat_w,     hhweight),
      eff_vat      = weighted.mean(eff_vat_w, hhweight),
      median_conso = weighted_quantile(conso_w, hhweight, 0.50),
      .groups      = "drop"
    )

  export_excel(milieu_detail,
               file.path(paths$TABLES, "07", "07_milieu_detailed.xlsx"))

  # ── Data quality diagnostics ──────────────────────────────────────────────
  message("\n  n_items distribution:")
  print(summary(hh$n_items))

  message("  eff_vat distribution:")
  print(summary(hh$eff_vat_w))

  n_high_vat <- sum(hh$eff_vat_w > 0.20, na.rm = TRUE)
  message(sprintf("  Households with eff_vat_w > 20%%: %d (%.1f%%)",
                  n_high_vat, 100 * n_high_vat / nrow(hh)))

  message(">>> Appendix tables successfully generated")
  invisible(NULL)
}
