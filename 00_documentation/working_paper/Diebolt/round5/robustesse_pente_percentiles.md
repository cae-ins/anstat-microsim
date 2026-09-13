# Robustesse de la pente de prix de l'annexe B — finesse des rangs, estimation continue, repère externe

**Statut : exploration.** Ce mémo ne fait partie d'aucune tâche du `plan_round5.md`.
Ni `informality_anchor.R` ni `DT_CEQ_CIV2021.tex` n'ont été modifiés. Le code de
cette exploration est isolé dans `05_scripts_R/utils/robustness_price_gradient_round5.R`,
qui recopie la logique d'échantillonnage de `vat_unit_value_gradient()` sans y toucher.
Sortie chiffrée : `07_reports/tables/06/06_06_robustness_price_gradient.xlsx`.

**Référence à battre (T1, spécification principale).** Pente du logarithme du prix
unitaire relatif, différence produits taxés − produits non taxés, par rang de décile,
avec contrôle intra-cellule de la quantité :
$\hat\pi = -0{,}002841$, erreur type $0{,}001172$, IC 95 % $[-0{,}005138 ; -0{,}000543]$,
$p = 0{,}0154$. La spécification A0 ci-dessous la reproduit à la dixième décimale
($-0{,}00284056531$, erreur type $0{,}00117231158$), ce qui vérifie que la copie de code
est fidèle.

---

## 0. Verdict en tête

Les trois analyses vont dans le même sens et **ne déplacent pas la conclusion de
l'annexe B** ; deux d'entre elles la renforcent.

1. **La discrétisation n'est pas le sujet.** Ventiles, cinquantiles et centiles donnent,
   après remise à l'échelle, exactement la même pente que les déciles
   ($-0{,}00277$ à $-0{,}00290$) avec des erreurs types identiques à $0{,}5$ % près. Le
   résultat n'est pas un artefact de découpage en dix groupes.
2. **La discrétisation elle-même n'est pas nécessaire.** Le rang percentile continu et
   le logarithme de la consommation par tête donnent $-0{,}00290$ et $-0{,}00289$ en
   équivalent par décile, à l'intérieur de l'intervalle de confiance de référence. La
   forme linéaire n'est pas rejetée non plus (Wald contre le modèle saturé, $p = 0{,}32$ ;
   terme quadratique en rang, $p = 0{,}62$).
3. **Le repère externe rétrécit fortement l'écart, sans l'annuler.** La pente
   d'informalité la plus conservatrice de Bachas, Gadenne et Jensen (2024, Table 2,
   $-4{,}6$ point de pourcentage par point de log, spécification avec effets COICOP-4 et
   blocs d'enquête) implique, une fois traduite, une pente de prix de $+0{,}00144$ par
   décile — soit **quatre fois moins** que le $+0{,}00552$ postulé par S3, mais toujours
   hors de l'intervalle observé. Cette traduction est fragile et **ne doit pas être
   publiée comme un chiffre** ; elle vaut comme ordre de grandeur.

Le point 3 recèle le résultat le plus intéressant du mémo, et il ne porte pas sur la
pente observée mais sur S3 : **la pente alimentaire de S3 ($0{,}034$ par décile) est de
1,7 à 3,8 fois plus raide que ce que les estimations de Bachas et al. impliquent
elles-mêmes une fois converties à l'échelle des déciles ivoiriens** ($0{,}0197$ avec leur
spécification simple, $0{,}0089$ avec leurs contrôles complets). Le paramétrage de S3
sur-extrapole donc la source qu'il invoque, indépendamment de tout ce que disent les
valeurs unitaires ivoiriennes.

---

## 1. Méthode

### 1.1 Échantillon

Strictement celui de la spécification principale de T1 : module 7B de l'EHCVM 2021,
prix unitaire implicite $= $ `s07bq08` $/$ `s07bq07a`, cellules
produit × unité (`s07bq07b`) × conditionnement (`s07bq07c`) × région, retenues si elles
comptent au moins 20 observations et au moins 5 déciles distincts.
**141 928 achats, 2 563 cellules exploitables** (59 622 achats sur produits taxés,
82 306 sur produits non taxés). Le prix relatif et la quantité relative sont tous deux
centrés, en logarithme, à l'intérieur de la cellule et pondérés par `hhweight`.
Erreurs types agrégées par grappe.

