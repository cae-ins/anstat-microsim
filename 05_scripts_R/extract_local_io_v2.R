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

# 3. Extract Product Codes and Names (Resource section)
res_start <- 8
res_end <- 55 # U48 is at 55
prod_rows <- res_start:res_end
prod_codes <- as.character(df[prod_rows, 1])
prod_names <- as.character(df[prod_rows, 2])

# 4. Extract Resource Matrix (R): Products x Industries
R_mat <- df[prod_rows, ind_cols]
R_mat <- as.matrix(R_mat)
R_mat <- apply(R_mat, 2, function(x) as.numeric(as.character(x)))
R_mat[is.na(R_mat)] <- 0
rownames(R_mat) <- prod_codes
colnames(R_mat) <- ind_codes

# 5. Extract Use Matrix (U): Products x Industries
use_start <- 63
use_end <- use_start + length(prod_rows) - 1
U_mat <- df[use_start:use_end, ind_cols]
U_mat <- as.matrix(U_mat)
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

# 8. Compute Leontief Matrix (Symmetric Industry x Industry)
# Industry Output (g)
g <- colSums(R_mat)
# Product Output (q)
q <- rowSums(R_mat)

# Market Share Matrix (D) = R' * inv(diag(q))
# Industry Technology Assumption: SIOT = (U * inv(diag(g))) * (R' * inv(diag(q)))
# This is Product x Product matrix if we use the Industry Technology Assumption.
# Let's compute Technical Coefficients A = U * inv(diag(g))
# but we need Industry x Industry SIOT usually.

# For a quick check, let's just save the main matrices.
message("Success: Local matrices saved in ", output_dir)
