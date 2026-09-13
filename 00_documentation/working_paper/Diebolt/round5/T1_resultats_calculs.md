# T1 — Résultats des calculs (round 5)

Tâche T1 du `plan_round5.md` : réestimation de la pente de l'annexe B avec contrôle de
quantité, construction de S5 / S5′, portage de S4 dans la chaîne entrées–sorties,
effet sur la pauvreté de la variante $e_i^L$ du droit à déduction, diagnostic et
harmonisation de l'écart 2,17 / 2,35 entre les étapes 12 et 14.
Couvre M1(i), M2, M3 (volet calcul) et le point mineur 1.

Référentiel de comparaison : `Diebolt/round5/T0_baseline.md` et `Diebolt/round5/baseline/`
(HEAD `90515e7`). Toutes les valeurs ci-dessous portent le chemin de la sortie dont elles
sont lues. Aucune valeur n'est calculée à la main : les nombres du mémo sont recopiés des
classeurs produits par le pipeline.

---

## 0. Verdict en tête, pour T5 et T9

**Le message de l'annexe B reste « infirmé », et il est renforcé, pas affaibli.**
Après contrôle intra-cellule de la quantité achetée, la pente de prix des produits taxés
relativement aux non taxés reste négative, $-0{,}284$ % par décile, avec un intervalle de
confiance à 95 % de $[-0{,}514 ; -0{,}054]$. La valeur impliquée par le gradient alimentaire
de S3 ($+0{,}552$ %) reste **hors de cet intervalle**, et de très loin. La contingence
prévue par le brief (« si l'IC corrigé contient $+0{,}55$ %, le résultat devient non
concluant ») **ne s'est pas réalisée**. T5 et T9 peuvent donc conserver la formulation
« infirmé pour l'alimentation », en indiquant que la pente présentée est celle obtenue
avec contrôle de quantité.

Le contrôle est loin d'être cosmétique : le coefficient de la quantité relative est
$-0{,}158$ (une remise de gros nette et fortement significative), mais il déplace la pente
d'intérêt de seulement $0{,}005$ point de pourcentage. Autrement dit, la remise de gros
existe bien, elle est massive, et elle n'est pas ce qui produit la pente négative observée
entre produits taxés et non taxés.

---

## 1. Réestimation de la pente de l'annexe B avec contrôle de quantité

Source : `07_reports/tables/06/06_05_unit_value_gradient.xlsx`,
feuilles `gradient_specifications` et `confrontation_specifications`
(nouvelles ; la feuille `gradient` conserve la spécification brute à l'identique et la
feuille `confrontation_s3` est inchangée).
Code : `05_scripts_R/utils/informality_anchor.R`, fonction `vat_unit_value_gradient()`.

Transformation ajoutée : `log_quantite_relatif` $= \log(\text{quantite}) -$ moyenne pondérée
de $\log(\text{quantite})$ **à l'intérieur de la cellule produit × unité × conditionnement ×
région**, exactement la même opération que celle qui construit `prix_relatif`. Le contrôle
reste donc un contrôle intra-cellule. Erreurs types agrégées par grappe, comme
précédemment. Échantillon inchangé : 141 928 achats, 2 563 cellules exploitables.

### Pente du logarithme du prix unitaire relatif, par rang de décile

| Spécification | Produits non taxés | Produits taxés | Différence (taxés − non taxés) | Erreur type de la différence | $p$ | IC 95 % de la différence | Coefficient de quantité |
|---|---|---|---|---|---|---|---|
| Pente brute (héritée) | $+0{,}008520$ | $+0{,}005625$ | $-0{,}002895$ | $0{,}001157$ | $0{,}0123$ | $[-0{,}005162 ; -0{,}000628]$ | — |
| **Contrôle de quantité (principale)** | $+0{,}008388$ | $+0{,}005547$ | $\mathbf{-0{,}002841}$ | $0{,}001172$ | $0{,}0154$ | $\mathbf{[-0{,}005138 ; -0{,}000543]}$ | $-0{,}157720$ |
| Contrôle de quantité interagi | $+0{,}008379$ | $+0{,}005554$ | $-0{,}002825$ | $0{,}001180$ | $0{,}0166$ | $[-0{,}005137 ; -0{,}000513]$ | $-0{,}168099$ (interaction avec `taxe` : $+0{,}024355$) |

