# Audit de reproductibilité numérique — DT_CEQ_CIV2021

**Date :** 23 juillet 2026
**Manuscrit :** `00_documentation/working_paper/DT_CEQ_CIV2021.tex`
**Sorties :** `07_reports/tables/` et `02_data_intermediate/`
**Tolérances :** `psantanna-core/references/rules/replication-protocol.md`
**Exécution contrôlée :** étapes 1 à 26 réexécutées après intégration du plan de sondage dans les régressions de TVA; 452,17 secondes

## Résumé

| Statut | Nombre |
|---|---:|
| PASS | 19 |
| FAIL | 0 |
| EXPLAINED | 11 |
| UNMATCHED | 0 |
| **Verdict global** | **PASS** |

Le fichier `reproducibility_claims_DT_CEQ_CIV2021.json` conserve les 30 comparaisons, leurs sources et leurs valeurs non arrondies. Aucun chiffre du papier n’est en contradiction avec une sortie calculée.

Les trois nouveaux groupes de claims portent sur les régressions de sondage : effectif, coefficients M3, erreurs-types, effet d’une hausse de 10~\%, terme quadratique et comparaison S1--S2. Leurs treize composantes numériques sont toutes dans les tolérances prescrites.

Les onze lignes `EXPLAINED` relèvent d’une seule alternative nommée : la précision d’affichage. Les masses nationales sont généralement publiées à un chiffre après la virgule ou au milliard entier, les revenus moyens au FCFA entier et les effectifs pondérés à l’unité. Dans tous les cas, la sortie non arrondie donne exactement la valeur affichée. Plusieurs affirmations de ce type figuraient déjà comme `EXPLAINED` dans l’audit précédent; pour éviter qu’un désaccord permanent ne se cache derrière cette catégorie, la règle d’affichage est désormais explicitement inscrite dans le fichier de claims. Il ne subsiste aucun désaccord de spécification.

## Comparaison des affirmations principales

| ID | Affirmation publiée | Valeur calculée | Statut |
|---|---|---|---|
| C1 | Gini 0,3409 → 0,3167 | 0,340882241 → 0,316712385 | PASS |
| C2 | Pauvreté 37,72 %; 42,04 %; 33,92 % | 37,7152 %; 42,0360 %; 33,9189 % | PASS |
| C3 | Nouveaux pauvres 4,35 %; pertes 142,84; gains 9,35 mds | 4,35045 %; 142,83539; 9,35379 mds | PASS |
| C4 | Réforme large : 97,2 mds; +0,47 pt; −0,22 pt | 97,17114 mds; +0,47420 pt; −0,22470 pt | EXPLAINED — affichage |
| C5 | IRPP 206,9; cotisations 162,4 mds | 206,87979; 162,35905 mds | EXPLAINED — affichage |
| C6 | Accises 67,9; douane 185,1 mds | 67,92661; 185,11129 mds | EXPLAINED — affichage |
| C7 | PSSN : 191 767 ménages; 27,108 mds; facteur 1,000739 | 191 767,374; 27,108; 1,000738720 | EXPLAINED — poids arrondis |
| C8 | Variante PSSN : 192 544 ménages; 79,5 % pauvres | 192 543,7; 79,4664 % | EXPLAINED — poids arrondis |
| C9 | Réductions de prix 25,15, dont électricité 8,69 mds | 25,15377; 8,69000 mds | PASS |
| C10 | Éducation nette 1 301,62; santé nette 81,85 mds | 1 301,61884; 81,84601 mds | PASS |
| C11 | Shapley : indirects 0,00849; directs 0,00650; éducation 0,00682 | 0,00849286; 0,00649577; 0,00681571 | PASS |
| C12 | Consommation de l’enquête / comptes : 59,9 % | 59,9334 % | PASS |
| C13 | TVA finale 697; enchâssée 214; totale 912 mds | 697,22299; 214,34131; 911,56431 mds | EXPLAINED — affichage au milliard |
| C14 | Droit à déduction : 214,4 → 22,3; total 719,6 mds | 214,34131 → 22,32718; total 719,55017 | EXPLAINED — affichage |
| C15 | IRPP central/strict/élargi : 206,9/176,7/197,8 | 206,8798/176,6522/197,8046 | EXPLAINED — affichage |
| C16 | Sensibilité P95, P99,5 et sans winsorisation | écarts de −5,586 %, +0,985 % et +1,957 % | PASS |
| C17 | Après TVA : 193 926 ménages et 1 055 501 personnes | 193 926,072 et 1 055 500,904 | EXPLAINED — poids arrondis |
| C18 | TRE courant − ICIO : −0,015 pt, IC [−0,108; 0,070] | −0,0150, IC [−0,1079; 0,0702] | PASS |
| C19 | Robustesses S3, collecte amont et non-raccordés | toutes les masses s’arrondissent aux valeurs publiées | EXPLAINED — affichage |
| C20 | Six revenus moyens au FCFA entier | écarts inférieurs à 0,5 FCFA | EXPLAINED — affichage |
| C21 | RS direct +0,0063; Kakwani IRPP 0,453 | 0,006335; 0,453184 | PASS |
| C22 | Répartition électrique : variation du Gini 0,00010 | 0,00010456 | PASS |
| C23 | Robustesses éducation et santé du revenu final | six taux conformes à moins de 0,01 point | PASS |
| C24 | Convergence Shapley à 500 tirages | écart maximal 0,0000694 | PASS |
| C25 | Réforme : 37,95/37,25/37,29/37,21/37,32 % | 37,946/37,247/37,286/37,212/37,323 % | PASS |
| C26 | Population 30,09 millions; tailles 4,62 et 4,97 | conforme aux sorties et au rapport brut | PASS |
| C27 | IRPP D1/D5/D10 et part D10 | écarts inférieurs à 0,01 point | PASS |
| C28 | Régression de sondage : 12 965 ménages | 12 965; 66 strates; 1 015 ddl | PASS |
| C29 | S3 M3 : consommation 0,01251 (0,000447); +0,119 pt pour 10 %; urbain 0,005197 (0,000393) | 0,0125102323 (0,0004470022); +0,119235 pt; 0,0051966090 (0,0003930426) | PASS |
| C30 | Quadratique 0,000428 (0,000302), p=0,157; S1/S2 0,01751/0,006757 | 0,0004275392 (0,0003021536), p=0,157395; 0,0175058541/0,0067573564 | PASS |

## Contrôles automatiques du paquet de réplication

- pré-contrôle : **41 PASS, 0 WARN, 0 FAIL**;
- vérification finale : **32 PASS, 0 FAIL**;
- parité de la carte des **33** tableaux et figures avec les labels LaTeX : PASS;
- identités CEQ ménage par ménage : PASS;
- fermeture de la décomposition de Shapley : PASS;
- environnement : R 4.5.3 sous Windows 11, `renv.lock` présent;
- capture : `replication_package/environment/sessionInfo.txt`.

Les anciennes valeurs de référence dans `replication_package/output/expected_metrics.csv` ont été remplacées par les sorties recalculées. Le tableau méthodologique supprimé lors du raccourcissement de l’introduction a également été retiré de `replication_package/exhibit_map.csv`. Le programme `01_verify_outputs.R` aboutit désormais sans échec.

## Verdict

Le papier satisfait le contrôle de reproductibilité numérique sur l’arbre courant : zéro FAIL, zéro UNMATCHED et tous les écarts d’affichage reliés à une valeur non arrondie identifiable. La version peut être figée après les derniers contrôles éditoriaux et la mise à jour de la mémoire de projet.