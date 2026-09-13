# Etape 14 - Pauvrete apres TVA directe et incorporee.
#
# Specification centrale : TRE 2023 courant et informalite par produit-decile
# (S3). Le TRE constant et ICIO 2020 sont des robustesses. Tous les montants
# fiscaux nominaux sont convertis dans l'unite reelle de pcexp avec def_spa.

source("05_scripts_R/00_setup.R")

SILVER_14 <- file.path(SILVER, "14")
dir.create(SILVER_14, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(TABLES, "14"), showWarnings = FALSE, recursive = TRUE)

current <- load_parquet(
  file.path(SILVER, "13b", "fiscal_data_local_io_current.parquet")
)
constant <- load_parquet(
  file.path(SILVER, "13b", "fiscal_data_local_io_constant.parquet")
)
oecd <- load_parquet(file.path(SILVER, "13", "fiscal_data_io.parquet"))

required_base <- c(
  "hhid", "hhweight", "pcweight", "grappe", "strata", "region",
  "milieu", "decile", "yd_pc", "hhsize", "zref"
)
assert_required_columns(current, required_base, "TRE courant")

constant_tax <- constant %>%
  select(
    hhid,
    starts_with("vat_direct_local_"),
    starts_with("vat_emb_local_"),
    starts_with("vat_total_local_")
  ) %>%
  rename_with(~ paste0(.x, "_constant"), -hhid)

oecd_tax <- oecd %>%
  select(
    hhid,
    starts_with("vat_direct_io_"),
    starts_with("vat_emb_io_"),
    starts_with("vat_total_io_")
  ) %>%
  rename_with(~ paste0(.x, "_oecd"), -hhid)

hh <- current %>%
  left_join(constant_tax, by = "hhid") %>%
  left_join(oecd_tax, by = "hhid")

concepts <- tribble(
  ~concept_id, ~matrix, ~scenario, ~component, ~tax_var,
  "yd", "Aucune", "reference", "avant TVA", NA_character_,
  "cur_direct_strict", "TRE courant", "S1", "directe",
  "vat_direct_local_strict_real",
  "cur_direct_s2", "TRE courant", "S2", "directe",
  "vat_direct_local_s2_real",
  "cur_direct_s3", "TRE courant", "S3", "directe",
  "vat_direct_local_s3_real",
  "cur_direct_s4", "TRE courant", "S4", "directe",
  "vat_direct_local_s4_real",
  "cur_total_strict", "TRE courant", "S1", "directe + incorporee",
  "vat_total_local_strict_real",
  "cur_total_s2", "TRE courant", "S2", "directe + incorporee",
  "vat_total_local_s2_real",
  "cur_total_s3", "TRE courant", "S3", "directe + incorporee",
  "vat_total_local_s3_real",
  "cur_total_s4", "TRE courant", "S4", "directe + incorporee",
  "vat_total_local_s4_real",
  "cur_total_s3_legal", "TRE courant", "S3, droit à déduction juridique", "directe + incorporée",
  "vat_total_local_s3_legal_real",
  "cur_total_s3_alpha_low", "TRE courant", "S3 x 0,8", "directe + incorporée",
  "vat_total_local_s3_alpha_low_real",
  "cur_total_s3_alpha_high", "TRE courant", "S3 x 1,2", "directe + incorporée",
  "vat_total_local_s3_alpha_high_real",
  "cur_total_s3_upstream_75", "TRE courant", "collecte amont 75 %", "directe + incorporée",
  "vat_total_local_s3_upstream_75_real",
  "cur_total_s3_upstream_50", "TRE courant", "collecte amont 50 %", "directe + incorporée",
  "vat_total_local_s3_upstream_50_real",
  "cur_total_s3_unmapped", "TRE courant", "non-raccordés imputés", "directe + incorporée",
  "vat_total_local_s3_unmapped_imputed_real",
  "const_total_strict", "TRE constant", "S1", "directe + incorporee",
  "vat_total_local_strict_real_constant",
  "const_total_s2", "TRE constant", "S2", "directe + incorporee",
  "vat_total_local_s2_real_constant",
  "const_total_s3", "TRE constant", "S3", "directe + incorporee",
  "vat_total_local_s3_real_constant",
  "oecd_total_strict", "ICIO 2020", "S1", "directe + incorporee",
  "vat_total_io_strict_real_oecd",
  "oecd_total_s2", "ICIO 2020", "S2", "directe + incorporee",
  "vat_total_io_s2_real_oecd",
  "oecd_total_s3", "ICIO 2020", "S3", "directe + incorporee",
  "vat_total_io_s3_real_oecd"
)