Observations : 82 306 (non taxés), 59 622 (taxés), 141 928 (différence).

### Confrontation à S3, spécification par spécification

Source : même classeur, feuille `confrontation_specifications`.

| Spécification | Pente de prix impliquée par S3 | Pente de prix observée | IC 95 % | S3 dans l'intervalle ? | Pente $\alpha$ impliquée par l'observation |
|---|---|---|---|---|---|
| Brute | $+0{,}005521$ | $-0{,}002895$ | $[-0{,}005162 ; -0{,}000628]$ | **non** (0) | $-0{,}017827$ |
| **Contrôle de quantité** | $+0{,}005521$ | $-0{,}002841$ | $[-0{,}005138 ; -0{,}000543]$ | **non** (0) | $\mathbf{-0{,}017494}$ |
| Contrôle interagi | $+0{,}005521$ | $-0{,}002825$ | $[-0{,}005137 ; -0{,}000513]$ | **non** (0) | $-0{,}017398$ |

Taux de TVA moyen des produits taxés retenus : $\tau = 0{,}169909$ (inchangé).
Pente $\alpha$ postulée par S3 pour l'alimentation : $s_1 = 0{,}034$.

Ni le signe ni l'ampleur ne changent : la pente corrigée vaut 98 % de la pente brute. Le
rejet du gradient alimentaire de S3 tient donc à la comparaison entre produits taxés et non
taxés à l'intérieur d'une même cellule, et non à un effet de remise de gros mal contrôlé.

### Deux éléments de texte à intégrer en prose par T5 (annexe B)

Le brief demande de transmettre ces deux points, à présenter comme un raffinement
méthodologique de l'exercice, non comme une réponse au rapporteur.

1. L'EHCVM 2021 ne contient aucune variable de lieu d'achat ni de mode d'acquisition
   formel/informel des produits de consommation (modules 7A, 7B et 9) : un balayage
   exhaustif des 53 fichiers de l'enquête l'établit. Le canal de taxation ne peut donc être
   identifié qu'indirectement, par les valeurs unitaires du module 7B.
2. Le contrôle intra-cellule de la quantité achetée en une fois est la meilleure correction
   disponible avec les données existantes contre la confusion entre remise de gros et
   circuit taxé. La pente présentée est celle obtenue avec ce contrôle ; la pente brute est
   rapportée pour comparaison.

Ces deux phrases sont aussi consignées dans la feuille `notes` du classeur
`06_05_unit_value_gradient.xlsx`.

---

## 2. Définition et paramètres de S5 et S5′

Source : `07_reports/tables/06/06_03_vat_informality_parameters.xlsx`, feuilles
`parametres_S5`, `matrice_S5`, `matrice_S5b`, `alpha_scenarios_s4_s5`.
Code : `05_scripts_R/utils/vat_scenarios.R`, fonctions `vat_alpha_decile_s5()`,
`vat_alpha_decile_s5_mean_food()`, `vat_alpha_decile_s5_matrix()`.

Pour la seule fonction COICOP 1 (alimentation), le profil $\alpha_1(d) = 0{,}12 + (d-1)\times
0{,}034$ de S3 est remplacé par $\alpha_1(d) = \bar\alpha_1 + (d - 5{,}5)\,s_5$ avec
$\bar\alpha_1 = 0{,}12 + 4{,}5\times 0{,}034 = 0{,}273$, la valeur de S3 au rang médian. Le
niveau moyen est donc tenu constant et seul l'effet de pente est isolé. Les douze autres
fonctions gardent exactement le profil de S3. $\alpha$ est borné dans $[0,1]$ (la borne n'est
jamais atteinte ici).

