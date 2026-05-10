# =============================================================================
# Etape 15 — Simulation d'une reforme TVA : hausse de 0 % a 9 %
#
# OBJECTIF :
# Mesurer l'impact distributif d'une reforme TVA qui applique un taux de 9 %
# a des produits actuellement exoneres (r_vat_official == 0).
# Focus : taux de pauvrete (P0/P1/P2) et charge par quintile.
#
# SCENARIOS (modifiables dans la section CONFIG) :
#   S_agri     — produits agricoles bruts (ICIO : A01_02, A03)
#   S_commerce — commerce/distribution (ICIO : G, formalisation)
#   S_all      — tous produits a 0% hors services publics (E, L, P, Q)
#
# APPROCHE :
#   delta_vat_hh = Σ_k (depan_w_k × taux_reforme)  ∀ k dans l'ensemble cible
#   pcexp_reform = pcexp − delta_vat_hh / hhsize
#   Charge relative = delta_vat_hh / (pcexp × hhsize)  par quintile
#
# ENTREE :
#   SILVER/01/conso_clean.parquet
#   SILVER/06/fiscal_sensitivity_taxation.parquet
#   01_data_sources/concordance_codpr_ICIO.csv
#   DATA/ehcvm_welfare_2b_CIV2021.dta
#
# SORTIE :
#   TABLES/15/15_01_fgt_reform_national.xlsx
#   TABLES/15/15_02_burden_by_quintile.xlsx
#   TABLES/15/15_03_fgt_by_quintile.xlsx
#   TABLES/15/15_04_nouveaux_pauvres_reform.xlsx
#   FIGS/fig_reform_burden_quintile.png
#   FIGS/fig_reform_fgt_impact.png
#   SILVER/15/reform_vat_hh.parquet
# =============================================================================
library(dplyr); library(tidyr); library(ggplot2)

source("05_scripts_R/00_setup.R")

SILVER_15 <- file.path(SILVER, "15")
dir.create(SILVER_15, showWarnings = FALSE)
dir.create(file.path(TABLES, "15"), showWarnings = FALSE)

# ── CONFIG ────────────────────────────────────────────────────────────────────
TAUX_REFORME <- 0.09   # taux TVA appliqué aux produits cibles

# Secteurs ICIO exonérés de manière structurelle (hors réforme)
SECTEURS_HORS_REFORME <- c("E", "L", "P", "Q", "T")

# ── 1. CHARGEMENT ─────────────────────────────────────────────────────────────
conc <- read_source_csv(
  path_parts = c("concordance_codpr_ICIO.csv"),
  .label = "codpr-ICIO concordance",
  .required_cols = c("codpr", "secteur_ICIO")
) %>% filter(secteur_ICIO != "hors_champ")

conso <- load_parquet(
  file.path(SILVER, "01", "conso_clean.parquet")
) %>% select(hhid, hhweight, region, milieu, codpr, depan_w, r_vat_official)
assert_required_columns(
  conso,
  c("hhid", "hhweight", "codpr", "depan_w", "r_vat_official"),
  object_name = "conso_clean.parquet"
)

hh_sens <- load_parquet(
  file.path(SILVER, "06", "fiscal_sensitivity_taxation.parquet")
) %>% select(hhid, decile)
assert_required_columns(
  hh_sens,
  c("hhid", "decile"),
  object_name = "fiscal_sensitivity_taxation.parquet"
)

welfare <- load_raw_dta(
  "ehcvm_welfare_2b_CIV2021.dta",
  col_select = c("hhid", "pcexp", "zref", "hhsize")
)

# ── 2. DÉFINITION DES SCÉNARIOS ───────────────────────────────────────────────
# Produits éligibles à la réforme : actuellement à 0% ET hors secteurs
# protégés. On utilise r_vat_official == 0 comme critère direct.
eligible_codpr <- conso %>%
  filter(r_vat_official == 0) %>%
  left_join(conc %>% select(codpr, secteur_ICIO), by = "codpr") %>%
  filter(!secteur_ICIO %in% SECTEURS_HORS_REFORME | is.na(secteur_ICIO)) %>%
  distinct(codpr, secteur_ICIO)

