# Incidence distributive de la TVA en Côte d'Ivoire
### Microsimulation fiscale · EHCVM 2021 · Document de travail — Avril 2026

---

## Table des matières

- [Présentation](#présentation)
- [Cadre conceptuel](#cadre-conceptuel)
- [Méthodologie](#méthodologie)
- [Données](#données)
- [Informalité et taxation effective](#informalité-et-taxation-effective)
- [Résultats produits](#résultats-produits)
- [Hypothèses principales](#hypothèses-principales)
- [Limites et extensions en cours](#limites-et-extensions-en-cours)
- [Structure du dépôt](#structure-du-dépôt)
- [Architecture des données](#architecture-des-données)
- [Reproductibilité](#reproductibilité)
- [Références](#références)

---

## Présentation

Ce projet estime l'**incidence distributive de la taxe sur la valeur ajoutée (TVA)** en Côte d'Ivoire à partir des données de consommation des ménages de l'**enquête EHCVM 2021**.

L'objectif central est d'identifier **qui supporte effectivement la charge de la TVA** — en valeur absolue et relativement à la consommation totale — et de déterminer si le système fiscal est **progressif, proportionnel ou régressif** le long de la distribution du bien-être.

L'analyse est conçue comme un **exercice d'incidence fiscale de premier ordre**, fournissant un cadre transparent et reproductible adapté aux contraintes de données habituelles en Afrique subsaharienne.

---

## Cadre conceptuel

L'analyse s'appuie sur le cadre **CEQ (Commitment to Equity)**, adapté au contexte ivoirien et aux données disponibles.

Dans le cadre CEQ standard, plusieurs concepts de revenu sont comparés (revenu de marché, revenu disponible, revenu consommable, revenu final). En raison des contraintes de données, ce projet se concentre sur le passage de la **consommation observée** à une **mesure de bien-être post-fiscalité simulée**.

### Identité centrale

```
Revenu consommable = Consommation totale − Taxes indirectes (TVA)
```

Cette identité isole l'**effet direct des taxes à la consommation** sur le bien-être des ménages.

---

## Méthodologie

La stratégie empirique repose sur une **approche de microsimulation ascendante** en cinq étapes :

| Étape | Description |
|-------|-------------|
| **1. Agrégation de la consommation** | Consommation au niveau du ménage construite à partir des dépenses par produit |
| **2. Cartographie fiscale** | Chaque produit (`codpr`) reçoit un traitement fiscal (exonéré / taux réduit / taux normal) |
| **3. Imputation de la taxe** | TVA simulée au niveau produit, puis agrégée au niveau ménage |
| **4. Comparaison du bien-être** | Consommation avant taxe comparée au revenu consommable simulé |
| **5. Analyse distributive** | Résultats analysés par décile via les taux effectifs, courbes de concentration et indices de progressivité |

---

## Données

| Attribut | Détail |
|----------|--------|
| **Source** | EHCVM 2021 — Côte d'Ivoire |
| **Unité d'observation** | Ménage × produit |
| **Unité d'analyse** | Ménage |

### Variables clés

| Variable | Description |
|----------|-------------|
| `codpr` | Identifiant produit |
| `modep` | Mode d'acquisition (marché, autoconsommation, don, etc.) |
| `depan` | Dépense annuelle |
| `hhweight` | Pondération sondage |

---

## Informalité et taxation effective

Un défi majeur dans les économies en développement est que **toutes les transactions ne sont pas effectivement taxées**, en raison de la prévalence du secteur informel.

Pour y répondre, l'analyse intègre des **scénarios de taxation effective hétérogène** basés sur le cadre de la **courbe d'Engel de l'informalité (IEC)** (Bachas, Gadenne & Jensen, 2024).

### Scénario 1 — Strict (α = 1)

- Taxation complète de toute la consommation éligible
- Représente une **borne supérieure théorique**
- Sert de référence pour la comparaison

### Scénario 2 — CEI × milieu

- α varie selon la catégorie COICOP **et** le milieu (urbain/rural)
- Capture les différences structurelles d'accès au marché et de formalisation

### Scénario 3 — CEI × décile

- α croît de façon monotone avec le niveau de consommation
- Reflète le fait que **les ménages plus aisés transactent davantage dans les marchés formels**

Ces scénarios permettent de tester la robustesse des conclusions quant à l'**effet de l'informalité sur les résultats distributifs**, au-delà des niveaux agrégés de taxation.

---

## Résultats produits

- Taux effectifs de TVA par décile
- Charge fiscale (absolue et relative à la consommation)
- Courbes de concentration (avant et après taxe)
- Coefficients de Gini (avant et après taxe)
- Indice de Kakwani de progressivité fiscale
- Analyses de sensibilité et de robustesse par scénario

---

## Hypothèses principales

| Hypothèse | Description |
|-----------|-------------|
| **Répercussion intégrale** | La TVA est entièrement répercutée dans les prix à la consommation (pas d'absorption par le producteur) |
| **Consommation comme indicateur de bien-être** | La consommation totale du ménage est utilisée comme proxy du revenu permanent |
| **Équilibre partiel** | Pas d'effets indirects via les chaînes de production ni d'ajustements d'équilibre général |

> Les résultats doivent être interprétés comme une **approximation de premier ordre** de l'incidence fiscale.

---

## Limites et extensions en cours

| Limite | Statut |
|--------|--------|
| Pas de taxes directes ni de transferts sociaux modélisés | Périmètre de premier ordre — incidence TVA uniquement |
| Pas de réponses comportementales (ajustements de prix ou de demande) | Incidence statique par construction |
| Pas d'effets de transmission entrées-sorties | En cours — branche `integration-IO-matrix` : modèle de prix de Leontief avec la matrice OCDE ICIO 2023, pour capturer la TVA enchâssée dans les consommations intermédiaires et les biens exonérés |
| Informalité modélisée par scénarios, non observée directement | Traitée via les 3 scénarios IEC (Bachas et al. 2024) |
| Pas d'analyse de scénarios de réforme fiscale | En cours — branche `reform-scenarios` : réforme de la TVA sur les intrants avicoles, impact distributif par décile, indice de Kakwani, tableau de sensibilité croisé |
| Pas d'estimation de l'impact sur la pauvreté | Traité — étape 12 (R et Stata) : indices FGT (P0, P1, P2) avant et après TVA, par décile, milieu et région ; nouveaux pauvres ; composante réforme avicole |

Ces limites sont explicitement reconnues dans le cadre d'une **stratégie de recherche transparente et progressive**.

---

## Structure du dépôt

```
anstat-microsim/
│
├── 00_documentation/
│   ├── EHCVM_products/       # Fichiers de nomenclature des produits
│   ├── methodologie/         # Notes méthodologiques CEQ et extensions
│   ├── presentation/         # Présentations
│   ├── ressources_CEQ/       # Scripts Stata CEQ de référence (BM CIV 2021)
│   └── statutory_rates/      # Code fiscal et annexes fiscales
│
├── 01_data_sources/           # Couche Bronze — données brutes (non versionnées)
│   ├── Datain/               # Fichiers bruts EHCVM 2021
│   ├── Dataout/              # Données traitées EHCVM (.dta)
│   ├── Documents/            # Documents de référence (questionnaires, méthodologie)
│   └── Programs/             # Scripts de traitement de l'enquête (équipe EHCVM)
│
├── 02_data_intermediate/      # Couche Silver — intermédiaires parquet (non versionnés)
│
├── 03_data_output/            # Couche Gold — données analytiques finales (non versionnées)
│
├── 04_scripts/                # Pipeline Stata (version originale)
│   ├── 00_master.do          # Script maître — lance le pipeline complet
│   ├── 00_setup.do           # Environnement et chemins globaux
│   ├── 01_prepare_data.do    # Préparation des données et construction des variables
│   ├── 02_mapping_tax.do     # Cartographie fiscale des produits
│   ├── 03_compute_taxes.do   # Calcul de l'incidence TVA au niveau ménage
│   ├── 04_analysis.do        # Résultats distributifs CEQ
│   ├── 05_progressivity.do   # Mesures de progressivité (Kakwani, Gini)
│   ├── 06_01_sensitivity_taxation.do  # Sensibilité : scénarios de traitement fiscal
│   ├── 06_02_sensitivity_ranking.do   # Sensibilité : robustesse du classement bien-être
│   ├── 07_appendix_tables.do # Tableaux annexes
│   ├── 08_figures.do         # Courbes de concentration, profils de taux effectifs
│   ├── 09_vat_determinants.do        # Déterminants socio-démographiques de l'exposition à la TVA
│   ├── 10_reform_chicken_inputs.do   # Simulation de réforme : TVA sur intrants avicoles
│   ├── 11_reform_figures.do          # Figures de réforme
│   └── 12_poverty_incidence.do       # Incidence sur la pauvreté — FGT (P0, P1, P2)
│
├── 05_scripts_R/              # Pipeline R (réécriture — branche rewrite-r)
│   ├── 00_master.R           # Orchestrateur inspiré INES (enchainement + lance_pipeline)
│   ├── 00_setup.R            # Chemins, paquets, utilitaires ; source config.R
│   ├── config.R              # Indicateur source de données (local / MinIO) + credentials
│   ├── 01_prepare_data.R     # Bronze -> Silver : filtre, winsorisation, sauvegarde parquet
│   ├── 02_mapping_tax.R      # Cartographie TVA depuis Excel -> parquet
│   ├── 03_compute_taxes.R    # Agrégation TVA ménage + concepts de revenu CEQ
│   ├── 04_analysis.R         # Ventilation par décile/quintile, milieu et région
│   ├── 05_progressivity.R    # Gini, IC, Kakwani, RS ; courbes de Lorenz et de concentration
│   ├── 06_01_sensitivity_taxation.R  # 3 scénarios d'informalité + bootstrap Kakwani
│   ├── 06_02_sensitivity_ranking.R   # Robustesse sur 4 classements bien-être
│   ├── 07_appendix_tables.R  # Tableaux étendus (COICOP, région, milieu)
│   ├── 08_figures.R          # Figures 1 à 4
│   ├── 09_vat_determinants.R # MCO M1-M4, erreurs-types robustes cluster, marginsplot
│   ├── 10_reform_chicken_inputs.R    # Simulation de réforme avicole
│   ├── 11_reform_figures.R   # Figures de réforme R1-R4
│   ├── 12_poverty_incidence.R        # Incidence sur la pauvreté — FGT (P0, P1, P2)
│   └── utils/
│       ├── distributive.R    # Gini, IC, Kakwani, ntile pondérés
│       └── io.R              # Parquet, Excel, figures, load_raw_dta (local/MinIO)
│
├── 06_logs/                   # Journaux d'exécution (non versionnés)
│
├── 07_reports/
│   ├── tables/               # Tableaux Excel exportés (non versionnés)
│   └── figures/              # Figures et graphiques (non versionnés)
│
├── .env.example               # Modèle de credentials MinIO (copier vers .env, ne jamais committer)
└── README.md
```

---

## Architecture des données

Le pipeline sépare le code, les données et le calcul — une frontière nette qui facilite la réplication sur l'infrastructure institutionnelle.

```
Développement local          Réseau institutionnel
───────────────────          ──────────────────────────────────────
01_data_sources/             bucket MinIO : anstat-raw    (Bronze)
02_data_intermediate/    →   bucket MinIO : anstat-silver (Silver, parquet)
```

La source de données est contrôlée par un unique indicateur dans `05_scripts_R/config.R` :

```r
USE_MINIO <- FALSE   # passer à TRUE sur le réseau institutionnel
```

Les credentials ne sont jamais codés en dur. Copier `.env.example` vers `.env` et renseigner les valeurs :

```
MINIO_ENDPOINT=http://minio.institution.local:9000
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
```

Tous les accès aux fichiers `.dta` bruts passent par `load_raw_dta()` dans `utils/io.R`, qui route de façon transparente vers le chemin local ou MinIO selon l'indicateur.

---

## Reproductibilité

**Pipeline Stata (`04_scripts/`)**

- Code en fichiers `.do` avec commentaires intégrés
- Chemins paramétrés via `00_setup.do`

**Pipeline R (`05_scripts_R/`)**

- Orchestrateur inspiré INES : `00_master.R` définit un data.frame `enchainement` ; `lance_pipeline(premiere_etape, derniere_etape)` exécute n'importe quel sous-ensemble d'étapes
- Les intermédiaires parquet (couche Silver) remplacent les fichiers `.dta` intermédiaires Stata — I/O plus rapide, format agnostique au langage
- Erreurs-types robustes à la corrélation intra-cluster via `sandwich::vcovCL()` — équivalent de `vce(cluster grappe)` en Stata
- Indices distributifs pondérés (Gini, IC, Kakwani, RS) implémentés à partir des formules de base avec rang fractionnaire à mi-point — cohérent avec `-conindex-` sous Stata
- Intervalles de confiance bootstrap sur le Kakwani (500 réplications)
- Tous les outputs (tableaux, figures) exportés automatiquement vers `07_reports/`

Pour lancer le pipeline R complet depuis la racine du projet :

```r
source("05_scripts_R/00_master.R")
lance_pipeline(premiere_etape = 1, derniere_etape = 13)
```

Pour lancer uniquement l'analyse de pauvreté (après que les étapes 6 et 11 ont tourné) :

```r
lance_pipeline(premiere_etape = 13, derniere_etape = 13)
```

---

## Références

- Bachas, P., Gadenne, L., & Jensen, A. (2024). *Informality, Consumption Taxes, and Redistribution*. American Economic Review.
- Lustig, N. (Ed.) (2018). *Commitment to Equity Handbook*. Brookings Institution Press.
- World Bank (2024). *Urban Informality in Sub-Saharan Africa*. Policy Research Working Paper No. 10703.
- UNECA (2019). *Economic Report on Africa: Fiscal Policy for Financing Sustainable Development*.

---

---

![Statut](https://img.shields.io/badge/Statut-Document%20de%20travail-orange?style=flat-square)
![Date](https://img.shields.io/badge/Date-Avril%202026-lightgrey?style=flat-square)
![Institution](https://img.shields.io/badge/Institution-ANStat%20CAE-green?style=flat-square)
