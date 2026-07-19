# Réponse aux rapporteurs — deuxième tour simulé

**Manuscrit :** « TVA, informalité et pauvreté en Côte d'Ivoire : une analyse
d'incidence fiscale sur l'EHCVM 2021 »
**Revue cible :** *World Development*
**Version révisée :** `DT_CEQ_CIV2021_v4.pdf`

Nous remercions l'éditrice et les cinq rapporteurs. La révision ne se limite pas
à une réécriture. Nous avons repris la chaîne de calcul depuis les dépenses de
l'EHCVM jusqu'aux agrégats fiscaux, ajouté l'inférence conforme au plan de
sondage, rejoué les scénarios de réforme et rendu explicite le niveau atteint
dans la cascade CEQ. Toutes les grandeurs du papier proviennent désormais des
sorties du pipeline; aucune valeur de résultat n'est saisie manuellement.

## Réponse à la décision éditoriale

### 1. Modèle entrées-sorties et TVA incorporée

Le TRE ivoirien 2023 aux prix courants est désormais la spécification centrale.
Le TRE constant et l'ICIO OCDE 2020 sont présentés comme deux contrôles de
robustesse. La méthode est documentée dans le papier par les équations de
valorisation, de construction produit-produit, de premier tour fiscal et de
propagation de Leontief, ainsi que par un schéma de chaîne de production.

La matrice d'emplois est d'abord convertie des prix d'acquisition aux prix de
base. Les marges de commerce et de transport sont retirées des lignes de
produits puis réaffectées aux services correspondants; les impôts nets sur les
produits sont retirés. Les emplois sont ensuite séparés entre origines
domestique et importée. La TVA d'amont non récupérable est calculée au point où
la chaîne de déduction est rompue, puis propagée dans tous les tours domestiques
par `(I-A_d')^{-1}`. Les importations interviennent au premier tour, sans être
itérées comme production ivoirienne. Direct et incorporé partagent enfin un
dénominateur TTC commun au niveau item, ce qui préserve leur additivité.

Le matériel Stata de référence contient une concordance déterministe détaillée
entre les postes de consommation et 52 secteurs I/O. Le pipeline en extrait la
table, vérifie l'unicité de chaque affectation, puis applique une passerelle
explicite `52 secteurs -> 48 produits TRE`. Chaque poste a ainsi une affectation
unique. Les taux et parts taxables sectoriels sont des moyennes
pondérées par la consommation nationale de l'EHCVM, et non des moyennes non
pondérées de secteurs possibles. Le mapping couvre 92,5 % de la consommation
pondérée pour le TRE et 95,2 % pour ICIO.

Les contrôles numériques sont publiés dans les tables 13 : rayon spectral de
0,346 pour le TRE courant, 0,347 pour le TRE constant et 0,318 pour ICIO;
résidus de l'ordre de `10^-17`. Sous S3, les masses totales sont de 907,3,
913,0 et 903,2 milliards de FCFA. La différence de pauvreté TRE courant–ICIO
est de -0,072 point, avec un IC à 95 % de [-0,197; 0,031]. La comparaison ne
soutient donc plus une différence substantielle entre matrices; elle établit
la robustesse du résultat à la source I/O.

**Code et sorties :** `utils/leontief_vat.R`, `extract_local_io_v4.R`,
`13_leontief_io.R`, `13b_leontief_local_io.R`, tables `13_02` à `13_06`, et
annexe de concordance du manuscrit.

### 2. Positionnement dans la littérature

L'introduction a été réécrite. L'emploi d'un modèle I/O pour la taxe incorporée
n'est plus présenté comme la nouveauté du papier. La contribution est située
par rapport à Warwick et al. (2022) et à la pratique TAXDEV : application
ivoirienne récente, intégration explicite de l'informalité des achats,
concordance auditable entre questionnaire et TRE national, et inférence de
sondage sur les effets de pauvreté. Le papier cite désormais la deuxième
édition du *CEQ Handbook* et Jensen (2022) pour le lien entre structure de
l'emploi, déclaration par tiers et capacité de l'impôt direct.

### 3. Inférence et unité de classement

Les Kakwani, FGT et différences entre matrices reposent sur 500 réplications du
bootstrap Rao–Wu stratifié par grappes. Les mêmes poids de réplication sont
utilisés pour les variantes appariées, ce qui incorpore leur covariance. Les
FGT utilisent les poids de personnes `hhweight * hhsize`, le seuil officiel
EHCVM de 369 516 FCFA par personne et par an, et `Y_D` par tête comme unité de
classement centrale. Les dépenses sont winsorisées séparément par produit au
P99; P95 et P99,5 sont conservés comme sensibilités. Les régressions de
déterminants sans tableau ont été retirées.

La précédente question sur les revenus nets négatifs ne s'applique plus à la
construction révisée : `pcexp` ancre le revenu disponible, tandis que les
revenus pré-fiscaux provisoires sont reconstruits à rebours en ajoutant les
prélèvements. Aucun revenu net négatif n'est donc tronqué dans le calcul du
Reynolds–Smolensky présenté. La première page précise R 4.5.3, la branche de
réplication et le script maître.

**Code et sorties :** `utils/distributive.R`, `14_leontief_poverty.R`,
`15_reform_vat_simulation.R`, tables 06, 14, 15 et `16_05`.

### 4. Cohérence institutionnelle et externe

