# Audit indépendant — Round 5 (rapport de référé *Journal of African Economies*)

Auditeur : agent indépendant, n'ayant participé à aucune des tâches T0–T11.
Date : 2026-09-06. Référentiel : commit `90515e7`.
Méthode : relecture des diffs R, re-lecture directe des classeurs `07_reports/tables/**`,
recompilation complète des deux documents LaTeX, exécution du vérificateur du paquet de
réplication, vérification à la source (Crossref, PDF éditeur) de sept notices et de quatre
grandeurs externes reprises dans le texte.

---

## 0. Verdict

### **CORRECTIONS REQUISES**

Le fond du tour est solide et, sur la substance, exemplaire : **les neuf points majeurs et
dix-huit des vingt points mineurs sont traités**, aucune valeur nouvelle citée dans le `.tex`
n'est fausse, les scénarios S1–S3 sont bit-à-bit invariants, les identités comptables ferment
à $10^{-9}$, les deux documents compilent sans une seule référence ou citation indéfinie, et
la bibliographie est en parité stricte (53 notices, 53 citations, zéro orpheline).

Trois défauts empêchent néanmoins de clore le tour en l'état. Ils sont tous localisés et
aucun n'exige de relancer le pipeline.

| # | Gravité | Défaut |
|---|---|---|
| **R1** | bloquant | `replication_package/code/01_verify_outputs.R` **échoue** depuis la restructuration (1 FAIL / 47) et le `README.md` du paquet affirme le contraire |
| **R2** | bloquant | la colonne RS de `tab:comparaison-ceq-afrique` mélange **deux définitions** ; la ligne ivoirienne n'est pas comparable aux cinq autres |
| **R3** | bloquant | `06_06_robustness_price_gradient.xlsx` alimente désormais deux passages du corps mais son script est **hors pipeline, hors `exhibit_map.csv`, hors `reproducibility_claims`** |
| R4 | sérieux | les claims C31–C37 restent toutes en `PENDING_AUDIT_T12` ; `reproducibility_audit_DT_CEQ_CIV2021.md` n'a pas été touché depuis le 23 juillet |
| R5 | sérieux | le manuscrit passe de **62 à 74 pages** : M8(iii)(iv) sont traités, mais l'objectif de longueur du §6.2(a) est *aggravé* |

Neuf réserves mineures suivent en §7.

---

## 1. Périmètre des fichiers modifiés — CONFORME

`git diff 90515e7 --stat` : 15 fichiers suivis, tous dans le périmètre annoncé
(`DT_CEQ_CIV2021.tex/.pdf`, `references.bib`, `reproducibility_claims_*.json`,
7 scripts R, `exhibit_map.csv`, `replication_package/README.md`, `project_state.md`,
`MEMOIRE_PARTAGEE_CEQ_CIV2021.md`). **Aucun fichier suivi hors périmètre n'a été touché.**
Non suivis et légitimes : `DT_CEQ_CIV2021_supplement.tex/.pdf`,
`05_scripts_R/utils/robustness_price_gradient_round5.R`, `Diebolt/round5/`, `08_lit_review/ceq36.pdf`.

Deux résidus : `DT_CEQ_CIV2021_T4_compile.pdf` (artefact de compilation de la tâche T4, à
supprimer) et l'absence de `DT_CEQ_CIV2021_v23.pdf` demandé par T11(v).

*Note de transparence* : l'exécution de `01_verify_outputs.R` par cet audit a réécrit
`replication_package/output/verification_report.csv`, qui apparaît maintenant modifié et
consigne le FAIL décrit en R1. C'est une conséquence de la vérification, pas une édition.

---

## 2. Intégrité des calculs R — PASS

### 2.1 Invariance de S1–S3 et des macros de tête

| Grandeur | Cible du brief | Lue dans la sortie | Verdict |
|---|---|---|---|
| Masses S3 (directe / enchâssée / totale) | 697,2 / 214,3 / 911,6 | 697,2229936 / 214,3413137 / 911,5643073 (`13_03_local_io_diagnostics_current`) | PASS |
| Kakwani S3 ponctuel | 0,165 | 0,164825289 (`06_01_ceq_summary_scenarios`) | PASS |
| IC bootstrap Kakwani S3 | [0,157 ; 0,173] | 0,164630912 [0,156878348 ; 0,172743475] (`06_01_bootstrap_kakwani`) | PASS |
| $\Delta P_0$ S3 directe | 2,35 [1,89 ; 2,87] | 0,023502863 [0,018911377 ; 0,028665659] (`14_01_fgt_comparison`) | PASS |
| $\Delta P_0$ S3 directe+enchâssée | 3,54 [3,02 ; 4,10] | 0,035408306 [0,030192896 ; 0,040985341] | PASS |
| Shapley Gini impôts indirects | 0,00849 | 0,00849285868 (`expected_metrics.csv`, `23_01`) | PASS |
| 17 macros `ceq_summary_values.tex` | inchangées | fichier non modifié dans `git diff 90515e7` | PASS |

### 2.2 Identités comptables

`22_03_identity_checks.xlsx` : six lignes, `valide = TRUE`, écart maximum $1{,}86\times10^{-9}$
(tolérance $10^{-6}$). `18_05_ceq_identity_checks.xlsx` : deux lignes $Y_D=Y_N+R$ au statut `OK`,
écarts $9{,}3\times10^{-10}$ et $1{,}86\times10^{-9}$. **PASS.**

### 2.3 Chaque chiffre nouveau du `.tex`, relu dans sa sortie

Toutes les valeurs ci-dessous ont été relues **directement** dans les classeurs, pas reprises
des mémos T1/T2.

**`tab:vat-scenarios` (l. 1078–1093)** — source `06_01_ceq_summary_scenarios` + `06_01_bootstrap_kakwani`, masses `13_03` :

