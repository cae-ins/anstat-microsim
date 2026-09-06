# Rapport externe reçu le 20 juillet 2026

## Statut

Rapport transmis par l’auteur au cours de la révision du document de travail.
Le texte ci-dessous conserve l’évaluation générale et les 25 remarques
numérotées. Lorsque l’interface d’origine n’a pas rendu une formule, la cible
est identifiée par son numéro d’équation et le signalement est conservé.

## Overall Feedback

This paper presents a fiscally detailed CEQ-style incidence analysis for Côte
d'Ivoire using the 2021 EHCVM survey, and its core finding—that the tax-transfer
system reduces inequality while simultaneously pushing households into
poverty—is policy-relevant and clearly articulated. The methodological
architecture (distinguishing direct, non-deductible, and embedded VAT; using a
Leontief price model with the 2023 supply-use table; and constructing
informality-adjusted scenarios) is ambitious and represents a genuine
contribution relative to earlier CEQ applications in francophone West Africa.

However, several issues merit attention. First, the paper's clarity would
benefit from a more concise introduction; the current structure front-loads
nearly all quantitative results before the methodology is presented, which
risks confusing readers about how the numbers were derived and under what
assumptions they hold. Second, the informality adjustment—central to the
paper's novelty—deserves more transparent validation: the reader needs to
understand how the probability of taxation varies by consumption function and
decile, what data or behavioral model supports these probabilities, and how
sensitive the poverty-increasing result is to plausible alternative
calibrations beyond the three scenarios mentioned. Third, the counterfactual
reform exercise (9% VAT on exempted products with a uniform lump-sum transfer)
is illustrative but somewhat stylized; discussing administrative feasibility,
leakage, or comparing it with existing targeting mechanisms would strengthen
its policy relevance. Finally, while the paper flags that in-kind service
valuations should not be conflated with monetary poverty, more discussion of
the welfare interpretation of the "final income" concept—and its sensitivity
to unit-cost assumptions for education and health—would be warranted given the
large magnitudes involved (1.3 trillion FCFA for education alone).

## Commentaires détaillés

### 1. Ambiguity in the direction of poverty threshold crossing

Cible : « 4,34 % de la population passe sous le seuil national » dans le
résumé et « 4,34 % de la population franchit ce seuil » dans l’introduction.

Le verbe « franchir » est directionnellement ambigu. La formulation doit
indiquer explicitement que le franchissement se fait à la baisse.

### 2. Potential inconsistency in poverty rate comparison baseline

Cible : « la pauvreté monétaire atteint 42,0 % au revenu consommable, contre
37,7 % au revenu primaire ».

Cette comparaison couvre plusieurs passages de la cascade CEQ. Elle pourrait
être interprétée à tort comme l’effet des seuls impôts indirects. Le texte doit
distinguer le passage complet du revenu primaire au revenu consommable de
l’effet propre de la fiscalité indirecte.

### 3. Scenario labeling gap: S2 described but S1 never introduced

S3 est présenté comme scénario central et S2 comme variante par milieu, tandis
que la transmission intégrale n’est pas nommée S1. L’étiquetage doit être
symétrique.

### 4. Unclear treatment of « valeurs d’usage » in the VAT simulation scope

Cible : « La simulation de TVA retient les dépenses déclarées comme achats et
comme valeurs d’usage. »

La différence entre valeurs d’usage incluses et loyers imputés exclus n’est pas
définie. Le champ doit être explicité pour permettre la réplication.

### 5. Winsorization details and impact on tax estimates omitted

La winsorisation aux 99e, 95e et 99,5e centiles n’indique ni le rôle des poids,
ni le niveau exact d’application. Son effet sur l’assiette et les recettes doit
être quantifié, notamment pour les produits peu observés.

### 6. Weighted population of 30.09 million vs. actual 2021 population

La population pondérée de 30,09 millions dépasse le résultat du RGPH 2021,
proche de 29 millions. Le papier doit expliquer les cibles de pondération et le
statut de cet écart.

### 7. Inconsistency between household size and person counts

Le tableau indique 12 965 ménages, 64 491 personnes et une taille moyenne de
4,62. Le ratio non pondéré vaut environ 4,97. Une note doit préciser que 4,62
est une moyenne pondérée.

### 8. Accise definition states it « adds to customs duties and VAT »

La formulation actuelle rend ambigu l’ordre légal. Les accises interviennent
après les droits de douane et avant la TVA, et entrent dans l’assiette de cette
dernière.

### 9. IRPP terminology potentially confusing given cédulaire tax system

Le terme IRPP peut suggérer un impôt unifié. Le papier doit indiquer clairement
s’il agrège l’impôt sur les salaires, la contribution nationale et l’impôt
général sur le revenu, ou s’il désigne seulement ce dernier.

