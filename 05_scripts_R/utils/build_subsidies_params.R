# build_subsidies_params.R
# Construit le classeur versionne des paramètres de l'étape 20.

if (!requireNamespace("openxlsx", quietly = TRUE)) {
  stop("Le package openxlsx est requis.")
}

root <- getwd()
out <- file.path(root, "01_data_sources", "params_subsidies_2021.xlsx")

electricity <- data.frame(
  parametre = c(
    "subvention_exploitation_2021",
    "part_abonnes_tarif_social",
    "part_consommation_tarif_social",
    "tarif_moyen_social_ht",
    "tarif_moyen_general_ht",
    "periodes_facturation_annuelles"
  ),
  valeur = c(8.69e9, 0.30, 0.1012, 51, 70, 6),
  unite = c("FCFA", "proportion", "proportion", "FCFA/kWh",
            "FCFA/kWh", "bimestres"),
  scenario = c("central", "central", "diagnostic", "central", "central",
               "central"),
  source_id = c("ANARE2021", "ANARE2021", "ANARE2021", "ANARE2021",
                "ANARE2021", "ANARE2021"),
  page = c("46", "111", "annexe 14, p. 141", "106-107", "106-107", "104"),
  commentaire = c(
    "Subvention d'exploitation versée au secteur électrique en 2021.",
    "Le rapport indique environ 30 % d'abonnés sociaux en 2019; cette part sert à identifier le groupe bénéficiaire dans l'enquête.",
    "Part de la consommation associée au tarif social dans l'annexe graphique.",
    "Tarif moyen hors taxes simulé pour un client social basse tension.",
    "Tarif moyen hors taxes simulé pour un client domestique général basse tension.",
    "La basse tension est facturée tous les deux mois."
  ),
  stringsAsFactors = FALSE
)

water_tariffs <- data.frame(
  tranche = c("sociale", "domestique", "normale", "industrielle"),
  borne_basse_m3_trimestre = c(0, 18, 90, 300),
  borne_haute_m3_trimestre = c(18, 90, 300, Inf),
  tarif_ttc_fcfa_m3 = c(235, 367.3, 586.8, 786.3),
  tarif_reference_fcfa_m3 = c(367.3, 367.3, 367.3, 367.3),
  scenario = c("central", "central", "central", "robustesse"),
  source_id = c("SODECI2021", "SODECI2021", "SODECI2021", "EAU2014"),
  commentaire = c(
    "Les 18 premiers m3 trimestriels bénéficient du tarif social.",
    "Le tarif domestique sert de référence pour mesurer la réduction de prix de la première tranche.",
    "Tarif de la tranche normale.",
    "Valeur de robustesse issue de la grille détaillée antérieure; elle n'affecte presque aucun ménage de l'enquête."
  ),
  stringsAsFactors = FALSE
)

fuel <- data.frame(
  produit = c("super", "gasoil", "super", "gasoil"),
  scenario = c("central", "central", "borne_haute_non_2021",
               "borne_haute_non_2021"),
  prix_pompe_fcfa_litre = c(615, 615, 615, 615),
  prix_sans_soutien_fcfa_litre = c(615, 615, 695, 695),
  ecart_fcfa_litre = c(0, 0, 80, 80),
  source_id = c("DGH2021", "DGH2021", "BCEAO2023", "BCEAO2023"),
  commentaire = c(
    "Aucune série 2021 de prix de parité auditable ne permet d'isoler un soutien: le scénario central n'impute aucun bénéfice.",
    "Aucune série 2021 de prix de parité auditable ne permet d'isoler un soutien: le scénario central n'impute aucun bénéfice.",
    "Borne illustrative fondée sur la structure régionale publiée pour 2022; elle n'est jamais mélangée au résultat central.",
    "Borne illustrative fondée sur la structure régionale publiée pour 2022; elle n'est jamais mélangée au résultat central."
  ),
  stringsAsFactors = FALSE
)

method <- data.frame(
  parametre = c(
    "part_sociale_basse", "part_sociale_haute",
    "marge_revendeur_eau_basse", "marge_revendeur_eau_haute",
    "bootstrap_reps", "bootstrap_seed"
  ),
  valeur = c(0.20, 0.40, 0, 0.20, 500, 20260920),
  unite = c("proportion", "proportion", "proportion de la dépense",
            "proportion de la dépense", "réplications", "entier"),
  commentaire = c(
    "Robustesse: les 20 % d'abonnés aux factures les plus faibles sont considérés sociaux.",
    "Robustesse: les 40 % d'abonnés aux factures les plus faibles sont considérés sociaux.",
    "Le revendeur d'eau n'est pas valorisé dans le scénario central.",
    "Borne haute: 20 % de la dépense au revendeur représente une réduction de prix implicite.",
    "Bootstrap de sondage Rao-Wu.",
    "Graine reproductible."
  ),
  stringsAsFactors = FALSE
)

sources <- data.frame(
  source_id = c("ANARE2021", "SODECI2021", "EAU2014", "DGH2021",
                "BCEAO2023"),
  organisme = c(
    "ANARE-CI",
    "SODECI, cité dans une étude contemporaine",
    "ONEP, grille détaillée actualisée en 2014",
    "Direction générale des hydrocarbures",
    "BCEAO"
  ),
  titre = c(
    "Rapport d'activités 2021",
    "Tarification domestique de l'eau du service public ivoirien",
    "Structure tarifaire de l'eau potable en milieu urbain",
    "Prix maxima des produits pétroliers en 2021",
    "Degré de transmission des prix internationaux dans l'UEMOA"
  ),
  annee = c(2021, 2021, 2014, 2021, 2023),
  url = c(
    "https://anare.ci/wp-content/uploads/2022/11/RAPPORT-DACTIVITE-ANARE-CI-2021.pdf",
    "https://fr.scribd.com/document/935432127/TAP-IJHSSI-2021",
    "https://labo.univ-oran2.dz/VRPG2/laboratoires/egeat/images/egeat/revue/CGO_Numero_14_et_15/articles/CGO14-15_Article_2_3.pdf",
    "https://www.fratmat.info/article/215870/economie/carburant-les-prix-de-lessence-super-sans-plomb-et-du-gasoil-restent-inchanges",
    "https://www.bceao.int/sites/default/files/2023-08/Etude%20-%20Degr%C3%A9%20de%20transmission%20des%20prix%20internationaux%20dans%20l%27UEMOA.pdf"
  ),
  fichier_archive = c(
    "reference_external/ANARE_CI_rapport_activite_2021.pdf",
    NA,
    NA,
    NA,
    "reference_external/BCEAO_transmission_prix_UEMOA_2023.pdf"
  ),
  date_acces = rep("2026-07-19", 5),
  stringsAsFactors = FALSE
)

openxlsx::write.xlsx(
  list(
    electricite = electricity,
    eau = water_tariffs,
    carburants = fuel,
    methode = method,
    sources = sources
  ),
  file = out,
  overwrite = TRUE
)
message("Classeur créé : ", out)