| Ligne du tableau | Publié | Lu | Verdict |
|---|---|---|---|
| S4 masse / K / IC / RS | 860 / 0,104 / [0,096 ; 0,112] / 0,0059 | 860,2897 / 0,1043232 / [0,0964503 ; 0,1123138] / 0,0058542 | PASS |
| S5 masse / K / IC / RS | 689 / 0,156 / [0,148 ; 0,164] / 0,0071 | 689,1870 / 0,1560966 / [0,1479663 ; 0,1641163] / 0,0070700 | PASS |
| S5′ (note) masse / K / IC / RS | 685 / 0,1515 / [0,143 ; 0,160] / 0,0068 | 685,0523 / 0,1515230 / [0,1432343 ; 0,1597467] / 0,0068146 | PASS |

**`tab:fgt-io` (l. 1211–1231)** — source `14_01_fgt_comparison`, colonnes `delta_p0`, `delta_p0_lo/hi` :

| Ligne | Publié | Lu | Verdict |
|---|---|---|---|
| S5 directe | 2,36 [1,90 ; 2,87] | 0,0235919 [0,0190108 ; 0,0287306] | PASS |
| S4 directe | 3,55 [3,03 ; 4,08] | 0,0354637 [0,0303081 ; 0,0407723] | PASS |
| S5 dir.+ench. | 3,56 [3,03 ; 4,12] | 0,0356054 [0,0302667 ; 0,0411699] | PASS |
| S4 dir.+ench. | 4,50 [3,90 ; 5,12] | 0,0449943 [0,0389758 ; 0,0511973] | PASS |
| S5′ (note) | 2,39 [1,93 ; 2,90] / 3,58 [3,04 ; 4,12] | 0,0238576 [0,0193323 ; 0,0290274] / 0,0358106 [0,0303726 ; 0,0411975] | PASS |
| $P_0$ après (%) | 39,83 / 41,02 / 41,03 / 41,97 | 0,3983101 / 0,4101819 / 0,4103236 / 0,4197125 | PASS |

**`tab:io-robustness`, ligne $e_i^L$ (l. 3113, note l. 3119–3122)** — la case « -- » est remplie et
la note « non recalculé » a disparu : $+2{,}42$ point, IC $[1{,}96 ; 2{,}92]$, contre
`cur_total_s3_legal` = 0,0242193 [0,0196321 ; 0,0292103]. **PASS.** Les dérivés du §5.3 sont exacts :
recul $3{,}540831-2{,}421931 = 1{,}1189$ → « $1,119$ point » ; apport de la composante enchâssée
sous $e_i^L$ $2{,}421931-2{,}350286 = 0{,}0716$ → « $0,072$ point » ; sous S3
$3{,}540831-2{,}350286 = 1{,}1905$ → « $1,191$ point ». Masses 214,4 → 22,3 et 911,6 → 719,6 : PASS (`13_03`).

**Classement $Y_P$ (l. 1121–1145)** — source `06_02_ceq_rankings_extended`, feuilles
`kakwani_rs_par_classement` et `bootstrap_kakwani_S3` : 0,164825 → 0,157253 ($-4{,}6$ %),
RS 0,0075665 → 0,0071694 ($-5{,}2$ %) ; directe+enchâssée 0,130015 → 0,122390 ($-5{,}9$ %),
RS 0,0078597 → 0,0073435 ($-6{,}6$ %) ; IC $Y_P$ [0,1494069 ; 0,1650715] → « [0,149 ; 0,165] » ;
variante à rang seul 0,1647875 → écart $-0{,}0000378$ → « $-0,00004$ » ; concentration
0,498445 → 0,498135 → « de 0,4984 à 0,4981 » ; Gini 0,333619 vs 0,340882 → « 0,334 » et « 0,341 ».
**Toutes PASS.** La feuille `coherence_YD` reproduit `06_01` à écart exactement nul, sous assertion bloquante.

**`tab:shapley-pauvrete` (l. 1820–1834)** — source `23_07_shapley_poverty_p0`, convention PDI :
$-0{,}0013792$ / $+0{,}0039332$ / $-0{,}0422782$ / $+0{,}0008832$ / $+0{,}0708529$ / $+0{,}0059509$,
total $0{,}0379628$. Sous-total monétaire recalculé $= -0{,}0388410$ → « $-3{,}88$ », en nature
$+0{,}0768038$ → « $+7{,}68$ », parts $-102{,}3$ % et $202{,}3$ %. **PASS**, y compris la note
expliquant l'écart d'arrondi.

**Efficacité d'impact restreinte au bloc A (l. 1887–1898)** — source `23_11_effectiveness` :
prélèvements directs 0,7179 pour 226,2 Mds ; impôts indirects 0,1821 pour 1 197,70 Mds ;
paiements directs 0,0606 pour 128,7 Mds ; réductions de prix $-0{,}0803$ pour 26,07 Mds. **PASS.**
Aucun nouveau code n'a été écrit : les valeurs préexistaient, seul le périmètre cité a changé.

**Annexe B, pente corrigée (l. 2749–2772)** — source `06_05_unit_value_gradient`, feuilles
`gradient_specifications` / `confrontation_specifications` : $\hat\pi=-0{,}0028405653$,
e.t. $0{,}0011723116$, $p=0{,}01539$, IC $[-0{,}0051383 ; -0{,}0005428]$, coefficient de quantité
$-0{,}1577202$, spécification interagie $-0{,}0028250$, pente brute $-0{,}0028948$ IC
$[-0{,}0051619 ; -0{,}0006276]$, $\tau=0{,}1699088$, pente impliquée par S3 $+0{,}0055208$,
$s_5' = -0{,}0174936$. **Toutes PASS**, y compris « la pente corrigée vaut 98 % de la pente brute »
(98,1 %) et « borne supérieure $-0{,}05$ % » ($-0{,}0543$ %).

**Diagnostic 2,17 / 2,35 (annexe B, l. 2696–2706)** — `12_06_deflation_convention` :
convention nominale 6,096 / 2,174 / 3,517 contre convention réelle 6,173 / 2,350 / 3,546 ;
`12_01_fgt_national` est désormais **identique à $10^{-9}$ près** à `14_01` pour les concepts
communs. Le point mineur 1 est clos par harmonisation, pas par explication *ad hoc*. **PASS.**

