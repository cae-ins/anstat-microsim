# 02_mapping_tax.R
#
# OBJECTIVE:
# Build a clean VAT mapping from the official CGI 2026 table, then merge
# it with the cleaned consumption data.
#
# KEY STEPS:
# 1. Import Excel VAT mapping (sheet TVA_detail)
# 2. Handle "Hors champ" (out-of-scope) products
# 3. Clean and convert VAT rate strings to proportions
# 4. Merge with conso_clean
# 5. Keep only matched, in-scope observations
# 6. Label variables and save
#
# INPUT:  DATA/COPR_EHCVM_TVA_renseigne.xlsx (sheet TVA_detail)
#         SILVER/01/conso_clean.parquet
# OUTPUT: SILVER/02/mapping_fiscal_official.parquet
#         SILVER/01/conso_clean.parquet  (updated with fiscal variables)
#
# NOTES:
# - Merge key: code + produit
# - VAT rates stored as proportions: 0, 0.09, 0.18
# - hors_champ == 1 for products outside VAT scope OR non-market acquisitions
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata)
# R rewrite: rewrite-r branch

map_tax <- function(paths) {

  message(">>> STEP 2: Loading and cleaning VAT mapping")

  # ── Import Excel mapping ──────────────────────────────────────────────────
  raw <- readxl::read_excel(
    file.path(paths$ROOT, "01_data_sources", "COPR_EHCVM_TVA_renseigne.xlsx"),
    sheet = "TVA_detail"
  )

  # ── Handle "Hors champ" ───────────────────────────────────────────────────
  # "Hors champ" = outside VAT scope; mode != "Achat" = non-market acquisition
  mapping <- raw %>%
    dplyr::mutate(
      hors_champ = as.integer(
        trimws(TVA_statutaire) == "Hors champ" | mode != "Achat"
      ),
      TVA_statutaire = dplyr::if_else(
        trimws(TVA_statutaire) == "Hors champ",
        "9999", TVA_statutaire
      )
    ) %>%
    dplyr::mutate(
      TVA_clean      = gsub("[%* ]", "", TVA_statutaire),
      TVA_num        = suppressWarnings(as.numeric(TVA_clean)),
      r_vat_official = TVA_num / 100
    ) %>%
    dplyr::select(code, produit, hors_champ, r_vat_official) %>%
    dplyr::mutate(source = "official") %>%
    dplyr::arrange(code, produit)

  # ── Diagnostics ───────────────────────────────────────────────────────────
  message("  VAT rate distribution:")
  print(table(mapping$r_vat_official, useNA = "ifany"))
  message("  Hors champ: ", sum(mapping$hors_champ, na.rm = TRUE))

  save_parquet(mapping,
               file.path(paths$SILVER, "02", "mapping_fiscal_official.parquet"))

  # ── Merge with consumption data ───────────────────────────────────────────
  message(">>> Merging mapping with consumption data")

  conso <- load_parquet(file.path(paths$SILVER, "01", "conso_clean.parquet"))

  # Prepare merge keys (code + produit as character)
  conso <- conso %>%
    dplyr::mutate(
      code    = as.character(as.integer(codpr)),
      produit = as.character(produit)
    )

  mapping_chr <- mapping %>%
    dplyr::mutate(
      code    = as.character(code),
      produit = as.character(produit)
    )

  merged <- conso %>%
    dplyr::left_join(mapping_chr, by = c("code", "produit"))

  # ── Merge diagnostics ─────────────────────────────────────────────────────
  n_matched   <- sum(!is.na(merged$r_vat_official))
  n_unmatched <- sum(is.na(merged$r_vat_official))
  message(sprintf("  Matched: %s | Unmatched (will be dropped): %s",
                  format(n_matched, big.mark = ","),
                  format(n_unmatched, big.mark = ",")))

  if (n_unmatched > 0) {
    message("  Unmatched products (sample):")
    unmatched_sample <- merged %>%
      dplyr::filter(is.na(r_vat_official)) %>%
      dplyr::distinct(code, produit) %>%
      head(10)
    print(unmatched_sample)
  }

  # ── Keep matched, in-scope observations only ──────────────────────────────
  merged_clean <- merged %>%
    dplyr::filter(!is.na(r_vat_official)) %>%
    dplyr::filter(hors_champ == 0)

  message(sprintf("  Rows after scope filter: %s",
                  format(nrow(merged_clean), big.mark = ",")))

  # ── Save updated conso_clean with fiscal variables ────────────────────────
  save_parquet(merged_clean,
               file.path(paths$SILVER, "01", "conso_clean.parquet"))

  message(">>> Official VAT mapping cleaned, merged, and saved")
  invisible(merged_clean)
}
