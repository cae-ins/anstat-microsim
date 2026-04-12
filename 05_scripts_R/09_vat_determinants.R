# 09_vat_determinants.R
#
# OBJECTIVE:
# Analyze socio-demographic determinants of effective VAT exposure across
# three informality scenarios (strict, S2, S3).
#
# APPROACH:
# OLS with cluster-robust SE at the PSU (grappe) level.
# Four nested models per dependent variable:
#   M1 : bivariate (lconso_w only)
#   M2 : + household demographics
#   M3 : + milieu + region fixed effects
#   M4 : M3 + n_items (consumption diversification)
#
# INPUT:  SILVER/06/fiscal_sensitivity_taxation.parquet
#         SILVER/01/conso_clean.parquet  (for n_items)
#         DATA/ehcvm_welfare_2b_CIV2021.dta (for socio-demographics)
# OUTPUT: TABLES/09/09_reg_panel_*.xlsx
#         FIGS/fig6_margins_income_milieu.png
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

run_determinants <- function(paths) {

  message(">>> STEP 9: VAT determinants")

  # ── Load and merge data ───────────────────────────────────────────────────
  hh_sens <- load_parquet(
    file.path(paths$SILVER, "06", "fiscal_sensitivity_taxation.parquet")
  )

  # n_items from item-level data
  n_items_hh <- load_parquet(
    file.path(paths$SILVER, "01", "conso_clean.parquet")
  ) %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(n_items = dplyr::n(), .groups = "drop")

  welfare_data <- load_raw_dta(
    "ehcvm_welfare_2b_CIV2021.dta",
    col_select = c("hhid", "hhsize", "hgender", "hage",
                   "heduc", "halfa2", "grappe", "region")
  )

  hh <- hh_sens %>%
    dplyr::left_join(n_items_hh,   by = "hhid") %>%
    dplyr::left_join(welfare_data, by = "hhid") %>%
    dplyr::mutate(
      lconso_w    = log(conso_w),
      lconso_w2   = lconso_w^2,
      educ_high   = as.integer(heduc >= 4 & !is.na(heduc)),
      head_female = as.integer(hgender == 2 & !is.na(hgender)),
      urban       = as.integer(as.character(milieu) == "Urbain"),
      region_fac  = as.factor(as.character(region))
    )

  # ── Descriptive stats ─────────────────────────────────────────────────────
  message(sprintf("  Correlation n_items / lconso_w: %.3f",
                  cor(hh$n_items, hh$lconso_w, use = "complete.obs")))

  for (dv in c("eff_vat_strict", "eff_vat_s2", "eff_vat_s3")) {
    message(sprintf("  Mean %s: %.4f", dv, weighted.mean(hh[[dv]], hh$hhweight)))
  }

  # ── OLS models ────────────────────────────────────────────────────────────
  fit_ols <- function(formula_str, data) {
    lm(as.formula(formula_str), data = data, weights = data$hhweight)
  }

  models <- list()
  for (dv in c("strict", "s2", "s3")) {
    dep <- paste0("eff_vat_", dv)
    models[[paste0(dv, "_m1")]] <- fit_ols(
      paste(dep, "~ lconso_w"), hh
    )
    models[[paste0(dv, "_m2")]] <- fit_ols(
      paste(dep, "~ lconso_w + hhsize + head_female + educ_high"), hh
    )
    models[[paste0(dv, "_m3")]] <- fit_ols(
      paste(dep, "~ lconso_w + hhsize + head_female + educ_high",
            "+ urban + region_fac"), hh
    )
    models[[paste0(dv, "_m4")]] <- fit_ols(
      paste(dep, "~ lconso_w + hhsize + head_female + educ_high",
            "+ urban + region_fac + n_items"), hh
    )
  }

  # ── Export regression tables (cluster-robust SE at grappe level) ──────────
  coef_keep <- c("lconso_w", "hhsize", "head_female", "educ_high",
                 "urban", "n_items", "(Intercept)")

  for (panel in c("strict", "s2", "s3")) {
    panel_models <- models[grep(paste0("^", panel, "_"), names(models))]

    tab_list <- purrr::imap(panel_models, function(m, name) {
      cl  <- hh$grappe[!is.na(hh$grappe)]
      res <- tidy_lm_robust(m, cluster_var = cl) %>%
        dplyr::filter(term %in% coef_keep) %>%
        dplyr::mutate(model = name)
      res
    })

    tab <- dplyr::bind_rows(tab_list)
    export_excel(tab,
                 file.path(paths$TABLES, "09",
                           paste0("09_reg_panel_", panel, ".xlsx")))
  }

  # Comparative M3 table across three panels
  m3_tab <- purrr::imap(
    models[grepl("_m3$", names(models))],
    function(m, name) {
      cl  <- hh$grappe[!is.na(hh$grappe)]
      tidy_lm_robust(m, cluster_var = cl) %>%
        dplyr::filter(term %in% c("lconso_w", "hhsize", "head_female",
                                   "educ_high", "urban", "(Intercept)")) %>%
        dplyr::mutate(model = name)
    }
  ) %>% dplyr::bind_rows()

  export_excel(m3_tab,
               file.path(paths$TABLES, "09", "09_reg_comparison_M3.xlsx"))

  # ── Figure 6 — Predicted effective VAT rate by income × milieu ───────────
  m_interact <- lm(
    eff_vat_s3 ~ lconso_w * urban + hhsize + head_female + educ_high +
      region_fac,
    data    = hh,
    weights = hh$hhweight
  )

  # Prediction grid
  lc_grid <- seq(
    quantile(hh$lconso_w, 0.05, na.rm = TRUE),
    quantile(hh$lconso_w, 0.95, na.rm = TRUE),
    length.out = 60
  )
  top_region <- names(sort(table(hh$region_fac), decreasing = TRUE))[1]

  pred_grid <- expand.grid(
    lconso_w    = lc_grid,
    urban       = c(0L, 1L)
  ) %>%
    dplyr::mutate(
      hhsize      = median(hh$hhsize, na.rm = TRUE),
      head_female = 0L,
      educ_high   = 0L,
      region_fac  = factor(top_region, levels = levels(hh$region_fac))
    )

  pred_grid$pred <- predict(m_interact, newdata = pred_grid)

  fig6 <- ggplot2::ggplot(pred_grid,
           ggplot2::aes(x = lconso_w, y = pred,
                        color = factor(urban),
                        group = factor(urban))) +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::scale_color_manual(
      values = c("0" = "maroon", "1" = "navy"),
      labels = c("0" = "Rural", "1" = "Urban")
    ) +
    ggplot2::labs(
      title    = "Predicted effective VAT rate by income and milieu",
      subtitle = "Scenario 3 (CEI \u00d7 decile) \u2014 C\u00f4te d'Ivoire EHCVM 2021",
      x        = "Log total consumption (winsorized)",
      y        = "Predicted effective VAT rate (S3)",
      color    = NULL,
      caption  = "Cluster-robust SE at grappe level. Survey weights. Region FE included."
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.caption    = ggplot2::element_text(size = 7)
    )

  export_fig(fig6, file.path(paths$FIGS, "fig6_margins_income_milieu.png"))

  # ── Non-linearity test ─────────────────────────────────────────────────────
  m_nl <- lm(
    eff_vat_s3 ~ lconso_w + lconso_w2 + hhsize + head_female + educ_high +
      urban + region_fac,
    data    = hh,
    weights = hh$hhweight
  )
  pval_nl <- summary(m_nl)$coefficients["lconso_w2", "Pr(>|t|)"]
  message(sprintf("\n  Non-linearity test (lconso_w^2): p = %.4f — %s",
                  pval_nl,
                  ifelse(pval_nl < 0.10,
                         "H0 rejected -> non-linear form justified",
                         "H0 not rejected -> linear form preferred")))

  invisible(models)
}
