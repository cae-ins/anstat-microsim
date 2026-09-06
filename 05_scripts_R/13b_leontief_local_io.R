# Etape 13b - TVA incorporee, TRE national 2023.
#
# Le tableau des emplois est publie aux prix d'acquisition. Il est converti
# aux prix de base avant la construction des coefficients techniques. Les
# intrants domestiques et importes sont ensuite separes, et la concordance
# produit-TRE est extraite du do-file Banque mondiale de reference.

source("05_scripts_R/00_setup.R")

io_basis <- Sys.getenv("IO_LOCAL_BASIS", unset = "current")
if (!io_basis %in% c("current", "constant")) {
  stop("IO_LOCAL_BASIS doit valoir 'current' ou 'constant'.", call. = FALSE)
}

input_dir <- file.path(SILVER, "IO_local", io_basis)
required_files <- c(
  "use_matrix_2023.csv",
  "resource_matrix_2023.csv",
  "hfce_2023.csv",
  "valuation_bridge_2023.csv"
)
if (!all(file.exists(file.path(input_dir, required_files)))) {
  stop(
    "Fichiers TRE manquants. Executer 05_scripts_R/extract_local_io.R.",
    call. = FALSE
  )
}

message("Etape 13b - TRE 2023, prix ", io_basis)

# 1. Matrices aux prix de base et separation domestique/importee.
U_purchaser <- as.matrix(read.csv(
  file.path(input_dir, "use_matrix_2023.csv"),
  row.names = 1,
  check.names = FALSE
))
R <- as.matrix(read.csv(
  file.path(input_dir, "resource_matrix_2023.csv"),
  row.names = 1,
  check.names = FALSE
))
valuation <- read.csv(
  file.path(input_dir, "valuation_bridge_2023.csv"),
  check.names = FALSE
)

product_codes <- rownames(U_purchaser)
if (!identical(product_codes, rownames(R)) ||
    !identical(product_codes, valuation$code)) {
  stop("Ordre des produits incoherent dans les fichiers TRE.", call. = FALSE)
}

valuation_conversion <- convert_sut_uses_to_basic_prices(
  U_purchaser,
  valuation
)
U_basic <- valuation_conversion$uses_basic
origin <- split_uses_by_origin(
  U_basic,
  domestic_supply = valuation$domestic_output,
  imports = valuation$imports
)

industry_output <- colSums(R)
product_output <- rowSums(R)
B_dom <- sweep(origin$domestic, 2, industry_output, "/")
B_import <- sweep(origin$imported, 2, industry_output, "/")
D <- sweep(t(R), 2, product_output, "/")
B_dom[!is.finite(B_dom)] <- 0
B_import[!is.finite(B_import)] <- 0
D[!is.finite(D)] <- 0

A_dom <- B_dom %*% D
A_import <- B_import %*% D
A_dom[A_dom < 0] <- 0
A_import[A_import < 0] <- 0
rownames(A_dom) <- colnames(A_dom) <- product_codes
rownames(A_import) <- colnames(A_import) <- product_codes

# 2. Concordance itemid -> 52 secteurs du do-file -> produits du TRE.
wb_to_tre <- wb52_to_tre48_bridge()
item_mapping <- build_tre_item_mapping(ROOT)

export_excel(
  item_mapping %>% dplyr::arrange(codpr),
  file.path(
    TABLES, "13",
    paste0("13_04_itemid_to_tre_mapping_", io_basis, ".xlsx")
  )
)
export_excel(
  wb_to_tre,
  file.path(
    TABLES, "13",
    paste0("13_05_wb52_to_tre48_bridge_", io_basis, ".xlsx")
  )
)

# 3. Vecteur de taux, pondere par les depenses nationales EHCVM.
conso <- load_parquet(file.path(SILVER, "01", "conso_clean.parquet"))
assert_required_columns(
  conso,
  c("hhid", "hhweight", "milieu", "coicop", "codpr", "depan_w",
    "r_vat_official"),
  object_name = "conso_clean.parquet"
)

observed_profile <- conso %>%
  left_join(item_mapping, by = "codpr") %>%
  filter(code_TRE %in% product_codes) %>%
  mutate(national_exp = depan_w * hhweight) %>%
  group_by(code = code_TRE) %>%
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

