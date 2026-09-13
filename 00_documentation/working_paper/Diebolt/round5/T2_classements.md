# T2 — Classement alternatif indépendant de l'assiette taxée (round 5)

Tâche T2 du `plan_round5.md`, volet calcul de **M4(ii)** du rapport `referee_JAE.md`
(§3.1(a) et M4). Le rapporteur objecte que, $Y_D$ étant la consommation et la TVA une
fonction de cette même consommation, le Kakwani de 0,165 et le RS de $+0{,}0076$
mesurent en partie une propriété mécanique du dispositif de calcul. Il demande de
republier ces deux indices sous un classement qui n'est pas l'assiette elle-même et de
dire de combien ils se déplacent.

Script modifié : `05_scripts_R/06_02_sensitivity_ranking.R` (bloc ajouté en fin de
script, fonction `run_extended_rankings()`). Aucun autre script ni le `.tex` n'ont été
touchés. Relance : `lance_pipeline(7, 7)` uniquement, exécutée avec succès.
Sortie : `07_reports/tables/06/06_02_ceq_rankings_extended.xlsx`
(feuilles `coherence_YD`, `kakwani_rs_par_classement`, `ecarts_vs_YD`,
`bootstrap_kakwani_S3`, `classements`, `notes`). Toutes les valeurs de ce mémo sont
recopiées de ce classeur.

---

## 0. Test de cohérence : reproduction des valeurs publiées sous $Y_D$

Le bloc commence par recalculer les indices sous le classement du corps du texte
(revenu disponible par tête, poids population, charge réelle déflatée par `def_spa`)
et les confronte à `02_data_intermediate/06/06_01_ceq_summary_scenarios.parquet`, qui
alimente le tableau 3. Une assertion bloquante arrête le script si l'écart dépasse
$10^{-10}$.

Feuille `coherence_YD` :

| Scénario | Kakwani recalculé | Kakwani publié (06_01) | Écart | RS recalculé | RS publié | Écart |
|---|---|---|---|---|---|---|
| S1 | 0,07555581 | 0,07555581 | 0 | 0,006937450 | 0,006937450 | 0 |
| S2 | 0,13186429 | 0,13186429 | 0 | 0,006381283 | 0,006381283 | 0 |
| **S3** | **0,16482529** | **0,16482529** | **0** | **0,007566547** | **0,007566547** | **0** |
| S4 | 0,10432323 | 0,10432323 | 0 | 0,005854170 | 0,005854170 | 0 |
| S5 | 0,15609658 | 0,15609658 | 0 | 0,007069979 | 0,007069979 | 0 |
| S5′ | 0,15152299 | 0,15152299 | 0 | 0,006814612 | 0,006814612 | 0 |

**Confirmation demandée par le brief : la reproduction sous $Y_D$ donne bien
0,165 et 0,0076 pour S3** ($0{,}16482529 \to 0{,}165$ à trois décimales ;
$0{,}007566547 \to 0{,}0076$ à quatre décimales), et l'écart au fichier producteur du
tableau 3 est exactement nul, colonne par colonne, pour les six scénarios.

---

## 1. Classements testés

| Code | Variable de classement | Unité de la charge | Poids | Indépendant de l'assiette |
|---|---|---|---|---|
| `YD_pc` | Revenu disponible par tête (référence du tableau 3) | taille du ménage | `pcweight` | non |
| `YP_pc` | **Revenu primaire $Y_P$ reconstruit à l'étape 22, convention PDI, par tête** | taille du ménage | `pcweight` | **oui** |
| `YP_pgt_pc` | Revenu primaire $Y_P$, convention PGT, par tête (contrôle) | taille du ménage | `pcweight` | oui |
| `YD_ae1` | Revenu disponible par adulte équivalent, échelle 1 | `eqadu1` | `hhweight × eqadu1` | non |
| `YP_ae1` | **Revenu primaire PDI par adulte équivalent, échelle 1** | `eqadu1` | `hhweight × eqadu1` | **oui** |
| `YD_ae2` | Revenu disponible par adulte équivalent, échelle 2 | `eqadu2` | `hhweight × eqadu2` | non |
| `YP_ae2` | **Revenu primaire PDI par adulte équivalent, échelle 2** | `eqadu2` | `hhweight × eqadu2` | **oui** |

