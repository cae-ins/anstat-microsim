# utils/informality_anchor.R
#
# OBJECTIF :
# Confronter le profil de transmission effective de la TVA (coefficients alpha
# des scenarios S2 et S3) a une source ivoirienne, au lieu de le laisser
# entierement exogene.
#
# DEUX ANCRAGES INDEPENDANTS :
#
#   1. Ancrage de niveau, par l'offre. Le module 10 de l'EHCVM recense les
#      entreprises non agricoles des menages : code d'activite (s10q17c),
#      chiffre d'affaires des trente derniers jours (s10q46, s10q48, s10q50),
#      mois d'activite (s10q59), clientele principale (s10q44) et surtout
#      immatriculation fiscale (s10q30, numero de compte contribuable). Ces
#      unites ne collectent quasiment jamais la TVA. La part de la consommation
#      marchande des menages qu'elles fournissent borne donc par le haut la part
#      des achats effectivement taxee.
#
#   2. Ancrage de pente, par les valeurs unitaires. Le module 7B enregistre la
#      quantite et la valeur du dernier achat de chaque produit alimentaire. Le
#      prix unitaire implicite qui en resulte peut etre compare entre deciles, a
#      produit, unite et region donnes. Les produits non taxes servent de groupe
#      de controle : leur gradient mesure les effets de qualite et de remise sur
#      quantite. La difference des deux gradients isole la part du gradient de
#      prix imputable au circuit taxe.
#
# CE QUE CES ANCRAGES NE SONT PAS :
# Le module 10 ne couvre que les entreprises DES MENAGES. Il ne mesure pas la
# part de marche du commerce formel constitue en societe. La grandeur obtenue
# est une borne, pas une estimation de alpha. Les tables publiees le disent.
#
# SORTIES : voir build_informality_anchor().


# ── Concordance code d'activite NAEMA vers fonction COICOP ────────────────────
# La nomenclature d'activite du module 10 (s10q17c) est rapprochee des treize
# fonctions COICOP utilisees par la chaine. Le rapprochement porte sur le bien
# ou le service vendu au menage, pas sur le secteur institutionnel du vendeur.
# Les codes sans destination finale identifiable (commerce de gros non
# alimentaire, services aux entreprises, activites extraterritoriales) ne sont
# pas rattaches : leur poids est publie separement.
vat_activity_to_coicop <- function() {
  tibble::tribble(
    ~code_min, ~code_max, ~coicop_num, ~libelle_concordance,
    # Agriculture, elevage, peche, sylviculture : produits alimentaires bruts
    10L,  52L,  1L,  "Agriculture, elevage, peche, sylviculture",
    # Extraction de charbon et de lignite : combustible domestique
    100L, 100L, 4L,  "Charbon et lignite",
    # Fabrication de produits alimentaires
    151L, 159L, 1L,  "Fabrication de produits alimentaires et de boissons",
    160L, 161L, 2L,  "Fabrication du tabac",
    # Textile, habillement, cuir et chaussures
    171L, 192L, 3L,  "Textile, habillement, cuir et chaussures",
    # Bois, papier
    201L, 210L, 5L,  "Bois, vannerie, papier",
    # Raffinage petrolier : carburants
    231L, 231L, 7L,  "Raffinage petrolier",
    243L, 243L, 6L,  "Produits pharmaceutiques",
    244L, 244L, 13L, "Savons, parfums et produits de toilette",
    251L, 252L, 5L,  "Caoutchouc et matieres plastiques",
    261L, 262L, 5L,  "Verre et ceramique domestiques",
    263L, 266L, 4L,  "Ciment, platre et autres mineraux de construction",
    271L, 280L, 5L,  "Metallurgie et ouvrages metalliques",
    281L, 282L, 4L,  "Construction et menuiserie metalliques",
    283L, 296L, 5L,  "Coutellerie, outillage et machines",
    300L, 335L, 8L,  "Materiel electrique, electronique et informatique",
    361L, 361L, 5L,  "Matelas et meubles",
    362L, 362L, 13L, "Fabrication non classee ailleurs",
    # Electricite, gaz, eau, construction
    401L, 410L, 4L,  "Electricite, gaz et eau",
    451L, 457L, 4L,  "Construction et travaux du batiment",
    # Commerce et reparation liees aux moyens de transport, carburants
    501L, 506L, 7L,  "Commerce et reparation de vehicules, carburants",
    # Commerce de gros a destination finale identifiable
    512L, 512L, 1L,  "Commerce de gros de produits agricoles bruts",
    513L, 513L, 3L,  "Commerce de gros d'articles de menage et d'habillement",
    # Commerce de detail
    521L, 523L, 1L,  "Commerce de detail alimentaire et general",
    524L, 524L, 3L,  "Commerce de detail d'habillement et de chaussures",
    525L, 525L, 8L,  "Commerce de detail d'articles electroniques",
    527L, 527L, 5L,  "Reparation d'articles personnels et domestiques",
    # Hebergement et restauration
    551L, 553L, 11L, "Hotels, restaurants et debits de boisson",
    # Transports
    601L, 634L, 7L,  "Transports de personnes et de marchandises",
    # Postes, telecommunications, informatique
    641L, 643L, 8L,  "Postes et telecommunications",
    721L, 729L, 8L,  "Activites informatiques",
    # Finance et assurance. Le code 654, services de transfert d'argent, est
    # volontairement exclu : le montant declare est le volume transfere et non
    # la remuneration du service, ce qui gonflerait l'offre d'un facteur de
    # plusieurs dizaines.
    651L, 653L, 12L, "Services financiers et d'assurance",
    655L, 672L, 12L, "Services financiers et d'assurance",
    # Immobilier et location
    701L, 702L, 4L,  "Services de logement",
    712L, 713L, 5L,  "Location de machines et d'articles domestiques",
    # Enseignement, sante, action sociale
    801L, 809L, 10L, "Enseignement",
    851L, 853L, 6L,  "Sante humaine, veterinaire et action sociale",
    # Assainissement, culture, services personnels, personnel domestique
    900L, 900L, 4L,  "Assainissement et gestion des dechets",
    921L, 929L, 9L,  "Culture, loisirs et sport",
    930L, 930L, 13L, "Services personnels",
    950L, 950L, 5L,  "Personnel domestique employe par les menages"
  )
}