Le critère d'éligibilité des cellules reste défini **sur les déciles** dans toutes les
spécifications, y compris celles qui n'utilisent pas le décile dans la régression. C'est
délibéré : l'échantillon est ainsi rigoureusement identique d'une ligne à l'autre du
tableau, et l'on isole l'effet du choix de la variable de rang dans le modèle, jamais un
effet de composition.

### 1.2 Spécifications

Toutes de la forme

$$\text{prix\_relatif} = \beta_0 + \beta_1 \, r + \beta_2\, \text{taxe}
+ \pi \, (r \times \text{taxe}) + \gamma \, \text{log\_quantite\_relatif} + \varepsilon,$$

où seule change la variable de niveau de vie $r$ :

| Code | $r$ | Unité native | Facteur de remise à l'échelle « par décile » |
|---|---|---|---|
| A0 | rang de décile ($1$ à $10$) | par décile | $1$ |
| A1 | rang de ventile ($1$ à $20$) | par ventile | $2$ |
| A2 | rang de cinquantile ($1$ à $50$) | par cinquantile | $5$ |
| A3 | rang de centile ($1$ à $100$) | par centile | $10$ |
| B1 | rang percentile continu pondéré, dans $[0,1]$ | par unité de rang | $0{,}100003$ |
| B2 | $\log(\text{pcexp})$ | par point de log | $0{,}193119$ |

Les rangs discrets sont construits par `weighted_ntile(pcexp, pcweight, n)`, la même
fonction que le pipeline. Le rang continu utilise la convention du point médian de la
masse, $(\,\text{cumul} - w/2\,)/\text{total}$, qui évite d'attribuer $0$ au ménage le
plus pauvre et $1$ au plus riche.

Les deux facteurs de conversion des spécifications continues **ne sont pas imposés a
priori, ils sont mesurés** sur les 12 965 ménages : on régresse la moyenne pondérée
(par `pcweight`) du rang continu, puis du log de la consommation par tête, sur le rang
de décile. On obtient $0{,}100003$ unité de rang et $0{,}193119$ point de log par rang de
décile. Un décile de la distribution ivoirienne correspond donc à un écart de
consommation par tête d'environ $21{,}3$ % ($e^{0{,}1931} - 1$).

---

## 2. Analyse A — percentiles plus fins

### 2.1 Résultats

Toutes les pentes sont celles de la différence taxés − non taxés, en équivalent par
décile. La colonne « brute » donne le coefficient dans son unité native, avant remise à
l'échelle.

| Spécification | Coefficient natif | Erreur type native | **Pente par décile** | Erreur type | IC 95 % | $p$ |
|---|---|---|---|---|---|---|
| **A0. Déciles (référence T1)** | $-0{,}00284057$ | $0{,}00117231$ | $\mathbf{-0{,}002841}$ | $0{,}001172$ | $[-0{,}005138 ; -0{,}000543]$ | $0{,}0154$ |
| A1. Ventiles (20 groupes) | $-0{,}00138506$ | $0{,}00058942$ | $-0{,}002770$ | $0{,}001179$ | $[-0{,}005081 ; -0{,}000460]$ | $0{,}0188$ |
| A2. Cinquantiles (50 groupes) | $-0{,}00058090$ | $0{,}00023480$ | $-0{,}002904$ | $0{,}001174$ | $[-0{,}005206 ; -0{,}000603]$ | $0{,}0134$ |
| A3. Centiles (100 groupes) | $-0{,}00028844$ | $0{,}00011772$ | $-0{,}002884$ | $0{,}001177$ | $[-0{,}005192 ; -0{,}000577]$ | $0{,}0143$ |

