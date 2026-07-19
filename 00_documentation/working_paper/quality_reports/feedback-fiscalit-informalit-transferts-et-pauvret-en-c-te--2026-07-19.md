# Fiscalité, informalité, transferts et pauvreté en Côte d'Ivoire : une analyse d'incidence sur l'EHCVM 2021

**Date**: 19/07/2026 20:01:05
**Domain**: social_sciences/economics
**Taxonomy**: academic/research_paper
**Filter**: Active comments

---

## Overall Feedback

**Paramétrage du scénario d'informalité S3**

Les résultats principaux s'appuient massivement sur le scénario S3, dans lequel la TVA directe passe de 1 387 milliards sous transmission intégrale à 693 milliards, recalculant par la même occasion les effets de pauvreté et les recettes des réformes. La section 4.3 explique que l'hypothèse de taxation effective $\alpha_{kh}$ varie par fonction COICOP et par décile, conformément à Bachas et al. (2024).

Cependant, les paramètres précis de cette variation restent absents du texte. Le lecteur cherchera à consulter la matrice des coefficients $\alpha$, la règle exacte de calibration, les cibles retenues, ainsi que la justification empirique des niveaux appliqués au contexte ivoirien. Publier ces paramètres et montrer les profils implicites de formalité par décile permettrait d'éviter que le scénario S3 agisse comme une boîte noire et permettrait de distinguer formellement une mesure d'incidence ancrée dans les données d'une simple hypothèse structurante.


**Construction de la TVA enchâssée**

La modélisation de la TVA enchâssée constitue une contribution méthodologique majeure, ajoutant 214 milliards de FCFA sous le scénario S3. La section 4.6 définit la charge de premier tour par l'équation $b=(1-e)\odot(A^{d\prime}+A^{m\prime})\bar\tau$. Dans ce calcul, la variable $e_i$, construite en section 4.5 à partir de la part taxable des dépenses finales, sert de proxy pour établir le droit à déduction de la production tout entière.

Cette formulation imbrique le statut fiscal du produit, le droit à déduction de l'entreprise et l'informalité productive finale dans un seul paramètre dérivé de la demande des ménages. Séparer conceptuellement ces trois objets (le taux statutaire sur les intrants, la fraction de la production conférant un droit à déduction, et la transmission/formalité lors de la vente finale) clarifierait la mécanique sous-jacente. Il est recommandé de proposer une sensibilité où la variable $e$ est construite à partir d'un classement juridique des branches ou des produits plutôt qu'à partir de la seule dépense finale observée dans l'enquête.


**Concordance entre le libellé de réforme et le contrefactuel simulé**

La section 4.15 précise que le passage de produits exonérés au taux de 9 % laisse inchangés les coefficients techniques ainsi que le vecteur $c$ de taxe intégrée. Mathématiquement, la réforme simulée se comporte donc comme une taxe additionnelle sur la vente finale.

Les sections 6.2 et 8, en revanche, décrivent cette simulation comme le fait de « porter certains produits exonérés au taux de 9 % ». Dans la stricte logique d'une taxe sur la valeur ajoutée, lever une exonération pour acter une taxation à 9 % ouvrirait des droits à déduction sur les intrants et modifierait nécessairement la TVA non récupérable dans la chaîne de coûts. L'écart entre le libellé politique et la réalité du choc statique modélisé requiert une mise en cohérence : renommer la simulation comme une taxation de la vente finale à vecteur $c$ constant, ou introduire une variante modélisant la reclassification des produits dans la matrice des droits à déduction.


**Imputation du PSSN et ciblage effectif**

La section 4.9 reconstitue un ciblage basé sur un proxy means test (PMT) sélectionnant 191 767 ménages, calé sur une masse de 27,108 milliards de FCFA. La section 5.6 indique de son côté que ce PMT cible des bénéficiaires dont 85,9 % se situent sous le seuil de pauvreté, tandis que la proportion n'est que de 37,7 % parmi les ménages déclarant effectivement recevoir ce transfert dans l'enquête (avec un chevauchement pondéré de seulement 972 ménages).

