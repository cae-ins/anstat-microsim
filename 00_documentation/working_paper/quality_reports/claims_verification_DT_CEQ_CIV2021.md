# Vérification des affirmations — DT_CEQ_CIV2021

**Date :** 19 juillet 2026
**Protocole :** Chain-of-Verification adapté en mode séquentiel
**Résultat :** **PARTIAL — 0 contradiction, indépendance par contexte séparé indisponible**

La session n'autorisait pas la création d'un agent vérificateur indépendant. Les affirmations ont donc été contrôlées séquentiellement contre les classeurs du pipeline et les pages officielles, sans bénéficier de l'indépendance architecturale complète du protocole CoVe.

## Affirmations numériques

| ID | Affirmation vérifiée | Source | Verdict |
|---|---|---|---|
| C1 | Gini : 0,3414 au revenu primaire et 0,3168 au revenu final | `22_01_income_concepts.xlsx` | conforme |
| C2 | Pauvreté : 37,7 % au revenu primaire et 42,0 % au revenu consommable | `22_01_income_concepts.xlsx` | conforme |
| C3 | 4,34 % de la population passe sous le seuil; pertes de 142,7 mds FCFA | `24_01_fiscal_impoverishment.xlsx` | conforme |
| C4 | Pauvreté comptable au revenu final : 33,9 % | `22_01_income_concepts.xlsx` | conforme |
| C5 | Réforme large : 97,2 mds, +0,47 point sans recyclage, -0,23 avec recyclage | `15_05_budget_neutral_recycling.xlsx` et tableaux de l'étape 15 | conforme |
| C6 | IRPP 225,5 mds; cotisations 162,4 mds | `16_03_coverage_kakwani.xlsx` | conforme |
| C7 | Accises 67,9 mds; droits de douane 185,1 mds | `17_04_macro_validation.xlsx` | conforme |
| C8 | PSSN : 191 767 ménages, 27,108 mds, facteur de calage 1,000739 | `18_02_coverage_targeting.xlsx` et `18_03_macro_validation.xlsx` | conforme |
| C9 | Réductions de prix : 25,15 mds, dont 8,69 d'électricité | `19_04_macro_validation.xlsx` | conforme |
| C10 | Éducation nette : 1 301,6 mds; santé nette : 81,85 mds | tableaux des étapes 20 et 21 | conforme |
| C11 | Contributions de Shapley : indirects 0,0084; directs 0,0070; éducation 0,0068; santé 0,0018 | `23_01_shapley_pdi.xlsx` | conforme |
| C12 | Consommation EHCVM = 59,9 % de la consommation finale des ménages ANStat | feuille `controle_macro_ANSTAT` du classeur maître de l'étape 25 | conforme |

## Attributions littéraires

| ID | Attribution | Source primaire consultée | Verdict |
|---|---|---|---|
| L1 | Le manuel CEQ organise l'incidence des impôts et dépenses sur pauvreté et inégalité | Brookings, page officielle du *Commitment to Equity Handbook* (2022) | conforme |
| L2 | Un système progressif peut appauvrir certains ménages pauvres | Higgins et Lustig, *Journal of Development Economics* (2016) | conforme |
| L3 | La part des achats informels diminue avec le revenu et modifie la progressivité des taxes à la consommation | Bachas, Gadenne et Jensen, *Review of Economic Studies* (2024) | conforme |
| L4 | Les exonérations peuvent créer une taxe incorporée par les intrants | Chandler, Thomas et Tremblay, World Bank Policy Research Working Paper 11120 (2025) | conforme |
| L5 | Les transferts monétaires peuvent mieux cibler les pauvres que les exonérations de TVA | Warwick et coauteurs, *World Development* (2022) | conforme |
| L6 | Le PMT prédit le niveau de vie avec des caractéristiques observables du ménage | Grosh et Baker, Banque mondiale, LSMS Working Paper 118 (1995) | conforme |
| L7 | Akim et coauteurs analysent Côte d'Ivoire, Mali et Sénégal avec enquêtes, CEQ et OpenFisca | AFD Research Paper 190 (2020) | conforme |
| L8 | La 21e CIST a adopté les nouvelles normes sur l'économie informelle en 2023 | OIT/ILOSTAT | conforme |

## Conclusion

Aucune contradiction n'a été trouvée. Le statut reste PARTIAL uniquement parce que la vérification n'a pas été exécutée dans un contexte indépendant. Une reprise future avec un agent `claim-verifier` peut transformer ce contrôle en PASS architectural sans modifier le manuscrit si les mêmes sources sont utilisées.
