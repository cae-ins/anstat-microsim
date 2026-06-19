library(dplyr)
library(tidyr)
library(arrow)

source("05_scripts_R/00_setup.R")

io_basis <- Sys.getenv("IO_LOCAL_BASIS", unset = "current")
valid_basis <- c("current", "constant")
if (!io_basis %in% valid_basis) {
  stop("IO_LOCAL_BASIS doit valoir 'current' ou 'constant'.", call. = FALSE)
}

input_dir <- file.path(SILVER, "IO_local", io_basis)
legacy_input_dir <- file.path(SILVER, "IO_local")
required_files <- c("use_matrix_2023.csv", "resource_matrix_2023.csv", "hfce_2023.csv")

if (!all(file.exists(file.path(input_dir, required_files)))) {
  if (io_basis == "current" &&
      all(file.exists(file.path(legacy_input_dir, required_files)))) {
    input_dir <- legacy_input_dir
    message("Matrices TRE lues depuis le dossier historique: ", input_dir)
  } else {
    stop(
      "Matrices TRE introuvables pour IO_LOCAL_BASIS='", io_basis, "'.\n",
      "Executer d'abord: source('05_scripts_R/extract_local_io.R')",
      call. = FALSE
    )
  }
}

message("Etape 13b - matrice I/O locale TRE 2023 (basis: ", io_basis, ")")

# 1. Load local matrices
U <- as.matrix(read.csv(file.path(input_dir, "use_matrix_2023.csv"),
                        row.names = 1, check.names = FALSE))
R <- as.matrix(read.csv(file.path(input_dir, "resource_matrix_2023.csv"),
                        row.names = 1, check.names = FALSE))
hfce_df <- read.csv(file.path(input_dir, "hfce_2023.csv"), check.names = FALSE)

if (!identical(dim(U), dim(R))) {
  stop("Dimensions incompatibles entre matrices U et R.", call. = FALSE)
}

ind_codes <- colnames(U)
prod_codes <- rownames(U)

# 2. Industry and product output
g <- colSums(R)
q <- rowSums(R)

# 3. Derive product-by-product technical coefficients
# Industry technology assumption:
# B = U * inv(diag(g))      product x industry
# D = R' * inv(diag(q))     industry x product
# A = B * D                 product x product
B <- sweep(U, 2, g, "/")
B[!is.finite(B)] <- 0

D <- sweep(t(R), 2, q, "/")
D[!is.finite(D)] <- 0

A <- B %*% D

# 4. Leontief price inverse: tau = (I - A')^-1 * t
I <- diag(nrow(A))
L_inv <- solve(I - t(A))

# 5. VAT rates by TRE product
t_vec <- setNames(rep(0.18, length(prod_codes)), prod_codes)

# Exonerations / hors champ aligned with the local TRE product codes.
t_vec[c("A01", "A02", "A03", "A04", "A06", "E32", "L39", "P43", "Q44", "T47")] <- 0.00

tau <- as.numeric(L_inv %*% t_vec)
names(tau) <- prod_codes

tau_df <- data.frame(
  basis = io_basis,
  code = prod_codes,
  t_direct = t_vec,
  t_indirect = tau - t_vec,
  tau_total = tau
) %>% arrange(desc(tau_total))

# 6. Bridge TRE products to EHCVM codpr via the existing ICIO concordance
conc_oecd <- read_source_csv("concordance_codpr_ICIO.csv")

bridge <- tribble(
  ~secteur_ICIO, ~code_TRE,
  "A01_02", "A01", "A01_02", "A02", "A01_02", "A03", "A01_02", "A04", "A01_02", "A05",
  "A03", "A06",
  "C10T12", "C08", "C10T12", "C09", "C10T12", "C10", "C10T12", "C11", "C10T12", "C12", "C10T12", "C13", "C10T12", "C14", "C10T12", "C15",
  "C13T15", "C16", "C13T15", "C17",
  "C17_18", "C18", "C17_18", "C19",
  "C19", "C20",
  "C20", "C21",
  "C21", "C21",
  "C26", "C25",
  "C27", "C26",
  "C29", "C28",
  "C31T33", "C29", "C31T33", "C30",
  "D", "D31",
  "E", "E32",
  "F", "F33",
  "G", "G34",
  "H49", "H35", "H50", "H35", "H51", "H35", "H52", "H35", "H53", "H35",
  "I", "I36",
  "J58T60", "J37", "J61", "J37",
  "K", "K38",
  "L", "L39",
  "M", "M40",
  "N", "N41",
  "O", "O42",
  "P", "P43",
  "Q", "Q44",
  "R", "R45",
  "S", "S46",
  "T", "T47"
)

