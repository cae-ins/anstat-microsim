# Feuille de route — Modèle CEQ Côte d'Ivoire (EHCVM 2021)

> **Objectif** : construire un modèle d'incidence fiscale complet suivant le cadre
> *Commitment to Equity* (Lustig et al.) pour la Côte d'Ivoire à partir de
> l'EHCVM 2021. Le modèle produit les 7 concepts de revenu CEQ standard et
> mesure l'impact distributif de chaque instrument fiscal et de dépense publique.

---

## État d'avancement

| # | Étape | Description | Statut |
|---|---|---|---|
| 01 | `01_prepare_data` | Nettoyage EHCVM, winsorisation, mapping COICOP | ✅ Commité (fix en attente) |
| 02 | `02_mapping_tax` | Mapping TVA officielle par codpr | ✅ Commité (fix en attente) |
| 03 | `03_compute_taxes` | TVA directe au niveau ménage, concepts Market/Consumable | ✅ Commité |
| 04 | `04_analysis` | Analyse distributive (déciles, quintiles, milieu, région) | ✅ Commité |
| 05 | `05_progressivity` | Kakwani, Reynolds-Smolensky, courbes de Lorenz/concentration | ✅ Commité |
| 06a | `06_01_sensitivity_taxation` | Sensibilité scénarios d'informalité (strict / CEI×milieu / CEI×décile) | ✅ Commité |
| 06b | `06_02_sensitivity_ranking` | Sensibilité classements (total / pc / AE1 / AE2) | ✅ Commité (fix en attente) |
| 07 | `07_appendix_tables` | Tableaux annexes | ✅ Commité |
| 08 | `08_figures` | Figures analytiques fig1–fig4 | ✅ Commité |
| 09 | `09_vat_determinants` | Déterminants TVA effective (régressions OLS) | ✅ Commité |
| 10 | `10_reform_chicken_inputs` | Simulation réforme intrants avicoles, Kakwani | ✅ Commité |
| 11 | `11_reform_figures` | Figures réforme figR1–figR4 | ✅ Commité |
| 12 | `12_poverty_incidence` | FGT (P0/P1/P2) avant/après TVA, 3 scénarios, milieu, région | ✅ Commité (fix en attente) |
| 13 | `13_leontief_io` | TVA enchâssée via OECD ICIO 2023 (modèle de prix Leontief) | ⏳ Écrit, non commité |
| 14 | `14_leontief_poverty` | Impact TVA enchâssée sur pauvreté, direct vs total I/O | ⏳ Écrit, non commité |
| 15 | `15_reform_vat_simulation` | Simulation réforme 0%→9% (agri / commerce / tous), FGT, charge quintile | ⏳ Écrit, non commité |

### Correctifs en attente (unstaged)

- `01_prepare_data.R` — décodage labels `codpr` + mapping COICOP 13 divisions
- `02_mapping_tax.R` — fix chemin Excel + conversion `codpr` via `as.integer()`
- `06_02_sensitivity_ranking.R` — fix `group_by` (mutate + nouvelle colonne)
- `12_poverty_incidence.R` — fix FGT : poids individu `w_ind = hhweight × hhsize`, P0 binaire

---

## Concepts de revenu CEQ

Le cadre CEQ définit 7 concepts construits en cascade. La pipeline actuelle couvre
uniquement les deux premiers.

```
Y_M   Market Income         = conso_w (proxy consommation winsorisée)
Y_NM  Net Market Income     = Y_M − impôts directs − cotisations sociales      [manquant]
Y_G   Gross Income          = Y_NM + pensions contributives                    [manquant]
Y_T   Taxable Income        = Y_G  (≈ Y_G pour CIV)                           [manquant]
Y_D   Disposable Income     = Y_T  + transferts non contributifs               [manquant]
Y_C   Consumable Income     = Y_D  − TVA − accises − douanes + subsidies       ← on est ici (TVA seule)
Y_F   Final Income          = Y_C  + éducation + santé (in-kind)               [manquant]
```