Cette substitution d'une incidence déclarée par un ciblage théorique modifie drastiquement le profil distributif de l'instrument. Si l'objectif du cadre CEQ est d'évaluer le système socio-fiscal tel qu'il est réellement reçu, l'utilisation exclusive d'un ciblage reconstitué parfait pose question. Ajouter une variante centrale ou de robustesse qui intègre en priorité les bénéficiaires déclarés par l'enquête, avant de combler les quotas manquants via le PMT, rapprocherait l'incidence simulée de l'incidence manifeste.


**Hiérarchie et publication des scénarios d'impôts directs**

La section 4.8 construit plusieurs critères d'assujettissement : l'un strict (exigeant bulletin de paie et cotisation), l'un élargi, et un scénario central multicritères. Le tableau 9 rapporte que le scénario strict génère paradoxalement davantage d'IRPP (290,3 milliards) que le scénario central (225,5 milliards). Par extension, une estimation incluant le traitement des non-réponses au sein d'une borne haute aboutit à une masse de l'IRPP d'environ 322 milliards.

L'inversion apparente des masses entre la définition stricte et la définition agrégée mérite une analyse explicite pour dissiper tout doute sur la mécanique du module salarial. Afin de certifier le volume des prélèvements directs, composante qui dicte la décomposition de Shapley, le document devrait détailler pour chaque scénario d'assujettissement (strict, central, élargi) les effectifs pondérés correspondants, la masse salariale concernée, le produit de l'IRPP, la charge de cotisations, ainsi que la méthode stricte de traitement des données manquantes.

**Status**: [Pending]

---

## Detailed Comments (4)

### 1. Dénominateur de TVA enchâssée en section 4.6

**Status**: [Pending]

**Quote**:
> Pour ne pas compter deux fois la même dépense TTC, les composantes directe et enchâssée utilisent un dénominateur commun. Pour une dépense $d$, un taux direct $\tau$, un taux enchâssé $c$ et une part formelle $\alpha$, nous calculons

$$
\begin{aligned}
& T^{d}(d)=\alpha d \frac{\tau}{1+\tau+c}, \\
& T^{e}(d)=\alpha d \frac{c}{1+\tau+c}+(1-\alpha) d \frac{c}{1+c} .
\end{aligned}
$$

Une transaction finale informelle ne supporte pas la TVA directe, mais son prix peut contenir une taxe incorporée plus en amont. La figure 2 résume cette mécanique.

**Feedback**:
La décomposition de la dépense TTC en TVA directe et TVA enchâssée dépend d'une convention qui n'est pas entièrement explicite. Si $c$ est interprété comme un coût amont incorporé au prix hors TVA, la TVA finale devrait aussi s'appliquer à cette composante, ce qui ferait apparaître un terme croisé $	au c$. Les fractions $\tau/(1+\tau+c)$ et $c/(1+\tau+c)$ sont donc cohérentes seulement si $c$ est défini comme une composante additive du prix avec la TVA finale, et non comme un multiplicateur de coût avant TVA finale.

---

### 2. Dénominateur de TVA directe à clarifier en 4.3

**Status**: [Pending]

**Quote**:
> La dépense $d_{k h}$ observée pour le produit $k$ est un montant toutes taxes comprises. La part de TVA qu'elle contient est donc $\tau_{k} /\left(1+\tau_{k}\right)$, et non le taux appliqué directement au montant TTC. Pour un ménage $h$, la TVA directe s'écrit

$$
T_{h}^{d}=\sum_{k} d_{k h} \alpha_{k h} \frac{\tau_{k}}{1+\tau_{k}},
$$