safe_mean <- function(x) {
  if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
}

conc_local <- conc_oecd %>%
  left_join(bridge, by = "secteur_ICIO", relationship = "many-to-many") %>%
  left_join(tau_df, by = c("code_TRE" = "code")) %>%
  group_by(codpr, libelle) %>%
  summarise(
    basis = first(io_basis),
    tau_total = safe_mean(tau_total),
    t_direct = safe_mean(t_direct),
    t_indirect = safe_mean(t_indirect),
    .groups = "drop"
  )

# 7. Household incidence
conso <- load_parquet(file.path(SILVER, "01", "conso_clean.parquet")) %>%
  select(hhid, hhweight, region, milieu, codpr, depan_w)

conso_local <- conso %>%
  left_join(conc_local %>% select(codpr, t_indirect, tau_total), by = "codpr") %>%
  mutate(
    t_indirect = replace_na(t_indirect, 0),
    tau_total = replace_na(tau_total, 0),
    vat_emb_item = depan_w * t_indirect
  )

hh_local <- conso_local %>%
  group_by(hhid) %>%
  summarise(
    hhweight = first(hhweight),
    vat_emb_local = sum(vat_emb_item, na.rm = TRUE),
    conso_w = sum(depan_w, na.rm = TRUE),
    .groups = "drop"
  )

fiscal <- load_parquet(file.path(SILVER, "03", "fiscal_data.parquet"))
fiscal_local <- fiscal %>%
  left_join(hh_local %>% select(hhid, vat_emb_local), by = "hhid") %>%
  mutate(
    io_basis = io_basis,
    vat_emb_local = replace_na(vat_emb_local, 0),
    eff_vat_local = (vat_w + vat_emb_local) / conso_w
  )

# 8. Results summary
cat("\n=== Comparaison TVA enchassee : OCDE vs LOCAL ===\n")
if (file.exists(file.path(SILVER, "13", "fiscal_data_io.parquet"))) {
  fiscal_oecd <- load_parquet(file.path(SILVER, "13", "fiscal_data_io.parquet")) %>%
    select(hhid, vat_emb_oecd = vat_emb)

  comp <- fiscal_local %>%
    left_join(fiscal_oecd, by = "hhid") %>%
    summarise(
      basis = first(io_basis),
      mean_emb_oecd = weighted.mean(vat_emb_oecd, hhweight, na.rm = TRUE),
      mean_emb_local = weighted.mean(vat_emb_local, hhweight, na.rm = TRUE),
      total_vat_oecd = sum(vat_emb_oecd * hhweight, na.rm = TRUE),
      total_vat_local = sum(vat_emb_local * hhweight, na.rm = TRUE)
    )
  print(comp)
}

# 9. Save
SILVER_13b <- file.path(SILVER, "13b")
dir.create(SILVER_13b, showWarnings = FALSE)

fiscal_out <- file.path(SILVER_13b, sprintf("fiscal_data_local_io_%s.parquet", io_basis))
tau_out <- file.path(SILVER_13b, sprintf("tau_local_sector_%s.csv", io_basis))

save_parquet(fiscal_local, fiscal_out)
write.csv(tau_df, tau_out, row.names = FALSE)

if (io_basis == "current") {
  save_parquet(fiscal_local, file.path(SILVER_13b, "fiscal_data_local_io.parquet"))
  write.csv(tau_df, file.path(SILVER_13b, "tau_local_sector.csv"), row.names = FALSE)
}

message("Etape 13b terminee - sorties: ", SILVER_13b)