scenarios <- list(
  S_agri     = eligible_codpr %>% filter(secteur_ICIO %in% c("A01_02", "A03"))  %>% pull(codpr),
  S_commerce = eligible_codpr %>% filter(secteur_ICIO == "G")                   %>% pull(codpr),
  S_all      = eligible_codpr$codpr
)

message("\n=== Produits éligibles par scénario ===")
purrr::iwalk(scenarios, ~message(sprintf("  %-12s : %d codpr", .y, length(.x))))

# ── 3. CHARGE TVA ADDITIONNELLE PAR MÉNAGE ────────────────────────────────────
compute_delta_vat <- function(codpr_cibles) {
  conso %>%
    filter(codpr %in% codpr_cibles) %>%
    group_by(hhid) %>%
    summarise(
      delta_vat = sum(depan_w * TAUX_REFORME, na.rm = TRUE),
      .groups   = "drop"
    )
}

delta_vat <- purrr::map(scenarios, compute_delta_vat)

# ── 4. DONNÉES BIEN-ÊTRE ET QUINTILE ──────────────────────────────────────────
base <- welfare %>%
  left_join(hh_sens, by = "hhid") %>%
  filter(!is.na(pcexp), !is.na(zref), !is.na(hhsize), hhsize > 0,
         !is.na(decile)) %>%
  mutate(
    quintile = ceiling(decile / 2),
    w_ind    = hhweight * hhsize   # poids individu pour taux de pauvreté
  )

# ── 5. FONCTIONS UTILITAIRES ──────────────────────────────────────────────────
fgt <- function(y, z, w, alpha) {
  gap <- pmax(0, 1 - y / z)
  if (alpha == 0L) weighted.mean(gap > 0, w, na.rm = TRUE)
  else             weighted.mean(gap^alpha, w, na.rm = TRUE)
}

make_hh_reform <- function(delta_df, hh_data) {
  hh_data %>%
    left_join(delta_df, by = "hhid") %>%
    mutate(
      delta_vat    = replace_na(delta_vat, 0),
      pcexp_reform = pcexp - delta_vat / hhsize,
      # Charge relative : delta_vat annualisé / revenu total ménage
      burden_rel   = delta_vat / (pcexp * hhsize),
      poor_pre     = pcexp        < zref,
      poor_reform  = pcexp_reform < zref,
      new_poor     = (!poor_pre) & poor_reform
    )
}

compute_fgt_scenario <- function(hh, scenario_name) {
  p0_pre <- fgt(hh$pcexp,        hh$zref, hh$w_ind, 0)
  p1_pre <- fgt(hh$pcexp,        hh$zref, hh$w_ind, 1)
  p2_pre <- fgt(hh$pcexp,        hh$zref, hh$w_ind, 2)
  tibble(
    scenario  = scenario_name,
    concept   = c("Avant réforme", sprintf("Après réforme (%s)", scenario_name)),
    p0        = c(p0_pre,
                  fgt(hh$pcexp_reform, hh$zref, hh$w_ind, 0)),
    p1        = c(p1_pre,
                  fgt(hh$pcexp_reform, hh$zref, hh$w_ind, 1)),
    p2        = c(p2_pre,
                  fgt(hh$pcexp_reform, hh$zref, hh$w_ind, 2))
  ) %>%
    mutate(
      delta_p0 = p0 - p0[1],
      delta_p1 = p1 - p1[1],
      delta_p2 = p2 - p2[1]
    )
}

