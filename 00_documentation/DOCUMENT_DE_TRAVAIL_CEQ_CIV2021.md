---
title: "Microsimulation fiscale CEQ — Côte d'Ivoire (EHCVM 2021)"
subtitle: "Document de travail : méthodologie, pipeline R et résultats — TVA, matrice entrées-sorties et impôts directs"
author: "Cellule d'Analyses Économiques — ANStat"
date: "Juillet 2026"
lang: fr
toc: true
toc-depth: 2
numbersections: true
---

# Résumé exécutif

Ce document de travail présente la méthodologie complète et les résultats du modèle de
microsimulation fiscale de type *Commitment to Equity* (CEQ) construit pour la Côte
d'Ivoire à partir de l'Enquête Harmonisée sur les Conditions de Vie des Ménages
(EHCVM 2021). Le modèle est implémenté sous la forme d'un pipeline R reproductible de
16 étapes (branche `rewrite-r`), réécriture complète du pipeline Stata original.

Principaux résultats :

- **La TVA simulée représente environ 1 502 milliards de FCFA** de charge annuelle pour
  les ménages, soit un taux effectif moyen d'environ 12 % de la consommation marchande —
  nettement en dessous du taux légal de 18 %, du fait des exonérations et du taux réduit.
- **La progressivité de la TVA dépend de l'hypothèse d'informalité.** Sous pass-through
  complet (α = 1), la TVA est légèrement régressive (Kakwani = −0,006, IC bootstrap à
  95 % : [−0,009 ; −0,003]). Dès que l'on tient compte de la courbe d'Engel de
  l'informalité (Bachas, Gadenne & Jensen 2024), elle devient progressive
  (Kakwani = +0,031 à +0,064).
- **La TVA accroît fortement la pauvreté monétaire mesurée** : le taux de pauvreté (P0)
  passe de 37,5 % avant TVA à 44,5 % après TVA directe (scénario strict), et jusqu'à
  **53,7 %** lorsque la TVA enchâssée dans les consommations intermédiaires est mesurée
  avec la matrice entrées-sorties locale (TRE 2023).
- **La matrice I/O locale double la TVA enchâssée estimée** par rapport à la matrice
  OCDE ICIO : 255 956 FCFA/ménage/an contre 128 997 FCFA.
- **Une réforme portant les produits exonérés à 9 %** ferait basculer environ 80 000
  personnes sous le seuil de pauvreté (+1,45 point de P0) dans le scénario le plus large.
- **Nouveau — impôts directs (étape 16)** : l'IRPP (IS + CN + IGR) et les cotisations
  CNPS/CMU simulés sur les salariés formels représentent respectivement 290 et 163
  milliards de FCFA. Ils sont fortement progressifs (Kakwani = +0,37 et +0,33) : le
  décile supérieur acquitte 61,6 % de la masse IRPP. Leur effet redistributif global
  reste modeste (Reynolds-Smolensky = −0,007) car seuls 25 % des salariés — moins de
  10 % des ménages — sont dans l'emploi formel.

---

# Contexte et objectifs

## Le cadre Commitment to Equity

Le cadre CEQ (Lustig et al., CEQ Handbook) mesure l'incidence des impôts et des
dépenses publiques sur la distribution des revenus et la pauvreté. Il repose sur la
construction en cascade de sept concepts de revenu :

```
Y_M   Market Income        = revenu de marché (ici : proxy consommation)
Y_NM  Net Market Income    = Y_M − impôts directs − cotisations        ← étape 16 ✅
Y_G   Gross Income         = Y_NM + pensions contributives              [à venir]
Y_T   Taxable Income       = Y_G                                        [à venir]
Y_D   Disposable Income    = Y_T + transferts non contributifs          [à venir]
Y_C   Consumable Income    = Y_D − TVA − accises − douanes + subsides   ← TVA couverte ✅
Y_F   Final Income         = Y_C + éducation + santé (en nature)        [à venir]
```

