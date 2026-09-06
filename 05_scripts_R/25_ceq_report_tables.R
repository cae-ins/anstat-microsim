# 25_ceq_report_tables.R
# Rassemble les résultats validés, les contrôles macroéconomiques ANSTAT, le
# dictionnaire et le manifeste de réplication. Aucun paramètre économique nouveau.

ceq_report_tables <- function(paths) {
  message(">>> ETAPE 26 : Tables CEQ finales et manifeste de réplication")
  f_income <- file.path(paths$SILVER, "22", "all_income_concepts.parquet")
  f_shapley <- file.path(paths$SILVER, "23", "marginal_contributions.parquet")
  f_fi <- file.path(paths$SILVER, "24", "fiscal_impoverishment.parquet")
  f_transfer <- file.path(paths$SILVER, "18", "transfers.parquet")
  f_pmt <- file.path(paths$TABLES, "18", "18_02_coverage_targeting.xlsx")
  f_sub <- file.path(paths$SILVER, "19", "subsidies.parquet")
  f_other <- file.path(paths$SILVER, "17", "indirect_other.parquet")
  f_reform <- file.path(paths$SILVER, "15", "reform_vat_hh.parquet")
  invisible(lapply(
    c(f_income, f_shapley, f_fi, f_transfer, f_pmt, f_sub, f_other, f_reform),
    assert_local_file_exists
  ))
  hh <- load_parquet(f_income); shapley <- load_parquet(f_shapley)
  fi_hh <- load_parquet(f_fi); tr <- load_parquet(f_transfer)
  reform <- load_parquet(f_reform) |>
    dplyr::filter(scenario == "S_all", hypothese == "S3") |>
    dplyr::left_join(
      tr |> dplyr::select(hhid, pssn_selected), by = "hhid"
    )

  concept_vars <- c("yp_pc_pdi", "yn_pc_pdi", "yg_pc_pdi", "yd_pc", "yc_pc", "yf_pc")
  concept_labels <- c("Revenu primaire", "Revenu net de marché", "Revenu brut",
                      "Revenu disponible", "Revenu consommable", "Revenu final")
  concepts_decile <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(concept_vars),
      ~ stats::weighted.mean(.x, pcweight)), .groups = "drop") |>
    tidyr::pivot_longer(-decile, names_to = "variable", values_to = "fcfa_par_personne") |>
    dplyr::mutate(concept = factor(variable, levels = concept_vars, labels = concept_labels),
      scenario = "Central, pensions comme revenu différé", unite = "FCFA 2021 par personne et par an") |>
    dplyr::select(scenario, decile, concept, variable, fcfa_par_personne, unite)
  concepts_national <- purrr::map2_dfr(concept_vars, concept_labels, function(v, lab) {
    tibble::tibble(scenario = "Central, pensions comme revenu différé", concept = lab,
      variable = v, moyenne = stats::weighted.mean(hh[[v]], hh$pcweight),
      gini = weighted_gini(pmax(hh[[v]], 0), hh$pcweight),
      pauvrete_fgt0 = stats::weighted.mean(hh[[v]] < hh$zref, hh$pcweight),
      pauvrete_fgt1 = fgt_index(hh[[v]], hh$zref, hh$pcweight, 1),
      unite = "FCFA 2021 par personne et par an")
  })
  instruments_decile <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      prelevements_directs = sum(direct_levies_pdi_hh_real * hhweight) / 1e9,
      paiements_publics_directs = sum(public_transfers_hh_real * hhweight) / 1e9,
      impots_indirects = sum(indirect_taxes_hh_real * hhweight) / 1e9,
      reductions_prix = sum(subsidy_total_hh_real * hhweight) / 1e9,
      education_nette = sum(education_net_hh_real * hhweight) / 1e9,
      sante_nette = sum(health_net_hh_real * hhweight) / 1e9, .groups = "drop") |>
    dplyr::mutate(scenario = "Central", unite = "milliards de FCFA 2021", .before = 1)

  fi_summary <- function(pre, post, label) {
    loss <- pmax(pmin(pre, hh$zref) - pmin(post, hh$zref), 0)
    gain <- pmax(pmin(post, hh$zref) - pmin(pre, hh$zref), 0)
    tibble::tibble(scenario = label,
      part_population_appauvrie = stats::weighted.mean(post < pre & post < hh$zref, hh$pcweight),
      part_nouveaux_pauvres = stats::weighted.mean(pre >= hh$zref & post < hh$zref, hh$pcweight),
      perte_milliards = sum(loss * hh$pcweight) / 1e9,
      gain_milliards = sum(gain * hh$pcweight) / 1e9,
      fgt1_avant = fgt_index(pre, hh$zref, hh$pcweight, 1),
      fgt1_apres = fgt_index(post, hh$zref, hh$pcweight, 1))
  }
  fiscal_poverty <- dplyr::bind_rows(
    fi_summary(hh$yp_pc_pdi, hh$yc_pc, "PDI"),
    fi_summary(hh$yp_pc_pgt, hh$yc_pc, "PGT"))

  reform_population <- sum(reform$pcweight)
  reform_revenue <- reform$transfert_pc_nominal[[1]] * reform_population
  selected_households <- sum(reform$hhweight * reform$pssn_selected)
  if (!is.finite(selected_households) || selected_households <= 0) {
    stop("Aucun ménage PMT disponible pour la robustesse de recyclage.")
  }
  universal_pc <- reform_revenue / reform_population
  targeted_hh <- reform_revenue / selected_households
  reform_welfare <- list(
    "Sans recyclage" = reform$yd_pc_sans_recyclage,
    "Transfert universel, budget intégral" =
      reform$yd_pc_sans_recyclage + universal_pc * reform$def_spa,
    "Transfert universel, 10 % de coût de distribution" =
      reform$yd_pc_sans_recyclage + 0.9 * universal_pc * reform$def_spa,
    "Registre PMT du PSSN, budget intégral" =
      reform$yd_pc_sans_recyclage + reform$pssn_selected *
        targeted_hh * reform$def_spa / reform$hhsize,
    "Registre PMT du PSSN, 10 % de coût de distribution" =
      reform$yd_pc_sans_recyclage + reform$pssn_selected *
        0.9 * targeted_hh * reform$def_spa / reform$hhsize
  )
  reform_delivery <- purrr::imap_dfr(reform_welfare, function(welfare, scenario) {
    tibble::tibble(
      scenario = scenario,
      assiette_reforme = "Tous les produits admissibles initialement à taux nul",
      transmission = "S3, fonction de consommation et décile",
      part_recette_recyclee = dplyr::case_when(
        scenario == "Sans recyclage" ~ 0,
        grepl("10 %", scenario) ~ 0.9,
        TRUE ~ 1
      ),
      taux_pauvrete = stats::weighted.mean(welfare < reform$zref, reform$pcweight),
      gini = weighted_gini(pmax(welfare, 0), reform$pcweight),
      gain_moyen_fcfa_personne = stats::weighted.mean(
        welfare - reform$yd_pc_sans_recyclage, reform$pcweight
      ),
      recette_milliards_fcfa = reform_revenue / 1e9
    )
  })

  # Les références macro servent de contrôle de périmètre, jamais de cible de
  # calage. Les comptes ANStat couvrent toute l'économie; le modèle ne couvre
  # que les charges et services attribuables aux ménages de l'enquête.
  sub <- load_parquet(f_sub)
  oth <- load_parquet(f_other)
  nominal <- function(x) x / hh$def_spa
  electricity_nominal <- sum(
    (sub$subsidy_electricity_hh_real / sub$def_spa) * sub$hhweight
  ) / 1e9
  excise_nominal <- sum(
    (oth$excise_hh_real / oth$def_spa) * oth$hhweight
  ) / 1e9
  customs_nominal <- sum(
    (oth$custom_duty_hh_real / oth$def_spa) * oth$hhweight
  ) / 1e9

  macro <- tibble::tibble(
    agregat = c(
      "Consommation des ménages",
      "TVA supportée par les ménages",
      "Accises supportées par les ménages",
      "Droits de douane supportés par les ménages",
      "Impôts indirects nets des réductions de prix",
      "Réduction de prix de l'électricité",
      "Services d'éducation attribués",
      "Services de santé attribués",
      "Paiements publics directs aux ménages"
    ),
    simulation_2021_milliards = c(
      sum(nominal(hh$yd_hh) * hh$hhweight) / 1e9,
      sum(nominal(hh$vat_total_local_s3_real) * hh$hhweight) / 1e9,
      excise_nominal,
      customs_nominal,
      sum(nominal(
        hh$indirect_taxes_hh_real - hh$subsidy_total_hh_real
      ) * hh$hhweight) / 1e9,
      electricity_nominal,
      sum(nominal(hh$education_gross_hh_real) * hh$hhweight) / 1e9,
      sum(nominal(hh$health_gross_hh_real) * hh$hhweight) / 1e9,
      sum(
        (tr$public_transfers_hh_real / tr$def_spa) * tr$hhweight
      ) / 1e9
    ),
    reference_2021_milliards = c(
      26754, 1116.6, 292.909156164, 555.106823047, 3074,
      57.5, 2971, 743, 906.8
    ),
    reference_2022_milliards = c(
      29510, 1287.5, NA_real_, NA_real_, 3276,
      24.7, 3163, 840, 767.7
    ),
    reference_2023_milliards = c(
      34059, 1531.64, NA_real_, NA_real_, 4431,
      23.99, 3494, 980, 695.20
    ),
    reference = c(
      "Consommation finale des ménages",
      "TVA DGI plus TVA DGD",
      "Accises intérieures, à l'importation et taxe sur les carburants",
      "Droits de douane, hors redevance statistique et hors TVA",
      "Droits et taxes sur produits nets de subventions",
      "Subvention au secteur électrique, dont gaz imputé",
      "Valeur ajoutée de la branche enseignement",
      "Valeur ajoutée santé humaine et action sociale",
      "Subventions et autres transferts du TOFE"
    ),
    comparabilite = c(
      "Enquête auprès des ménages contre agrégat exhaustif des comptes nationaux.",
      "Ménages seulement contre recouvrement de TVA de tous les agents; la TVA non déductible des entreprises n'est pas une consommation des ménages.",
      "Produits identifiables dans l'enquête et achats des ménages contre recettes perçues sur toutes les ventes et importations.",
      "Achats des ménages contre droits acquittés par tous les importateurs.",
      "Ménages et instruments modélisés contre ensemble de l'économie et montant net des subventions.",
      "Le calcul central utilise 8,69 milliards d'aide d'exploitation ANARE; le TOFE inclut notamment du gaz imputé.",
      "Budget public distribuable contre valeur ajoutée publique et privée de toute la branche.",
      "Budget public de soins et intrants contre valeur ajoutée publique et privée de toute la branche.",
      "Paiements monétaires identifiables aux ménages contre ensemble des subventions et transferts publics."
    ),
    source = c(
      "ANStat, Comptes nationaux annuels définitifs 2023",
      "ANStat, Annuaire des statistiques économiques 2023",
      "Loi de règlement 2021, rapport de présentation",
      "Loi de règlement 2021, rapport de présentation",
      "ANStat, Comptes nationaux annuels définitifs 2023",
      "ANStat, Annuaire des statistiques économiques 2023",
      "ANStat, Comptes nationaux annuels définitifs 2023",
      "ANStat, Comptes nationaux annuels définitifs 2023",
      "ANStat, Annuaire des statistiques économiques 2023"
    )
  ) |>
    dplyr::mutate(
      ratio_simulation_reference_2021_pct =
        100 * simulation_2021_milliards / reference_2021_milliards
    )
  pmt_calage <- readxl::read_excel(f_pmt, sheet = "pssn")
  pmt_coefficients <- readxl::read_excel(f_pmt, sheet = "coefficients_pmt")
  pmt_variables <- tibble::tibble(
    variable = c("log(taille du ménage)", "milieu", "région", "âge du chef",
      "âge du chef au carré", "chef femme", "éducation du chef", "chef marié",
      "nombre de 0-5 ans", "nombre de 6-10 ans", "nombre de 11-15 ans",
      "nombre de 65 ans ou plus", "nombre de personnes handicapées"),
    source_enquete = c("Fichier ménage EHCVM", "Fichier ménage EHCVM", "Fichier ménage EHCVM",
      rep("Fichier individus EHCVM, caractéristiques du chef", 5),
      rep("Fichier individus EHCVM, composition du ménage", 5)),
    role = c("Échelle et économies de taille", "Écart urbain-rural", "Écarts géographiques",
      "Cycle de vie", "Non-linéarité du cycle de vie", "Caractéristique du chef",
      "Capital scolaire du chef", "Situation familiale du chef",
      "Jeunes enfants", "Enfants d'âge scolaire", "Adolescents",
      "Personnes âgées", "Handicap déclaré"))

  dictionary <- tibble::tibble(
    terme = c("PDI", "PGT", "TVA non déductible", "PMT", "calage",
      "revenu primaire", "revenu disponible", "revenu consommable", "revenu final",
      "bénéfice en nature", "appauvrissement fiscal"),
    definition = c(
      "Convention où les pensions contributives sont un revenu différé et les cotisations retraite une épargne.",
      "Convention alternative où les pensions sont des paiements publics et les cotisations retraite des prélèvements.",
      "TVA restant dans le coût d'un bien ou service parce qu'elle n'est récupérée par aucune entreprise; elle peut atteindre indirectement le prix payé par le ménage.",
      "Test indirect de niveau de vie qui classe les ménages à partir de caractéristiques observables.",
      "Ajustement des poids, effectifs ou montants simulés pour retrouver une référence administrative explicitement documentée.",
      "Ressources avant prélèvements directs et paiements publics.",
      "Ressources monétaires après prélèvements directs et paiements publics.",
      "Revenu disponible moins impôts indirects, plus réductions publiques de prix.",
      "Revenu consommable augmenté des services publics d'éducation et de santé valorisés au coût de production.",
      "Coût public moyen attribué à un utilisateur, net des paiements directs quand le résultat est présenté net.",
      "Perte de ressources sous le seuil de pauvreté provoquée par le système fiscal et les paiements monétaires."))

  workbook <- list(
    concepts_nationaux = as.data.frame(concepts_national),
    concepts_deciles = as.data.frame(concepts_decile),
    instruments_deciles = as.data.frame(instruments_decile),
    shapley = as.data.frame(shapley),
    pauvrete_fiscale = as.data.frame(fiscal_poverty),
    controle_macro_ANSTAT = as.data.frame(macro),
    PMT_variables = as.data.frame(pmt_variables),
    PMT_calage = as.data.frame(pmt_calage),
    PMT_coefficients = as.data.frame(pmt_coefficients),
    reforme_modalites_recyclage = as.data.frame(reform_delivery),
    dictionnaire = as.data.frame(dictionary))
  out_dir <- file.path(paths$TABLES, "25"); dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_xlsx <- file.path(out_dir, "CEQ_CIV_2021_master.xlsx")
  openxlsx::write.xlsx(workbook, out_xlsx, overwrite = TRUE)
  export_excel(
    reform_delivery,
    file.path(out_dir, "25_02_reform_delivery_sensitivity.xlsx")
  )

  manifest_files <- unique(c(unname(c(
    f_income, f_shapley, f_fi, f_transfer, f_sub, f_other, f_reform
  )),
    file.path(paths$ROOT, "01_data_sources", c(
      "params_indirect_other_2021.xlsx", "params_transfers_2021.xlsx",
      "params_subsidies_2021.xlsx", "params_education_2021.xlsx",
      "params_health_2021.xlsx"
    )),
    file.path(paths$ROOT, "01_data_sources", "reference_external", c(
      "ANSTAT_CNA_definitifs_2023.pdf", "ANSTAT_annuaire_statistiques_economiques_2023.pdf"))))
  manifest_files <- manifest_files[file.exists(manifest_files)]
  info <- file.info(manifest_files)
  git_hash <- tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE),
                       error = function(e) NA_character_)
  manifest <- tibble::tibble(
    fichier = normalizePath(manifest_files, winslash = "/", mustWork = TRUE),
    taille_octets = info$size, modification = format(info$mtime, "%Y-%m-%dT%H:%M:%S%z"),
    md5 = unname(tools::md5sum(manifest_files)), git_revision = git_hash[[1]],
    version_R = R.version.string, construit_le = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
  utils::write.csv(manifest, file.path(out_dir, "CEQ_CIV_2021_manifest.csv"), row.names = FALSE,
                   fileEncoding = "UTF-8")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Le package jsonlite est requis.")
  jsonlite::write_json(manifest, file.path(out_dir, "CEQ_CIV_2021_manifest.json"),
                       pretty = TRUE, dataframe = "rows", na = "null")

  gen_dir <- file.path(paths$ROOT, "00_documentation", "working_paper", "generated")
  dir.create(gen_dir, recursive = TRUE, showWarnings = FALSE)
  # Les macros injectees dans le manuscrit portent la virgule decimale, sinon
  # elles jureraient avec le reste du texte francais.
  fr <- function(x, chiffres) sub(".", ",", sprintf(paste0("%.", chiffres, "f"), x),
                                  fixed = TRUE)
  gini_de <- function(v) concepts_national$gini[concepts_national$variable == v]
  pauvrete_de <- function(v) {
    100 * concepts_national$pauvrete_fgt0[concepts_national$variable == v]
  }
  macro <- function(nom, valeur) sprintf("\\newcommand{\\%s}{%s}", nom, valeur)
  summary_tex <- c(
    "% Généré automatiquement par 25_ceq_report_tables.R — ne pas éditer à la main.",
    "% Injecté dans DT_CEQ_CIV2021.tex par \\input{generated/ceq_summary_values}.",
    macro("GiniPrimaire", fr(gini_de("yp_pc_pdi"), 4)),
    macro("GiniNetMarche", fr(gini_de("yn_pc_pdi"), 4)),
    macro("GiniBrut", fr(gini_de("yg_pc_pdi"), 4)),
    macro("GiniDisponible", fr(gini_de("yd_pc"), 4)),
    macro("GiniConsommable", fr(gini_de("yc_pc"), 4)),
    macro("GiniFinal", fr(gini_de("yf_pc"), 4)),
    macro("PauvretePrimaire", paste0(fr(pauvrete_de("yp_pc_pdi"), 2), "~\\%")),
    macro("PauvreteNetMarche", paste0(fr(pauvrete_de("yn_pc_pdi"), 2), "~\\%")),
    macro("PauvreteBrut", paste0(fr(pauvrete_de("yg_pc_pdi"), 2), "~\\%")),
    macro("PauvreteDisponible", paste0(fr(pauvrete_de("yd_pc"), 2), "~\\%")),
    macro("PauvreteConsommable", paste0(fr(pauvrete_de("yc_pc"), 2), "~\\%")),
    macro("PauvreteFinale", paste0(fr(pauvrete_de("yf_pc"), 2), "~\\%")),
    macro("ReductionGini", fr(gini_de("yp_pc_pdi") - gini_de("yf_pc"), 5)),
    macro("PartAppauvrie", paste0(fr(
      100 * fiscal_poverty$part_population_appauvrie[fiscal_poverty$scenario == "PDI"], 2), "~\\%")),
    macro("PartNouveauxPauvres", paste0(fr(
      100 * fiscal_poverty$part_nouveaux_pauvres[fiscal_poverty$scenario == "PDI"], 2), "~\\%")))
  writeLines(summary_tex, file.path(gen_dir, "ceq_summary_values.tex"), useBytes = TRUE)

  if (any(abs(shapley$variation_totale - sum(shapley$contribution_gini)) > 1e-8)) {
    stop("La décomposition de Shapley ne se réconcilie pas.")
  }
  message("  Classeur final : ", out_xlsx)
  message("  Contrôle ANSTAT : 2021 central, 2022-2023 en comparaison temporelle")
  invisible(workbook)
}