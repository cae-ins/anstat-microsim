library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
df <- read_excel(file_path, sheet = "TRE", col_names = FALSE)
# Look at columns 55 to 74 for row 60 (headers of Emplois)
print(as.character(df[60, 55:ncol(df)]))
# Look at columns 55 to 74 for row 61
print(as.character(df[61, 55:ncol(df)]))