---

## Feuille de route détaillée

### Bloc A — Impôts directs et cotisations

#### Étape 16 — IRPP et cotisations sociales `16_direct_taxes.R`

**Objectif** : calculer la charge des impôts directs et des cotisations par ménage.

**Travail à faire :**
- Identifier le revenu salarial dans l'EHCVM (module emploi / revenus d'activité)
- Appliquer le barème IRPP CIV (tranches progressives, CGI en vigueur)
- Cotisations CNPS : salarié (6,3 % santé + taux retraite) + part patronale
- CMU (Couverture Maladie Universelle) si identifiable dans l'EHCVM
- Construire `net_market_income = market_income − irpp − cotisations`

**Inputs :**
- `EHCVM` modules emploi/revenus (variables à identifier)
- Barème IRPP CIV (à encoder depuis le CGI)
- Taux CNPS (document CNPS ou CGI)

**Outputs :**
- `SILVER/16/direct_taxes.parquet` — `hhid, irpp, cotisations, net_market_income`
- `TABLES/16/16_01_irpp_by_decile.xlsx`
- `TABLES/16/16_02_cotisations_by_decile.xlsx`

**Point de vigilance** : le revenu salarial est souvent sous-reporté dans les
enquêtes ménages. Documenter explicitement l'hypothèse de couverture retenue.

---

#### Étape 17 — Droits de douane et accises `17_indirect_other.R`

**Objectif** : étendre l'impôt indirect au-delà de la TVA.

**Travail à faire :**
- Accises : tabac, alcool, carburant (taux Loi de finances CIV)
- Droits de douane CEDEAO/TEC : via ratio importations/consommation par produit
- Concordance `codpr` → ligne tarifaire SH/TEC à construire
- Ajouter `excise_hh`, `custom_duty_hh` à `consumable_income`

**Inputs :**
- Taux accises (Loi de finances CIV 2021)
- Tarif Extérieur Commun CEDEAO (TEC)
- Concordance `codpr` → SH (à créer ou adapter depuis COPR_EHCVM)

**Outputs :**
- `SILVER/17/indirect_other.parquet` — `hhid, excise_hh, custom_duty_hh`
- `TABLES/17/17_01_excise_by_decile.xlsx`

---

### Bloc B — Transferts directs

#### Étape 18 — Transferts monétaires reçus `18_transfers.R`

**Objectif** : identifier les bénéficiaires de programmes sociaux et de pensions.

**Travail à faire :**
- Pensions contributives (CNPS retraite) : revenus de pension déclarés
- Transferts non contributifs : PFISP, transferts conditionnels, aide sociale
- Transferts privés (envois de fonds) : à exclure du concept CEQ ou à traiter séparément
- Construire `gross_income` et `disposable_income`

**Inputs :**
- Module revenus EHCVM (variables transferts reçus)
- Budget PFISP / documentation programmes sociaux CIV

**Outputs :**
- `SILVER/18/transfers.parquet` — `hhid, pension_contrib, transfer_noncont, gross_income, disposable_income`
- `TABLES/18/18_01_beneficiaries_by_decile.xlsx`
- `TABLES/18/18_02_coverage_rates.xlsx`

---

### Bloc C — Subventions indirectes

#### Étape 19 — Subventions énergie et eau `19_subsidies.R`

**Objectif** : mesurer les subventions implicites sur les utilités.

**Travail à faire :**
- Subventions carburant (si actives en 2021, PETROCI/prix administré)
- Eau/électricité : tarif social SODECI/CIE vs coût économique
- Calcul : `subsidy = (prix_marché − prix_payé) × quantité_consommée`
- Impact distributif des subventions (souvent régressives)

**Inputs :**
- Module énergie/eau EHCVM (quantités consommées, dépenses)
- Grilles tarifaires SODECI/CIE 2021
- Prix carburant administré vs prix de parité importation

**Outputs :**
- `SILVER/19/subsidies.parquet` — `hhid, subsidy_fuel, subsidy_utility`

