# Incidence distributive du système fiscal en Côte d'Ivoire
### Microsimulation CEQ · EHCVM 2021 · Document de travail - Juillet 2026

---

## Table des matieres

- [Presentation](#presentation)
- [Acces au code et aux donnees](#acces-au-code-et-aux-donnees)
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

Ce projet estime l'incidence distributive des impôts, cotisations, paiements publics, réductions de prix et services publics d'éducation et de santé en Côte d'Ivoire à partir de l'EHCVM 2021.

L'objectif est d'identifier qui supporte les prélèvements et qui bénéficie des dépenses publiques, puis de mesurer leurs effets sur les inégalités, la pauvreté et l'appauvrissement fiscal.

L'analyse est concue comme un exercice d'incidence fiscale de premier ordre, transparent, reproductible et adapte aux contraintes de donnees habituelles en Afrique subsaharienne.

---

## Acces au code et aux donnees

Le code et la documentation sont publics sur GitHub :
https://github.com/cae-ins/anstat-microsim. La branche `rewrite-r` contient
l'implementation R utilisee par le document de travail.

```bash
git clone --branch rewrite-r --single-branch \
  https://github.com/cae-ins/anstat-microsim.git
cd anstat-microsim
```

Les microdonnees ne sont pas dupliquees dans Git. L'EHCVM 2021-2022 est
accessible par deux catalogues officiels :

- ANStat : https://centredecalcul.anstat.ci/index.php/welcome
- Banque mondiale : https://microdata.worldbank.org/index.php/catalog/6273

La reference du catalogue Banque mondiale est
`CIV_2021_EHCVM-2_v01_M`. L'utilisateur doit accepter les conditions d'acces,
de confidentialite et de citation du catalogue choisi, puis placer les fichiers
dans l'arborescence decrite ci-dessous. Le hash obtenu par `git rev-parse HEAD`
doit etre conserve avec chaque jeu de resultats afin d'identifier la version
exacte du code.

---

## Cadre conceptuel

L'analyse s'appuie sur le cadre CEQ (Commitment to Equity), adapte au contexte ivoirien et aux donnees disponibles.

En pratique, le projet se concentre sur le passage de la consommation observee a une mesure de bien-etre post-fiscalite simulee.

### Identités centrales

    Revenu disponible = revenu net de marché + paiements publics monétaires
    Revenu consommable = revenu disponible - impôts indirects + réductions publiques de prix
    Revenu final = revenu consommable + éducation publique + santé publique

Le document de travail définit en français courant les conventions de pension
PDI et PGT, le PMT, le calage, la TVA non déductible et tous les concepts de
revenu avant de présenter les équations.
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

Les fichiers harmonises de consommation, de bien-etre et d'individus sont
places dans `01_data_sources/Dataout/`. Les modules menages detailles, dont
l'emploi et la sante, sont places dans
`01_data_sources/Datain/Menage/`. Les matrices entrees-sorties sont placees
dans `01_data_sources/IO/`.

Les fichiers `ehcvm_conso_CIV2021.dta`,
`ehcvm_individu_CIV2021.dta` et `ehcvm_welfare_2b_CIV2021.dta` sont des
sorties harmonisees, pas de simples renommages des fichiers telecharges. En
partant des modules bruts, executer les programmes officiels conserves dans
`01_data_sources/Programs/` apres adaptation de leurs chemins. Cette
preparation assemble les modules, annualise la consommation et construit
l'agregat de bien-etre 2b. Elle requiert Stata. Le pipeline R commence une fois
ces sorties produites dans `Dataout/`; il ne faut pas renommer des fichiers
bruts pour contourner cette etape.

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
- `01_data_sources/params_indirect_other_2021.xlsx` pour les accises et le TEC
- 01_data_sources/params_transfers_2021.xlsx pour les pensions, paiements publics et filets sociaux
- 01_data_sources/params_subsidies_2021.xlsx pour les réductions de prix
- 01_data_sources/params_education_2021.xlsx pour les dépenses d'éducation
- 01_data_sources/params_health_2021.xlsx pour les dépenses de santé
- 01_data_sources/reference_external/ANSTAT_CNA_definitifs_2023.pdf
- 01_data_sources/reference_external/ANSTAT_annuaire_statistiques_economiques_2023.pdf
- `01_data_sources/IO/CIV2020ttl.csv` pour l'extension input-output

---

## Informalite et taxation effective

L'analyse integre trois scenarios de taxation effective inspires du cadre IEC (Informality Engel Curve) :

- `Strict` : alpha = 1, borne superieure theorique
- `S2` : alpha varie selon la categorie COICOP et le milieu urbain/rural
- `S3` : alpha varie avec le decile de consommation

Les coefficients S2 et S3 sont des hypotheses exogenes, non estimees sur l'EHCVM et non calees sur une recette administrative. Le pipeline publie la matrice S3 exacte et son profil implicite par decile.

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
- Accises et droits de douane par decile, avec validation micro-macro et Kakwani
- Pensions, PSSN, bourses et prestations sociales, avec scénarios PDI/PGT
- Réductions publiques de prix de l'électricité et de l'eau
- Services publics d'éducation et de santé, bruts et nets des paiements directs
- Sept concepts de revenu CEQ jusqu'au revenu final
- Décomposition exacte de Shapley entre six groupes d'instruments
- Appauvrissement fiscal, nouveaux pauvres et gains sous le seuil
- Classeur final avec contrôles ANStat 2021 et comparaisons 2022-2023

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
| Pensions contributives et transferts sociaux | Traites par l'etape 19 ; PDI central et PGT en robustesse |
| Impots directs et cotisations sociales | Traites par l'etape 17 |
| Accises et droits de douane | Traites par l'etape 18 ; effets directs en version 1 |
| Informalite observee indirectement | Traitee par scenarios |
| Effets input-output | Traites par les scripts `13` et `14` |
| Reforme fiscale | Traitee par les scripts `10`, `11` et `15` |
| Pauvreté | Traitée par les étapes 12 et 25 |
| Réductions de prix | Traitées par l'étape 20; carburants en borne haute |
| Éducation publique | Traitée par l'étape 21, brute et nette des frais |
| Santé publique | Traitée par l'étape 22 sans statut d'assurance au centre |
| Revenu final | Assemblé et vérifié à l'étape 23 |
| Shapley et appauvrissement fiscal | Traités aux étapes 24 et 25 |

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

Le meme protocole sert a un economiste et a un agent de programmation. Il est
documente dans `replication_package/README.md`; `AGENTS.md` et
`replication_package/AGENT_RUNBOOK.md` traduisent les memes regles pour un agent,
sans changer la methode ni les tolerances.

### 1. Restaurer l'environnement

```bash
Rscript --vanilla replication_package/code/00_restore_environment.R
```

Cette commande restaure les versions fixees dans `renv.lock` dans une
bibliotheque isolee du projet. Elle est la seule etape autorisee a installer des
paquets.

### 2. Placer et verifier les donnees

Les microdonnees EHCVM doivent etre obtenues aupres de l'ANStat ou du catalogue
de la Banque mondiale, puis placees aux chemins decrits dans
`replication_package/data/access-restricted-data.md`.

```bash
Rscript --vanilla replication_package/code/00_preflight.R
```

Le pre-controle verifie R, les paquets, l'arborescence, les 20 entrees attendues,
leurs tailles et empreintes MD5. Son rapport est ecrit dans
`replication_package/output/preflight_report.csv`; aucune ligne `FAIL` n'est
acceptable.

### 3. Reproduire les 26 etapes

```bash
Rscript --vanilla replication_package/code/00_run_all.R
```

Le programme extrait automatiquement les matrices TRE si necessaire, execute le
pipeline complet, enregistre le journal et lance la verification numerique. Une
execution partielle avec `lance_pipeline()` reste utile au developpement, mais
ne constitue pas une replication depuis les entrees.

### 4. Verifier des sorties existantes

```bash
Rscript --vanilla replication_package/code/01_verify_outputs.R
```

Le rapport `replication_package/output/verification_report.csv` compare les
indicateurs centraux aux valeurs attendues. Il doit lui aussi contenir zero
echec.

### Documentation de replication

- `replication_package/data/data_manifest.csv` : provenance, taille et hash des entrees;
- `replication_package/exhibit_map.csv` : chaque tableau et figure relie a son script;
- `replication_package/environment/` : versions, `sessionInfo()` et besoins materiels;
- `replication_package/replication_spec.json` : commandes et criteres de succes lisibles par machine;
- `replication_package/DCAS_checklist.md` : controle de preparation a la diffusion.
## Etat du pipeline

Le pipeline R a ete verifie en execution reelle sur ce depot.

- L'orchestrateur expose les étapes 1 à 26
- La chaîne a été rejouée depuis zéro en deux segments successifs, étapes 1 à 13
  puis 14 à 26, sur les mêmes sorties intermédiaires; toutes les étapes ont abouti
- Les sorties intermediaires sont ecrites dans `02_data_intermediate/`
- Les tableaux et figures sont exportes dans `07_reports/`
- Les extensions input-output, pauvrete, reforme et prelevements directs utilisent la meme couche d'I/O

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
| 14 | `13_leontief_io.R`, `13b_leontief_local_io.R` | TVA enchassee, ICIO et TRE |
| 15 | `14_leontief_poverty.R` | pauvrete avec TVA enchassee |
| 16 | `15_reform_vat_simulation.R` | taxation de la vente finale à 9 %, vecteur de TVA incorporée constant, informalité et recyclage |
| 17 | `16_direct_taxes.R` | impots directs, cotisations et revenu de marche net |
| 18 | `17_indirect_other.R` | accises, droits de douane TEC et validation micro-macro |
| 19 | 18_transfers.R | pensions, paiements publics et filets sociaux; PDI/PGT |
| 20 | 19_subsidies.R | réductions publiques de prix de l'électricité et de l'eau |
| 21 | 20_inkind_education.R | services publics d'éducation |
| 22 | 21_inkind_health.R | services publics de santé, sans assurance EHCVM au centre |
| 23 | 22_income_concepts.R | sept concepts de revenu CEQ |
| 24 | 23_marginal_contribution.R | progressivité et décomposition de Shapley |
| 25 | 24_fiscal_impoverishment.R | appauvrissement fiscal et gains sous le seuil |
| 26 | 25_ceq_report_tables.R | classeur CEQ, contrôles ANStat et manifeste |

### Limites restantes

- la propagation par le TRE des droits de douane et des accises sur carburants
  reste une extension;
- le prix de parité du carburant 2021 n'est pas assez documenté pour une
  réduction de prix centrale;
- la référence AT/MP doit encore être remplacée par une exécution administrative
  indépendante;
- les agrégats ANStat couvrent toute l'économie et servent de contrôles de
  périmètre, non de cibles de calage des ménages.
---

## Références principales

- Lustig, N. (dir.), 2022, Commitment to Equity Handbook, deuxième édition,
  Brookings Institution et CEQ Institute.
- Akim, A.-M., Ben Jelloul, M., Czajka, L. et Robilliard, A.-S., 2020,
  Collect More, Spend Better?, AFD Research Paper 190.
- Demery, L., 2003, Analyzing the Incidence of Public Spending.
- Shorrocks, A. F., 2013, Decomposition Procedures for Distributional
  Analysis, Journal of Economic Inequality.
- Higgins, S. et Lustig, N., 2016, Can a Poverty-Reducing and Progressive Tax
  and Transfer System Hurt the Poor?, Journal of Development Economics.
- ANStat, Comptes nationaux annuels définitifs 2023.
- ANStat, Annuaire des statistiques économiques 2023.
- ANARE-CI, Rapport d'activités 2021.
---

![Statut](https://img.shields.io/badge/Statut-Document%20de%20travail-orange?style=flat-square)
![Date](https://img.shields.io/badge/Date-Juillet%202026-lightgrey?style=flat-square)
![Institution](https://img.shields.io/badge/Institution-ANStat%20CAE-green?style=flat-square)