| Paramètre | Valeur | Source |
|---|---|---|
| $\bar\alpha_1$ (niveau moyen conservé) | $0{,}273$ | `parametres_S5` |
| Pente alimentaire de S3 (référence) | $0{,}034$ | `parametres_S5` |
| **S5** — pente nulle | $s_5 = 0$ | `parametres_S5` |
| **S5′** — pente estimée | $s_5 = \hat\pi\,(1+\bar\alpha_1\tau)/\tau = \mathbf{-0{,}017494}$ | `parametres_S5` |
| $\hat\pi$ retenu (pente corrigée) | $-0{,}002841$ | `confrontation_specifications` |
| $\tau$ | $0{,}169909$ | `confrontation_specifications` |

Profil alimentaire résultant (feuilles `matrice_S5` et `matrice_S5b`) :

| Décile | D1 | D2 | D3 | D4 | D5 | D6 | D7 | D8 | D9 | D10 |
|---|---|---|---|---|---|---|---|---|---|---|
| S3 | 0,120 | 0,154 | 0,188 | 0,222 | 0,256 | 0,290 | 0,324 | 0,358 | 0,392 | 0,426 |
| **S5** | 0,273 | 0,273 | 0,273 | 0,273 | 0,273 | 0,273 | 0,273 | 0,273 | 0,273 | 0,273 |
| **S5′** | 0,3517 | 0,3342 | 0,3167 | 0,2992 | 0,2817 | 0,2643 | 0,2468 | 0,2293 | 0,2118 | 0,1943 |

S5 est la variante à publier dans les tableaux du corps ; S5′ est à rapporter en texte ou en
annexe.

La table $\alpha$ est persistée en `02_data_intermediate/06/alpha_scenarios_s4_s5.parquet`
(colonnes `coicop_num`, `decile`, `alpha_4`, `alpha_5`, `alpha_5b`) et relue par l'étape 13b,
de sorte que la TVA directe seule et la chaîne entrées–sorties portent sur exactement les
mêmes coefficients.

