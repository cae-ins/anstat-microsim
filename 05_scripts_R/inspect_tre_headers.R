library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
# Read first few rows but many columns
df <- read_excel(file_path, sheet = "TRE", n_max = 5)
col_names <- colnames(df)
# Row 1 and 2 often contain the Industry codes in TREs
headers <- read_excel(file_path, sheet = "TRE", n_max = 2, col_names = FALSE)
print(headers)
