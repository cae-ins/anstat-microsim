# 00_setup.R
#
# Environment setup: paths, packages, utility functions.
# Must be run from the project root directory.
#
# USAGE: source("05_scripts_R/00_setup.R")
#
# AUTHOR: Armand Kouakou Djaha (original Stata)
# R rewrite: rewrite-r branch

# ── Verify working directory ──────────────────────────────────────────────────
if (!file.exists("05_scripts_R/00_setup.R")) {
  stop(
    "Wrong working directory.\n",
    "Run R from the project root folder (where 05_scripts_R/ is visible)."
  )
}

ROOT <- getwd()

# ── Source paths ───────────────────────────────────────────────────────────────
DATA   <- file.path(ROOT, "01_data_sources", "Dataout")
CODE   <- file.path(ROOT, "05_scripts_R")

# ── Load config (data source flag + MinIO credentials) ────────────────────────
source(file.path(CODE, "config.R"))

# ── Medallion layers ───────────────────────────────────────────────────────────
SILVER <- file.path(ROOT, "02_data_intermediate")
GOLD   <- file.path(ROOT, "03_data_output")

# ── Reports ────────────────────────────────────────────────────────────────────
LOGS   <- file.path(ROOT, "06_logs")
TABLES <- file.path(ROOT, "07_reports", "tables")
FIGS   <- file.path(ROOT, "07_reports", "figures")

# ── Create directories if missing ─────────────────────────────────────────────
for (d in c(
  SILVER,
  file.path(SILVER, "01"), file.path(SILVER, "02"),
  file.path(SILVER, "03"), file.path(SILVER, "04"),
  file.path(SILVER, "05"), file.path(SILVER, "06"),
  file.path(SILVER, "10"),
  GOLD, LOGS,
  file.path(ROOT, "07_reports"), TABLES,
  file.path(TABLES, "01"), file.path(TABLES, "04"),
  file.path(TABLES, "05"), file.path(TABLES, "06"),
  file.path(TABLES, "07"), file.path(TABLES, "09"),
  file.path(TABLES, "10"), file.path(TABLES, "12"), FIGS
)) {
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
}

# ── Required packages ──────────────────────────────────────────────────────────
required_packages <- c(
  "haven",       # read Stata .dta files
  "arrow",       # parquet I/O (fast intermediate files)
  "dplyr",       # data manipulation
  "tidyr",       # reshaping
  "tibble",      # tibble construction
  "purrr",       # functional programming (map, map_dfr)
  "ggplot2",     # figures
  "scales",      # ggplot2 axis helpers
  "openxlsx",    # Excel export
  "readxl",      # Excel import
  "sandwich",    # cluster-robust variance-covariance matrices
  "lmtest"       # coeftest with robust SE
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing package: ", pkg)
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

# ── Source utility functions ───────────────────────────────────────────────────
source(file.path(CODE, "utils", "distributive.R"))
source(file.path(CODE, "utils", "io.R"))

message("✓ Setup complete. Working directory: ", ROOT)
