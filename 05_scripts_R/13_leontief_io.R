# Etape 13 - TVA incorporee, matrice OCDE ICIO 2020.
#
# La TVA d'amont n'est un cout que lorsque le producteur n'a pas droit a
# deduction. Ce cout est ensuite transmis par toutes les chaines domestiques
# en aval. La formulation reproduit la logique du do-file Banque mondiale
# 04. CIV21WBN_vat_in.do sans appliquer (I-A')^-1 au taux statutaire entier.

source("05_scripts_R/00_setup.R")

SILVER_13 <- file.path(SILVER, "13")
dir.create(SILVER_13, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(TABLES, "13"), showWarnings = FALSE, recursive = TRUE)

# 1. Matrice ICIO et separation approximative origine domestique/importee.
io_raw <- read.csv(
  source_file_path("IO", "CIV2020ttl.csv", label = "Matrice ICIO CSV"),
  row.names = 1,
  check.names = FALSE
)

sector_codes <- names(io_raw)[1:45]
sector_rows <- paste0("TTL_", sector_codes)
Z_total <- as.matrix(io_raw[sector_rows, sector_codes])
storage.mode(Z_total) <- "double"

output <- as.numeric(io_raw["OUTPUT", sector_codes])
names(output) <- sector_codes
imports <- pmax(-as.numeric(io_raw[sector_rows, "IMPO"]), 0)
names(imports) <- sector_codes

origin <- split_uses_by_origin(Z_total, output, imports)
A_dom <- sweep(origin$domestic, 2, output, "/")
A_import <- sweep(origin$imported, 2, output, "/")
A_dom[!is.finite(A_dom)] <- 0
A_import[!is.finite(A_import)] <- 0
rownames(A_dom) <- colnames(A_dom) <- sector_codes
rownames(A_import) <- colnames(A_import) <- sector_codes

# 2. Taux sectoriels ponderes par la consommation nationale EHCVM.
concordance <- read_source_csv(
  path_parts = c("concordance_codpr_ICIO.csv"),
  .label = "Concordance codpr-ICIO",
  .required_cols = c("codpr", "secteur_ICIO")
)

conso <- load_parquet(file.path(SILVER, "01", "conso_clean.parquet"))
assert_required_columns(
  conso,
  c("hhid", "hhweight", "milieu", "coicop", "codpr", "depan_w",
    "r_vat_official"),
  object_name = "conso_clean.parquet"
)

sector_profile_observed <- conso %>%
  left_join(
    concordance %>% select(codpr, secteur_ICIO),
    by = "codpr"
  ) %>%
  filter(secteur_ICIO %in% sector_codes) %>%
  mutate(national_exp = depan_w * hhweight) %>%
  group_by(secteur = secteur_ICIO) %>%
  summarise(
    consumption_weight = sum(national_exp, na.rm = TRUE),
    statutory_rate = weighted.mean(
      r_vat_official, national_exp, na.rm = TRUE
    ),
    taxable_share = weighted.mean(
      r_vat_official > 0, national_exp, na.rm = TRUE
    ),
    .groups = "drop"
  )

sector_profile <- tibble(
  secteur = sector_codes,
  statutory_rate = 0.18,
  taxable_share = 1,
  rate_source = "default_18"
) %>%
  mutate(
    statutory_rate = ifelse(
      secteur %in% c("K", "L", "O", "P", "Q", "T"),
      0,
      statutory_rate
    ),
    taxable_share = ifelse(
      secteur %in% c("K", "L", "O", "P", "Q", "T"),
      0,
      taxable_share
    ),
    rate_source = ifelse(statutory_rate == 0, "structural_exemption",
                         rate_source)
  ) %>%
  left_join(
    sector_profile_observed %>%
      rename(
        observed_rate = statutory_rate,
        observed_taxable_share = taxable_share
      ),
    by = "secteur"
  ) %>%
  mutate(
    statutory_rate = coalesce(observed_rate, statutory_rate),
    taxable_share = coalesce(observed_taxable_share, taxable_share),
    rate_source = ifelse(!is.na(observed_rate),
                         "EHCVM_consumption_weighted", rate_source)
  )

