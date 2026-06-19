library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
df <- read_excel(file_path, sheet = "TRE")
print(paste("Rows:", nrow(df)))
# Search for keywords like "EMPLOIS" or "CONSOMMATIONS INTERMEDIAIRES" in the first column
print(df[50:150, 1:2])
