# =============================================================================
# Etape 15 - Taxation de la vente finale a 9 % avec vecteur c constant
#
# La simulation croise trois ensembles de produits (agricoles, commerce, tous
# les produits eligibles) et trois hypotheses de paiement/transmission de la
# TVA (strict, S2 milieu x COICOP, S3 decile x COICOP). Pour chaque combinaison,
# elle estime l'effet brut et un benchmark budgetairement neutre qui recycle la
# recette sous forme d'un transfert universel par personne.
# =============================================================================

source("05_scripts_R/00_setup.R")

TAUX_REFORME <- 0.09
SECTEURS_HORS_REFORME <- c("E", "L", "P", "Q", "T")
REPS_BOOT <- 500L

dir.create(file.path(SILVER, "15"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(TABLES, "15"), recursive = TRUE, showWarnings = FALSE)

conc <- read_source_csv(
  path_parts = "concordance_codpr_ICIO.csv",
  .label = "codpr-ICIO concordance",
  .required_cols = c("codpr", "secteur_ICIO")
) %>%
  dplyr::filter(secteur_ICIO != "hors_champ") %>%
  dplyr::distinct(codpr, secteur_ICIO)

conso <- load_parquet(file.path(SILVER, "01", "conso_clean.parquet")) %>%
  dplyr::select(
    hhid, codpr, coicop, milieu, depan_w, r_vat_official
  )

base <- load_parquet(
  file.path(SILVER, "04", "fiscal_data_analysis_ready.parquet")
) %>%
  dplyr::filter(
    is.finite(yd_pc), is.finite(zref), hhsize > 0,
    is.finite(hhweight), is.finite(def_spa)
  ) %>%
  dplyr::mutate(quintile = ceiling(decile / 2))

assert_required_columns(
  base,
  c("hhid", "grappe", "strata", "hhweight", "pcweight", "hhsize",
    "yd_pc", "yd_hh", "zref", "def_spa", "decile", "quintile"),
  object_name = "fiscal_data_analysis_ready.parquet"
)

eligible_codpr <- conso %>%
  dplyr::filter(r_vat_official == 0) %>%
  dplyr::left_join(conc, by = "codpr") %>%
  dplyr::filter(
    !secteur_ICIO %in% SECTEURS_HORS_REFORME | is.na(secteur_ICIO)
  ) %>%
  dplyr::distinct(codpr, secteur_ICIO)

scenarios <- list(
  S_agri = eligible_codpr %>%
    dplyr::filter(secteur_ICIO %in% c("A01_02", "A03")) %>%
    dplyr::pull(codpr),
  S_commerce = eligible_codpr %>%
    dplyr::filter(secteur_ICIO == "G") %>%
    dplyr::pull(codpr),
  S_all = eligible_codpr$codpr
)

items <- conso %>%
  dplyr::left_join(
    base %>% dplyr::select(hhid, decile),
    by = "hhid"
  ) %>%
  dplyr::mutate(
    alpha_strict = 1,
    alpha_s2 = vat_alpha_milieu(coicop, milieu),
    alpha_s3 = vat_alpha_decile(coicop, decile)
  )

calcule_choc <- function(codpr_cibles, scenario) {
  items %>%
    dplyr::filter(codpr %in% codpr_cibles) %>%
    tidyr::pivot_longer(
      c(alpha_strict, alpha_s2, alpha_s3),
      names_to = "hypothese", values_to = "alpha"
    ) %>%
    dplyr::mutate(
      hypothese = dplyr::recode(
        hypothese,
        alpha_strict = "strict", alpha_s2 = "S2", alpha_s3 = "S3"
      ),
      # A taux initial nul, la depense observee est la base hors taxe.
      delta_vat_nominal = depan_w * alpha * TAUX_REFORME
    ) %>%
    dplyr::group_by(hhid, hypothese) %>%
    dplyr::summarise(
      delta_vat_nominal = sum(delta_vat_nominal, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(scenario = scenario)
}

chocs <- purrr::imap_dfr(scenarios, calcule_choc)

prepare_combinaison <- function(scenario, hypothese) {
  choc <- chocs %>%
    dplyr::filter(
      .data$scenario == .env$scenario,
      .data$hypothese == .env$hypothese
    ) %>%
    dplyr::select(hhid, delta_vat_nominal)

  hh <- base %>%
    dplyr::left_join(choc, by = "hhid") %>%
    dplyr::mutate(
      delta_vat_nominal = tidyr::replace_na(delta_vat_nominal, 0),
      delta_vat_reel = delta_vat_nominal * def_spa,
      yd_pc_sans_recyclage = yd_pc - delta_vat_reel / hhsize,
      charge_relative = delta_vat_reel / yd_hh
    )

  recette <- sum(hh$delta_vat_nominal * hh$hhweight, na.rm = TRUE)
  population <- sum(hh$hhsize * hh$hhweight, na.rm = TRUE)
  transfert_pc_nominal <- recette / population

  hh %>%
    dplyr::mutate(
      scenario = scenario,
      hypothese = hypothese,
      recette_nominale = recette,
      transfert_pc_nominal = transfert_pc_nominal,
      yd_pc_recyclage = yd_pc_sans_recyclage +
        transfert_pc_nominal * def_spa
    )
}

cles <- tidyr::crossing(
  scenario = names(scenarios),
  hypothese = c("strict", "S2", "S3")
)

combinaisons <- purrr::map2(
  cles$scenario, cles$hypothese, prepare_combinaison
)
names(combinaisons) <- paste(cles$scenario, cles$hypothese, sep = "__")

# Les neuf contrefactuels portent sur les memes menages, dans le meme ordre.
# Reutiliser les memes poids Rao-Wu permet donc une inference appariee entre
# reformes et hypotheses d'informalite, tout en evitant neuf tirages identiques.
set.seed(20241500)
poids_bootstrap_hh <- replicate(
  REPS_BOOT,
  rao_wu_weights(base, "hhweight", "grappe", "strata")
)

resume_fgt <- function(hh, poids_bootstrap = poids_bootstrap_hh) {
  reps <- ncol(poids_bootstrap)
  point <- function(y) {
    c(
      p0 = fgt_index(y, hh$zref, hh$pcweight, 0),
      p1 = fgt_index(y, hh$zref, hh$pcweight, 1),
      p2 = fgt_index(y, hh$zref, hh$pcweight, 2)
    )
  }
  avant <- point(hh$yd_pc)
  apres_brut <- point(hh$yd_pc_sans_recyclage)
  apres_recycle <- point(hh$yd_pc_recyclage)

  boot <- vapply(seq_len(reps), function(b) {
    w_hh <- poids_bootstrap[, b]
    w_pc <- w_hh * hh$hhsize
    recette_b <- sum(hh$delta_vat_nominal * w_hh, na.rm = TRUE)
    transfert_b <- recette_b / sum(w_pc, na.rm = TRUE)
    y_recycle_b <- hh$yd_pc_sans_recyclage + transfert_b * hh$def_spa
    p_avant <- vapply(0:2, function(a) {
      fgt_index(hh$yd_pc, hh$zref, w_pc, a)
    }, numeric(1))
    c(
      brut = vapply(0:2, function(a) {
        fgt_index(hh$yd_pc_sans_recyclage, hh$zref, w_pc, a)
      }, numeric(1)) - p_avant,
      recycle = vapply(0:2, function(a) {
        fgt_index(y_recycle_b, hh$zref, w_pc, a)
      }, numeric(1)) - p_avant
    )
  }, numeric(6))

  delta_point <- rbind(
    sans_recyclage = apres_brut - avant,
    recyclage_universel = apres_recycle - avant
  )
  noms_boot <- c("brut", "recycle")

  purrr::map_dfr(seq_len(2), function(i) {
    lignes <- (3 * (i - 1) + 1):(3 * i)
    tibble::tibble(
      recyclage = rownames(delta_point)[i],
      indicateur = c("P0", "P1", "P2"),
      avant = avant,
      apres = if (i == 1) apres_brut else apres_recycle,
      delta = delta_point[i, ],
      ic95_bas = apply(boot[lignes, , drop = FALSE], 1, stats::quantile, 0.025),
      ic95_haut = apply(boot[lignes, , drop = FALSE], 1, stats::quantile, 0.975),
      methode = "Rao-Wu rescaled bootstrap",
      repetitions = reps,
      bloc_bootstrap = noms_boot[i]
    )
  })
}

fgt_national <- purrr::imap_dfr(combinaisons, function(hh, cle) {
  resultat <- resume_fgt(hh)
  dplyr::mutate(
    resultat,
    scenario = hh$scenario[1],
    hypothese = hh$hypothese[1],
    .before = 1
  )
})

burden_quintile <- purrr::map_dfr(combinaisons, function(hh) {
  hh %>%
    dplyr::group_by(quintile) %>%
    dplyr::summarise(
      charge_moyenne_nominale = stats::weighted.mean(
        delta_vat_nominal, hhweight
      ),
      charge_relative = stats::weighted.mean(charge_relative, pcweight),
      recette_nominale = sum(delta_vat_nominal * hhweight),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      scenario = hh$scenario[1], hypothese = hh$hypothese[1],
      part_recette = recette_nominale / sum(recette_nominale)
    )
})

fgt_quintile <- purrr::map_dfr(combinaisons, function(hh) {
  hh %>%
    dplyr::group_by(quintile) %>%
    dplyr::summarise(
      p0_avant = fgt_index(yd_pc, zref, pcweight, 0),
      p0_sans_recyclage = fgt_index(
        yd_pc_sans_recyclage, zref, pcweight, 0
      ),
      p0_recyclage = fgt_index(yd_pc_recyclage, zref, pcweight, 0),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      scenario = hh$scenario[1], hypothese = hh$hypothese[1],
      delta_p0_brut = p0_sans_recyclage - p0_avant,
      delta_p0_recycle = p0_recyclage - p0_avant
    )
})

nouveaux_pauvres <- purrr::map_dfr(combinaisons, function(hh) {
  pauvre_avant <- hh$yd_pc < hh$zref
  tibble::tibble(
    scenario = hh$scenario[1],
    hypothese = hh$hypothese[1],
    recyclage = c("sans_recyclage", "recyclage_universel"),
    nouveaux_menages_pauvres = c(
      sum((!pauvre_avant & hh$yd_pc_sans_recyclage < hh$zref) * hh$hhweight),
      sum((!pauvre_avant & hh$yd_pc_recyclage < hh$zref) * hh$hhweight)
    ),
    nouveaux_individus_pauvres = c(
      sum((!pauvre_avant & hh$yd_pc_sans_recyclage < hh$zref) * hh$pcweight),
      sum((!pauvre_avant & hh$yd_pc_recyclage < hh$zref) * hh$pcweight)
    ),
    individus_sortis_pauvrete = c(
      0,
      sum((pauvre_avant & hh$yd_pc_recyclage >= hh$zref) * hh$pcweight)
    )
  )
})

budget <- purrr::map_dfr(combinaisons, function(hh) {
  transferts <- hh$transfert_pc_nominal[1] *
    sum(hh$pcweight, na.rm = TRUE)
  tibble::tibble(
    scenario = hh$scenario[1], hypothese = hh$hypothese[1],
    recette_nominale = hh$recette_nominale[1],
    transfert_pc_nominal = hh$transfert_pc_nominal[1],
    transferts_totaux = transferts,
    solde = hh$recette_nominale[1] - transferts
  )
})

export_excel(
  fgt_national,
  file.path(TABLES, "15", "15_01_fgt_reform_national.xlsx")
)
export_excel(
  burden_quintile,
  file.path(TABLES, "15", "15_02_burden_by_quintile.xlsx")
)
export_excel(
  fgt_quintile,
  file.path(TABLES, "15", "15_03_fgt_by_quintile.xlsx")
)
export_excel(
  nouveaux_pauvres,
  file.path(TABLES, "15", "15_04_nouveaux_pauvres_reform.xlsx")
)
export_excel(
  budget,
  file.path(TABLES, "15", "15_05_budget_neutral_recycling.xlsx")
)

hh_all <- purrr::map_dfr(combinaisons, function(hh) {
  hh %>%
    dplyr::select(
      hhid, grappe, strata, hhweight, pcweight, hhsize, decile, quintile,
      yd_pc, zref, def_spa, delta_vat_nominal, delta_vat_reel,
      charge_relative, transfert_pc_nominal,
      yd_pc_sans_recyclage, yd_pc_recyclage, scenario, hypothese
    )
})
save_parquet(hh_all, file.path(SILVER, "15", "reform_vat_hh.parquet"))

fig_burden <- burden_quintile %>%
  dplyr::filter(hypothese == "S3") %>%
  ggplot2::ggplot(
    ggplot2::aes(
      x = factor(quintile), y = 100 * charge_relative, fill = scenario
    )
  ) +
  ggplot2::geom_col(position = "dodge", width = 0.75) +
  ggplot2::scale_fill_manual(
    values = c(S_agri = "#2F6B4F", S_commerce = "#4472A8", S_all = "#B0473C")
  ) +
  ggplot2::labs(
    title = "Charge brute de la reforme TVA par quintile",
    subtitle = "Scenario central S3 : paiement et transmission par produit et decile",
    x = "Quintile", y = "Charge additionnelle (% du revenu disponible)",
    fill = NULL,
    caption = "Taxation de la vente finale a 9 %, vecteur de TVA incorporee c constant. Montants convertis par le deflateur spatial EHCVM."
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(legend.position = "bottom")

fig_fgt <- fgt_national %>%
  dplyr::filter(hypothese == "S3", indicateur == "P0") %>%
  ggplot2::ggplot(
    ggplot2::aes(x = scenario, y = 100 * delta, fill = recyclage)
  ) +
  ggplot2::geom_col(position = "dodge", width = 0.7) +
  ggplot2::geom_errorbar(
    ggplot2::aes(ymin = 100 * ic95_bas, ymax = 100 * ic95_haut),
    position = ggplot2::position_dodge(width = 0.7), width = 0.16
  ) +
  ggplot2::scale_fill_manual(
    values = c(sans_recyclage = "#B0473C", recyclage_universel = "#2F6B4F")
  ) +
  ggplot2::labs(
    title = "Effet de la reforme TVA sur la pauvrete",
    subtitle = "Scenario central S3, avec intervalles a 95 % Rao-Wu",
    x = NULL, y = "Variation de P0 (points de pourcentage)", fill = NULL
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(legend.position = "bottom")

export_fig(fig_burden, file.path(FIGS, "fig_reform_burden_quintile.png"))
export_fig(fig_fgt, file.path(FIGS, "fig_reform_fgt_impact.png"))

message("Etape 15 terminee : vente finale a 9 %, c constant, S2/S3 et recyclage neutre.")