$Y_P$ est lu dans `02_data_intermediate/22/all_income_concepts.parquet`
(`yp_pc_pdi`, `yp_pc_pgt`). Il n'entre dans aucun calcul de TVA : ni les $\alpha$, ni
les déciles de S3, ni l'assiette ne dépendent de lui. Sous PDI, $Y_P$ est positif pour
les 12 965 ménages ; sous PGT, dix-neuf ménages ont un $Y_P$ négatif et sont planchés à
zéro avant calcul des indices, comme partout ailleurs dans la chaîne. Le classement
équivalent-adulte demandé par le brief est produit dans ses deux échelles, croisé avec
les deux concepts.

**Indice d'actifs par ACP : non calculé.** `02_data_intermediate/01/conso_clean.parquet`
ne contient que la consommation au niveau article (`codpr`, `depan_w`, `coicop`,
`r_vat_official`, …) : aucune variable de logement ni de bien durable n'est présente
dans SILVER/01. La construire supposerait de charger de nouveaux modules bruts, ce que
le brief exclut. L'option est donc explicitement laissée non faite.

Deux assiettes sont couvertes, S1 à S5′ pour chacune : la **TVA directe** (colonnes
`vat_*_real` de l'étape 6, égales à $10^{-10}$ près aux colonnes
`vat_direct_local_*_real` de l'étape 13b, publiées aussi sous ce second nom dans le
classeur pour contrôle) et la **TVA directe + enchâssée** (`vat_total_local_*_real`,
étape 13b, disponible pour les six scénarios depuis T1). Le bloc se restreint
automatiquement à ce qui existe si les étapes 14 ou 23 n'ont pas encore tourné.

Deux variantes de calcul sont publiées côte à côte :

- **Variante A, « concept »** — le classement sert aussi de concept de bien-être :
  $K = C(\text{TVA}\mid\text{rang}) - G(\text{bien-être})$ et
  $RS = G(\text{bien-être}) - G(\text{bien-être} - \text{TVA})$. Sous le rang $Y_D$
  elle est exactement la convention de `06_01`, d'où le test de cohérence ci-dessus.
  C'est la variante à citer dans le papier.
- **Variante B, « classement fixe »** — le concept de bien-être reste $Y_D$, seul le
  rang change : $K = C(\text{TVA}\mid R) - C(Y_D\mid R)$ et
  $RS = C(Y_D\mid R) - C(Y_D-\text{TVA}\mid R)$. Elle isole l'effet de *classement* pur,
  à concept et assiette inchangés. Sous le rang $Y_D$ elle reproduit le Kakwani publié
  mais son RS ($0{,}0076775$) est la composante d'équité verticale d'Atkinson–Plotnick,
  c'est-à-dire le RS augmenté du reclassement, et non le RS du tableau 3.

---

## 2. Résultat principal — S3, scénario central

### 2.1 TVA directe

| Classement | $G$ du classement | $C$ de la TVA | **Kakwani** | Écart au rang $Y_D$ | **RS** | Écart au rang $Y_D$ |
|---|---|---|---|---|---|---|
| $Y_D$ par tête (référence) | 0,333619 | 0,498445 | **0,164825** | — | **0,0075665** | — |
| **$Y_P$ PDI par tête** | 0,340882 | 0,498135 | **0,157253** | **$-0{,}007573$ ($-4{,}6$ %)** | **0,0071694** | **$-0{,}000397$ ($-5{,}2$ %)** |
| $Y_P$ PGT par tête | 0,343495 | 0,490467 | 0,146972 | $-0{,}017853$ ($-10{,}8$ %) | 0,0068473 | $-0{,}000719$ ($-9{,}5$ %) |
| $Y_D$ par adulte éq. 1 | 0,320470 | 0,481980 | 0,161510 | $-0{,}003316$ ($-2{,}0$ %) | 0,0073976 | $-0{,}000169$ ($-2{,}2$ %) |
| **$Y_P$ par adulte éq. 1** | 0,327680 | 0,481823 | **0,154144** | **$-0{,}010682$ ($-6{,}5$ %)** | **0,0070102** | **$-0{,}000556$ ($-7{,}4$ %)** |
| $Y_D$ par adulte éq. 2 | 0,299783 | 0,459601 | 0,159818 | $-0{,}005007$ ($-3{,}0$ %) | 0,0073007 | $-0{,}000266$ ($-3{,}5$ %) |
| **$Y_P$ par adulte éq. 2** | 0,306858 | 0,459372 | **0,152515** | **$-0{,}012311$ ($-7{,}5$ %)** | **0,0069157** | **$-0{,}000651$ ($-8{,}6$ %)** |

