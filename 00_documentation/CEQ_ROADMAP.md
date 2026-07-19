# Feuille de route — Modèle CEQ Côte d'Ivoire (EHCVM 2021)

> **Objectif** : construire un modèle d'incidence fiscale complet suivant le cadre
> *Commitment to Equity* (Lustig et al.) pour la Côte d'Ivoire à partir de
> l'EHCVM 2021. Le modèle produit les 7 concepts de revenu CEQ standard et
> mesure l'impact distributif de chaque instrument fiscal et de dépense publique.

---

## État d'avancement

| # | Étape | Description | Statut |
|---|---|---|---|
| 01 | `01_prepare_data` | Nettoyage EHCVM, winsorisation, mapping COICOP | ✅ Exécutable et vérifié |
| 02 | `02_mapping_tax` | Mapping TVA officielle par codpr | ✅ Exécutable et vérifié |
| 03 | `03_compute_taxes` | TVA directe au niveau ménage, ancrée sur le revenu disponible | ✅ Exécutable et vérifié |
| 04 | `04_analysis` | Analyse distributive (déciles, quintiles, milieu, région) | ✅ Commité |
| 05 | `05_progressivity` | Kakwani, Reynolds-Smolensky, courbes de Lorenz/concentration | ✅ Commité |
| 06a | `06_01_sensitivity_taxation` | Sensibilité scénarios d'informalité (strict / CEI×milieu / CEI×décile) | ✅ Commité |
| 06b | `06_02_sensitivity_ranking` | Sensibilité classements (total / pc / AE1 / AE2) | ✅ Exécutable et vérifié |
| 07 | `07_appendix_tables` | Tableaux annexes | ✅ Commité |
| 08 | `08_figures` | Figures analytiques fig1–fig4 | ✅ Commité |
| 09 | `09_vat_determinants` | Déterminants TVA effective (régressions OLS) | ✅ Commité |
| 10 | `10_reform_chicken_inputs` | Simulation réforme intrants avicoles, Kakwani | ✅ Commité |
| 11 | `11_reform_figures` | Figures réforme figR1–figR4 | ✅ Commité |
| 12 | `12_poverty_incidence` | FGT (P0/P1/P2) avant/après TVA, 3 scénarios, milieu, région | ✅ Exécutable et vérifié |
| 13 | `13_leontief_io` | TVA enchâssée : TRE 2023 central, TRE constant et ICIO 2020 en robustesse | ✅ Exécutable et vérifié |
| 14 | `14_leontief_poverty` | Pauvreté après TVA directe et enchâssée, inférence Rao--Wu appariée | ✅ Exécutable et vérifié |
| 15 | `15_reform_vat_simulation` | Réforme 0%→9%, S1/S2/S3 et recyclage universel à budget constant | ✅ Exécutable et vérifié |
| 16 | `16_direct_taxes` | IS, CN, IGR, CNPS et CMU; reconstruction PDI provisoire depuis `Y_D` | ✅ Vérifié dans la reprise complète |
| 17 | `17_indirect_other` | Accises 2021 et droits de douane TEC au niveau ménage | ✅ Vérifié dans la reprise complète |
| 18 | 18_transfers | Pensions, transferts directs et filets sociaux; scénarios PDI/PGT | ✅ Vérifié dans la reprise complète |
| 19 | 19_subsidies | Réductions publiques de prix de l'électricité et de l'eau; carburants en robustesse | ✅ Vérifié dans la reprise complète |
| 20 | 20_inkind_education | Services publics d'éducation, bruts et nets des frais des familles | ✅ Vérifié dans la reprise complète |
| 21 | 21_inkind_health | Services publics de santé sans recours central au statut d'assurance EHCVM | ✅ Vérifié dans la reprise complète |
| 22 | 22_income_concepts | Sept concepts de revenu et identités CEQ complètes | ✅ Vérifié dans la reprise complète |
| 23 | 23_marginal_contribution | Progressivité et décomposition exacte de Shapley | ✅ Vérifié dans la reprise complète |
| 24 | 24_fiscal_impoverishment | Appauvrissement fiscal et gains sous le seuil | ✅ Vérifié dans la reprise complète |
| 25 | 25_ceq_report_tables | Classeur CEQ, contrôles ANStat et manifeste de réplication | ✅ Vérifié dans la reprise complète |