Le coefficient de quantité relative est identique aux quatre décimales dans les quatre
spécifications ($-0{,}1577$), et le $R^2$ passe de $0{,}0465$ à $0{,}0466$.

### 2.2 Les effectifs se dégradent, la précision non — pourquoi

L'intuition du brief (« les erreurs types devraient se dégrader parce que les effectifs
par cellule croisée deviennent plus petits ») est exacte sur les effectifs et fausse sur
les erreurs types. Les effectifs s'effondrent bien :

| Groupement | Groupes | Cellules groupe × taxe × cellule | Observations médianes par cellule croisée | Part des cellules croisées à une seule observation |
|---|---|---|---|---|
| Déciles | 10 | 23 503 | 4 | 12,6 % |
| Ventiles | 20 | 40 924 | 2 | 27,7 % |
| Cinquantiles | 50 | 70 949 | 1 | 51,3 % |
| Centiles | 100 | 93 522 | 1 | 67,6 % |

Aux centiles, deux tiers des combinaisons groupe × taxe × cellule ne contiennent plus
qu'un seul achat. Et pourtant l'erreur type remise à l'échelle bouge de $0{,}0011723$ à
$0{,}0011788$, soit $0{,}55$ % dans le pire des cas.

La raison est structurelle et mérite d'être dite explicitement : **le rang entre
linéairement dans le modèle**. L'estimateur n'utilise à aucun moment la moyenne
intra-groupe ; il utilise la covariance entre le rang du ménage et le prix relatif de son
achat, sur les 141 928 observations. Passer des déciles aux centiles ne fait que
réétiqueter chaque ménage avec un rang dix fois plus fin, ce qui divise le coefficient
par dix et l'erreur type par dix, sans rien changer à l'information mobilisée. Les
écarts résiduels ($-0{,}00277$ contre $-0{,}00290$) viennent uniquement du fait que
`weighted_ntile` ne place pas les points de coupure aux mêmes endroits selon $n$, donc
que le rang discret est une approximation légèrement différente du rang vrai.

**Conséquence pour le papier : l'analyse A, telle que demandée, est un test faible.**
Elle établit que la conclusion ne dépend pas du découpage, mais elle ne pouvait
pratiquement pas conclure autrement. Le test informatif est celui de la section 2.3.

### 2.3 Le test qui aurait pu échouer : laisser l'écart libre à chaque décile

On estime $\text{prix\_relatif} \sim \text{décile}_f + \text{décile}_f \times
\text{taxe} + \text{log\_quantite\_relatif}$, où $\text{décile}_f$ est un facteur : dix
écarts de prix taxés − non taxés, un par décile, aucune forme imposée.

| Décile | D1 | D2 | D3 | D4 | D5 | D6 | D7 | D8 | D9 | D10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Écart de prix taxés − non taxés | $+0{,}0175$ | $+0{,}0200$ | $+0{,}0096$ | $-0{,}0021$ | $-0{,}0027$ | $+0{,}0084$ | $+0{,}0132$ | $+0{,}0015$ | $-0{,}0158$ | $-0{,}0074$ |
| Erreur type | $0{,}0116$ | $0{,}0103$ | $0{,}0094$ | $0{,}0091$ | $0{,}0095$ | $0{,}0089$ | $0{,}0079$ | $0{,}0102$ | $0{,}0078$ | $0{,}0086$ |
| $p$ | $0{,}131$ | $0{,}053$ | $0{,}307$ | $0{,}816$ | $0{,}778$ | $0{,}342$ | $0{,}094$ | $0{,}880$ | $0{,}042$ | $0{,}385$ |

Le profil est bruité — un seul décile est significatif à 5 % pris isolément — mais il
descend : $+0{,}0175$ en D1, $-0{,}0074$ en D10, soit $-0{,}0249$ sur neuf rangs, très
exactement les $-0{,}00284 \times 9 = -0{,}0256$ de la pente linéaire.

Deux tests de forme :