### 2.2 TVA directe + enchâssée

| Classement | $C$ de la TVA | **Kakwani** | Écart au rang $Y_D$ | **RS** | Écart au rang $Y_D$ |
|---|---|---|---|---|---|
| $Y_D$ par tête (référence) | 0,463635 | **0,130015** | — | **0,0078597** | — |
| **$Y_P$ PDI par tête** | 0,463272 | **0,122390** | **$-0{,}007626$ ($-5{,}9$ %)** | **0,0073435** | **$-0{,}000516$ ($-6{,}6$ %)** |
| $Y_P$ PGT par tête | 0,456085 | 0,112590 | $-0{,}017425$ ($-13{,}4$ %) | 0,0069375 | $-0{,}000922$ ($-11{,}7$ %) |
| $Y_D$ par adulte éq. 1 | 0,448313 | 0,127842 | $-0{,}002173$ ($-1{,}7$ %) | 0,0077099 | $-0{,}000150$ ($-1{,}9$ %) |
| **$Y_P$ par adulte éq. 1** | 0,448048 | **0,120369** | **$-0{,}009647$ ($-7{,}4$ %)** | **0,0072030** | **$-0{,}000657$ ($-8{,}4$ %)** |
| $Y_D$ par adulte éq. 2 | 0,428003 | 0,128220 | $-0{,}001795$ ($-1{,}4$ %) | 0,0077152 | $-0{,}000144$ ($-1{,}8$ %) |
| **$Y_P$ par adulte éq. 2** | 0,427651 | **0,120794** | **$-0{,}009221$ ($-7{,}1$ %)** | **0,0072099** | **$-0{,}000650$ ($-8{,}3$ %)** |

### 2.3 Intervalles de confiance (bootstrap Rao–Wu rescalé, 500 réplications)

Feuille `bootstrap_kakwani_S3`, plan de sondage grappes × strates du corps du texte.

| Assiette | Classement | Kakwani ponctuel | Moyenne bootstrap | IC 95 % | Écart type |
|---|---|---|---|---|---|
| TVA directe | $Y_D$ par tête | 0,164825 | 0,164631 | [0,156878 ; 0,172744] | 0,004122 |
| **TVA directe** | **$Y_P$ par tête** | **0,157253** | **0,157063** | **[0,149407 ; 0,165072]** | **0,004110** |
| TVA directe + enchâssée | $Y_D$ par tête | 0,130015 | 0,129916 | [0,123410 ; 0,137015] | 0,003706 |
| **TVA directe + enchâssée** | **$Y_P$ par tête** | **0,122390** | **0,122299** | **[0,115419 ; 0,129627]** | **0,003825** |

Le déplacement du Kakwani ($-0{,}0076$) est du même ordre que l'écart type du bootstrap
($0{,}0041$) : il vaut moins de deux écarts types, et les deux intervalles se
chevauchent sur la quasi-totalité de leur longueur (les bornes $Y_P$ tombent à
l'intérieur de l'intervalle $Y_D$ pour la borne haute, et l'écart entre bornes basses
est de 0,0075).

---

## 3. Tous les scénarios sous le classement $Y_P$ par tête

