library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
# Read only the row that contains the branch codes (usually row 4 or 5)
branches <- read_excel(file_path, sheet = "TRE", skip = 3, n_max = 1)
print(colnames(branches))
# Let's also read the next few rows to see where the data starts
data_start <- read_excel(file_path, sheet = "TRE", skip = 3, n_max = 5)
print(data_start)
