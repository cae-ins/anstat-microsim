# 16_direct_taxes.R
#
# OBJECTIF :
# Calculer les impots directs sur les salaires (IS, CN, IGR) et les
# cotisations sociales (CNPS part salariee, CMU) par menage. Les montants sont
# prepares pour la reconstruction a rebours des concepts de revenu CEQ.
# L'etape ne soustrait plus les prelevements de conso_w : pcexp est l'ancre du
# revenu disponible et le revenu de marche doit etre reconstruit a rebours.
#
# BAREMES (CGI 2021, cf. 00_documentation/methodologie/MEMOIRE_FISCAL_CIV2021.md) :
#   IS   : 1,2 % du SBI (= 1,5 % de la base imposable BI = 0,8 x SBI)
#   CN   : par tranches mensuelles sur BI : 0 % (<=50k), 1,5 % (50k-130k),
#          5 % (130k-200k), 10 % (>200k)
#   IGR  : base R = 0,8 x (SBI - IS - CN), quotient familial N (plafond 5 parts),
#          bareme mensuel en 10 tranches sur Q = R/N, reduction finale de 15 %
#   CNPS : part salariee retraite 6,3 % du SBI plafonne a 1 647 315 FCFA/mois
#   CMU  : 1 000 FCFA/mois par adulte contributif participant, selon la
#          couverture observee et les effectifs administratifs de reference
#
# NOTE : le script Banque mondiale de reference (ressources_CEQ/02. CIV21WBN_dtx.do)
# encode un bareme IGR de *proposition de reforme* (0/16/21/24/28/32 %,
# deduction 5 500 FCFA par demi-part) et non le bareme CGI en vigueur en 2021.
# On retient donc le bareme par quotient de la memoire fiscale du projet.
#
# HYPOTHESES (a documenter dans le rapport — couverture des impots directs) :
#   - Scenario fiscal central multi-criteres : remuneration positive et au
#     moins un indice de tracabilite de l'emploi principal, ou emploi secondaire
#     remunere dans une categorie professionnelle retenue.
#   - Robustesses fiscales : bulletin ET cotisation (stricte), puis bulletin OU
#     cotisation (elargie), sur la meme assiette salariale annualisee issue de s04.
#   - La formalite OIT est mesuree separement pour l'emploi principal salarie :
#     cotisation declaree CGRAE/CNPS; une variante ajoute l'acces conjoint aux
#     conges annuel et maladie payes. Elle ne determine pas l'assujettissement.
#   - Enfants a charge (<18 ans) attribues au salarie formel le mieux paye du
#     menage ; les autres salaries ne portent que leurs parts d'etat civil.
#
# ENTREE :  DATA/ehcvm_individu_CIV2021.dta
#           01_data_sources/Datain/Menage/s04_me_CIV2021.dta  (flags formalite)
#           SILVER/04/fiscal_data_analysis_ready.parquet
# SORTIE :  SILVER/16/direct_taxes.parquet
#           TABLES/16/16_01_irpp_by_decile.xlsx
#           TABLES/16/16_02_cotisations_by_decile.xlsx
#           TABLES/16/16_03_coverage_kakwani.xlsx
#           TABLES/16/16_04_formality_definitions.xlsx
#           FIGS/fig16_direct_burden_decile.png
#
# AUTEUR : CAE — ANStat

