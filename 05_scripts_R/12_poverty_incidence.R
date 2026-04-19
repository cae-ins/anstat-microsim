# 12_poverty_incidence.R
#
# OBJECTIF :
# Estimer l'impact de la TVA sur la pauvreté via les indices FGT (Foster,
# Greer & Thorbecke, 1984) : taux (P0), écart (P1), sévérité (P2).
#
# APPROCHE :
# Pour chaque scénario de taxation, on soustrait la charge TVA par tête
# à la dépense per capita officielle EHCVM (pcexp), puis on compare au
# seuil de pauvreté ménage-spécifique (zref).
#
#   pcexp_après = pcexp - vat_scénario / hhsize
#
# NOTE MÉTHODOLOGIQUE :
#   pcexp (agrégat officiel EHCVM) inclut tous les modes d'acquisition
#   (marché, autoconsommation, dons, etc.).
#   La TVA simulée ne porte que sur les achats marché (modep==1).
#   La soustraction est cohérente : l'autoconsommation et les dons ne
#   sont pas soumis à la TVA.
#
# INPUT :  SILVER/06/fiscal_sensitivity_taxation.parquet
#          SILVER/10/reform_chicken_hh.parquet  (optionnel — réforme)
#          DATA/ehcvm_welfare_2b_CIV2021.dta
# OUTPUT : TABLES/12/12_01_fgt_national.xlsx
#          TABLES/12/12_02_fgt_milieu.xlsx
#          TABLES/12/12_03_fgt_region.xlsx
#          TABLES/12/12_04_poverty_impact_decile.xlsx
#          TABLES/12/12_05_fgt_reform.xlsx  (si réforme disponible)
#          FIGS/fig_poverty_decile_impact.png
#
# AUTEUR : CAE — ANStat

