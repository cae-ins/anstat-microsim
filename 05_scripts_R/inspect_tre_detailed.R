library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
df <- read_excel(file_path, sheet = "TRE", skip = 3)
print(colnames(df))
# Print the first few rows of the first 10 columns
print(df[1:40, 1:10])
