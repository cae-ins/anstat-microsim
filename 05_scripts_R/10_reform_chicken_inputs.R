# 10_reform_chicken_inputs.R
#
# OBJECTIF :
# Simuler l'impact distributionnel d'une augmentation de la TVA sur les intrants
# de la production avicole (aliment compose, poussins d'un jour, produits veterinaires)
# en utilisant une approximation du transfert de prix.
#
# APPROCHE :
# Les intrants de production ne sont PAS observes dans l'EHCVM.
# La reforme est modelisee via son effet sur le PRIX DU POULET observe.
# Transmission: r_reform = alpha × s_inputs × delta_VAT_inputs
#
# TROIS SCENARIOS :
# - Conservateur (S1): alpha=0.50, s_inputs=0.65
# - Central     (S2): alpha=0.70, s_inputs=0.75
# - Complet    (S3): alpha=1.00, s_inputs=0.89
#
# SORTIES :
# - Part budgetaire du poulet par decile
# - Taux de TVA effectif implicite par decile
# - Charge TVA additionnelle par decile
# - Gain de recette fiscale estime
# - Indice de Kakwani (progressivite)
#
# ENTREE :  SILVER/01/conso_clean.parquet
# SORTIE :  SILVER/10/reform_chicken_inputs.parquet
#           TABLES/10/10_*.xlsx
#
# AUTEUR : CAE — ANStat (Avril 2026)
# Rewrite R : rewrite-r branch

