library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
df <- read_excel(file_path, sheet = "TRE", col_names = FALSE)

# Locate products in Resource section
res_start <- 8
res_end <- which(df$...1 == "U48")[1] # Use the first one
print(paste("Resource products end at row:", res_end))

# Locate industries columns
ind_cols <- 12:58
print(paste("Industry codes:", paste(as.character(df[6, ind_cols]), collapse=", ")))

# Locate products in Use section
use_label_row <- which(df$...1 == "Emploi des produits")
print(paste("Use label row:", use_label_row))
use_start <- use_label_row + 3
# The number of products is the same
num_prods <- res_end - res_start + 1
use_end <- use_start + num_prods - 1
print(paste("Use products end at row:", use_end))

# Final Demand check
print(paste("Final Demand columns start after industry block (col 58)"))
print(as.character(df[use_label_row, 59:ncol(df)]))