La masse de TVA S3 est rapprochée des 556,3 milliards de TVA intérieure
encaissée par la DGI : le ratio collecte/simulation vaut 80,3 % pour la TVA
directe et 61,3 % pour la TVA totale. Ces ratios restent des diagnostics de
champ, car la référence DGI exclut notamment la TVA en douane. Les simulations
directes sont comparées au poste administratif plus large de 591,6 milliards
d'« impôts sur revenus et salaires ». Les masses sont aussi exprimées en
pourcentage du PIB nominal 2021 et une conversion fixe FCFA–euro est donnée.

La CMU est construite à partir de la couverture publique déclarée dans le
module santé, d'un tirage reproductible séparé parmi pauvres et non-pauvres et
d'une contribution de
1 000 FCFA par mois pour les adultes non pauvres retenus. Le vivier observé
n'atteint pas les cibles administratives; l'écart est publié. Une application
statutaire à tous les adultes constitue une borne distincte.

Pour l'impôt sur salaire, le papier définit un scénario central
d'assujettissement multi-critères sur les emplois principal et secondaire. Les critères strict
(`bulletin ET cotisation`), élargi (`bulletin OU cotisation`) et une borne haute
de non-réponse sont publiés. La définition OIT issue de la 21e CIST est un
diagnostic séparé et n'est ni le centre du papier ni l'assiette centrale. Le
partage égal des parts d'enfants modifie l'IRPP de 0,04 %, l'emploi secondaire
représente 1,60 % de la masse salariale du proxy et la borne de non-réponse
augmente l'IRPP de 42,8 %.

Un tableau descriptif par milieu, une validation externe et une comparaison
avec Akim et al. (2020) ont été ajoutés. Le nombre CGRAE publié, limité aux
agents publics, n'est pas comparable au proxy EHCVM public-privé; nous le
signalons au lieu de produire un ratio trompeur. La nouvelle table `16_10` et
la figure 16 montrent la charge à la fois en pourcentage du revenu disponible
et en pourcentage du salaire des assujettis. Les égalités de salaire pour le
quotient familial sont départagées par l'ordre stable de l'identifiant.

**Code et sorties :** `16_direct_taxes.R`, tables `16_04` à `16_10`, figure
`fig16_direct_burden_decile.png`.

### 5. Réforme à 9 % et recyclage

Les ensembles agricole, commerce et large sont simulés sous strict, S2 et S3.
Le contrefactuel budgétairement neutre redistribue uniformément la recette par
personne; recette et transfert sont recalculés dans chaque réplication Rao–Wu.
Sous S3, la réforme large lève 97,2 milliards et augmente la pauvreté de 0,47
point sans recyclage, mais la réduit de 0,23 point après transfert universel.
La réforme agricole lève 54,1 milliards; les effets correspondants sont +0,26
et -0,15 point. Le papier précise que le taux de 9 % modifie la vente finale et
ne recalcule pas automatiquement le vecteur de taxe déjà incorporée.

**Code et sorties :** `utils/vat_scenarios.R`,
`15_reform_vat_simulation.R`, tables `15_01` à `15_05` et figure de réforme.

## Cascade CEQ et portée des résultats

La méthodologie applique maintenant les identités économiques de la cascade
CEQ :

`Y_N = Y_P - impôts directs - cotisations`,
`Y_G = Y_P + transferts directs`,
`Y_D = Y_N + transferts directs`,
`Y_C = Y_D - impôts indirects + subventions`,
`Y_F = Y_C + santé + éducation + autres transferts en nature`.

`Y_N` et `Y_G` sont des branches parallèles; le revenu imposable administratif
n'est pas un concept CEQ. Dans l'EHCVM, `pcexp` est l'ancre observée de `Y_D`.
Le pipeline produit donc aujourd'hui un `Y_C` partiel, comprenant la TVA
directe et incorporée. L'étape 16 permet seulement une reconstruction
provisoire `Y_N*=Y_D` et `Y_P*=Y_D+D+C` sous l'hypothèse de transferts directs
nuls. Le papier ne présente plus `conso_w` comme revenu de marché : il s'agit
de l'assiette d'affectation des dépenses, winsorisée par produit.

La figure de cascade et la feuille de route rendent visibles les composantes
restantes : accises et douanes; pensions contributives et transferts directs;
subventions indirectes; éducation et santé en nature; assemblage des concepts;
puis synthèse CEQ complète. Les modules du questionnaire mobilisables sont
inventoriés dans le texte et dans `NOTE_CASCADE_CEQ_QUESTIONNAIRE.md`.

## Fichiers de réplication et vérifications

- Manuscrit : `00_documentation/working_paper/DT_CEQ_CIV2021.tex`
- Bibliographie : `00_documentation/working_paper/references.bib`
- PDF révisé : `00_documentation/working_paper/DT_CEQ_CIV2021_v4.pdf`
- Note CEQ/questionnaire : `00_documentation/NOTE_CASCADE_CEQ_QUESTIONNAIRE.md`
- Feuille de route : `00_documentation/CEQ_ROADMAP.md`
- Orchestrateur : `05_scripts_R/00_master.R`

L'appel ciblé `lance_pipeline(17, 17)` exécute et termine uniquement l'étape 16.
Les équations, diagnostics, tables et figures mentionnés ci-dessus sont
regénérés par les scripts, et le PDF est compilé à partir de ces sorties.
