library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
# Read row 5 (skip 4) to find Industry names/codes
row5 <- read_excel(file_path, sheet = "TRE", skip = 4, n_max = 1, col_names = FALSE)
print(as.character(row5))

# Read row 6 (skip 5)
row6 <- read_excel(file_path, sheet = "TRE", skip = 5, n_max = 1, col_names = FALSE)
print(as.character(row6))