> **Convention de numérotation** : la colonne `#` renvoie au numéro de *script*.
> L'étape d'orchestrateur correspondante dans `00_master.R` est décalée de +1 à
> partir de `06_02` (les deux scripts 06 comptent pour deux étapes) : le script
> `16_direct_taxes.R` est ainsi l'**étape 17** de `lance_pipeline`, d'où
> `lance_pipeline(17,17)`. Les étapes ci-dessous sont numérotées en
> étapes d'orchestrateur (18 à 26), avec le nom de script en regard ; les étapes 18 à 26 sont désormais vérifiées.

### Correctifs récents

- une reprise fraîche des étapes 1 à 13 puis 14 à 26 a abouti le 19 juillet
  2026; les deux segments se suivent sur les mêmes sorties intermédiaires
- les étapes 7 et 13 ne réintroduisent plus des colonnes déjà présentes lors
  des jointures; ce correctif rend la chaîne reproductible depuis zéro sans
  modifier les variables économiques

- `01_prepare_data.R` utilise désormais `load_raw_dta()` et des validations de colonnes
- `02_mapping_tax.R` passe par la couche d'I/O commune pour le fichier Excel de mapping
- `06_02_sensitivity_ranking.R` a été stabilisé sur la jointure welfare et les contrôles d'entrée
- `09_vat_determinants.R` a été corrigé sur la jointure `region` et l'alignement du clustering `grappe`
- `12_poverty_incidence.R` vérifie explicitement les colonnes welfare critiques
- `utils/io.R` centralise désormais les contrôles d'existence, lectures `csv/xlsx`, et validations de schéma
- le TRE 2023 est construit aux prix de base, en séparant emplois domestiques et
  importés; la concordance déterministe `itemid` → 52 secteurs des do-files
  Banque mondiale est réemployée avant le passage vers les 48 produits du TRE
- les intervalles des effets distributifs utilisent un bootstrap Rao--Wu
  respectant strates et grappes; les comparaisons de matrices et de réformes
  réutilisent les mêmes réplications
- le proxy d'assujettissement fiscal Banque mondiale est distinct du diagnostic
  d'emploi formel au sens de l'OIT, qui n'est pas utilisé comme assiette centrale

### État de couverture

La cascade CEQ est complète jusqu'au revenu final. Les limites restantes portent
sur la qualité de certaines sources, les hypothèses de transmission et la
comparabilité des repères macroéconomiques; elles ne correspondent plus à des
étapes manquantes.

---

## Concepts de revenu CEQ

Le scénario PDI suit exactement `12. CIV21WBN_ceqincome.do`. L'agrégat de
consommation officiel `pcexp` est l'ancre du revenu disponible `yd_pc` ;
`conso_w`, limité aux postes de consommation imposables, est une assiette
d'imputation fiscale et non un revenu de marché. Le revenu de marché est
reconstruit à rebours, puis les concepts CEQ sont calculés en avant.

```
Y_D  Disposable income          = pcexp                                      [ancre observée]
Y_P  Market income + pensions   = Y_D + impôts directs + cotisations - transferts directs
Y_M  Market income              = Y_P                                        [convention PDI CIV]
Y_N  Net market income          = Y_P - impôts directs - cotisations
Y_G  Gross income               = Y_P + transferts directs
Y_D  Disposable income          = Y_N + transferts directs
Y_C  Consumable income          = Y_D - taxes indirectes + subventions indirectes
Y_F  Final income               = Y_C + éducation + santé + autres transferts en nature
```

`Y_N` et `Y_G` sont deux branches issues de `Y_P`, non deux maillons successifs.
Le revenu imposable est une assiette administrative interne au calcul de
l'impôt ; il ne constitue pas un concept de revenu CEQ. `Y_D` est observé et
`Y_C` et `Y_F` sont désormais construits. L'étape 19 remplace la remontée
provisoire de l'étape 17 par des concepts cohérents avec les transferts : PDI
est central et PGT constitue la robustesse, avec fermeture exacte de
`Y_D=Y_N+R` dans les deux cas.

---

## Feuille de route détaillée

### Bloc A — Impôts directs et cotisations

#### Étape 17 (script `16_direct_taxes.R`) — IRPP et cotisations sociales

**Objectif** : calculer la charge des impôts directs et des cotisations par ménage.

**Travail réalisé :**
- revenu salarial et statut d'emploi identifiés dans les modules emploi principal
  et secondaire de l'EHCVM ;
