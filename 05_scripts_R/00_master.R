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
  "01_prepare_data.R", "02_mapping_tax.R", "03_compute_taxes.R",
  "04_analysis.R", "05_progressivity.R", "06_01_sensitivity_taxation.R",
  "06_02_sensitivity_ranking.R", "07_appendix_tables.R", "08_figures.R",
  "09_vat_determinants.R", "10_reform_chicken_inputs.R", "11_reform_figures.R",
  "12_poverty_incidence.R", "16_direct_taxes.R", "17_indirect_other.R",
  "18_transfers.R", "19_subsidies.R", "20_inkind_education.R",
  "21_inkind_health.R", "22_income_concepts.R", "23_marginal_contribution.R",
  "24_fiscal_impoverishment.R", "25_ceq_report_tables.R"
)

for (f in step_files) {
  source(file.path(CODE, f))
}

# Les etapes 13-15 (Leontief I/O, pauvrete I/O, reforme TVA) sont des scripts
# autonomes qui s'executent des le source(). On les enveloppe dans des
# fonctions paresseuses pour pouvoir les enchainer depuis lance_pipeline().
run_leontief_io <- function(paths) {
  local_io_files <- file.path(
    SILVER, "IO_local", rep(c("current", "constant"), each = 3),
    rep(c("A_domestic_2023.csv", "imports_2023.csv", "valuation_bridge_2023.csv"), 2)
  )
  if (!all(file.exists(local_io_files))) {
    tre_sources <- file.path(
      ROOT, "01_data_sources", "IO",
      c("TRE_COURANT_2023.XLS", "TRE_CONSTANT_2023.XLS")
    )
    missing_tre <- tre_sources[!file.exists(tre_sources)]
    if (length(missing_tre) > 0L) {
      stop(
        "Fichiers TRE requis pour l'étape 14 : ",
        paste(missing_tre, collapse = ", "),
        ". Voir replication_package/data/access-restricted-data.md.",
        call. = FALSE
      )
    }
    source(file.path(CODE, "extract_local_io_v4.R"))
  }
  source(file.path(CODE, "13_leontief_io.R"))
  old_basis <- Sys.getenv("IO_LOCAL_BASIS", unset = NA_character_)
  on.exit({
    if (is.na(old_basis)) Sys.unsetenv("IO_LOCAL_BASIS")
    else Sys.setenv(IO_LOCAL_BASIS = old_basis)
  }, add = TRUE)
  for (basis in c("current", "constant")) {
    Sys.setenv(IO_LOCAL_BASIS = basis)
    source(file.path(CODE, "13b_leontief_local_io.R"))
  }
}
run_leontief_poverty <- function(paths) source(file.path(CODE, "14_leontief_poverty.R"))
run_reform_vat       <- function(paths) source(file.path(CODE, "15_reform_vat_simulation.R"))

# ── Definition du pipeline ( Inspire de INES enchainement.R) ────────────────────
# data.frame avec une ligne par etape : id, description, nom de fonction
enchainement <- tibble::tibble(
  etape_id = 1:26,
  description = c(
    "Preparation des donnees EHCVM", "Mapping TVA par produit",
    "Calcul de l'incidence TVA", "Analyse distributive",
    "Indices de progressivite", "Sensibilite des scenarios de taxation",
    "Sensibilite des classements distributifs", "Tableaux annexes",
    "Figures analytiques", "Determinants de la TVA effective",
    "Simulation reforme intrants avicoles", "Figures reforme",
    "Incidence sur la pauvrete", "TVA enchassee par matrice entrees-sorties",
    "Pauvrete avec TVA enchassee", "Simulation reforme TVA 0% vers 9%",
    "Impots directs et cotisations", "Accises et droits de douane",
    "Pensions, paiements directs et filets sociaux",
    "Reductions de prix sur electricite, eau et carburants",
    "Services publics d'education attribues aux menages",
    "Services publics de sante attribues aux menages",
    "Assemblage des concepts de revenu CEQ",
    "Contributions distributives et decomposition de Shapley",
    "Appauvrissement fiscal et gains sous le seuil",
    "Tables CEQ finales, controle ANSTAT et manifeste"
  ),
  fonction = c(
    "prepare_data", "map_tax", "compute_taxes", "run_analysis",
    "run_progressivity", "run_sensitivity_taxation", "run_sensitivity_ranking",
    "run_appendix_tables", "run_figures", "run_determinants",
    "run_reform_chicken", "run_reform_figures", "run_poverty_incidence",
    "run_leontief_io", "run_leontief_poverty", "run_reform_vat",
    "direct_taxes", "indirect_other", "transfers", "subsidies",
    "inkind_education", "inkind_health", "income_concepts",
    "marginal_contribution", "fiscal_impoverishment", "ceq_report_tables"
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
                           derniere_etape  = 26,
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

# Le chargement du master ne lance aucune etape. L'appel est toujours explicite,
# par exemple: source('05_scripts_R/00_master.R'); lance_pipeline(1, 26).
