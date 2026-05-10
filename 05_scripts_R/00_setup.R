# 00_setup.R
#
# Configuration de l'environnement : chemins, packages, fonctions utilitaires.
# Doit etre execute depuis le dossier racine du projet.
#
# UTILISATION: source("05_scripts_R/00_setup.R")
#
# AUTEUR: Armand Kouakou Djaha (version Stata originale)
#Traduction R: rewrite-r branch

# ── Verifier le dossier de travail ──────────────────────────────────────────────────
if (!file.exists("05_scripts_R/00_setup.R")) {
  stop(
    "Dossier de travail incorrect.\n",
    "Executer R depuis le dossier racine du projet (ou 05_scripts_R/ est visible)."
  )
}

ROOT <- getwd()

# ── Chemins des sources ───────────────────────────────────────────────────────────────
DATA   <- file.path(ROOT, "01_data_sources", "Dataout")
CODE   <- file.path(ROOT, "05_scripts_R")

# ── Charger la config (flag source de donnees + identifiants MinIO) ────────────────────────
source(file.path(CODE, "config.R"))

# ── Couches Medallion ───────────────────────────────────────────────────────────
SILVER <- file.path(ROOT, "02_data_intermediate")
GOLD   <- file.path(ROOT, "03_data_output")

# ── Rapports ────────────────────────────────────────────────────────────────────
LOGS   <- file.path(ROOT, "06_logs")
TABLES <- file.path(ROOT, "07_reports", "tables")
FIGS   <- file.path(ROOT, "07_reports", "figures")

# ── Creer les dossiers si absents ─────────────────────────────────────────────
for (d in c(
  SILVER,
  file.path(SILVER, "01"), file.path(SILVER, "02"),
  file.path(SILVER, "03"), file.path(SILVER, "04"),
  file.path(SILVER, "05"), file.path(SILVER, "06"),
  file.path(SILVER, "10"), file.path(SILVER, "13"),
  file.path(SILVER, "14"), file.path(SILVER, "15"),
  GOLD, LOGS,
  file.path(ROOT, "07_reports"), TABLES,
  file.path(TABLES, "01"), file.path(TABLES, "04"),
  file.path(TABLES, "05"), file.path(TABLES, "06"),
  file.path(TABLES, "07"), file.path(TABLES, "09"),
  file.path(TABLES, "10"), file.path(TABLES, "12"),
  file.path(TABLES, "14"), file.path(TABLES, "15"),FIGS
)) {
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
}

# ── Packages requis ──────────────────────────────────────────────────────────
required_packages <- c(
  "haven",       # lire fichiers Stata .dta
  "arrow",       # I/O parquet (fichiers intermediaires rapides)
  "dplyr",       # manipulation des donnees
  "tidyr",       # remanie ment
  "tibble",      # construction tibble
  "purrr",       # programmation fonctionnelle (map, map_dfr)
  "ggplot2",     # graphique s
  "scales",      # helpers axes ggplot2
  "openxlsx",    # export Excel
  "readxl",      # import Excel
  "readr",       # import CSV
  "sandwich",    # matrices de variance-covariance robustes en cluster
  "lmtest"       # coeftest avec SE robustes
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installation du package: ", pkg)
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE)
  )
}

# ── Charger les fonctions utilitaires ───────────────────────────────────────────────────
source(file.path(CODE, "utils", "distributive.R"))
source(file.path(CODE, "utils", "io.R"))

message("✓ Configuration terminee. Dossier de travail: ", ROOT)