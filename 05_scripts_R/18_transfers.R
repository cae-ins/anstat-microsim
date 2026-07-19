# 18_transfers.R
#
# OBJECTIF :
# Construire les transferts directs publics, les filets sociaux et les
# pensions necessaires a la branche directe CEQ. Le scenario central traite
# les pensions comme revenu differe (PDI); le scenario PGT est une robustesse.
#
# ENTREES :
#   SILVER/04/fiscal_data_analysis_ready.parquet
#   SILVER/16/direct_taxes.parquet
#   modules EHCVM S02, S04, S05, S13 et S15
#   01_data_sources/params_transfers_2021.xlsx
#
# SORTIES :
#   SILVER/18/transfers.parquet
#   TABLES/18/18_01_beneficiaries_by_decile.xlsx
#   TABLES/18/18_02_coverage_targeting.xlsx
#   TABLES/18/18_03_macro_validation.xlsx
#   TABLES/18/18_04_pension_scenarios.xlsx
#   TABLES/18/18_05_ceq_identity_checks.xlsx
#   TABLES/18/18_06_progressivity_inference.xlsx
#   FIGS/fig18_transfers_decile.png

transfers <- function(paths) {

  message(">>> ETAPE 19 : Pensions, transferts directs et filets sociaux")

  fiscal_path <- file.path(
    paths$SILVER, "04", "fiscal_data_analysis_ready.parquet"
  )
  direct_path <- file.path(paths$SILVER, "16", "direct_taxes.parquet")
  params_path <- file.path(
    paths$ROOT, "01_data_sources", "params_transfers_2021.xlsx"
  )
  for (p in c(fiscal_path, direct_path, params_path)) {
    assert_local_file_exists(p)
  }

  fiscal <- load_parquet(fiscal_path)
  direct <- load_parquet(direct_path)
  params <- readxl::read_excel(params_path, sheet = "programmes")
  class_s15 <- readxl::read_excel(
    params_path, sheet = "classification_s15"
  )
  macro_refs <- readxl::read_excel(params_path, sheet = "macro_refs")
  method_params <- readxl::read_excel(params_path, sheet = "methode")

  assert_required_columns(
    fiscal,
    c(
      "hhid", "grappe", "strata", "hhweight", "pcweight", "region",
      "milieu", "decile", "quintile", "hhsize", "def_spa", "yd_pc",
      "yd_hh", "zref"
    ),
    object_name = "fiscal_data_analysis_ready.parquet"
  )
  assert_required_columns(
    direct,
    c(
      "hhid", "irpp", "cnps", "cmu", "irpp_real", "cnps_real",
      "cmu_real", "n_salaries_formels"
    ),
    object_name = "direct_taxes.parquet"
  )
  assert_required_columns(
    params,
    c("instrument", "parametre", "valeur", "unite", "source"),
    object_name = "params_transfers_2021.xlsx/programmes"
  )

  get_param <- function(instrument, parametre) {
    hit <- params |>
      dplyr::filter(
        .data$instrument == .env$instrument,
        .data$parametre == .env$parametre
      )
    if (nrow(hit) != 1L || !is.finite(as.numeric(hit$valeur[[1]]))) {
      stop(
        sprintf("Parametre absent ou ambigu: %s / %s", instrument, parametre),
        call. = FALSE
      )
    }
    as.numeric(hit$valeur[[1]])
  }

  get_macro <- function(agregat) {
    hit <- macro_refs |>
      dplyr::filter(.data$agregat == .env$agregat)
    if (nrow(hit) != 1L || !is.finite(as.numeric(hit$reference_2021[[1]]))) {
      stop(sprintf("Reference macro absente: %s", agregat), call. = FALSE)
    }
    as.numeric(hit$reference_2021[[1]])
  }

  make_hhid <- function(grappe, menage) {
    as.numeric(grappe) * 100 + as.numeric(menage)
  }

  first_valid <- function(x, default = NA_real_) {
    x <- as.numeric(x)
    x <- x[is.finite(x)]
    if (length(x) == 0L) default else x[[1]]
  }

  hh <- fiscal |>
    dplyr::select(
      hhid, grappe, strata, hhweight, pcweight, region, milieu, decile,
      quintile, hhsize, def_spa, yd_pc, yd_hh, zref
    ) |>
    dplyr::left_join(
      direct |>
        dplyr::select(
          hhid, irpp, cnps, cmu, irpp_real, cnps_real, cmu_real,
          n_salaries_formels
        ),
      by = "hhid"
    )
  if (nrow(hh) != nrow(fiscal) || anyDuplicated(hh$hhid)) {
    stop("Jointure fiscale/directe non bijective.", call. = FALSE)
  }
  if (any(!is.finite(hh$yd_pc)) || any(hh$yd_pc <= 0)) {
    stop("Le revenu disponible doit etre strictement positif.", call. = FALSE)
  }

  # -------------------------------------------------------------------------
  # 1. Demographie, scolarisation et couverture sociale
  # -------------------------------------------------------------------------
  ind <- load_raw_dta(
    "ehcvm_individu_CIV2021.dta",
    col_select = c(
      "hhid", "grappe", "menage", "numind", "sexe", "age", "lien",
      "mstat", "educ_hi", "handit", "handig", "hhweight"
    )
  )

  s02_path <- source_file_path(
    "Datain", "Menage", "s02_me_CIV2021.dta", label = "Module education S02"
  )
  s04_path <- source_file_path(
    "Datain", "Menage", "s04_me_CIV2021.dta", label = "Module emploi S04"
  )
  s05_path <- source_file_path(
    "Datain", "Menage", "s05_me_CIV2021.dta", label = "Module pensions S05"
  )
  s13_path <- source_file_path(
    "Datain", "Menage", "s13a_2_me_CIV2021.dta",
    label = "Module transferts prives S13"
  )
  s15_path <- source_file_path(
    "Datain", "Menage", "s15_me_CIV2021.dta",
    label = "Module filets sociaux S15"
  )

  s02 <- haven::read_dta(
    s02_path,
    col_select = c(
      "grappe", "menage", "individu", "s02q12", "s02q14", "s02q19",
      "s02q28"
    )
  ) |>
    dplyr::transmute(
      grappe = as.numeric(grappe),
      menage = as.numeric(menage),
      numind = as.numeric(individu),
      hhid = make_hhid(grappe, menage),
      enrolled = as.integer(s02q12) == 1L,
      school_level = as.integer(s02q14),
      public_school = as.integer(s02q19) == 1L,
      scholarship_reported = pmax(dplyr::coalesce(as.numeric(s02q28), 0), 0)
    )

  ind_aug <- ind |>
    dplyr::mutate(
      grappe = as.numeric(grappe),
      menage = as.numeric(menage),
      numind = as.numeric(numind),
      hhid = as.numeric(hhid),
      age = as.numeric(age),
      sexe = as.integer(sexe),
      lien = as.integer(lien),
      mstat = as.integer(mstat),
      educ_hi = as.integer(educ_hi),
      disabled = dplyr::coalesce(as.integer(handit) == 1L, FALSE) |
        dplyr::coalesce(as.integer(handig) == 1L, FALSE)
    ) |>
    dplyr::left_join(
      s02 |>
        dplyr::select(grappe, menage, numind, enrolled, school_level),
      by = c("grappe", "menage", "numind")
    ) |>
    dplyr::mutate(
      enrolled = dplyr::coalesce(enrolled, FALSE),
      dependent_child = lien %in% c(3L, 5L),
      eligible_child = dependent_child & (
        (age >= 2 & age < 14) |
          (age >= 14 & age < 22 & enrolled) |
          (age >= 14 & age < 22 & disabled)
      )
    )

  demog <- ind_aug |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      head_age = first_valid(age[lien == 1L]),
      head_female = first_valid(sexe[lien == 1L], default = 1) == 2,
      head_educ = first_valid(educ_hi[lien == 1L], default = 0),
      head_married = first_valid(mstat[lien == 1L], default = 0) == 2,
      n_age_0_5 = sum(age < 6, na.rm = TRUE),
      n_age_6_10 = sum(age >= 6 & age < 11, na.rm = TRUE),
      n_age_11_15 = sum(age >= 11 & age < 16, na.rm = TRUE),
      n_age_65_plus = sum(age >= 65, na.rm = TRUE),
      n_disabled = sum(disabled, na.rm = TRUE),
      n_eligible_children = sum(eligible_child, na.rm = TRUE),
      n_dependent_children = sum(dependent_child, na.rm = TRUE),
      n_newborn = sum(dependent_child & age < 1, na.rm = TRUE),
      n_one_year = sum(dependent_child & age >= 1 & age < 2, na.rm = TRUE),
      .groups = "drop"
    )

  s04_coverage <- haven::read_dta(
    s04_path,
    col_select = c(
      "grappe", "menage", "individu", "s04q32", "s04q38", "s04q40"
    )
  ) |>
    dplyr::transmute(
      hhid = make_hhid(grappe, menage),
      numind = as.numeric(individu),
      months_job = dplyr::coalesce(as.numeric(s04q32), 0),
      contributes_pension = as.integer(s04q38) == 1L,
      maternity_right = as.integer(s04q40) == 1L
    ) |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      n_covered_workers = sum(
        dplyr::coalesce(contributes_pension, FALSE) & months_job >= 3,
        na.rm = TRUE
      ),
      n_at_workers = sum(
        dplyr::coalesce(contributes_pension, FALSE) & months_job > 0,
        na.rm = TRUE
      ),
      maternity_covered = any(
        dplyr::coalesce(maternity_right, FALSE), na.rm = TRUE
      ),
      .groups = "drop"
    )

  # -------------------------------------------------------------------------
  # 2. PSSN : PMT transparent et calage sur la couverture active de 2021
  # -------------------------------------------------------------------------
  hh_pmt <- hh |>
    dplyr::left_join(demog, by = "hhid") |>
    dplyr::mutate(
      head_age = dplyr::coalesce(
        head_age, stats::median(head_age, na.rm = TRUE)
      ),
      head_female = dplyr::coalesce(head_female, FALSE),
      head_educ = dplyr::coalesce(head_educ, 0),
      head_married = dplyr::coalesce(head_married, FALSE),
      dplyr::across(
        dplyr::starts_with("n_"),
        ~ dplyr::coalesce(as.numeric(.x), 0)
      ),
      region_factor = factor(as.integer(region)),
      milieu_factor = factor(as.integer(milieu))
    )

  pmt_model <- stats::lm(
    log(yd_pc) ~ log(hhsize) + milieu_factor + region_factor +
      head_age + I(head_age^2) + head_female + head_educ + head_married +
      n_age_0_5 + n_age_6_10 + n_age_11_15 + n_age_65_plus + n_disabled,
    data = hh_pmt,
    weights = hhweight
  )
  hh_pmt$pmt_pred_pc <- exp(stats::predict(pmt_model, newdata = hh_pmt))
  if (any(!is.finite(hh_pmt$pmt_pred_pc))) {
    stop("Le score PMT contient des valeurs non finies.", call. = FALSE)
  }

  pssn_target_hh <- get_param("PSSN", "menages servis")
  pssn_full_hh <- get_param("PSSN", "cohorte annee complete")
  pssn_partial_hh <- get_param("PSSN", "cohorte partielle")
  pssn_quarterly <- get_param("PSSN", "allocation trimestrielle")
  pssn_full_payments <- get_param("PSSN", "paiements cohorte complete")
  pssn_partial_payments <- get_param("PSSN", "paiements cohorte partielle")
  pssn_target_mass <- get_macro("Masse PSSN centrale")
  pssn_all_full_mass <- get_macro("Masse PSSN tous servis toute l'annee")

  pmt_rank <- hh_pmt |>
    dplyr::arrange(pmt_pred_pc, hhid) |>
    dplyr::mutate(cum_hhweight = cumsum(hhweight), pmt_order = dplyr::row_number())
  cut_target <- which.min(abs(pmt_rank$cum_hhweight - pssn_target_hh))
  cut_full <- which.min(abs(pmt_rank$cum_hhweight - pssn_full_hh))
  pmt_rank <- pmt_rank |>
    dplyr::mutate(
      pssn_status = dplyr::case_when(
        pmt_order <= cut_full ~ "annee_complete",
        pmt_order <= cut_target ~ "cohorte_partielle",
        TRUE ~ "non_beneficiaire"
      ),
      pssn_selected = pmt_order <= cut_target,
      pssn_raw = dplyr::case_when(
        pssn_status == "annee_complete" ~
          pssn_quarterly * pssn_full_payments,
        pssn_status == "cohorte_partielle" ~
          pssn_quarterly * pssn_partial_payments,
        TRUE ~ 0
      )
    )
  pssn_raw_mass <- sum(pmt_rank$pssn_raw * pmt_rank$hhweight)
  pssn_calibration_factor <- pssn_target_mass / pssn_raw_mass
  pssn_all_full_raw_mass <- sum(
    pmt_rank$pssn_selected * pssn_quarterly * pssn_full_payments *
      pmt_rank$hhweight
  )
  pssn_all_full_factor <- pssn_all_full_mass / pssn_all_full_raw_mass
  pmt_rank <- pmt_rank |>
    dplyr::transmute(
      hhid, hhweight, yd_pc, zref, pmt_pred_pc, pmt_order, pssn_status, pssn_selected,
      pssn_hh = pssn_raw * pssn_calibration_factor,
      pssn_hh_all_full = as.numeric(pssn_selected) * pssn_quarterly *
        pssn_full_payments * pssn_all_full_factor
    )

  # S15 observe la participation, mais pas le montant monetaire.
  s15 <- haven::read_dta(
    s15_path,
    col_select = c(
      "grappe", "menage", "s15q01", "s15q03", "s15q05", "s15q09"
    )
  ) |>
    dplyr::transmute(
      hhid = make_hhid(grappe, menage),
      programme_code = as.integer(s15q01),
      applied = as.integer(s15q03) == 1L,
      benefited = as.integer(s15q05) == 1L,
      frequency = pmax(dplyr::coalesce(as.numeric(s15q09), 0), 0)
    ) |>
    dplyr::left_join(
      class_s15 |>
        dplyr::transmute(
          programme_code = as.integer(code), libelle, nature_ceq,
          paiement_public_monetaire, traitement
        ),
      by = "programme_code"
    )
  pssn_observed <- s15 |>
    dplyr::filter(programme_code == 7L) |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      pssn_reported = any(dplyr::coalesce(benefited, FALSE)),
      pssn_reported_frequency = sum(
        frequency[dplyr::coalesce(benefited, FALSE)], na.rm = TRUE
      ),
      .groups = "drop"
    )

  # Variante de robustesse : conserver d'abord tous les bénéficiaires PSSN
  # déclarés dans S15, puis compléter la couverture par ordre de PMT.
  hybrid_rank <- pmt_rank |>
    dplyr::left_join(
      pssn_observed |> dplyr::select(hhid, pssn_reported), by = "hhid"
    ) |>
    dplyr::mutate(pssn_reported = dplyr::coalesce(pssn_reported, FALSE)) |>
    dplyr::arrange(dplyr::desc(pssn_reported), pmt_pred_pc, hhid) |>
    dplyr::mutate(
      hybrid_order = dplyr::row_number(),
      cum_hhweight_hybrid = cumsum(hhweight)
    )
  cut_hybrid_target <- which.min(
    abs(hybrid_rank$cum_hhweight_hybrid - pssn_target_hh)
  )
  cut_hybrid_full <- which.min(
    abs(hybrid_rank$cum_hhweight_hybrid - pssn_full_hh)
  )
  hybrid_rank <- hybrid_rank |>
    dplyr::mutate(
      pssn_status_reported_first = dplyr::case_when(
        hybrid_order <= cut_hybrid_full ~ "annee_complete",
        hybrid_order <= cut_hybrid_target ~ "cohorte_partielle",
        TRUE ~ "non_beneficiaire"
      ),
      pssn_selected_reported_first = hybrid_order <= cut_hybrid_target,
      pssn_raw_reported_first = dplyr::case_when(
        pssn_status_reported_first == "annee_complete" ~
          pssn_quarterly * pssn_full_payments,
        pssn_status_reported_first == "cohorte_partielle" ~
          pssn_quarterly * pssn_partial_payments,
        TRUE ~ 0
      )
    )
  pssn_raw_mass_reported_first <- sum(
    hybrid_rank$pssn_raw_reported_first * hybrid_rank$hhweight
  )
  pssn_factor_reported_first <-
    pssn_target_mass / pssn_raw_mass_reported_first
  hybrid_rank <- hybrid_rank |>
    dplyr::transmute(
      hhid, pssn_status_reported_first, pssn_selected_reported_first,
      pssn_hh_reported_first =
        pssn_raw_reported_first * pssn_factor_reported_first
    )

  # -------------------------------------------------------------------------
  # 3. Bourses, prestations familiales et accidents du travail
  # -------------------------------------------------------------------------
  scholarships <- s02 |>
    dplyr::mutate(
      scholarship_central = dplyr::if_else(
        scholarship_reported > 0 & enrolled & public_school &
          school_level %in% c(3L, 5L, 8L),
        scholarship_reported,
        0
      )
    ) |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      scholarship_hh = sum(scholarship_central, na.rm = TRUE),
      scholarship_all_reported_hh = sum(scholarship_reported, na.rm = TRUE),
      n_scholarships = sum(scholarship_central > 0, na.rm = TRUE),
      .groups = "drop"
    )

  family_child_monthly <- get_param(
    "Prestations familiales", "allocation enfant mensuelle"
  )
  family_prenatal <- get_param(
    "Prestations familiales", "allocation prenatale totale"
  )
  family_birth <- get_param(
    "Prestations familiales", "allocation naissance"
  )
  family_maternity <- get_param(
    "Prestations familiales", "allocation maternite totale"
  )
  industrial_fund <- get_param("Accidents du travail", "depenses annuelles")

  family_base <- hh |>
    dplyr::select(hhid, hhweight) |>
    dplyr::left_join(demog, by = "hhid") |>
    dplyr::left_join(s04_coverage, by = "hhid") |>
    dplyr::mutate(
      dplyr::across(
        c(
          n_eligible_children, n_dependent_children, n_newborn, n_one_year,
          n_covered_workers, n_at_workers
        ),
        ~ dplyr::coalesce(as.numeric(.x), 0)
      ),
      maternity_covered = dplyr::coalesce(maternity_covered, FALSE),
      family_covered = n_covered_workers > 0 | maternity_covered,
      family_allowance_hh = as.numeric(family_covered) *
        n_eligible_children * family_child_monthly * 12,
      prenatal_allowance_hh = as.numeric(family_covered) *
        n_newborn * family_prenatal,
      birth_grant_hh = as.numeric(family_covered) * n_newborn *
        as.numeric(n_dependent_children <= 3) * family_birth,
      maternity_allowance_hh = as.numeric(family_covered) *
        n_one_year * family_maternity,
      family_benefits_hh = family_allowance_hh + prenatal_allowance_hh +
        birth_grant_hh + maternity_allowance_hh
    )
  at_contributors <- sum(
    family_base$n_at_workers * family_base$hhweight, na.rm = TRUE
  )
  if (!is.finite(at_contributors) || at_contributors <= 0) {
    stop("Aucun travailleur couvert pour l'assurance AT/MP.", call. = FALSE)
  }
  at_average_spending <- industrial_fund / at_contributors
  family_base <- family_base |>
    dplyr::mutate(
      industrial_accident_hh = n_at_workers * at_average_spending
    ) |>
    dplyr::select(
      hhid, n_eligible_children, n_covered_workers, n_at_workers,
      family_allowance_hh, prenatal_allowance_hh, birth_grant_hh,
      maternity_allowance_hh, family_benefits_hh, industrial_accident_hh
    )

  # -------------------------------------------------------------------------
  # 4. Pensions contributives et transferts prives (diagnostics)
  # -------------------------------------------------------------------------
  pensions <- haven::read_dta(
    s05_path,
    col_select = c(
      "grappe", "menage", "s05q02", "s05q04", "s05q06", "s05q08"
    )
  ) |>
    dplyr::transmute(
      hhid = make_hhid(grappe, menage),
      retirement = pmax(dplyr::coalesce(as.numeric(s05q02), 0), 0),
      survivor = pmax(dplyr::coalesce(as.numeric(s05q04), 0), 0),
      invalidity = pmax(dplyr::coalesce(as.numeric(s05q06), 0), 0),
      alimony_private = pmax(dplyr::coalesce(as.numeric(s05q08), 0), 0)
    ) |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      pension_retirement_hh = sum(retirement),
      pension_survivor_hh = sum(survivor),
      pension_invalidity_hh = sum(invalidity),
      pension_obs_hh = sum(retirement + survivor + invalidity),
      alimony_private_hh = sum(alimony_private),
      .groups = "drop"
    )

  private_remittances <- haven::read_dta(
    s13_path,
    col_select = c("grappe", "menage", "s13q22a", "s13q22b")
  ) |>
    dplyr::transmute(
      hhid = make_hhid(grappe, menage),
      amount_each = pmax(dplyr::coalesce(as.numeric(s13q22a), 0), 0),
      annual_factor = dplyr::case_when(
        as.integer(s13q22b) == 1L ~ 12,
        as.integer(s13q22b) == 2L ~ 4,
        as.integer(s13q22b) == 3L ~ 2,
        as.integer(s13q22b) == 4L ~ 1,
        as.integer(s13q22b) == 5L ~ 1,
        TRUE ~ 0
      ),
      private_remittance_s13 = amount_each * annual_factor
    ) |>
    dplyr::group_by(hhid) |>
    dplyr::summarise(
      private_remittance_s13_hh = sum(private_remittance_s13),
      .groups = "drop"
    )

  # -------------------------------------------------------------------------
  # 5. Assemblage PDI / PGT et identites CEQ
  # -------------------------------------------------------------------------
  hh <- hh |>
    dplyr::left_join(
      pmt_rank |>
        dplyr::select(
          hhid, pmt_pred_pc, pssn_status, pssn_selected, pssn_hh,
          pssn_hh_all_full
        ),
      by = "hhid"
    ) |>
    dplyr::left_join(pssn_observed, by = "hhid") |>
    dplyr::left_join(hybrid_rank, by = "hhid") |>
    dplyr::left_join(scholarships, by = "hhid") |>
    dplyr::left_join(family_base, by = "hhid") |>
    dplyr::left_join(pensions, by = "hhid") |>
    dplyr::left_join(private_remittances, by = "hhid") |>
    dplyr::mutate(
      pssn_reported = dplyr::coalesce(pssn_reported, FALSE),
      pssn_reported_frequency = dplyr::coalesce(
        pssn_reported_frequency, 0
      ),
      pssn_selected = dplyr::coalesce(pssn_selected, FALSE),
      pssn_selected_reported_first = dplyr::coalesce(
        pssn_selected_reported_first, FALSE
      ),
      pssn_status_reported_first = dplyr::coalesce(
        pssn_status_reported_first, "non_beneficiaire"
      ),
      pssn_status = dplyr::coalesce(pssn_status, "non_beneficiaire"),
      dplyr::across(
        c(
          pssn_hh, pssn_hh_all_full, pssn_hh_reported_first, scholarship_hh,
          scholarship_all_reported_hh, n_scholarships,
          n_eligible_children, n_covered_workers, n_at_workers,
          family_allowance_hh, prenatal_allowance_hh, birth_grant_hh,
          maternity_allowance_hh, family_benefits_hh,
          industrial_accident_hh, pension_retirement_hh,
          pension_survivor_hh, pension_invalidity_hh, pension_obs_hh,
          alimony_private_hh, private_remittance_s13_hh
        ),
        ~ dplyr::coalesce(as.numeric(.x), 0)
      ),
      other_cash_hh = 0,
      public_transfers_hh = pssn_hh + scholarship_hh + family_benefits_hh +
        industrial_accident_hh + other_cash_hh,
      public_transfers_all_full_hh = pssn_hh_all_full + scholarship_hh +
        family_benefits_hh + industrial_accident_hh + other_cash_hh,
      public_transfers_reported_first_hh = pssn_hh_reported_first +
        scholarship_hh + family_benefits_hh + industrial_accident_hh + other_cash_hh,
      pssn_hh_real = pssn_hh * def_spa,
      pssn_hh_reported_first_real = pssn_hh_reported_first * def_spa,
      scholarship_hh_real = scholarship_hh * def_spa,
      family_benefits_hh_real = family_benefits_hh * def_spa,
      industrial_accident_hh_real = industrial_accident_hh * def_spa,
      pension_obs_hh_real = pension_obs_hh * def_spa,
      public_transfers_hh_real = public_transfers_hh * def_spa,
      public_transfers_pc_real = public_transfers_hh_real / hhsize,
      # PDI central: la retraite est du revenu differe. Seule la CMU reste
      # dans les cotisations non pension deja simulees a l'etape 17.
      direct_levies_pdi_hh_real = irpp_real + cmu_real,
      yp_pc_pdi = yd_pc + direct_levies_pdi_hh_real / hhsize -
        public_transfers_pc_real,
      yl_pc_pdi = yp_pc_pdi,
      yn_pc_pdi = yp_pc_pdi - direct_levies_pdi_hh_real / hhsize,
      yg_pc_pdi = yp_pc_pdi + public_transfers_pc_real,
      yd_pc_check_pdi = yn_pc_pdi + public_transfers_pc_real,
      # PGT robustesse : les pensions sont ajoutees aux paiements publics et les cotisations retraite aux prelevements.
      public_transfers_pgt_hh_real = public_transfers_hh_real +
        pension_obs_hh_real,
      direct_levies_pgt_hh_real = irpp_real + cmu_real + cnps_real,
      yp_pc_pgt = yd_pc + direct_levies_pgt_hh_real / hhsize -
        public_transfers_pgt_hh_real / hhsize,
      yn_pc_pgt = yp_pc_pgt - direct_levies_pgt_hh_real / hhsize,
      yg_pc_pgt = yp_pc_pgt + public_transfers_pgt_hh_real / hhsize,
      yd_pc_check_pgt = yn_pc_pgt + public_transfers_pgt_hh_real / hhsize
    )

  amount_cols <- c(
    "pssn_hh", "scholarship_hh", "family_benefits_hh",
    "industrial_accident_hh", "pension_obs_hh", "public_transfers_hh"
  )
  if (any(!is.finite(as.matrix(hh[, amount_cols]))) ||
      any(as.matrix(hh[, amount_cols]) < 0)) {
    stop("Transferts negatifs ou non finis detectes.", call. = FALSE)
  }

  identity_pdi <- max(abs(hh$yd_pc_check_pdi - hh$yd_pc), na.rm = TRUE)
  identity_pgt <- max(abs(hh$yd_pc_check_pgt - hh$yd_pc), na.rm = TRUE)
  if (identity_pdi > 1e-6 || identity_pgt > 1e-6) {
    stop("Les identites CEQ PDI/PGT ne ferment pas.", call. = FALSE)
  }

  pssn_sim_mass <- sum(hh$pssn_hh * hh$hhweight)
  pssn_sim_mass_reported_first <- sum(
    hh$pssn_hh_reported_first * hh$hhweight
  )
  at_sim_mass <- sum(hh$industrial_accident_hh * hh$hhweight)
  if (abs(pssn_sim_mass - pssn_target_mass) > 1 ||
      abs(pssn_sim_mass_reported_first - pssn_target_mass) > 1 ||
      abs(at_sim_mass - industrial_fund) > 1) {
    stop("Echec du calage macro PSSN ou AT/MP.", call. = FALSE)
  }

  output_cols <- c(
    "hhid", "grappe", "strata", "hhweight", "pcweight", "region",
    "milieu", "decile", "quintile", "hhsize", "def_spa", "yd_pc",
    "yd_hh", "pmt_pred_pc", "pssn_status", "pssn_selected",
    "pssn_reported", "pssn_reported_frequency", "pssn_hh",
    "pssn_status_reported_first", "pssn_selected_reported_first",
    "pssn_hh_reported_first", "pssn_hh_reported_first_real",
    "pssn_hh_all_full", "scholarship_hh", "scholarship_all_reported_hh",
    "n_scholarships", "n_eligible_children", "n_covered_workers",
    "n_at_workers", "family_allowance_hh", "prenatal_allowance_hh",
    "birth_grant_hh", "maternity_allowance_hh", "family_benefits_hh",
    "industrial_accident_hh", "other_cash_hh", "public_transfers_hh",
    "public_transfers_reported_first_hh", "public_transfers_all_full_hh",
    "pension_retirement_hh",
    "pension_survivor_hh", "pension_invalidity_hh", "pension_obs_hh",
    "alimony_private_hh", "private_remittance_s13_hh", "pssn_hh_real",
    "scholarship_hh_real", "family_benefits_hh_real",
    "industrial_accident_hh_real", "pension_obs_hh_real",
    "public_transfers_hh_real", "public_transfers_pc_real",
    "direct_levies_pdi_hh_real", "yp_pc_pdi", "yl_pc_pdi", "yn_pc_pdi",
    "yg_pc_pdi", "yd_pc_check_pdi", "public_transfers_pgt_hh_real",
    "direct_levies_pgt_hh_real", "yp_pc_pgt", "yn_pc_pgt", "yg_pc_pgt",
    "yd_pc_check_pgt"
  )
  save_parquet(
    hh |>
      dplyr::select(dplyr::all_of(output_cols)),
    file.path(paths$SILVER, "18", "transfers.parquet")
  )

  # -------------------------------------------------------------------------
  # 6. Rapports de validation et figure
  # -------------------------------------------------------------------------
  transfer_long <- hh |>
    dplyr::select(
      hhid, decile, hhweight, pssn_hh, scholarship_hh,
      family_benefits_hh, industrial_accident_hh
    ) |>
    tidyr::pivot_longer(
      cols = c(
        pssn_hh, scholarship_hh, family_benefits_hh,
        industrial_accident_hh
      ),
      names_to = "instrument", values_to = "montant_hh"
    )
  beneficiaries_decile <- transfer_long |>
    dplyr::group_by(decile, instrument) |>
    dplyr::summarise(
      menages_beneficiaires_ponderes = sum(
        hhweight * (montant_hh > 0), na.rm = TRUE
      ),
      couverture_menages_pct = 100 * stats::weighted.mean(
        montant_hh > 0, hhweight, na.rm = TRUE
      ),
      montant_moyen_menage = stats::weighted.mean(
        montant_hh, hhweight, na.rm = TRUE
      ),
      masse_milliards = sum(montant_hh * hhweight, na.rm = TRUE) / 1e9,
      .groups = "drop"
    )
  export_excel(
    beneficiaries_decile,
    file.path(paths$TABLES, "18", "18_01_beneficiaries_by_decile.xlsx")
  )

  s15_diagnostics <- s15 |>
    dplyr::left_join(
      hh |>
        dplyr::select(hhid, hhweight, decile, yd_pc, zref),
      by = "hhid"
    ) |>
    dplyr::group_by(
      programme_code, libelle, nature_ceq, paiement_public_monetaire, traitement
    ) |>
    dplyr::summarise(
      demandes_ponderees = sum(hhweight * dplyr::coalesce(applied, FALSE)),
      beneficiaires_ponderes = sum(
        hhweight * dplyr::coalesce(benefited, FALSE)
      ),
      part_beneficiaires_pauvres_pct = dplyr::if_else(
        sum(hhweight * dplyr::coalesce(benefited, FALSE)) > 0,
        100 * sum(
          hhweight * dplyr::coalesce(benefited, FALSE) * (yd_pc < zref),
          na.rm = TRUE
        ) / sum(hhweight * dplyr::coalesce(benefited, FALSE), na.rm = TRUE),
        NA_real_
      ),
      .groups = "drop"
    )

  pssn_targeting <- tibble::tibble(
    indicateur = c(
      "Cible administrative de menages",
      "Menages imputes ponderes",
      "Ecart de couverture",
      "Menages declarant le programme cash S15",
      "Chevauchement impute et declare S15",
      "Part des imputes sous le seuil de pauvrete",
      "Part des declares S15 sous le seuil de pauvrete",
      "Masse PSSN calibree",
      "Facteur de calage de masse"
    ),
    valeur = c(
      pssn_target_hh,
      sum(hh$hhweight * hh$pssn_selected),
      sum(hh$hhweight * hh$pssn_selected) - pssn_target_hh,
      sum(hh$hhweight * hh$pssn_reported),
      sum(hh$hhweight * hh$pssn_reported * hh$pssn_selected),
      stats::weighted.mean(
        hh$yd_pc < hh$zref, hh$hhweight * hh$pssn_selected, na.rm = TRUE
      ),
      stats::weighted.mean(
        hh$yd_pc < hh$zref, hh$hhweight * hh$pssn_reported, na.rm = TRUE
      ),
      pssn_sim_mass,
      pssn_calibration_factor
    ),
    unite = c(
      "menages", "menages", "menages", "menages", "menages",
      "ratio", "ratio", "FCFA", "ratio"
    )
  )
  pssn_targeting_robustness <- dplyr::bind_rows(
    tibble::tibble(
      scenario = "PMT seul (central)",
      menages_selectionnes_ponderes = sum(hh$hhweight * hh$pssn_selected),
      beneficiaires_declares_conserves_ponderes = sum(
        hh$hhweight * hh$pssn_reported * hh$pssn_selected
      ),
      part_selectionnes_pauvres = stats::weighted.mean(
        hh$yd_pc < hh$zref, hh$hhweight * hh$pssn_selected, na.rm = TRUE
      ),
      masse_milliards = pssn_sim_mass / 1e9,
      facteur_calage = pssn_calibration_factor
    ),
    tibble::tibble(
      scenario = "Déclarés S15 d'abord, complément PMT",
      menages_selectionnes_ponderes = sum(
        hh$hhweight * hh$pssn_selected_reported_first
      ),
      beneficiaires_declares_conserves_ponderes = sum(
        hh$hhweight * hh$pssn_reported * hh$pssn_selected_reported_first
      ),
      part_selectionnes_pauvres = stats::weighted.mean(
        hh$yd_pc < hh$zref,
        hh$hhweight * hh$pssn_selected_reported_first,
        na.rm = TRUE
      ),
      masse_milliards = pssn_sim_mass_reported_first / 1e9,
      facteur_calage = pssn_factor_reported_first
    )
  )
  pssn_decile_robustness <- hh |>
    dplyr::group_by(decile) |>
    dplyr::summarise(
      menages_pmt = sum(hhweight * pssn_selected),
      menages_declares_dabord = sum(
        hhweight * pssn_selected_reported_first
      ),
      masse_pmt_milliards = sum(hhweight * pssn_hh) / 1e9,
      masse_declares_dabord_milliards = sum(
        hhweight * pssn_hh_reported_first
      ) / 1e9,
      .groups = "drop"
    )
  pmt_coefficients <- tibble::tibble(
    terme = names(stats::coef(pmt_model)),
    coefficient = as.numeric(stats::coef(pmt_model))
  )
  openxlsx::write.xlsx(
    list(
      pssn = as.data.frame(pssn_targeting),
      robustesse_declares_dabord = as.data.frame(pssn_targeting_robustness),
      deciles_declares_dabord = as.data.frame(pssn_decile_robustness),
      programmes_s15 = as.data.frame(s15_diagnostics),
      coefficients_pmt = as.data.frame(pmt_coefficients),
      methode = as.data.frame(method_params)
    ),
    file = file.path(paths$TABLES, "18", "18_02_coverage_targeting.xlsx"),
    overwrite = TRUE
  )

  pension_mass <- sum(hh$pension_obs_hh * hh$hhweight)
  scholarship_mass <- sum(hh$scholarship_hh * hh$hhweight)
  family_mass <- sum(hh$family_benefits_hh * hh$hhweight)
  macro_validation <- tibble::tibble(
    agregat = c(
      "Menages PSSN servis", "Masse PSSN", "Bourses publiques observees",
      "Prestations familiales simulees", "Accidents du travail",
      "Pensions contributives observees"
    ),
    simulation_2021 = c(
      sum(hh$hhweight * hh$pssn_selected), pssn_sim_mass,
      scholarship_mass, family_mass, at_sim_mass, pension_mass
    ),
    reference_2021 = c(
      get_macro("Menages PSSN servis"), pssn_target_mass, NA_real_, NA_real_,
      industrial_fund, get_macro("Prestations CGRAE")
    ),
    unite = c("menages", rep("FCFA", 5)),
    comparabilite = c(
      "Calage sur la couverture active 2021.",
      "Calage exact; decomposition 177 000 complets et 15 000 partiels.",
      "Identification directe S02; secondaire general et superieur publics.",
      "Bareme CNPS sur enfants des menages ayant un cotisant declare.",
      "Calage exact sur une reference technique, non independante.",
      "EHCVM tous regimes contre CGRAE agents publics seulement."
    )
  ) |>
    dplyr::mutate(
      ratio_simulation_reference_pct = dplyr::if_else(
        is.finite(reference_2021) & reference_2021 > 0,
        100 * simulation_2021 / reference_2021,
        NA_real_
      )
    )
  export_excel(
    macro_validation,
    file.path(paths$TABLES, "18", "18_03_macro_validation.xlsx")
  )

  pension_scenarios <- tibble::tibble(
    scenario = c("PDI central", "PGT robustesse"),
    pension_dans_transferts = c(FALSE, TRUE),
    cnps_retraite_dans_prelevements = c(FALSE, TRUE),
    masse_transferts_milliards = c(
      sum(hh$public_transfers_hh_real * hh$hhweight) / 1e9,
      sum(hh$public_transfers_pgt_hh_real * hh$hhweight) / 1e9
    ),
    gini_yp_plancher_zero = c(
      weighted_gini(pmax(hh$yp_pc_pdi, 0), hh$pcweight),
      weighted_gini(pmax(hh$yp_pc_pgt, 0), hh$pcweight)
    ),
    gini_yn_plancher_zero = c(
      weighted_gini(pmax(hh$yn_pc_pdi, 0), hh$pcweight),
      weighted_gini(pmax(hh$yn_pc_pgt, 0), hh$pcweight)
    ),
    part_population_yp_negatif_pct = c(
      100 * stats::weighted.mean(hh$yp_pc_pdi < 0, hh$pcweight),
      100 * stats::weighted.mean(hh$yp_pc_pgt < 0, hh$pcweight)
    ),
    gini_yd = weighted_gini(hh$yd_pc, hh$pcweight)
  )
  export_excel(
    pension_scenarios,
    file.path(paths$TABLES, "18", "18_04_pension_scenarios.xlsx")
  )

  identity_checks <- tibble::tibble(
    scenario = c("PDI central", "PGT robustesse"),
    identite = c("Y_D = Y_N + R", "Y_D = Y_N + R"),
    ecart_absolu_max = c(identity_pdi, identity_pgt),
    ecart_moyen_pondere = c(
      stats::weighted.mean(
        hh$yd_pc_check_pdi - hh$yd_pc, hh$pcweight, na.rm = TRUE
      ),
      stats::weighted.mean(
        hh$yd_pc_check_pgt - hh$yd_pc, hh$pcweight, na.rm = TRUE
      )
    ),
    statut = c(
      ifelse(identity_pdi <= 1e-6, "OK", "ECHEC"),
      ifelse(identity_pgt <= 1e-6, "OK", "ECHEC")
    )
  )
  export_excel(
    identity_checks,
    file.path(paths$TABLES, "18", "18_05_ceq_identity_checks.xlsx")
  )

  hh_inference <- hh |>
    dplyr::mutate(dtr_pc = public_transfers_hh_real / hhsize)
  transfer_targeting_stat <- function(d) {
    weighted_gini(d$yd_pc, d$pcweight) -
      weighted_conindex(d$dtr_pc, d$yd_pc, d$pcweight)
  }
  transfer_boot <- bootstrap_survey_statistic(
    data = hh_inference,
    statistic = transfer_targeting_stat,
    weight_var = "pcweight",
    cluster_var = "grappe",
    strata_var = "strata",
    reps = 500,
    seed = 20240918
  )
  progressivity <- tibble::tibble(
    indicateur = "Indice de ciblage des transferts (Gini - concentration)",
    estimation = transfer_targeting_stat(hh_inference),
    concentration_transferts = weighted_conindex(
      hh_inference$dtr_pc, hh_inference$yd_pc, hh_inference$pcweight
    ),
    gini_revenu_disponible = weighted_gini(
      hh_inference$yd_pc, hh_inference$pcweight
    ),
    ic95_bas = transfer_boot$lo,
    ic95_haut = transfer_boot$hi,
    ecart_type = transfer_boot$sd,
    repetitions_valides = transfer_boot$reps_ok,
    methode = transfer_boot$method,
    interpretation = "Positif: transfert concentre davantage vers les menages pauvres."
  )
  export_excel(
    progressivity,
    file.path(paths$TABLES, "18", "18_06_progressivity_inference.xlsx")
  )

  figure_data <- hh |>
    dplyr::transmute(
      decile, pcweight, yd_pc,
      PSSN = pssn_hh_real / hhsize,
      Bourses = scholarship_hh_real / hhsize,
      `Prestations familiales` = family_benefits_hh_real / hhsize,
      `Accidents du travail` = industrial_accident_hh_real / hhsize
    ) |>
    tidyr::pivot_longer(
      cols = c(PSSN, Bourses, `Prestations familiales`, `Accidents du travail`),
      names_to = "instrument", values_to = "transfert_pc"
    ) |>
    dplyr::group_by(decile, instrument) |>
    dplyr::summarise(
      taux_revenu_pct = 100 * sum(transfert_pc * pcweight) /
        sum(yd_pc * pcweight),
      .groups = "drop"
    )
  fig <- ggplot2::ggplot(
    figure_data,
    ggplot2::aes(x = factor(decile), y = taux_revenu_pct, fill = instrument)
  ) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = c(
      "PSSN" = "#1F77B4",
      "Bourses" = "#2CA02C",
      "Prestations familiales" = "#FF7F0E",
      "Accidents du travail" = "#D62728"
    )) +
    ggplot2::labs(
      x = "Decile de revenu disponible par tete",
      y = "Transfert moyen (% du revenu disponible)",
      fill = NULL
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(decimal.mark = ",", suffix = " %")
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")
  export_fig(
    fig, file.path(paths$FIGS, "fig18_transfers_decile.png"),
    width = 10, height = 6
  )

  message("  PSSN: ", round(sum(hh$hhweight * hh$pssn_selected)),
          " menages; ", round(pssn_sim_mass / 1e9, 3), " Mds FCFA")
  message("  Transferts publics centraux: ",
          round(sum(hh$public_transfers_hh * hh$hhweight) / 1e9, 3),
          " Mds FCFA")
  message("  Pensions observees: ", round(pension_mass / 1e9, 3),
          " Mds FCFA")
  message(">>> ETAPE 19 terminee")

  invisible(hh)
}