Conformément à la pratique CEQ pour les pays où le revenu est difficilement mesurable
(CEQ Handbook, ch. 6 ; Hill et al. 2017 pour l'Éthiopie), le revenu de marché est
proxié par la **consommation totale winsorisée** (`conso_w`). La seule étude CEQ
publiée sur la Côte d'Ivoire (Akim, Ben Jelloul, Czajka & Robilliard, AFD 2020, sur
l'ENV 2014) sert de point de comparaison.

## Objectifs du modèle

1. Mesurer l'incidence distributive de la TVA ivoirienne (taux effectifs par décile,
   progressivité, sensibilité à l'informalité).
2. Quantifier l'impact de la TVA — directe et enchâssée — sur la pauvreté (FGT).
3. Simuler des réformes fiscales (TVA intrants avicoles, extension du taux de 9 %).
4. Étendre progressivement le modèle vers un CEQ complet (impôts directs — fait —,
   accises, transferts, dépenses en nature).

---

# Données

| Source | Fichier | Usage |
|---|---|---|
| EHCVM 2021 — consommation | `ehcvm_conso_CIV2021.dta` | 787 410 lignes de dépenses (hhid × produit × mode d'acquisition) |
| EHCVM 2021 — bien-être | `ehcvm_welfare_2b_CIV2021.dta` | `pcexp` (dépense par tête officielle), `zref` (seuil de pauvreté), `hhsize` |
| EHCVM 2021 — individus | `ehcvm_individu_CIV2021.dta` | 64 491 individus : salaires annuels harmonisés, état civil, âge |
| EHCVM 2021 — module emploi (s04) | `s04_me_CIV2021.dta` | Flags de formalité : bulletin de paie (s04q42), cotisation CGRAE/CNPS (s04q38) |
| Mapping TVA | `COPR_EHCVM_TVA_renseigne.xlsx` | Taux de TVA statutaire par produit `codpr` (18 % / 9 % / 0 %) |
| Matrice I/O internationale | OCDE ICIO 2023 (CIV 2020), 45 secteurs ISIC Rev.4 | TVA enchâssée (étape 13) |
| Matrice I/O locale | TRE 2023 Côte d'Ivoire (+ TRE constant, scénario de robustesse) | TVA enchâssée locale (étape 13b) |
| Barèmes fiscaux 2021 | CGI (IS, CN, IGR), CNPS, CMU | Impôts directs (étape 16) |

L'échantillon d'analyse compte **12 965 ménages**. Traitements amont : restriction aux
transactions marchandes (`modep == 1`, la TVA ne portant ni sur l'autoconsommation ni
sur les dons), winsorisation des dépenses au 99e percentile, validation des
identifiants et des schémas de colonnes à chaque lecture.

---

# Architecture du pipeline R

Le pipeline (dossier `05_scripts_R/`) suit une architecture en couches type
« medallion » orchestrée à la manière du modèle INES (INSEE) :

- `00_setup.R` — chemins (`DATA`, `SILVER`, `GOLD`, `TABLES`, `FIGS`), packages,
  utilitaires ; `00_master.R` — table d'enchaînement des 17 étapes et orchestrateur
  `lance_pipeline(première, dernière)`.
- `utils/io.R` — couche I/O commune : `load_raw_dta()` (locale ou MinIO),
  `save_parquet()`, `export_excel()`, `export_fig()`, validations
  (`assert_required_columns`, `assert_local_file_exists`).
- `utils/distributive.R` — indices pondérés cohérents avec `conindex` de Stata :
  Gini, indice de concentration, Kakwani, Reynolds-Smolensky, `weighted_ntile`,
  bootstrap de Kakwani (500 réplications).
- Chaque étape lit ses entrées en parquet (couche SILVER `02_data_intermediate/NN/`),
  écrit ses tables en Excel (`07_reports/tables/NN/`) et ses figures en PNG
  (`07_reports/figures/`).

| Bloc | Étapes | Contenu |
|---|---|---|
| 0 — Fondations | 01–03 | Nettoyage, mapping TVA, incidence ménage |
| 1 — Analyse TVA | 04–09 | Distribution, progressivité, sensibilité, déterminants |
| 2 — Réformes TVA | 10–15 | Réforme avicole, Leontief I/O, réforme 0 %→9 % |
| A — Impôts directs | 16 (fait), 17 | IRPP + cotisations ; accises/douanes à venir |
| B–E | 18–25 | Transferts, subsides, en nature, synthèse CEQ |

---

# Méthodologie et résultats par étape

## Étape 01 — Préparation des données (`01_prepare_data.R`)

Chargement de la consommation brute, restriction aux achats marchands, winsorisation
de `depan` au P99 (le maximum brut atteint 25 millions de FCFA pour une médiane de
15 643 FCFA, skewness 45,5), diagnostics exportés. Sortie :
`SILVER/01/conso_clean.parquet` (niveau ménage × produit, avec taux TVA et poids).

## Étape 02 — Mapping TVA (`02_mapping_tax.R`)

Affectation à chaque produit `codpr` de son taux de TVA statutaire (18 % taux normal,
9 % taux réduit — lait, pâtes, matériels solaires… —, 0 % exonérations : produits
alimentaires de base, santé, éducation) depuis le classeur officiel
`COPR_EHCVM_TVA_renseigne.xlsx`.

## Étape 03 — Incidence TVA ménage (`03_compute_taxes.R`)

Hypothèse d'incidence statique avec transfert complet sur les consommateurs :
`vat_item = depan_w × r_vat_official`, agrégé par ménage. Concepts :
`market_income = conso_w` ; `consumable_income = conso_w − vat_w`.

## Étape 04 — Analyse distributive (`04_analysis.R`)

Classement des ménages en déciles/quintiles pondérés de `conso_w` (`weighted_ntile`).

| Décile | Conso. moyenne (FCFA) | TVA moyenne (FCFA) | Part de la TVA totale |
|---|---:|---:|---:|
| 1 (plus pauvre) | 422 435 | 54 111 | 2,3 % |
| 5 | 1 477 399 | 178 785 | 7,7 % |
| 10 (plus riche) | 4 852 597 | 577 190 | 24,8 % |

Le quintile supérieur acquitte 41,6 % de la TVA totale ; l'urbain 68,7 % (contre
31,3 % pour le rural). Masse totale simulée : **≈ 1 502 milliards de FCFA**.

## Étape 05 — Progressivité (`05_progressivity.R`)

Indices pondérés au rang fractionnaire (règle du point médian, équivalent
`conindex`) : Gini de la consommation 0,356 ; indice de concentration de la TVA
0,350 ; **Kakwani = −0,006** ; Reynolds-Smolensky = +0,001. Sous pass-through
complet, la TVA ivoirienne est donc **quasi proportionnelle, très légèrement
régressive**.

## Étape 06 — Sensibilité (`06_01`, `06_02`)

**06_01 — Scénarios d'informalité.** Le scénario strict (α = 1) suppose que tout achat
supporte la TVA. Deux scénarios alternatifs pondèrent le pass-through par la
probabilité d'achat formel, suivant la courbe d'Engel de l'informalité (IEC) de
Bachas, Gadenne & Jensen (2024, REStud) : S2 (α par COICOP × milieu urbain/rural) et
S3 (α linéaire selon le décile, par COICOP).

| Scénario | Kakwani | IC bootstrap 95 % | Lecture |
|---|---:|---|---|
| Strict (α = 1) | −0,006 | [−0,009 ; −0,003] | Légèrement régressive |
| S2 — CEI × milieu | +0,031 | [+0,027 ; +0,036] | Progressive |
| S3 — IEC × décile | +0,064 | [+0,060 ; +0,067] | Progressive |

**Le signe de la progressivité de la TVA n'est pas robuste à l'hypothèse
d'informalité** : les ménages pauvres achetant davantage dans des circuits informels
échappent de fait à une partie de la TVA.

**06_02 — Sensibilité aux classements.** En classant les ménages par consommation par
tête ou par adulte-équivalent (AE1, AE2) plutôt que par consommation totale, la TVA
devient progressive même dans le scénario strict (Kakwani = +0,019 à +0,029). Le
choix du classement de bien-être importe donc autant que l'hypothèse de taxation.

## Étape 07–08 — Tableaux annexes et figures

Tables détaillées par décile/quintile/milieu/région et par fonction COICOP ; figures
fig1–fig4 (taux effectifs par scénario, courbes de concentration, TVA par COICOP,
profils α de l'IEC).

## Étape 09 — Déterminants de la TVA effective (`09_vat_determinants.R`)

Régressions OLS du taux de TVA effectif, erreurs-types clusterisées par grappe. Dans
le scénario strict, le taux effectif décroît avec la consommation (élasticité
négative), la taille du ménage et le chef de ménage féminin, et croît en milieu
urbain. Dans S3 (informalité par décile), le gradient de consommation s'inverse
(+0,008, significatif) : la TVA effective devient croissante avec le niveau de vie.

## Étape 10–11 — Réforme des intrants avicoles

Simulation de la suppression de l'exonération de TVA sur les intrants avicoles
(provende, poussins…), avec transmission partielle aux prix du poulet (paramètres
α × s). La part budgétaire du poulet croît avec le niveau de vie (0,06 % de la
consommation en D1, 0,93 % en D10) : la mesure est **progressive**
(Kakwani = +0,24) et son impact pauvreté est négligeable (+0,01 point de P0,
≈ 280–480 nouveaux pauvres selon le scénario). Le décile 10 supporterait 45 % de la
charge additionnelle.

## Étape 12 — Incidence de la TVA sur la pauvreté (`12_poverty_incidence.R`)

Indices FGT (P0, P1, P2) calculés sur `pcexp_après = pcexp − vat/hhsize`, seuil
ménage-spécifique `zref`, poids population `hhweight × hhsize`.

| Concept | P0 | P1 | P2 |
|---|---:|---:|---:|
| Avant TVA (pcexp officiel) | 37,5 % | 10,4 % | 4,1 % |
| Après TVA — Strict | 44,5 % | 13,0 % | 5,3 % |
| Après TVA — S2 | 40,8 % | 11,5 % | 4,5 % |
| Après TVA — S3 | 40,5 % | 11,4 % | 4,5 % |

La TVA directe ajoute donc **+3,0 à +7,1 points de pauvreté** selon l'hypothèse
d'informalité. L'effet est plus marqué en milieu rural (P0 : 54,5 % → 61,8 % en
strict) qu'urbain (22,2 % → 29,0 %). Les basculements sous le seuil se concentrent
dans les déciles 4 à 8 (jusqu'à 58 000 ménages pondérés par décile).

## Étape 13 — TVA enchâssée : modèle de prix de Leontief (`13_leontief_io.R`)

Les exonérations de TVA ne suppriment pas la TVA payée sur les intrants : celle-ci
reste « enchâssée » dans les prix. Le modèle de prix de Leontief la mesure :
`Δp = (I − A')⁻¹ · t`, où `A` est la matrice des coefficients techniques (OCDE ICIO
2023, 45 secteurs, condition de Hawkins-Simon vérifiée) et `t` le vecteur de taux de
TVA effectifs par secteur (agrégés depuis le mapping `codpr` via une concordance
codpr → ICIO). La TVA enchâssée par ménage vaut la hausse de prix appliquée à son
panier hors TVA directe.

## Étape 14 — Pauvreté avec TVA enchâssée (`14_leontief_poverty.R`)

| Concept | P0 | Δ P0 |
|---|---:|---:|
| Avant TVA | 37,5 % | — |
| TVA directe (strict) | 44,5 % | +7,1 pts |
| TVA directe + enchâssée I/O (strict) | 48,8 % | +11,3 pts |

Avec la matrice OCDE, la TVA enchâssée ajoute environ 4 points de pauvreté
supplémentaires : **l'exonération ne protège que partiellement les ménages pauvres.**

## Étape 13b/14b — Matrice I/O locale (TRE 2023)

L'utilisation des Tableaux des Ressources et des Emplois ivoiriens de 2023 en
remplacement de la matrice OCDE change substantiellement le diagnostic :

| Indicateur | OCDE ICIO (13/14) | TRE local 2023 (13b/14b) |
|---|---:|---:|
| TVA enchâssée moyenne (FCFA/ménage/an) | 128 997 | **255 956** |
| Masse TVA enchâssée (FCFA/an) | 831 mds | **1 650 mds** |
| P0 total (directe + enchâssée) | 48,8 % | **53,7 %** |

La structure productive locale incorpore bien plus de taxes indirectes dans les prix
finaux que ne le suggère la matrice internationale. La charge totale (directe +
enchâssée) est quasi proportionnelle : 17,3 % du revenu en Q1 contre 20,2 % en Q5,
la composante enchâssée pesant même légèrement plus lourd, en proportion, vers le
milieu de la distribution. Le TRE constant 2023 (scénario de robustesse) donne des
résultats très proches (P0 total 54,2 %).

## Étape 15 — Réforme TVA : passage des produits exonérés à 9 % (`15_reform_vat_simulation.R`)

Simulation d'un taux de 9 % appliqué aux produits actuellement à 0 % :
S_agri (produits agricoles bruts, 60 produits), S_all (tous les exonérés hors
services publics, 91 produits).

| Scénario | Δ P0 | Nouveaux pauvres | dont Q1+Q2 |
|---|---:|---:|---:|
| S_agri | +0,84 pt | 46 107 | 33,5 % |
| S_all | +1,45 pt | 80 211 | 33,1 % |

La charge relative maximale porte sur le 4e quintile (1,94 % du revenu en S_all) :
la mesure serait quasi proportionnelle sur le haut de la distribution mais ferait
basculer un nombre substantiel de ménages modestes sous le seuil de pauvreté.

## Étape 16 — Impôts directs et cotisations sociales (`16_direct_taxes.R`) — **nouveau**

### Méthode

Construction du **Net Market Income** = `market_income − irpp − cotisations`.
Barèmes CGI 2021 (documentés dans `00_documentation/methodologie/MEMOIRE_FISCAL_CIV2021.md`),
appliqués mensuellement puis annualisés :

1. **Impôt sur les Salaires (IS)** : 1,5 % de la base imposable BI = 0,8 × SBI,
   soit 1,2 % du salaire brut imposable.
2. **Contribution Nationale (CN)** : barème par tranches mensuelles sur BI —
   0 % jusqu'à 50 000 FCFA ; 1,5 % de 50 à 130 000 ; 5 % de 130 à 200 000 ;
   10 % au-delà.
3. **Impôt Général sur le Revenu (IGR)** : base R = 0,8 × (SBI − IS − CN) ;
   quotient familial N (célibataire 1 part, marié 2, veuf 1,5, +0,5 par enfant de
   moins de 18 ans, plafond 5 parts) ; barème mensuel en 10 tranches sur Q = R/N ;
   réduction finale de 15 %.
4. **CNPS (part salariée)** : retraite 6,3 % du SBI plafonné à 1 647 315 FCFA/mois.
5. **CMU** : retenue salariale simulée de 500 FCFA/mois.

**Assiette et assujettissement.** Le salaire annuel harmonisé de l'emploi principal
(`salaire`, fichier individus) sert d'assiette ; seuls les salariés **formels
stricts** — bulletin de paie (s04q42 = 1) **et** cotisation CGRAE/CNPS (s04q38 = 1)
— sont assujettis (scénario central). Un scénario « élargi » (bulletin **ou**
cotisation) borne la simulation par le haut. L'emploi secondaire est exclu
(formalité inobservée) : l'estimation est une borne basse. Les enfants à charge sont
attribués au salarié formel le mieux rémunéré du ménage.

Le script Stata de référence de la Banque mondiale (`ressources_CEQ/02. CIV21WBN_dtx.do`)
encode un barème IGR de *proposition de réforme* (0/16/21/24/28/32 %) et non le
barème CGI en vigueur en 2021 ; c'est pourquoi le barème par quotient de la mémoire
fiscale du projet a été retenu.

### Résultats

**Couverture.** 4 564 salariés déclarent un salaire positif dans l'EHCVM ; 966
(21,2 % ; 25,0 % en pondéré) sont formels stricts. Seuls **9,8 % des ménages**
comptent au moins un salarié formel — c'est la limite structurelle de l'impôt direct
en contexte de forte informalité (cf. Lustig 2017 ; SOUTHMOD 2021).

| Indicateur | Valeur |
|---|---:|
| Masse IRPP simulée (IS + CN + IGR) | 290,3 mds FCFA/an |
| Masse cotisations simulées (CNPS + CMU) | 162,7 mds FCFA/an |
| Masse IRPP — scénario élargi | 326,7 mds FCFA/an |
| Kakwani IRPP | **+0,373** |
| Kakwani cotisations | **+0,329** |
| Gini market income → net market income | 0,356 → 0,349 |
| Reynolds-Smolensky | **−0,007** |

**Incidence par décile.** Le profil est fortement progressif : le taux effectif
IRPP passe de 0,15 % de la consommation en D1 à 5,05 % en D10, et le décile
supérieur — où 39,2 % des ménages ont un salarié formel, contre 0,7 % en D1 —
acquitte **61,6 % de la masse IRPP** et 54,4 % des cotisations.

| Décile | % ménages avec salarié formel | Taux effectif IRPP | Part masse IRPP |
|---|---:|---:|---:|
| 1 | 0,7 % | 0,15 % | 0,2 % |
| 5 | 4,2 % | 0,47 % | 1,5 % |
| 8 | 14,7 % | 1,55 % | 8,9 % |
| 10 | 39,2 % | 5,05 % | 61,6 % |

**Lecture CEQ.** Les impôts directs ivoiriens sont très progressifs mais leur
capacité redistributive globale est bridée par leur assiette étroite : la baisse du
Gini n'est que de 0,7 point (RS = −0,007), conforme au constat de Lustig (2017)
selon lequel les impôts directs jouent un rôle redistributif marginal en Afrique
subsaharienne. Ordre de grandeur : la masse simulée (290 mds) est cohérente avec
les recettes d'impôts sur salaires de la DGI (≈ 300–350 mds FCFA en 2021), ce qui
valide l'hypothèse de couverture retenue.

*(Note technique : pour 19 ménages, salaire déclaré élevé et consommation modeste
rendent le net négatif ; le Gini du net est calculé après troncature à zéro,
pratique standard CEQ.)*

---

# Figures principales

![Taux de TVA effectif par décile — trois scénarios d'informalité](07_reports/figures/fig1_eff_vat_three_scenarios.png)

![Courbes de concentration de la TVA](07_reports/figures/fig2_concentration_curves.png)

![TVA par fonction COICOP](07_reports/figures/fig3_vat_by_coicop.png)

![Impact de la TVA sur le taux de pauvreté par décile](07_reports/figures/fig_poverty_decile_impact.png)

![Impact pauvreté — TVA directe vs TVA totale (I/O)](07_reports/figures/fig_poverty_io_impact.png)

![Charge de la réforme TVA 9 % par quintile](07_reports/figures/fig_reform_burden_quintile.png)

![Impact FGT de la réforme TVA 9 %](07_reports/figures/fig_reform_fgt_impact.png)

![Charge des impôts directs et cotisations par décile (étape 16)](07_reports/figures/fig16_direct_burden_decile.png)

---

# Limites et hypothèses

1. **Incidence statique, pass-through complet** (scénario central) : pas de réponse
   comportementale des ménages ni des producteurs ; les scénarios S2/S3 encadrent
   l'incertitude liée à l'informalité des achats.
2. **Market Income proxié par la consommation** : approche standard (Hill et al.
   2017) mais qui comprime l'épargne des ménages aisés ; la sensibilité aux
   classements (06_02) montre que le signe de la progressivité de la TVA en dépend.
3. **Couverture des impôts directs** : le salaire d'enquête est sous-déclaré et
   l'emploi secondaire exclu (borne basse) ; les revenus non salariaux (BIC,
   fonciers, capitaux) ne sont pas encore simulés — extension prévue avec les
   modules s05/s10/s11.
4. **Quotient familial approché** : enfants attribués au principal apporteur ;
   situations d'infirmité (1 part) non observées.
5. **Matrice I/O** : la concordance codpr → secteurs (ICIO et TRE) reste
   perfectible pour certains secteurs clés (cacao, énergie) ; le TRE courant 2023
   décrit la structure productive de 2023 appliquée à des consommations de 2021.
6. **Réformes TVA post-2021** non couvertes (millésime EHCVM) — cf. FMI (2023).

---

# Cascade CEQ achevée (étapes 17–26)

| Étape | Contenu | Statut |
|---|---|---|
| 17 | Impôts directs et cotisations | Achevée |
| 18 | Accises et droits de douane | Achevée |
| 19 | Pensions, paiements publics et filets sociaux; PMT et calage PSSN | Achevée |
| 20 | Réductions de prix de l'électricité et de l'eau | Achevée |
| 21 | Services publics d'éducation | Achevée |
| 22 | Services publics de santé sans assurance EHCVM au centre | Achevée |
| 23 | Sept concepts de revenu CEQ | Achevée |
| 24 | Décomposition exacte de Shapley | Achevée |
| 25 | Appauvrissement fiscal et gains sous le seuil | Achevée |
| 26 | Classeur final, contrôles ANStat et manifeste | Achevée |

La méthode complète, les données, les robustesses et les références sont
désormais dans le working paper LaTeX et dans
PLAN_ETAPES20_26_FINALISATION_CEQ.md. Le PDF courant remplace cette ancienne
synthèse Markdown comme document de référence.

---
# Bibliographie

- Akim, A., M. Ben Jelloul, L. Czajka & A.-S. Robilliard (2020), *Collect More,
  Spend Better? Assessing the Incidence of Fiscal Systems and Public Spending in
  Three Francophone West African Countries*, AFD Research Papers.
- Bachas, P., L. Gadenne & A. Jensen (2024), « Informality, Consumption Taxes and
  Redistribution », *Review of Economic Studies*, 91(5).
- Foster, J., J. Greer & E. Thorbecke (1984), « A Class of Decomposable Poverty
  Measures », *Econometrica*, 52(3).
- Higgins, S. & N. Lustig (2016), « Can a poverty-reducing and progressive tax and
  transfer system hurt the poor? », *Journal of Development Economics*, 122.
- Hill, R., G. Inchauste, N. Lustig, E. Tsehaye & T. Woldehanna (2017), *A Fiscal
  Incidence Analysis for Ethiopia*, CEQ Working Paper 41.
- Kakwani, N. (1977), « Measurement of Tax Progressivity: An International
  Comparison », *Economic Journal*, 87(345).
- Lustig, N. (dir.) (2018/2023), *Commitment to Equity Handbook*, Vol. 1 & 2,
  Brookings / CEQ Institute.
- Lustig, N. (2017), *Fiscal Policy, Inequality and the Poor in the Developing
  World*, CEQ Working Paper 23.
- OCDE (2023), *Inter-Country Input-Output (ICIO) Tables*.
- SOUTHMOD (2021), « Modelling tax-benefit systems in developing countries »,
  *International Journal of Microsimulation* (éditorial).
- World Bank (2019), *Côte d'Ivoire — Relever le Défi de la Mobilisation Fiscale*.
- Younger, S., E. Osei-Assibey & F. Oppong (2016), *Fiscal Incidence in Ghana*,
  CEQ Working Paper 35.
- FMI (2023), *Côte d'Ivoire — Country Report No. 23/406*.
- Code Général des Impôts de Côte d'Ivoire (2021) ; CNPS ; dispositif CMU.

---

# Annexe A — Inventaire des scripts du pipeline

| Script | Fonction | Entrées principales | Sorties principales |
|---|---|---|---|
| `00_setup.R` | Chemins, packages, utils | — | environnement |
| `00_master.R` | Orchestrateur (17 étapes) | — | `lance_pipeline()` |
| `01_prepare_data.R` | `prepare_data` | `ehcvm_conso` | `SILVER/01/conso_clean.parquet` |
| `02_mapping_tax.R` | `map_tax` | classeur TVA | `SILVER/02/mapping_fiscal_official.parquet` |
| `03_compute_taxes.R` | `compute_taxes` | SILVER/01 | `SILVER/03/fiscal_data.parquet` |
| `04_analysis.R` | `run_analysis` | SILVER/03 | tables 04, `fiscal_data_analysis_ready.parquet` |
| `05_progressivity.R` | `run_progressivity` | SILVER/04 | table 05 (Gini/Kakwani/RS) |
| `06_01_sensitivity_taxation.R` | `run_sensitivity_taxation` | SILVER/01 | `fiscal_sensitivity_taxation.parquet`, tables 06 |
| `06_02_sensitivity_ranking.R` | `run_sensitivity_ranking` | SILVER/06, welfare | tables 06_02 |
| `07_appendix_tables.R` | `run_appendix_tables` | SILVER/04 | tables 07 |
| `08_figures.R` | `run_figures` | SILVER | fig1–fig4 |
| `09_vat_determinants.R` | `run_determinants` | SILVER/06 | tables 09 (OLS, SE cluster grappe) |
| `10_reform_chicken_inputs.R` | `run_reform_chicken` | SILVER/06 | `reform_chicken_hh.parquet`, tables 10 |
| `11_reform_figures.R` | `run_reform_figures` | SILVER/10 | figR1–figR4 |
| `12_poverty_incidence.R` | `run_poverty_incidence` | SILVER/06, welfare | tables 12, fig pauvreté |
| `13_leontief_io.R` (+ `13b` local) | script autonome | ICIO / TRE, concordance | `fiscal_data_io.parquet` |
| `14_leontief_poverty.R` (+ `14b`) | script autonome | SILVER/13 | tables 14, 14b |
| `15_reform_vat_simulation.R` | script autonome | SILVER/01, 06, welfare | tables 15, `reform_vat_hh.parquet` |
| `16_direct_taxes.R` | `direct_taxes` | individus, s04, SILVER/04 | `SILVER/16/direct_taxes.parquet`, tables 16, fig16 |

Exécution : depuis la racine du projet, `source("05_scripts_R/00_master.R")` puis
`lance_pipeline(1, 17)` (l'étape 16 correspond à l'identifiant 17 de
l'enchaînement).

---

# Annexe B — Code intégral de l'étape 16 (`16_direct_taxes.R`)

```r
# 16_direct_taxes.R
#
# OBJECTIF :
# Calculer les impots directs sur les salaires (IS, CN, IGR) et les
# cotisations sociales (CNPS part salariee, CMU) par menage, puis construire
# le concept CEQ Net Market Income :
#
#   net_market_income = market_income - irpp - cotisations
#
# BAREMES (CGI 2021, cf. 00_documentation/methodologie/MEMOIRE_FISCAL_CIV2021.md) :
#   IS   : 1,2 % du SBI (= 1,5 % de la base imposable BI = 0,8 x SBI)
#   CN   : par tranches mensuelles sur BI : 0 % (<=50k), 1,5 % (50k-130k),
#          5 % (130k-200k), 10 % (>200k)
#   IGR  : base R = 0,8 x (SBI - IS - CN), quotient familial N (plafond 5 parts),
#          bareme mensuel en 10 tranches sur Q = R/N, reduction finale de 15 %
#   CNPS : part salariee retraite 6,3 % du SBI plafonne a 1 647 315 FCFA/mois
#   CMU  : retenue simulee de 500 FCFA/mois par salarie formel (part salariale)
#
# NOTE : le script Banque mondiale de reference (ressources_CEQ/02. CIV21WBN_dtx.do)
# encode un bareme IGR de *proposition de reforme* (0/16/21/24/28/32 %,
# deduction 5 500 FCFA par demi-part) et non le bareme CGI en vigueur en 2021.
# On retient donc le bareme par quotient de la memoire fiscale du projet.
#
# HYPOTHESES (a documenter dans le rapport — couverture des impots directs) :
#   - Assujettis = salaries "formels stricts" : bulletin de paie (s04q42==1)
#     ET cotisation CGRAE/CNPS (s04q38==1). Scenario de robustesse "elargi" :
#     bulletin OU cotisation.
#   - Assiette = salaire annuel harmonise de l'emploi principal (ehcvm_individu,
#     variable `salaire`). L'emploi secondaire est exclu (formalite inconnue)
#     -> estimation en borne basse.
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
  CMU_MENSUEL    <- 500        # retenue CMU simulee, part salariale (FCFA/mois)
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
    col_select = c("grappe", "menage", "individu", "s04q38", "s04q42")
  ) %>%
    dplyr::transmute(
      grappe, menage,
      numind        = individu,
      bulletin_paie = as.integer(s04q42) == 1L,
      cotise_caisse = as.integer(s04q38) == 1L
    )

  ind <- ind %>%
    dplyr::left_join(s04, by = c("grappe", "menage", "numind")) %>%
    dplyr::mutate(
      salaire       = dplyr::coalesce(as.numeric(salaire), 0),
      bulletin_paie = dplyr::coalesce(bulletin_paie, FALSE),
      cotise_caisse = dplyr::coalesce(cotise_caisse, FALSE),
      formel_strict = salaire > 0 & bulletin_paie & cotise_caisse,
      formel_large  = salaire > 0 & (bulletin_paie | cotise_caisse)
    )

  n_sal    <- sum(ind$salaire > 0)
  n_strict <- sum(ind$formel_strict)
  n_large  <- sum(ind$formel_large)
  message(sprintf(
    "  Salaries (salaire > 0) : %d | formels stricts : %d (%.1f %%) | elargis : %d (%.1f %%)",
    n_sal, n_strict, 100 * n_strict / n_sal, n_large, 100 * n_large / n_sal
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
    dplyr::group_by(hhid) %>%
    dplyr::mutate(
      rang_salaire = dplyr::row_number(dplyr::desc(salaire)),
      top_earner   = formel_strict & rang_salaire == min(rang_salaire[formel_strict], Inf)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      parts_etat_civil = dplyr::case_when(
        as.integer(mstat) %in% c(2L, 3L) ~ 2,
        as.integer(mstat) == 5L          ~ 1.5,
        TRUE                             ~ 1
      ),
      n_parts = pmin(
        parts_etat_civil + ifelse(top_earner, 0.5 * n_enfants, 0),
        PLAFOND_PARTS
      )
    )

  # ── 4. Calcul des prelevements mensuels par salarie ────────────────────────
  calcule_prelevements <- function(df, flag_formel) {
    df %>%
      dplyr::mutate(
        assujetti = .data[[flag_formel]],
        sbi_m     = ifelse(assujetti, salaire / 12, 0),
        bi_m      = ABATTEMENT * sbi_m,
        is_m      = TAUX_IS * sbi_m,
        cn_m      = calc_cn(bi_m),
        r_m       = ABATTEMENT * (sbi_m - is_m - cn_m),
        q_m       = r_m / n_parts,
        igr_m     = pmax(0, calc_igr_part(q_m)) * n_parts * 0.85,
        cnps_m    = TAUX_CNPS * pmin(sbi_m, PLAFOND_CNPS_M),
        cmu_m     = ifelse(assujetti, CMU_MENSUEL, 0),
        irpp_an   = (is_m + cn_m + igr_m) * 12,
        cotis_an  = (cnps_m + cmu_m) * 12
      )
  }

  ind_strict <- calcule_prelevements(ind, "formel_strict")
  ind_large  <- calcule_prelevements(ind, "formel_large")

  # Controles de coherence
  stopifnot(
    all(ind_strict$irpp_an >= 0, na.rm = TRUE),
    all(ind_strict$cnps_m <= TAUX_CNPS * PLAFOND_CNPS_M + 1e-6, na.rm = TRUE),
    all(ind_strict$igr_m[ind_strict$q_m <= 25000] == 0, na.rm = TRUE)
  )

  # ── 5. Agregation menage ───────────────────────────────────────────────────
  agrege_hh <- function(df, suffixe = "") {
    df %>%
      dplyr::group_by(hhid) %>%
      dplyr::summarise(
        !!paste0("n_salaries_formels", suffixe) := sum(assujetti),
        !!paste0("irpp", suffixe)               := sum(irpp_an),
        !!paste0("cotisations", suffixe)        := sum(cotis_an),
        .groups = "drop"
      )
  }

  hh_direct <- agrege_hh(ind_strict) %>%
    dplyr::left_join(agrege_hh(ind_large, "_large"), by = "hhid")

  # ── 6. Jointure au fichier fiscal menage et Net Market Income ──────────────
  fiscal <- load_parquet(
    file.path(paths$SILVER, "04", "fiscal_data_analysis_ready.parquet")
  )
  assert_required_columns(
    fiscal, c("hhid", "hhweight", "conso_w", "decile", "quintile",
              "market_income", "consumable_income"),
    object_name = "fiscal_data_analysis_ready.parquet"
  )

  hh <- fiscal %>%
    dplyr::left_join(hh_direct, by = "hhid") %>%
    dplyr::mutate(
      dplyr::across(
        c(n_salaries_formels, irpp, cotisations,
          n_salaries_formels_large, irpp_large, cotisations_large),
        ~ dplyr::coalesce(.x, 0)
      ),
      net_market_income       = market_income - irpp - cotisations,
      net_market_income_large = market_income - irpp_large - cotisations_large,
      eff_irpp                = irpp / conso_w,
      eff_cotis               = cotisations / conso_w
    )

  n_orphelins <- nrow(hh_direct) - sum(hh_direct$hhid %in% fiscal$hhid)
  if (n_orphelins > 0)
    warning(sprintf("  %d menages du module emploi absents du fichier fiscal", n_orphelins))

  save_parquet(
    hh %>% dplyr::select(
      hhid, hhweight, decile, quintile, milieu, region, conso_w,
      n_salaries_formels, irpp, cotisations, net_market_income,
      n_salaries_formels_large, irpp_large, cotisations_large,
      net_market_income_large, eff_irpp, eff_cotis
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
        taux_effectif = 100 * weighted.mean(.data[[eff_var]], hhweight),
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
  # Le Market Income est proxie par la consommation : pour quelques menages a
  # salaire declare eleve mais consommation modeste, irpp + cotisations peut
  # exceder conso_w. On borne le net a zero pour les indices (bottom-coding
  # CEQ standard) et on trace le nombre de menages concernes.
  n_neg <- sum(hh$net_market_income < 0)
  if (n_neg > 0)
    message(sprintf(
      "  Attention : %d menages avec net_market_income < 0 (borne a 0 pour le Gini)",
      n_neg
    ))
  net_mi_pos <- pmax(hh$net_market_income, 0)

  w_ind_strict <- sum(ind$hhweight[ind$formel_strict], na.rm = TRUE)
  w_ind_sal    <- sum(ind$hhweight[ind$salaire > 0],   na.rm = TRUE)

  resume <- tibble::tibble(
    indicateur = c(
      "Salaries formels stricts (pondere)",
      "Salaries (salaire > 0, pondere)",
      "Taux de formalite parmi les salaries (%)",
      "Menages avec au moins un salarie formel (%)",
      "Masse IRPP simulee (FCFA/an, pondere)",
      "Masse cotisations simulees (FCFA/an, pondere)",
      "Masse IRPP — scenario elargi (FCFA/an)",
      "Kakwani IRPP (welfare = conso_w)",
      "Kakwani cotisations",
      "Gini market income",
      "Gini net market income",
      "Reynolds-Smolensky (Gini net - Gini market)"
    ),
    valeur = c(
      w_ind_strict,
      w_ind_sal,
      100 * w_ind_strict / w_ind_sal,
      100 * weighted.mean(hh$n_salaries_formels > 0, hh$hhweight),
      sum(hh$irpp * hh$hhweight),
      sum(hh$cotisations * hh$hhweight),
      sum(hh$irpp_large * hh$hhweight),
      kakwani_index(hh$irpp, hh$conso_w, hh$hhweight),
      kakwani_index(hh$cotisations, hh$conso_w, hh$hhweight),
      weighted_gini(hh$market_income, hh$hhweight),
      weighted_gini(net_mi_pos, hh$hhweight),
      reynolds_smolensky(hh$market_income, net_mi_pos, hh$hhweight)
    )
  )

  message("\n  Couverture et progressivite :")
  print(as.data.frame(resume))

  export_excel(resume,
               file.path(paths$TABLES, "16", "16_03_coverage_kakwani.xlsx"))

  # ── 9. Figure : charge directe par decile ──────────────────────────────────
  fig_data <- hh %>%
    dplyr::group_by(decile) %>%
    dplyr::summarise(
      IRPP        = 100 * weighted.mean(eff_irpp, hhweight),
      Cotisations = 100 * weighted.mean(eff_cotis, hhweight),
      .groups     = "drop"
    ) %>%
    tidyr::pivot_longer(-decile, names_to = "composante", values_to = "taux")

  fig16 <- ggplot2::ggplot(
    fig_data,
    ggplot2::aes(x = factor(decile), y = taux, fill = composante)
  ) +
    ggplot2::geom_col(position = "stack", width = 0.75) +
    ggplot2::scale_fill_manual(
      values = c("IRPP" = "firebrick", "Cotisations" = "steelblue")
    ) +
    ggplot2::labs(
      title    = "Charge des impots directs et cotisations par decile",
      subtitle = "Scenario formel strict — Côte d'Ivoire, EHCVM 2021",
      x        = "Décile de consommation (D1 = plus pauvre)",
      y        = "Taux effectif (% de la consommation)",
      fill     = NULL,
      caption  = paste0(
        "Assujettis : salariés avec bulletin de paie ET cotisation CGRAE/CNPS.\n",
        "Barèmes CGI 2021 (IS, CN, IGR par quotient familial), CNPS 6,3 % plafonnée, CMU 500 FCFA/mois."
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
```

---

# Annexe C — Fonctions utilitaires clés

**`utils/io.R`** — `load_raw_dta(filename, col_select)` (lecture .dta locale ou
MinIO selon `USE_MINIO`), `source_file_path(...)`, `read_source_excel/csv()`,
`save_parquet()/load_parquet()`, `export_excel()`, `export_fig()`,
`assert_required_columns()`, `tidy_lm_robust()` (SE cluster-robustes).

**`utils/distributive.R`** — `weighted_frac_rank()` (rang fractionnaire pondéré,
règle du point médian), `weighted_gini()`, `weighted_conindex()`,
`kakwani_index(t, welfare, w)` = CI(t) − Gini(welfare),
`reynolds_smolensky(avant, après, w)`, `weighted_ntile(x, w, n)` (équivalent
`xtile [pw=]`), `bootstrap_kakwani()` (500 réplications, IC percentile 95 %).

---

*Document généré depuis le pipeline `rewrite-r` — juillet 2026. Les tables
complètes se trouvent dans `07_reports/tables/`, les données intermédiaires dans
`02_data_intermediate/`, et le détail méthodologique des barèmes dans
`00_documentation/methodologie/MEMOIRE_FISCAL_CIV2021.md`.*