direct_taxes <- function(paths) {

  message(">>> ETAPE 16 : Impots directs (IS, CN, IGR) et cotisations (CNPS, CMU)")

  # ── Parametres fiscaux (CGI 2021) ──────────────────────────────────────────
  TAUX_IS        <- 0.012      # 1,5 % de BI = 1,2 % du SBI
  ABATTEMENT     <- 0.80       # base imposable = 80 % du SBI
  TAUX_CNPS      <- 0.063      # part salariee retraite
  PLAFOND_CNPS_M <- 1647315    # plafond mensuel de l'assiette CNPS (FCFA)
  CMU_MENSUEL    <- 1000       # contribution mensuelle CMU (FCFA/adulte)
  CMU_CIBLE_PAUVRES <- 75000
  CMU_CIBLE_NON_PAUVRES <- 1425000
  PLAFOND_PARTS  <- 5

  # ── Contribution Nationale : bareme mensuel par tranches sur BI ────────────
  calc_cn <- function(bi) {
    pmax(0, pmin(bi, 130000) - 50000)  * 0.015 +
    pmax(0, pmin(bi, 200000) - 130000) * 0.050 +
    pmax(0, bi - 200000)               * 0.100
  }

  # ── IGR : bareme mensuel par part (Q = R/N) ────────────────────────────────
  calc_igr_part <- function(q) {
    dplyr::case_when(
      q <= 25000  ~ 0,
      q <= 45000  ~ q * 10 / 110 - 2273,
      q <= 60000  ~ q * 15 / 115 - 4076,
      q <= 80000  ~ q * 20 / 120 - 7083,
      q <= 100000 ~ q * 25 / 125 - 11000,
      q <= 120000 ~ q * 30 / 130 - 15769,
      q <= 140000 ~ q * 35 / 135 - 21296,
      q <= 160000 ~ q * 40 / 140 - 27500,
      q <= 180000 ~ q * 45 / 145 - 34310,
      q <= 200000 ~ q * 50 / 150 - 41667,
      TRUE        ~ q * 60 / 160 - 57813
    )
  }

  # ── 1. Chargement individus (agregat harmonise INS) ────────────────────────
  ind <- load_raw_dta(
    "ehcvm_individu_CIV2021.dta",
    col_select = c("hhid", "grappe", "menage", "numind", "age", "mstat",
                   "salaire", "salaire_sec", "emploi_sec", "hhweight")
  )
  assert_required_columns(
    ind, c("hhid", "grappe", "menage", "numind", "age", "mstat", "salaire"),
    object_name = "ehcvm_individu_CIV2021.dta"
  )

  # ── 2. Flags de formalite depuis le module emploi brut (s04) ───────────────
  s04_path <- source_file_path("Datain", "Menage", "s04_me_CIV2021.dta",
                               label = "Module emploi s04")
  s04 <- haven::read_dta(
    s04_path,
    col_select = c(
      'grappe', 'menage', 'individu', 's04q32', 's04q33', 's04q34',
      's04q35', 's04q38', 's04q40', 's04q42', 's04q43',
      's04q43_unite', 's04q50', 's04q51b', 's04q51d', 's04q58',
      's04q58_unite'
    )
  ) %>%
    dplyr::transmute(
      grappe, menage,
      numind        = individu,
      mois_principal = as.numeric(s04q32),
      conge_paye = as.integer(s04q33) == 1L,
      conge_annuel_pris = as.numeric(s04q34) > 0,
      conge_maladie = as.integer(s04q35) == 1L,
      bulletin_paie_renseigne = !is.na(as.integer(s04q42)),
      bulletin_paie = as.integer(s04q42) == 1L,
      cotise_caisse_renseigne = !is.na(as.integer(s04q38)),
      cotise_caisse = as.integer(s04q38) == 1L,
      conge_maternite = as.integer(s04q40) == 1L,
      salaire_principal_bm = dplyr::case_when(
        as.integer(s04q43_unite) == 1L ~ as.numeric(s04q43) * 52,
        as.integer(s04q43_unite) == 2L ~ as.numeric(s04q43) * 12,
        as.integer(s04q43_unite) == 3L ~ as.numeric(s04q43) * 3,
        as.integer(s04q43_unite) == 4L ~ as.numeric(s04q43),
        TRUE ~ 0
      ),
      emploi_secondaire = as.integer(s04q50) == 1L,
      secteur_secondaire_formel = as.integer(s04q51b) %in% c(1:4, 10L),
      profession_secondaire_formelle = dplyr::between(
        as.integer(s04q51d), 11L, 401L
      ),
      salaire_secondaire_bm = dplyr::case_when(
        as.integer(s04q58_unite) == 1L ~ as.numeric(s04q58) * 52,
        as.integer(s04q58_unite) == 2L ~ as.numeric(s04q58) * 12,
        as.integer(s04q58_unite) == 3L ~ as.numeric(s04q58) * 3,
        as.integer(s04q58_unite) == 4L ~ as.numeric(s04q58),
        TRUE ~ 0
      )
    )

  ind <- ind %>%
    dplyr::left_join(s04, by = c("grappe", "menage", "numind")) %>%
    dplyr::mutate(
      salaire       = dplyr::coalesce(as.numeric(salaire), 0),
      mois_principal = dplyr::coalesce(mois_principal, 0),
      bulletin_paie = dplyr::coalesce(bulletin_paie, FALSE),
      bulletin_paie_renseigne = dplyr::coalesce(
        bulletin_paie_renseigne, FALSE
      ),
      cotise_caisse_renseigne = dplyr::coalesce(
        cotise_caisse_renseigne, FALSE
      ),
      cotise_caisse = dplyr::coalesce(cotise_caisse, FALSE),
      conge_paye = dplyr::coalesce(conge_paye, FALSE),
      conge_annuel_pris = dplyr::coalesce(conge_annuel_pris, FALSE),
      conge_maladie = dplyr::coalesce(conge_maladie, FALSE),
      conge_maternite = dplyr::coalesce(conge_maternite, FALSE),
      emploi_secondaire = dplyr::coalesce(emploi_secondaire, FALSE),
      secteur_secondaire_formel = dplyr::coalesce(
        secteur_secondaire_formel, FALSE
      ),
      profession_secondaire_formelle = dplyr::coalesce(
        profession_secondaire_formelle, FALSE
      ),
      salaire_principal_bm = dplyr::coalesce(salaire_principal_bm, 0),
      salaire_secondaire_bm = dplyr::coalesce(salaire_secondaire_bm, 0),
      formel_principal_bm = salaire_principal_bm > 0 & mois_principal > 0 &
        (conge_paye | conge_annuel_pris | conge_maladie | cotise_caisse |
           conge_maternite | bulletin_paie),
      formel_secondaire_bm = emploi_secondaire &
        (secteur_secondaire_formel | profession_secondaire_formelle),
      salaire_bm = ifelse(formel_principal_bm, salaire_principal_bm, 0) +
        ifelse(formel_secondaire_bm, salaire_secondaire_bm, 0),
      formel_fiscal_bm = salaire_bm > 0,
      emploi_salarie_principal = salaire_principal_bm > 0 & mois_principal > 0,
      # 21e CIST (OIT, 2023) : la cotisation patronale a un regime legal
      # caracterise l'emploi salarie formel. Les conges payes sont des
      # criteres complementaires, presentes ici dans une variante elargie.
      formel_oit = emploi_salarie_principal & cotise_caisse,
      formel_oit_elargi = emploi_salarie_principal &
        (cotise_caisse | (conge_paye & conge_maladie)),
      formel_fiscal_strict = salaire_bm > 0 & bulletin_paie & cotise_caisse,
      formel_fiscal_large = salaire_bm > 0 & (bulletin_paie | cotise_caisse),
      # Diagnostic de non-reponse : il conserve par construction tous les
      # emplois du scenario central. Les absences de reponse au bulletin et a la
      # cotisation sont publiees separement et ne sont jamais recodees comme
      # une reponse positive.
      formel_fiscal_nonrep_diag = formel_fiscal_bm
    )

  n_sal    <- sum(ind$emploi_salarie_principal)
  n_bm     <- sum(ind$formel_fiscal_bm)
  n_oit    <- sum(ind$formel_oit)
  n_strict <- sum(ind$formel_fiscal_strict)
  n_large  <- sum(ind$formel_fiscal_large)
  message(sprintf(
    paste0('  Salaries principaux : %d | central multi-criteres : %d | OIT : %d | ',
           'fiscal strict : %d | fiscal elargi : %d'),
    n_sal, n_bm, n_oit, n_strict, n_large
  ))

  # ── 3. Quotient familial ───────────────────────────────────────────────────
  # Parts d'etat civil : marie (2,3) = 2 ; veuf (5) = 1,5 ;
  # celibataire / union libre / divorce / separe (1,4,6,7) = 1.
  # Enfants (<18 ans) du menage : +0,5 part chacun, attribues au salarie
  # formel le mieux paye du menage. Plafond legal : 5 parts.
  enfants_hh <- ind %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(n_enfants = sum(age < 18, na.rm = TRUE), .groups = "drop")

  ind <- ind %>%
    dplyr::left_join(enfants_hh, by = "hhid") %>%
    dplyr::mutate(
      parts_etat_civil = dplyr::case_when(
        as.integer(mstat) %in% c(2L, 3L) ~ 2,
        as.integer(mstat) == 5L          ~ 1.5,
        TRUE                             ~ 1
      )
    )

  # ── 4. Calcul des prelevements mensuels par salarie ────────────────────────
  calcule_prelevements <- function(
    df, flag_formel, salaire_var,
    allocation_enfants = c("mieux_paye", "egale")
  ) {
    allocation_enfants <- match.arg(allocation_enfants)
    df %>%
      dplyr::mutate(
        assujetti = .data[[flag_formel]],
        salaire_assujetti = .data[[salaire_var]]
      ) %>%
      dplyr::group_by(hhid) %>%
      dplyr::mutate(
        n_assujettis_hh = sum(assujetti),
        rang_assujetti = dplyr::row_number(dplyr::desc(
          ifelse(assujetti, salaire_assujetti, -Inf)
        )),
        top_earner = assujetti & rang_assujetti == 1L
      ) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(
        parts_enfants = dplyr::case_when(
          !assujetti ~ 0,
          allocation_enfants == "egale" ~
            0.5 * n_enfants / pmax(n_assujettis_hh, 1),
          top_earner ~ 0.5 * n_enfants,
          TRUE ~ 0
        ),
        n_parts = pmin(
          parts_etat_civil + parts_enfants,
          PLAFOND_PARTS
        ),
        sbi_m     = ifelse(assujetti, salaire_assujetti / 12, 0),
        bi_m      = ABATTEMENT * sbi_m,
        is_m      = TAUX_IS * sbi_m,
        cn_m      = calc_cn(bi_m),
        r_m       = ABATTEMENT * (sbi_m - is_m - cn_m),
        q_m       = r_m / n_parts,
        igr_m     = pmax(0, calc_igr_part(q_m)) * n_parts * 0.85,
        cnps_m    = TAUX_CNPS * pmin(sbi_m, PLAFOND_CNPS_M),
        irpp_an   = (is_m + cn_m + igr_m) * 12,
        cnps_an   = cnps_m * 12,
        cotis_an  = cnps_an
      )
  }

  ind_bm <- calcule_prelevements(ind, "formel_fiscal_bm", "salaire_bm")
  ind_strict <- calcule_prelevements(
    ind, "formel_fiscal_strict", "salaire_bm"
  )
  ind_large <- calcule_prelevements(
    ind, "formel_fiscal_large", "salaire_bm"
  )
  ind_nonrep_diag <- calcule_prelevements(
    ind, "formel_fiscal_nonrep_diag", "salaire_bm"
  )
  ind_bm_parts_egales <- calcule_prelevements(
    ind, "formel_fiscal_bm", "salaire_bm", allocation_enfants = "egale"
  )

  salaire_bm_hh <- ind_bm %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(
      salaire_bm_an = sum(salaire_assujetti, na.rm = TRUE),
      .groups = "drop"
    )

  # Controles de coherence
  stopifnot(
    all(ind_bm$irpp_an >= 0, na.rm = TRUE),
    all(ind_bm$cnps_m <= TAUX_CNPS * PLAFOND_CNPS_M + 1e-6, na.rm = TRUE),
    all(ind_bm$igr_m[ind_bm$q_m <= 25000] == 0, na.rm = TRUE)
  )

  # ── 5. Agregation menage ───────────────────────────────────────────────────
  agrege_hh <- function(df, suffixe = "") {
    df %>%
      dplyr::group_by(hhid) %>%
      dplyr::summarise(
        !!paste0("n_salaries_formels", suffixe) := sum(assujetti),
        !!paste0("irpp", suffixe)               := sum(irpp_an),
        !!paste0("cnps", suffixe)               := sum(cnps_an),
        !!paste0("cotisations", suffixe)        := sum(cotis_an),
        .groups = "drop"
      )
  }

  hh_direct <- agrege_hh(ind_bm) %>%
    dplyr::left_join(salaire_bm_hh, by = "hhid") %>%
    dplyr::left_join(agrege_hh(ind_strict, "_strict"), by = "hhid") %>%
    dplyr::left_join(agrege_hh(ind_large, "_large"), by = "hhid") %>%
    dplyr::left_join(
      agrege_hh(ind_nonrep_diag, "_nonrep_diag"), by = "hhid"
    ) %>%
    dplyr::left_join(
      agrege_hh(ind_bm_parts_egales, "_parts_egales"), by = "hhid"
    )

  # ── 6. Jointure au fichier fiscal menage et Net Market Income ──────────────
  fiscal <- load_parquet(
    file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  )
  assert_required_columns(
    fiscal, c('hhid', 'hhweight', 'pcexp', 'hhsize', 'pcweight', 'def_spa',
              'yd_pc', 'yd_hh', 'zref', 'strata', 'decile', 'quintile'),
    object_name = "fiscal_data_analysis_ready.parquet"
  )

  # CMU : l'enquete identifie les personnes couvertes par une assurance maladie
  # financee par un organisme public. Un tirage reproductible cale ensuite les
  # participants pauvres et non pauvres sur les effectifs administratifs. Seuls
  # les adultes non pauvres selectionnes contribuent.
  s03_path <- source_file_path("Datain", "Menage", "s03_me_CIV2021.dta",
                               label = "Module sante s03")
  s03 <- haven::read_dta(
    s03_path,
    col_select = c("grappe", "menage", "individu", "s03q32", "s03q34")
  ) %>%
    dplyr::transmute(
      grappe, menage, numind = individu,
      assurance_publique = as.integer(s03q32) == 1L &
        as.integer(s03q34) %in% c(2L, 3L)
    )

  set.seed(74375322)
  cmu_ind <- ind %>%
    dplyr::select(hhid, grappe, menage, numind, age, hhweight) %>%
    dplyr::left_join(s03, by = c("grappe", "menage", "numind")) %>%
    dplyr::left_join(
      fiscal %>% dplyr::select(hhid, yd_pc, zref),
      by = "hhid"
    ) %>%
    dplyr::mutate(
      assurance_publique = dplyr::coalesce(assurance_publique, FALSE),
      pauvre = yd_pc < zref,
      eligible_pauvre = assurance_publique & pauvre,
      eligible_non_pauvre = assurance_publique & !pauvre,
      tirage = stats::runif(dplyr::n())
    )

  selectionne_cmu <- function(df, eligibilite, cible) {
    df %>%
      dplyr::filter(.data[[eligibilite]]) %>%
      dplyr::arrange(dplyr::desc(tirage)) %>%
      dplyr::mutate(
        effectif_cumule = cumsum(hhweight),
        selectionne = effectif_cumule <= cible
      ) %>%
      dplyr::filter(selectionne) %>%
      dplyr::select(hhid, numind)
  }

  cmu_pauvres <- selectionne_cmu(
    cmu_ind, "eligible_pauvre", CMU_CIBLE_PAUVRES
  ) %>% dplyr::mutate(cmu_groupe = "pauvre_non_contributif")
  cmu_non_pauvres <- selectionne_cmu(
    cmu_ind, "eligible_non_pauvre", CMU_CIBLE_NON_PAUVRES
  ) %>% dplyr::mutate(cmu_groupe = "non_pauvre_contributif")

  cmu_ind <- cmu_ind %>%
    dplyr::left_join(
      dplyr::bind_rows(cmu_pauvres, cmu_non_pauvres),
      by = c("hhid", "numind")
    ) %>%
    dplyr::mutate(
      cmu_participant = !is.na(cmu_groupe),
      cmu_contributeur = cmu_groupe %in% "non_pauvre_contributif" &
        dplyr::coalesce(age >= 18, FALSE),
      cmu_an = ifelse(cmu_contributeur, 12 * CMU_MENSUEL, 0),
      cmu_universelle_an = ifelse(
        dplyr::coalesce(age >= 18, FALSE), 12 * CMU_MENSUEL, 0
      )
    )

  cmu_hh <- cmu_ind %>%
    dplyr::group_by(hhid) %>%
    dplyr::summarise(
      n_cmu_participants = sum(cmu_participant),
      n_cmu_contributeurs = sum(cmu_contributeur),
      cmu = sum(cmu_an),
      cmu_universelle = sum(cmu_universelle_an),
      .groups = "drop"
    )

  hh <- fiscal %>%
    dplyr::left_join(hh_direct, by = "hhid") %>%
    dplyr::left_join(cmu_hh, by = "hhid") %>%
    dplyr::mutate(
      dplyr::across(
        c(n_salaries_formels, irpp, cnps, cotisations,
          n_salaries_formels_strict, irpp_strict, cnps_strict,
          cotisations_strict,
          n_salaries_formels_large, irpp_large, cnps_large,
          cotisations_large, n_cmu_participants, n_cmu_contributeurs,
          n_salaries_formels_nonrep_diag, irpp_nonrep_diag,
          cnps_nonrep_diag, cotisations_nonrep_diag,
          n_salaries_formels_parts_egales, irpp_parts_egales,
          cnps_parts_egales, cotisations_parts_egales,
          cmu, cmu_universelle),
        ~ dplyr::coalesce(.x, 0)
      ),
      cotisations = cnps + cmu,
      cotisations_strict = cnps_strict + cmu,
      cotisations_large = cnps_large + cmu,
      cotisations_cmu_universelle = cnps + cmu_universelle,
      irpp_real = irpp * def_spa,
      cotisations_real = cotisations * def_spa,
      cnps_real = cnps * def_spa,
      cmu_real = cmu * def_spa,
      cmu_universelle_real = cmu_universelle * def_spa,
      cotisations_cmu_universelle_real =
        cotisations_cmu_universelle * def_spa,
      irpp_strict_real = irpp_strict * def_spa,
      cotisations_strict_real = cotisations_strict * def_spa,
      irpp_large_real = irpp_large * def_spa,
      cotisations_large_real = cotisations_large * def_spa,
      yp_pc_no_dtr = yd_pc + (irpp_real + cotisations_real) / hhsize,
      yn_pc_no_dtr = yd_pc,
      yp_pc_no_dtr_strict = yd_pc +
        (irpp_strict_real + cotisations_strict_real) / hhsize,
      yp_pc_no_dtr_large = yd_pc +
        (irpp_large_real + cotisations_large_real) / hhsize,
      eff_irpp = irpp_real / yd_hh,
      eff_cotis = cotisations_real / yd_hh
    )

  n_orphelins <- nrow(hh_direct) - sum(hh_direct$hhid %in% fiscal$hhid)
  if (n_orphelins > 0)
    warning(sprintf("  %d menages du module emploi absents du fichier fiscal", n_orphelins))

  save_parquet(
    hh %>% dplyr::select(
      hhid, grappe, hhweight, pcweight, decile, quintile, milieu, region,
      pcexp, hhsize, def_spa, yd_pc, yd_hh,
      n_salaries_formels, irpp, cnps, cmu, cotisations,
      irpp_real, cnps_real, cmu_real, cotisations_real,
      n_cmu_participants, n_cmu_contributeurs,
      cmu_universelle, cmu_universelle_real,
      cotisations_cmu_universelle, cotisations_cmu_universelle_real,
      yp_pc_no_dtr, yn_pc_no_dtr,
      n_salaries_formels_strict, irpp_strict, cnps_strict, cotisations_strict,
      irpp_strict_real, cotisations_strict_real, yp_pc_no_dtr_strict,
      n_salaries_formels_large, irpp_large, cnps_large, cotisations_large,
      irpp_large_real, cotisations_large_real, yp_pc_no_dtr_large,
      n_salaries_formels_nonrep_diag, irpp_nonrep_diag,
      n_salaries_formels_parts_egales, irpp_parts_egales,
      eff_irpp, eff_cotis
    ),
    file.path(paths$SILVER, "16", "direct_taxes.parquet")
  )

  # ── 7. Tables par decile ───────────────────────────────────────────────────
  table_decile <- function(var, eff_var) {
    hh %>%
      dplyr::group_by(decile) %>%
      dplyr::summarise(
        n_hh          = dplyr::n(),
        pct_hh_formel = 100 * weighted.mean(n_salaries_formels > 0, hhweight),
        moyenne       = weighted.mean(.data[[var]], hhweight),
        taux_effectif = 100 * weighted.mean(.data[[eff_var]], pcweight),
        masse         = sum(.data[[var]] * hhweight),
        .groups       = "drop"
      ) %>%
      dplyr::mutate(part_masse = 100 * masse / sum(masse))
  }

  irpp_decile  <- table_decile("irpp", "eff_irpp")
  cotis_decile <- table_decile("cotisations", "eff_cotis")

  message("\n  IRPP par decile (taux effectif %, part de la masse %) :")
  print(irpp_decile)

  export_excel(irpp_decile,
               file.path(paths$TABLES, "16", "16_01_irpp_by_decile.xlsx"))
  export_excel(cotis_decile,
               file.path(paths$TABLES, "16", "16_02_cotisations_by_decile.xlsx"))

  # ── 8. Couverture, progressivite (Kakwani), Reynolds-Smolensky ────────────
  # L'agregat de consommation officiel est l'ancre du revenu disponible dans
  # la cascade CEQ. On reconstruit ici les revenus
  # pre-fiscaux en remontant les prelevements; il ne s'agit pas d'assimiler la
  # consommation au Market Income.
  w_ind_sal <- sum(
    ind$hhweight[ind$emploi_salarie_principal], na.rm = TRUE
  )
  w_ind_sal_fiscal <- sum(
    ind$hhweight[
      ind$salaire_principal_bm > 0 | ind$salaire_secondaire_bm > 0
    ],
    na.rm = TRUE
  )
  w_ind_bm <- sum(ind$hhweight[ind$formel_fiscal_bm], na.rm = TRUE)
  w_ind_oit <- sum(ind$hhweight[ind$formel_oit], na.rm = TRUE)
  w_ind_oit_elargi <- sum(
    ind$hhweight[ind$formel_oit_elargi], na.rm = TRUE
  )
  w_ind_strict <- sum(
    ind$hhweight[ind$formel_fiscal_strict], na.rm = TRUE
  )
  w_ind_large <- sum(
    ind$hhweight[ind$formel_fiscal_large], na.rm = TRUE
  )
  w_ind_nonrep_diag <- sum(
    ind$hhweight[ind$formel_fiscal_nonrep_diag], na.rm = TRUE
  )

  formalite_croisee <- ind %>%
    dplyr::filter(emploi_salarie_principal) %>%
    dplyr::group_by(
      bulletin_renseigne = bulletin_paie_renseigne,
      bulletin_paie,
      cotisation_renseignee = cotise_caisse_renseigne,
      cotise_caisse,
      assujetti_scenario_central = formel_principal_bm,
      formel_oit,
      formel_oit_elargi
    ) %>%
    dplyr::summarise(
      observations = dplyr::n(),
      effectif_pondere = sum(hhweight, na.rm = TRUE),
      part_salaries = 100 * effectif_pondere / w_ind_sal,
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(effectif_pondere))

  masse_salaire_principal_bm <- sum(
    ind$salaire_principal_bm * ind$hhweight * ind$formel_principal_bm,
    na.rm = TRUE
  )
  masse_salaire_secondaire_bm <- sum(
    ind$salaire_secondaire_bm * ind$hhweight * ind$formel_secondaire_bm,
    na.rm = TRUE
  )
  masse_irpp_bm <- sum(hh$irpp * hh$hhweight)
  masse_irpp_parts_egales <- sum(hh$irpp_parts_egales * hh$hhweight)

  profile_scenario <- function(df_scenario, scenario, criterion, missing_rule) {
    tibble::tibble(
      scenario = scenario,
      critere_assujettissement = criterion,
      traitement_non_reponse = missing_rule,
      effectif_assujetti_pondere = sum(
        df_scenario$hhweight * df_scenario$assujetti, na.rm = TRUE
      ),
      masse_salariale_milliards = sum(
        df_scenario$hhweight * df_scenario$salaire_assujetti *
          df_scenario$assujetti, na.rm = TRUE
      ) / 1e9,
      irpp_milliards = sum(
        df_scenario$hhweight * df_scenario$irpp_an, na.rm = TRUE
      ) / 1e9,
      cnps_salariale_milliards = sum(
        df_scenario$hhweight * df_scenario$cnps_an, na.rm = TRUE
      ) / 1e9
    )
  }
  scenario_profiles <- dplyr::bind_rows(
    profile_scenario(
      ind_bm, "Central multi-critères",
      "Salaire commun; au moins un indice de traçabilité ou emploi secondaire retenu",
      "Un marqueur manquant n'est jamais recodé positif; d'autres marqueurs observés peuvent classer l'emploi"
    ),
    profile_scenario(
      ind_strict, "Strict",
      "Même salaire commun; bulletin ET cotisation déclarés",
      "Toute non-réponse au bulletin ou à la cotisation vaut critère non satisfait"
    ),
    profile_scenario(
      ind_large, "Élargi",
      "Même salaire commun; bulletin OU cotisation déclaré",
      "Toute non-réponse au bulletin ou à la cotisation vaut critère non satisfait"
    ),
    profile_scenario(
      ind_nonrep_diag, "Diagnostic non-réponse",
      "Même assiette salariale et même classement que le scénario central",
      "Les non-réponses restent manquantes; leurs effectifs sont publiés séparément"
    )
  ) |>
    dplyr::mutate(
      cmu_milliards = sum(hh$cmu * hh$hhweight, na.rm = TRUE) / 1e9,
      cotisations_avec_cmu_milliards = cnps_salariale_milliards + cmu_milliards
    )
  robustesse_assiette <- tibble::tibble(
    indicateur = c(
      "Assujettis, scenario central multi-criteres",
      "Assujettis stricts : bulletin ET cotisation",
      "Assujettis elargis : bulletin OU cotisation",
      "Assujettis dans le diagnostic de non-reponse",
      "Masse IRPP du diagnostic de non-reponse",
      "Variation IRPP du diagnostic de non-reponse",
      "Salaries a salaire positif sans reponse bulletin",
      "Salaries a salaire positif sans reponse cotisation",
      "Masse salariale principale du scenario central",
      "Masse salariale secondaire du scenario central",
      "Part de l'emploi secondaire dans la masse salariale centrale",
      "Masse IRPP, parts des enfants au mieux paye",
      "Masse IRPP, parts des enfants reparties egalement",
      "Variation IRPP liee a l'allocation des parts"
    ),
    valeur = c(
      w_ind_bm, w_ind_strict, w_ind_large, w_ind_nonrep_diag,
      sum(hh$irpp_nonrep_diag * hh$hhweight),
      100 * (
        sum(hh$irpp_nonrep_diag * hh$hhweight) / masse_irpp_bm - 1
      ),
      sum(ind$hhweight[
        ind$salaire_bm > 0 & !ind$bulletin_paie_renseigne
      ], na.rm = TRUE),
      sum(ind$hhweight[
        ind$salaire_bm > 0 & !ind$cotise_caisse_renseigne
      ], na.rm = TRUE),
      masse_salaire_principal_bm,
      masse_salaire_secondaire_bm,
      100 * masse_salaire_secondaire_bm /
        (masse_salaire_principal_bm + masse_salaire_secondaire_bm),
      masse_irpp_bm,
      masse_irpp_parts_egales,
      100 * (masse_irpp_parts_egales / masse_irpp_bm - 1)
    ),
    unite = c(
      rep("personnes ponderees", 4),
      "FCFA/an ponderes", "pourcentage",
      rep("personnes ponderees", 2),
      "FCFA/an ponderes", "FCFA/an ponderes", "pourcentage",
      "FCFA/an ponderes", "FCFA/an ponderes", "pourcentage"
    ),
    statut = c(
      "central", "robustesse", "robustesse", "diagnostic",
      "diagnostic", "diagnostic", "diagnostic", "diagnostic",
      "diagnostic", "diagnostic", "diagnostic", "central",
      "robustesse", "diagnostic"
    )
  )

  description_echantillon <- purrr::imap_dfr(
    list(
      National = fiscal,
      Urbain = dplyr::filter(fiscal, as.integer(milieu) == 1L),
      Rural = dplyr::filter(fiscal, as.integer(milieu) == 2L)
    ),
    function(hh_zone, zone) {
      ind_zone <- dplyr::filter(ind, hhid %in% hh_zone$hhid)
      tibble::tibble(
        zone = zone,
        menages_observes = nrow(hh_zone),
        personnes_observees = nrow(ind_zone),
        menages_ponderes = sum(hh_zone$hhweight, na.rm = TRUE),
        personnes_ponderees = sum(ind_zone$hhweight, na.rm = TRUE),
        taille_menage_moyenne = stats::weighted.mean(
          hh_zone$hhsize, hh_zone$hhweight, na.rm = TRUE
        ),
        age_moyen = stats::weighted.mean(
          ind_zone$age, ind_zone$hhweight, na.rm = TRUE
        ),
        part_moins_18_ans = 100 * stats::weighted.mean(
          ind_zone$age < 18, ind_zone$hhweight, na.rm = TRUE
        ),
        part_salaries_remuneres = 100 * stats::weighted.mean(
          ind_zone$emploi_salarie_principal,
          ind_zone$hhweight, na.rm = TRUE
        ),
        part_assujettis_central = 100 * stats::weighted.mean(
          ind_zone$formel_fiscal_bm, ind_zone$hhweight, na.rm = TRUE
        )
      )
    }
  )

  cmu_diagnostic <- tibble::tibble(
    categorie = c(
      "Participants pauvres non contributifs",
      "Participants non pauvres contributifs",
      "Contributeurs adultes non pauvres",
      "Adultes dans la variante statutaire universelle"
    ),
    cible_administrative = c(
      CMU_CIBLE_PAUVRES, CMU_CIBLE_NON_PAUVRES,
      NA_real_, NA_real_
    ),
    effectif_pondere = c(
      sum(cmu_ind$hhweight[
        cmu_ind$cmu_groupe %in% "pauvre_non_contributif"
      ], na.rm = TRUE),
      sum(cmu_ind$hhweight[
        cmu_ind$cmu_groupe %in% "non_pauvre_contributif"
      ], na.rm = TRUE),
      sum(cmu_ind$hhweight[cmu_ind$cmu_contributeur], na.rm = TRUE),
      sum(cmu_ind$hhweight[
        dplyr::coalesce(cmu_ind$age >= 18, FALSE)
      ], na.rm = TRUE)
    )
  )

  hh_inference <- hh %>%
    dplyr::mutate(
      irpp_pc = irpp_real / hhsize,
      cotisations_pc = cotisations_real / hhsize
    )
  kak_irpp_boot <- bootstrap_kakwani(
    hh_inference, "irpp_pc", "yd_pc", "pcweight",
    cluster_var = "grappe", strata_var = "strata",
    reps = 500, seed = 20240916
  )
  kak_cotis_boot <- bootstrap_kakwani(
    hh_inference, "cotisations_pc", "yd_pc", "pcweight",
    cluster_var = "grappe", strata_var = "strata",
    reps = 500, seed = 20240917
  )
  inference <- tibble::tibble(
    indicateur = c("Kakwani IRPP", "Kakwani cotisations"),
    estimation = c(
      kakwani_index(hh_inference$irpp_pc, hh_inference$yd_pc,
                    hh_inference$pcweight),
      kakwani_index(hh_inference$cotisations_pc, hh_inference$yd_pc,
                    hh_inference$pcweight)
    ),
    ic95_bas = c(kak_irpp_boot$lo, kak_cotis_boot$lo),
    ic95_haut = c(kak_irpp_boot$hi, kak_cotis_boot$hi),
    ecart_type = c(kak_irpp_boot$sd, kak_cotis_boot$sd),
    repetitions_valides = c(kak_irpp_boot$reps_ok, kak_cotis_boot$reps_ok),
    methode = c(kak_irpp_boot$method, kak_cotis_boot$method)
  )

  resume <- tibble::tibble(
    indicateur = c(
      "Salaries avec remuneration brute observee (pondere)",
      "Assujettis selon le scenario central multi-criteres (pondere)",
      "Taux de couverture du scenario central multi-criteres (%)",
      "Assujettis selon le scenario strict (pondere)",
      "Menages avec au moins un assujetti central (%)",
      "Masse IRPP centrale simulee (FCFA/an, pondere)",
      "Masse CNPS centrale simulee (FCFA/an, pondere)",
      "Masse CMU centrale simulee (FCFA/an, pondere)",
      "Masse cotisations centrales simulees (FCFA/an, pondere)",
      "Masse CMU variante statutaire universelle (FCFA/an)",
      "Masse IRPP scenario fiscal strict (FCFA/an)",
      "Masse IRPP scenario fiscal elargi (FCFA/an)",
      'Kakwani IRPP (rang = revenu disponible par tete)',
      "Kakwani cotisations",
      'Gini Y_P reconstitue a rebours (hypothese dtr=0)',
      'Gini Y_N provisoire (revenu disponible, hypothese dtr=0)',
      'Reynolds-Smolensky direct provisoire (hypothese dtr=0)'
    ),
    valeur = c(
      w_ind_sal_fiscal,
      w_ind_bm,
      100 * w_ind_bm / w_ind_sal_fiscal,
      w_ind_strict,
      100 * weighted.mean(hh$n_salaries_formels > 0, hh$hhweight),
      sum(hh$irpp * hh$hhweight),
      sum(hh$cnps * hh$hhweight),
      sum(hh$cmu * hh$hhweight),
      sum(hh$cotisations * hh$hhweight),
      sum(hh$cmu_universelle * hh$hhweight),
      sum(hh$irpp_strict * hh$hhweight),
      sum(hh$irpp_large * hh$hhweight),
      kakwani_index(hh$irpp_real / hh$hhsize, hh$yd_pc, hh$pcweight),
      kakwani_index(hh$cotisations_real / hh$hhsize, hh$yd_pc, hh$pcweight),
      weighted_gini(hh$yp_pc_no_dtr, hh$pcweight),
      weighted_gini(hh$yn_pc_no_dtr, hh$pcweight),
      reynolds_smolensky(hh$yp_pc_no_dtr, hh$yn_pc_no_dtr, hh$pcweight)
    )
  )

  validation_externe <- tibble::tibble(
    agregat = c(
      "IRPP menages simule / impots DGI sur revenus et salaires",
      "Assujettis fiscaux EHCVM / cotisants publics CGRAE projetes"
    ),
    simulation_2021 = c(masse_irpp_bm / 1e9, w_ind_bm),
    reference_administrative_2021 = c(591.6, 268947),
    unite = c("milliards FCFA", "personnes"),
    ratio_simulation_reference_pct = c(
      100 * (masse_irpp_bm / 1e9) / 591.6,
      NA_real_
    ),
    comparabilite = c(
      paste0(
        "Le poste DGI est plus large que l'IRPP des menages : il couvre ",
        "l'ensemble des impots sur revenus et salaires. Le ratio est un ",
        "diagnostic de couverture, pas une cible de calage."
      ),
      paste0(
        "Le scenario EHCVM couvre public et prive, tandis que la reference ",
        "CGRAE ne couvre que les agents publics; aucun ratio n'est calcule."
      )
    ),
    source = c(
      paste0(
        "Ministere de l'Economie et des Finances, statistiques 2021 : ",
        "https://documents.economie-ivoirienne.ci/",
        "index.php?bid=256&fid=266&p=fstream-pdf"
      ),
      paste0(
        "DPBEP 2021-2023, tableau 21, IPS-CGRAE : ",
        "https://budget.gouv.ci/doc/loi/",
        "ANNEXE%203%20%20DOCUMENT%20DE%20PROGRAMMATION%20",
        "BUDGETAIRE%20ET%20ECONOMIQUE%20PLURIANNUELLE%20",
        "%28DPBEP%29%202021%20-%202023.pdf"
      )
    )
  )

  message("\n  Couverture et progressivite :")
  print(as.data.frame(resume))

  export_excel(resume,
               file.path(paths$TABLES, "16", "16_03_coverage_kakwani.xlsx"))
  export_excel(
    formalite_croisee,
    file.path(paths$TABLES, "16", "16_04_formality_definitions.xlsx")
  )
  export_excel(
    inference,
    file.path(paths$TABLES, "16", "16_05_design_inference.xlsx")
  )
  export_excel(
    cmu_diagnostic,
    file.path(paths$TABLES, "16", "16_06_cmu_calibration.xlsx")
  )
  openxlsx::write.xlsx(
    list(
      assiette_et_parts = as.data.frame(robustesse_assiette),
      profils_scenarios = as.data.frame(scenario_profiles),
      recouvrement_criteres = as.data.frame(formalite_croisee)
    ),
    file = file.path(
      paths$TABLES, "16", "16_07_robustness_diagnostics.xlsx"
    ),
    overwrite = TRUE
  )
  message(
    "  → exported: ",
    file.path(paths$TABLES, "16", "16_07_robustness_diagnostics.xlsx")
  )
  export_excel(
    description_echantillon,
    file.path(paths$TABLES, "16", "16_08_sample_description.xlsx")
  )
  export_excel(
    validation_externe,
    file.path(paths$TABLES, "16", "16_09_external_validation.xlsx")
  )

  # ── 9. Figure : charge directe par decile ──────────────────────────────────
  # Le premier denominateur repond a la question distributive CEQ; le second
  # mesure la charge conditionnelle parmi les salaires effectivement assujettis.
  burden_decile <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      irpp_sur_yd = 100 * stats::weighted.mean(eff_irpp, pcweight),
      cotisations_sur_yd = 100 * stats::weighted.mean(eff_cotis, pcweight),
      irpp_sur_salaire = 100 * sum(irpp * hhweight, na.rm = TRUE) /
        sum(salaire_bm_an * hhweight, na.rm = TRUE),
      cotisations_sur_salaire =
        100 * sum(cotisations * hhweight, na.rm = TRUE) /
        sum(salaire_bm_an * hhweight, na.rm = TRUE),
      .groups     = "drop"
    )

  export_excel(
    burden_decile,
    file.path(paths$TABLES, "16", "16_10_burden_denominators.xlsx")
  )

  fig_data <- burden_decile %>%
    tidyr::pivot_longer(
      -decile,
      names_to = c("composante", "denominateur"),
      names_pattern = "(irpp|cotisations)_sur_(yd|salaire)",
      values_to = "taux"
    ) %>%
    dplyr::mutate(
      composante = dplyr::recode(
        composante, irpp = "IRPP", cotisations = "Cotisations"
      ),
      denominateur = dplyr::recode(
        denominateur,
        yd = "En % du revenu disponible",
        salaire = "En % du salaire des assujettis"
      )
    )

  fig16 <- ggplot2::ggplot(
    fig_data,
    ggplot2::aes(x = factor(decile), y = taux, fill = composante)
  ) +
    ggplot2::geom_col(position = "stack", width = 0.75) +
    ggplot2::facet_wrap(~ denominateur, nrow = 1, scales = "free_y") +
    ggplot2::scale_fill_manual(
      values = c("IRPP" = "firebrick", "Cotisations" = "steelblue")
    ) +
    ggplot2::labs(
      title    = "Charge des impots directs et cotisations par decile",
      subtitle = "Scenario central d'assujettissement multi-criteres — EHCVM 2021",
      x        = "Décile de consommation (D1 = plus pauvre)",
      y        = "Taux effectif (%)",
      fill     = NULL,
      caption  = paste0(
        "Assujettis : rémunération positive et indices observés de traçabilité de l'emploi principal ou secondaire.\n",
        "Barèmes CGI 2021 (IS, CN, IGR par quotient familial), CNPS 6,3 % plafonnée ; CMU calibrée sur les effectifs administratifs."
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.caption    = ggplot2::element_text(size = 7)
    )

  export_fig(fig16, file.path(paths$FIGS, "fig16_direct_burden_decile.png"))

  invisible(hh)
}
