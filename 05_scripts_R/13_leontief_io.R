# =============================================================================
# Etape 13 — Modele de prix de Leontief : TVA enchasee via matrice I/O
# OECD ICIO 2023 (CIV 2020) × EHCVM 2021
# =============================================================================
library(readxl); library(dplyr); library(tidyr)

source("05_scripts_R/00_setup.R")

SILVER_13 <- file.path(SILVER, "13")
dir.create(SILVER_13, showWarnings = FALSE)

# ── 1. MATRICE I/O ────────────────────────────────────────────────────────────
io_raw <- read.csv(
  source_file_path("IO", "CIV2020ttl.csv", label = "Matrice ICIO CSV"),
  row.names = 1, check.names = FALSE
)

sect_cols <- names(io_raw)[1:45]           # 45 secteurs ISIC Rev.4
sect_rows <- paste0("TTL_", sect_cols)

Z      <- as.matrix(io_raw[sect_rows, sect_cols])
output <- as.numeric(io_raw["OUTPUT", sect_cols])
names(output) <- sect_cols

A <- sweep(Z, 2, output, "/")              # coefficients techniques
rownames(A) <- sect_cols; colnames(A) <- sect_cols

stopifnot(max(Re(eigen(A)$values)) < 1)   # condition de Hawkins-Simon

# ── 2. VECTEUR t PAR SECTEUR ──────────────────────────────────────────────────
conc <- read_source_csv(
  path_parts = c("concordance_codpr_ICIO.csv"),
  .label = "Concordance codpr-ICIO",
  .required_cols = c("codpr", "libelle", "secteur_ICIO")
) %>% filter(secteur_ICIO != "hors_champ")

tva <- read_source_excel(
  path_parts = c("COPR_EHCVM_TVA_renseigne.xlsx"),
  sheet = "TVA_detail",
  .label = "Classeur de mapping TVA",
  .required_cols = c("code", "TVA_statutaire")
) %>%
  rename(codpr = code) %>%
  mutate(taux_tva = case_when(
    TVA_statutaire == "18%" ~ 0.18,
    TVA_statutaire == "9%"  ~ 0.09,
    TRUE                    ~ 0.00
  )) %>%
  select(codpr, taux_tva)

# Taux moyen observe par secteur (depuis les codpr)
t_obs <- conc %>%
  left_join(tva, by = "codpr") %>%
  group_by(secteur_ICIO) %>%
  summarise(t_moyen = mean(taux_tva, na.rm = TRUE), .groups = "drop")

# Vecteur t : défaut 0.18, puis t_obs, puis exonérations CGI (priorité max)
t_vec <- setNames(rep(0.18, 45), sect_cols)

for (i in seq_len(nrow(t_obs))) {
  s <- t_obs$secteur_ICIO[i]
  if (s %in% names(t_vec)) t_vec[s] <- t_obs$t_moyen[i]
}

# Exonérations structurelles CGI CIV 2026 — priorité absolue
# L  : loyer résidentiel exonéré (CGI art. 355) — file classifie à tort à 18%
# A01_02, A03 : agriculture et pêche, produits bruts exonérés
# E  : eau courante exonérée
# G  : t_G = 0 (pass-through informel — décision IEC)
# P  : éducation exonérée
# Q  : santé exonérée
# T  : ménages-employeurs, hors champ
t_vec[c("L", "A01_02", "A03", "E", "G", "P", "Q", "T")] <- 0.00

# ── 3. LEONTIEF : τ = (I - A')⁻¹ · t ────────────────────────────────────────
L_inv <- solve(diag(45) - t(A))
tau   <- as.numeric(L_inv %*% t_vec)
names(tau) <- sect_cols

tau_df <- data.frame(
  secteur    = sect_cols,
  t_direct   = round(t_vec, 4),
  t_indirect = round(tau - t_vec, 4),
  tau_total  = round(tau, 4)
) %>% arrange(desc(tau_total))

cat("\n=== Taux enchâssé par secteur (τ = direct + indirect) ===\n")
print(tau_df, row.names = FALSE)

