library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
sheets <- excel_sheets(file_path)
print(paste("Sheets in", file_path, ":"))
print(sheets)

# Try to read the first sheet
df <- read_excel(file_path, sheet = sheets[1], n_max = 20)
print(head(df))
