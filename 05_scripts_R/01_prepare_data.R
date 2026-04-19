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

  # ── Decode codpr labels (equivalent to Stata: decode codpr, gen(produit)) ─
  codpr_labels <- attr(df$codpr, "labels")
  if (!is.null(codpr_labels)) {
    label_lookup <- setNames(names(codpr_labels), as.character(codpr_labels))
    df$produit <- label_lookup[as.character(as.double(df$codpr))]
  }
  df$codpr <- as.double(df$codpr)

  # ── Map codpr to COICOP division (EHCVM-II CIV2021 nomenclature) ────────
  # Based on EHCVM questionnaire structure and COICOP-HBS classification
  df$coicop <- dplyr::case_when(
    # 1 - Food and non-alcoholic beverages
    df$codpr %in% 1:163   ~ 1L,
    df$codpr %in% 166:177  ~ 1L,
    # 2 - Alcoholic beverages, tobacco
    df$codpr %in% c(164, 165, 197, 201, 301, 302) ~ 2L,
    # 3 - Clothing and footwear
    df$codpr == 401        ~ 3L,    # shoe repair
    df$codpr %in% 501:521  ~ 3L,
    # 4 - Housing, water, electricity, gas, fuels
    df$codpr %in% 202:207  ~ 4L,    # kerosene, charcoal, firewood, candles
    df$codpr %in% 303:305  ~ 4L,    # gas, generator fuel, batteries
    df$codpr %in% 330:334  ~ 4L,    # rent, water, electricity
    df$codpr %in% 601:602  ~ 4L,    # housing maintenance
    df$codpr %in% 609:612  ~ 4L,    # utility connection fees
    df$codpr %in% 618:619  ~ 4L,    # solar panels
    # 5 - Furnishings, household equipment, routine maintenance
    df$codpr == 217        ~ 5L,    # grain milling
    df$codpr %in% 306:310  ~ 5L,    # soap, detergent, insecticide, maid, laundry
    df$codpr == 402        ~ 5L,    # light bulbs
    df$codpr %in% 613:617  ~ 5L,    # furniture, linen
    df$codpr %in% 620:625  ~ 5L,    # appliance repair, cookware, utensils
    # 6 - Health
    df$codpr == 416        ~ 6L,    # OTC medications
    df$codpr == 419        ~ 6L,    # contraceptives
    df$codpr %in% 761:777  ~ 6L,    # consultations, exams, hospitalization
    # 7 - Transport
    df$codpr %in% 208:215  ~ 7L,    # fuel, urban transport
    df$codpr %in% 311:312  ~ 7L,    # vehicle wash, parking
    df$codpr %in% 403:407  ~ 7L,    # lubricants, vehicle repair, intercity transport
    df$codpr == 421        ~ 7L,    # toll
    df$codpr %in% 626:636  ~ 7L,    # vehicle purchase, parts, insurance, rental, travel
    # 8 - Information and communication
    df$codpr == 313        ~ 8L,    # phone booth
    df$codpr %in% 335:338  ~ 8L,    # phone, internet, cable TV, mobile recharge
    df$codpr %in% 408:409  ~ 8L,    # post, fax
    df$codpr == 420        ~ 8L,    # photocopies
    df$codpr %in% 637:641  ~ 8L,    # phone, electronics purchase, repair
    # 9 - Recreation, sport, culture
    df$codpr == 216        ~ 9L,    # newspapers
    df$codpr %in% 314:315  ~ 9L,    # lottery, magazines
    df$codpr %in% 410:414  ~ 9L,    # gardening, pets, sports, cinema
    df$codpr %in% 642:644  ~ 9L,    # sports items, books, stationery
    # 10 - Education
    df$codpr %in% 646:647  ~ 10L,   # professional training, tutoring
    df$codpr %in% 701:748  ~ 10L,   # all education levels
    # 11 - Restaurants and accommodation
    df$codpr %in% 191:196  ~ 11L,   # meals outside home
    df$codpr == 648        ~ 11L,   # hotel
    # 12 - Insurance and financial services
    df$codpr %in% 652:657  ~ 12L,   # insurance, administrative fees
    # 13 - Personal care, social protection, miscellaneous
    df$codpr %in% 316:324  ~ 13L,   # hairdressing, toiletries, personal hygiene
    df$codpr == 415        ~ 13L,   # washable COVID mask
    df$codpr %in% 417:418  ~ 13L,   # perfume, toothbrush
    df$codpr %in% 645:645  ~ 13L,   # pilgrimage
    df$codpr %in% 649:651  ~ 13L,   # watches, jewelry, personal effects
    df$codpr == 658        ~ 13L,   # other services (funeral, etc.)
    # 98 - Non-consumption: use value of durables
    df$codpr %in% 801:843  ~ 98L,
    # 99 - Non-consumption: ceremonies
    df$codpr %in% 901:912  ~ 99L,
    # Residual
    TRUE                   ~ 99L
  )
  message(sprintf("  COICOP assigned: %d obs | Missing: %d",
                  sum(!is.na(df$coicop)), sum(is.na(df$coicop))))

  # ── Convert remaining Stata labelled columns to factors ──────────────────
  df <- haven::as_factor(df)

  # ── Save cleaned dataset ──────────────────────────────────────────────────
  message(">>> Saving cleaned consumption dataset")
  save_parquet(df, file.path(paths$SILVER, "01", "conso_clean.parquet"))

  invisible(df)
}