compute_burden_quintile <- function(hh, scenario_name) {
  hh %>%
    group_by(quintile) %>%
    summarise(
      # Charge moyenne par ménage (FCFA/an)
      delta_vat_mean    = weighted.mean(delta_vat,  hhweight, na.rm = TRUE),
      # Charge relative (% du revenu) — clé pour régressivité
      burden_rel_mean   = weighted.mean(burden_rel, hhweight, na.rm = TRUE),
      # Part de la réforme captée par le quintile
      delta_vat_total   = sum(delta_vat * hhweight,  na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      scenario      = scenario_name,
      vat_share_q   = delta_vat_total / sum(delta_vat_total)
    )
}

compute_fgt_quintile <- function(hh, scenario_name) {
  hh %>%
    group_by(quintile) %>%
    summarise(
      p0_pre     = fgt(pcexp,        zref, w_ind, 0L),
      p0_reform  = fgt(pcexp_reform, zref, w_ind, 0L),
      p1_pre     = fgt(pcexp,        zref, w_ind, 1L),
      p1_reform  = fgt(pcexp_reform, zref, w_ind, 1L),
      np_pond    = sum(new_poor * hhweight, na.rm = TRUE),
      .groups    = "drop"
    ) %>%
    mutate(
      scenario   = scenario_name,
      delta_p0   = p0_reform - p0_pre
    )
}

# ── 6. CALCULS PAR SCÉNARIO ───────────────────────────────────────────────────
results <- purrr::imap(delta_vat, function(dv, sc) {
  hh <- make_hh_reform(dv, base)
  list(
    hh        = hh,
    fgt_nat   = compute_fgt_scenario(hh, sc),
    burden_q  = compute_burden_quintile(hh, sc),
    fgt_q     = compute_fgt_quintile(hh, sc)
  )
})

# ── 7. TABLES NATIONALES ──────────────────────────────────────────────────────
fgt_national <- purrr::map_dfr(results, "fgt_nat")

message("\n=== FGT national — impact des scénarios de réforme ===")
print(fgt_national %>% select(scenario, concept, p0, delta_p0, p1, p2))

export_excel(fgt_national,
             file.path(TABLES, "15", "15_01_fgt_reform_national.xlsx"))

# ── 8. CHARGE PAR QUINTILE ────────────────────────────────────────────────────
burden_quintile <- purrr::map_dfr(results, "burden_q")

message("\n=== Charge TVA par quintile (scénario S_all) ===")
print(burden_quintile %>%
  filter(scenario == "S_all") %>%
  select(quintile, delta_vat_mean, burden_rel_mean, vat_share_q))

export_excel(burden_quintile,
             file.path(TABLES, "15", "15_02_burden_by_quintile.xlsx"))

# ── 9. FGT PAR QUINTILE ───────────────────────────────────────────────────────
fgt_quintile <- purrr::map_dfr(results, "fgt_q")

export_excel(fgt_quintile,
             file.path(TABLES, "15", "15_03_fgt_by_quintile.xlsx"))

# ── 10. NOUVEAUX PAUVRES ──────────────────────────────────────────────────────
np_table <- purrr::map_dfr(names(results), function(sc) {
  hh <- results[[sc]]$hh
  hh %>%
    group_by(quintile) %>%
    summarise(
      np_pond = sum(new_poor * hhweight, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(scenario = sc)
}) %>%
  pivot_wider(names_from = scenario, values_from = np_pond, names_prefix = "np_")

np_totaux <- purrr::map_dfr(names(results), function(sc) {
  hh <- results[[sc]]$hh
  tibble(
    scenario    = sc,
    np_total    = sum(hh$new_poor * hh$hhweight, na.rm = TRUE),
    np_q1       = sum(hh$new_poor * hh$hhweight * (hh$quintile == 1), na.rm = TRUE),
    np_q2       = sum(hh$new_poor * hh$hhweight * (hh$quintile == 2), na.rm = TRUE),
    share_q1_q2 = (np_q1 + np_q2) / np_total
  )
})

message("\n=== Nouveaux pauvres générés par la réforme ===")
print(np_totaux %>%
  mutate(across(c(np_total, np_q1, np_q2),
                ~format(round(.), big.mark = ","))))

export_excel(np_table,
             file.path(TABLES, "15", "15_04a_nouveaux_pauvres_par_quintile.xlsx"))
export_excel(np_totaux,
             file.path(TABLES, "15", "15_04b_nouveaux_pauvres_totaux.xlsx"))

# ── 11. QUINTILE LE PLUS TOUCHÉ (résumé) ─────────────────────────────────────
message("\n=== Quintile le plus touché par la réforme (charge relative) ===")
purrr::iwalk(results, function(res, sc) {
  q_max <- res$burden_q %>%
    filter(quintile == quintile[which.max(burden_rel_mean)])
  message(sprintf(
    "  %-12s : Q%d — charge relative %.2f%% (%.0f FCFA/ménage)",
    sc, q_max$quintile, q_max$burden_rel_mean * 100, q_max$delta_vat_mean
  ))
})

# ── 12. FIGURE — Charge relative par quintile ────────────────────────────────
fig_burden <- ggplot(
  burden_quintile,
  aes(x = factor(quintile), y = burden_rel_mean * 100, fill = scenario)
) +
  geom_col(position = "dodge", width = 0.75) +
  scale_fill_manual(values = c(
    S_agri     = "darkgreen",
    S_commerce = "steelblue",
    S_all      = "firebrick"
  ),
  labels = c(
    S_agri     = "Agricole (A01_02+A03)",
    S_commerce = "Commerce (G)",
    S_all      = "Tous produits à 0%"
  )) +
  labs(
    title    = "Charge de la réforme TVA par quintile de consommation",
    subtitle = sprintf(
      "Hausse de 0%% à %.0f%% — Côte d'Ivoire, EHCVM 2021",
      TAUX_REFORME * 100
    ),
    x    = "Quintile (Q1 = plus pauvre)",
    y    = "Charge relative (% du revenu de consommation)",
    fill = "Scénario",
    caption = paste0(
      "Charge relative = TVA additionnelle / (pcexp × hhsize).\n",
      "Pondérations sondage. Q1 = 20% les plus pauvres."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        plot.caption    = element_text(size = 7))

export_fig(fig_burden,
           file.path(FIGS, "fig_reform_burden_quintile.png"))

# ── 13. FIGURE — ΔP0 par quintile × scénario ─────────────────────────────────
fig_fgt <- ggplot(
  fgt_quintile,
  aes(x = factor(quintile), y = delta_p0 * 100, fill = scenario)
) +
  geom_col(position = "dodge", width = 0.75) +
  scale_fill_manual(values = c(
    S_agri     = "darkgreen",
    S_commerce = "steelblue",
    S_all      = "firebrick"
  ),
  labels = c(
    S_agri     = "Agricole (A01_02+A03)",
    S_commerce = "Commerce (G)",
    S_all      = "Tous produits à 0%"
  )) +
  labs(
    title    = "Impact de la réforme TVA sur le taux de pauvreté par quintile",
    subtitle = sprintf(
      "ΔP0 (pp) — hausse de 0%% à %.0f%% — Côte d'Ivoire, EHCVM 2021",
      TAUX_REFORME * 100
    ),
    x    = "Quintile (Q1 = plus pauvre)",
    y    = "\u0394 P0 (points de pourcentage)",
    fill = "Scénario",
    caption = paste0(
      "Pondérations individu (hhweight × hhsize).\n",
      "P0 avant réforme = 37.5% (cible officielle EHCVM)."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        plot.caption    = element_text(size = 7))

export_fig(fig_fgt,
           file.path(FIGS, "fig_reform_fgt_impact.png"))

# ── 14. SAUVEGARDE PARQUET ────────────────────────────────────────────────────
hh_all <- purrr::imap_dfr(results, function(res, sc) {
  res$hh %>%
    select(hhid, hhweight, quintile, decile, pcexp, zref,
           delta_vat, pcexp_reform, burden_rel,
           poor_pre, poor_reform, new_poor) %>%
    mutate(scenario = sc)
})

save_parquet(hh_all,
             file.path(SILVER_15, "reform_vat_hh.parquet"))

message("\nÉtape 15 terminée — outputs dans ", SILVER_15, " et ", file.path(TABLES, "15"))