- proxy fiscal central reproduit depuis les do-files Banque mondiale, avec
  scénarios strict et élargi en robustesse ; indicateur OIT conservé comme
  diagnostic séparé ;
- barèmes CGI 2021 appliqués à l'individu : IS, Contribution nationale et IGR
  par quotient familial ;
- CNPS salariée plafonnée et CMU simulée séparément selon la calibration du
  do-file de référence, avec universalité statutaire en robustesse ;
- agrégation au ménage, intervalles Rao--Wu et export des prélèvements nécessaires
  à la reconstruction PDI provisoire.

**Inputs :**
- modules emploi, statut professionnel, bulletin de paie et protection sociale EHCVM ;
- barèmes CGI 2021 et paramètres CNPS/CMU ;
- do-files Banque mondiale `11. CIV21WBN_nhi.do` et
  `12. CIV21WBN_ceqincome.do`.

**Outputs :**
- `02_data_intermediate/16/direct_taxes.parquet` — prélèvements individuels
  et ménages, variables de couverture et concepts PDI provisoires ;
- `07_reports/tables/16/16_01_irpp_by_decile.xlsx` à
  `07_reports/tables/16/16_10_burden_denominators.xlsx` ;
- `07_reports/figures/fig16_direct_burden_decile.png`.

**Point de vigilance** : le revenu salarial peut être sous-reporté et le proxy
fiscal ne doit pas être interprété comme la définition statistique OIT de
l'emploi formel. Les concepts provisoires de cette étape sont remplacés par les
scénarios PDI/PGT complets de l'étape 19.

---

#### Étape 18 (script `17_indirect_other.R`) — Droits de douane et accises ✅

**Objectif atteint** : étendre l’impôt indirect au-delà de la TVA, sans calage
sur les recettes administratives.

**Implémentation validée :**
- accises 2021 sur alcool, tabac, boissons non alcoolisées, cosmétiques et
  carburants, avec cascade légale droits de douane → accise → TVA ;
- bandes du TEC CEDEAO 0/5/10/20/35 %, part importée et correction des marges
  issues du TRE 2023 ;
- transmission centrale intégrale, avec variantes S2/S3 pour l’alcool et le
  tabac ;
- bootstrap Rao--Wu à 500 réplications pour les indices de Kakwani ;
- validation micro--macro contre la loi de règlement 2021, sans forcer les
  masses ménages à reproduire les recettes couvrant toute l’économie.

**Résultats vérifiés :** 67,9 milliards de FCFA d’accises et 185,1 milliards de
droits de douane imputés aux ménages ; couverture TEC de 100 % et couverture
TRE de 92,3 %. Le Kakwani vaut 0,102 pour les accises et 0,059 pour les droits
de douane.

**Outputs :**
- `02_data_intermediate/17/indirect_other.parquet` ;
- `07_reports/tables/17/17_01_excise_by_decile.xlsx` à
  `17_05_mapping_diagnostics.xlsx` ;
- `07_reports/figures/fig17_indirect_other_decile.png` ;
- paramètres et sources dans `01_data_sources/params_indirect_other_2021.xlsx`
  et `NOTE_METHODOLOGIQUE_ACCISES_DOUANES_2021.md`.

**Limite résiduelle :** la version 1 impute les effets directs. La propagation
Leontief des droits de douane et de l’accise sur les carburants reste une
extension, de même que l’identification fine SH lorsque la nomenclature EHCVM
le permettra.

---

### Bloc B — Transferts directs

#### Étape 19 (script `18_transfers.R`) — Pensions, transferts directs et filets sociaux ✅

**Objectif atteint** : construire les transferts publics monétaires et fermer la
branche directe CEQ à partir de `Y_D`, en distinguant pensions contributives,
transferts publics, transferts privés et prestations en nature.

**Implémentation validée :**
- PSSN imputé par un score PMT déterministe puis calé sur 192 000 ménages servis
  en 2021 : 177 000 ménages à quatre paiements et 15 000 à trois paiements de
  36 000 FCFA ;
- participation aux quatorze programmes S15 conservée comme diagnostic de
  couverture et de ciblage ; les aliments, soins, HIMO et moustiquaires ne sont
  pas confondus avec un transfert monétaire ;
- bourses directement identifiées dans S02 pour le secondaire général et le
  supérieur publics ;
- prestations familiales simulées selon les barèmes CNPS et accidents du
  travail répartis comme dépense annuelle moyenne entre les travailleurs présumés couverts à partir
  de la cotisation retraite et de la durée d'emploi, sans utiliser l'assurance maladie ;