# ── Ancrage de niveau : part de l'offre assuree par des unites non immatriculees
informality_supply_anchor <- function(paths, conso_item) {

  entreprises_path <- source_file_path(
    "Datain", "Menage", "s10_2_me_CIV2021.dta",
    label = "Module 10 entreprises non agricoles"
  )
  brut <- haven::read_dta(
    entreprises_path,
    col_select = c("grappe", "menage", "s10q17c", "s10q29", "s10q30", "s10q31",
                   "s10q44", "s10q46", "s10q48", "s10q50", "s10q58", "s10q59")
  )

  # Ponderation et milieu proviennent du fichier menage deja utilise partout.
  menages <- conso_item |>
    dplyr::distinct(hhid, hhweight, milieu, region)

  entreprises <- brut |>
    dplyr::transmute(
      hhid = as.numeric(grappe) * 100 + as.numeric(menage),
      code_activite = as.integer(s10q17c),
      comptabilite = as.integer(s10q29) == 1L,
      immatriculee_ncc = as.integer(s10q30) == 1L,
      registre_commerce = as.integer(s10q31) == 1L,
      clientele = as.integer(s10q44),
      active = as.integer(s10q58) == 1L,
      mois_actifs = pmin(pmax(dplyr::coalesce(as.numeric(s10q59), 0), 0), 12),
      ca_mensuel = dplyr::coalesce(as.numeric(s10q46), 0) +
        dplyr::coalesce(as.numeric(s10q48), 0) +
        dplyr::coalesce(as.numeric(s10q50), 0)
    ) |>
    dplyr::filter(!is.na(code_activite)) |>
    dplyr::mutate(
      active = dplyr::coalesce(active, FALSE),
      ca_annuel = ca_mensuel * mois_actifs
    ) |>
    dplyr::inner_join(menages, by = "hhid")

  # La clientele principale « Menage/Particulier » porte le code 6 du module.
  # Le libelle est verifie plutot que suppose.
  libelles_clientele <- attr(brut$s10q44, "labels")
  code_menage <- unname(libelles_clientele[
    grepl("nage|articulier", names(libelles_clientele))
  ])
  if (length(code_menage) != 1L) {
    stop("La modalite de clientele « Menage/Particulier » n'est pas identifiee.",
         call. = FALSE)
  }

  concordance <- vat_activity_to_coicop()
  attribuer_coicop <- function(code) {
    idx <- vapply(code, function(x) {
      hit <- which(concordance$code_min <= x & x <= concordance$code_max)
      if (length(hit) == 0L) NA_integer_ else hit[[1]]
    }, integer(1))
    concordance$coicop_num[idx]
  }
  entreprises <- entreprises |>
    dplyr::mutate(
      coicop_num = attribuer_coicop(code_activite),
      vend_aux_menages = clientele == code_menage,
      ca_pondere = ca_annuel * hhweight
    )

  # Diagnostics de couverture : ce qui est retenu et ce qui ne l'est pas.
  diagnostics <- tibble::tibble(
    indicateur = c(
      "Entreprises recensees", "Entreprises actives",
      "Entreprises vendant principalement aux menages",
      "Part du chiffre d'affaires non rattachee a une fonction COICOP (%)",
      "Entreprises avec numero de compte contribuable",
      "Part du chiffre d'affaires des unites immatriculees (%)",
      "Entreprises tenant une comptabilite ecrite",
      "Entreprises inscrites au registre du commerce"
    ),
    valeur = c(
      nrow(entreprises),
      sum(entreprises$active, na.rm = TRUE),
      sum(entreprises$active & entreprises$vend_aux_menages, na.rm = TRUE),
      100 * sum(entreprises$ca_pondere[entreprises$active &
        entreprises$vend_aux_menages & is.na(entreprises$coicop_num)]) /
        sum(entreprises$ca_pondere[entreprises$active &
          entreprises$vend_aux_menages]),
      sum(dplyr::coalesce(entreprises$immatriculee_ncc, FALSE)),
      100 * sum(entreprises$ca_pondere[
        dplyr::coalesce(entreprises$immatriculee_ncc, FALSE)]) /
        sum(entreprises$ca_pondere),
      sum(dplyr::coalesce(entreprises$comptabilite, FALSE)),
      sum(dplyr::coalesce(entreprises$registre_commerce, FALSE))
    )
  )

  # Offre des entreprises de menages non immatriculees, par fonction COICOP.
  offre <- entreprises |>
    dplyr::filter(active, vend_aux_menages, !is.na(coicop_num)) |>
    dplyr::mutate(
      non_immatriculee = !dplyr::coalesce(immatriculee_ncc, FALSE)
    ) |>
    dplyr::group_by(coicop_num) |>
    dplyr::summarise(
      offre_menages_milliards = sum(ca_pondere) / 1e9,
      offre_non_immatriculee_milliards = sum(ca_pondere[non_immatriculee]) / 1e9,
      entreprises = dplyr::n(),
      .groups = "drop"
    )

  offre_milieu <- entreprises |>
    dplyr::filter(active, vend_aux_menages, !is.na(coicop_num)) |>
    dplyr::mutate(
      non_immatriculee = !dplyr::coalesce(immatriculee_ncc, FALSE),
      milieu = as.character(milieu)
    ) |>
    dplyr::group_by(coicop_num, milieu) |>
    dplyr::summarise(
      offre_non_immatriculee_milliards = sum(ca_pondere[non_immatriculee]) / 1e9,
      entreprises = dplyr::n(),
      .groups = "drop"
    )

  # Denominateur : consommation marchande des menages par fonction, meme
  # enquete et memes ponderations que le numerateur.
  demande <- conso_item |>
    dplyr::mutate(coicop_num = as.integer(as.character(coicop))) |>
    dplyr::group_by(coicop_num) |>
    dplyr::summarise(
      consommation_marchande_milliards = sum(depan_w * hhweight, na.rm = TRUE) / 1e9,
      .groups = "drop"
    )
  demande_milieu <- conso_item |>
    dplyr::mutate(coicop_num = as.integer(as.character(coicop)),
                  milieu = as.character(milieu)) |>
    dplyr::group_by(coicop_num, milieu) |>
    dplyr::summarise(
      consommation_marchande_milliards = sum(depan_w * hhweight, na.rm = TRUE) / 1e9,
      .groups = "drop"
    )

  borne <- demande |>
    dplyr::left_join(offre, by = "coicop_num") |>
    dplyr::mutate(
      dplyr::across(c(offre_menages_milliards, offre_non_immatriculee_milliards),
                    ~ dplyr::coalesce(.x, 0)),
      entreprises = dplyr::coalesce(entreprises, 0L),
      ratio_offre_consommation =
        offre_non_immatriculee_milliards / consommation_marchande_milliards,
      part_offre_non_immatriculee = pmin(ratio_offre_consommation, 1),
      alpha_borne_superieure = 1 - part_offre_non_immatriculee,
      # Une borne n'est exploitable que si la concordance ne sur-attribue pas
      # l'offre a la fonction et si le nombre d'entreprises suffit. Un ratio
      # superieur a un signale que le rapprochement d'activites envoie vers la
      # fonction plus de chiffre d'affaires que la consommation observee : la
      # borne vaut alors zero pour une raison de nomenclature, pas d'economie.
      couverture_suffisante = entreprises >= 30L,
      borne_saturee = ratio_offre_consommation >= 1,
      borne_exploitable = couverture_suffisante & !borne_saturee
    ) |>
    dplyr::arrange(coicop_num)

  borne_milieu <- demande_milieu |>
    dplyr::left_join(offre_milieu, by = c("coicop_num", "milieu")) |>
    dplyr::mutate(
      offre_non_immatriculee_milliards =
        dplyr::coalesce(offre_non_immatriculee_milliards, 0),
      entreprises = dplyr::coalesce(entreprises, 0L),
      part_offre_non_immatriculee = pmin(
        offre_non_immatriculee_milliards / consommation_marchande_milliards, 1),
      alpha_borne_superieure = 1 - part_offre_non_immatriculee
    ) |>
    dplyr::arrange(coicop_num, milieu)

  list(borne = borne, borne_milieu = borne_milieu,
       concordance = concordance, diagnostics = diagnostics)
}


