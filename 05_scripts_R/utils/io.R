# utils/io.R
#
# I/O helpers: parquet, Excel, figures, raw data (local or MinIO).
# Thin wrappers that log output paths and create directories as needed.
#
# Data source is controlled by USE_MINIO (set in config.R):
#   USE_MINIO = FALSE  → read from local DATA/ path (default)
#   USE_MINIO = TRUE   → read from MinIO via arrow S3 filesystem


# Internal helper: fail fast on missing local files.
assert_local_file_exists <- function(path, label = NULL) {
  if (!file.exists(path)) {
    stop(sprintf(
      "%s not found: %s",
      if (is.null(label)) "File" else label,
      path
    ))
  }
  invisible(path)
}


# Internal helper: validate required columns before downstream use.
assert_required_columns <- function(df, required, object_name = deparse(substitute(df))) {
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop(sprintf(
      "%s is missing required columns: %s",
      object_name,
      paste(missing, collapse = ", ")
    ))
  }
  invisible(df)
}


# Resolve a project source file without changing the current folder structure.
source_file_path <- function(..., must_exist = TRUE, label = "Source file") {
  path <- file.path(ROOT, "01_data_sources", ...)
  if (must_exist) {
    assert_local_file_exists(path, label = label)
  }
  path
}


# ── Raw .dta loader (local or MinIO) ─────────────────────────────────────────
# Usage: load_raw_dta("ehcvm_welfare_2b_CIV2021.dta")
#        load_raw_dta("ehcvm_welfare_2b_CIV2021.dta", col_select = c("hhid","hhsize"))
load_raw_dta <- function(filename, col_select = NULL, ...) {
  if (exists("USE_MINIO") && isTRUE(USE_MINIO)) {
    # ── MinIO path ────────────────────────────────────────────────────────────
    # Downloads to a temp file, then reads with haven.
    # Requires: aws.s3 package + MINIO_* env vars set in config.R
    if (!requireNamespace("aws.s3", quietly = TRUE)) {
      stop("Package 'aws.s3' required for MinIO access. ",
           "Install with: install.packages('aws.s3')")
    }
    s3_key  <- filename
    tmp     <- tempfile(fileext = ".dta")
    aws.s3::save_object(
      object = s3_key,
      bucket = MINIO_BUCKET_RAW,
      file   = tmp,
      region = "",
      base_url = sub("^https?://", "", MINIO_ENDPOINT),
      key    = MINIO_ACCESS_KEY,
      secret = MINIO_SECRET_KEY
    )
    message("  ← MinIO: ", MINIO_BUCKET_RAW, "/", s3_key)
    if (is.null(col_select)) {
      haven::read_dta(tmp, ...)
    } else {
      haven::read_dta(tmp, col_select = tidyselect::all_of(col_select), ...)
    }
  } else {
    # ── Local path ────────────────────────────────────────────────────────────
    local_path <- file.path(DATA, filename)
    assert_local_file_exists(local_path, label = "Raw DTA file")
    if (is.null(col_select)) {
      haven::read_dta(local_path, ...)
    } else {
      haven::read_dta(local_path, col_select = tidyselect::all_of(col_select), ...)
    }
  }
}


read_source_excel <- function(path_parts, sheet = NULL, .label = "Excel source",
                              .required_cols = NULL, ...) {
  path <- do.call(source_file_path, c(as.list(path_parts), list(label = .label)))
  df <- readxl::read_excel(path, sheet = sheet, ...)
  if (!is.null(.required_cols)) {
    assert_required_columns(df, .required_cols, object_name = basename(path))
  }
  df
}


read_source_csv <- function(path_parts, .label = "CSV source",
                            .required_cols = NULL, ...) {
  path <- do.call(source_file_path, c(as.list(path_parts), list(label = .label)))
  df <- readr::read_csv(path, show_col_types = FALSE, ...)
  if (!is.null(.required_cols)) {
    assert_required_columns(df, .required_cols, object_name = basename(path))
  }
  df
}


read_source_csv_base <- function(path_parts, row.names = NULL, check.names = FALSE,
                                 .label = "CSV source") {
  path <- do.call(source_file_path, c(as.list(path_parts), list(label = .label)))
  utils::read.csv(path, row.names = row.names, check.names = check.names)
}


# ── Parquet ───────────────────────────────────────────────────────────────────
save_parquet <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  arrow::write_parquet(as.data.frame(df), path)
  message("  → saved: ", path)
}

load_parquet <- function(path) {
  assert_local_file_exists(path, label = "Parquet file")
  arrow::read_parquet(path)
}


# ── Excel ─────────────────────────────────────────────────────────────────────
export_excel <- function(df, path, sheet = "Sheet1") {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  openxlsx::write.xlsx(as.data.frame(df), file = path,
                       sheetName = sheet, overwrite = TRUE)
  message("  → exported: ", path)
}


# ── Figures ───────────────────────────────────────────────────────────────────
export_fig <- function(p, path, width = 12, height = 8, dpi = 300) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(path, plot = p, width = width, height = height,
                  dpi = dpi, bg = "white")
  message("  → figure: ", path)
}


# ── Regression table helper ───────────────────────────────────────────────────
# Extracts tidy coefficient table with cluster-robust SE.
tidy_lm_robust <- function(model, cluster_var, df_correction = TRUE) {
  vcov_cl  <- sandwich::vcovCL(model, cluster = cluster_var)
  coefs    <- coef(model)
  se       <- sqrt(diag(vcov_cl))
  tstat    <- coefs / se
  pval     <- 2 * pt(abs(tstat), df = model$df.residual, lower.tail = FALSE)
  stars    <- dplyr::case_when(
    pval < 0.01 ~ "***",
    pval < 0.05 ~ "**",
    pval < 0.10 ~ "*",
    TRUE        ~ ""
  )
  tibble::tibble(
    term      = names(coefs),
    estimate  = coefs,
    std_error = se,
    t_stat    = tstat,
    p_value   = pval,
    sig       = stars
  )
}
