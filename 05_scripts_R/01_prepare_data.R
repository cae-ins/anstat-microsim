# 01_prepare_data.R
#
# OBJECTIF :
# Construire un jeu de donnees de depenses propre et coherent pour l'analyse de l'incidence TVA.
#
# ETAPES CLES :
# 1. Charger les donnees de consommation EHCVM brutes
# 2. Valider les identifiants
# 3. Restreindre aux transactions marchandes (modep == 1)
# 4. Winsoriser la depense au 99e percentile
# 5. Exporter les tableaux et figures diagnostiques
# 6. Sauvegarder le jeu de donnees nettoy en parquet
#
# ENTREE:  DATA/ehcvm_conso_civ2021.dta  (niveau item: hhid × produit)
# SORTIE: SILVER/01/conso_clean.parquet
#
# AUTEUR: Armand Kouakou Djaha, MSc (version Stata originale)
# Traduction R: rewrite-r branch

prepare_data <- function(paths) {

  message(">>> ETAPE 1: Chargement des donnees de consommation brutes")

  df <- load_raw_dta("ehcvm_conso_CIV2021.dta")
  assert_required_columns(
    df,
    c("hhid", "codpr", "modep", "depan"),
    object_name = "ehcvm_conso_CIV2021.dta"
  )

  # ── Valider les identifiants ──────────────────────────────────────────────────
  stopifnot(
    "hhid doit etre non manquant" = !anyNA(df$hhid),
    "codpr doit etre non manquant" = !anyNA(df$codpr)
  )
  message(sprintf("  Lignes: %s | Menages: %s | Produits: %s",
                  format(nrow(df), big.mark = ","),
                  format(dplyr::n_distinct(df$hhid), big.mark = ","),
                  format(dplyr::n_distinct(df$codpr), big.mark = ",")))

  # ── Statistiques resumees sur depan brut ──────────────────────────────────────
  summary_raw <- df %>%
    dplyr::summarise(
      N        = dplyr::n(),
      Mean     = mean(depan, na.rm = TRUE),
      SD       = sd(depan, na.rm = TRUE),
      P1       = quantile(depan, 0.01, na.rm = TRUE),
      P5       = quantile(depan, 0.05, na.rm = TRUE),
      P10      = quantile(depan, 0.10, na.rm = TRUE),
      P25      = quantile(depan, 0.25, na.rm = TRUE),
      Median   = quantile(depan, 0.50, na.rm = TRUE),
      P75      = quantile(depan, 0.75, na.rm = TRUE),
      P90      = quantile(depan, 0.90, na.rm = TRUE),
      P95      = quantile(depan, 0.95, na.rm = TRUE),
      P99      = quantile(depan, 0.99, na.rm = TRUE),
      Min      = min(depan, na.rm = TRUE),
      Max      = max(depan, na.rm = TRUE),
      Skewness = (mean((depan - mean(depan, na.rm = TRUE))^3, na.rm = TRUE) /
                  sd(depan, na.rm = TRUE)^3),
      Kurtosis = (mean((depan - mean(depan, na.rm = TRUE))^4, na.rm = TRUE) /
                  sd(depan, na.rm = TRUE)^4)
    ) %>%
    tidyr::pivot_longer(dplyr::everything(),
                        names_to = "stat", values_to = "depan")

  export_excel(summary_raw,
               file.path(paths$TABLES, "01", "summary_depan_raw.xlsx"))

  # ── Restreindre aux transactions marchandes ────────────────────────────────
  # modep: 1=Achat 2=Autoconsommation 3=Don 4=Valeur d'usage 5=Loyer impute
  # La TVA s'applique uniquement aux transactions marchandes (methode CEQ)
  message(">>> Restriction a la consommation basee sur le marche (modep == 1)")
  df <- df %>% dplyr::filter(modep == 1)
  message(sprintf("  Lignes apres filtre: %s", format(nrow(df), big.mark = ",")))

  # ── Winsoriser au 99e percentile ─────────────────────────────────────────
  p99  <- quantile(df$depan, 0.99, na.rm = TRUE)
  df   <- df %>%
    dplyr::mutate(
      log_depan = log(depan),
      depan_w   = pmin(depan, p99)
    )

  # ── Figure diagnostique: distribution log(depan) ───────────────────────────
  p_logdepan <- ggplot2::ggplot(df, ggplot2::aes(x = log_depan)) +
    ggplot2::geom_histogram(bins = 60, fill = "steelblue",
                             color = "white", alpha = 0.8) +
    ggplot2::labs(
      title   = "Distribution de log(depan) apres nettoyage",
      subtitle = "Achats sur marche uniquement (modep == 1)",
      x = "log(depense annuelle par item, CFA)",
      y = "Effectif"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  export_fig(p_logdepan,
             file.path(paths$FIGS, "log_depan_af_cleaning.png"))

  # ── Decoder les labels codpr (equivalent Stata: decode codpr, gen(produit)) ─
  codpr_labels <- attr(df$codpr, "labels")
  if (!is.null(codpr_labels)) {
    label_lookup <- setNames(names(codpr_labels), as.character(codpr_labels))
    df$produit <- label_lookup[as.character(as.double(df$codpr))]
  }
  df$codpr <- as.double(df$codpr)

  # ── Mapper codpr vers la division COICOP (nomenclature EHCVM-II CIV2021) ────────
  # Base sur la structure du questionnaire EHCVM et la classification COICOP-HBS
  df$coicop <- dplyr::case_when(
    # 1 - Nouriture et boissons non alcoolisees
    df$codpr %in% 1:163   ~ 1L,
    df$codpr %in% 166:177  ~ 1L,
    # 2 - Boissons alcoolisees, tabac
    df$codpr %in% c(164, 165, 197, 201, 301, 302) ~ 2L,
    # 3 - Vetements et chaussures
    df$codpr == 401        ~ 3L,    # reparateur de chaussures
    df$codpr %in% 501:521  ~ 3L,
    # 4 - Logement, eau, electricite, gaz, combustibles
    df$codpr %in% 202:207  ~ 4L,    # kerosene, charbon, bois, bougies
    df$codpr %in% 303:305  ~ 4L,    # gaz, carburant groupe, batteries
    df$codpr %in% 330:334  ~ 4L,    # loyer, eau, electricite
    df$codpr %in% 601:602  ~ 4L,    # entretien du logement
    df$codpr %in% 609:612  ~ 4L,    # frais de raccordement services
    df$codpr %in% 618:619  ~ 4L,    # panneaux solaires
    # 5 - Ameublement, equipement menager, entretien courant
    df$codpr == 217        ~ 5L,    # mouture cereale s
    df$codpr %in% 306:310  ~ 5L,    # savon, detergent, insecticide, femme de menage, lessive
    df$codpr == 402        ~ 5L,    # ampoules
    df$codpr %in% 613:617  ~ 5L,    # mobilier, linge de maison
    df$codpr %in% 620:625  ~ 5L,    # Reparation appareil, batterie de cuisine, ustensiles
    # 6 - Sante
    df$codpr == 416        ~ 6L,    # medicaments OTC
    df$codpr == 419        ~ 6L,    # contraceptifs
    df$codpr %in% 761:777  ~ 6L,    # consultations, examens, hospitalisation
    # 7 - Transport
    df$codpr %in% 208:215  ~ 7L,    # carburant, transport urbain
    df$codpr %in% 311:312  ~ 7L,    # lavage voiture, parking
    df$codpr %in% 403:407  ~ 7L,    # lubricants, Reparation voiture, transport interurbain
    df$codpr == 421        ~ 7L,    # pedage
    df$codpr %in% 626:636  ~ 7L,    # achat vehicule, pieces, assurance, location, voyage
    # 8 - Information et communication
    df$codpr == 313        ~ 8L,    # cabine telephonique
    df$codpr %in% 335:338  ~ 8L,    # telephone, internet, cable TV, recharge mobile
    df$codpr %in% 408:409  ~ 8L,    # poste, fax
    df$codpr == 420        ~ 8L,    # photocopies
    df$codpr %in% 637:641  ~ 8L,    # telephone, achat electronique, Reparation
    # 9 - Loisir, sport, culture
    df$codpr == 216        ~ 9L,    # journaux
    df$codpr %in% 314:315  ~ 9L,    # loterie, magazines
    df$codpr %in% 410:414  ~ 9L,    # jardinage, animaux domestique s, sport, cinema
    df$codpr %in% 642:644  ~ 9L,    # articles de sport, livres, papeterie
    # 10 - Education
    df$codpr %in% 646:647  ~ 10L,   # formation professionnelle, cours particulier
    df$codpr %in% 701:748  ~ 10L,   # tous les niveaux d'education
    # 11 - Restaurants et hebergement
    df$codpr %in% 191:196  ~ 11L,   # repas hors maison
    df$codpr == 648        ~ 11L,   # hotel
    # 12 - Assurance et services financiers
    df$codpr %in% 652:657  ~ 12L,   # assurance, frais administratifs
    # 13 - Soins personnels, protection sociale, divers
    df$codpr %in% 316:324  ~ 13L,   # coiffure, produits hygieniques, hygiene personnelle
    df$codpr == 415        ~ 13L,   # masque COVID lavable
    df$codpr %in% 417:418  ~ 13L,   # parfum, brosse a dents
    df$codpr %in% 645:645  ~ 13L,   # pelerinage
    df$codpr %in% 649:651  ~ 13L,   # montres, bijoux, effets personnels
    df$codpr == 658        ~ 13L,   # autres services (funerailles, etc.)
    # 98 - Non-consommation: valeur d'usage des biens durables
    df$codpr %in% 801:843  ~ 98L,
    # 99 - Non-consommation: ceremonies
    df$codpr %in% 901:912  ~ 99L,
    # Residuel
    TRUE                   ~ 99L
  )
  message(sprintf("  COICOP assigne: %d obs | Manquant: %d",
                  sum(!is.na(df$coicop)), sum(is.na(df$coicop))))

  # ── Convertir les colonnes labellees Stata en facteurs ──────────────────
  df <- haven::as_factor(df)

  # ── Sauvegarder le jeu de donnees nettoy ──────────────────────────────────────────────────
  message(">>> Sauvegarde du jeu de donnees de consommation nettoy")
  save_parquet(df, file.path(paths$SILVER, "01", "conso_clean.parquet"))

  invisible(df)
}