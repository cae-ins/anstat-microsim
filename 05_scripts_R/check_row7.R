library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
df <- read_excel(file_path, sheet = "TRE", col_names = FALSE)
ind_cols <- 12:58
print(as.character(df[7, ind_cols]))