# ── 4. JOINTURE VERS LES CODPR ────────────────────────────────────────────────
tau_lookup <- data.frame(
  secteur_ICIO = names(tau),
  tau_total    = tau,
  t_direct     = t_vec,
  t_indirect   = tau - t_vec
)

result <- conc %>%
  left_join(tau_lookup, by = "secteur_ICIO") %>%
  left_join(tva, by = "codpr") %>%
  select(codpr, libelle, secteur_ICIO, taux_tva, t_direct, t_indirect, tau_total)

cat("\n=== Top 20 codpr par τ total ===\n")
print(result %>% arrange(desc(tau_total)) %>% head(20))

# ── 5. INCIDENCE AU NIVEAU MÉNAGE ─────────────────────────────────────────────
# Charger données item-niveau (hhid × codpr)
conso <- load_parquet(file.path(SILVER, "01", "conso_clean.parquet")) %>%
  select(hhid, hhweight, region, milieu, codpr, depan, depan_w)
assert_required_columns(
  conso,
  c("hhid", "hhweight", "region", "milieu", "codpr", "depan_w"),
  object_name = "conso_clean.parquet"
)

# Joindre τ par codpr — les produits sans mapping (hors_champ) reçoivent 0
tau_codpr <- result %>% select(codpr, t_indirect, tau_total)

conso_io <- conso %>%
  left_join(tau_codpr, by = "codpr") %>%
  mutate(
    t_indirect = replace_na(t_indirect, 0),
    tau_total  = replace_na(tau_total,  0),
    # TVA enchâssée par produit — cohérent avec vat_item = depan_w * r dans step 03
    vat_emb_item = depan_w * t_indirect
  )

# Agréger au niveau ménage
hh_io <- conso_io %>%
  group_by(hhid) %>%
  summarise(
    hhweight    = first(hhweight),
    region      = first(region),
    milieu      = first(milieu),
    vat_emb     = sum(vat_emb_item, na.rm = TRUE),
    conso_w     = sum(depan_w,      na.rm = TRUE),
    .groups     = "drop"
  )

# Charger fiscal_data (step 03) et fusionner
fiscal <- load_parquet(file.path(SILVER, "03", "fiscal_data.parquet"))
assert_required_columns(
  fiscal,
  c("hhid", "hhweight", "conso_w", "vat_w", "eff_vat_w", "consumable_income"),
  object_name = "fiscal_data.parquet"
)

fiscal_io <- fiscal %>%
  left_join(hh_io %>% select(hhid, vat_emb), by = "hhid") %>%
  mutate(
    vat_emb            = replace_na(vat_emb, 0),
    # Taux effectif TVA totale (directe + enchâssée)
    eff_vat_io         = (vat_w + vat_emb) / conso_w,
    # Revenu consommable ajusté I/O
    consumable_io      = consumable_income - vat_emb,
    # Part TVA enchâssée dans la charge totale
    share_emb          = vat_emb / (vat_w + vat_emb)
  )

cat("\n=== Résumé TVA enchâssée par décile ===\n")
fiscal_io <- fiscal_io %>%
  mutate(decile = ntile(conso_w, 10))
print(
  fiscal_io %>%
    group_by(decile) %>%
    summarise(
      eff_vat_direct  = round(weighted.mean(eff_vat_w,  hhweight, na.rm=TRUE), 4),
      eff_vat_emb     = round(weighted.mean(vat_emb / conso_w, hhweight, na.rm=TRUE), 4),
      eff_vat_total   = round(weighted.mean(eff_vat_io, hhweight, na.rm=TRUE), 4),
      share_emb_pct   = round(100 * weighted.mean(share_emb, hhweight, na.rm=TRUE), 1),
      .groups = "drop"
    )
)

# ── 6. SAUVEGARDE ─────────────────────────────────────────────────────────────
readr::write_csv(tau_df,    file.path(SILVER_13, "leontief_tau_secteur.csv"))
readr::write_csv(result,    file.path(SILVER_13, "leontief_tau_codpr.csv"))
save_parquet(fiscal_io, file.path(SILVER_13, "fiscal_data_io.parquet"))

cat("\nÉtape 13 terminée — outputs dans", SILVER_13, "\n")
