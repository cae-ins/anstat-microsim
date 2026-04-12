# 01_prepare_data.R
#
# OBJECTIVE:
# Construct a clean, consistent expenditure dataset for VAT incidence analysis.
#
# KEY STEPS:
# 1. Load EHCVM raw consumption data
# 2. Validate identifiers
# 3. Restrict to market-based transactions (modep == 1)
# 4. Winsorize expenditure at 99th percentile
# 5. Export diagnostic tables and figures
# 6. Save cleaned dataset as parquet
#
# INPUT:  DATA/ehcvm_conso_civ2021.dta  (item-level: hhid × product)
# OUTPUT: SILVER/01/conso_clean.parquet
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

prepare_data <- function(paths) {

  message(">>> STEP 1: Loading raw consumption data")

  df <- haven::read_dta(
    file.path(paths$DATA, "ehcvm_conso_civ2021.dta")
  )

  # ── Validate identifiers ──────────────────────────────────────────────────
  stopifnot(
    "hhid must be non-missing" = !anyNA(df$hhid),
    "codpr must be non-missing" = !anyNA(df$codpr)
  )
  message(sprintf("  Rows: %s | Households: %s | Products: %s",
                  format(nrow(df), big.mark = ","),
                  format(dplyr::n_distinct(df$hhid), big.mark = ","),
                  format(dplyr::n_distinct(df$codpr), big.mark = ",")))

  # ── Summary statistics on raw depan ──────────────────────────────────────
  summary_raw <- df %>%
    dplyr::summarise(
      N        = dplyr::n(),
      Mean     = mean(depan, na.rm = TRUE),
      SD       = sd(depan, na.rm = TRUE),
      P1       = quantile(depan, 0.01, na.rm = TRUE),
      P5       = quantile(depan, 0.05, na.rm = TRUE),
      P10      = quantile(depan, 0.10, na.rm = TRUE),
      P25      = quantile(depan, 0.25, na.rm = TRUE),
      Median   = quantile(depan, 0.50, na.rm = TRUE),
      P75      = quantile(depan, 0.75, na.rm = TRUE),
      P90      = quantile(depan, 0.90, na.rm = TRUE),
      P95      = quantile(depan, 0.95, na.rm = TRUE),
      P99      = quantile(depan, 0.99, na.rm = TRUE),
      Min      = min(depan, na.rm = TRUE),
      Max      = max(depan, na.rm = TRUE),
      Skewness = (mean((depan - mean(depan, na.rm = TRUE))^3, na.rm = TRUE) /
                  sd(depan, na.rm = TRUE)^3),
      Kurtosis = (mean((depan - mean(depan, na.rm = TRUE))^4, na.rm = TRUE) /
                  sd(depan, na.rm = TRUE)^4)
    ) %>%
    tidyr::pivot_longer(dplyr::everything(),
                        names_to = "stat", values_to = "depan")

  export_excel(summary_raw,
               file.path(paths$TABLES, "01", "summary_depan_raw.xlsx"))

  # ── Restrict to market-based transactions ────────────────────────────────
  # modep: 1=Purchase 2=Own-consumption 3=Gift 4=Use value 5=Imputed rent
  # VAT applies only to market transactions (CEQ methodology)
  message(">>> Restricting to market-based consumption (modep == 1)")
  df <- df %>% dplyr::filter(modep == 1)
  message(sprintf("  Rows after filter: %s", format(nrow(df), big.mark = ",")))

  # ── Winsorize at 99th percentile ─────────────────────────────────────────
  p99  <- quantile(df$depan, 0.99, na.rm = TRUE)
  df   <- df %>%
    dplyr::mutate(
      log_depan = log(depan),
      depan_w   = pmin(depan, p99)
    )

  # ── Diagnostic figure: log(depan) distribution ───────────────────────────
  p_logdepan <- ggplot2::ggplot(df, ggplot2::aes(x = log_depan)) +
    ggplot2::geom_histogram(bins = 60, fill = "steelblue",
                             color = "white", alpha = 0.8) +
    ggplot2::labs(
      title   = "Distribution of log(depan) after cleaning",
      subtitle = "Market purchases only (modep == 1)",
      x = "log(annual expenditure per item, CFA)",
      y = "Count"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  export_fig(p_logdepan,
             file.path(paths$FIGS, "log_depan_af_cleaning.png"))

  # ── Convert Stata labelled columns to factors ─────────────────────────────
  df <- haven::as_factor(df)

  # ── Save cleaned dataset ──────────────────────────────────────────────────
  message(">>> Saving cleaned consumption dataset")
  save_parquet(df, file.path(paths$SILVER, "01", "conso_clean.parquet"))

  invisible(df)
}