missing_tax <- setdiff(na.omit(concepts$tax_var), names(hh))
if (length(missing_tax) > 0) {
  stop("Variables fiscales manquantes: ", paste(missing_tax, collapse = ", "),
       call. = FALSE)
}

welfare_after_tax <- function(data, tax_var) {
  if (is.na(tax_var)) return(data$yd_pc)
  data$yd_pc - data[[tax_var]] / data$hhsize
}

point_fgt <- purrr::pmap_dfr(concepts, function(
    concept_id, matrix, scenario, component, tax_var) {
  welfare <- welfare_after_tax(hh, tax_var)
  tibble(
    concept_id = concept_id,
    matrix = matrix,
    scenario = scenario,
    component = component,
    p0 = fgt_index(welfare, hh$zref, hh$pcweight, 0),
    p1 = fgt_index(welfare, hh$zref, hh$pcweight, 1),
    p2 = fgt_index(welfare, hh$zref, hh$pcweight, 2)
  )
})

base_point <- point_fgt %>% filter(concept_id == "yd")
point_fgt <- point_fgt %>%
  mutate(
    delta_p0 = p0 - base_point$p0,
    delta_p1 = p1 - base_point$p1,
    delta_p2 = p2 - base_point$p2
  )

# Bootstrap Rao-Wu conjoint : une meme replication sert a tous les concepts.
set.seed(20240901)
bootstrap_reps <- 500L
bootstrap_array <- replicate(bootstrap_reps, {
  replicate_weight <- rao_wu_weights(
    hh, "pcweight", "grappe", "strata"
  )
  unlist(lapply(concepts$tax_var, function(tax_var) {
    welfare <- welfare_after_tax(hh, tax_var)
    c(
      p0 = fgt_index(welfare, hh$zref, replicate_weight, 0),
      p1 = fgt_index(welfare, hh$zref, replicate_weight, 1),
      p2 = fgt_index(welfare, hh$zref, replicate_weight, 2)
    )
  }))
})

stat_names <- unlist(lapply(concepts$concept_id, function(id) {
  paste(id, c("p0", "p1", "p2"), sep = "__")
}))
rownames(bootstrap_array) <- stat_names

bootstrap_ci <- purrr::map_dfr(seq_len(nrow(concepts)), function(i) {
  rows <- (3 * i - 2):(3 * i)
  base_rows <- 1:3
  value <- bootstrap_array[rows, , drop = FALSE]
  delta <- value - bootstrap_array[base_rows, , drop = FALSE]
  tibble(
    concept_id = concepts$concept_id[i],
    p0_lo = quantile(value[1, ], 0.025, na.rm = TRUE),
    p0_hi = quantile(value[1, ], 0.975, na.rm = TRUE),
    p1_lo = quantile(value[2, ], 0.025, na.rm = TRUE),
    p1_hi = quantile(value[2, ], 0.975, na.rm = TRUE),
    p2_lo = quantile(value[3, ], 0.025, na.rm = TRUE),
    p2_hi = quantile(value[3, ], 0.975, na.rm = TRUE),
    delta_p0_lo = quantile(delta[1, ], 0.025, na.rm = TRUE),
    delta_p0_hi = quantile(delta[1, ], 0.975, na.rm = TRUE),
    delta_p1_lo = quantile(delta[2, ], 0.025, na.rm = TRUE),
    delta_p1_hi = quantile(delta[2, ], 0.975, na.rm = TRUE),
    delta_p2_lo = quantile(delta[3, ], 0.025, na.rm = TRUE),
    delta_p2_hi = quantile(delta[3, ], 0.975, na.rm = TRUE)
  )
})

fgt_results <- point_fgt %>%
  left_join(bootstrap_ci, by = "concept_id")