Feuille `kakwani_rs_par_classement`. L'écart au classement $Y_D$ est remarquablement
stable d'un scénario à l'autre : entre $-0{,}00756$ et $-0{,}00764$ sur les six
scénarios et les deux assiettes, soit une translation quasi rigide.

| Scénario | Kakwani $Y_D$ | Kakwani $Y_P$ | Écart | RS $Y_D$ | RS $Y_P$ | Écart |
|---|---|---|---|---|---|---|
| **TVA directe** | | | | | | |
| S1 | 0,075556 | 0,067933 | $-0{,}007623$ | 0,0069375 | 0,0061572 | $-0{,}000780$ |
| S2 | 0,131864 | 0,124268 | $-0{,}007597$ | 0,0063813 | 0,0059652 | $-0{,}000416$ |
| **S3** | **0,164825** | **0,157253** | **$-0{,}007573$** | **0,0075665** | **0,0071694** | **$-0{,}000397$** |
| S4 | 0,104323 | 0,096741 | $-0{,}007583$ | 0,0058542 | 0,0053817 | $-0{,}000472$ |
| S5 | 0,156097 | 0,148533 | $-0{,}007563$ | 0,0070700 | 0,0066809 | $-0{,}000389$ |
| S5′ | 0,151523 | 0,143965 | $-0{,}007558$ | 0,0068146 | 0,0064296 | $-0{,}000385$ |
| **TVA directe + enchâssée** | | | | | | |
| S1 | 0,067959 | 0,060314 | $-0{,}007645$ | 0,0072004 | 0,0062944 | $-0{,}000906$ |
| S2 | 0,106349 | 0,098707 | $-0{,}007641$ | 0,0066569 | 0,0061214 | $-0{,}000536$ |
| **S3** | **0,130015** | **0,122390** | **$-0{,}007626$** | **0,0078597** | **0,0073435** | **$-0{,}000516$** |
| S4 | 0,087155 | 0,079530 | $-0{,}007625$ | 0,0061343 | 0,0055415 | $-0{,}000593$ |
| S5 | 0,123209 | 0,115590 | $-0{,}007619$ | 0,0073701 | 0,0068620 | $-0{,}000508$ |
| S5′ | 0,119659 | 0,112043 | $-0{,}007615$ | 0,0071184 | 0,0066143 | $-0{,}000504$ |

Le classement des scénarios est strictement conservé sous $Y_P$ comme sous $Y_D$ et sous
les deux échelles d'équivalent-adulte : $S3 > S5 > S5' > S2 > S4 > S1$ pour le Kakwani,
sur les deux assiettes. Tous les Kakwani restent strictement positifs sous les sept
classements, les deux assiettes et les six scénarios : le plus petit de l'ensemble est
$0{,}052$ (S1, directe + enchâssée, rang $Y_P$ PGT).

---

## 4. D'où vient le déplacement : décomposition par la variante B

C'est le résultat le plus utile pour la rédaction de T4. Sous la variante B (concept de
bien-être maintenu à $Y_D$, seul le rang change), le Kakwani de S3 ne bouge
pratiquement pas :

| Classement | Kakwani variante A (concept) | Kakwani variante B (rang seul) |
|---|---|---|
| $Y_D$ par tête | 0,1648253 | 0,1648253 |
| $Y_P$ PDI par tête | 0,1572527 | **0,1647875** ($-0{,}0000378$) |
| $Y_P$ PGT par tête | 0,1469724 | 0,1627062 ($-0{,}0021191$) |
| $Y_P$ par adulte éq. 1 | 0,1541436 | 0,1616535 (contre 0,1615095 pour $Y_D$ ae1) |
| $Y_P$ par adulte éq. 2 | 0,1525145 | 0,1599674 (contre 0,1598183 pour $Y_D$ ae2) |

