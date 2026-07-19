# Audit de reproductibilité numérique — DT_CEQ_CIV2021

**Date :** 19 juillet 2026
**Manuscrit :** `00_documentation/working_paper/DT_CEQ_CIV2021.tex`
**Sorties :** `07_reports/tables/` et `02_data_intermediate/`
**Tolérances :** `psantanna-core/references/rules/replication-protocol.md`
**Exécution contrôlée :** `replication_package/output/logs/full_run_20260719_220317.log`

## Résumé

| Statut | Nombre |
|---|---:|
| PASS | 7 |
| FAIL | 0 |
| EXPLAINED | 8 |
| UNMATCHED | 0 |
| **Verdict global** | **PASS** |

Les huit lignes `EXPLAINED` ne signalent pas un désaccord de fond. Elles
correspondent à une alternative nommée et vérifiable : le papier affiche les
masses en milliards avec un ou plusieurs chiffres après la virgule, tandis que
les classeurs conservent les valeurs non arrondies. Dans chaque cas, la valeur
calculée s'arrondit exactement à la valeur publiée. Les effectifs non entiers du
PSSN sont des sommes de poids d'enquête et sont affichés à l'unité la plus proche.

## Comparaison des affirmations principales

| ID | Affirmation publiée | Valeur calculée | Statut |
|---|---|---|---|
| C1 | Gini 0,3414 → 0,3168 | 0,341420936 → 0,316765191 | PASS |
| C2 | Pauvreté 37,70 %; 42,01 %; 33,90 % | 37,70247 %; 42,01295 %; 33,89753 % | PASS |
| C3 | Nouveaux pauvres 4,34 %; pertes 142,73; gains 9,30 mds | 4,340155 %; 142,733076; 9,297973 mds | PASS |
| C4 | Réforme large : 97,2 mds; +0,47 pt; −0,23 pt | 97,171135 mds; +0,474198 pt; −0,224696 pt | EXPLAINED — arrondi d'affichage |
| C5 | IRPP 225,5; cotisations 162,4 mds | 225,5185; 162,3591 mds | EXPLAINED — arrondi d'affichage |
| C6 | Accises 67,9; douane 185,1 mds | 67,926608; 185,111294 mds | EXPLAINED — arrondi d'affichage |
| C7 | PSSN : 191 767 ménages; 27,108 mds; facteur 1,000739 | 191 767,374; 27,108; 1,000738720 | EXPLAINED — poids arrondis à l'unité |
| C8 | PSSN déclarations d'abord : 192 544; 79,5 % pauvres | 192 543,7; 79,46638 % | EXPLAINED — poids arrondis à l'unité |
| C9 | Réductions de prix 25,15, dont électricité 8,69 mds | 25,15377; 8,69000 mds | PASS |
| C10 | Éducation nette 1 301,62; santé nette 81,85 mds | 1 301,618841; 81,84601 mds | PASS |
| C11 | Shapley : 0,0084; 0,0070; 0,0068; 0,0018 | 0,008414805; 0,007045237; 0,006833985; 0,001801687 | PASS |
| C12 | Couverture de la consommation ANStat : 59,9 % | 59,93338 % | PASS |
| C13 | TVA directe 692,9; incorporée 214,4; totale 907,3 mds | 692,8879; 214,43992; 907,3279 mds | EXPLAINED — arrondi d'affichage |
| C14 | Sensibilité juridique : 214,4 → 22,3 mds | 214,43992 → 22,32836 mds | EXPLAINED — arrondi d'affichage |
| C15 | Effectifs et masses des trois scénarios directs | Effectifs identiques; masses non arrondies conformes | EXPLAINED — arrondi d'affichage |

Le fichier `reproducibility_claims_DT_CEQ_CIV2021.json` contient les sources et
les tolérances affirmation par affirmation. Le contrôle automatique plus large
compte 32 PASS et 0 FAIL; il vérifie aussi les identités CEQ, la fermeture de
Shapley, les fichiers sensibles aux corrections Refine.ink et la parité des 34
labels de tableaux et figures avec la carte de réplication.

## Environnement

- R 4.5.3 sous Windows 11;
- environnement figé dans `renv.lock`;
- détails dans `replication_package/environment/sessionInfo.txt`;
- durée observée : 350,4 secondes;
- prévol : 40 PASS, 0 WARN, 0 FAIL;
- vérification finale : 32 PASS, 0 FAIL.

## Verdict

Aucune contradiction numérique et aucune affirmation principale sans
contrepartie calculée. Le papier satisfait le contrôle de reproductibilité
numérique sur l'arbre courant.
