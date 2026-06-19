library(readxl)
file_path <- "01_data_sources/IO/TRE_COURANT_2023.XLS"
df <- read_excel(file_path, sheet = "TRE", col_names = FALSE)
emploi_row <- which(df$...1 == "Emploi des produits")
print(paste("Emploi des produits starts at row:", emploi_row))

# Show rows around the start of Emploi
print(df[(emploi_row-5):(emploi_row+20), 1:12])