t_vec <- setNames(sector_profile$statutory_rate, sector_profile$secteur)
taxable_share <- setNames(
  sector_profile$taxable_share, sector_profile$secteur
)

# 3. Rupture de la chaine de deduction et propagation en aval.
vat_io <- compute_embedded_vat(
  A_dom = A_dom,
  A_import = A_import,
  statutory_rate = t_vec,
  taxable_share = taxable_share
)

sector_rates <- sector_profile %>%
  mutate(
    domestic_input_share = origin$domestic_share,
    first_round_rate = vat_io$first_round,
    embedded_rate = vat_io$embedded_rate,
    total_rate = statutory_rate + embedded_rate,
    spectral_radius = vat_io$spectral_radius,
    equation_residual = vat_io$equation_residual
  ) %>%
  arrange(desc(embedded_rate))

# 4. Incidence menage sans double comptage entre composantes.
item_rates <- concordance %>%
  filter(secteur_ICIO %in% sector_codes) %>%
  left_join(
    sector_rates %>% select(secteur, embedded_rate),
    by = c("secteur_ICIO" = "secteur")
  ) %>%
  select(codpr, secteur_ICIO, embedded_rate)

fiscal <- load_parquet(
  file.path(SILVER, "04", "fiscal_data_analysis_ready.parquet")
)
assert_required_columns(
  fiscal,
  c("hhid", "hhweight", "pcweight", "pcexp", "yd_pc", "yd_hh",
    "hhsize", "def_spa", "decile", "vat_w"),
  object_name = "fiscal_data_analysis_ready.parquet"
)

conso_io <- conso %>%
  left_join(item_rates, by = "codpr") %>%
  left_join(fiscal %>% select(hhid, decile), by = "hhid") %>%
  mutate(
    embedded_rate = replace_na(embedded_rate, 0),
    alpha_strict = 1,
    alpha_s2 = vat_alpha_milieu(coicop, milieu),
    alpha_s3 = vat_alpha_decile(coicop, decile),
    formal_denominator = 1 + r_vat_official + embedded_rate,
    informal_denominator = 1 + embedded_rate,
    vat_direct_io_strict_item =
      depan_w * alpha_strict * r_vat_official / formal_denominator,
    vat_emb_io_strict_item =
      depan_w * alpha_strict * embedded_rate / formal_denominator +
      depan_w * (1 - alpha_strict) * embedded_rate /
        informal_denominator,
    vat_direct_io_s2_item =
      depan_w * alpha_s2 * r_vat_official / formal_denominator,
    vat_emb_io_s2_item =
      depan_w * alpha_s2 * embedded_rate / formal_denominator +
      depan_w * (1 - alpha_s2) * embedded_rate / informal_denominator,
    vat_direct_io_s3_item =
      depan_w * alpha_s3 * r_vat_official / formal_denominator,
    vat_emb_io_s3_item =
      depan_w * alpha_s3 * embedded_rate / formal_denominator +
      depan_w * (1 - alpha_s3) * embedded_rate / informal_denominator
  )