# ── Ancrage de pente : gradient des valeurs unitaires par decile ──────────────
vat_unit_value_gradient <- function(paths, conso_item, hh_decile) {

  module_path <- source_file_path(
    "Datain", "Menage", "s07b_me_CIV2021.dta",
    label = "Module 7B consommation alimentaire"
  )
  brut <- haven::read_dta(
    module_path,
    col_select = c("grappe", "menage", "s07bq01", "s07bq07a", "s07bq07b",
                   "s07bq07c", "s07bq08")
  )

  achats <- brut |>
    dplyr::transmute(
      hhid = as.numeric(grappe) * 100 + as.numeric(menage),
      codpr = as.numeric(s07bq01),
      quantite = as.numeric(s07bq07a),
      unite = as.integer(s07bq07b),
      taille = as.integer(s07bq07c),
      valeur = as.numeric(s07bq08)
    ) |>
    dplyr::filter(is.finite(quantite), quantite > 0,
                  is.finite(valeur), valeur > 0, !is.na(unite)) |>
    dplyr::mutate(prix_unitaire = valeur / quantite,
                  taille = dplyr::coalesce(taille, 0L))

  # Statut fiscal du produit : la table de correspondance de l'etape 2 est deja
  # portee par les donnees de consommation nettoyees.
  statut <- conso_item |>
    dplyr::distinct(codpr, r_vat_official, hors_champ) |>
    dplyr::filter(!is.na(r_vat_official))

  achats <- achats |>
    dplyr::inner_join(dplyr::distinct(statut), by = "codpr") |>
    dplyr::inner_join(
      hh_decile |> dplyr::select(hhid, decile, hhweight, milieu, region) |>
        dplyr::distinct(),
      by = "hhid"
    ) |>
    dplyr::mutate(
      taxe = as.integer(hors_champ == 0 & r_vat_official > 0),
      cellule = paste(codpr, unite, taille, as.character(region), sep = "_")
    )

  # Faisabilite : une cellule n'est exploitable que si elle contient assez
  # d'observations pour estimer un gradient de prix par decile.
  cellules <- achats |>
    dplyr::group_by(cellule, taxe) |>
    dplyr::summarise(observations = dplyr::n(),
                     deciles_distincts = dplyr::n_distinct(decile),
                     .groups = "drop")
  cellules_exploitables <- cellules |>
    dplyr::filter(observations >= 20L, deciles_distincts >= 5L)
  faisabilite <- tibble::tibble(
    indicateur = c(
      "Achats alimentaires exploitables",
      "Cellules produit x unite x taille x region",
      "Cellules exploitables (20 observations et 5 deciles au moins)",
      "Cellules exploitables sur produits taxes",
      "Cellules exploitables sur produits non taxes",
      "Part des achats portant sur un produit taxe (%)"
    ),
    valeur = c(
      nrow(achats),
      dplyr::n_distinct(cellules$cellule),
      dplyr::n_distinct(cellules_exploitables$cellule),
      sum(cellules_exploitables$taxe == 1L),
      sum(cellules_exploitables$taxe == 0L),
      100 * mean(achats$taxe == 1L)
    )
  )

  # Gradient : le prix unitaire relatif est mesure a l'interieur de chaque
  # cellule, ce qui neutralise le produit, l'unite, le conditionnement et la
  # region. On regresse ensuite le logarithme du prix relatif sur le rang de
  # decile, separement pour les produits taxes et non taxes.
  echantillon <- achats |>
    dplyr::filter(cellule %in% cellules_exploitables$cellule) |>
    dplyr::group_by(cellule) |>
    dplyr::mutate(
      prix_relatif = log(prix_unitaire) -
        stats::weighted.mean(log(prix_unitaire), hhweight)
    ) |>
    dplyr::ungroup()

  # Un seul modele en interaction plutot que deux regressions separees : les
  # deux groupes partagent les memes grappes, si bien que la difference des
  # deux pentes n'aurait pas d'erreur type correcte si elle etait recomposee.
  echantillon$grappe_cluster <- floor(echantillon$hhid / 100)
  modele <- stats::lm(prix_relatif ~ decile * taxe, data = echantillon,
                      weights = echantillon$hhweight)
  test <- lmtest::coeftest(
    modele, vcov. = sandwich::vcovCL(modele, cluster = echantillon$grappe_cluster))
  extraire <- function(terme, etiquette, observations) {
    tibble::tibble(
      groupe = etiquette, observations = observations,
      pente_par_decile = unname(test[terme, "Estimate"]),
      erreur_type = unname(test[terme, "Std. Error"]),
      p_value = unname(test[terme, "Pr(>|t|)"])
    )
  }
  n_taxe <- sum(echantillon$taxe == 1L)
  n_non_taxe <- sum(echantillon$taxe == 0L)
  pente_non_taxe <- extraire("decile", "Produits non taxes", n_non_taxe)
  ecart <- extraire("decile:taxe", "Difference taxes moins non taxes",
                    nrow(echantillon))
  pente_taxe <- tibble::tibble(
    groupe = "Produits taxes", observations = n_taxe,
    pente_par_decile = pente_non_taxe$pente_par_decile + ecart$pente_par_decile,
    erreur_type = NA_real_, p_value = NA_real_
  )
  gradient <- dplyr::bind_rows(pente_taxe, pente_non_taxe, ecart) |>
    dplyr::mutate(
      lecture = "Pente du logarithme du prix unitaire relatif par rang de decile"
    )

  # Confrontation au profil S3. Si une part alpha des achats supporte la taxe au
  # taux tau, le prix moyen paye vaut (1 + alpha x tau) fois le prix hors taxe.
  # Une pente d'alpha par decile implique donc une pente de prix d'environ
  # tau x d(alpha) / (1 + alpha x tau). Le gradient de prix observe teste ainsi
  # directement l'ordre de grandeur postule par S3.
  taux_moyen_taxe <- stats::weighted.mean(
    echantillon$r_vat_official[echantillon$taxe == 1L],
    echantillon$hhweight[echantillon$taxe == 1L])
  parametres_alimentaires <- vat_alpha_decile_parameters() |>
    dplyr::filter(coicop_num == 1L)
  alpha_median_s3 <- parametres_alimentaires$alpha_d1 +
    4.5 * parametres_alimentaires$slope
  pente_prix_impliquee_s3 <- taux_moyen_taxe * parametres_alimentaires$slope /
    (1 + alpha_median_s3 * taux_moyen_taxe)
  confrontation <- tibble::tibble(
    grandeur = c("Taux de TVA moyen des produits taxes retenus",
                 "Pente alpha par decile postulee par S3 (alimentation)",
                 "Pente de prix impliquee par S3",
                 "Pente de prix observee (difference taxes moins non taxes)",
                 "Borne basse de l'intervalle a 95 % de la pente observee",
                 "Borne haute de l'intervalle a 95 % de la pente observee",
                 "La pente impliquee par S3 est dans l'intervalle observe"),
    valeur = c(
      taux_moyen_taxe, parametres_alimentaires$slope, pente_prix_impliquee_s3,
      ecart$pente_par_decile,
      ecart$pente_par_decile - 1.96 * ecart$erreur_type,
      ecart$pente_par_decile + 1.96 * ecart$erreur_type,
      as.numeric(
        pente_prix_impliquee_s3 >= ecart$pente_par_decile - 1.96 * ecart$erreur_type &
        pente_prix_impliquee_s3 <= ecart$pente_par_decile + 1.96 * ecart$erreur_type)
    )
  )

  list(faisabilite = faisabilite, gradient = gradient,
       confrontation = confrontation)
}


