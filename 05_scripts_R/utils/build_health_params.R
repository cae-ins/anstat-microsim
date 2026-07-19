# Construit les paramètres budgétaires et les variantes de l'étape 22.
if (!requireNamespace("openxlsx", quietly = TRUE)) stop("Le package openxlsx est requis.")
root <- getwd(); out <- file.path(root, "01_data_sources", "params_health_2021.xlsx")

budget <- data.frame(
  parametre = c("budget_soins_intrants_central", "budget_programme_sante_total"),
  valeur = c(108527426081, 141737335727), unite = "FCFA",
  scenario = c("central", "robustesse_large"),
  source = "Rapport annuel de performance 2021, programme santé",
  pages = c("actions médicaments/intrants et prise en charge", "programme 2 total"),
  explication = c(
    "Somme des actions médicaments et intrants (16,940 milliards) et prise en charge médicale (91,588 milliards).",
    "Inclut aussi pilotage et infrastructure; publié comme borne large et non comme résultat central."
  ), stringsAsFactors = FALSE
)

methode <- data.frame(
  parametre = c("annualisation_consultation_30_jours", "annualisation_depenses_3_mois",
                "poids_hospitalisation_central", "poids_hospitalisation_bas",
                "poids_hospitalisation_haut", "taille_cellule_min",
                "bootstrap_reps", "bootstrap_seed"),
  valeur = c(12, 4, 10, 5, 20, 30, 500, 20240922),
  unite = c("facteur", "facteur", "unités de consultation", "unités de consultation",
            "unités de consultation", "observations", "réplications", "entier"),
  explication = c(
    "Un épisode de consultation déclaré sur 30 jours est annualisé par douze.",
    "Les paiements de soins déclarés sur trois mois sont annualisés par quatre.",
    "Une hospitalisation utilise dix fois les ressources d'une consultation dans le calcul central.",
    "Robustesse basse de l'intensité hospitalière.", "Robustesse haute de l'intensité hospitalière.",
    "Une cellule âge-sexe-milieu plus petite est remplacée par le taux national âge-sexe.",
    "Bootstrap Rao-Wu par grappes et strates.", "Graine reproductible."
  ), stringsAsFactors = FALSE
)

sources <- data.frame(
  source_id = c("RAP2021", "EHCVM2021", "CEQ"),
  reference = c(
    "Côte d'Ivoire, Rapport annuel de performance 2021, programme santé.",
    "EHCVM 2021, module 3 : recours, prestataire et paiements; fichier individus pour âge et sexe.",
    "CEQ Handbook : méthode d'incidence des dépenses publiques en nature."
  ),
  fichier_archive = c("01_data_sources/reference_external/RAP_general_performance_2021.pdf", NA, NA),
  stringsAsFactors = FALSE
)
openxlsx::write.xlsx(list(budget=budget, methode=methode, sources=sources), out, overwrite=TRUE)
message("Créé : ", out)