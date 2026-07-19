# Construit les paramètres budgétaires de l'étape 21.
if (!requireNamespace("openxlsx", quietly = TRUE)) stop("Le package openxlsx est requis.")
root <- getwd()
out <- file.path(root, "01_data_sources", "params_education_2021.xlsx")

budgets <- data.frame(
  groupe = c("prescolaire_primaire", "secondaire_general", "secondaire_technique",
             "postsecondaire_professionnel", "superieur"),
  budget_central_fcfa = c(587505439820, 378933615854, 13052223530,
                          91770972962, 283609254144),
  budget_courant_fcfa = c(574034292284, 356458103135, 13052223530,
                          91770972962, 197972798645),
  source = rep("Rapport annuel de performance 2021 de la Côte d'Ivoire", 5),
  pages = c("559-560", "579", "programmes 2-3 METFP", "programme 2 METFP", "619 et 629"),
  definition = c(
    "Programme enseignement préscolaire et primaire du MENA.",
    "Programme enseignement secondaire général du MENA.",
    "Programme enseignement secondaire technique du METFP.",
    "Programme formation professionnelle et post-bac court du METFP.",
    "Enseignement supérieur et œuvres universitaires du MESRS."
  ), stringsAsFactors = FALSE
)

methode <- data.frame(
  parametre = c("bootstrap_reps", "bootstrap_seed", "etablissement_public_code",
                "frais_centraux_q20_q21", "frais_larges_q20_q27"),
  valeur = c(500, 20240921, 1, 1, 1),
  unite = c("réplications", "entier", "code EHCVM", "indicateur", "indicateur"),
  explication = c(
    "Bootstrap Rao-Wu tenant compte des grappes et des strates.",
    "Graine reproductible.",
    "Le code 1 de s02q19 désigne un établissement public.",
    "Le résultat central retranche les frais d'inscription et les contributions scolaires directement payés.",
    "La robustesse retranche toutes les dépenses scolaires déclarées de s02q20 à s02q27."
  ), stringsAsFactors = FALSE
)

sources <- data.frame(
  source_id = c("RAP2021", "EHCVM2021", "CEQ"),
  reference = c(
    "Côte d'Ivoire, Rapport annuel de performance 2021, ministères MENA, METFP et MESRS.",
    "EHCVM 2021, module 2 éducation : fréquentation, niveau, statut public et paiements.",
    "CEQ Handbook, méthode standard d'analyse d'incidence des dépenses publiques d'éducation."
  ),
  fichier_archive = c("01_data_sources/reference_external/RAP_general_performance_2021.pdf", NA, NA),
  stringsAsFactors = FALSE
)

openxlsx::write.xlsx(list(budgets=budgets, methode=methode, sources=sources), out, overwrite=TRUE)
message("Créé : ", out)