structural_exemptions <- c("K38", "L39", "O42", "P43", "Q44", "T47", "U48")
product_profile <- tibble(
  code = product_codes,
  statutory_rate = ifelse(code %in% structural_exemptions, 0, 0.18),
  taxable_share = ifelse(code %in% structural_exemptions, 0, 1),
  rate_source = ifelse(code %in% structural_exemptions,
                       "structural_exemption", "default_18")
) %>%
  left_join(
    observed_profile %>%
      rename(
        observed_rate = statutory_rate,
        observed_taxable_share = taxable_share
      ),
    by = "code"
  ) %>%
  mutate(
    statutory_rate = coalesce(observed_rate, statutory_rate),
    taxable_share = coalesce(observed_taxable_share, taxable_share),
    taxable_share_legal = ifelse(code %in% structural_exemptions, 0, 1),
    rate_source = ifelse(!is.na(observed_rate),
                         "EHCVM_consumption_weighted", rate_source),
    legal_right_source = ifelse(
      code %in% structural_exemptions,
      "exonération structurelle simplifiée",
      "droit à déduction supposé intégral"
    )
  )

vat_io <- compute_embedded_vat(
  A_dom = A_dom,
  A_import = A_import,
  statutory_rate = product_profile$statutory_rate,
  taxable_share = product_profile$taxable_share
)
vat_io_legal <- compute_embedded_vat(
  A_dom = A_dom,
  A_import = A_import,
  statutory_rate = product_profile$statutory_rate,
  taxable_share = product_profile$taxable_share_legal
)
vat_io_upstream_75 <- compute_embedded_vat(
  A_dom = A_dom,
  A_import = A_import,
  statutory_rate = product_profile$statutory_rate,
  taxable_share = product_profile$taxable_share,
  upstream_collection = 0.75
)
vat_io_upstream_50 <- compute_embedded_vat(
  A_dom = A_dom,
  A_import = A_import,
  statutory_rate = product_profile$statutory_rate,
  taxable_share = product_profile$taxable_share,
  upstream_collection = 0.50
)

product_rates <- product_profile %>%
  mutate(
    basis = io_basis,
    purchaser_to_basic_ratio = ifelse(
      valuation$purchaser_total > 0,
      valuation$basic_total / valuation$purchaser_total,
      0
    ),
    domestic_input_share = origin$domestic_share,
    first_round_rate = vat_io$first_round,
    embedded_rate = vat_io$embedded_rate,
    first_round_rate_legal = vat_io_legal$first_round,
    embedded_rate_legal = vat_io_legal$embedded_rate,
    embedded_rate_upstream_75 = vat_io_upstream_75$embedded_rate,
    embedded_rate_upstream_50 = vat_io_upstream_50$embedded_rate,
    delta_embedded_rate_legal = embedded_rate_legal - embedded_rate,
    total_rate = statutory_rate + embedded_rate,
    spectral_radius = vat_io$spectral_radius,
    equation_residual = vat_io$equation_residual
  ) %>%
  arrange(desc(embedded_rate))

# 4. Incidence ménage. La cascade est multiplicative : la TVA finale porte sur
# un prix qui comprend déjà le coût fiscal non déductible accumulé en amont.
item_rates <- item_mapping %>%
  left_join(
    product_rates %>% select(
      code, embedded_rate, embedded_rate_legal,
      embedded_rate_upstream_75, embedded_rate_upstream_50
    ),
    by = c("code_TRE" = "code")
  ) %>%
  select(
    codpr, io_wb, code_TRE, embedded_rate, embedded_rate_legal,
    embedded_rate_upstream_75, embedded_rate_upstream_50
  )

fiscal <- load_parquet(
  file.path(SILVER, "04", "fiscal_data_analysis_ready.parquet")
)

conso_with_rates <- conso %>%
  left_join(item_rates, by = "codpr")

# Profil alpha du scenario S4, produit par l'etape 6 a partir du module 10.
alpha_s4_table <- vat_alpha_s4_table(SILVER)

