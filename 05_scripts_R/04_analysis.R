# 04_analysis.R
#
# OBJECTIF :
# Produire des resultats distributifs de type CEQ pour l'incidence de la TVA.
# Ranger les menages par consommation, calculer les profils par decile/quintile/milieu/region.
#
# ENTREE :  SILVER/03/fiscal_data.parquet
# SORTIE :  TABLES/04/04_*.xlsx
#           SILVER/04/results_by_decile.parquet
#           SILVER/04/fiscal_data_analysis_ready.parquet
#
# AUTEUR : Armand Kouakou Djaha, MSc (Stata original)
# Rewrite R : rewrite-r branch

run_analysis <- function(paths) {

  message(">>> ETAPE 4 : Analyse distributive")

  hh <- load_parquet(file.path(paths$SILVER, "03", "fiscal_data.parquet"))

  # ── Validation ───────────────────────────────────────────────────────────
  stopifnot(
    "hhid manquant"     = !anyNA(hh$hhid),
    "hhweight manquant" = !anyNA(hh$hhweight),
    "conso_w manquant"  = !anyNA(hh$conso_w),
    "vat_w manquant"    = !anyNA(hh$vat_w),
    "conso doit etre > 0" = all(hh$conso > 0),
    "vat doit etre >= 0"  = all(hh$vat >= 0)
  )

  # ── Classement des menages ───────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      decile   = weighted_ntile(conso_w, hhweight, n = 10),
      quintile = weighted_ntile(conso_w, hhweight, n = 5)
    )

  # ── Resultats par decile ─────────────────────────────────────────────────
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

  # ── Resultats par quintile ───────────────────────────────────────────────
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

  # ── Resultats par milieu (urbain/rural) ─────────────────────────────────
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

  # ── Resultats par region ─────────────────────────────────────────────────
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

  # ── Sauvegarder le jeu de donne enrichi ──────────────────────────────────
  save_parquet(hh,
               file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet"))

  message("  TVA effective par decile :")
  print(
    hh %>%
      dplyr::group_by(decile) %>%
      dplyr::summarise(eff_vat_w = weighted.mean(eff_vat_w, hhweight),
                       .groups = "drop")
  )

  invisible(hh)
}
