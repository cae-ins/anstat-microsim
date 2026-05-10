library(readxl)
path <- "C:/Users/f.migone/Desktop/projects/actif/anstat-microsim/00_documentation/EHCVM_products/COPR_EHCVM.xlsx"
cat("Sheets:", paste(excel_sheets(path), collapse=", "), "\n")
df <- read_excel(path, sheet=1, n_max=5)
cat("Columns:", paste(names(df), collapse=", "), "\n")
print(head(df, 5))