| Test | Statistique | $p$ |
|---|---|---|
| Wald (différences secondes) : linéaire en décile contre modèle saturé, 8 ddl | $\chi^2 = 9{,}31$ | $0{,}317$ |
| Terme quadratique $\text{rang}^2 \times \text{taxe}$ (rang continu) | $-0{,}0213$ (e.t. $0{,}0424$) | $0{,}615$ |

**La restriction linéaire n'est pas rejetée.** La droite est un résumé acceptable du
profil, et non une contrainte qui fabriquerait la pente.

---

## 3. Analyse B — estimation continue, sans discrétisation

| Spécification | Coefficient natif | Erreur type native | **Pente par décile** | Erreur type | IC 95 % | $p$ |
|---|---|---|---|---|---|---|
| **A0. Déciles (référence)** | $-0{,}00284057$ | $0{,}00117231$ | $\mathbf{-0{,}002841}$ | $0{,}001172$ | $[-0{,}005138 ; -0{,}000543]$ | $0{,}0154$ |
| B1. Rang percentile continu $[0,1]$ | $-0{,}0290110$ | $0{,}0117818$ | $-0{,}002901$ | $0{,}001178$ | $[-0{,}005210 ; -0{,}000592]$ | $0{,}0138$ |
| B2. $\log(\text{pcexp})$ | $-0{,}0149557$ | $0{,}0057018$ | $-0{,}002888$ | $0{,}001101$ | $[-0{,}005046 ; -0{,}000730]$ | $0{,}0087$ |

Lecture directe des coefficients natifs, avant toute remise à l'échelle :

- **B1.** Passer du ménage le plus pauvre au plus riche (une unité de rang complète)
  abaisse le prix unitaire des produits taxés de $2{,}90$ % relativement aux produits non
  taxés, à produit, unité, conditionnement, région et quantité achetée donnés.
- **B2.** Doubler la consommation par tête ($+0{,}693$ point de log) l'abaisse de
  $1{,}04$ %. Cette écriture est la plus proche de celle de Bachas et al., qui régressent
  aussi sur le log de la dépense — voir la section 4.

Les trois pentes remises à l'échelle ($-0{,}002841$, $-0{,}002901$, $-0{,}002888$) sont
séparées de moins de $0{,}06$ erreur type. **La discrétisation en déciles ne coûte donc
rien et ne fabrique rien.** B2 est même très légèrement plus précise que la référence
(erreur type $0{,}001101$ contre $0{,}001172$, $p = 0{,}0087$ contre $0{,}0154$), ce qui
est attendu : le log de la consommation utilise la variation de niveau de vie à
l'intérieur de chaque décile, que le rang discret jette.

---

## 4. Analyse C — repère externe (Bachas, Gadenne et Jensen 2024)

### 4.1 Pourquoi les deux pentes ne sont pas comparables

C'est le point qui doit être dit avant tout chiffre. Les deux régressions n'ont **pas la
même variable dépendante** :

| | Bachas, Gadenne et Jensen (2024) | Annexe B du présent papier |
|---|---|---|
| Variable dépendante | Part **informelle du budget** du ménage (entre 0 et 1) | $\log$ du **prix unitaire relatif** d'un achat, centré dans sa cellule |
| Variable explicative | $\log$ de la dépense totale par tête | Rang de décile (ou log de la consommation par tête) |
| Unité d'observation | Ménage | Achat alimentaire (module 7B) |
| Champ | Toute la consommation, 32 pays, nomenclature COICOP harmonisée | Alimentation seule, Côte d'Ivoire, produits du module 7B |
| Ce qui est mesuré | Le **canal** d'achat, directement observé (lieu d'achat renseigné dans leurs enquêtes) | La **conséquence de prix** du canal, observée indirectement |
| Unité de la pente | Point de part budgétaire par point de log | Point de log de prix par rang de décile |

Une pente de $-4{,}6$ chez eux et une pente de $-0{,}0028$ chez nous sont des grandeurs
sans rapport dimensionnel. Toute comparaison directe des deux nombres est un
non-sens, et le papier ne doit à aucun moment les juxtaposer sans cette mise en garde.

