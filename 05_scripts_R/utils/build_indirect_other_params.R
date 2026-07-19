# Rebuild 01_data_sources/params_indirect_other_2021.xlsx from documented
# statutory parameters and the CEQ Côte d'Ivoire item mappings.

build_indirect_other_params <- function(root = getwd()) {
  if (!requireNamespace("openxlsx", quietly = TRUE) ||
      !requireNamespace("readr", quietly = TRUE) ||
      !requireNamespace("dplyr", quietly = TRUE) ||
      !requireNamespace("tibble", quietly = TRUE)) {
    stop("Packages openxlsx, readr, dplyr et tibble requis.", call. = FALSE)
  }
  source(file.path(root, "05_scripts_R", "utils", "tre_mapping.R"))

  url_annexe <- paste0(
    "https://cotedivoirepaie.ci/wp-content/uploads/2022/02/",
    "Annexe_fiscale_2021.pdf"
  )
  url_dgi <- paste0(
    "https://www.dgi.gouv.ci/assets/documents/",
    "IMPOTS%20ET%20TAXES%20EN%20COTE%20D%27IVOIRE%20.pdf"
  )
  url_fuel <- paste0(
    "https://apisite.dgh.ci/Files/Annuaire_des_Statistiques_des_",
    "Hydrocarbures_en_C%C3%B4te_d%27Ivoire/62e8fecf09bad.pdf"
  )
  url_tec <- "https://apps.douanes.ci/info/tec"
  url_budget <- paste0(
    "https://budget.gouv.ci/doc/loi/",
    "LFR%20Loi%20de%20Reglement%202021-%20RAPPORT%20DE%20PRESENTATION.pdf"
  )
  wb_excise <- file.path(
    "00_documentation", "ressources_CEQ", "05. CIV21WBN_excise.do"
  )

  fuel_specific <- 55
  fuel_price <- 615
  fuel_vat <- 0.09
  fuel_ave <- fuel_specific / (fuel_price / (1 + fuel_vat) - fuel_specific)

  excises <- tibble::tribble(
    ~codpr, ~libelle_parametre, ~groupe, ~type_taux,
    ~taux_ad_valorem, ~taux_specifique_fcfa, ~prix_reference_fcfa,
    ~tva_prix_reference, ~taux_ad_valorem_equivalent, ~include_central,
    ~source_principale, ~source_mapping, ~note,
    160L, "Jus traditionnel", "boissons_non_alcoolisees", "ad_valorem",
    0.14, NA, NA, 0.18, 0.14, TRUE, url_dgi, wb_excise,
    "Taux légal; poste retenu par le do-file CEQ.",
    162L, "Boissons gazeuses", "boissons_non_alcoolisees", "ad_valorem",
    0.14, NA, NA, 0.18, 0.14, TRUE, url_dgi, wb_excise,
    "Taux légal; poste retenu par le do-file CEQ.",
    163L, "Jus en poudre", "boissons_non_alcoolisees", "ad_valorem",
    0.14, NA, NA, 0.18, 0.14, TRUE, url_dgi, wb_excise,
    "Taux légal; poste retenu par le do-file CEQ.",
    177L, "Jus manufacturé", "boissons_non_alcoolisees", "ad_valorem",
    0.14, NA, NA, 0.18, 0.14, TRUE, url_dgi, wb_excise,
    "Taux légal; poste retenu par le do-file CEQ.",
    164L, "Bières et vins traditionnels", "alcool", "ad_valorem",
    0.17, NA, NA, 0.18, 0.17, TRUE, url_dgi, wb_excise,
    "Catégorie mixte; choix prudent du taux bière du do-file CEQ.",
    165L, "Bières industrielles", "alcool", "ad_valorem",
    0.17, NA, NA, 0.18, 0.17, TRUE, url_dgi, wb_excise,
    "Taux légal des bières et cidres.",
    201L, "Cigarettes et tabacs", "tabac", "ad_valorem",
    0.46, NA, NA, 0.18, 0.46, TRUE, url_annexe, wb_excise,
    "39% + 5% sport + 2% solidarité sida/tabagisme en 2021.",
    301L, "Whisky et autres liqueurs", "alcool", "ad_valorem",
    0.45, NA, NA, 0.18, 0.45, TRUE, url_dgi, wb_excise,
    "Proxy pour alcools titrant au moins 35 degrés.",
    302L, "Vins modernes", "alcool", "ad_valorem",
    0.35, NA, NA, 0.18, 0.35, TRUE, url_dgi, wb_excise,
    "Taux légal des vins ordinaires.",
    321L, "Lait corporel et maquillage", "cosmetiques", "ad_valorem",
    0.10, NA, NA, 0.18, 0.10, TRUE, url_annexe, "Mapping EHCVM",
    "Hydroquinone non identifiable; taux général de 10%.",
    417L, "Parfum", "cosmetiques", "ad_valorem",
    0.10, NA, NA, 0.18, 0.10, TRUE, url_annexe, "Mapping EHCVM",
    "Taux général des parfums et cosmétiques.",
    202L, "Pétrole lampant", "carburants", "specific",
    0, 0, 555, 0.09, 0, TRUE, url_fuel, "Mapping EHCVM",
    "Exonéré de TSU; conservé pour diagnostic.",
    208L, "Carburant véhicule", "carburants", "specific",
    NA, fuel_specific, fuel_price, fuel_vat, fuel_ave, TRUE,
    url_fuel, "Mapping EHCVM",
    "Moyenne non pondérée super 85 et gasoil 25 FCFA/litre.",
    209L, "Carburant motocycle", "carburants", "specific",
    NA, fuel_specific, fuel_price, fuel_vat, fuel_ave, TRUE,
    url_fuel, "Mapping EHCVM",
    "Moyenne non pondérée super 85 et gasoil 25 FCFA/litre.",
    304L, "Carburant groupe électrogène", "carburants", "specific",
    NA, fuel_specific, fuel_price, fuel_vat, fuel_ave, TRUE,
    url_fuel, "Mapping EHCVM",
    "Moyenne non pondérée super 85 et gasoil 25 FCFA/litre.",
    197L, "Boisson alcoolisée hors ménage", "exclu", "ad_valorem",
    NA, NA, NA, 0.18, NA, FALSE, url_dgi, "Mapping EHCVM",
    "Service de restauration: contenu en alcool non isolable.",
    303L, "Gaz domestique", "exclu", "specific",
    NA, NA, NA, 0.09, NA, FALSE, url_fuel, "Mapping EHCVM",
    "Produit subventionné; relève du bloc C.",
    317L, "Savon de toilette et shampoing", "exclu", "ad_valorem",
    NA, NA, NA, 0.18, NA, FALSE, url_annexe, "Mapping EHCVM",
    "Catégorie mixte: le savon n'est pas isolable du shampoing.",
    626L, "Achat de voiture personnelle", "exclu", "ad_valorem",
    NA, NA, NA, 0.18, NA, FALSE, url_dgi, wb_excise,
    "Puissance fiscale de 13 CV ou plus non observable."
  )

  concordance <- readr::read_csv(
    file.path(root, "01_data_sources", "concordance_codpr_ICIO.csv"),
    show_col_types = FALSE
  ) |>
    dplyr::distinct(codpr, .keep_all = TRUE)
  customs <- concordance |>
    dplyr::select(codpr, libelle, mode_acq) |>
    dplyr::left_join(build_customs_item_mapping(root), by = "codpr") |>
    dplyr::mutate(
      mapping_zero_force = is.na(bande_tec) & codpr %in% c(205L, 331L, 630L, 653L),
      cusio_wb = dplyr::if_else(mapping_zero_force, 0L, cusio_wb),
      taux_wb_avec_rs = dplyr::if_else(mapping_zero_force, 0, taux_wb_avec_rs),
      redevance_statistique = dplyr::if_else(
        mapping_zero_force, 0, redevance_statistique
      ),
      bande_tec = dplyr::if_else(mapping_zero_force, 0, bande_tec),
      description_wb = dplyr::if_else(
        mapping_zero_force, "Hors champ marchand ou non importable", description_wb
      ),
      import_share_override = NA_real_,
      source = url_tec,
      source_mapping = file.path(
        "00_documentation", "ressources_CEQ",
        "01. CIV21WBN_presimulation_setup.do"
      ),
      note = paste0(
        "Bande TEC dérivée du taux CEQ net de la redevance statistique; ",
        "services à taux nul."
      )
    )

  macro_refs <- tibble::tribble(
    ~agregat, ~reference_2021_fcfa, ~champ, ~source,
    "Droits de douane", 555106823047,
    "Produits pétroliers et marchandises générales; poste 7171", url_budget,
    "Redevance statistique", 62018117642,
    "Hors droits de douane simulés; poste 7174", url_budget,
    "Tabacs - régime intérieur", 35544439007,
    "Poste 71521", url_budget,
    "Boissons non alcoolisées - régime intérieur", 9486195451,
    "Poste 71522", url_budget,
    "Boissons alcoolisées - régime intérieur", 29100963233,
    "Poste 71523", url_budget,
    "Alcools à l'importation", 19847700030,
    "Poste 71762", url_budget,
    "Tabacs à l'importation - taxe spéciale", 8733451021,
    "Poste 71767; hors comptes sport/sida non recouvrés dans la table", url_budget,
    "Autres accises intérieures", 10806111757,
    "Poste 71529; champ plus large que les cosmétiques des ménages", url_budget,
    "TSU produits pétroliers", 179390295665,
    "Poste 717631; inclut les usages non ménages", url_budget
  )

  method <- tibble::tribble(
    ~parametre, ~valeur,
    "année d'enquête", "2021",
    "ordre fiscal", "CAF -> droit de douane -> accise -> TVA",
    "scénario central", "répercussion intégrale",
    "sensibilité informelle", "S2/S3 sur alcool et tabac seulement",
    "marges", "TRE national 2023, prix courants",
    "part importée", "imports/(imports+production domestique), TRE 2023",
    "effets indirects Leontief", "extension non incluse dans la version 1"
  )

  output <- file.path(root, "01_data_sources", "params_indirect_other_2021.xlsx")
  openxlsx::write.xlsx(
    list(
      accises = as.data.frame(excises),
      tec_codpr = as.data.frame(customs),
      macro_refs = as.data.frame(macro_refs),
      methode = as.data.frame(method)
    ),
    file = output,
    overwrite = TRUE
  )
  message("Paramètres écrits: ", output)
  invisible(output)
}
