# 11_reform_figures.R
#
# OBJECTIF :
# Produire toutes les figures pour la simulation de la reforme TVA sur les intrants avicoles.
#
# FIGURES :
# Fig R1 — Part budgetaire du poulet par decile (barres)
#           → qui consomme du poulet en % du budget ?
# Fig R2 — Variation du taux TVA effectif par decile : 3 scenarios (lignes)
#           → figure distributionnelle principale ; pente descendante = regressif
# Fig R3 — Taux TVA effectif avant vs apres reforme — S2 central (lignes)
#           → ampleur du deplacement par decile
# Fig R4 — Part de la charge fiscale additionnelle par decile — S2 (barres)
#           → qui paie la nouvelle recette ? gauche-lourde = regressif
#
# ENTREE :  SILVER/06/reform_chicken_inputs.parquet  (niveau decile)
# SORTIE :  FIG8/figR1_*.png ... FIG8/figR4_*.png
#
# AUTEUR : CAE — ANStat (Stata original)
# Rewrite R : rewrite-r branch

run_reform_figures <- function(paths) {

  message(">>> STEP 11: Reform figures")

  reform <- load_parquet(
    file.path(paths$SILVER, "06", "reform_chicken_inputs.parquet")
  ) %>%
    dplyr::mutate(
      budget_share_poultry = dpoul / conso_w_hh * 100
    )

  # ── Figure R1 — Budget share of poultry by decile ─────────────────────────
  figR1 <- ggplot2::ggplot(reform,
            ggplot2::aes(x = factor(decile), y = budget_share_poultry)) +
    ggplot2::geom_col(fill = "maroon", alpha = 0.75) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", budget_share_poultry)),
                        vjust = -0.3, size = 2.8) +
    ggplot2::labs(
      title    = "Budget share of poultry by welfare decile",
      subtitle = "C\u00f4te d'Ivoire EHCVM 2021 \u2014 market purchases only",
      x        = "Consumption decile (D1=poorest, D10=richest)",
      y        = "Share of household budget (%)",
      caption  = paste0(
        "Products: codpr 34 (viande de poulet), 33 (poulet sur pied),",
        " 35 (autres volailles).\nSource: EHCVM 2021."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(plot.caption = ggplot2::element_text(size = 7))

  export_fig(figR1, file.path(paths$FIGS, "figR1_poultry_budget_share.png"))

  # ── Figure R2 — Change in effective VAT rate: 3 scenarios ─────────────────
  figR2_data <- reform %>%
    dplyr::select(decile, delta_eff_s1, delta_eff_s2, delta_eff_s3) %>%
    tidyr::pivot_longer(-decile, names_to = "scenario", values_to = "delta") %>%
    dplyr::mutate(
      label = dplyr::recode_values(scenario,
        "delta_eff_s1" ~ "S1 Conservative (\u03b1=0.50, s=0.65) \u2014 ~5.9% price impact",
        "delta_eff_s2" ~ "S2 Central (\u03b1=0.70, s=0.75) \u2014 ~9.5% price impact",
        "delta_eff_s3" ~ "S3 Full pass-through (\u03b1=1.00, s=0.89) \u2014 ~16.0% price impact"
      ),
      label = factor(label, levels = unique(label))
    )

  figR2 <- ggplot2::ggplot(figR2_data,
            ggplot2::aes(x = decile, y = delta,
                         color = label, linetype = label)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_hline(yintercept = 0,
                         color = "gray30", linewidth = 0.4) +
    ggplot2::scale_color_manual(values = c("navy", "maroon", "#2e8b57")) +
    ggplot2::scale_linetype_manual(values = c("dashed", "solid", "dotdash")) +
    ggplot2::scale_x_continuous(breaks = 1:10) +
    ggplot2::labs(
      title    = "Change in effective VAT rate \u2014 poultry input reform",
      subtitle = paste0("Impact of applying 18% VAT to compound feed,",
                        " day-old chicks & veterinary products"),
      x        = "Consumption decile (D1=poorest, D10=richest)",
      y        = "\u0394 Effective VAT rate (pp)",
      color    = NULL, linetype = NULL,
      caption  = paste0(
        "Reform: 0% \u2192 18% VAT on poultry production inputs.\n",
        "Transmission: \u0394p = \u03b1 \u00d7 s_inputs \u00d7 \u0394VAT.",
        " Source: EHCVM 2021."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position  = "bottom",
      legend.direction = "vertical",
      plot.caption     = ggplot2::element_text(size = 7)
    )

  export_fig(figR2, file.path(paths$FIGS, "figR2_delta_eff_vat_scenarios.png"))

  # ── Figure R3 — Effective VAT: before vs after — S2 central ───────────────
  figR3_data <- reform %>%
    dplyr::select(decile, eff_vat_base, eff_vat_s2) %>%
    tidyr::pivot_longer(-decile, names_to = "period", values_to = "rate") %>%
    dplyr::mutate(
      label = dplyr::recode_values(period,
        "eff_vat_base" ~ "Baseline (pre-reform)",
        "eff_vat_s2"   ~ "Post-reform \u2014 S2 Central (\u03b1=0.70)"
      ),
      label = factor(label, levels = unique(label))
    )

  figR3 <- ggplot2::ggplot(figR3_data,
            ggplot2::aes(x = decile, y = rate,
                         color = label, linetype = label)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_manual(values = c("gray55", "maroon")) +
    ggplot2::scale_linetype_manual(values = c("longdash", "solid")) +
    ggplot2::scale_x_continuous(breaks = 1:10) +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 0.1)
    ) +
    ggplot2::labs(
      title    = "Effective VAT rate before and after reform \u2014 S2 Central",
      subtitle = "C\u00f4te d'Ivoire EHCVM 2021",
      x        = "Consumption decile (D1=poorest, D10=richest)",
      y        = "Effective VAT rate (VAT / total consumption)",
      color    = NULL, linetype = NULL,
      caption  = paste0(
        "Reform: 18% VAT on poultry production inputs,",
        " 70% pass-through, 75% input cost share.\n",
        "Source: EHCVM 2021."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.caption    = ggplot2::element_text(size = 7)
    )

  export_fig(figR3, file.path(paths$FIGS, "figR3_eff_vat_before_after.png"))

  # ── Figure R4 — Share of additional fiscal burden by decile ───────────────
  cum_d1d5 <- sum(reform$share_burden_s2[reform$decile <= 5])

  figR4 <- ggplot2::ggplot(reform,
            ggplot2::aes(x = factor(decile), y = share_burden_s2)) +
    ggplot2::geom_col(fill = "navy", alpha = 0.75) +
    ggplot2::geom_hline(yintercept = 10,
                         color = "gray70", linetype = "dotted") +
    ggplot2::annotate("text", x = 3.5, y = 10.6,
                       label = "Equal share = 10%/decile",
                       color = "gray50", size = 2.8) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f", share_burden_s2)),
                        vjust = -0.3, size = 2.8) +
    ggplot2::labs(
      title    = "Share of additional fiscal burden by decile \u2014 S2 Central",
      subtitle = "Who pays the additional revenue from the reform?",
      x        = "Consumption decile (D1=poorest, D10=richest)",
      y        = "Share of total additional VAT revenue (%)",
      caption  = paste0(
        sprintf("D1\u2013D5 (bottom half) cumulative share: %.1f%%.\n", cum_d1d5),
        "Reform: 18% VAT on poultry inputs, \u03b1=0.70, s=0.75.",
        " Source: EHCVM 2021."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(plot.caption = ggplot2::element_text(size = 7))

  export_fig(figR4, file.path(paths$FIGS, "figR4_burden_share_by_decile.png"))

  message("  figR1 : Poultry budget share by decile")
  message("  figR2 : Delta effective VAT rate \u2014 3 scenarios")
  message("  figR3 : Effective VAT before vs after \u2014 S2")
  message("  figR4 : Fiscal burden share by decile \u2014 S2")
  message("================================================")
  message(" REFORM FIGURES COMPLETED \u2014 4 figures exported")
  message("================================================")

  invisible(NULL)
}