La différence de fond est plus importante encore que la différence d'unités : **leurs
enquêtes contiennent la variable de lieu d'achat, la nôtre non.** C'est précisément
l'absence de cette variable dans l'EHCVM 2021 (établie par le balayage exhaustif des
53 fichiers rapporté en T1) qui oblige l'annexe B à passer par les valeurs unitaires.
Notre test n'est pas une réplication moins bonne du leur : c'est un test d'une
implication de prix, exécuté faute de pouvoir observer le canal.

### 4.2 Traduction, sous hypothèses fortes et explicites

La transformation est celle qui figure déjà dans `informality_anchor.R` (l. 470–482 et
518–521) et qui sert à construire S5′. Si une part $\alpha$ des achats supporte la taxe
au taux $\tau$, le prix moyen payé vaut $(1 + \alpha\tau)$ fois le prix hors taxe, d'où

$$\frac{\partial \log p}{\partial d} \;\simeq\; \frac{\tau}{1 + \bar\alpha\tau}\,
\frac{\partial \alpha}{\partial d},
\qquad \tau = 0{,}169909, \quad \bar\alpha = 0{,}273 .$$

Pour appliquer cette formule à une pente empruntée à Bachas et al., trois hypothèses
sont nécessaires, et aucune n'est anodine :

1. **$\alpha$ est le complément à un de la part informelle du budget.** Ce que collecte
   effectivement l'administration n'est pas mécaniquement égal à la part formelle des
   achats. C'est cependant exactement l'hypothèse qui a servi à calibrer S3 : la
   traduction ci-dessous est donc dans les termes mêmes du papier, elle n'en ajoute pas.
2. **Leur pente moyenne, tous produits confondus, vaut pour l'alimentation seule.** Or
   l'alimentation est partout le poste le plus informel et le moins élastique en
   formalité au revenu. La pente alimentaire est donc, très probablement, **plus plate**
   que la moyenne empruntée : la traduction ci-dessous **surestime** le gradient
   alimentaire, ce qui joue contre la conclusion du papier et rend le calcul
   conservateur dans le bon sens.