matrix_difference <- tibble(
  comparaison = c("TRE courant - ICIO", "TRE constant - TRE courant"),
  scenario = "S3",
  delta_p0 = c(
    point_fgt$p0[point_fgt$concept_id == "cur_total_s3"] -
      point_fgt$p0[point_fgt$concept_id == "oecd_total_s3"],
    point_fgt$p0[point_fgt$concept_id == "const_total_s3"] -
      point_fgt$p0[point_fgt$concept_id == "cur_total_s3"]
  ),
  lo_95 = c(
    quantile(
      bootstrap_array["cur_total_s3__p0", ] -
        bootstrap_array["oecd_total_s3__p0", ],
      0.025
    ),
    quantile(
      bootstrap_array["const_total_s3__p0", ] -
        bootstrap_array["cur_total_s3__p0", ],
      0.025
    )
  ),
  hi_95 = c(
    quantile(
      bootstrap_array["cur_total_s3__p0", ] -
        bootstrap_array["oecd_total_s3__p0", ],
      0.975
    ),
    quantile(
      bootstrap_array["const_total_s3__p0", ] -
        bootstrap_array["cur_total_s3__p0", ],
      0.975
    )
  )
)

# Nouveaux pauvres dans la specification centrale, en menages et en personnes.
central_welfare <- welfare_after_tax(hh, "vat_total_local_s3_real")
new_poor <- hh$yd_pc >= hh$zref & central_welfare < hh$zref
new_poor_summary <- tibble(
  specification = "TRE courant, S3",
  menages_ponderes = sum(hh$hhweight[new_poor], na.rm = TRUE),
  personnes_ponderees = sum(hh$pcweight[new_poor], na.rm = TRUE),
  part_nouveaux_pauvres_ruraux = weighted.mean(
    as.character(hh$milieu[new_poor]) %in% c("2", "Rural", "rural"),
    hh$pcweight[new_poor],
    na.rm = TRUE
  )
)

print(fgt_results %>%
        select(matrix, scenario, component, p0, delta_p0,
               delta_p0_lo, delta_p0_hi))
print(matrix_difference)
print(new_poor_summary)

export_excel(
  fgt_results,
  file.path(TABLES, "14", "14_01_fgt_comparison.xlsx")
)
export_excel(
  matrix_difference,
  file.path(TABLES, "14", "14_02_matrix_robustness.xlsx")
)
export_excel(
  new_poor_summary,
  file.path(TABLES, "14", "14_03_new_poor_central.xlsx")
)

figure_data <- fgt_results %>%
  filter(
    matrix == "TRE courant", component != "avant TVA",
    scenario %in% c("S1", "S2", "S3")
  ) %>%
  mutate(
    composante = ifelse(component == "directe", "TVA directe",
                        "TVA directe + incorporee"),
    scenario = factor(scenario, levels = c("S3", "S2", "S1"))
  )

fig <- ggplot(
  figure_data,
  aes(x = scenario, y = delta_p0 * 100, fill = composante)
) +
  geom_col(position = "dodge", width = 0.72) +
  geom_errorbar(
    aes(ymin = delta_p0_lo * 100, ymax = delta_p0_hi * 100),
    position = position_dodge(width = 0.72), width = 0.16
  ) +
  scale_fill_manual(values = c(
    "TVA directe" = "steelblue",
    "TVA directe + incorporee" = "firebrick"
  )) +
  labs(
    title = "Effet de la TVA sur la pauvrete",
    subtitle = "TRE 2023 courant; intervalles Rao-Wu a 95 %",
    x = "Hypothese de formalite des achats",
    y = "Variation de P0 (points de pourcentage)",
    fill = NULL,
    caption = paste0(
      "S3 (central) : formalite par produit et decile; S2 : produit et milieu; ",
      "S1 : transmission complète."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

export_fig(fig, file.path(FIGS, "fig_poverty_io_impact.png"))

save_parquet(
  hh %>%
    transmute(
      hhid, hhweight, pcweight, grappe, strata, region, milieu, decile,
      yd_pc, zref, hhsize,
      yc_pc_tre_s3 = central_welfare,
      poor_yd = yd_pc < zref,
      poor_yc_tre_s3 = central_welfare < zref,
      new_poor_tre_s3 = new_poor
    ),
  file.path(SILVER_14, "poverty_io.parquet")
)

message("Etape 14 terminee - inference Rao-Wu et robustesses I/O")