- scénario central PDI, où pensions et cotisations retraite sont du revenu
  différé, et robustesse PGT, où elles deviennent transfert et prélèvement ;
- pensions alimentaires et envois de fonds S13 présentés séparément, car il s'agit de transferts entre ménages et non de paiements publics ;
- bootstrap Rao--Wu à 500 réplications et contrôle observation par observation
  de l'identité `Y_D = Y_N + R`.

**Sorties vérifiées :**
- `02_data_intermediate/18/transfers.parquet` ;
- `07_reports/tables/18/18_01_beneficiaries_by_decile.xlsx` à
  `18_06_progressivity_inference.xlsx` ;
- `07_reports/figures/fig18_transfers_decile.png` ;
- `01_data_sources/params_transfers_2021.xlsx`, reproductible par
  `utils/build_transfers_params.R`.

**Résultats centraux :** 27,108 milliards de FCFA de PSSN, 6,090 milliards de
bourses, 84,324 milliards de prestations familiales et 8,276 milliards
AT/MP, soit 125,798 milliards de transferts nominaux. Les pensions observées
atteignent 252,603 milliards. L'indice de ciblage `Gini - concentration` vaut
0,092, IC à 95 % [0,040 ; 0,149]. La sélection discrète représente 191 767
ménages pondérés ; l'écart de 233 ménages à la cible est inférieur au poids du
ménage frontière et le facteur de calage de masse est 1,00074.

**Limites résiduelles :** le PMT est une reconstruction transparente, pas le
registre administratif du PSSN. La dépense AT/MP provient du matériel technique
CEQ et n'est pas une validation indépendante. Les prestations familiales
reposent sur l'éligibilité statutaire et la cohabitation observée. En PGT,
0,124 % de la population appartient à un ménage dont `Y_P` reconstruit est
négatif ; les Gini de scénario appliquent donc explicitement un plancher à zéro.

---

### Bloc C — Réductions publiques de prix

#### Étape 20 (module 19_subsidies.R) — Électricité, eau et carburants ✅

L'étape répartit 8,69 milliards de FCFA d'aide électrique documentée par
l'ANARE-CI selon les quantités estimées à partir des factures et des tarifs
sociaux/domestiques. Elle estime 16,46 milliards de réduction de prix de l'eau
par inversion du barème SODECI. Le soutien carburant central est nul faute de
prix de parité 2021 auditable; une borne haute postérieure est isolée en
robustesse. La masse centrale totale est 25,15 milliards. Les scénarios
d'abonnés sociaux, de revente d'eau et de carburant sont publiés séparément.

### Bloc D — Services publics en nature

#### Étape 21 (module 20_inkind_education.R) — Éducation publique ✅

Les élèves du public sont identifiés dans le module éducation de l'EHCVM par
fréquentation, niveau et type d'établissement. Les dépenses exécutées sont
divisées par les effectifs pondérés de chaque niveau. La dépense publique
attribuée atteint 1 354,87 milliards de FCFA au coût public, puis
1 301,62 milliards après déduction des frais directement payés par les
familles. Les variantes dépenses courantes et déduction de tous les frais sont
conservées. Chaque budget de niveau est réconcilié exactement.

#### Étape 22 (module 21_inkind_health.R) — Santé publique ✅

Les déclarations d'assurance maladie des questions 32 à 37 ne sont pas utilisées
dans l'allocation centrale. Pour les consultations publiques, une dépense
publique moyenne attendue est calculée par âge, sexe et milieu; les petites
cellules sont remplacées par une moyenne âge-sexe nationale. Les
hospitalisations publiques restent fondées sur les séjours observés sur douze
mois. La dépense attribuée vaut 108,53 milliards de FCFA au coût public et
81,85 milliards nette des paiements directs. Des variantes d'usage observé, de
budget large et de poids hospitalier encadrent le résultat.

### Bloc E — Synthèse CEQ

#### Étape 23 (module 22_income_concepts.R) — Concepts de revenu complets ✅

Les prélèvements, paiements publics, impôts indirects, réductions de prix,
services d'éducation et de santé sont réunis sans recalculer les instruments.
Les sept concepts de revenu sont construits sous les deux conventions de
pension. Toutes les identités ferment ménage par ménage. Le Gini passe de
0,3414 au revenu primaire à 0,3168 au revenu final; le taux de pauvreté passe
de 37,70 % à 42,01 % au revenu consommable, puis à 33,90 % au revenu final.

