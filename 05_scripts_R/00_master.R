# 00_master.R
# Master script — runs the full pipeline.
#
# Inspired by the INES (Microsimulation INSEE) enchainement.R architecture:
# each step is a named function; the orchestrator iterates through a
# data-frame of steps and calls them sequentially.
#
# USAGE:
#   # From the project root directory in R:
#   source("05_scripts_R/00_master.R")
#
#   # Or run a subset of steps:
#   source("05_scripts_R/00_master.R"); lance_pipeline(1, 5)
#
# AUTHOR: Armand Kouakou Djaha, MSc (original Stata pipeline)
# R rewrite: rewrite-r branch

# ── Setup (paths, packages, utility functions) ────────────────────────────────
source("05_scripts_R/00_setup.R")

# ── Source all step modules ────────────────────────────────────────────────────
step_files <- c(
  "01_prepare_data.R",
  "02_mapping_tax.R",
  "03_compute_taxes.R",
  "04_analysis.R",
  "05_progressivity.R",
  "06_01_sensitivity_taxation.R",
  "06_02_sensitivity_ranking.R",
  "07_appendix_tables.R",
  "08_figures.R",
  "09_vat_determinants.R",
  "10_reform_chicken_inputs.R",
  "11_reform_figures.R"
)

for (f in step_files) {
  source(file.path(CODE, f))
}

# ── Pipeline definition (inspired by INES enchainement.R) ────────────────────
# data.frame with one row per step: id, description, function name
enchainement <- tibble::tibble(
  etape_id    = 1:12,
  description = c(
    "Pr\u00e9paration des donn\u00e9es EHCVM",
    "Mapping TVA par produit",
    "Calcul de l'incidence TVA",
    "Analyse distributive (d\u00e9ciles, quintiles, milieu, r\u00e9gion)",
    "Indices de progressivit\u00e9 (Gini, Kakwani, Reynolds-Smolensky)",
    "Sensibilit\u00e9 \u2014 sc\u00e9narios de taxation (alpha strict / milieu / d\u00e9cile)",
    "Sensibilit\u00e9 \u2014 classements distributifs (total / pc / AE1 / AE2)",
    "Tableaux annexes",
    "Figures analytiques (fig1\u2013fig4)",
    "D\u00e9terminants de la TVA effective (r\u00e9gressions OLS)",
    "Simulation r\u00e9forme intrants avicoles",
    "Figures r\u00e9forme (figR1\u2013figR4)"
  ),
  fonction = c(
    "prepare_data",
    "map_tax",
    "compute_taxes",
    "run_analysis",
    "run_progressivity",
    "run_sensitivity_taxation",
    "run_sensitivity_ranking",
    "run_appendix_tables",
    "run_figures",
    "run_determinants",
    "run_reform_chicken",
    "run_reform_figures"
  )
)

# ── Paths object (passed to each step function) ───────────────────────────────
paths <- list(
  ROOT   = ROOT,
  DATA   = DATA,
  CODE   = CODE,
  SILVER = SILVER,
  GOLD   = GOLD,
  LOGS   = LOGS,
  TABLES = TABLES,
  FIGS   = FIGS
)

# ── Orchestrator ──────────────────────────────────────────────────────────────
lance_pipeline <- function(premiere_etape = 1,
                           derniere_etape  = 12,
                           verbose         = TRUE) {

  steps <- dplyr::filter(enchainement,
                          etape_id >= premiere_etape,
                          etape_id <= derniere_etape)

  for (i in seq_len(nrow(steps))) {
    step <- steps[i, ]

    if (verbose) {
      message(sprintf(
        "\n\u2550\u2550\u2550\u2550\u2550\u2550 \u00c9tape %02d / %02d : %s",
        step$etape_id, max(steps$etape_id), step$description
      ))
    }

    fn <- tryCatch(
      get(step$fonction, envir = .GlobalEnv),
      error = function(e) {
        stop(sprintf("Function '%s' not found. Did all step files load?",
                     step$fonction))
      }
    )

    tryCatch(
      fn(paths),
      error = function(e) {
        message(sprintf("\u274c ERREUR \u00e0 l'\u00e9tape %d (%s):\n  %s",
                        step$etape_id, step$fonction,
                        conditionMessage(e)))
        stop(e)
      }
    )

    if (verbose) {
      message(sprintf("\u2713 \u00c9tape %02d termin\u00e9e", step$etape_id))
    }
  }

  if (verbose) {
    message("\n\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550")
    message(" PIPELINE TERMIN\u00c9 AVEC SUCC\u00c8S")
    message("\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550")
  }

  invisible(NULL)
}

# ── Run ────────────────────────────────────────────────────────────────────────
lance_pipeline(premiere_etape = 1, derniere_etape = 12)