**Effet collatéral `12_05_fgt_reform`** — le $P_0$ de référence passe à 0,3317800 et 330 ménages
basculent : la phrase du corps (« $+0,01$ point, moins de 500 ménages », l. 2141–2143) reste
exacte. **PASS.**

### 2.4 Recompilation

Le pipeline n'a pas été relancé intégralement (durée), mais l'invariance a été contrôlée par une
voie plus forte : les valeurs S1–S3 lues aujourd'hui dans les classeurs sont identiques, chiffre
par chiffre, aux cibles du brief et aux copies `Diebolt/round5/baseline/`, les identités ferment,
et `ceq_summary_values.tex` est resté hors diff. Le vérificateur du paquet passe 46 de ses 47
contrôles numériques et de présence (le 47ᵉ est R1, sans rapport avec les calculs).

---

## 3. Pente corrigée et définition de S5 — PASS

- `utils/informality_anchor.R` l. 368–378 : `log_quantite_relatif = log(quantite) −
  weighted.mean(log(quantite), hhweight)` **à l'intérieur d'un `group_by(cellule)`**, donc
  exactement la même transformation intra-cellule que `prix_relatif`. Trois formules déclarées
  l. 391–395, la principale étant `prix_relatif ~ decile * taxe + log_quantite_relatif`.
  Estimation pondérée par `hhweight`, `vcovCL` agrégé par grappe. **Conforme au brief.**
- La pente rapportée dans le `.tex` ($-0{,}002841$) est bien le coefficient `decile:taxe` de
  cette spécification, relu dans le classeur. **PASS.**
- `utils/vat_scenarios.R` : `vat_alpha_decile_s5()` implémente
  $\alpha_1(d)=\bar\alpha_1+(d-5{,}5)s_5$ avec $\bar\alpha_1 = a_1 + 4{,}5\,s_1 = 0{,}273$,
  bornage `pmin(pmax(·,0),1)`, les douze autres fonctions inchangées. **Conforme à
  l'équation~(\ref{eq:alpha-s5}) publiée.**
- Conversion S5′ : $s_5=\hat\pi(1+\bar\alpha_1\tau)/\tau$
  $= -0{,}0028405653 \times 1{,}0463851 / 0{,}1699088 = -0{,}0174936$, inverse exacte de la
  relation de prix $\partial\log p/\partial d \simeq \tau(1+\bar\alpha\tau)^{-1}\partial\alpha/\partial d$
  de l'annexe B. Recalculé à la main, identique à la valeur publiée dans `parametres_S5`. **PASS.**
- Profil S5′ publié en annexe (l. 2598–2601) : 0,352 → 0,194, identique à la matrice
  `matrice_S5b`. **PASS.**
- `13b_leontief_local_io.R` : la table $\alpha$ est lue depuis `SILVER/06`, l'absence du fichier
  est bloquante, et **une assertion bloquante compare le décile de l'étape 4 à celui de l'étape 6**
  avant jointure. Les formules `vat_direct_local_s{4,5,5b}_item` et `vat_emb_local_*` sont
  structurellement identiques à celles de S3. **PASS.**
- `utils/robustness_price_gradient_round5.R` : les six spécifications rapportées dans le `.tex`
  (l. 2765–2772) sont exactement celles de `06_06_robustness_price_gradient`, feuilles `pentes` et
  `tests_de_forme` : ventiles $-0{,}0027701$, cinquantiles $-0{,}0029045$, centiles $-0{,}0028844$,
  rang continu $-0{,}0029012$, $\log(pcexp)$ $-0{,}0028882$, Wald $\chi^2=9{,}308$, $p=0{,}31699$.
  A0 reproduit la référence à la dixième décimale. **PASS sur le fond — voir R3 sur la traçabilité.**

---

## 4. Bibliographie — PASS

- `references.bib` : **53 notices**. Citations extraites des **deux** documents : **53 clés
  distinctes**. `comm` sur les deux listes : **zéro orpheline, zéro citation sans notice.**
- `younger2016` supprimée avec un commentaire de bloc expliquant la résolution vers
  `youngerghana2017` ; `younger2017` (CEQ WP 55) conservée et documentée comme distincte. Mineur 10 clos.
- `atkinson1980` basculée en `@incollection` avec `booktitle`, `editor`, `pages`, `isbn`. Mineur 11 clos.

**Vérification à la source (sept notices, dont deux du tableau africain) :**

| Clé | Contrôle | Résultat |
|---|---|---|
| `youngerghana2017` | Crossref 10.1111/rode.12299 | titre, trois auteurs, *RDE* 21(4), 2017 — **conforme** |
| `brown2018` | Crossref 10.1016/j.jdeveco.2018.05.004 | *JDE* 134, 109–124, 2018 — **conforme** |
| `ahmadstern1984` | Crossref 10.1016/0047-2727(84)90057-4 | *JPubE* 25(3), 259–298 — **conforme** |
| `sahnyounger2000` | Crossref 10.1111/j.1475-5890.2000.tb00027.x | *Fiscal Studies* 21(3), 329–347 — **conforme** |
| `worldbankpssnicr2024` | documents.worldbank.org, ICR00006568, P143332 | rapport existant ; « 227 000 ménages bénéficiaires » **confirmé** |
| `imftogo2017` | IMF eLibrary CR 17/128 | chapitre d'incidence fiscale confirmé ; Gini disponible 0,38 et $P_0$ 55,1 % en 2015 **conformes** |
| `lustig2017cgd` | PDF CGD, tableau 1, p. 25 | **lu ligne à ligne**, voir §5 |

Aucune notice fabriquée détectée. Deux grandeurs externes citées dans le corps ont en outre été
vérifiées mot à mot dans les sources originales :

- **Bachas, Gadenne & Jensen (2024), Table 2 « Average Slopes of the Informality Engel Curves »** :
  colonne 1 = 10,2 ; colonne 9 = 4,6 (« even with these extensive observable controls, the average
  IEC slope is -4.6 »). Le §4.2 bis (l. 426–435) est donc **exact**.
