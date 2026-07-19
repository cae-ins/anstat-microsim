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
  file.path(SILVER, "16"), file.path(SILVER, "17"),
  file.path(SILVER, "18"), file.path(SILVER, "19"),
  file.path(SILVER, "20"), file.path(SILVER, "21"),
  file.path(SILVER, "22"), file.path(SILVER, "23"),
  file.path(SILVER, "24"),
  GOLD, LOGS,
  file.path(ROOT, "07_reports"), TABLES,
  file.path(TABLES, "01"), file.path(TABLES, "04"),
  file.path(TABLES, "05"), file.path(TABLES, "06"),
  file.path(TABLES, "07"), file.path(TABLES, "09"),
  file.path(TABLES, "10"), file.path(TABLES, "12"),
  file.path(TABLES, "14"), file.path(TABLES, "15"),
  file.path(TABLES, "16"), file.path(TABLES, "17"),
  file.path(TABLES, "18"), file.path(TABLES, "19"),
  file.path(TABLES, "20"), file.path(TABLES, "21"),
  file.path(TABLES, "22"), file.path(TABLES, "23"),
  file.path(TABLES, "24"), file.path(TABLES, "25"), FIGS
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
  "lmtest",      # coeftest avec SE robustes
  "jsonlite"     # manifeste de réplication JSON
)

strict_replication <- identical(Sys.getenv("CEQ_REPLICATION_STRICT"), "1")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L && strict_replication) {
  stop(
    "Paquets R absents en mode réplication stricte : ",
    paste(missing_packages, collapse = ", "),
    ". Exécuter renv::restore() depuis la racine du dépôt.",
    call. = FALSE
  )
}
for (pkg in missing_packages) {
  message("Installation du package: ", pkg)
  install.packages(pkg, repos = "https://cloud.r-project.org")
}
for (pkg in required_packages) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# ── Charger les fonctions utilitaires ───────────────────────────────────────────────────
source(file.path(CODE, "utils", "distributive.R"))
source(file.path(CODE, "utils", "io.R"))
source(file.path(CODE, "utils", "leontief_vat.R"))
source(file.path(CODE, "utils", "vat_scenarios.R"))
source(file.path(CODE, "utils", "tre_mapping.R"))

message("✓ Configuration terminee. Dossier de travail: ", ROOT)