Autrement dit : **reclasser les ménages selon un revenu qui n'a servi à construire ni
l'assiette ni les $\alpha$ ne déplace pratiquement pas la concentration de la charge de
TVA** ($C$ passe de 0,498445 à 0,498135, soit $-0{,}0003$). Les $-0{,}0076$ de la
variante A viennent presque entièrement de l'autre terme du Kakwani : le Gini de la
variable de référence passe de 0,333619 pour $Y_D$ à 0,340882 pour $Y_P$
($+0{,}007263$), parce que les transferts publics et les prélèvements directs réduisent
l'inégalité entre $Y_P$ et $Y_D$. Le déplacement mesure donc le fait que $Y_P$ est plus
inégal que $Y_D$, non un effet de circularité du classement sur l'assiette.

C'est un argument favorable au papier, et il est chiffré : la crainte du rapporteur
selon laquelle le Kakwani de 0,165 serait « en partie une propriété mécanique du
dispositif de calcul » se traduit, quand on la teste, par un déplacement de
$-0{,}0076$ (soit $-4{,}6$ %), dont $-0{,}00004$ seulement est imputable au classement
lui-même.

---

## 5. Phrase d'interprétation factuelle, à l'usage de T4

Sous un classement fondé sur le revenu primaire reconstruit — indépendant de l'assiette
puisqu'il n'intervient ni dans les coefficients $\alpha$, ni dans les déciles de S3, ni
dans la charge — le Kakwani de la TVA directe sous S3 passe de $0{,}165$ à $0{,}157$ et
le Reynolds–Smolensky de $+0{,}00757$ à $+0{,}00717$, soit des baisses de $4{,}6$ % et
$5{,}2$ % ; sur la TVA directe et enchâssée, de $0{,}130$ à $0{,}122$ et de $+0{,}00786$
à $+0{,}00734$ ($-5{,}9$ % et $-6{,}6$ %). Le déplacement, inférieur à deux écarts types
du bootstrap Rao–Wu, laisse les deux intervalles de confiance largement superposés
([0,157 ; 0,173] contre [0,149 ; 0,165]), ne change ni le signe des indices, ni
l'ordre des six scénarios de taxation, et provient pour l'essentiel de ce que le revenu
primaire est plus inégal que le revenu disponible (Gini $0{,}341$ contre $0{,}334$) et
non d'un reclassement des ménages : à concept de bien-être inchangé, le seul changement
de rang déplace le Kakwani de $-0{,}00004$. Les classements par adulte équivalent
donnent le même diagnostic avec des amplitudes voisines ($-6{,}5$ % et $-7{,}5$ %), et
la convention PGT, plus défavorable parce qu'elle sort les pensions du revenu primaire,
borne le déplacement à $-10{,}8$ %.

---

## 6. Modification de code

| Fichier | Nature de la modification |
|---|---|
| `05_scripts_R/06_02_sensitivity_ranking.R` | Appel de `run_extended_rankings(paths, hh)` ajouté en fin de `run_sensitivity_ranking()`, et nouvelle fonction `run_extended_rankings()` : construction des sept classements, jointure de `SILVER/22/all_income_concepts.parquet` (revenu primaire PDI et PGT) et de `SILVER/13b/fiscal_data_local_io_current.parquet` (TVA directe et TVA totale, S1 à S5′), calcul des indices en variantes « concept » et « classement fixe », test de cohérence bloquant contre `SILVER/06/06_01_ceq_summary_scenarios.parquet`, table d'écarts au classement $Y_D$, bootstrap Rao–Wu 500 sur le Kakwani de S3, export de `06_02_ceq_rankings_extended.xlsx`. Les sorties préexistantes (`06_02_eff_vat_*.xlsx`, `06_02_ceq_rankings.xlsx`, `06_02_ceq_rankings.parquet`) sont inchangées. |

Le bloc dégrade proprement : si `SILVER/22` ou `SILVER/13b` n'existent pas encore lors
d'une exécution du pipeline complet depuis l'étape 1, il émet un message et se
restreint aux classements et assiettes disponibles au lieu d'échouer.

**Nouvelle sortie à répercuter dans `replication_package/exhibit_map.csv` par T11 :**
`07_reports/tables/06/06_02_ceq_rankings_extended.xlsx`.
