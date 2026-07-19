# Rebuild 01_data_sources/params_transfers_2021.xlsx from documented
# administrative parameters and CEQ modelling choices.

build_transfers_params <- function(root = getwd()) {
  if (!requireNamespace("openxlsx", quietly = TRUE) ||
      !requireNamespace("tibble", quietly = TRUE)) {
    stop("Packages openxlsx et tibble requis.", call. = FALSE)
  }

  url_ceq <- paste0(
    "https://commitmentoequity.org/wp-content/uploads/2023/04/",
    "CEQ-Handbook-Volume-1-.pdf"
  )
  url_akim <- paste0(
    "https://horizon.documentation.ird.fr/exl-doc/pleins_textes/",
    "2022-08/010085651.pdf"
  )
  url_pssn_perf <- paste0(
    "https://budget.gouv.ci/doc/loi/",
    "LFR%20Rapport%20G%C3%A9n%C3%A9ral%20sur%20la%20performance%20",
    "du%20MBPE%202021.pdf"
  )
  url_pssn_wb <- paste0(
    "https://www.worldbank.org/en/news/feature/2022/07/07/",
    "afw-cote-divoire-a-small-grant-that-changes-lives"
  )
  url_cnps_salarie <- "https://www.cnps.ci/salarie/"
  url_cnps_employeur <- "https://www.cnps.ci/employeur/"
  url_cgrae <- paste0(
    "https://budget.gouv.ci/doc/loi/",
    "03%20ANNEXE%2003%20-%20DPBEP_2022_2024%20DU%2031_12_2021.pdf"
  )
  legacy_dtr <- file.path(
    "00_documentation", "ressources_CEQ", "03. CIV21WBN_dtr.do"
  )

  programmes <- tibble::tribble(
    ~instrument, ~parametre, ~valeur, ~unite, ~statut, ~source, ~note,
    "PSSN", "menages servis", 192000, "menages", "central",
    url_pssn_perf,
    "Realisation 2021 du rapport officiel de performance.",
    "PSSN", "cohorte annee complete", 177000, "menages", "central",
    legacy_dtr,
    "Decomposition technique du portefeuille 2021; 4 paiements.",
    "PSSN", "cohorte partielle", 15000, "menages", "central",
    legacy_dtr,
    "Decomposition technique du portefeuille 2021; 3 paiements retenus.",
    "PSSN", "allocation trimestrielle", 36000, "FCFA/menage", "central",
    url_pssn_wb,
    "Montant trimestriel documente par la Banque mondiale.",
    "PSSN", "paiements cohorte complete", 4, "trimestres", "central",
    legacy_dtr, "Annee complete.",
    "PSSN", "paiements cohorte partielle", 3, "trimestres", "central",
    legacy_dtr,
    "Trois trimestres documentes dans les notes techniques; le vieux code n'en imputait qu'un.",
    "Prestations familiales", "allocation enfant mensuelle", 5000,
    "FCFA/enfant", "central", url_cnps_salarie,
    "Bareme CNPS; remplace le montant obsolete de 1 666,66 FCFA du do-file.",
    "Prestations familiales", "allocation prenatale totale", 13500,
    "FCFA/grossesse", "central", url_cnps_salarie,
    "Proxy par naissance observee.",
    "Prestations familiales", "allocation naissance", 18000,
    "FCFA/naissance", "central", url_cnps_salarie,
    "Limitee aux trois premieres naissances par le proxy de composition familiale.",
    "Prestations familiales", "allocation maternite totale", 18000,
    "FCFA/enfant", "central", url_cnps_salarie,
    "Proxy par enfant age d'un an, suivant le fichier technique CEQ.",
    "Accidents du travail", "depenses annuelles", 8275831514,
    "FCFA", "central", legacy_dtr,
    "Reference technique CEQ; depense annuelle moyenne repartie entre travailleurs presumes couverts.",
    "Pensions", "prestations CGRAE", 180900000000,
    "FCFA", "validation", url_cgrae,
    "Champ agents publics; comparaison partielle avec les pensions EHCVM.",
    "Bourses", "montant administratif", NA_real_, "FCFA", "a_documenter",
    "EHCVM S02 et budgets Education",
    "Le montant declare est central; pas de calage sans reference administrative de champ equivalent."
  )

  classification_s15 <- tibble::tribble(
    ~code, ~libelle, ~nature_ceq, ~paiement_public_monetaire, ~traitement,
    1L, "Don de cereales", "en_nature", FALSE, "diagnostic etape 21-22/extension",
    2L, "Don de farines de cereales", "en_nature", FALSE, "diagnostic etape 21-22/extension",
    3L, "Nourriture scolaire", "en_nature", FALSE, "education en nature",
    4L, "Nourriture contre travail", "travail_plus_nature", FALSE, "hors transfert cash faute de montant",
    5L, "Supplement alimentaire", "en_nature", FALSE, "sante/nutrition en nature",
    6L, "Travaux HIMO", "revenu_du_travail", FALSE, "non ajoute aux paiements publics: la remuneration ne peut pas etre isolee",
    7L, "Transfert cash gouvernement/ONG", "cash", TRUE, "diagnostic PSSN observe; montant impute par PMT",
    8L, "Prise en charge femmes enceintes", "en_nature", FALSE, "sante en nature",
    9L, "Soins enfants de moins de 5 ans", "en_nature", FALSE, "sante en nature",
    10L, "Soutien COVID-19", "cash_probable", FALSE, "sensibilite seulement; montant 2021 non identifiable",
    11L, "Moustiquaire impregnee", "en_nature", FALSE, "sante en nature",
    12L, "Programme non libelle 12", "inconnu", FALSE, "diagnostic uniquement",
    13L, "Programme non libelle 13", "inconnu", FALSE, "diagnostic uniquement",
    14L, "Programme non libelle 14", "inconnu", FALSE, "diagnostic uniquement"
  )

  pension_refs <- tibble::tribble(
    ~scenario, ~pension_recues, ~cotisations_retraite, ~convention, ~source,
    "PDI central", "revenu acquis avant intervention publique", "epargne obligatoire", "pensions deja comprises dans les ressources initiales", url_ceq,
    "PGT robustesse", "paiement public", "prelevement obligatoire", "pensions ajoutees aux paiements publics et cotisations retraite ajoutees aux prelevements", url_ceq
  )

  macro_refs <- tibble::tribble(
    ~agregat, ~reference_2021, ~unite, ~comparabilite, ~source,
    "Menages PSSN servis", 192000, "menages",
    "Cible de calage de couverture active, pas cumul historique.", url_pssn_perf,
    "Masse PSSN centrale", 27108000000, "FCFA",
    "177 000 x 4 x 36 000 + 15 000 x 3 x 36 000.", paste(url_pssn_perf, url_pssn_wb, sep = " ; "),
    "Masse PSSN tous servis toute l'annee", 27648000000, "FCFA",
    "Borne haute 192 000 x 4 x 36 000.", paste(url_pssn_perf, url_pssn_wb, sep = " ; "),
    "Depenses accidents du travail", 8275831514, "FCFA",
    "Reference technique, non validation administrative independante.", legacy_dtr,
    "Prestations CGRAE", 180900000000, "FCFA",
    "Public uniquement; la pension enquete inclut d'autres regimes.", url_cgrae
  )

  methode <- tibble::tribble(
    ~parametre, ~valeur, ~source,
    "annee", "2021", "EHCVM 2021",
    "pensions centrales", "PDI - pensions comme revenu differe", url_ceq,
    "pensions robustesse", "PGT - pensions comme transferts", url_ceq,
    "PSSN", "PMT deterministe, 192 000 menages, calage de masse", url_pssn_perf,
    "bourses", "identification directe S02, secondaire general ou superieur public", legacy_dtr,
    "prestations familiales", "eligibilite statutaire simulee sur couverture declaree", url_cnps_salarie,
    "accidents du travail", "depense annuelle moyenne repartie entre travailleurs presumes couverts", legacy_dtr,
    "transferts prives", "presentes separement car il s'agit de transferts entre menages", url_ceq,
    "comparateur regional", "identification directe si montant enquete; sinon imputation et calage", url_akim,
    "cotisations employeur famille", "5% plus 0,75% maternite; diagnostic seulement", url_cnps_employeur
  )

  output <- file.path(root, "01_data_sources", "params_transfers_2021.xlsx")
  openxlsx::write.xlsx(
    list(
      programmes = as.data.frame(programmes),
      classification_s15 = as.data.frame(classification_s15),
      pension_refs = as.data.frame(pension_refs),
      macro_refs = as.data.frame(macro_refs),
      methode = as.data.frame(methode)
    ),
    file = output,
    overwrite = TRUE
  )
  message("Parametres ecrits: ", output)
  invisible(output)
}
