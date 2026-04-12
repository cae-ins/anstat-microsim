# utils/io.R
#
# I/O helpers: parquet, Excel, figures
# Thin wrappers that log output paths and create directories as needed.


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