- **Brown, Ravallion & van de Walle (2018)** : « The simple average R2 is 0.53, with a range from
  0.32 (for Ethiopia) to 0.64 (Burkina Faso) » ; moyenne 0,52 des travaux antérieurs ; « for H=0.4,
  we find that 36% of those who are poor are excluded on average, while 31% of those who are deemed
  poor are actually not poor » ; 81 % d'exclusion à H = 0,2. Les l. 1516–1541 et 2318–2321 sont
  **exactes au mot près**.

---

## 5. Tableau de comparaison CEQ africaine — RÉSERVE R2

**Présence confirmée** : `tab:comparaison-ceq-afrique` est bien dans le **corps** (l. 2073–2121,
§5.11, page 40 du PDF), pas en annexe.

**Chiffre ivoirien** : la colonne « Appauvris » porte `\PartAppauvrie{}` = **37,5 %**, pas 4,35 %.
La prose (l. 2053–2065) oppose explicitement les deux mesures et explique pourquoi 37,5 % est la
grandeur comparable. **Le point est traité exactement comme T7 le demandait.**

**Vérification à la source des cellules externes.** Lecture directe de Lustig, *CGD Working Paper
448*, tableau 1, p. 25 :

| Pays | RS publié dans le tableau du papier | Colonne « Reynolds-Smolensky » de Lustig | Appauvris publiés | Colonne de Lustig |
|---|---|---|---|---|
| Ghana | 1,6 | **1,6** | 5,1 | **5,1** |
| Tanzanie | 4,1 | **4,1** | 50,9 | **50,9** |
| Éthiopie | 2,3 | **2,3** | 28,5 | **28,5** |
| Afrique du Sud | 8,3 | **8,3** | 5,9 | **5,9** |

Les $\Delta P_0$ ont été recoupés indépendamment : CEQ WP 36 (Tanzanie), tableau 6, p. 15, lu dans
le PDF Tulane — revenu disponible 0,282 et revenu consommable 0,348 au seuil national TZS 36 482,
soit **+6,6 points**, valeur du tableau. La note de provenance (« le tableau 2 de Higgins & Lustig
ne couvre ni le Ghana, ni l'Éthiopie, ni la Tanzanie, ni l'Ouganda ») est **exacte et rare** :
c'est un point d'honnêteté que peu d'auteurs feraient.

**Le défaut.** Le tableau 1 de Lustig comporte **deux colonnes distinctes** : « Reynolds-Smolensky »
et « Change in inequality (Gini) ». Elles diffèrent systématiquement :

| | Ghana | Tanzanie | Éthiopie | Afrique du Sud |
|---|---|---|---|---|
| Reynolds-Smolensky (colonne utilisée) | 1,6 | 4,1 | 2,3 | 8,3 |
| Change in inequality (Gini) | −1,4 | −3,8 | −2,0 | −7,7 |

Or la ligne ivoirienne, **1,62**, est une simple différence de Gini
($\GiniPrimaire - \GiniConsommable = 0{,}3409-0{,}3247$), c'est-à-dire l'analogue de la *seconde*
colonne, tandis que les cinq comparateurs viennent de la *première*. La note du tableau
(l. 2094–2096) définit d'ailleurs la colonne comme « la variation du coefficient de Gini » — ce qui
est vrai pour la Côte d'Ivoire et **faux pour les cinq autres lignes**.

L'écart n'est pas cosmétique : c'est précisément le reclassement, dont le papier établit par
ailleurs qu'il absorbe 21,8 % du pouvoir égalisateur du système ivoirien. À convention homogène, la
Côte d'Ivoire se situerait **au-dessus** du Ghana (1,62 contre 1,4 en différence de Gini), et non
« au même niveau » comme l'écrit la l. 2042.

**Correction demandée (deux voies, l'une ou l'autre) :**
1. *(la plus simple, exacte, sans calcul)* remplacer les quatre valeurs par la colonne
   « Change in inequality (Gini) » de Lustig — Ghana 1,4 ; Tanzanie 3,8 ; Éthiopie 2,0 ;
   Afrique du Sud 7,7 — renommer l'en-tête « $\Delta$ Gini » et conserver la note actuelle ;
   ajuster la l. 2042 (« légèrement au-dessus du Ghana »).
2. *(la plus fidèle au concept)* calculer le vrai RS ivoirien
   $G(Y_P) - C(Y_C \mid Y_P)$ — le terme est déjà produit par la décomposition Atkinson–Plotnick de
   l'étape 23 — et le substituer au 1,62, en conservant la colonne RS de Lustig et en corrigeant la
   note pour dire « indice de Reynolds–Smolensky » et non « variation du coefficient de Gini ».

---

## 6. Positionnement Bachas/UEMOA et pratique standard CEQ — PASS, sans édulcoration

- **UEMOA / Bénin / EMICOV** : présents l. 2783–2790. Le passage nomme l'EMICOV béninoise 2015,
  l'EICVM burkinabè 2009 et l'EDMC sénégalaise 2008 pour établir que l'absence de variable de lieu
  d'achat dans l'EHCVM est une **contrainte de source et non un choix de méthode**. Bien tourné.
- **Sur-extrapolation de S3** : l. 424–441, avec la conversion à l'échelle ivoirienne
  (0,193 point de log par décile) donnant un gradient de 0,0089 à 0,0197 contre 0,034 postulé,
  « de 1,7 à 3,8 fois davantage ». Arithmétique vérifiée, bornes vérifiées à la source.
- **La réserve de signe** : l. 442–448.

  > « La convergence s'arrête là et il faut le dire sans détour. Le gradient de prix mesuré en
  > Côte d'Ivoire est de signe négatif, tandis que la pente moyenne de \citet{bachas2024}
  > impliquerait, une fois traduite, un gradient de prix positif : les deux exercices ne se
  > rejoignent pas sur la direction du phénomène […]. Rien de ce qui précède n'autorise à écrire
  > que le gradient ivoirien suivrait la même direction qu'ailleurs. »

  **C'est exactement la formulation demandée : explicite, non édulcorée, et placée dans le corps
  et non en note.** La recommandation du mémo de robustesse de ne pas publier le chiffre traduit
  $+0{,}001442$ a par ailleurs été respectée : il n'apparaît nulle part dans le `.tex`.