**Cohérence des déciles vérifiée, pas supposée.** Le décile de l'étape 4 (porté par
`fiscal_data_analysis_ready.parquet`, construit par `weighted_ntile(yd_pc, pcweight)`) et
celui de l'étape 6 (`weighted_ntile(pcexp, pcweight)`) coïncident pour les 12 965 ménages
(taux d'accord 1,000 ; `yd_pc` et `pcexp` sont strictement identiques). Une assertion
bloquante a été ajoutée dans `13b_leontief_local_io.R` : le script s'arrête si les deux
déciles divergent.

---

## 3. Résultats S4, S5 et S5′

### 3.1 Masses de TVA (milliards de FCFA, nominal)

Sources : `07_reports/tables/13/13_03_local_io_diagnostics_current.xlsx` (13b) et
`07_reports/tables/06/06_01_*` (TVA directe seule). Les deux chaînes donnent exactement la
même masse directe pour chaque scénario, à $10^{-10}$ près.

| Scénario | Directe | Enchâssée | Totale |
|---|---|---|---|
| S1 (strict) | 1 398,43 | 206,09 | 1 604,52 |
| S2 | 743,75 | 213,92 | 957,66 |
| **S3 (central)** | **697,22** | **214,34** | **911,56** |
| **S4** (borne d'offre) | **860,29** | **212,16** | **1 072,45** |
| **S5** (pente nulle) | **689,19** | **214,57** | **903,75** |
| **S5′** (pente estimée) | **685,05** | **214,68** | **899,73** |
| S3 avec $e_i^L$ | 697,22 | 22,33 | 719,55 |

Aplatir la pente alimentaire à niveau moyen constant abaisse légèrement la masse directe
($-8{,}0$ milliards sous S5, $-12{,}2$ sous S5′, soit $-1{,}2$ % et $-1{,}8$ %) : à niveau
moyen égal, la dépense alimentaire absolue étant plus élevée en haut de distribution, une
pente positive collecte un peu plus qu'une pente plate.

### 3.2 Progressivité (TVA directe seule, classement $Y_D$)

Sources : `07_reports/tables/06/06_01_ceq_summary_scenarios.xlsx` et
`07_reports/tables/06/06_01_bootstrap_kakwani.xlsx` (bootstrap Rao–Wu, 500 réplications).

| Scénario | Kakwani (point) | Kakwani bootstrap (moyenne) | IC 95 % | RS |
|---|---|---|---|---|
| S1 | 0,07556 | 0,07558 | [0,06734 ; 0,08385] | 0,006937 |
| S2 | 0,13186 | 0,13161 | [0,12274 ; 0,14037] | 0,006381 |
| **S3** | **0,16483** | **0,16463** | **[0,15688 ; 0,17274]** | **0,007567** |
| **S4** | **0,10432** | **0,10426** | **[0,09645 ; 0,11231]** | **0,005854** |
| **S5** | **0,15610** | **0,15590** | **[0,14797 ; 0,16412]** | **0,007070** |
| **S5′** | **0,15152** | **0,15132** | **[0,14323 ; 0,15975]** | **0,006815** |

Le sens du biais demandé par le rapporteur est confirmé et chiffrable : une pente
alimentaire plus plate abaisse le Kakwani de $0{,}0087$ (S5) ou $0{,}0133$ (S5′) et le RS
de $0{,}0005$ à $0{,}0008$. La progressivité mesurée sous S3 est donc surestimée. L'ampleur
reste modérée : les intervalles de S3 et de S5 se chevauchent partiellement.

### 3.3 Effet sur la pauvreté (étape 15, TRE 2023 courant, bootstrap Rao–Wu 500)

Source : `07_reports/tables/14/14_01_fgt_comparison.xlsx`.
$P_0$ avant TVA : $37{,}472$ %.

| Scénario | Composante | $P_0$ après (%) | $\Delta P_0$ (points) | IC 95 % |
|---|---|---|---|---|
| S1 | directe | 43,645 | 6,173 | [5,545 ; 6,888] |
| S2 | directe | 40,351 | 2,879 | [2,367 ; 3,481] |
| **S3** | directe | 39,822 | **2,350** | [1,891 ; 2,867] |
| **S4** | **directe** | **41,018** | **3,546** | **[3,031 ; 4,077]** |
| **S5** | **directe** | **39,831** | **2,359** | **[1,901 ; 2,873]** |
| **S5′** | **directe** | **39,858** | **2,386** | **[1,933 ; 2,903]** |
| S1 | directe + enchâssée | 44,544 | 7,072 | [6,387 ; 7,765] |
| S2 | directe + enchâssée | 41,427 | 3,956 | [3,375 ; 4,577] |
| **S3** | directe + enchâssée | 41,013 | **3,541** | [3,019 ; 4,099] |
| **S4** | **directe + enchâssée** | **41,971** | **4,499** | **[3,898 ; 5,120]** |
| **S5** | **directe + enchâssée** | **41,032** | **3,561** | **[3,027 ; 4,117]** |
| **S5′** | **directe + enchâssée** | **41,053** | **3,581** | **[3,037 ; 4,120]** |
| **$e_i^L$ (S3, droit juridique)** | **directe + enchâssée** | **39,894** | **2,422** | **[1,963 ; 2,921]** |

Ces six lignes nouvelles (`cur_direct_s4`, `cur_total_s4`, `cur_direct_s5`, `cur_total_s5`,
`cur_direct_s5b`, `cur_total_s5b`) et la ligne `cur_total_s3_legal` sont désormais produites
par `14_leontief_poverty.R` avec le même bootstrap conjoint que S1–S3 : une même réplication
Rao–Wu sert à tous les concepts, ce qui rend les écarts entre concepts comparables.

### 3.4 Nouveaux pauvres et appauvrissement

Source : `07_reports/tables/14/14_04_new_poor_by_scenario.xlsx` (sortie nouvelle).
Population pondérée de référence : 29 809 415 personnes (6 445 888 ménages).

| Scénario | Composante | Ménages nouveaux pauvres | Personnes nouvelles pauvres | Part de population (%) | Part appauvrie au sens Higgins–Lustig (%) |
|---|---|---|---|---|---|
| S1 | directe + enchâssée | 390 818 | 2 108 046 | 7,072 | 44,54 |
| **S3** | directe + enchâssée | **193 926** | **1 055 501** | **3,541** | **41,01** |
| **S4** | directe | 195 890 | 1 057 152 | 3,546 | 41,02 |
| **S4** | **directe + enchâssée** | **248 063** | **1 341 255** | **4,499** | **41,97** |
| **S5** | directe | 135 611 | 703 261 | 2,359 | 39,83 |
| **S5** | **directe + enchâssée** | **194 571** | **1 061 376** | **3,561** | **41,03** |
| **S5′** | directe | 136 793 | 711 181 | 2,386 | 39,86 |
| **S5′** | **directe + enchâssée** | **195 590** | **1 067 494** | **3,581** | **41,05** |
| **$e_i^L$** | **directe + enchâssée** | **138 613** | **721 963** | **2,422** | **39,89** |

La colonne « part appauvrie au sens Higgins–Lustig » compte les personnes qui subissent une
perte à l'étape TVA **et** se trouvent sous le seuil après TVA ; comme presque tous les
ménages acquittent une TVA non nulle, elle est très proche du $P_0$ après TVA. C'est la part
de population *nouvellement* pauvre (colonne précédente) qui porte l'information utile.
Le chiffre de 4,35 % cité dans le papier reste, lui, celui de l'étape 25 sur la cascade CEQ
complète, et il est inchangé (`07_reports/tables/24/`).

### 3.5 Lecture pour T5

- **S4 remplace S1 comme borne haute de référence** : 3,55 point de $\Delta P_0$ en TVA
  directe et 4,50 en directe + enchâssée, contre 6,17 et 7,07 sous S1. C'est bien une borne
  haute, mais ancrée sur l'offre ivoirienne observée.
- **S5 confirme le sens du biais et le borne** : la progressivité mesurée sous S3 est
  surestimée (Kakwani $0{,}165 \to 0{,}156$) et l'appauvrissement sous-estimé
  ($3{,}54 \to 3{,}56$ point en directe + enchâssée ; $3{,}58$ sous S5′). Le sens est celui
  qu'annonce le rapporteur et il renforce la thèse du papier, mais l'ampleur est faible :
  l'effet pauvreté ne se déplace que de $0{,}02$ à $0{,}04$ point, très en deçà de la largeur
  des intervalles de confiance. La conclusion honnête est que le paramétrage de la pente
  alimentaire affecte nettement l'indice de progressivité et très peu l'effet pauvreté.
- **$e_i^L$ est l'incertitude de premier ordre du papier** : $\Delta P_0$ passe de
  $3{,}541$ [3,019 ; 4,099] à $2{,}422$ [1,963 ; 2,921], soit $-1{,}119$ point, une baisse de
  32 %. La composante enchâssée n'ajoute alors que $0{,}072$ point à l'effet de la TVA
  directe seule ($2{,}350$), contre $1{,}191$ point sous la définition retenue. Les
  intervalles se chevauchent à peine. Ce n'est donc **pas** un argument de robustesse : le
  brief de T5 prévoit ce cas, et le passage du §5.3 comme `sec:limites` doivent présenter la
  définition du droit à déduction comme la principale incertitude du papier. La case
  « -- » du tableau 5 et la note « son effet sur la pauvreté n'est pas recalculé » peuvent
  être remplacées par $+2{,}42$ point, IC $[1{,}96 ; 2{,}92]$.

---

## 4. Diagnostic 2,17 / 2,35 et nouvelles valeurs de l'annexe B

### 4.1 Diagnostic

Source : `07_reports/tables/12/12_06_deflation_convention.xlsx` (sortie nouvelle).

L'écart est **entièrement** dû à une incohérence de convention de déflation entre scripts, et
à rien d'autre. Trois vérifications, sur les 12 965 ménages appariés :

1. **Les masses sont rigoureusement identiques.** `vat_s3` (étape 6) et
   `vat_direct_local_s3` (étape 13b) valent tous deux 697,223 milliards, avec un écart
   ménage par ménage maximal de $4{,}7\times10^{-10}$ FCFA et une corrélation de 1,000. Il
   n'y a donc **aucun** changement de périmètre entre l'annexe B et le tableau 4 (ni
   `depan_w`, ni périmètre TRE, ni définition de $\alpha$).
2. **Les déciles coïncident exactement** (taux d'accord 1,000), donc les $\alpha$ appliqués
   sont les mêmes.
3. **La déflation explique la totalité de l'écart.** L'étape 12 soustrayait la charge
   *nominale* de `pcexp`, qui est un agrégat spatialement déflaté, alors que l'étape 15
   soustrait `vat_direct_local_s3_real` $=$ `vat_s3` $\times$ `def_spa`. En reproduisant le
   calcul de l'étape 12 avec la charge déflatée, on retrouve $2{,}350286$ %, c'est-à-dire à
   la dernière décimale la valeur de l'étape 15 ; réciproquement, en soustrayant la charge
   nominale dans l'étape 15, on retrouve $2{,}174457$ %.

| Scénario | $\Delta P_0$ convention nominale | $\Delta P_0$ convention réelle | Écart (points) | Masse nominale (Mds) | Masse réelle (Mds) |
|---|---|---|---|---|---|
| S1 (strict) | 6,096 | 6,173 | +0,077 | 1 398,43 | 1 436,68 |
| S3 | 2,174 | 2,350 | +0,176 | 697,22 | 721,20 |
| S4 | 3,517 | 3,546 | +0,030 | 860,29 | 887,43 |

`def_spa` moyen pondéré : 1,00121 ; sa dispersion (de 0,862 à 1,103) suffit à déplacer le
$\Delta P_0$ de S3 de 0,18 point, parce que les ménages proches du seuil sont concentrés dans
les régions où le déflateur s'écarte le plus de 1.

### 4.2 Harmonisation retenue

`12_poverty_incidence.R` a été aligné sur la convention réelle de l'étape 15, qui est celle
du corps du texte. Les colonnes `pcexp_after_*` sont désormais construites à partir de
`vat_*_real`. Les variantes nominales sont conservées sous les noms
`pcexp_after_*_nominal` uniquement pour alimenter le tableau de diagnostic
`12_06_deflation_convention.xlsx`, de sorte que l'écart reste vérifiable.

### 4.3 Nouvelles valeurs de l'annexe B pour T5

Source : `07_reports/tables/12/12_01_fgt_national.xlsx`, désormais identique à
`07_reports/tables/14/14_01_fgt_comparison.xlsx` pour les concepts communs.

| Phrase de l'annexe B (l. 2536–2537 et 2616 du `.tex`) | Valeur actuelle | **Valeur harmonisée** |
|---|---|---|
| TVA directe sous S4 | 3,52 | **3,55** |
| TVA directe sous S1 | 6,10 | **6,17** |
| TVA directe sous S3 | 2,17 | **2,35** |

La valeur S3 de l'annexe B devient donc exactement celle du tableau 4, ce qui clôt le point
mineur 1 sans avoir à invoquer un changement de périmètre. T5 doit expliciter la convention
(charge déflatée par `def_spa`, identique au corps du texte) au moment de citer ces trois
chiffres. La phrase du `sec:limites` « abaisse la borne haute de la charge de 6,10 à 3,52
points de pauvreté » devient « de 6,17 à 3,55 points ».

Table complète après harmonisation (`12_01_fgt_national.xlsx`) :

| Concept | $P_0$ | $\Delta P_0$ (points) |
|---|---|---|
| Avant TVA | 37,472 | — |
| Après TVA — S1 | 43,645 | 6,173 |
| Après TVA — S2 | 40,351 | 2,879 |
| Après TVA — S3 | 39,822 | 2,350 |
| Après TVA — S4 | 41,018 | 3,546 |
| Après TVA — S5 | 39,831 | 2,359 |
| Après TVA — S5′ | 39,858 | 2,386 |

---

## 5. Vérifications de non-régression

Toutes les vérifications prescrites au point « Relances » du brief T1 ont été exécutées après
`lance_pipeline(6, 7)`, `lance_pipeline(13, 16)` et `lance_pipeline(23, 26)`.

**(a) Macros de tête invariantes.**
`git diff --stat 00_documentation/working_paper/generated/ceq_summary_values.tex` renvoie une
sortie vide : les 17 macros sont bit-à-bit identiques.

**(b) Identités comptables fermées à $10^{-6}$.**
`07_reports/tables/22/22_03_identity_checks.xlsx` : six lignes, toutes `valide = TRUE`,
écart maximal $1{,}86\times10^{-9}$ (PDI disponible $9{,}31\times10^{-10}$, PDI brut 0,
PGT disponible $1{,}86\times10^{-9}$, PGT brut 0, revenu consommable 0, revenu final 0).
`07_reports/tables/18/18_05_ceq_identity_checks.xlsx` : les deux lignes $Y_D = Y_N + R$ sont
au statut `OK`, écarts absolus maximaux $9{,}31\times10^{-10}$ et $1{,}86\times10^{-9}$.

**(c) Valeurs S3 inchangées.**

| Grandeur | Référence T0 | Après T1 | Verdict |
|---|---|---|---|
| Masses S3 (directe / enchâssée / totale) | 697,223 / 214,341 / 911,564 | 697,223 / 214,341 / 911,564 | identique |
| Kakwani S3 (point) | 0,164825 | 0,164825 | identique |
| Kakwani S3 bootstrap et IC | 0,164631 [0,156878 ; 0,172744] | 0,164631 [0,156878 ; 0,172744] | identique |
| $\Delta P_0$ S3 directe | 2,350286 [1,891 ; 2,867] | 2,350286 [1,891 ; 2,867] | identique |
| $\Delta P_0$ S3 directe + enchâssée | 3,540831 [3,019 ; 4,099] | 3,540831 [3,019 ; 4,099] | identique |
| Shapley pauvreté (12 lignes PDI et PGT) | — | — | fichier bit-à-bit identique |

**(d) `13_07_legal_deduction_sensitivity.xlsx` inchangé pour les masses.**
Feuille `comparaison_macro` : S3 697,223 / 214,341 / 911,564 et S3 juridique
697,223 / 22,327 / 719,550, strictement identiques à la copie T0.

**Comparaison exhaustive des sorties.** Un balayage automatisé de toutes les feuilles de
tous les classeurs des dossiers 06, 12, 13, 14, 22, 23, 24 et 25 contre les copies de
`Diebolt/round5/baseline/` donne :

- **Dossiers 22, 23, 24, 25 : aucune différence**, sur aucune feuille, sur aucune cellule.
  La cascade CEQ complète, la décomposition de Shapley, l'appauvrissement fiscal et les
  tables finales sont donc rigoureusement invariants.
- Dossiers 06, 13 et 14 : uniquement des **ajouts** de lignes ou de colonnes (S4, S5, S5′,
  `cur_total_s3_legal`). Après réappariement sur la clé de scénario ou de concept, l'écart
  numérique maximal sur les lignes et colonnes préexistantes est **exactement 0**
  (`06_01_ceq_summary_scenarios`, `06_01_bootstrap_kakwani`,
  `06_01_decile_effective_rates_by_scenario`, `13_03_local_io_diagnostics_current` et
  `_constant`, `13_06_macro_validation`, `14_01_fgt_comparison` sur ses 18 concepts
  d'origine).
- Dossier 12 : les valeurs changent, **intentionnellement**, par l'harmonisation de la
  convention de déflation décrite en §4 (`12_01`, `12_02`, `12_03`, `12_04`).

**Un effet collatéral à signaler.** `12_05_fgt_reform.xlsx` (réforme des intrants avicoles)
change aussi, puisqu'il part de `poor_strict` désormais construit en convention réelle : le
$P_0$ de référence passe de 33,111 % à 33,178 % et la variante de transmission la plus
conservatrice ne fait plus basculer de ménage. Le nombre de ménages basculant dans le
scénario de transmission maximale reste 330. **La phrase du `.tex` (l. 2065–2069) — « $+0{,}01$
point de $P_0$, moins de 500 ménages basculant sous le seuil dans le scénario de transmission
maximale » — reste vraie et n'a pas à être modifiée.** Ce classeur n'est référencé par aucun
flottant de `replication_package/exhibit_map.csv`.

---

## 6. Scripts modifiés

| Fichier | Nature de la modification |
|---|---|
| `05_scripts_R/utils/informality_anchor.R` | Réestimation de la pente sur trois spécifications (brute, contrôle de quantité, contrôle interagi) avec `log_quantite_relatif` centré intra-cellule ; nouvelles tables `gradient_specifications` et `confrontation_specifications` ; feuille `notes` ; remontée de $\tau$, $\bar\alpha_1$, pente brute et pente corrigée dans la valeur de retour de `vat_unit_value_gradient()` et de `build_informality_anchor()`. La feuille `gradient` et la feuille `confrontation_s3` conservent la spécification brute à l'identique. |
| `05_scripts_R/utils/vat_scenarios.R` | Ajout de `vat_alpha_decile_s5_mean_food()`, `vat_alpha_decile_s5(coicop, decile, slope_food)` et `vat_alpha_decile_s5_matrix(slope_food)`. Aucune fonction existante n'est touchée. |
| `05_scripts_R/06_01_sensitivity_taxation.R` | Construction de `alpha_5`, `alpha_5b`, `vat_item_s5`, `vat_item_s5b`, des agrégats ménage `vat_s5*`, `_real`, `_pc`, `eff_vat_s5*` et `consumable_s5*` ; ajout de S5 et S5′ à `scenarios`, à `bs_list` (bootstrap Kakwani 500 réplications) et aux exports ; persistance de `SILVER/06/alpha_scenarios_s4_s5.parquet` ; nouvelles feuilles `parametres_S5`, `matrice_S5`, `matrice_S5b`, `alpha_scenarios_s4_s5` dans `06_03_vat_informality_parameters.xlsx` ; colonnes `alpha_4`, `alpha_5`, `alpha_5b` ajoutées au diagnostic par COICOP × décile. |
| `05_scripts_R/12_poverty_incidence.R` | Passage à la convention réelle (charge déflatée par `def_spa`) ; ajout de S5 et S5′ partout où S4 apparaît ; correction de `total_new_poor`, qui n'énumérait que strict/S2/S3 et couvre désormais les six scénarios ; nouveau tableau de diagnostic `12_06_deflation_convention.xlsx` ; S5 ajouté à la figure par décile. |
| `05_scripts_R/13b_leontief_local_io.R` | Lecture de `SILVER/06/alpha_scenarios_s4_s5.parquet` avec arrêt bloquant si le fichier est absent ; assertion de coïncidence des déciles des étapes 4 et 6 ; création de `alpha_s4`, `alpha_s5`, `alpha_s5b` et des colonnes `vat_direct_local_{s4,s5,s5b}_item`, `vat_emb_local_{s4,s5,s5b}_item`, agrégats ménage et totaux ; ajout de `"s4"`, `"s5"`, `"s5b"` en fin de `io_scenarios` pour ne pas déplacer les lignes déjà publiées. Aucune colonne existante n'est modifiée. |
| `05_scripts_R/14_leontief_poverty.R` | Ajout au tribble `concepts` de `cur_total_s3_legal`, `cur_direct_s4`, `cur_total_s4`, `cur_direct_s5`, `cur_total_s5`, `cur_direct_s5b`, `cur_total_s5b` ; nouvelle sortie `14_04_new_poor_by_scenario.xlsx` (ménages et personnes nouvellement pauvres, part de population, part appauvrie au sens Higgins–Lustig) pour chaque concept de TVA. S3 reste la spécification centrale. |

Aucun fichier `.tex` n'a été modifié : c'est le périmètre de T5 et de T9.

**Nouvelles sorties à répercuter dans `replication_package/exhibit_map.csv` par T11 :**
`07_reports/tables/12/12_06_deflation_convention.xlsx`,
`07_reports/tables/14/14_04_new_poor_by_scenario.xlsx`,
`02_data_intermediate/06/alpha_scenarios_s4_s5.parquet`, ainsi que les feuilles
`gradient_specifications`, `confrontation_specifications` et `notes` de
`06_05_unit_value_gradient.xlsx` et les feuilles `parametres_S5`, `matrice_S5`,
`matrice_S5b`, `alpha_scenarios_s4_s5` de `06_03_vat_informality_parameters.xlsx`.
