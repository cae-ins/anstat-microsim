# 03_compute_taxes.R
#
# OBJECTIF :
# Calculer l'incidence de la TVA au niveau menage en utilisant les microdonnees EHCVM.
#
# APPROCHE :
# 1. Extraire la TVA d'une depense TTC: vat_item = depan x r / (1 + r)
# 2. Agreger au niveau menage (somme a travers les produits)
# 3. Calculer le taux TVA effectif: eff_vat = vat / conso
# 4. Ancrer le scenario PDI sur yd_pc = pcexp et construire yc_pc_vat
#
# HYPOTHESES :
# - Transfert complet sur les consommateurs (incidence statique)
# - Achats et valeurs d'usage retenus comme dans le do-file Banque mondiale
#
# ENTREE:  SILVER/01/conso_clean.parquet  (niveau item: hhid × produit)
# SORTIE: SILVER/03/fiscal_data.parquet  (niveau menage)
#
# AUTEUR: Armand Kouakou Djaha, MSc (version Stata originale)
# Traduction R: rewrite-r branch

compute_taxes <- function(paths) {

  message(">>> ETAPE 3: Calcul de l'incidence TVA")

  df <- load_parquet(file.path(paths$SILVER, "01", "conso_clean.parquet"))

  # ── TVA au niveau item ─────────────────────────────────────────────────────
  df <- df %>%
    dplyr::mutate(
      vat_content_share = r_vat_official / (1 + r_vat_official),
      vat_item   = depan   * vat_content_share,
      vat_item_w = depan_w * vat_content_share
    )

  # ── Agreger au niveau menage ─────────────────────────────────────────
  message(">>> Agregation au niveau menage")

  hh <- df %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(
      year     = dplyr::first(year),
      grappe   = dplyr::first(grappe),
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

  # ── Taux TVA effectif ─────────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      eff_vat   = vat   / conso,
      eff_vat_w = vat_w / conso_w
    )

  # ── Variables log ───────────────────────────────────────────────────
  hh <- hh %>%
    dplyr::mutate(
      lconso   = log(conso),
      lconso_w = log(conso_w)
    )

  # ── Concepts proxy CEQ ─────────────────────────────────────────────
  welfare <- load_raw_dta(
    'ehcvm_welfare_2b_CIV2021.dta',
    col_select = c('hhid', 'pcexp', 'zref', 'hhsize', 'def_spa', 'def_temp')
  )

  hh <- hh %>%
    dplyr::left_join(welfare, by = 'hhid') %>%
    dplyr::mutate(
      pcweight = hhweight * hhsize,
      strata = paste(as.character(region), as.character(milieu), sep = '_'),
      yd_pc = pcexp,
      yd_hh = pcexp * hhsize,
      vat_real = vat * def_spa,
      vat_w_real = vat_w * def_spa,
      yc_pc_vat = yd_pc - vat_w_real / hhsize,
      disposable_income = yd_hh,
      consumable_income = yd_hh - vat_w_real
    )

  # ── Sauvegarder ─────────────────────────────────────────────────
  message(">>> Sauvegarde des donnees fiscales au niveau menage")
  save_parquet(hh, file.path(paths$SILVER, "03", "fiscal_data.parquet"))

  invisible(hh)
}