- **S1 comme pratique standard** : l. 450–459. « La quasi-totalité des applications CEQ publiées
  appliquent le taux statutaire de TVA à la consommation déclarée sans aucun ajustement pour
  l'informalité […] et c'est très exactement ce que fait ici le scénario S1, que la présente étude
  ne retient pourtant que comme borne haute théorique et non ancrée. » Étayé par le dépouillement
  T7 (Ghana, Éthiopie, Afrique du Sud, Tanzanie). **PASS.**

---

## 7. Restructuration et intégrité des renvois

### 7.1 Ce qui est acquis

- **Flottants du corps : 13** (8 tableaux + 5 figures), contre 31 avant le tour. Cible « dix à
  douze » du plan légèrement dépassée, cible « une dizaine » du référé atteinte en pratique.
- **Le supplément compile seul** : `pdflatex ×3 + bibtex`, 13 pages, **zéro erreur, zéro référence
  indéfinie, zéro citation indéfinie**, bibliographie propre.
- **Tous les renvois du corps vers le supplément sont en prose** — « matériel supplémentaire,
  section S.1 / S.2 / S.3 / S.4 » (l. 52, 187, 230, 524, 551). Aucun `\ref` vers un label déplacé.
- **Aucune équation étiquetée n'a disparu** : 21 `\label{eq:…}` dans le corps, dont la nouvelle
  `eq:alpha-s5` ; toutes résolues.
- **Zéro `[h]`** dans l'un ou l'autre document (mineur 19 clos).
- **Parité `exhibit_map.csv` ↔ documents : 38 / 38**, ensembles strictement égaux sur les deux
  fichiers `.tex` (33 dans le manuscrit, 5 dans le supplément). Numéros de ligne des producteurs
  vérifiés par sondage : exacts.

### 7.2 Compilation finale des deux documents

| Document | Passes | Pages | Erreurs | `Undefined reference` | `Citation undefined` | Overfull hbox |
|---|---|---|---|---|---|---|
| `DT_CEQ_CIV2021` | pdflatex, bibtex, pdflatex ×2 | **74** | 0 | **0** | **0** | **0** |
| `DT_CEQ_CIV2021_supplement` | pdflatex, bibtex, pdflatex ×2 | **13** | 0 | **0** | **0** | 0 |

### 7.3 Réserve R5 — la longueur a augmenté

Le baseline T0 mesurait **62 pages**. Le manuscrit en compte aujourd'hui **74**. La ventilation
(lue dans le `.aux`) : corps et bibliographie jusqu'à ~p. 50, annexes A–D p. 51–63, et une **nouvelle
annexe E « Tableaux et figures complémentaires » p. 64–74**, qui recueille les 20 flottants sortis
du corps.

Les cinq objets documentaires ont bien quitté le PDF principal, comme M8(iii) l'exigeait, et le
compte de flottants du corps est conforme à M8(iv). Mais l'objectif du §6.2(a) du référé — ramener
le manuscrit de 62 pages vers 30–40 — est **manqué et le mouvement est inverse** : les 20 flottants
déplacés vers l'annexe E occupent 11 pages du même PDF, et environ dix pages de prose neuve
(T3, T4, T5, T6, T7, T8) s'y ajoutent. Le plan T10 autorisait explicitement ce déplacement interne ;
l'audit ne le traite donc pas comme une désobéissance mais comme un **objectif du référé non
atteint**, à arbitrer avant soumission. Piste la moins coûteuse : basculer l'annexe E vers le
matériel supplémentaire (qui passerait de 13 à ~24 pages, le manuscrit à ~63), ce qui suppose de
convertir une quinzaine de `\ref` en renvois en prose.

---

## 8. Standards de forme JAE — PASS sauf une demi-mesure