3. **Le passage du log de la dépense au rang de décile utilise l'échelle ivoirienne**
   ($0{,}193119$ point de log par rang de décile, mesuré sur l'EHCVM 2021, section 1.2).
   Cette étape-ci est propre : elle n'emprunte rien à Bachas et al.

Restent, non corrigées : la différence de nomenclature (leur COICOP-4 harmonisée contre
les 219 176 achats du module 7B ivoirien), la différence de définition de « food »,
l'hétérogénéité entre les 32 pays de leur échantillon, et le fait que leur pente est une
moyenne inter-pays dont la Côte d'Ivoire ne fait pas partie.

**Ces réserves suffisent à disqualifier les chiffres ci-dessous comme quantités
publiables.** Ils sont rapportés comme ordres de grandeur, et le mémo recommande
explicitement de ne pas les faire figurer tels quels dans le `.tex` (section 5).

### 4.3 Résultats de la traduction

| Source | Pente d'informalité (pp par point de log) | $\partial\alpha/\partial\log c$ | $\partial\alpha$ par décile | **Pente de prix impliquée** | Dans l'IC observé ? | Écart au point estimé |
|---|---|---|---|---|---|---|
| **S3 (postulé, papier)** | — | — | $\mathbf{0{,}034000}$ | $\mathbf{+0{,}005521}$ | **non** | $+7{,}13$ e.t. |
| Bachas et al., spécification simple | $-10{,}2$ | $+0{,}102$ | $0{,}019698$ | $+0{,}003199$ | **non** | $+5{,}15$ e.t. |
| **Bachas et al., contrôles complets** (COICOP-4, blocs d'enquête) | $\mathbf{-4{,}6}$ | $+0{,}046$ | $\mathbf{0{,}008883}$ | $\mathbf{+0{,}001442}$ | **non** | $+3{,}65$ e.t. |
| **Observé (référence T1)** | $+9{,}1$ (implicite) | $-0{,}0906$ (implicite) | $-0{,}017494$ | $\mathbf{-0{,}002841}$ | — | — |

La dernière ligne inverse la transformation : la pente de prix observée correspond à une
pente de $\alpha$ de $-0{,}017494$ par décile (c'est le $s_5$ de S5′, calculé en T1), soit
$-0{,}0906$ par point de log, soit une courbe d'Engel de l'informalité **de pente
$+9{,}1$** dans les unités de Bachas et al. — là où leurs 32 pays donnent $-10{,}2$ à
$-4{,}6$. Ces chiffres ne sont pas comparables terme à terme, pour toutes les raisons de
la section 4.1 ; ils indiquent seulement que l'implication ivoirienne, prise au pied de
la lettre, se situe hors du domaine couvert par leur échantillon de pays.

Sur l'ensemble de la distribution (neuf rangs de décile, de D1 à D10), cela se lit :

| | Écart de prix taxés − non taxés, D1 à D10 |
|---|---|
| Postulé par S3 | $+4{,}97$ % |
| Impliqué par Bachas et al., spécification simple | $+2{,}88$ % |
| Impliqué par Bachas et al., contrôles complets | $+1{,}30$ % |
| **Observé (IC 95 %)** | $\mathbf{-2{,}56}$ % $[-4{,}62 ; -0{,}49]$ |

### 4.4 Ce qu'il faut en retenir

**(i) Le repère externe ne réconcilie pas l'annexe B avec S3.** Même la version la plus
conservatrice ($-4{,}6$, la plus contrôlée, appliquée avec l'hypothèse la plus
défavorable à la thèse du papier) implique une pente de prix positive, à $3{,}65$ erreurs
types du point estimé et hors de l'intervalle. Le désaccord entre S3 et les prix
ivoiriens n'est pas un désaccord de calibration fine : il est de **signe**.

**(ii) Le résultat le plus solide de cette section porte sur S3, pas sur la pente
observée.** Converties à l'échelle ivoirienne, les estimations de Bachas et al.
impliquent un gradient de $\alpha$ de $0{,}0089$ à $0{,}0197$ par décile. S3 en postule
$0{,}034$ — de $1{,}7$ à $3{,}8$ fois plus. Ce constat **ne dépend d'aucune donnée
ivoirienne autre que l'écart de log-consommation entre déciles**, et il ne dépend pas du
tout du module 7B. C'est un argument entièrement séparé de celui de l'annexe B, et il
est nettement plus robuste, parce qu'il ne fait pas intervenir la traduction en prix : il
compare une pente de $\alpha$ à une pente de $\alpha$, dans la même unité. À ce titre, il
mérite d'être considéré pour le papier bien plus que les chiffres du tableau 4.3.

**(iii) Une réserve honnête sur la portée de notre propre test.** Nos deux résultats sont
de signe opposé à celui de Bachas et al., pas seulement d'amplitude différente. Trois
lectures restent ouvertes et le papier ne peut pas trancher entre elles :
(a) le gradient de formalité alimentaire est réellement nul ou négatif en Côte d'Ivoire ;
(b) il est positif mais faible, et le test de prix n'a pas la puissance de le détecter
sous le bruit de qualité et d'assortiment intra-cellule ;
(c) les ménages aisés achètent bien davantage dans le circuit taxé, mais paient
simultanément moins cher pour des raisons que le contrôle intra-cellule de quantité ne
capte pas entièrement (accès à des points de vente à plus forte rotation, achats
groupés hors module 7B).
La formulation « infirmé pour l'alimentation » reste défendable au sens où **l'ampleur
postulée par S3 est rejetée** ; elle serait excessive si elle était lue comme
« le gradient de formalité alimentaire est négatif en Côte d'Ivoire ». La nuance vaut
d'être portée dans le texte.

---

## 5. Recommandation d'intégration

| Résultat | Publier ? | Où |
|---|---|---|
| A1–A3 (ventiles, cinquantiles, centiles) | **Non**, pas en tableau | Une phrase en annexe B suffit |
| A bis (profil non paramétrique par décile, tests de forme) | **Oui** | Annexe B, en note ou en petit tableau |
| B1–B2 (rang continu, $\log$ pcexp) | **Oui**, une ligne | Annexe B, tableau de robustesse |
| C, tableau 4.3 (traduction en prix) | **Non** | Nulle part tel quel |
| C (ii), sur-extrapolation de S3 par rapport à Bachas | **Oui, en priorité** | Section sur les scénarios, ou `sec:limites` |
| C (iii), réserve sur la portée du test | **Oui** | Annexe B ou `sec:limites` |

**Une phrase pour l'annexe B, si T5 la veut :** « La pente est insensible à la finesse du
découpage du niveau de vie (ventiles, cinquantiles, centiles) comme à son abandon : en
rang percentile continu elle vaut $-0{,}0029$ par décile équivalent
[$-0{,}0052$ ; $-0{,}0006$], et $-0{,}0029$ [$-0{,}0050$ ; $-0{,}0007$] en régression sur le
logarithme de la consommation par tête, contre $-0{,}0028$
[$-0{,}0051$ ; $-0{,}0005$] dans la spécification par décile. Laisser l'écart de prix libre
à chaque décile ne rejette pas la forme linéaire ($p = 0{,}32$). »

**Une phrase pour les scénarios ou `sec:limites`, plus importante que la précédente :**
« Le gradient alimentaire de S3 ($+3{,}4$ points de $\alpha$ par décile) est lui-même
plus raide que ce qu'impliquent les estimations qu'il invoque : rapportée à l'écart de
consommation entre déciles ivoiriens ($0{,}193$ point de log), la pente moyenne des
courbes d'Engel de l'informalité de Bachas, Gadenne et Jensen (2024) correspond à
$+2{,}0$ points de $\alpha$ par décile dans leur spécification la plus simple et
$+0{,}9$ point dans celle qui contrôle les effets fixes COICOP-4 et les blocs
d'enquête. » — Ce constat justifie S5 (pente nulle) sur une base indépendante de
l'annexe B, ce qui est un gain net : le lecteur qui ne croit pas au test de valeurs
unitaires a désormais une seconde raison d'accepter S5.

**Ce qu'il ne faut pas écrire :** aucune phrase qui mettrait en regard « $-4{,}6$ chez
Bachas et al. » et « $-0{,}0028$ ici » sans expliciter que les deux variables dépendantes
diffèrent. Et aucun report du chiffre $+0{,}001442$ comme s'il s'agissait d'une
estimation : c'est une traduction sous trois hypothèses, dont deux sont invérifiables
avec les données disponibles.

---

## 6. Reproduction

```r
source("05_scripts_R/00_setup.R")
source("05_scripts_R/utils/robustness_price_gradient_round5.R")
res <- run_price_gradient_robustness(list(SILVER = SILVER, TABLES = TABLES))
```

Durée : environ deux minutes. Sortie :
`07_reports/tables/06/06_06_robustness_price_gradient.xlsx`, feuilles `pentes`,
`profil_decile`, `profil_ventile`, `tests_de_forme`, `effectifs_par_groupement`,
`reperes_externes`, `parametres`, `moyennes_par_decile`.

Ce classeur est une sortie exploratoire : **il n'est pas à inscrire dans
`replication_package/exhibit_map.csv`** tant que la décision d'intégration au papier
n'est pas prise.

**Source des chiffres externes.** Bachas, Gadenne et Jensen (2024), *Informality,
Consumption Taxes and Redistribution*, Review of Economic Studies 91(5) ; Table 2,
« Average Slopes of the Informality Engel Curves », 32 pays. Bornes utilisées :
$-10{,}2$ (spécification sans contrôles) et $-4{,}6$ (avec effets fixes COICOP-4 et blocs
d'enquête). Ces valeurs sont saisies en dur dans le script, section C ; aucune donnée de
leur dépôt n'a été téléchargée.
