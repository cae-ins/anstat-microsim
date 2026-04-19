# =============================================================================
# Étape 14 — Incidence de la TVA enchâssée (I/O) sur la pauvreté
# Étend l'étape 12 en ajoutant la composante TVA enchâssée via Leontief
#
# APPROCHE :
#   pcexp_io = pcexp - (vat_direct + vat_emb) / hhsize
#
#   Trois comparaisons par scénario d'informalité (strict / s2 / s3) :
#     (A) Avant TVA       : pcexp
#     (B) Après direct    : pcexp - vat_direct / hhsize        [step 12]
#     (C) Après total I/O : pcexp - (vat_direct + vat_emb) / hhsize  [step 14]
#
# INPUT :  SILVER/06/fiscal_sensitivity_taxation.parquet  (vat_strict/s2/s3, decile)
#          SILVER/13/fiscal_data_io.parquet               (vat_emb)
#          DATA/ehcvm_welfare_2b_CIV2021.dta              (pcexp, zref, hhsize)
# OUTPUT : TABLES/14/14_01_fgt_comparison.xlsx
#          TABLES/14/14_02_fgt_milieu.xlsx
#          TABLES/14/14_03_fgt_region.xlsx
#          TABLES/14/14_04_nouveaux_pauvres_io.xlsx
#          FIGS/fig_poverty_io_impact.png
# =============================================================================
library(dplyr); library(tidyr); library(ggplot2); library(readr)

source("05_scripts_R/00_setup.R")

SILVER_14 <- file.path(SILVER, "14")
dir.create(SILVER_14, showWarnings = FALSE)
dir.create(file.path(TABLES, "14"), showWarnings = FALSE)

# ── 1. CHARGEMENT ─────────────────────────────────────────────────────────────
hh_sens <- arrow::read_parquet(
  file.path(SILVER, "06", "fiscal_sensitivity_taxation.parquet")
)

hh_io <- arrow::read_parquet(
  file.path(SILVER, "13", "fiscal_data_io.parquet")
) %>% select(hhid, vat_emb)

welfare <- load_raw_dta(
  "ehcvm_welfare_2b_CIV2021.dta",
  col_select = c("hhid", "pcexp", "zref", "hhsize")
)

# ── 2. JOINTURE ET CONCEPTS DE BIEN-ÊTRE ─────────────────────────────────────
hh <- hh_sens %>%
  left_join(hh_io,   by = "hhid") %>%
  left_join(welfare, by = "hhid") %>%
  mutate(vat_emb = replace_na(vat_emb, 0)) %>%
  filter(!is.na(pcexp), !is.na(zref), !is.na(hhsize), hhsize > 0) %>%
  mutate(w_ind = hhweight * hhsize)

n_miss <- nrow(hh_sens) - nrow(hh)
if (n_miss > 0)
  warning(sprintf("%d ménages exclus (pcexp/zref/hhsize manquants)", n_miss))

hh <- hh %>%
  mutate(
    # (A) Avant TVA
    pcexp_pre         = pcexp,
    # (B) Après TVA directe seulement
    pcexp_direct_s1   = pcexp - vat_strict / hhsize,
    pcexp_direct_s2   = pcexp - vat_s2     / hhsize,
    pcexp_direct_s3   = pcexp - vat_s3     / hhsize,
    # (C) Après TVA totale (directe + enchâssée I/O)
    pcexp_io_s1       = pcexp - (vat_strict + vat_emb) / hhsize,
    pcexp_io_s2       = pcexp - (vat_s2     + vat_emb) / hhsize,
    pcexp_io_s3       = pcexp - (vat_s3     + vat_emb) / hhsize
  )

# ── 3. FONCTION FGT ───────────────────────────────────────────────────────────
fgt <- function(y, z, w, alpha) {
  gap <- pmax(0, 1 - y / z)
  if (alpha == 0L) weighted.mean(gap > 0, w, na.rm = TRUE)
  else             weighted.mean(gap^alpha, w, na.rm = TRUE)
}

welfare_vars <- c(
  "pcexp_pre",
  "pcexp_direct_s1", "pcexp_direct_s2", "pcexp_direct_s3",
  "pcexp_io_s1",     "pcexp_io_s2",     "pcexp_io_s3"
)
welfare_labels <- c(
  "pcexp_pre"       = "Avant TVA",
  "pcexp_direct_s1" = "Direct — Strict",
  "pcexp_direct_s2" = "Direct — S2 (CEI x milieu)",
  "pcexp_direct_s3" = "Direct — S3 (CEI x décile)",
  "pcexp_io_s1"     = "Total I/O — Strict",
  "pcexp_io_s2"     = "Total I/O — S2 (CEI x milieu)",
  "pcexp_io_s3"     = "Total I/O — S3 (CEI x décile)"
)

compute_fgt_table <- function(data, group_var = NULL) {
  p0_ref <- fgt(data$pcexp_pre, data$zref, data$hhweight, 0)
  purrr::map_dfr(welfare_vars, function(wv) {
    fn <- function(df) {
      p0_base <- fgt(df$pcexp_pre, df$zref, df$w_ind, 0)
      tibble(
        concept  = welfare_labels[[wv]],
        p0       = fgt(df[[wv]], df$zref, df$w_ind, 0),
        p1       = fgt(df[[wv]], df$zref, df$w_ind, 1),
        p2       = fgt(df[[wv]], df$zref, df$w_ind, 2),
        delta_p0 = fgt(df[[wv]], df$zref, df$w_ind, 0) - p0_base
      )
    }
    if (is.null(group_var)) fn(data)
    else {
      data %>%
        group_by(across(all_of(group_var))) %>%
        group_modify(~fn(.x)) %>%
        ungroup()
    }
  })
}

