# utils/io.R
#
# I/O helpers: parquet, Excel, figures, raw data (local or MinIO).
# Thin wrappers that log output paths and create directories as needed.
#
# Data source is controlled by USE_MINIO (set in config.R):
#   USE_MINIO = FALSE  → read from local DATA/ path (default)
#   USE_MINIO = TRUE   → read from MinIO via arrow S3 filesystem


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
    haven::read_dta(tmp, col_select = col_select, ...)
  } else {
    # ── Local path ────────────────────────────────────────────────────────────
    local_path <- file.path(DATA, filename)
    if (!file.exists(local_path)) {
      stop("File not found: ", local_path)
    }
    haven::read_dta(local_path, col_select = col_select, ...)
  }
}


# ── Parquet ───────────────────────────────────────────────────────────────────
save_parquet <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  arrow::write_parquet(as.data.frame(df), path)
  message("  → saved: ", path)
}

load_parquet <- function(path) {
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