national_embedded_mean <- with(
  dplyr::filter(conso_with_rates, !is.na(embedded_rate)),
  stats::weighted.mean(embedded_rate, depan_w * hhweight, na.rm = TRUE)
)
coicop_embedded_mean <- conso_with_rates %>%
  dplyr::filter(!is.na(embedded_rate)) %>%
  dplyr::group_by(coicop) %>%
  dplyr::summarise(
    embedded_rate_coicop = stats::weighted.mean(
      embedded_rate, depan_w * hhweight, na.rm = TRUE
    ),
    .groups = "drop"
  )

conso_local <- conso_with_rates %>%
  left_join(coicop_embedded_mean, by = "coicop") %>%
  left_join(fiscal %>% select(hhid, decile), by = "hhid") %>%
  mutate(
    mapped_tre = !is.na(code_TRE),
    embedded_rate_unmapped_imputed = dplyr::coalesce(
      embedded_rate, embedded_rate_coicop, national_embedded_mean
    ),
    embedded_rate = replace_na(embedded_rate, 0),
    embedded_rate_legal = replace_na(embedded_rate_legal, 0),
    embedded_rate_upstream_75 = replace_na(embedded_rate_upstream_75, 0),
    embedded_rate_upstream_50 = replace_na(embedded_rate_upstream_50, 0),
    alpha_strict = 1,
    alpha_s2 = vat_alpha_milieu(coicop, milieu),
    alpha_s3 = vat_alpha_decile(coicop, decile),
    alpha_s4 = vat_alpha_s4(coicop, decile, alpha_s4_table),
    alpha_s3_low = pmax(0, 0.8 * alpha_s3),
    alpha_s3_high = pmin(1, 1.2 * alpha_s3),
    vat_direct_local_strict_item =
      depan_w * alpha_strict * r_vat_official / (1 + r_vat_official),
    vat_emb_local_strict_item =
      depan_w * alpha_strict / (1 + r_vat_official) *
        embedded_rate / (1 + embedded_rate) +
      depan_w * (1 - alpha_strict) * embedded_rate / (1 + embedded_rate),
    vat_direct_local_s2_item =
      depan_w * alpha_s2 * r_vat_official / (1 + r_vat_official),
    vat_emb_local_s2_item =
      depan_w * alpha_s2 / (1 + r_vat_official) *
        embedded_rate / (1 + embedded_rate) +
      depan_w * (1 - alpha_s2) * embedded_rate / (1 + embedded_rate),
    vat_direct_local_s3_item =
      depan_w * alpha_s3 * r_vat_official / (1 + r_vat_official),
    vat_emb_local_s3_item =
      depan_w * alpha_s3 / (1 + r_vat_official) *
        embedded_rate / (1 + embedded_rate) +
      depan_w * (1 - alpha_s3) * embedded_rate / (1 + embedded_rate),
    vat_direct_local_s4_item =
      depan_w * alpha_s4 * r_vat_official / (1 + r_vat_official),
    vat_emb_local_s4_item =
      depan_w * alpha_s4 / (1 + r_vat_official) *
        embedded_rate / (1 + embedded_rate) +
      depan_w * (1 - alpha_s4) * embedded_rate / (1 + embedded_rate),
    vat_direct_local_s3_alpha_low_item =
      depan_w * alpha_s3_low * r_vat_official / (1 + r_vat_official),
    vat_emb_local_s3_alpha_low_item =
      depan_w * alpha_s3_low / (1 + r_vat_official) *
        embedded_rate / (1 + embedded_rate) +
      depan_w * (1 - alpha_s3_low) * embedded_rate / (1 + embedded_rate),
    vat_direct_local_s3_alpha_high_item =
      depan_w * alpha_s3_high * r_vat_official / (1 + r_vat_official),
    vat_emb_local_s3_alpha_high_item =
      depan_w * alpha_s3_high / (1 + r_vat_official) *
        embedded_rate / (1 + embedded_rate) +
      depan_w * (1 - alpha_s3_high) * embedded_rate / (1 + embedded_rate),
    vat_direct_local_s3_upstream_75_item = vat_direct_local_s3_item,
    vat_emb_local_s3_upstream_75_item =
      depan_w * alpha_s3 / (1 + r_vat_official) *
        embedded_rate_upstream_75 / (1 + embedded_rate_upstream_75) +
      depan_w * (1 - alpha_s3) * embedded_rate_upstream_75 /
        (1 + embedded_rate_upstream_75),
    vat_direct_local_s3_upstream_50_item = vat_direct_local_s3_item,
    vat_emb_local_s3_upstream_50_item =
      depan_w * alpha_s3 / (1 + r_vat_official) *
        embedded_rate_upstream_50 / (1 + embedded_rate_upstream_50) +
      depan_w * (1 - alpha_s3) * embedded_rate_upstream_50 /
        (1 + embedded_rate_upstream_50),
    vat_direct_local_s3_unmapped_imputed_item = vat_direct_local_s3_item,
    vat_emb_local_s3_unmapped_imputed_item =
      depan_w * alpha_s3 / (1 + r_vat_official) *
        embedded_rate_unmapped_imputed / (1 + embedded_rate_unmapped_imputed) +
      depan_w * (1 - alpha_s3) * embedded_rate_unmapped_imputed /
        (1 + embedded_rate_unmapped_imputed),
    vat_direct_local_s3_legal_item =
      depan_w * alpha_s3 * r_vat_official / (1 + r_vat_official),
    vat_emb_local_s3_legal_item =
      depan_w * alpha_s3 / (1 + r_vat_official) *
        embedded_rate_legal / (1 + embedded_rate_legal) +
      depan_w * (1 - alpha_s3) * embedded_rate_legal /
        (1 + embedded_rate_legal)
  )