# ── Orchestration : tables publiees et table alpha du scenario ancre ──────────
build_informality_anchor <- function(paths, conso_item, hh_decile) {

  message("  Ancrage ivoirien du profil d'informalite...")

  offre <- informality_supply_anchor(paths, conso_item)
  valeurs_unitaires <- vat_unit_value_gradient(paths, conso_item, hh_decile)

  # Confrontation au profil exogene : alpha moyen de S3 par fonction, pondere
  # par la depense, contre la borne superieure ivoirienne.
  alpha_s3 <- vat_alpha_decile_parameters() |>
    dplyr::left_join(
      conso_item |>
        dplyr::mutate(coicop_num = as.integer(as.character(coicop))) |>
        # Le decile peut deja etre porte par les donnees d'articles; on le
        # retire avant la jointure pour eviter des colonnes suffixees.
        dplyr::select(-dplyr::any_of("decile")) |>
        dplyr::left_join(dplyr::select(hh_decile, hhid, decile), by = "hhid") |>
        dplyr::group_by(coicop_num) |>
        dplyr::summarise(
          decile_moyen_depense = stats::weighted.mean(
            decile, depan_w * hhweight, na.rm = TRUE),
          .groups = "drop"),
      by = "coicop_num"
    ) |>
    dplyr::mutate(
      alpha_s3_moyen = pmin(alpha_d1 + (decile_moyen_depense - 1) * slope, 1)
    ) |>
    dplyr::select(coicop_num, alpha_s3_moyen)

  alpha_s2 <- vat_alpha_milieu_parameters() |>
    dplyr::transmute(coicop_num,
                     alpha_s2_moyen = (alpha_rural + alpha_urban) / 2)

  comparaison <- offre$borne |>
    dplyr::left_join(alpha_s3, by = "coicop_num") |>
    dplyr::left_join(alpha_s2, by = "coicop_num") |>
    dplyr::mutate(
      s3_au_dessus_de_la_borne = alpha_s3_moyen > alpha_borne_superieure,
      ecart_s3_borne = alpha_s3_moyen - alpha_borne_superieure
    )

  # Scenario S4 : alpha fixe a la borne superieure ivoirienne la ou celle-ci est
  # exploitable, et laisse au coefficient de S3 sinon. La borne n'a pas de
  # dimension de niveau de vie, faute d'information sur l'acheteur du cote de
  # l'offre : elle est donc constante sur les deciles pour les fonctions
  # ancrees. Le resultat majore la charge de TVA compatible avec l'offre
  # observee; ce n'est pas une estimation ponctuelle de alpha.
  bornes_exploitables <- offre$borne |>
    dplyr::filter(borne_exploitable) |>
    dplyr::select(coicop_num, alpha_borne_superieure)
  alpha_s4 <- tidyr::crossing(
      vat_alpha_decile_parameters(), tibble::tibble(decile = 1:10)) |>
    dplyr::mutate(alpha_s3 = pmin(alpha_d1 + (decile - 1) * slope, 1)) |>
    dplyr::left_join(bornes_exploitables, by = "coicop_num") |>
    dplyr::mutate(
      ancree = !is.na(alpha_borne_superieure),
      alpha_4 = dplyr::if_else(ancree, alpha_borne_superieure, alpha_s3)
    ) |>
    dplyr::select(coicop_num, decile, alpha_4, ancree)
  # Les postes hors champ de consommation (98 valeur d'usage, 99 ceremonies) ne
  # portent aucune TVA dans les autres scenarios non plus.
  alpha_s4$alpha_4[alpha_s4$coicop_num %in% c(98L, 99L)] <- 0

  notes <- tibble::tibble(
    champ = c("nature", "source", "portee", "limite", "traitement des saturations",
              "usage"),
    valeur = c(
      "Borne superieure ivoirienne sur la part des achats effectivement taxee",
      "EHCVM 2021, module 10 (entreprises non agricoles des menages) et module de consommation",
      "Les unites du module 10 ne collectent quasiment jamais la TVA : la part de la consommation qu'elles fournissent ne peut pas etre taxee",
      "Le module 10 ne couvre pas le commerce formel constitue en societe : la borne ne mesure pas la part de marche du secteur formel",
      "Une fonction dont l'offre rapprochee depasse la consommation observee, ou qui compte moins de trente entreprises, est declaree non exploitable et conserve le coefficient de S3",
      "Le scenario S4 majore la charge de TVA compatible avec l'offre observee et ne remplace pas S3"
    )
  )

  openxlsx::write.xlsx(
    list(
      borne_par_fonction = as.data.frame(offre$borne),
      borne_par_milieu = as.data.frame(offre$borne_milieu),
      comparaison_s2_s3 = as.data.frame(comparaison),
      concordance_activites = as.data.frame(offre$concordance),
      diagnostics = as.data.frame(offre$diagnostics),
      notes = as.data.frame(notes)
    ),
    file = file.path(paths$TABLES, "06", "06_04_informality_anchor_supply.xlsx"),
    overwrite = TRUE
  )
  openxlsx::write.xlsx(
    list(
      faisabilite = as.data.frame(valeurs_unitaires$faisabilite),
      gradient = as.data.frame(valeurs_unitaires$gradient),
      confrontation_s3 = as.data.frame(valeurs_unitaires$confrontation)
    ),
    file = file.path(paths$TABLES, "06", "06_05_unit_value_gradient.xlsx"),
    overwrite = TRUE
  )

  message(sprintf(
    "    Offre des entreprises de menages : %.1f %% du chiffre d'affaires non rattache a une fonction",
    offre$diagnostics$valeur[offre$diagnostics$indicateur ==
      "Part du chiffre d'affaires non rattachee a une fonction COICOP (%)"]))
  message(sprintf(
    "    Bornes exploitables : %d fonctions sur %d; S3 depasse la borne dans %d cas",
    sum(comparaison$borne_exploitable, na.rm = TRUE), nrow(comparaison),
    sum(comparaison$borne_exploitable & comparaison$s3_au_dessus_de_la_borne,
        na.rm = TRUE)))

  list(alpha_s4 = alpha_s4, comparaison = comparaison,
       gradient = valeurs_unitaires$gradient,
       faisabilite = valeurs_unitaires$faisabilite)
}
