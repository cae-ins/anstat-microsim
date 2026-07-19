# Étape 19 — Pensions, transferts directs et filets sociaux

Date de cadrage : 19 juillet 2026.

## Objectif

L’étape 19 construit les transferts directs publics reçus par les ménages et
ferme la branche directe de la cascade CEQ à partir du revenu disponible
observé dans l’EHCVM 2021. Elle distingue explicitement les transferts
monétaires, les pensions contributives, les transferts privés et les
prestations en nature afin d’éviter les doubles comptes avec les étapes santé,
éducation et autres transferts en nature.

Les paiements publics monétaires comprennent ici le PSSN, les bourses, les
prestations familiales et les indemnisations d'accidents du travail. Ils sont
ajoutés au revenu net de marché pour retrouver le revenu disponible. Les
pensions alimentaires et les envois de fonds entre ménages sont présentés
séparément, car ils ne sont pas versés par une administration.

Les identités sont écrites avec R pour les paiements publics monétaires, D pour
les impôts directs et C pour les cotisations. Ces lettres abrègent des montants
déjà définis; elles ne constituent pas des catégories supplémentaires :

    revenu primaire = revenu disponible + impôts directs + cotisations
                       - paiements publics monétaires
    revenu net de marché = revenu primaire - impôts directs - cotisations
    revenu brut = revenu primaire + paiements publics monétaires
    revenu disponible = revenu net de marché + paiements publics monétaires

Le revenu disponible reste ancré sur la consommation par personne de l'EHCVM.
Chaque identité est vérifiée ménage par ménage.
## Traitement des pensions

Le scénario central suit l’approche CEQ *Pensions as Deferred Income* (PDI).
Les pensions contributives sont du revenu différé et les cotisations retraite
ne sont pas assimilées aux cotisations sociales non pension. Pour la Côte
d’Ivoire, la convention centrale est donc `Y_P = Y_L`.

Le scénario de robustesse *Pensions as Government Transfers* (PGT) classe les
pensions observées comme transferts publics et les cotisations retraite comme
prélèvements. Le revenu disponible doit être identique dans les deux scénarios.

Les pensions alimentaires et les transferts reçus de parents ou de ménages privés
sont présentés séparément. Ils déplacent de l'argent entre ménages et ne sont
donc pas comptés comme paiements publics.

## Instruments

| Instrument | Source enquête | Source externe | Allocation centrale |
|---|---|---|---|
| PSSN/PFSP | S15, PMT et caractéristiques du ménage | effectifs actifs, paiements et montant 2021 | ciblage PMT déterministe et calage sur la cible |
| Bourses | S02, montant déclaré | budgets et bénéficiaires | identification directe |
| Prestations familiales | S01, S02, S04 et couverture salariale | barèmes et dépenses CNPS | éligibilité statutaire simulée |
| Accidents du travail | S04 : cotisation retraite et durée d'emploi, sans statut d'assurance maladie | dépenses AT/MP | dépense annuelle moyenne répartie entre travailleurs présumés couverts |
| Autres aides cash | S15 | documentation de programme | inclusion seulement si monétisable et documentée |
| Pensions | S05 | CNPS et CGRAE | diagnostic PDI, transfert en PGT |
| Transferts privés | S05 et S13 | — | présentés séparément, jamais ajoutés aux paiements publics |
| Prestations en nature S15 | S15 | coût des programmes | hors étape 19 |

## Principes d’allocation

1. Le PSSN central est calé sur un nombre de ménages effectivement payés dans
   la période de référence, et non sur un cumul historique de bénéficiaires.
2. Le rang de ciblage est déterministe. Une variation aléatoire autour du seuil
   n’est admise qu’en sensibilité avec graine fixe.
3. S15 sert à mesurer la couverture déclarée et les erreurs de ciblage. Comme
   il ne contient pas les montants, il ne peut pas constituer seul l’assiette
   monétaire centrale.
4. Les bourses déclarées dans S02 sont utilisées directement, sous contrôles
   d’outliers et comparaison au budget.
5. Les aliments, soins, moustiquaires, formations et autres prestations en
   nature ne sont pas agrégés aux transferts monétaires.
6. Les montants sont conservés en francs courants pour les masses budgétaires,
   puis ajustés par `def_spa` avant d’être combinés à `pcexp`.

## Données mobilisées

### Enquête

- `s05_me_CIV2021.dta` : retraite, réversion, invalidité et pension alimentaire ;
- `s02_me_CIV2021.dta` : bourses et scolarisation ;
- `s15_me_CIV2021.dta` : demandes, participation et fréquence des programmes ;
- `ehcvm_individu_CIV2021.dta` et modules S01/S04 : âge, lien, emploi et couverture ;
- `fiscal_data_analysis_ready.parquet` : ancre `Y_D`, rangs, poids et plan de sondage ;
- `direct_taxes.parquet` : IRPP, CNPS et CMU ;
- `indirect_other.parquet` : raccord ultérieur vers le revenu consommable partiel.

### Sources externes

- Lustig (dir., 2022), *Commitment to Equity Handbook*, pour PDI/PGT et les
  concepts de revenu ;
- Akim, Ben Jelloul, Czajka et Robilliard (2020), pour la comparaison
  d’incidence en Afrique de l’Ouest francophone ;
- Grosh et Baker (1995), *Proxy Means Tests for Targeting Social Programs*,
  pour la logique générale du test indirect de niveau de vie ;
- Banque mondiale (2015), document d’évaluation du Projet Filets Sociaux
  Productifs P143332, pour le système de ciblage et le registre social
  ivoiriens ;
- le rapport annuel de performance budgétaire 2021 pour les paiements du PSSN,
  les bourses, les prestations familiales et les accidents du travail ;
- CNPS et CGRAE pour les barèmes, effectifs et dépenses.

Chaque valeur externe est encodée avec son URL, son champ, son année et une
note de comparabilité dans `params_transfers_2021.xlsx`.

## Sorties produites

- `02_data_intermediate/18/transfers.parquet` ;
- `07_reports/tables/18/18_01_beneficiaries_by_decile.xlsx` ;
- `18_02_coverage_targeting.xlsx` ;
- `18_03_macro_validation.xlsx` ;
- `18_04_pension_scenarios.xlsx` ;
- `18_05_ceq_identity_checks.xlsx` ;
- `18_06_progressivity_inference.xlsx` ;
- `07_reports/figures/fig18_transfers_decile.png`.

## Validation

- un ménage unique par `hhid`, sans montant négatif ou non fini ;
- couverture complète de la base fiscale ;
- cibles PSSN et masses administratives documentées ;
- absence de double compte des pensions et des transferts privés ;
- identités CEQ vérifiées au centime près ;
- comparaison PDI/PGT et bootstrap Rao--Wu à 500 réplications ;
- aucune modification des résultats des étapes 1 à 18.

## Statut de mise en œuvre

L'étape est implémentée et vérifiée par
`source("05_scripts_R/00_master.R"); lance_pipeline(19, 19)`.

La sortie centrale contient 12 965 ménages uniques. Le PSSN est calé à
27,108 milliards de FCFA, les accidents du travail à 8,276 milliards, et les
identités PDI/PGT ferment avec un écart absolu maximal de `9,31e-10`.
L'indice de ciblage des transferts est de 0,092, avec un intervalle Rao--Wu à
95 % de [0,040 ; 0,149].