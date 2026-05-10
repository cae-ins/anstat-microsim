# 02_mapping_tax.R
#
# OBJECTIF :
# Construire un mapping TVA propre a partir du tableau CGI 2026 officiel, puis le fusionner
# avec les donnees de consommation nettoyees.
#
# ETAPES CLES :
# 1. Importer le mapping Excel TVA (feuille TVA_detail)
# 2. Gerer les produits "Hors champ" (hors du champ TVA)
# 3. Nettoyer et convertir les chaines de taux TVA en proportions
# 4. Fusionner avec conso_clean
# 5. Garder uniquement les observations correspondantes et hors champ
# 6. Etiqueter les variables et sauvegarder
#
# ENTREE:  DATA/COPR_EHCVM_TVA_renseigne.xlsx (feuille TVA_detail)
#         SILVER/01/conso_clean.parquet
# SORTIE: SILVER/02/mapping_fiscal_official.parquet
#         SILVER/01/conso_clean.parquet  (mise a jour avec variables fiscales)
#
# NOTES :
# - Cle de fusion: code + produit
# - Taux TVA stockes en proportions: 0, 0,09, 0,18
# - hors_champ == 1 pour produits hors champ TVA OU acquisitions non marchandes
#
# AUTEUR: Armand Kouakou Djaha, MSc (version Stata originale)
# Traduction R: rewrite-r branch

map_tax <- function(paths) {

  message(">>> ETAPE 2: Chargement et nettoyage du mapping TVA")

  # ── Importer le mapping Excel ──────────────────────────────────────────────────
  raw <- read_source_excel(
    path_parts = c("COPR_EHCVM_TVA_renseigne.xlsx"),
    sheet = "TVA_detail",
    .label = "Classeur de mapping TVA",
    .required_cols = c("code", "produit", "mode", "TVA_statutaire")
  )

  # ── Gerer le "Hors champ" ───────────────────────────────────────────────────
  # "Hors champ" = hors du champ TVA ; mode != "Achat" = acquisition non marchande
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
  message("  Distribution des taux TVA:")
  print(table(mapping$r_vat_official, useNA = "ifany"))
  message("  Hors champ: ", sum(mapping$hors_champ, na.rm = TRUE))

  save_parquet(mapping,
               file.path(paths$SILVER, "02", "mapping_fiscal_official.parquet"))

  # ── Fusionner avec les donnees de consommation ───────────────────────────────────────────
  message(">>> Fusion du mapping avec les donnees de consommation")

  conso <- load_parquet(file.path(paths$SILVER, "01", "conso_clean.parquet"))

  # Preparer les cles de fusion (code + produit en caractere)
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

  # ── Diagnostics de la fusion ─────────────────────────────────────────────────────
  n_matched   <- sum(!is.na(merged$r_vat_official))
  n_unmatched <- sum(is.na(merged$r_vat_official))
  message(sprintf("  Correspondants: %s | Non correspondants (seront supprimes): %s",
                  format(n_matched, big.mark = ","),
                  format(n_unmatched, big.mark = ",")))

  if (n_unmatched > 0) {
    message("  Produits non correspondants (echantillon):")
    unmatched_sample <- merged %>%
      dplyr::filter(is.na(r_vat_official)) %>%
      dplyr::distinct(code, produit) %>%
      head(10)
    print(unmatched_sample)
  }

  # ── Garder uniquement les observations correspondantes et hors champ ──────────────────────────────
  merged_clean <- merged %>%
    dplyr::filter(!is.na(r_vat_official)) %>%
    dplyr::filter(hors_champ == 0)

  message(sprintf("  Lignes apres filtre de champ: %s",
                  format(nrow(merged_clean), big.mark = ",")))

  # ── Sauvegarder conso_clean mis a jour avec variables fiscales ────────────────────────
  save_parquet(merged_clean,
               file.path(paths$SILVER, "01", "conso_clean.parquet"))

  message(">>> Mapping TVA officiel nettoye, fusionne et sauvegarde")
  invisible(merged_clean)
}