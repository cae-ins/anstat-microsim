# Incidence distributive de la TVA en Cote d'Ivoire
### Microsimulation fiscale · EHCVM 2021 · Document de travail - Avril 2026

---

## Table des matieres

- [Presentation](#presentation)
- [Cadre conceptuel](#cadre-conceptuel)
- [Methodologie](#methodologie)
- [Donnees](#donnees)
- [Informalite et taxation effective](#informalite-et-taxation-effective)
- [Resultats produits](#resultats-produits)
- [Hypotheses principales](#hypotheses-principales)
- [Limites et extensions](#limites-et-extensions)
- [Structure du depot](#structure-du-depot)
- [Architecture des donnees](#architecture-des-donnees)
- [Reproductibilite](#reproductibilite)
- [Etat du pipeline](#etat-du-pipeline)
- [References](#references)

---

## Presentation

Ce projet estime l'incidence distributive de la TVA en Cote d'Ivoire a partir des donnees de consommation des menages de l'enquete EHCVM 2021.

L'objectif central est d'identifier qui supporte effectivement la charge de la TVA, en niveau et relativement a la consommation totale, et de determiner si le systeme est progressif, proportionnel ou regressif le long de la distribution du bien-etre.

L'analyse est concue comme un exercice d'incidence fiscale de premier ordre, transparent, reproductible et adapte aux contraintes de donnees habituelles en Afrique subsaharienne.

---

## Cadre conceptuel

L'analyse s'appuie sur le cadre CEQ (Commitment to Equity), adapte au contexte ivoirien et aux donnees disponibles.

En pratique, le projet se concentre sur le passage de la consommation observee a une mesure de bien-etre post-fiscalite simulee.

### Identite centrale

```text
Revenu consommable = Consommation totale - Taxes indirectes (TVA)
```

---

## Methodologie

La strategie empirique repose sur une approche de microsimulation ascendante en cinq etapes :

| Etape | Description |
|---|---|
| 1 | Agregation de la consommation au niveau menage a partir des depenses par produit |
| 2 | Cartographie fiscale des produits (`codpr`) |
| 3 | Imputation de la TVA au niveau produit puis agregation menage |
| 4 | Construction des concepts de bien-etre avant / apres taxe |
| 5 | Analyse distributive par decile, quintile, milieu et region |

---

## Donnees

| Attribut | Detail |
|---|---|
| Source | EHCVM 2021 - Cote d'Ivoire |
| Unite d'observation principale | Menage x produit |
| Unite d'analyse | Menage |

### Variables cles

| Variable | Description |
|---|---|
| `codpr` | Identifiant produit |
| `modep` | Mode d'acquisition |
| `depan` | Depense annuelle |
| `hhweight` | Ponderation sondage |

### Fichiers sources utilises par le pipeline R

- `01_data_sources/Dataout/ehcvm_conso_CIV2021.dta`
- `01_data_sources/Dataout/ehcvm_welfare_2b_CIV2021.dta`
- `01_data_sources/COPR_EHCVM_TVA_renseigne.xlsx`
- `01_data_sources/concordance_codpr_ICIO.csv`
- `01_data_sources/IO/CIV2020ttl.csv` pour l'extension input-output

---

## Informalite et taxation effective

L'analyse integre trois scenarios de taxation effective inspires du cadre IEC (Informality Engel Curve) :

- `Strict` : alpha = 1, borne superieure theorique
- `S2` : alpha varie selon la categorie COICOP et le milieu urbain/rural
- `S3` : alpha varie avec le decile de consommation

Ces scenarios servent a tester la robustesse des resultats distributifs a l'informalite.

---

## Resultats produits

- Taux effectifs de TVA par decile
- Charge fiscale absolue et relative
- Courbes de concentration
- Coefficients de Gini avant et apres taxe
- Indice de Kakwani
- Analyses de sensibilite
- Impact sur la pauvrete via les indices FGT
- Scenarios de reforme sur les intrants avicoles

---

## Hypotheses principales

| Hypothese | Description |
|---|---|
| Repercussion integrale | La TVA est entierement repercutee dans les prix a la consommation |
| Consommation comme proxy du bien-etre | La consommation totale du menage sert de proxy du revenu permanent |
| Equilibre partiel | Pas d'effets comportementaux ni d'equilibre general dans le coeur du pipeline |

Les resultats doivent etre interpretes comme une approximation de premier ordre de l'incidence fiscale.

---

## Limites et extensions

| Limite | Statut |
|---|---|
| Pas de taxes directes ni transferts sociaux modelises dans le coeur CEQ | Hors perimetre courant |
| Informalite observee indirectement | Traitee par scenarios |
| Effets input-output | Traites par les scripts `13` et `14` |
| Reforme fiscale | Traitee par les scripts `10`, `11` et `15` |
| Pauvrete | Traitee par le script `12` |

---

## Structure du depot

```text
anstat-microsim/
|
|-- 00_documentation/
|-- 01_data_sources/
|-- 02_data_intermediate/
|-- 03_data_output/
|-- 04_scripts/
|-- 05_scripts_R/
|-- 06_logs/
|-- 07_reports/
|-- 08_lit_review/
|-- .env.example
`-- README.md
```

### Organisation utile

- `01_data_sources/` : sources brutes et fichiers de reference
- `02_data_intermediate/` : couche `Silver` de travail en `parquet`
- `03_data_output/` : reserve pour sorties analytiques finales si besoin
- `05_scripts_R/` : pipeline R principal
- `07_reports/` : exports de tables et figures

---

## Architecture des donnees

Le pipeline separe code, donnees et sorties. Cette frontiere facilite la replication locale et la transition vers un stockage partage.

```text
Developpement local         Reseau institutionnel
01_data_sources/            bucket MinIO : anstat-raw
02_data_intermediate/   ->  bucket MinIO : anstat-silver
```

La source de donnees est controlee par `05_scripts_R/config.R` :

```r
USE_MINIO <- FALSE
```

Les credentials MinIO ne sont jamais codes en dur. Copier `.env.example` vers `.env` et renseigner :

```text
MINIO_ENDPOINT=http://minio.institution.local:9000
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
```

En pratique, le projet mobilise aujourd'hui la plateforme de facon minimale :

- `01_data_sources/` reste la source locale de developpement
- `02_data_intermediate/` est la vraie couche `Silver` operationnelle
- `MinIO` est prevu comme stockage partage sans changer l'arborescence
- le projet ne depend pas, a ce stade, de `Spark`, `Iceberg`, `Nessie`, `Trino`, `Superset` ou `Airflow`

---

## Reproductibilite

**Pipeline Stata (`04_scripts/`)**

- scripts `.do`
- chemins centralises dans `00_setup.do`

**Pipeline R (`05_scripts_R/`)**

- `00_master.R` definit l'orchestrateur `lance_pipeline(premiere_etape, derniere_etape)`
- les intermediaires sont stockes en `parquet`
- les acces aux sources et sorties sont centralises dans `utils/io.R`
- des validations explicites verifient l'existence des fichiers et des colonnes critiques
- `lance_pipeline()` valide les bornes d'etapes avant execution
- les outputs sont exportes automatiquement vers `07_reports/`

### Lancement depuis R

```r
source("05_scripts_R/00_master.R")
lance_pipeline(premiere_etape = 1, derniere_etape = 13)
```

Pour ne lancer que l'etape pauvrete :

```r
lance_pipeline(premiere_etape = 13, derniere_etape = 13)
```

### Lancement batch depuis PowerShell

```powershell
& 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe' -e "source('05_scripts_R/00_master.R')"
```

### Dependances R

- `00_setup.R` charge les paquets requis
- si un paquet est absent, `00_setup.R` tente de l'installer
- en environnement verrouille, il peut etre preferable de preinstaller les paquets avant le premier run

---

## Etat du pipeline

Le pipeline R a ete verifie en execution reelle sur ce depot.

- Les etapes `1` a `13` s'executent avec succes
- Les sorties intermediaires sont ecrites dans `02_data_intermediate/`
- Les tableaux et figures sont exportes dans `07_reports/`
- Les scripts `13`, `14` et `15` existent comme extensions du pipeline principal et utilisent la meme couche d'I/O

### Scripts R principaux

| Etape | Script | Role |
|---|---|---|
| 1 | `01_prepare_data.R` | nettoyage, filtre achat, winsorisation, `parquet` |
| 2 | `02_mapping_tax.R` | mapping TVA |
| 3 | `03_compute_taxes.R` | TVA directe menage |
| 4 | `04_analysis.R` | resultats distributifs |
| 5 | `05_progressivity.R` | Gini, Kakwani, RS |
| 6 | `06_01_sensitivity_taxation.R` | scenarios d'informalite |
| 7 | `06_02_sensitivity_ranking.R` | robustesse des classements |
| 8 | `07_appendix_tables.R` | tableaux annexes |
| 9 | `08_figures.R` | figures principales |
| 10 | `09_vat_determinants.R` | regressions de determinants |
| 11 | `10_reform_chicken_inputs.R` | reforme avicole |
| 12 | `11_reform_figures.R` | figures de reforme |
| 13 | `12_poverty_incidence.R` | pauvrete FGT |

### Points ouverts

- au moins un script de figures utilise `dplyr::case_match()`, ce qui produit un warning de depreciation sans bloquer l'execution
- `03_data_output/` est encore peu utilise ; la plupart des sorties analytiques vivent dans `02_data_intermediate/` et `07_reports/`

---

## References

- Bachas, P., Gadenne, L., & Jensen, A. (2024). *Informality, Consumption Taxes, and Redistribution*.
- Lustig, N. (Ed.) (2018). *Commitment to Equity Handbook*.
- World Bank (2024). *Urban Informality in Sub-Saharan Africa*. Policy Research Working Paper No. 10703.
- UNECA (2019). *Economic Report on Africa: Fiscal Policy for Financing Sustainable Development*.

---

![Statut](https://img.shields.io/badge/Statut-Document%20de%20travail-orange?style=flat-square)
![Date](https://img.shields.io/badge/Date-Avril%202026-lightgrey?style=flat-square)
![Institution](https://img.shields.io/badge/Institution-ANStat%20CAE-green?style=flat-square)