---

### Bloc D — Transferts en nature

#### Étape 20 — Éducation publique `20_inkind_education.R`

**Objectif** : allouer les dépenses publiques d'éducation aux ménages bénéficiaires.

**Travail à faire :**
- Identifier les enfants scolarisés dans le public par niveau (maternelle, primaire,
  secondaire 1er/2e cycle, supérieur) depuis le module éducation EHCVM
- Dépense publique unitaire par niveau (depuis budget fonctionnel MEN/MESRS)
- Allouer : `educ_inkind = Σ enfants_public_niveau_k × cout_unitaire_k`
- Incidence des dépenses par quintile (beneficiary incidence)

**Inputs :**
- Module éducation EHCVM (variables fréquentation, type établissement)
- Budget MEN/MESRS CIV 2021 (dépenses par niveau, nombre élèves)

**Outputs :**
- `SILVER/20/inkind_education.parquet` — `hhid, educ_inkind`
- `TABLES/20/20_01_beneficiary_incidence_educ.xlsx`
- Figure : incidence dépenses éducation par quintile

---

#### Étape 21 — Santé publique `21_inkind_health.R`

**Objectif** : allouer les dépenses publiques de santé aux ménages utilisateurs.

**Travail à faire :**
- Identifier les contacts de soins dans établissements publics depuis le module santé EHCVM
  (consultation, hospitalisation, PMI…)
- Coût unitaire par type de contact (CSU, district, CHU) depuis comptes de santé CIV
- Allouer : `health_inkind = Σ contacts_public_type_k × cout_unitaire_k`
- Construire `final_income = consumable_income + educ_inkind + health_inkind`

**Inputs :**
- Module santé EHCVM (consultations, hospitalisations, type établissement)
- Comptes nationaux de santé CIV 2021 ou budget MSHP

**Outputs :**
- `SILVER/21/inkind_health.parquet` — `hhid, health_inkind`
- `TABLES/21/21_01_beneficiary_incidence_health.xlsx`
- Figure : incidence dépenses santé par quintile

---

### Bloc E — Synthèse CEQ

#### Étape 22 — Concepts de revenu complets `22_income_concepts.R`

**Objectif** : assembler les 7 concepts et calculer les indicateurs synthétiques.

**Travail à faire :**
- Joindre tous les modules (16–21) sur `hhid`
- Construire la cascade Y_M → Y_NM → Y_G → Y_T → Y_D → Y_C → Y_F
- Gini pour chaque concept
- FGT (P0/P1/P2) pour chaque concept vs seuil `zref`
- Table CEQ maîtresse (format standard CEQ Institute)

**Outputs :**
- `SILVER/22/all_income_concepts.parquet`
- `TABLES/22/22_01_ceq_master_table.xlsx` — Gini + FGT pour les 7 concepts
- `TABLES/22/22_02_gini_by_concept.xlsx`

---

#### Étape 23 — Progressivité et contribution marginale `23_marginal_contribution.R`

**Objectif** : mesurer la contribution de chaque instrument à la réduction des inégalités.

**Travail à faire :**
- Kakwani et Reynolds-Smolensky pour **chaque** instrument séparément :
  IRPP, cotisations, pensions, transferts, TVA, accises, douanes, subsidies, éducation, santé
- Contribution marginale au Gini (méthode séquentielle ou décomposition de Shapley)
- Tableau de synthèse comparatif

**Outputs :**
- `TABLES/23/23_01_kakwani_all_instruments.xlsx`
- `TABLES/23/23_02_marginal_contribution.xlsx`
- Figure : contribution marginale par instrument (barres empilées)

---

#### Étape 24 — Appauvrissement fiscal et gains pour les pauvres `24_fiscal_impoverishment.R`

**Objectif** : mesurer les cas où le système fiscal nuit aux pauvres (Higgins-Lustig 2016).

