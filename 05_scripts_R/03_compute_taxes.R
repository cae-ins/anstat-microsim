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
# - Seuls les achats déclarés sont retenus; les valeurs d'usage sont exclues
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
      vat_item = depan_raw * vat_content_share,
      vat_item_w_p95 = depan_w_p95 * vat_content_share,
      vat_item_w = depan_w * vat_content_share,
      vat_item_w_p995 = depan_w_p995 * vat_content_share
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
      conso = sum(depan_raw, na.rm = TRUE),
      conso_w_p95 = sum(depan_w_p95, na.rm = TRUE),
      conso_w = sum(depan_w, na.rm = TRUE),
      conso_w_p995 = sum(depan_w_p995, na.rm = TRUE),
      vat = sum(vat_item, na.rm = TRUE),
      vat_w_p95 = sum(vat_item_w_p95, na.rm = TRUE),
      vat_w = sum(vat_item_w, na.rm = TRUE),
      vat_w_p995 = sum(vat_item_w_p995, na.rm = TRUE),
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
      vat_w_p95_real = vat_w_p95 * def_spa,
      vat_w_real = vat_w * def_spa,
      vat_w_p995_real = vat_w_p995 * def_spa,
      yc_pc_vat = yd_pc - vat_w_real / hhsize,
      disposable_income = yd_hh,
      consumable_income = yd_hh - vat_w_real
    )

  winsor_scenarios <- tibble::tribble(
    ~scenario, ~tax_var,
    "Sans winsorisation", "vat_real",
    "P95", "vat_w_p95_real",
    "P99 (central)", "vat_w_real",
    "P99,5", "vat_w_p995_real"
  )
  winsor_impact <- purrr::pmap_dfr(winsor_scenarios, function(scenario, tax_var) {
    welfare_after <- hh$yd_pc - hh[[tax_var]] / hh$hhsize
    tibble::tibble(
      scenario = scenario,
      tva_milliards_fcfa = sum(hh[[tax_var]] / hh$def_spa * hh$hhweight) / 1e9,
      taux_pauvrete = fgt_index(welfare_after, hh$zref, hh$pcweight, 0),
      gini_apres_tva = weighted_gini(pmax(welfare_after, 0), hh$pcweight)
    )
  }) |>
    dplyr::mutate(
      ecart_tva_vs_p99_pct = 100 * (tva_milliards_fcfa /
        tva_milliards_fcfa[scenario == "P99 (central)"] - 1),
      ecart_pauvrete_vs_p99_points = 100 * (taux_pauvrete -
        taux_pauvrete[scenario == "P99 (central)"])
    )
  export_excel(
    winsor_impact,
    file.path(paths$TABLES, "03", "03_02_winsorization_sensitivity.xlsx")
  )

  # ── Sauvegarder ─────────────────────────────────────────────────
  message(">>> Sauvegarde des donnees fiscales au niveau menage")
  save_parquet(hh, file.path(paths$SILVER, "03", "fiscal_data.parquet"))

  invisible(hh)
}