# ── 4. TABLES FGT ─────────────────────────────────────────────────────────────
fgt_national <- compute_fgt_table(hh)
message("\n=== FGT national — comparaison direct vs total I/O ===")
print(fgt_national %>% select(concept, p0, p1, p2, delta_p0))
export_excel(fgt_national, file.path(TABLES, "14", "14_01_fgt_comparison.xlsx"))

fgt_milieu <- compute_fgt_table(hh, "milieu")
export_excel(fgt_milieu,   file.path(TABLES, "14", "14_02_fgt_milieu.xlsx"))

fgt_region <- compute_fgt_table(hh, "region")
export_excel(fgt_region,   file.path(TABLES, "14", "14_03_fgt_region.xlsx"))

# ── 5. NOUVEAUX PAUVRES — COMPOSANTE I/O ──────────────────────────────────────
hh <- hh %>%
  mutate(
    poor_pre          = pcexp_pre      < zref,
    poor_direct_s1    = pcexp_direct_s1 < zref,
    poor_direct_s2    = pcexp_direct_s2 < zref,
    poor_direct_s3    = pcexp_direct_s3 < zref,
    poor_io_s1        = pcexp_io_s1    < zref,
    poor_io_s2        = pcexp_io_s2    < zref,
    poor_io_s3        = pcexp_io_s3    < zref,
    # Nouveaux pauvres générés par le seul enchâssement I/O
    # (non pauvres après direct, mais pauvres après total)
    np_io_s1 = (!poor_direct_s1) & poor_io_s1,
    np_io_s2 = (!poor_direct_s2) & poor_io_s2,
    np_io_s3 = (!poor_direct_s3) & poor_io_s3
  )

np_by_decile <- hh %>%
  group_by(decile) %>%
  summarise(
    p0_pre         = weighted.mean(poor_pre,       hhweight),
    p0_direct_s1   = weighted.mean(poor_direct_s1, hhweight),
    p0_io_s1       = weighted.mean(poor_io_s1,     hhweight),
    delta_io_s1    = weighted.mean(poor_io_s1,     hhweight) -
                     weighted.mean(poor_direct_s1, hhweight),
    np_io_s1_pond  = sum(np_io_s1 * hhweight, na.rm = TRUE),
    np_io_s2_pond  = sum(np_io_s2 * hhweight, na.rm = TRUE),
    np_io_s3_pond  = sum(np_io_s3 * hhweight, na.rm = TRUE),
    .groups = "drop"
  )

total_np <- np_by_decile %>%
  summarise(across(starts_with("np_"), sum))

message("\n=== Nouveaux pauvres générés par la seule composante enchâssée I/O ===")
message(sprintf("  Strict  : %s ménages",
  format(round(total_np$np_io_s1_pond), big.mark = ",")))
message(sprintf("  S2      : %s ménages",
  format(round(total_np$np_io_s2_pond), big.mark = ",")))
message(sprintf("  S3      : %s ménages",
  format(round(total_np$np_io_s3_pond), big.mark = ",")))

export_excel(np_by_decile,
             file.path(TABLES, "14", "14_04_nouveaux_pauvres_io.xlsx"))

# ── 6. FIGURE — ΔP0 par décile : direct vs total I/O (scénario strict) ───────
fig_data <- hh %>%
  group_by(decile) %>%
  summarise(
    delta_direct = weighted.mean(poor_direct_s1, hhweight) -
                   weighted.mean(poor_pre,        hhweight),
    delta_io     = weighted.mean(poor_io_s1,     hhweight) -
                   weighted.mean(poor_pre,        hhweight),
    delta_emb    = delta_io - delta_direct,
    .groups = "drop"
  ) %>%
  pivot_longer(cols = c(delta_direct, delta_emb),
               names_to = "composante", values_to = "delta_p0") %>%
  mutate(composante = case_when(
    composante == "delta_direct" ~ "TVA directe",
    composante == "delta_emb"    ~ "TVA enchâssée (I/O)"
  ))

fig <- ggplot(fig_data,
    aes(x = factor(decile), y = delta_p0 * 100, fill = composante)) +
  geom_col(position = "stack", width = 0.75) +
  scale_fill_manual(values = c(
    "TVA directe"        = "steelblue",
    "TVA enchâssée (I/O)"= "firebrick"
  )) +
  labs(
    title    = "Impact de la TVA sur le taux de pauvreté par décile",
    subtitle = "Scénario strict — Côte d'Ivoire, EHCVM 2021",
    x        = "Décile de consommation (D1 = plus pauvre)",
    y        = "\u0394 P0 (points de %)",
    fill     = "Composante",
    caption  = paste0(
      "Pondérations sondage. Seuil ménage-spécifique (zref, EHCVM).\n",
      "TVA enchâssée = impact marginal de la TVA sur intrants intermédiaires (Leontief, ICIO 2020)."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        plot.caption    = element_text(size = 7))

export_fig(fig, file.path(FIGS, "fig_poverty_io_impact.png"))

# ── 7. SAUVEGARDE PARQUET ─────────────────────────────────────────────────────
arrow::write_parquet(
  hh %>% select(hhid, hhweight, milieu, region, decile,
                pcexp_pre, pcexp_direct_s1, pcexp_io_s1,
                poor_pre, poor_direct_s1, poor_io_s1,
                np_io_s1, np_io_s2, np_io_s3),
  file.path(SILVER_14, "poverty_io.parquet")
)

message("\nÉtape 14 terminée — outputs dans ", SILVER_14, " et ", file.path(TABLES, "14"))
