library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
# Read many columns for row 5
row5_all <- read_excel(file_path, sheet = "TRE", skip = 4, n_max = 1, col_names = FALSE)
print(as.character(row5_all))
# Check how many columns are there
print(ncol(row5_all))