### 10. Reynolds–Smolensky sign convention inverted relative to CEQ usage

Le papier définit l’indice comme Gini après moins Gini avant, alors que la
convention CEQ usuelle prend Gini avant moins Gini après. Cette inversion gêne
la comparaison internationale et doit être corrigée ou très fortement
justifiée.

### 11. Equation (4) labels non-deductible VAT inconsistently

L’équation de charge ménage devrait utiliser « TVA enchâssée », qui désigne la
TVA non déductible cumulée atteignant le consommateur, et non la seule TVA non
déductible au niveau de l’entreprise.

### 12. Margin reallocation in TRE adjustment is incompletely specified

Le texte décrit le retrait puis la réaffectation des marges vers le commerce et
le transport, mais seule la soustraction apparaît dans l’équation (8). La règle
de répartition doit être donnée.

### 13. Equation (9): industry-technology assumption needs clarification

Le rapport estime que la formulation A = B·T ne correspond pas nécessairement à
l’hypothèse de technologie de branche annoncée. Le papier et le code doivent
être confrontés aux définitions standard des matrices rectangulaires de
ressources et d’emplois.

### 14. Spectral radius reported for A domestique alone

Le papier doit préciser que la matrice importée entre comme vecteur de coût
exogène et non dans l’inverse, ce qui rend la condition sur le seul rayon
spectral de la matrice domestique suffisante.

### 15. Treatment of the unmapped 7.5% of consumption

La concordance TRE couvre 92,5 % de la consommation pondérée. Le traitement du
reste doit être décrit et son effet probable sur la TVA enchâssée discuté.

### 16. Equations (13)–(14): additive versus multiplicative cascade

Le rapport questionne le dénominateur additif 1 + taux final + charge
enchâssée, au regard d’une cascade multiplicative. L’approximation éventuelle
doit être vérifiée, corrigée ou bornée quantitativement.

### 17. Full-formality assumption upstream of informal retail

La charge enchâssée attribuée aux achats informels vient d’un modèle amont qui
peut supposer des chaînes de production entièrement formelles. Cette hypothèse
doit être déclarée et une sensibilité amont plausible envisagée.

### 18. IGR base formula and the 20% professional deduction

Le rapport estime que la formule de base IGR pourrait appliquer deux fois
l’abattement professionnel de 20 %. La règle juridique 2021, le code et le
papier doivent être vérifiés ensemble avant toute correction.

### 19. Quotient familial: N undefined and child allocation underspecified

Le nombre de parts N doit être défini. Il faut aussi préciser si tous les
enfants sont rattachés au contribuable le mieux rémunéré du ménage ou répartis
entre plusieurs contribuables.

### 20. CMU target numbers cited without source

Les cibles de 75 000 participants pauvres non contributifs et 1 425 000
participants non pauvres contributifs doivent être sourcées ou présentées
explicitement comme paramètres de scénario.

### 21. Electricity subsidy allocation ambiguity

Le papier doit préciser si les 8,69 milliards de FCFA sont répartis seulement
entre les abonnés au tarif social ou entre tous les ménages, et justifier
l’interprétation de l’aide d’exploitation de l’ANARE-CI.

### 22. Hospitalization weight of ten ambulatory units

Le poids central de dix unités ambulatoires par hospitalisation n’est pas
justifié. Il faut expliciter son statut d’hypothèse, documenter les bornes cinq
et vingt, et montrer l’effet distributif de cette sensibilité.

### 23. Shapley decomposition: 50 bootstrap replications

Cinquante réplications paraissent faibles au regard des 500 utilisées ailleurs.
Le papier doit fournir un diagnostic de convergence, une justification, ou
augmenter le nombre de réplications.

### 24. Bootstrap notation conflicts with household index

La lettre h sert déjà aux ménages. Une autre lettre doit indexer les strates
dans la description du bootstrap Rao–Wu.

### 25. Equation (18): zero-rated expenditure and embedded VAT

Le rapport estime que la dépense à taux nul devrait être divisée par
1 + charge enchâssée avant application du taux de 9 %. Il faut vérifier cette
objection au regard de l’assiette juridique de la vente finale et de
l’hypothèse explicite de TVA enchâssée constante.

## Décision de travail

Révision majeure ciblée. Aucun point ne sera traité par simple reformulation
lorsqu’il met en cause une formule ou un calcul. Les points 10, 13, 16, 18, 23
et 25 font l’objet d’un audit du code et des sources avant décision. Les autres
points donnent lieu à une clarification, à une mesure de sensibilité ou à un
contrôle numérique selon leur nature.