**Travail à faire :**
- **Fiscal impoverishment** : ménages non pauvres (Y_M) qui deviennent pauvres (Y_C ou Y_F)
- **Fiscal gains to the poor** : ménages pauvres dont Y_F > Y_M
- Décomposition par instrument (quelle intervention appauvrissante ?)
- Indicateurs : FI headcount, FI gap, FGP headcount, FGP amount

**Référence** : Higgins & Lustig (2016), *Journal of Development Economics*

**Outputs :**
- `TABLES/24/24_01_fiscal_impoverishment.xlsx`
- `TABLES/24/24_02_fiscal_gains_poor.xlsx`

---

#### Étape 25 — Rapport CEQ standardisé `25_ceq_report_tables.R`

**Objectif** : produire les tables au format CEQ Institute pour comparabilité internationale.

**Travail à faire :**
- Tables maîtresses CEQ : incidence par centile, Gini, FGT, Kakwani
- Scénarios contrefactuels : avec/sans CMU, avec/sans réforme TVA (lien step 15)
- Export Excel multi-onglets au format CEQ Working Paper standard
- Vérification cohérence avec benchmark ECAM/PNUD si disponible

**Outputs :**
- `TABLES/25/CEQ_CIV_2021_master.xlsx` — rapport complet
- `07_reports/CEQ_CIV_2021_draft.pdf` (optionnel, via R Markdown / Quarto)

---

## Données manquantes à identifier

| Donnée | Source | Usage | Disponibilité |
|---|---|---|---|
| Module revenus/emploi EHCVM 2021 | INS Côte d'Ivoire | Étape 16 — IRPP, cotisations | À vérifier |
| Barème IRPP CIV (CGI) | Code Général des Impôts | Étape 16 | Public |
| Taux CNPS (cotisations) | CNPS / CGI | Étape 16 | Public |
| Module éducation EHCVM 2021 | INS Côte d'Ivoire | Étape 20 | À vérifier |
| Module santé EHCVM 2021 | INS Côte d'Ivoire | Étape 21 | À vérifier |
| Budget MEN/MESRS CIV 2021 | Ministère des Finances | Étape 20 | Public |
| Comptes santé CIV 2021 | MSHP / OMS | Étape 21 | Partiellement public |
| Grilles tarifaires SODECI/CIE 2021 | SODECI / CIE | Étape 19 | Public |
| Prix carburant administré 2021 | PETROCI / sources presse | Étape 19 | Public |
| TEC CEDEAO + concordance SH→codpr | CEDEAO / OMC | Étape 17 | Public |
| Taux accises CIV 2021 (LFI) | Loi de Finances 2021 | Étape 17 | Public |
| Documentation PFISP | Ministère des Affaires Sociales | Étape 18 | Partiellement public |

---

## Priorités recommandées

```
Immédiat     → Commiter les 4 fixes + steps 13–15
               (nettoyage branche avant nouvelles étapes)

Court terme  → Étapes 16–17 (impôts directs + accises)
               Déblocage du Net Market Income
               Condition : identifier module revenus EHCVM

Moyen terme  → Étapes 18–21 (transferts + in-kind)
               Complétion du Final Income
               Condition : données budget MEN/MSHP + modules EHCVM

Long terme   → Étapes 22–25 (synthèse + rapport CEQ publishable)
               Condition : toutes étapes précédentes validées
```

---

## Architecture pipeline cible

```
00_master.R
├── Bloc 0 — Fondations (01–03)        ✅
├── Bloc 1 — Analyse TVA (04–09)       ✅
├── Bloc 2 — Réformes TVA (10–15)      ⏳ steps 13–15 à commiter
├── Bloc A — Impôts directs (16–17)    ❌ à construire
├── Bloc B — Transferts (18)           ❌ à construire
├── Bloc C — Subsidies (19)            ❌ à construire
├── Bloc D — In-kind (20–21)           ❌ à construire
└── Bloc E — Synthèse CEQ (22–25)      ❌ à construire
```

---

*Document créé le 2026-04-19. Mettre à jour au fur et à mesure de l'avancement.*
