library(readxl)

# Extract the 2023 Supply-Use Tables (TRE) used by the local Leontief model.
# The workbook layout is the same for current-price and constant-price files.

output_root <- "02_data_intermediate/IO_local"

make_numeric_matrix <- function(x) {
  mat <- apply(x, 2, function(col) {
    suppressWarnings(as.numeric(as.character(col)))
  })
  mat <- as.matrix(mat)
  mat[is.na(mat)] <- 0
  mat
}

write_tre_outputs <- function(U_mat, R_mat, hfce_df, valuation_df, output_dir) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  write.csv(as.data.frame(U_mat), file.path(output_dir, "use_matrix_2023.csv"))
  write.csv(as.data.frame(R_mat), file.path(output_dir, "resource_matrix_2023.csv"))
  write.csv(hfce_df, file.path(output_dir, "hfce_2023.csv"), row.names = FALSE)
  write.csv(
    valuation_df,
    file.path(output_dir, "valuation_bridge_2023.csv"),
    row.names = FALSE
  )
}

extract_tre <- function(tre_path, basis, output_dir, legacy_output_dir = NULL) {
  if (!file.exists(tre_path)) {
    stop("Fichier TRE introuvable: ", tre_path, call. = FALSE)
  }

  df <- read_excel(tre_path, sheet = "TRE", col_names = FALSE, .name_repair = "minimal")

  ind_cols <- 12:58
  ind_codes <- as.character(unlist(df[7, ind_cols], use.names = FALSE))

  res_start <- 8
  res_end <- 55
  prod_rows <- res_start:res_end
  prod_codes <- as.character(df[[1]][prod_rows])
  prod_names <- as.character(df[[2]][prod_rows])

  if (anyNA(ind_codes) || anyNA(prod_codes)) {
    stop("Codes secteurs/produits manquants dans ", tre_path, call. = FALSE)
  }

  R_mat <- make_numeric_matrix(df[prod_rows, ind_cols])
  rownames(R_mat) <- prod_codes
  colnames(R_mat) <- ind_codes

  use_start <- 63
  use_end <- use_start + length(prod_rows) - 1
  U_mat <- make_numeric_matrix(df[use_start:use_end, ind_cols])
  rownames(U_mat) <- prod_codes
  colnames(U_mat) <- ind_codes

  hfce <- suppressWarnings(as.numeric(as.character(df[[65]][use_start:use_end])))
  hfce[is.na(hfce)] <- 0
  hfce_df <- data.frame(code = prod_codes, name = prod_names, hfce = hfce)

  numeric_source_column <- function(column) {
    value <- suppressWarnings(as.numeric(as.character(df[[column]][prod_rows])))
    value[is.na(value)] <- 0
    value
  }

  valuation_df <- data.frame(
    code = prod_codes,
    name = prod_names,
    purchaser_total = numeric_source_column(3),
    trade_margins = numeric_source_column(4),
    transport_margins = numeric_source_column(5),
    nondeductible_vat = numeric_source_column(6),
    product_subsidies = numeric_source_column(7),
    other_product_taxes = numeric_source_column(8),
    export_taxes = numeric_source_column(9),
    import_taxes = numeric_source_column(10),
    basic_total = numeric_source_column(11),
    imports = numeric_source_column(63),
    domestic_output = rowSums(R_mat)
  )

  write_tre_outputs(U_mat, R_mat, hfce_df, valuation_df, output_dir)
  if (!is.null(legacy_output_dir)) {
    write_tre_outputs(
      U_mat, R_mat, hfce_df, valuation_df, legacy_output_dir
    )
  }

  data.frame(
    basis = basis,
    source_file = tre_path,
    n_products = length(prod_codes),
    n_industries = length(ind_codes),
    resource_total = sum(R_mat),
    use_total = sum(U_mat),
    hfce_total = sum(hfce),
    output_dir = output_dir
  )
}

summaries <- rbind(
  extract_tre(
    tre_path = "01_data_sources/IO/TRE_COURANT_2023.XLS",
    basis = "current",
    output_dir = file.path(output_root, "current"),
    legacy_output_dir = output_root
  ),
  extract_tre(
    tre_path = "01_data_sources/IO/TRE_CONSTANT_2023.XLS",
    basis = "constant",
    output_dir = file.path(output_root, "constant")
  )
)

write.csv(summaries, file.path(output_root, "extract_summary_2023.csv"), row.names = FALSE)
print(summaries)
message("Success: local TRE matrices saved in ", output_root)
