library(readxl)
library(dplyr)
library(tidyr)

# Paths
tre_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
output_dir <- "02_data_intermediate/IO_local"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# 1. Load the full sheet
df <- read_excel(tre_path, sheet = "TRE", col_names = FALSE)

# 2. Extract Industry Codes
ind_cols <- 12:58
ind_codes <- as.character(df[7, ind_cols])
print(paste("Number of industry codes:", length(ind_codes)))

# 3. Extract Product Codes and Names (Resource section)
res_start <- 8
res_end <- 55 # U48 is at 55
prod_rows <- res_start:res_end
prod_codes <- as.character(df[prod_rows, 1])
prod_names <- as.character(df[prod_rows, 2])
print(paste("Number of product codes:", length(prod_codes)))

# 4. Extract Resource Matrix (R): Products x Industries
R_mat_raw <- df[prod_rows, ind_cols]
print(paste("R_mat_raw dim:", nrow(R_mat_raw), "x", ncol(R_mat_raw)))

R_mat <- as.matrix(R_mat_raw)
R_mat <- apply(R_mat, 2, function(x) as.numeric(as.character(x)))
R_mat[is.na(R_mat)] <- 0
print(paste("R_mat dim:", nrow(R_mat), "x", ncol(R_mat)))

# Try to set dimnames manually
rownames(R_mat) <- prod_codes
colnames(R_mat) <- ind_codes

message("Success setting names for R_mat")

# 5. Extract Use Matrix (U): Products x Industries
use_start <- 63
use_end <- use_start + length(prod_rows) - 1
U_mat_raw <- df[use_start:use_end, ind_cols]
print(paste("U_mat_raw dim:", nrow(U_mat_raw), "x", ncol(U_mat_raw)))

U_mat <- as.matrix(U_mat_raw)
U_mat <- apply(U_mat, 2, function(x) as.numeric(as.character(x)))
U_mat[is.na(U_mat)] <- 0
rownames(U_mat) <- prod_codes
colnames(U_mat) <- ind_codes

# 6. Extract Final Demand (HFCE)
# Col 65 is Ménages
hfce <- as.numeric(as.character(df[use_start:use_end, 65]))
hfce[is.na(hfce)] <- 0

# 7. Save to CSV
write.csv(as.data.frame(U_mat), file.path(output_dir, "use_matrix_2023.csv"))
write.csv(as.data.frame(R_mat), file.path(output_dir, "resource_matrix_2023.csv"))
write.csv(data.frame(code=prod_codes, name=prod_names, hfce=hfce), file.path(output_dir, "hfce_2023.csv"), row.names=FALSE)

message("Success: Local matrices saved in ", output_dir)