hh_io <- conso_io %>%
  group_by(hhid) %>%
  summarise(
    vat_direct_io_strict = sum(vat_direct_io_strict_item, na.rm = TRUE),
    vat_emb_io_strict = sum(vat_emb_io_strict_item, na.rm = TRUE),
    vat_direct_io_s2 = sum(vat_direct_io_s2_item, na.rm = TRUE),
    vat_emb_io_s2 = sum(vat_emb_io_s2_item, na.rm = TRUE),
    vat_direct_io_s3 = sum(vat_direct_io_s3_item, na.rm = TRUE),
    vat_emb_io_s3 = sum(vat_emb_io_s3_item, na.rm = TRUE),
    mapped_exp = sum(depan_w[!is.na(secteur_ICIO)], na.rm = TRUE),
    total_exp = sum(depan_w, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    vat_total_io_strict = vat_direct_io_strict + vat_emb_io_strict,
    vat_total_io_s2 = vat_direct_io_s2 + vat_emb_io_s2,
    vat_total_io_s3 = vat_direct_io_s3 + vat_emb_io_s3
  )

fiscal_io <- fiscal %>%
  left_join(hh_io, by = "hhid") %>%
  mutate(
    across(
      c(starts_with("vat_direct_io_"), starts_with("vat_emb_io_"),
        starts_with("vat_total_io_"), mapped_exp, total_exp),
      ~ replace_na(.x, 0)
    ),
    across(
      c(starts_with("vat_direct_io_"), starts_with("vat_emb_io_"),
        starts_with("vat_total_io_")),
      ~ .x * def_spa,
      .names = "{.col}_real"
    ),
    vat_direct_io = vat_direct_io_strict,
    vat_emb = vat_emb_io_strict,
    vat_total_io = vat_total_io_strict,
    vat_emb_real = vat_emb_io_strict_real,
    vat_total_io_real = vat_total_io_strict_real,
    eff_vat_io = vat_total_io_strict_real / yd_hh,
    yc_pc_io = yd_pc - vat_total_io_strict_real / hhsize,
    direct_reconciliation = vat_direct_io_strict - vat_w,
    mapped_share = ifelse(total_exp > 0, mapped_exp / total_exp, 0)
  )

io_scenarios <- c("strict", "s2", "s3")
summary_decile <- purrr::map_dfr(io_scenarios, function(scenario) {
  direct_var <- paste0("vat_direct_io_", scenario, "_real")
  embedded_var <- paste0("vat_emb_io_", scenario, "_real")
  total_var <- paste0("vat_total_io_", scenario, "_real")
  fiscal_io %>%
    group_by(decile) %>%
    summarise(
      direct_rate = weighted.mean(.data[[direct_var]] / yd_hh, pcweight),
      embedded_rate = weighted.mean(
        .data[[embedded_var]] / yd_hh, pcweight
      ),
      total_rate = weighted.mean(.data[[total_var]] / yd_hh, pcweight),
      embedded_share = sum(.data[[embedded_var]] * hhweight) /
        sum(.data[[total_var]] * hhweight),
      mapping_coverage = weighted.mean(mapped_share, hhweight),
      .groups = "drop"
    ) %>%
    mutate(scenario = scenario, .before = 1)
})

summary_macro <- purrr::map_dfr(io_scenarios, function(scenario) {
  direct_var <- paste0("vat_direct_io_", scenario)
  embedded_var <- paste0("vat_emb_io_", scenario)
  total_var <- paste0("vat_total_io_", scenario)
  tibble(
    matrice = "OCDE ICIO 2020",
    scenario = scenario,
    spectral_radius = vat_io$spectral_radius,
    equation_residual = vat_io$equation_residual,
    direct_vat_billion = sum(
      fiscal_io[[direct_var]] * fiscal_io$hhweight
    ) / 1e9,
    embedded_vat_billion = sum(
      fiscal_io[[embedded_var]] * fiscal_io$hhweight
    ) / 1e9,
    total_vat_billion = sum(
      fiscal_io[[total_var]] * fiscal_io$hhweight
    ) / 1e9,
    mapping_coverage = weighted.mean(
      fiscal_io$mapped_share, fiscal_io$hhweight
    )
  )
})

print(summary_macro)
print(summary_decile)

write_csv(sector_rates, file.path(SILVER_13, "leontief_tau_secteur.csv"))
write_csv(item_rates, file.path(SILVER_13, "leontief_tau_codpr.csv"))
save_parquet(fiscal_io, file.path(SILVER_13, "fiscal_data_io.parquet"))
export_excel(
  summary_decile,
  file.path(TABLES, "13", "13_01_io_incidence_by_decile.xlsx")
)
export_excel(
  summary_macro,
  file.path(TABLES, "13", "13_02_io_diagnostics.xlsx")
)

message("Etape 13 terminee - sorties dans ", SILVER_13)