| Contrôle | Résultat |
|---|---|
| Résumé sous 150 mots | **138 mots** (recomptés ; macros comptées pour un mot) — PASS |
| Introduction non redondante | Le §1 pose la question et la tension, ne reprend ni les chiffres ni la formulation du résumé ; la phrase « Notre hypothèse centrale… » a disparu — PASS |
| Aucune liste dans le corps | **Zéro** `itemize`/`enumerate` avant `\appendix` ; zéro dans tout le supplément. Les seuls `\item` sont des `tablenotes` — PASS |
| Codes JEL | H22, H23, H53, D31, I32, O17 — les six, PASS |
| Date | « Septembre 2026 » — PASS |
| Auteur correspondant | Nommé (« Auteur correspondant : Franck Migone, Cellule d'Analyses Économiques, ANStat, Abidjan ») mais **aucune adresse électronique** dans les deux fichiers — PARTIEL |

---

## 9. `exhibit_map.csv` et `reproducibility_claims.json`

### 9.1 Parité des labels — PASS (mais voir R1)

38 labels dans les deux `.tex`, 38 lignes dans le CSV, ensembles identiques.

### 9.2 Claims C31–C37 — vérifiées par cet audit

Toutes ont été recalculées depuis les classeurs. **Dispositions à inscrire dans le JSON en
remplacement de `PENDING_AUDIT_T12` :**

| Claim | Objet | Disposition |
|---|---|---|
| C31 | S4 dans `tab:vat-scenarios` | **PASS** |
| C32 | S5 et S5′ dans `tab:vat-scenarios` | **PASS** |
| C33 | S4/S5/S5′ dans `tab:fgt-io` | **PASS** |
| C34 | $e_i^L$ | **PASS** sur les nombres, mais le champ `computed` est **inachevé** : il se termine par « voir feuille pour la ligne directe correspondante » et invoque une ligne `cur_direct_s3_legal` **qui n'existe pas** dans `14_01`. La bonne rédaction : sous $e_i^L$ la TVA directe est celle de S3 (2,350286), d'où $2{,}421931-2{,}350286=0{,}071645$. À réécrire. |
| C35 | classement $Y_P$ | **PASS** |
| C36 | sous-totaux Shapley | **PASS** |
| C37 | comparaison CEQ Afrique | **PASS** pour les six cellules externes vérifiées à la source, **sauf la colonne RS** : voir R2 |

`reproducibility_audit_DT_CEQ_CIV2021.md` n'a **pas** été mis à jour (mtime 23 juillet). Livrable T12 restant.

### 9.3 Réserve R1 — le vérificateur du paquet échoue

Exécution de `verify_main(stop_on_fail = FALSE)` :

```
Vérification : 46 PASS, 1 FAIL.
16 carte exhibits : labels   FAIL   observed=5   expected=0
   tab:variables-questionnaire | tab:lexique | tab:mapping-52-48 |
   tab:acces-replication | tab:inventaire-pipeline
```

Cause : `01_verify_outputs.R` l. 68–74 ne lit que `DT_CEQ_CIV2021.aux`. Les cinq labels partis au
supplément figurent dans `exhibit_map.csv` mais plus dans ce `.aux`, d'où une `label_diff` de 5.
Le script n'a pas été modifié au round 5, alors que T11(iv) demandait de le réviser « si le
vérificateur en dépend ».

Aggravant : `replication_package/README.md` a été réécrit pour affirmer « 32 PASS à la vérification
finale, **sans échec** » et « la parité des 38 labels […] avec `exhibit_map.csv` ». Les deux
affirmations sont fausses aujourd'hui — le vérificateur produit 47 contrôles, dont un FAIL.

**Correction demandée**, dans `01_verify_outputs.R` :

```r
aux_files <- file.path(root, "00_documentation", "working_paper",
                       c("DT_CEQ_CIV2021.aux", "DT_CEQ_CIV2021_supplement.aux"))
aux_text  <- unlist(lapply(aux_files[file.exists(aux_files)], readLines, warn = FALSE))
```

puis mettre à jour la phrase du README avec les compteurs réellement observés après correctif.

### 9.4 Réserve R3 — sorties nouvelles non enregistrées

| Sortie | Adossée à quoi dans le `.tex` | Enregistrée ? |
|---|---|---|
| `06_06_robustness_price_gradient.xlsx` | l. 2765–2772 (ventiles/cinquantiles/centiles, rang continu, $\log$ pcexp, test de forme $p=0{,}32$) **et** l. 431–433 (les 0,193 point de log qui fondent toute la conversion Bachas) | **non** : ni `exhibit_map.csv`, ni `reproducibility_claims`, ni `README`, et son script `utils/robustness_price_gradient_round5.R` n'est appelé par aucune étape de `00_master.R` |
| `14_04_new_poor_by_scenario.xlsx` | l. 1237–1238 (« 193 926 ménages, 1 055 501 personnes ») | non |
| `12_06_deflation_convention.xlsx` | l. 2700–2706 (la convention de déflation de l'annexe B) | non |
| `06_02_ceq_rankings_extended.xlsx` | l. 1121–1145 | seulement comme `source` de C35, pas dans `exhibit_map.csv` |

Le mémo de robustesse recommandait lui-même de ne pas inscrire `06_06` « tant que la décision
d'intégration au papier n'est pas prise ». La décision **a été prise** — les chiffres sont dans le
corps et dans l'annexe B — donc l'inscription est due. **Correction demandée** : (a) rattacher
`robustness_price_gradient_round5.R` au pipeline (ou documenter sa commande d'exécution dans le
README, comme le fait déjà le mémo) ; (b) ajouter les quatre sorties comme producteurs
supplémentaires des lignes `tab:ancrage-offre`, `tab:fgt-io` et `tab:vat-scenarios` de
`exhibit_map.csv` ; (c) ajouter une claim C38 pour la phrase de robustesse de l'annexe B et le
0,193 point de log.

---

## 10. Matrice de couverture

### 10.1 Points majeurs

| # | Objet | Statut | Preuve |
|---|---|---|---|
| **M1(i)** | Scénario S5 chiffré, tableaux 3 et 4 | **RÉSOLU** | `tab:vat-scenarios` l. 1082, `tab:fgt-io` l. 1214 et 1218 ; valeurs relues dans `06_01` et `14_01` |
| **M1(ii)** | Sens du biais énoncé | **RÉSOLU** | l. 1251–1272 : progressivité surestimée de 0,009–0,013 point d'indice, appauvrissement sous-estimé de 0,02–0,04 point, avec la conclusion honnête que l'effet pauvreté bouge peu |
| **M1(iii)** | Réserve dans résumé et introduction | **RÉSOLU** | résumé l. 64 (dernière phrase) ; introduction l. 85 |
| **M2** | $\Delta P_0$ sous $e_i^L$ | **RÉSOLU** | `tab:io-robustness` l. 3113 : $+2{,}42$ [1,96 ; 2,92] ; note « non recalculé » supprimée ; présenté comme l'incertitude de premier ordre en §5.3, `sec:limites`, introduction et conclusion |
| **M3** | S4 dans le corps, remplace S1 | **RÉSOLU** | `tab:vat-scenarios` l. 1081, `tab:fgt-io` l. 1215 et 1220 ; définition §4.2 bis l. 400–403 ; conclusion l. 2463 cite $+4{,}50$ sous S4 et non plus $+7{,}07$ sous S1 |
| **M4(i)** | Circularité discutée + phrase « propagation identique » corrigée | **RÉSOLU** | l. 288–296 (décalage additif uniforme vs erreur corrélée, épargne) ; l. 308–322 (circularité) |
| **M4(ii)** | Kakwani/RS sous classement alternatif | **RÉSOLU** | l. 1115–1145, chiffres de `06_02_ceq_rankings_extended`. L'indice d'actifs par ACP est explicitement déclaré non fait (variables logement/durables absentes de SILVER/01) — le référé offrait l'alternative, elle est retenue |
| **M5(a)** | Tradition Ahmad–Stern et précédents africains | **RÉSOLU** | §4.3 l. 600–613 (`ahmadstern1984`, `ahmadstern1991`, `rajemison2000`, `chen2001`, `sahnyounger2000`) ; apport 1 reformulé en introduction l. 83 |
| **M5(b)** | Littérature PMT africaine | **RÉSOLU** | §4.9 l. 747–760 (`coady2004`, `brown2018`) ; §5.7 l. 1514–1546, avec comparaison chiffrée du $R^2$ vérifiée à la source |
| **M5(c)** | Deaton & Zaidi | **RÉSOLU** | l. 276 et l. 81 |
| **M6** | Comparaison CEQ africaine | **RÉSOLU AVEC RÉSERVE** | `tab:comparaison-ceq-afrique` l. 2073–2121, sept pays, trois indicateurs, sources par cellule, note de provenance exacte. **Réserve R2 sur la colonne RS** |
| **M7(i)** | Shapley pauvreté en deux blocs | **RÉSOLU** | l. 1820–1834, sous-totaux $-3{,}88$ / $+7{,}68$ recalculés depuis `23_07` ; message recentré sur le bloc monétaire l. 1772–1792 |
| **M7(ii)** | Efficacité d'impact retirée ou restreinte | **RÉSOLU** | l. 1884–1898 : restreinte au bloc A, justification explicite (« le critère suppose que la somme est librement réallouable »), éducation et santé retirées |
| **M8(i)** | Titre/résumé/intro recentrés | **RÉSOLU** | titre « Le critère de mesure décide du classement des instruments » ; résumé et introduction organisés autour de l'inversion et du reclassement de 43,8 % |
| **M8(ii)** | Résumé < 150 mots | **RÉSOLU** | 138 mots |
| **M8(iii)** | Cinq objets en matériel supplémentaire | **RÉSOLU** | supplément S.1–S.4, 13 pages, compile seul |
| **M8(iv)** | Flottants du corps ramenés à une dizaine | **RÉSOLU** | 13 |
| **M8(v)** | Section 6 développée | **RÉSOLU** | deux sous-sections neuves (l. 2238–2343) : faisabilité et coût de gestion sourcés sur l'ICR Banque mondiale 2024 (vérifié), fuite bornée en interne (14,1–20,5 %) et en externe (Brown *et al.*) |
| — | §6.2(a) longueur (30–40 p.) | **NON RÉSOLU** | 74 pages, contre 62 avant le tour — **réserve R5** |
| **M9** | Conclusion alignée sur la réserve PMT | **RÉSOLU** | l. 2469 : « ce chiffre ne doit pas être lu comme une recommandation en faveur du ciblage […] ils n'établissent pas que le ciblage soit préférable à l'allocation universelle » ; §6.2 l. 2313–2315 et 2335–2343 |

### 10.2 Points mineurs

| # | Objet | Statut | Preuve |
|---|---|---|---|
| 1 | 2,17 vs 2,35 | **RÉSOLU** | diagnostiqué (déflation), harmonisé (`12_01` ≡ `14_01`), convention explicitée l. 2696–2706 |
| 2 | « 1 316 milliards » | **RÉSOLU** | le nombre n'apparaît plus (origine identifiée : `23_11`, budget éducation 1 315,59) ; l'éducation sort de l'indicateur d'efficacité |
| 3 | « 42,7 % des salariés » | **PARTIEL** | dénominateur nommé et opposé aux 2,413 M du tableau descriptif (l. 1412–1420), **mais les 2,545 M ne figurent dans aucune sortie publiée** — voir §11, m6 |
| 4 | « seuls impôts indirects » | **RÉSOLU** | l. 1644 : « la seule TVA, directe et enchâssée » |
| 5 | Ordre agricole/large | **RÉSOLU** | l. 2158–2162, ordre unique agricole puis large, 75 938/141 356 puis 1 404/1 455 |
| 6 | Corruption « © » | **RÉSOLU** | zéro occurrence ; paragraphe de plan reconstruit l. 93 |
| 7 | « quantities » | **RÉSOLU** | « à quantités fixes » l. 91 |
| 8 | « intégrait » | **RÉSOLU** | « Un modèle de comportement intégrant… » l. 2471 |
| 9 | Résumé 239 mots | **RÉSOLU** | 138 |
| 10 | `younger2016` | **RÉSOLU** | supprimée, résolue vers `youngerghana2017` (DOI vérifié) |
| 11 | `atkinson1980` | **RÉSOLU** | `@incollection`, Aaron & Boskin (dir.), Brookings, p. 3–18 |
| 12 | `chandler2025` sous-exploité | **RÉSOLU** | confronté sur trois plans, l. 1332–1374, y compris sur le point où le papier diverge (droit à déduction) |
| 13 | Redondance résumé/intro | **RÉSOLU** | introduction entièrement réécrite |
| 14 | $R^2$ du PMT non commenté | **RÉSOLU** | l. 1514–1532, repère Brown *et al.* vérifié à la source, deux explications candidates nommées (taille du ménage, région déflatrice) |
| 15 | Répercussion intégrale | **RÉSOLU** | `sec:limites` l. 2410–2413 et `annexe:limites` point 3 l. 2858–2866 |
| 16 | Figures non exploitées | **RÉSOLU** | chaque figure du corps et chacune des figures 8/9/11 déplacées reçoit une phrase de lecture spécifique (l. 1399–1404, 1439–1444, 1563–1568, 1651–1658, 1918–1924, 2201–2206) |
| 17 | Correspondant + courriel | **PARTIEL** | correspondant nommé, **courriel absent** |
| 18 | JEL H23 et H53 | **RÉSOLU** | l. 71 |
| 19 | `[h]` → `[t]` | **RÉSOLU** | zéro `[h]` dans les deux documents |
| 20 | Date | **RÉSOLU** | « Septembre 2026 » |

**Récapitulatif : 9 majeurs traités (dont 1 avec réserve), 18 mineurs résolus, 2 partiels, plus
l'objectif de longueur du §6.2(a) non atteint.**

---

## 11. Réserves mineures, avec correction concrète

**m1 — Effectif de l'échantillon de l'annexe B (l. 2744–2746).**
« l'estimation mobilise 219 176 achats alimentaires répartis en 2 563 cellules exploitables ».
L'estimation porte sur **141 928** achats (`06_05`, feuille `gradient`, colonne `observations` de
la ligne « Difference taxes moins non taxes » ; confirmé par `06_06`, feuille `parametres`,
« Observations de l'echantillon » = 141 928). 219 176 est le nombre d'achats du module 7B avant
filtre de cellule. Défaut antérieur au round 5, mais désormais contredit par les sorties du tour.
**Correction** : « l'estimation mobilise 219 176 achats alimentaires, dont 141 928 tombent dans les
2 563 cellules exploitables, ».

**m2 — Adresse électronique de l'auteur correspondant (l. 48–52).**
Le mineur 17 demandait l'identification *et* l'adresse. **Correction** : ajouter
`\texttt{franckmigone@gmail.com}` (valeur prévue par le brief T9) ou l'adresse institutionnelle
ANStat après le nom du correspondant.

**m3 — Titre du matériel supplémentaire (`supplement.tex` l. 46–48).**
Le supplément porte encore l'**ancien** titre du manuscrit (« Fiscalité, informalité, transferts et
pauvreté en Côte d'Ivoire… »), alors que le manuscrit a été renommé. **Correction** : reprendre le
titre courant, ou l'abréger en « Matériel supplémentaire — Le critère de mesure décide du
classement des instruments ».

**m4 — « adulte contributif participant » (l. 2496).**
Redondance signalée au §6.2(e) du référé et inscrite au sweep de T11(v) ; toujours présente.
**Correction** : « par adulte contributif » ou « par adulte participant ».

**m5 — `exhibit_map.csv` : producteurs manquants.** Voir R3(b).

**m6 — Dénominateur des 2,545 millions (l. 1413).**
Un balayage numérique exhaustif de **tous** les classeurs `07_reports/tables/**` ne trouve aucune
valeur proche de 2 545 000 ni de 2,545. `16_direct_taxes.R` n'a pas été modifié au round 5. Le
mineur 3 est donc réglé sur le plan rédactionnel mais introduit un chiffre que le paquet de
réplication ne permet pas de vérifier. **Correction** : publier l'effectif dans
`16_08_sample_description.xlsx` (une colonne `personnes_avec_salaire_positif`) et ajouter la ligne
correspondante à `reproducibility_claims`, ou retirer la valeur et écrire le taux par rapport au
seul dénominateur publié (2,413 M ⇒ 45,0 %).

**m7 — Instantané `DT_CEQ_CIV2021_v23.pdf` non produit** (T11(v)).

**m8 — `DT_CEQ_CIV2021_T4_compile.pdf`** : artefact de compilation à supprimer.

**m9 — Attribution de la colonne 9 de Bachas *et al.* (l. 428–431).**
Le texte présente le $-4{,}6$ comme « celle qui contrôle les effets fixes de nomenclature COICOP à
quatre chiffres et les blocs d'enquête ». La colonne 9 de leur tableau 2 combine en réalité **les
trois** hypothèses : caractéristiques du ménage, localisation (blocs) et catégories fines de
produits. **Correction** : « celle qui combine caractéristiques du ménage, blocs d'enquête et
nomenclature fine des produits ».

---

## 12. Ce que l'audit retient au crédit du tour

Trois choses méritent d'être dites, parce qu'elles ne se voient pas dans une liste de défauts.

D'abord, **le contrôle de quantité était le test qui pouvait faire tomber l'annexe B**, et il a été
conduit sans complaisance : le coefficient de la remise de gros est massif ($-0{,}158$) et il ne
déplace la pente d'intérêt que de cinq millièmes de point. Le brief T1 prévoyait explicitement la
contingence d'un résultat non concluant ; elle ne s'est pas réalisée, et la démonstration a été
poussée plus loin que demandé (ventiles à centiles, rang continu, $\log$ de la consommation, test
de forme non paramétrique).

Ensuite, **le tour ne surinterprète pas ses propres résultats**. Le mémo T1 conclut que S5 déplace
nettement le Kakwani et très peu l'effet pauvreté ; le `.tex` l'écrit ainsi, sans transformer un
déplacement de deux centièmes de point en confirmation spectaculaire. De même, $e_i^L$ est présenté
comme l'incertitude de premier ordre du papier alors qu'il eût été plus flatteur de le noyer.

Enfin, **la réserve de signe face à Bachas et al. est formulée sans détour dans le corps**, et la
note de provenance du tableau africain avertit que quatre lignes ne figurent pas dans le tableau 2
publié de Higgins & Lustig. Ce sont deux endroits où il aurait été facile, et invérifiable, de ne
rien dire.

---

## 13. Liste ordonnée des corrections à appliquer

**Bloquantes**
1. **R1** — corriger `01_verify_outputs.R` pour lire les deux `.aux` ; réexécuter ; corriger les
   compteurs de `replication_package/README.md` (« sans échec » est faux en l'état).
2. **R2** — homogénéiser la colonne RS de `tab:comparaison-ceq-afrique` (voie 1 ou voie 2 du §5) et
   ajuster la l. 2042.
3. **R3** — inscrire `06_06`, `14_04`, `12_06` et `06_02_ceq_rankings_extended` dans
   `exhibit_map.csv` ; documenter l'exécution de `robustness_price_gradient_round5.R` dans le
   README (ou l'appeler depuis `00_master.R`) ; ajouter la claim C38.
4. **R4** — inscrire dans le JSON les dispositions du §9.2 (six PASS, C34 PASS après réécriture du
   champ `computed`, C37 PASS sous réserve R2) ; mettre à jour
   `quality_reports/reproducibility_audit_DT_CEQ_CIV2021.md`.

**À arbitrer avant soumission**
5. **R5** — décider du sort de l'annexe E (11 pages, 20 flottants) au regard de l'objectif de
   longueur du référé.

**Mineures** : m1 à m9 ci-dessus, toutes des éditions d'une à trois lignes.

Aucune de ces corrections n'exige de relancer le pipeline ni ne modifie une valeur numérique
publiée, à l'exception de la colonne RS du tableau africain (R2, voie 1 : substitution de quatre
valeurs lues dans la source ; voie 2 : une valeur ivoirienne lue dans les sorties de l'étape 23).
