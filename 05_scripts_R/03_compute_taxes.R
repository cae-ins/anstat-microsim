# 03_compute_taxes.R
#
# OBJECTIVE:
# Compute household-level VAT incidence using EHCVM microdata.
#
# APPROACH:
# 1. Compute VAT at item level: vat_item = depan × r_vat_official
# 2. Aggregate to household level (sum across products)
# 3. Compute effective VAT rate: eff_vat = vat / conso
# 4. Build CEQ proxy income concepts: market_income, consumable_income
#
# ASSUMPTIONS:
# - Full pass-through to consumers (static incidence)
# - Only market transactions (modep == 1), applied in step 01
#
# INPUT:  SILVER/01/conso_clean.parquet  (item-level: hhid × product)
# OUTPUT: SILVER/03/fiscal_data.parquet  (household-level)
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

compute_taxes <- function(paths) {

  message(">>> STEP 3: Computing VAT incidence")

  df <- load_parquet(file.path(paths$SILVER, "01", "conso_clean.parquet"))

  # ── VAT at item level ─────────────────────────────────────────────────────
  df <- df %>%
    dplyr::mutate(
      vat_item   = depan   * r_vat_official,
      vat_item_w = depan_w * r_vat_official
    )

  # ── Aggregate to household level ─────────────────────────────────────────
  message(">>> Aggregating to household level")

  hh <- df %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(
      year     = dplyr::first(year),
      hhweight = dplyr::first(hhweight),
      region   = dplyr::first(region),
      milieu   = dplyr::first(milieu),
      conso    = sum(depan,      na.rm = TRUE),
      conso_w  = sum(depan_w,    na.rm = TRUE),
      vat      = sum(vat_item,   na.rm = TRUE),
      vat_w    = sum(vat_item_w, na.rm = TRUE),
      n_items  = dplyr::n(),
      .groups  = "drop"
    )

  # ── Effective VAT rates ───────────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      eff_vat   = vat   / conso,
      eff_vat_w = vat_w / conso_w,
      lconso    = log(conso),
      lconso_w  = log(conso_w)
    )

  # ── CEQ proxy income concepts ─────────────────────────────────────────────
  # market_income     : pre-tax welfare proxy (winsorized consumption)
  # consumable_income : post-indirect-tax welfare (consumption net of VAT)
  hh <- hh %>%
    dplyr::mutate(
      market_income     = conso_w,
      consumable_income = conso_w - vat_w
    )

  # ── Diagnostics ──────────────────────────────────────────────────────────
  message("  n_items summary:")
  print(summary(hh$n_items))

  p_nitems <- ggplot2::ggplot(hh, ggplot2::aes(x = n_items)) +
    ggplot2::geom_histogram(bins = 40, fill = "steelblue",
                             color = "white", alpha = 0.8) +
    ggplot2::labs(
      title = "Number of consumption items per household",
      x = "n_items", y = "Count"
    ) +
    ggplot2::theme_minimal()
  export_fig(p_nitems, file.path(paths$FIGS, "n_items.png"))

  p_lconso <- ggplot2::ggplot(hh, ggplot2::aes(x = lconso_w)) +
    ggplot2::geom_histogram(ggplot2::aes(y = ggplot2::after_stat(density)),
                             bins = 50, fill = "navy",
                             color = "white", alpha = 0.8) +
    ggplot2::stat_function(
      fun  = dnorm,
      args = list(mean = mean(hh$lconso_w, na.rm = TRUE),
                  sd   = sd(hh$lconso_w,   na.rm = TRUE)),
      color = "firebrick", linewidth = 1
    ) +
    ggplot2::labs(
      title    = "Log household consumption (winsorized)",
      subtitle = "With normal density overlay",
      x = "log(conso_w)", y = "Density"
    ) +
    ggplot2::theme_minimal()
  export_fig(p_lconso, file.path(paths$FIGS, "log_conso_w.png"))

  message("\n  Household-level summary:")
  print(summary(hh[c("conso_w", "vat_w", "eff_vat_w")]))

  # ── Save ──────────────────────────────────────────────────────────────────
  save_parquet(hh, file.path(paths$SILVER, "03", "fiscal_data.parquet"))

  invisible(hh)
}