hh_local <- conso_local %>%
  group_by(hhid) %>%
  summarise(
    vat_direct_local_strict = sum(
      vat_direct_local_strict_item, na.rm = TRUE
    ),
    vat_emb_local_strict = sum(vat_emb_local_strict_item, na.rm = TRUE),
    vat_direct_local_s2 = sum(vat_direct_local_s2_item, na.rm = TRUE),
    vat_emb_local_s2 = sum(vat_emb_local_s2_item, na.rm = TRUE),
    vat_direct_local_s3 = sum(vat_direct_local_s3_item, na.rm = TRUE),
    vat_emb_local_s3 = sum(vat_emb_local_s3_item, na.rm = TRUE),
    vat_direct_local_s4 = sum(vat_direct_local_s4_item, na.rm = TRUE),
    vat_emb_local_s4 = sum(vat_emb_local_s4_item, na.rm = TRUE),
    vat_direct_local_s3_alpha_low = sum(vat_direct_local_s3_alpha_low_item, na.rm = TRUE),
    vat_emb_local_s3_alpha_low = sum(vat_emb_local_s3_alpha_low_item, na.rm = TRUE),
    vat_direct_local_s3_alpha_high = sum(vat_direct_local_s3_alpha_high_item, na.rm = TRUE),
    vat_emb_local_s3_alpha_high = sum(vat_emb_local_s3_alpha_high_item, na.rm = TRUE),
    vat_direct_local_s3_upstream_75 = sum(vat_direct_local_s3_upstream_75_item, na.rm = TRUE),
    vat_emb_local_s3_upstream_75 = sum(vat_emb_local_s3_upstream_75_item, na.rm = TRUE),
    vat_direct_local_s3_upstream_50 = sum(vat_direct_local_s3_upstream_50_item, na.rm = TRUE),
    vat_emb_local_s3_upstream_50 = sum(vat_emb_local_s3_upstream_50_item, na.rm = TRUE),
    vat_direct_local_s3_unmapped_imputed = sum(vat_direct_local_s3_unmapped_imputed_item, na.rm = TRUE),
    vat_emb_local_s3_unmapped_imputed = sum(vat_emb_local_s3_unmapped_imputed_item, na.rm = TRUE),
    vat_direct_local_s3_legal = sum(
      vat_direct_local_s3_legal_item, na.rm = TRUE
    ),
    vat_emb_local_s3_legal = sum(
      vat_emb_local_s3_legal_item, na.rm = TRUE
    ),
    mapped_exp_local = sum(depan_w[!is.na(code_TRE)], na.rm = TRUE),
    total_exp_local = sum(depan_w, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    vat_total_local_strict =
      vat_direct_local_strict + vat_emb_local_strict,
    vat_total_local_s2 = vat_direct_local_s2 + vat_emb_local_s2,
    vat_total_local_s3 = vat_direct_local_s3 + vat_emb_local_s3,
    vat_total_local_s4 = vat_direct_local_s4 + vat_emb_local_s4,
    vat_total_local_s3_alpha_low =
      vat_direct_local_s3_alpha_low + vat_emb_local_s3_alpha_low,
    vat_total_local_s3_alpha_high =
      vat_direct_local_s3_alpha_high + vat_emb_local_s3_alpha_high,
    vat_total_local_s3_upstream_75 =
      vat_direct_local_s3_upstream_75 + vat_emb_local_s3_upstream_75,
    vat_total_local_s3_upstream_50 =
      vat_direct_local_s3_upstream_50 + vat_emb_local_s3_upstream_50,
    vat_total_local_s3_unmapped_imputed =
      vat_direct_local_s3_unmapped_imputed + vat_emb_local_s3_unmapped_imputed,
    vat_total_local_s3_legal =
      vat_direct_local_s3_legal + vat_emb_local_s3_legal
  )

fiscal_local <- fiscal %>%
  left_join(hh_local, by = "hhid") %>%
  mutate(
    across(
      c(starts_with("vat_direct_local_"), starts_with("vat_emb_local_"),
        starts_with("vat_total_local_"),
        mapped_exp_local, total_exp_local),
      ~ replace_na(.x, 0)
    ),
    io_basis = io_basis,
    across(
      c(starts_with("vat_direct_local_"), starts_with("vat_emb_local_"),
        starts_with("vat_total_local_")),
      ~ .x * def_spa,
      .names = "{.col}_real"
    ),
    vat_direct_local = vat_direct_local_strict,
    vat_emb_local = vat_emb_local_strict,
    vat_total_local = vat_total_local_strict,
    vat_emb_local_real = vat_emb_local_strict_real,
    vat_total_local_real = vat_total_local_strict_real,
    eff_vat_local = vat_total_local_strict_real / yd_hh,
    yc_pc_local = yd_pc - vat_total_local_strict_real / hhsize,
    mapped_share_local = ifelse(
      total_exp_local > 0, mapped_exp_local / total_exp_local, 0
    )
  )

io_scenarios <- c(
  "strict", "s2", "s3", "s4", "s3_alpha_low", "s3_alpha_high",
  "s3_upstream_75", "s3_upstream_50", "s3_unmapped_imputed", "s3_legal"
)
summary_macro <- purrr::map_dfr(io_scenarios, function(scenario) {
  direct_var <- paste0("vat_direct_local_", scenario)
  embedded_var <- paste0("vat_emb_local_", scenario)
  total_var <- paste0("vat_total_local_", scenario)
  tibble(
    matrice = paste0("TRE 2023 ", io_basis),
    scenario = scenario,
    spectral_radius = vat_io$spectral_radius,
    equation_residual = vat_io$equation_residual,
    purchaser_use_billion = sum(U_purchaser) / 1e3,
    basic_use_billion = sum(U_basic) / 1e3,
    nondeductible_vat_tre_billion =
      sum(valuation$nondeductible_vat) / 1e3,
    direct_vat_billion = sum(
      fiscal_local[[direct_var]] * fiscal_local$hhweight
    ) / 1e9,
    embedded_vat_billion = sum(
      fiscal_local[[embedded_var]] * fiscal_local$hhweight
    ) / 1e9,
    total_vat_billion = sum(
      fiscal_local[[total_var]] * fiscal_local$hhweight
    ) / 1e9,
    mapping_coverage = weighted.mean(
      fiscal_local$mapped_share_local, fiscal_local$hhweight
    )
  )
})

print(summary_macro)

SILVER_13B <- file.path(SILVER, "13b")
dir.create(SILVER_13B, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(TABLES, "13"), showWarnings = FALSE, recursive = TRUE)

save_parquet(
  fiscal_local,
  file.path(
    SILVER_13B,
    sprintf("fiscal_data_local_io_%s.parquet", io_basis)
  )
)
write_csv(
  product_rates,
  file.path(SILVER_13B, sprintf("tau_local_sector_%s.csv", io_basis))
)
export_excel(
  summary_macro,
  file.path(
    TABLES, "13", sprintf("13_03_local_io_diagnostics_%s.xlsx", io_basis)
  )
)

if (io_basis == "current") {
  # Validation macroeconomique. La reference DGI est la TVA interieure
  # effectivement encaissee; les simulations sont des passifs bruts imputes
  # aux seuls paniers des menages. Les ratios diagnostiquent donc la collecte
  # et le champ, sans servir de facteur de calage.
  tva_dgi_2021 <- 556.3
  concentration_deciles <- purrr::map_dfr(
    io_scenarios,
    function(scenario) {
      total_var <- paste0("vat_total_local_", scenario)
      par_decile <- fiscal_local %>%
        dplyr::group_by(decile) %>%
        dplyr::summarise(
          masse = sum(.data[[total_var]] * hhweight),
          .groups = "drop"
        ) %>%
        dplyr::mutate(part = 100 * masse / sum(masse))
      tibble::tibble(
        scenario = scenario,
        part_masse_d1_pct = par_decile$part[par_decile$decile == 1],
        part_masse_d10_pct = par_decile$part[par_decile$decile == 10]
      )
    }
  )
  validation_macro <- summary_macro %>%
    dplyr::left_join(concentration_deciles, by = "scenario") %>%
    dplyr::transmute(
      scenario,
      tva_directe_simulee_mds = direct_vat_billion,
      tva_totale_simulee_mds = total_vat_billion,
      part_masse_d1_pct,
      part_masse_d10_pct,
      tva_interieure_dgi_mds = tva_dgi_2021,
      collecte_sur_directe_pct =
        100 * tva_dgi_2021 / direct_vat_billion,
      collecte_sur_totale_pct =
        100 * tva_dgi_2021 / total_vat_billion,
      comparabilite = paste0(
        "TVA DGI encaissee, toutes assiettes interieures, versus passif brut ",
        "impute a la consommation des menages; ni TVA en douane ni calage."
      ),
      source = paste0(
        "Ministere de l'Economie et des Finances, statistiques 2021 : ",
        "https://documents.economie-ivoirienne.ci/",
        "index.php?bid=256&fid=266&p=fstream-pdf"
      )
    )
  export_excel(
    validation_macro,
    file.path(TABLES, "13", "13_06_macro_validation.xlsx")
  )
  export_excel(
    summary_macro %>% dplyr::filter(
      scenario %in% c(
        "s3", "s3_alpha_low", "s3_alpha_high", "s3_upstream_75",
        "s3_upstream_50", "s3_unmapped_imputed"
      )
    ),
    file.path(TABLES, "13", "13_08_structure_sensitivities.xlsx")
  )

  legal_sensitivity <- summary_macro |>
    dplyr::filter(scenario %in% c("s3", "s3_legal")) |>
    dplyr::mutate(
      definition_droit_deduction = dplyr::if_else(
        scenario == "s3",
        "Part taxable observée dans la dépense finale EHCVM",
        "Classement juridique binaire : exemptions structurelles contre droit intégral"
      )
    )
  openxlsx::write.xlsx(
    list(
      comparaison_macro = as.data.frame(legal_sensitivity),
      classement_produits = as.data.frame(
        product_rates |>
          dplyr::select(
            code, statutory_rate, taxable_share, taxable_share_legal,
            rate_source, legal_right_source, embedded_rate,
            embedded_rate_legal, delta_embedded_rate_legal
          )
      )
    ),
    file = file.path(TABLES, "13", "13_07_legal_deduction_sensitivity.xlsx"),
    overwrite = TRUE
  )
  save_parquet(
    fiscal_local,
    file.path(SILVER_13B, "fiscal_data_local_io.parquet")
  )
  write_csv(
    product_rates,
    file.path(SILVER_13B, "tau_local_sector.csv")
  )
}

message("Etape 13b terminee - TRE ", io_basis)
