# 00_master.R
# Script maitre — execute le pipeline complet.
#
# Inspire de l'architecture INES (Microsimulation INSEE) enchainement.R :
# chaque etape est une fonction nommee ; l'orchestrateur itere a travers un
# data-frame des etapes et les appelle sequentiellement.
#
# UTILISATION:
#   # Depuis le dossier racine du projet en R:
#   source("05_scripts_R/00_master.R")
#
#   # Ou executer un sous-ensemble d'etapes:
#   source("05_scripts_R/00_master.R"); lance_pipeline(1, 5)
#
# AUTEUR: Armand Kouakou Djaha, MSc (pipeline Stata original)
# Traduction R: rewrite-r branch

# ── Configuration (chemins, packages, fonctions utilitaires) ───────────────────────────────
source("05_scripts_R/00_setup.R")

# ── Charger tous les modules d'etapes ────────────────────────────────────────────────────
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
  "11_reform_figures.R",
  "12_poverty_incidence.R"
)

for (f in step_files) {
  source(file.path(CODE, f))
}

# ── Definition du pipeline ( Inspire de INES enchainement.R) ────────────────────
# data.frame avec une ligne par etape : id, description, nom de fonction
enchainement <- tibble::tibble(
  etape_id    = 1:13,
  description = c(
    "Preparation des donnees EHCVM",
    "Mapping TVA par produit",
    "Calcul de l'incidence TVA",
    "Analyse distributive (deciles, quintiles, milieu, region)",
    "Indices de progressivite (Gini, Kakwani, Reynolds-Smolensky)",
    "Sensibilite — scenarios de taxation (alpha strict / milieu / decile)",
    "Sensibilite — classements distributifs (total / pc / AE1 / AE2)",
    "Tableaux annexes",
    "Figures analytiques (fig1-fig4)",
    "Determinants de la TVA effective (regressions OLS)",
    "Simulation reforme intrants avicoles",
    "Figures reforme (figR1-figR4)",
    "Incidence sur la povrete (FGT) — TVA et reforme avicole"
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
    "run_reform_figures",
    "run_poverty_incidence"
  )
)

# ── Objet paths (passe a chaque fonction d'etape) ───────────────────────────────
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

# ── Orchestrateur ──────────────────────────────────────────────────────────────
lance_pipeline <- function(premiere_etape = 1,
                           derniere_etape  = 13,
                           verbose         = TRUE) {

  stopifnot(
    is.numeric(premiere_etape), length(premiere_etape) == 1,
    is.numeric(derniere_etape),  length(derniere_etape) == 1
  )

  premiere_etape <- as.integer(premiere_etape)
  derniere_etape <- as.integer(derniere_etape)

  max_step <- max(enchainement$etape_id)
  if (premiere_etape < 1 || derniere_etape > max_step || premiere_etape > derniere_etape) {
    stop(sprintf(
      "Plage d'etapes invalide : [%d, %d]. Plage valide : [1, %d].",
      premiere_etape, derniere_etape, max_step
    ))
  }

  steps <- dplyr::filter(enchainement,
                          etape_id >= premiere_etape,
                          etape_id <= derniere_etape)

  for (i in seq_len(nrow(steps))) {
    step <- steps[i, ]

    if (verbose) {
      message(sprintf(
        "\n===== Etape %02d / %02d : %s",
        step$etape_id, max(steps$etape_id), step$description
      ))
    }

    fn <- tryCatch(
      get(step$fonction, envir = .GlobalEnv),
      error = function(e) {
        stop(sprintf("Fonction '%s' non trouvee. Tous les fichiers d'etapes ont-ils ete charges?",
                     step$fonction))
      }
    )

    tryCatch(
      fn(paths),
      error = function(e) {
        message(sprintf("\n✘ ERREUR a l'etape %d (%s):\n  %s",
                        step$etape_id, step$fonction,
                        conditionMessage(e)))
        stop(e)
      }
    )

    if (verbose) {
      message(sprintf("\n✓ Etape %02d terminee", step$etape_id))
    }
  }

  if (verbose) {
    message("\n==================================================")
    message(" PIPELINE TERMINE AVEC SUCCES")
    message("==================================================")
  }

  invisible(NULL)
}

# ── Execution ────────────────────────────────────────────────────────────────────────
lance_pipeline(premiere_etape = 1, derniere_etape = 13)