run_reform_chicken <- function(paths) {

  message(">>> STEP 10: Reform simulation — poultry input VAT")

  # ── Parameters ────────────────────────────────────────────────────────────
  delta_vat     <- 0.18
  s_low         <- 0.65; alpha_low  <- 0.50
  s_central     <- 0.75; alpha_cen  <- 0.70
  s_high        <- 0.89; alpha_full <- 1.00

  message(sprintf("  S1 Conservative : ~%.1f%% price impact",
                  alpha_low  * s_low     * delta_vat * 100))
  message(sprintf("  S2 Central      : ~%.1f%% price impact",
                  alpha_cen  * s_central * delta_vat * 100))
  message(sprintf("  S3 Full         : ~%.1f%% price impact",
                  alpha_full * s_high    * delta_vat * 100))

  # ── Load item-level data ──────────────────────────────────────────────────
  df <- load_parquet(file.path(paths$SILVER, "01", "conso_clean.parquet")) %>%
    dplyr::mutate(
      code_num     = suppressWarnings(as.integer(as.character(code))),
      poultry      = as.integer(code_num %in% c(34L, 33L, 35L)),
      depan_poultry = depan_w * poultry,
      vat_item_w    = depan_w * r_vat_official
    )

  # ── Household-level aggregates ────────────────────────────────────────────
  hh <- df %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(
      hhweight     = dplyr::first(hhweight),
      milieu       = dplyr::first(milieu),
      region       = dplyr::first(region),
      conso_w      = sum(depan_w,       na.rm = TRUE),
      dpoul        = sum(depan_poultry, na.rm = TRUE),
      vat_baseline = sum(vat_item_w,    na.rm = TRUE),
      .groups      = "drop"
    ) %>%
    dplyr::mutate(
      decile = weighted_ntile(conso_w, hhweight, n = 10)
    )

  # ── Budget share of chicken by decile ─────────────────────────────────────
  budget_share <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      conso_w       = weighted.mean(conso_w, hhweight),
      poul_tot      = sum(dpoul   * hhweight),
      conso_tot     = sum(conso_w * hhweight),
      .groups       = "drop"
    ) %>%
    dplyr::mutate(share_poultry = poul_tot / conso_tot * 100)

  export_excel(budget_share,
               file.path(paths$TABLES, "10", "10_poultry_budget_share.xlsx"))

  # ── Additional VAT burden under 3 scenarios ────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      add_vat_s1 = dpoul * alpha_low  * s_low     * delta_vat,
      add_vat_s2 = dpoul * alpha_cen  * s_central * delta_vat,
      add_vat_s3 = dpoul * alpha_full * s_high    * delta_vat,

      vat_post_s1  = vat_baseline + add_vat_s1,
      vat_post_s2  = vat_baseline + add_vat_s2,
      vat_post_s3  = vat_baseline + add_vat_s3,

      eff_vat_base = vat_baseline / conso_w,
      eff_vat_s1   = vat_post_s1  / conso_w,
      eff_vat_s2   = vat_post_s2  / conso_w,
      eff_vat_s3   = vat_post_s3  / conso_w,

      delta_eff_s1 = eff_vat_s1 - eff_vat_base,
      delta_eff_s2 = eff_vat_s2 - eff_vat_base,
      delta_eff_s3 = eff_vat_s3 - eff_vat_base
    )

  # ── Distributional results by decile ──────────────────────────────────────
  reform_decile <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      conso_w_hh     = weighted.mean(conso_w,      hhweight),
      dpoul          = weighted.mean(dpoul,         hhweight),
      eff_vat_base   = weighted.mean(eff_vat_base,  hhweight),
      eff_vat_s1     = weighted.mean(eff_vat_s1,   hhweight),
      eff_vat_s2     = weighted.mean(eff_vat_s2,   hhweight),
      eff_vat_s3     = weighted.mean(eff_vat_s3,   hhweight),
      delta_eff_s1   = weighted.mean(delta_eff_s1, hhweight),
      delta_eff_s2   = weighted.mean(delta_eff_s2, hhweight),
      delta_eff_s3   = weighted.mean(delta_eff_s3, hhweight),
      add_vat_tot_s1 = sum(add_vat_s1 * hhweight),
      add_vat_tot_s2 = sum(add_vat_s2 * hhweight),
      add_vat_tot_s3 = sum(add_vat_s3 * hhweight),
      .groups        = "drop"
    ) %>%
    dplyr::mutate(
      share_burden_s1 = add_vat_tot_s1 / sum(add_vat_tot_s1) * 100,
      share_burden_s2 = add_vat_tot_s2 / sum(add_vat_tot_s2) * 100,
      share_burden_s3 = add_vat_tot_s3 / sum(add_vat_tot_s3) * 100
    )

  message("\n  Distributional results — S2 Central scenario:")
  print(reform_decile %>%
    dplyr::select(decile, eff_vat_base, eff_vat_s2, delta_eff_s2, share_burden_s2))

  export_excel(reform_decile,
               file.path(paths$TABLES, "10",
                         "10_reform_distributional_results.xlsx"))
  save_parquet(reform_decile,
               file.path(paths$SILVER, "06", "reform_chicken_inputs.parquet"))

  # Household-level data — used by step 13 (poverty incidence)
  save_parquet(
    hh %>% dplyr::select(hhid, hhweight, milieu, region, conso_w, decile,
                          vat_baseline, add_vat_s1, add_vat_s2, add_vat_s3,
                          vat_post_s1, vat_post_s2, vat_post_s3),
    file.path(paths$SILVER, "10", "reform_chicken_hh.parquet")
  )

  # ── Fiscal revenue estimate ───────────────────────────────────────────────
  rev <- hh %>%
    dplyr::summarise(
      rev_s1 = sum(add_vat_s1 * hhweight),
      rev_s2 = sum(add_vat_s2 * hhweight),
      rev_s3 = sum(add_vat_s3 * hhweight)
    )
  message(sprintf("\n  Revenue S1: %s CFA", format(round(rev$rev_s1), big.mark = ",")))
  message(sprintf("  Revenue S2: %s CFA", format(round(rev$rev_s2), big.mark = ",")))
  message(sprintf("  Revenue S3: %s CFA", format(round(rev$rev_s3), big.mark = ",")))

  # ── Kakwani index of reform progressivity ─────────────────────────────────
  hh_kak <- hh %>% dplyr::arrange(conso_w)
  totw    <- sum(hh_kak$hhweight)
  hh_kak  <- hh_kak %>%
    dplyr::mutate(frac_rank = (cumsum(hhweight) - hhweight / 2) / totw)

  mu_c   <- weighted.mean(hh_kak$conso_w, hh_kak$hhweight)
  Gini_c <- 2 * sum(hh_kak$hhweight * (hh_kak$conso_w / mu_c) *
                      hh_kak$frac_rank) / totw - 1

  kakwani_reform <- purrr::map_dfr(c("s1", "s2", "s3"), function(sc) {
    tax    <- hh_kak[[paste0("add_vat_", sc)]]
    mu_t   <- weighted.mean(tax, hh_kak$hhweight)
    CI_t   <- 2 * sum(hh_kak$hhweight * (tax / mu_t) *
                        hh_kak$frac_rank) / totw - 1
    kak    <- CI_t - Gini_c
    tibble::tibble(
      scenario  = toupper(sc),
      gini_cons = Gini_c,
      ci_reform = CI_t,
      kakwani   = kak,
      direction = dplyr::case_when(
        kak < 0 ~ "Regressive",
        kak > 0 ~ "Progressive",
        TRUE    ~ "Proportional"
      )
    )
  })

  message("\n  Kakwani — reform progressivity:")
  print(kakwani_reform)

  export_excel(kakwani_reform,
               file.path(paths$TABLES, "10", "10_reform_kakwani.xlsx"))

  # ── Regressivity check ─────────────────────────────────────────────────────
  d1  <- reform_decile$delta_eff_s2[reform_decile$decile == 1]
  d10 <- reform_decile$delta_eff_s2[reform_decile$decile == 10]
  message(sprintf("\n  Delta eff. rate D1  (poorest) : %.4f", d1))
  message(sprintf("  Delta eff. rate D10 (richest) : %.4f", d10))
  message(ifelse(d1 > d10,
    "  -> REGRESSIVE: poor households bear a proportionally larger burden",
    ifelse(d1 < d10,
      "  -> PROGRESSIVE: rich households bear a proportionally larger burden",
      "  -> PROPORTIONAL")))

  # ── Sensitivity cross-table: alpha × s_inputs grid ────────────────────────
  bs_d1  <- reform_decile$dpoul[reform_decile$decile == 1]  /
            reform_decile$conso_w_hh[reform_decile$decile == 1]
  bs_d10 <- reform_decile$dpoul[reform_decile$decile == 10] /
            reform_decile$conso_w_hh[reform_decile$decile == 10]

  sensitivity <- expand.grid(
    alpha    = c(0.30, 0.50, 0.70, 1.00),
    s_inputs = c(0.65, 0.75, 0.89)
  ) %>%
    dplyr::mutate(
      price_impact_pct = alpha * s_inputs * 0.18 * 100,
      delta_eff_d1_pp  = bs_d1  * alpha * s_inputs * 0.18 * 100,
      delta_eff_d10_pp = bs_d10 * alpha * s_inputs * 0.18 * 100,
      regressive       = dplyr::if_else(delta_eff_d1_pp > delta_eff_d10_pp,
                                         "Yes", "No")
    )

  export_excel(sensitivity,
               file.path(paths$TABLES, "10", "10_reform_sensitivity.xlsx"))

  message("\n================================================")
  message(" REFORM SIMULATION COMPLETED")
  message("================================================")

  invisible(reform_decile)
}
