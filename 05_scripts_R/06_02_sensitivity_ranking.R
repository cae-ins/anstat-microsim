# 06_02_sensitivity_ranking.R
#
# OBJECTIF :
# Analyse de sensibilite de l'incidence de la TVA aux classements alternatifs de bien-etre.
# Le classement de base utilise la consommation totale du menage. Ici, nous testons aussi :
#   - consommation par habitant (conso_pc)
#   - consommation par adulte equivalent — echelle FAO 1 (conso_ae1)
#   - consommation par adulte equivalent — echelle 2 (conso_ae2)
#
# SORTIE :
#   - Taux de TVA effectif par decile sous chaque combinaison classement × scenario
#   - Indices resumes CEQ (Gini, CI, Kakwani, RS) par classement × scenario
#
# ENTREE :  SILVER/06/fiscal_sensitivity_taxation.parquet
#           DATA/ehcvm_welfare_2b_CIV2021.dta
# SORTIE :  TABLES/06/06_02_*.xlsx
#           SILVER/06/06_02_ceq_rankings.parquet
#
# AUTEUR : Armand Kouakou Djaha, MSc (Stata original)
# Rewrite R : rewrite-r branch

run_sensitivity_ranking <- function(paths) {

  message(">>> ETAPE 6.2 : Analyse de sensibilite — classements de bien-etre")

  hh_sens <- load_parquet(
    file.path(paths$SILVER, "06", "fiscal_sensitivity_taxation.parquet")
  )

# ── Fusionner les variables de bien-etre ─────────────────────────────────
  # Les variables pcexp, zref et hhsize sont déjà présentes dans la base de
  # sensibilité. Ne joindre que les deux échelles d'équivalent-adulte évite la
  # création silencieuse de colonnes .x/.y lors d'une exécution depuis l'étape 1.
  welfare_data <- load_raw_dta(
    "ehcvm_welfare_2b_CIV2021.dta",
    col_select = c("hhid", "eqadu1", "eqadu2")
  )
  assert_required_columns(
    welfare_data,
    c("hhid", "eqadu1", "eqadu2"),
    object_name = "ehcvm_welfare_2b_CIV2021.dta"
  )

  hh <- hh_sens %>%
    dplyr::left_join(welfare_data, by = "hhid")
  # ── Concepts de bien-etre ───────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      conso_pc  = conso_w / hhsize,
      conso_ae1 = conso_w / eqadu1,
      conso_ae2 = conso_w / eqadu2
    )

  # ── Classements par decile ───────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      decile_total = weighted_ntile(conso_w,   hhweight, n = 10),
      decile_pc    = weighted_ntile(conso_pc,  hhweight, n = 10),
      decile_ae1   = weighted_ntile(conso_ae1, hhweight, n = 10),
      decile_ae2   = weighted_ntile(conso_ae2, hhweight, n = 10)
    )

  # ── TVA effectif par classement × scenario ─────────────────────────────
  for (rank in c("total", "pc", "ae1", "ae2")) {
    dcol <- paste0("decile_", rank)
    out  <- hh %>%
      dplyr::mutate(decile_rank = .data[[dcol]]) %>%
      dplyr::group_by(decile_rank) %>%
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

  # ── Resume CEQ par classement × scenario ────────────────────────────────
  # Pour chaque classement, la charge TVA est mise a l'echelle par unite de bien-etre
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

  message("\n  Resume CEQ par classement et scenario :")
  print(ceq_rankings)

  save_parquet(ceq_rankings,
               file.path(paths$SILVER, "06", "06_02_ceq_rankings.parquet"))
  export_excel(ceq_rankings,
               file.path(paths$TABLES, "06", "06_02_ceq_rankings.xlsx"))

  invisible(ceq_rankings)
}
