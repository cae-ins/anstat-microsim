# 03_compute_taxes.R
#
# OBJECTIF :
# Calculer l'incidence de la TVA au niveau menage en utilisant les microdonnees EHCVM.
#
# APPROCHE :
# 1. Calculer la TVA au niveau item: vat_item = depan × r_vat_official
# 2. Agreger au niveau menage (somme a travers les produits)
# 3. Calculer le taux TVA effectif: eff_vat = vat / conso
# 4. Construire les concepts de revenu proxy CEQ: market_income, consumable_income
#
# HYPOTHESES :
# - Transfert complet sur les consommateurs (incidence statique)
# - Transactions marchandes uniquement (modep == 1), applique a l'etape 01
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
      vat_item   = depan   * r_vat_official,
      vat_item_w = depan_w * r_vat_official
    )

  # ── Agreger au niveau menage ─────────────────────────────────────────
  message(">>> Agregation au niveau menage")

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
  hh <- hh %>%
    dplyr::mutate(
      market_income     = conso_w,
      consumable_income = conso_w - vat_w
    )

  # ── Sauvegarder ─────────────────────────────────────────────────
  message(">>> Sauvegarde des donnees fiscales au niveau menage")
  save_parquet(hh, file.path(paths$SILVER, "03", "fiscal_data.parquet"))

  invisible(hh)
}