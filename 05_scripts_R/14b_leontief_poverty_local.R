library(dplyr)
library(tidyr)
library(ggplot2)

source("05_scripts_R/00_setup.R")

io_basis <- Sys.getenv("IO_LOCAL_BASIS", unset = "current")
valid_basis <- c("current", "constant")
if (!io_basis %in% valid_basis) {
  stop("IO_LOCAL_BASIS doit valoir 'current' ou 'constant'.", call. = FALSE)
}

fiscal_path <- file.path(
  SILVER, "13b", sprintf("fiscal_data_local_io_%s.parquet", io_basis)
)

if (!file.exists(fiscal_path)) {
  legacy_path <- file.path(SILVER, "13b", "fiscal_data_local_io.parquet")
  if (io_basis == "current" && file.exists(legacy_path)) {
    fiscal_path <- legacy_path
    message("Donnees 13b lues depuis le fichier historique: ", fiscal_path)
  } else {
    stop(
      "Sortie 13b introuvable pour IO_LOCAL_BASIS='", io_basis, "'.\n",
      "Executer d'abord: source('05_scripts_R/13b_leontief_local_io.R')",
      call. = FALSE
    )
  }
}

message("Etape 14b - pauvrete avec I/O locale TRE 2023 (basis: ", io_basis, ")")

# 1. Load local fiscal data from 13b
fiscal_local <- load_parquet(fiscal_path)

# 2. Load welfare data
welfare <- load_raw_dta(
  "ehcvm_welfare_2b_CIV2021.dta",
  col_select = c("hhid", "pcexp", "zref", "hhsize", "hhweight")
)

# 3. Build comparison dataset
# Y_M        = market income proxy (pcexp)
# Y_C_direct = consumable income after direct VAT only
# Y_C_total  = consumable income after direct + embedded VAT
df <- welfare %>%
  left_join(fiscal_local %>% select(hhid, vat_w, vat_emb_local), by = "hhid") %>%
  filter(!is.na(pcexp), !is.na(zref), !is.na(hhsize), hhsize > 0) %>%
  mutate(
    io_basis = io_basis,
    vat_w = replace_na(vat_w, 0),
    vat_emb_local = replace_na(vat_emb_local, 0),
    market_pc = pcexp,
    consumable_dir_pc = pcexp - (vat_w / hhsize),
    consumable_tot_pc = pcexp - ((vat_w + vat_emb_local) / hhsize)
  )

# 4. FGT functions
fgt0 <- function(y, z, w) weighted.mean(y < z, w, na.rm = TRUE)
fgt1 <- function(y, z, w) weighted.mean(pmax(0, (z - y) / z), w, na.rm = TRUE)

# 5. Poverty impact
poverty <- df %>%
  summarise(
    basis = first(io_basis),
    p0_market = fgt0(market_pc, zref, hhweight * hhsize),
    p0_dir = fgt0(consumable_dir_pc, zref, hhweight * hhsize),
    p0_tot = fgt0(consumable_tot_pc, zref, hhweight * hhsize),
    p1_market = fgt1(market_pc, zref, hhweight * hhsize),
    p1_dir = fgt1(consumable_dir_pc, zref, hhweight * hhsize),
    p1_tot = fgt1(consumable_tot_pc, zref, hhweight * hhsize)
  )

cat("\n=== Impact de la TVA sur la pauvrete (modele local 2023) ===\n")
print(poverty)

# 6. Incidence by quintile
df <- df %>% mutate(quintile = ntile(market_pc, 5))

incidence <- df %>%
  group_by(quintile) %>%
  summarise(
    basis = first(io_basis),
    mean_market = weighted.mean(market_pc, hhweight * hhsize, na.rm = TRUE),
    burden_dir_pct = weighted.mean(vat_w / (pcexp * hhsize),
                                   hhweight * hhsize, na.rm = TRUE) * 100,
    burden_emb_pct = weighted.mean(vat_emb_local / (pcexp * hhsize),
                                   hhweight * hhsize, na.rm = TRUE) * 100,
    .groups = "drop"
  )

cat("\n=== Charge fiscale par quintile (% du revenu) ===\n")
print(incidence)

# 7. Save
TABLES_14b <- file.path(TABLES, "14b")
dir.create(TABLES_14b, showWarnings = FALSE)

poverty_out <- file.path(
  TABLES_14b, sprintf("14b_01_poverty_impact_local_%s.csv", io_basis)
)
incidence_out <- file.path(
  TABLES_14b, sprintf("14b_02_incidence_quintile_local_%s.csv", io_basis)
)

readr::write_csv(poverty, poverty_out)
readr::write_csv(incidence, incidence_out)

if (io_basis == "current") {
  readr::write_csv(poverty, file.path(TABLES_14b, "14b_01_poverty_impact_local.csv"))
  readr::write_csv(incidence, file.path(TABLES_14b, "14b_02_incidence_quintile_local.csv"))
}

message("Analyse de pauvrete locale terminee - sorties: ", TABLES_14b)
