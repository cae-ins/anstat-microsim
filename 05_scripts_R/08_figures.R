# 08_figures.R
#
# OBJECTIVE:
# Produce all main analytical figures.
#
# FIGURES:
# Fig 1 — Effective VAT rate by decile: three informality scenarios
# Fig 2 — Concentration curves: three scenarios + Lorenz + equality line
# Fig 3 — VAT share by COICOP category (descriptive)
# Fig 4 — Alpha profiles by decile for key COICOP categories (IEC calibration)
#
# INPUT:  TABLES/06/06_01_decile_effective_rates_by_scenario.xlsx
#         SILVER/06/fiscal_sensitivity_taxation.parquet
#         TABLES/07/07_vat_by_coicop.xlsx
# OUTPUT: FIGS/fig1_*.png ... FIGS/fig4_*.png
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

run_figures <- function(paths) {

  message(">>> STEP 8: Generating figures")

  # ── FIGURE 1 — Effective VAT rates by decile: three scenarios ─────────────
  rates <- readxl::read_excel(
    file.path(paths$TABLES, "06",
              "06_01_decile_effective_rates_by_scenario.xlsx")
  )

  fig1_data <- rates %>%
    tidyr::pivot_longer(
      cols      = c(rate_strict, rate_s2_milieu, rate_s3_iec),
      names_to  = "scenario",
      values_to = "rate"
    ) %>%
    dplyr::mutate(
      label = dplyr::case_match(scenario,
        "rate_strict"    ~ "Strict (\u03b1=1) \u2014 theoretical upper bound",
        "rate_s2_milieu" ~ "S2: CEI \u00d7 milieu urbain/rural (Bachas et al. 2024)",
        "rate_s3_iec"    ~ "S3: CEI \u00d7 decile \u2014 IEC calibrated"
      ),
      label = factor(label, levels = unique(label))
    )

  fig1 <- ggplot2::ggplot(fig1_data,
           ggplot2::aes(x = decile, y = rate,
                        color = label, linetype = label)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_manual(values = c("maroon", "navy", "#2e8b57")) +
    ggplot2::scale_linetype_manual(values = c("solid", "dashed", "dotdash")) +
    ggplot2::scale_x_continuous(breaks = 1:10) +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 0.1)
    ) +
    ggplot2::labs(
      title    = "Effective VAT rate by consumption decile",
      subtitle = "Three informality scenarios \u2014 C\u00f4te d'Ivoire EHCVM 2021",
      x        = "Consumption decile",
      y        = "Effective VAT rate (VAT / consumption)",
      color    = NULL, linetype = NULL,
      caption  = "Source: EHCVM 2021. Alpha calibration: Bachas, Gadenne & Jensen (2024, RestUD 91(5))."
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position  = "bottom",
      legend.direction = "vertical",
      plot.caption     = ggplot2::element_text(size = 7)
    )

  export_fig(fig1, file.path(paths$FIGS, "fig1_eff_vat_three_scenarios.png"))

  # ── FIGURE 2 — Concentration curves ─────────────────────────────────────
  hh_sens <- load_parquet(
    file.path(paths$SILVER, "06", "fiscal_sensitivity_taxation.parquet")
  ) %>% dplyr::arrange(conso_w)

  totw <- sum(hh_sens$hhweight)
  hh_sens <- hh_sens %>%
    dplyr::mutate(
      cum_pop        = cumsum(hhweight) / totw,
      cum_conso      = cumsum(conso_w    * hhweight) / sum(conso_w    * hhweight),
      cum_vat_strict = cumsum(vat_strict * hhweight) / sum(vat_strict * hhweight),
      cum_vat_s2     = cumsum(vat_s2     * hhweight) / sum(vat_s2     * hhweight),
      cum_vat_s3     = cumsum(vat_s3     * hhweight) / sum(vat_s3     * hhweight)
    )

  fig2_data <- hh_sens %>%
    dplyr::select(cum_pop, cum_conso, cum_vat_strict, cum_vat_s2, cum_vat_s3) %>%
    tidyr::pivot_longer(-cum_pop, names_to = "curve", values_to = "cum_share") %>%
    dplyr::mutate(
      label = dplyr::case_match(curve,
        "cum_conso"      ~ "Lorenz \u2014 consumption",
        "cum_vat_strict" ~ "Concentration \u2014 Strict (\u03b1=1)",
        "cum_vat_s2"     ~ "Concentration \u2014 S2 (CEI \u00d7 milieu)",
        "cum_vat_s3"     ~ "Concentration \u2014 S3 (CEI \u00d7 decile)"
      ),
      label = factor(label, levels = c(
        "Lorenz \u2014 consumption",
        "Concentration \u2014 Strict (\u03b1=1)",
        "Concentration \u2014 S2 (CEI \u00d7 milieu)",
        "Concentration \u2014 S3 (CEI \u00d7 decile)"
      ))
    )

  fig2 <- ggplot2::ggplot(fig2_data,
           ggplot2::aes(x = cum_pop, y = cum_share,
                        color = label, linetype = label)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_abline(slope = 1, intercept = 0,
                          color = "gray70", linetype = "dotted",
                          linewidth = 0.5) +
    ggplot2::scale_color_manual(
      values = c("black", "maroon", "navy", "#2e8b57")
    ) +
    ggplot2::scale_linetype_manual(
      values = c("longdash", "solid", "dashed", "dotdash")
    ) +
    ggplot2::labs(
      title    = "Concentration curves \u2014 VAT under three scenarios",
      subtitle = "Curve above Lorenz = progressive | Curve below = regressive",
      x        = "Cumulative population share (ranked by consumption)",
      y        = "Cumulative share",
      color    = NULL, linetype = NULL,
      caption  = "Source: EHCVM 2021. Bachas, Gadenne & Jensen (2024, RestUD 91(5))."
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position   = c(0.26, 0.76),
      legend.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.caption      = ggplot2::element_text(size = 7)
    )

  export_fig(fig2, file.path(paths$FIGS, "fig2_concentration_curves.png"))

  # ── FIGURE 3 — VAT share by COICOP ───────────────────────────────────────
  vat_coicop <- readxl::read_excel(
    file.path(paths$TABLES, "07", "07_vat_by_coicop.xlsx")
  ) %>%
    dplyr::mutate(coicop_num = as.integer(as.character(coicop))) %>%
    dplyr::filter(!coicop_num %in% c(98, 99)) %>%
    dplyr::mutate(
      vat_share = vat_w / sum(vat_w) * 100,
      coicop_label = dplyr::case_match(coicop_num,
        1  ~ "Food/bev",    2  ~ "Alcohol/tob", 3  ~ "Clothing",
        4  ~ "Housing",     5  ~ "Furnishings", 6  ~ "Health",
        7  ~ "Transport",   8  ~ "Telecom",     9  ~ "Recreation",
        10 ~ "Education",   11 ~ "Restaurants", 12 ~ "Insurance",
        13 ~ "Personal care",
        .default = "Other"
      )
    ) %>%
    dplyr::arrange(dplyr::desc(vat_share)) %>%
    dplyr::mutate(
      coicop_label = factor(coicop_label, levels = coicop_label)
    )

  fig3 <- ggplot2::ggplot(vat_coicop,
           ggplot2::aes(x = coicop_label, y = vat_share)) +
    ggplot2::geom_col(fill = "navy", alpha = 0.8) +
    ggplot2::labs(
      title    = "Share of total VAT revenue by COICOP category",
      subtitle = "C\u00f4te d'Ivoire EHCVM 2021 \u2014 strict scenario",
      x        = NULL,
      y        = "Share of total VAT (%)",
      caption  = "Source: EHCVM 2021. VAT computed at item level (r_vat_official)."
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      axis.text.x  = ggplot2::element_text(angle = 45, hjust = 1, size = 8),
      plot.caption = ggplot2::element_text(size = 7)
    )

  export_fig(fig3, file.path(paths$FIGS, "fig3_vat_by_coicop.png"))

  # ── FIGURE 4 — Alpha profiles by decile: key categories ───────────────────
  # Illustrates the IEC calibration for the 4 most analytically important
  # COICOP categories driving the Kakwani sign reversal
  alpha_profiles <- tibble::tibble(
    decile     = 1:10,
    alpha_food = 0.12 + (1:10 - 1) * 0.034,   # food/bev: steepest IEC
    alpha_rest = 0.12 + (1:10 - 1) * 0.038,   # restaurants: same slope as food
    alpha_care = 0.15 + (1:10 - 1) * 0.034,   # personal care: steep
    alpha_tel  = 0.78 + (1:10 - 1) * 0.015    # telecom: near-flat (formal)
  ) %>%
    dplyr::mutate(
      dplyr::across(dplyr::starts_with("alpha_"), ~ pmin(.x, 1))
    ) %>%
    tidyr::pivot_longer(-decile, names_to = "cat", values_to = "alpha") %>%
    dplyr::mutate(
      label = dplyr::case_match(cat,
        "alpha_food" ~ "Food/beverages (coicop=1)",
        "alpha_rest" ~ "Restaurants (coicop=11)",
        "alpha_care" ~ "Personal care (coicop=13)",
        "alpha_tel"  ~ "Telecom/info-comm (coicop=8)"
      ),
      label = factor(label, levels = unique(label))
    )

  fig4 <- ggplot2::ggplot(alpha_profiles,
           ggplot2::aes(x = decile, y = alpha,
                        color = label, linetype = label)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_hline(yintercept = 1,
                         color = "gray80", linetype = "dotted") +
    ggplot2::scale_color_manual(
      values = c("maroon", "navy", "orange", "#2e8b57")
    ) +
    ggplot2::scale_linetype_manual(
      values = c("solid", "dashed", "dotdash", "longdash")
    ) +
    ggplot2::scale_x_continuous(breaks = 1:10) +
    ggplot2::scale_y_continuous(limits = c(0, 1),
                                 breaks = seq(0, 1, 0.1)) +
    ggplot2::labs(
      title    = "Effective alpha by consumption decile \u2014 Scenario 3",
      subtitle = "Informality Engel Curve calibration (Bachas et al. 2024)",
      x        = "Consumption decile",
      y        = "Effective alpha (\u03b1)",
      color    = NULL, linetype = NULL,
      caption  = paste0(
        "Alpha = effective VAT pass-through rate ",
        "(0 = fully informal, 1 = fully formal).\n",
        "Slopes calibrated from IEC estimates for lower-middle income countries."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position   = c(0.27, 0.82),
      legend.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.caption      = ggplot2::element_text(size = 7)
    )

  export_fig(fig4, file.path(paths$FIGS, "fig4_alpha_profiles_iec.png"))

  message(">>> Figures generated: fig1, fig2, fig3, fig4")
  invisible(NULL)
}