run_poverty_incidence <- function(paths) {

  message(">>> ETAPE 13 : Incidence de la TVA sur la pauvreté (FGT)")

  # ── Chargement des données ─────────────────────────────────────────────────
  hh_vat <- load_parquet(
    file.path(paths$SILVER, "06", "fiscal_sensitivity_taxation.parquet")
  )

  welfare <- load_raw_dta(
    "ehcvm_welfare_2b_CIV2021.dta",
    col_select = c("hhid", "pcexp", "zref", "hhsize")
  )

  hh <- hh_vat %>%
    dplyr::left_join(welfare, by = "hhid") %>%
    dplyr::mutate(
      # Poids individu : réplique le taux officiel au niveau population
      w_ind              = hhweight * hhsize,
      pcexp_after_strict = pcexp - vat_strict / hhsize,
      pcexp_after_s2     = pcexp - vat_s2     / hhsize,
      pcexp_after_s3     = pcexp - vat_s3     / hhsize
    )

  n_miss <- sum(is.na(hh$pcexp) | is.na(hh$zref))
  if (n_miss > 0)
    warning(sprintf("  %d ménages avec pcexp ou zref manquants — exclus de l'analyse", n_miss))

  hh <- dplyr::filter(hh, !is.na(pcexp), !is.na(zref), !is.na(hhweight))

  # ── Fonction FGT ──────────────────────────────────────────────────────────
  # alpha = 0 : taux de pauvreté (P0)
  # alpha = 1 : écart de pauvreté (P1)
  # alpha = 2 : sévérité de la pauvreté (P2)
  fgt <- function(y, z, w, alpha) {
    gap <- pmax(0, 1 - y / z)
    if (alpha == 0L) weighted.mean(gap > 0, w, na.rm = TRUE)
    else             weighted.mean(gap^alpha, w, na.rm = TRUE)
  }

  # ── Libellés des concepts de bien-être ────────────────────────────────────
  welfare_vars <- c(
    "pcexp",
    "pcexp_after_strict",
    "pcexp_after_s2",
    "pcexp_after_s3"
  )
  welfare_labels <- c(
    "pcexp"               = "Avant TVA (pcexp officiel)",
    "pcexp_after_strict"  = "Après TVA — Strict (alpha=1)",
    "pcexp_after_s2"      = "Après TVA — S2 (CEI x milieu)",
    "pcexp_after_s3"      = "Après TVA — S3 (CEI x décile)"
  )

  # ── Helper : table FGT (nationale ou par groupe) ──────────────────────────
  compute_fgt_table <- function(data, group_var = NULL) {
    purrr::map_dfr(welfare_vars, function(wv) {
      fn <- function(df) {
        tibble::tibble(
          concept = welfare_labels[[wv]],
          p0      = fgt(df[[wv]], df$zref, df$w_ind, 0),
          p1      = fgt(df[[wv]], df$zref, df$w_ind, 1),
          p2      = fgt(df[[wv]], df$zref, df$w_ind, 2)
        )
      }
      if (is.null(group_var)) {
        fn(data)
      } else {
        data %>%
          dplyr::group_by(dplyr::across(dplyr::all_of(group_var))) %>%
          dplyr::group_modify(~fn(.x)) %>%
          dplyr::ungroup()
      }
    })
  }

  # ── Table nationale ────────────────────────────────────────────────────────
  p0_base <- fgt(hh$pcexp, hh$zref, hh$w_ind, 0)
  p1_base <- fgt(hh$pcexp, hh$zref, hh$w_ind, 1)
  p2_base <- fgt(hh$pcexp, hh$zref, hh$w_ind, 2)

  fgt_national <- compute_fgt_table(hh) %>%
    dplyr::mutate(
      delta_p0 = p0 - p0_base,
      delta_p1 = p1 - p1_base,
      delta_p2 = p2 - p2_base
    )

  message("\n  Indices FGT — niveau national :")
  print(fgt_national)

  export_excel(fgt_national,
               file.path(paths$TABLES, "12", "12_01_fgt_national.xlsx"))

  # ── Par milieu ─────────────────────────────────────────────────────────────
  fgt_milieu <- compute_fgt_table(hh, group_var = "milieu")
  export_excel(fgt_milieu,
               file.path(paths$TABLES, "12", "12_02_fgt_milieu.xlsx"))

  # ── Par région ─────────────────────────────────────────────────────────────
  fgt_region <- compute_fgt_table(hh, group_var = "region")
  export_excel(fgt_region,
               file.path(paths$TABLES, "12", "12_03_fgt_region.xlsx"))

  # ── Impact par décile ─────────────────────────────────────────────────────
  # Deux lectures complémentaires :
  #   (1) delta P0 par décile : variation du taux de pauvreté dans le décile
  #   (2) nouveaux pauvres : ménages non pauvres avant TVA qui basculent sous
  #       le seuil après TVA — exprimés en nombre pondéré de ménages
  hh <- hh %>%
    dplyr::mutate(
      poor_pre    = as.integer(pcexp              < zref),
      poor_strict = as.integer(pcexp_after_strict < zref),
      poor_s2     = as.integer(pcexp_after_s2     < zref),
      poor_s3     = as.integer(pcexp_after_s3     < zref),
      new_poor_strict = as.integer(poor_pre == 0L & poor_strict == 1L),
      new_poor_s2     = as.integer(poor_pre == 0L & poor_s2     == 1L),
      new_poor_s3     = as.integer(poor_pre == 0L & poor_s3     == 1L)
    )

  decile_impact <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      p0_pre            = weighted.mean(poor_pre,    hhweight),
      p0_strict         = weighted.mean(poor_strict, hhweight),
      p0_s2             = weighted.mean(poor_s2,     hhweight),
      p0_s3             = weighted.mean(poor_s3,     hhweight),
      n_new_poor_strict = sum(new_poor_strict * hhweight),
      n_new_poor_s2     = sum(new_poor_s2     * hhweight),
      n_new_poor_s3     = sum(new_poor_s3     * hhweight),
      .groups           = "drop"
    ) %>%
    dplyr::mutate(
      delta_p0_strict = p0_strict - p0_pre,
      delta_p0_s2     = p0_s2     - p0_pre,
      delta_p0_s3     = p0_s3     - p0_pre
    )

  total_new_poor <- colSums(
    decile_impact[, c("n_new_poor_strict", "n_new_poor_s2", "n_new_poor_s3")]
  )
  message("\n  Impact par décile — nouveaux pauvres (ménages pondérés) :")
  message(sprintf("    Strict  : %s", format(round(total_new_poor["n_new_poor_strict"]), big.mark = ",")))
  message(sprintf("    S2      : %s", format(round(total_new_poor["n_new_poor_s2"]),     big.mark = ",")))
  message(sprintf("    S3      : %s", format(round(total_new_poor["n_new_poor_s3"]),     big.mark = ",")))

  message("\n  Delta P0 par décile (scénario Strict) :")
  print(decile_impact %>%
    dplyr::select(decile, p0_pre, p0_strict, delta_p0_strict, n_new_poor_strict))

  export_excel(decile_impact,
               file.path(paths$TABLES, "12", "12_04_poverty_impact_decile.xlsx"))

  # ── Figure : delta P0 par décile × scénario ───────────────────────────────
  fig_data <- decile_impact %>%
    dplyr::select(decile, delta_p0_strict, delta_p0_s2, delta_p0_s3) %>%
    tidyr::pivot_longer(
      cols      = -decile,
      names_to  = "scenario",
      values_to = "delta_p0"
    ) %>%
    dplyr::mutate(
      scenario = dplyr::case_when(
        scenario == "delta_p0_strict" ~ "Strict (alpha=1)",
        scenario == "delta_p0_s2"     ~ "S2 — CEI x milieu",
        scenario == "delta_p0_s3"     ~ "S3 — CEI x décile"
      ),
      scenario = factor(scenario, levels = c(
        "Strict (alpha=1)", "S2 — CEI x milieu", "S3 — CEI x décile"
      ))
    )

  fig_poverty <- ggplot2::ggplot(
    fig_data,
    ggplot2::aes(x = factor(decile), y = delta_p0 * 100,
                 fill = scenario)
  ) +
    ggplot2::geom_col(position = "dodge", width = 0.75) +
    ggplot2::scale_fill_manual(
      values = c(
        "Strict (alpha=1)"  = "firebrick",
        "S2 — CEI x milieu" = "steelblue",
        "S3 — CEI x décile" = "darkgreen"
      )
    ) +
    ggplot2::labs(
      title    = "Impact de la TVA sur le taux de pauvreté par décile",
      subtitle = "Variation du P0 (points de pourcentage) \u2014 C\u00f4te d'Ivoire, EHCVM 2021",
      x        = "D\u00e9cile de consommation (D1 = plus pauvre)",
      y        = "\u0394 P0 (pp)",
      fill     = "Sc\u00e9nario",
      caption  = paste0(
        "Pond\u00e9rations sondage. Seuil de pauvret\u00e9 m\u00e9nage-sp\u00e9cifique (zref, EHCVM).\n",
        "Nouveaux pauvres = m\u00e9nages non pauvres avant TVA passant sous le seuil apr\u00e8s TVA."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.caption    = ggplot2::element_text(size = 7)
    )

  export_fig(fig_poverty,
             file.path(paths$FIGS, "fig_poverty_decile_impact.png"))

  # ── Composante réforme avicole (conditionnelle) ───────────────────────────
  reform_path <- file.path(paths$SILVER, "10", "reform_chicken_hh.parquet")

  if (file.exists(reform_path)) {
    message("\n  Chargement données réforme avicole (SILVER/10)...")

    hh_reform <- load_parquet(reform_path) %>%
      dplyr::select(hhid, add_vat_s1, add_vat_s2, add_vat_s3)

    hh_ref <- hh %>%
      dplyr::left_join(hh_reform, by = "hhid") %>%
      dplyr::mutate(
        # La réforme augmente la charge TVA au-delà du strict baseline
        pcexp_reform_s1 = pcexp_after_strict - add_vat_s1 / hhsize,
        pcexp_reform_s2 = pcexp_after_strict - add_vat_s2 / hhsize,
        pcexp_reform_s3 = pcexp_after_strict - add_vat_s3 / hhsize,
        poor_reform_s1  = as.integer(pcexp_reform_s1 < zref),
        poor_reform_s2  = as.integer(pcexp_reform_s2 < zref),
        poor_reform_s3  = as.integer(pcexp_reform_s3 < zref)
      )

    p0_strict_ref <- weighted.mean(hh_ref$poor_strict,    hh_ref$hhweight)

    fgt_reform <- tibble::tibble(
      concept = c(
        "Référence : après TVA (Strict)",
        "Réforme S1 — conservateur (alpha=0.50, s=0.65)",
        "Réforme S2 — central      (alpha=0.70, s=0.75)",
        "Réforme S3 — complet      (alpha=1.00, s=0.89)"
      ),
      p0 = c(
        p0_strict_ref,
        weighted.mean(hh_ref$poor_reform_s1, hh_ref$hhweight),
        weighted.mean(hh_ref$poor_reform_s2, hh_ref$hhweight),
        weighted.mean(hh_ref$poor_reform_s3, hh_ref$hhweight)
      )
    ) %>%
      dplyr::mutate(
        delta_p0_vs_strict = p0 - p0_strict_ref,
        n_nouveaux_pauvres = delta_p0_vs_strict *
          sum(hh_ref$hhweight * (hh_ref$poor_pre == 0L), na.rm = TRUE)
      )

    message("\n  Impact pauvreté — réforme TVA intrants avicoles :")
    print(fgt_reform)

    export_excel(fgt_reform,
                 file.path(paths$TABLES, "12", "12_05_fgt_reform.xlsx"))
  } else {
    message(
      "\n  Réforme avicole : parquet ménage absent (SILVER/10/reform_chicken_hh.parquet).",
      "\n  Lancez d'abord l'étape 11 (run_reform_chicken) pour activer cette composante."
    )
  }

  invisible(decile_impact)
}