![](/documents/6859754a-8a61-47b2-959d-909f409109c6/images/image_001.jpg)
Figure 1 - Relations entre les concepts de revenu CEQ.

**Feedback**:
Dans la sous-section 4.3, la formule $T_h^d=\sum_k d_{kh}\alpha_{kh}\tau_k/(1+\tau_k)$ est présentée comme la formule de TVA directe, alors que la décomposition TTC de la sous-section 4.6 utilise ensuite le dénominateur commun $1+\tau+c$ pour séparer TVA directe et TVA enchâssée. Cette différence rend ambiguë la formule effectivement utilisée pour les résultats centraux de TVA directe.

---

### 3. Interaction alpha-TVA dans les accises en section 4.7

**Status**: [Pending]

**Quote**:
> Les accises et droits de douane sont retirés de la dépense TTC en respectant l'ordre légal de la cascade. Chaque poste de consommation est relié à un produit du TRE, à une bande du TEC et, s'il est accisable, à un taux 2021 . La part importée du produit $k$ est $m_{k}=M_{k} /\left(M_{k}+Q_{k}\right)$, à partir des importations et de la production domestique du TRE ; la part de marges commerciales et de transport est notée $\mu_{k}$. Pour une dépense $d_{k h}$, la base hors marges est $B_{k h}=d_{k h}\left(1-\mu_{k}\right)$. Si $\epsilon_{k}$ est le taux d'accise, $\delta_{k}$ la bande TEC et $r_{k}$ le taux de TVA, les deux charges directement contenues dans l'achat sont

$$
\begin{aligned}
A_{k h} & =B_{k h} \frac{\epsilon_{k}}{\left(1+\epsilon_{k}\right)\left(1+r_{k}\right)}, \\
T_{k h}^{\text {douane }} & =B_{k h} \frac{\delta_{k} m_{k}}{\left(1+\delta_{k} m_{k}\right)\left(1+\epsilon_{k}\right)\left(1+r_{k}\right)} .
\end{aligned}
$$

**Feedback**:
La formule d'extraction des accises et droits de douane gagnerait à préciser l'hypothèse faite sur la couche de TVA représentée par $(1+r_k)$. Comme ce facteur n'est pas modulé par $\alpha_{kh}$, le calcul semble supposer que le prix hors marges inclut toujours la TVA de la cascade amont, même lorsque la vente finale est traitée comme informelle pour la TVA directe. Si $\alpha_{kh}$ devait au contraire signifier que cette couche de TVA n'est pas contenue dans le prix observé, les accises et droits de douane pourraient être sous-estimés pour ces achats.

---

### 4. Unités ambiguës dans les identités de revenu en 4.2

**Status**: [Pending]

**Quote**:
> Le calcul complet retranche du revenu disponible la TVA payée sur les achats finaux, la TVA non récupérable répercutée dans les prix, les accises et les droits de douane, puis ajoute les réductions de prix de l'eau et de l'électricité. Il ajoute enfin les services publics d'éducation et de santé :

$$
\begin{aligned}
I_{h} & =\mathrm{TVA}_{h}^{\text {directe }}+\mathrm{TVA}_{h}^{\text {non deduct. }}+\text { Accises }_{h}+\text { Douane }_{h}, \\
Y_{C h} & =Y_{D h}-I_{h}+\text { Aides de prix }_{h} \\
Y_{F h} & =Y_{C h}+\text { Education }_{h}+\text { Sante }_{h}
\end{aligned}
$$

Les aides de prix et services sont exprimés par personne dans les identités, après agrégation des montants au ménage.

**Feedback**:
Dans la sous-section 4.2, les identités autour de $Y_{C h}$ laissent une ambiguïté d’unités : $Y_{D h}$ est introduit comme une grandeur par tête, tandis que $I_h$ agrège des taxes calculées au niveau du ménage. La phrase finale précise la conversion par personne pour les aides de prix et les services, mais pas explicitement pour $I_h$.

---