#### Étape 24 (module 23_marginal_contribution.R) — Shapley ✅

La variation du Gini est décomposée exactement entre six groupes sur les
64 sous-ensembles et les 720 ordres possibles. Les impôts indirects expliquent
34,1 % de la réduction totale, les prélèvements directs 28,6 %, l'éducation
27,7 %, la santé 7,3 % et les paiements publics directs 2,9 %. Cinquante
réplications Rao--Wu encadrent la décomposition complète.

#### Étape 25 (module 24_fiscal_impoverishment.R) — Appauvrissement fiscal ✅

L'analyse compare les revenus monétaires primaire et consommable, sans traiter
les services d'éducation et de santé comme de l'argent disponible. Elle mesure
4,34 % de nouveaux pauvres, 142,73 milliards de pertes sous le seuil et
9,30 milliards de gains. Les intervalles utilisent 500 réplications Rao--Wu.

#### Étape 26 (module 25_ceq_report_tables.R) — Rapport CEQ ✅

Le classeur CEQ_CIV_2021_master.xlsx regroupe les concepts de revenu,
instruments, résultats Shapley, appauvrissement fiscal, contrôles macroéconomiques
ANStat, variables et calage PMT, coefficients et dictionnaire. Un manifeste CSV
et JSON conserve empreintes des fichiers, version de R et état Git. Les
graphiques des étapes 20 à 25 n'utilisent aucune couleur violette.

Les méthodes détaillées, données, robustesses et références sont consignées
dans PLAN_ETAPES20_26_FINALISATION_CEQ.md et dans le document de travail.

---
## État des données nécessaires

| Donnée | Source | Usage | Disponibilité |
|---|---|---|---|
| Module revenus/emploi EHCVM 2021 | INS Côte d'Ivoire | Étapes 17 et 19 | Présent et audité |
| Barème IRPP CIV (CGI) | Code Général des Impôts | Étape 17 | Encodé |
| Taux CNPS et paramètres CMU | CNPS / CGI / do-files BM | Étape 17 | Encodés |
| Module éducation EHCVM 2021 | INS Côte d'Ivoire | Étape 21 | Présent, audité et rapproché des budgets |
| Module santé EHCVM 2021 | INS Côte d'Ivoire | Étape 22 | Présent et audité; assurance déclarée non utilisée au centre |
| Budget MEN/MESRS CIV 2021 | Ministère des Finances | Étape 21 | Encodé et réconcilié |
| Dépenses exécutées de santé 2021 | Ministère du Budget / MSHP | Étape 22 | Encodées et réconciliées |
| Grilles et aide électricité/eau 2021 | ANARE-CI / SODECI | Étape 20 | Encodées et réconciliées |
| Prix carburant administré 2021 | PETROCI / sources presse | Étape 20 | Public |
| TEC CEDEAO + concordance SH→codpr | CEDEAO / OMC | Étape 18 | Encodé et vérifié |
| Taux accises CIV 2021 (LFI) | Loi de Finances 2021 | Étape 18 | Encodé et vérifié |
| PSSN, CNPS, pensions et modules S02/S04/S05/S13/S15 | Rapports officiels + EHCVM | Étape 19 | Encodé, imputé et vérifié |

---

## Améliorations futures

La chaîne de calcul n'a plus de module manquant. Les améliorations futures
portent sur les sources et non sur la structure : disposer d'un prix de parité
carburant 2021, remplacer la référence technique AT/MP par une exécution
administrative indépendante, obtenir des comptes de santé plus détaillés et
apparier, lorsque cela sera possible, le registre PSSN à l'enquête.

---

## Architecture exécutée

    00_master.R
    ├── Bloc 0 — Fondations (étapes 01–03)           ✅
    ├── Bloc 1 — Analyse TVA (étapes 04–09)          ✅
    ├── Bloc 2 — Réformes TVA (étapes 10–16)         ✅
    ├── Bloc A — Prélèvements (étapes 17–18)         ✅
    ├── Bloc B — Paiements publics (étape 19)        ✅
    ├── Bloc C — Réductions de prix (étape 20)       ✅
    ├── Bloc D — Éducation et santé (étapes 21–22)   ✅
    └── Bloc E — Synthèse CEQ (étapes 23–26)         ✅

---

*Document créé le 2026-04-19 et mis à jour après validation des 26 étapes le
2026-07-19.*