# Rapport de mise en œuvre CEQ — étapes 20 à 26

## Objet et décisions transversales

Ce document consigne la méthode effectivement mise en œuvre, les données mobilisées, les contrôles et les résultats des étapes 20 à 26. Il part de l'état vérifié au 19 juillet 2026 : les impôts directs et
cotisations (étape 17), les accises et droits de douane (étape 18), puis les
pensions, transferts directs et filets sociaux (étape 19) sont exécutables. Les étapes 20 à 26 complètent le revenu consommable, construisent le revenu final et produisent la synthèse CEQ.

Les règles communes sont les suivantes.

- Le scénario central demeure PDI : les pensions contributives sont du revenu
  différé. Le scénario PGT, où pensions et cotisations retraite sont traitées
  comme transfert et prélèvement, est reproduit en robustesse.
- Toutes les masses sont calculées en FCFA nominaux, puis déflatées par
  `def_spa` avant d'être combinées à l'agrégat de bien-être réel.
- Le classement distributif central est le revenu disponible réel par tête de
  l'EHCVM. Les variantes par équivalent-adulte et par revenu pré-fiscal sont
  conservées lorsque le changement de rang peut modifier le diagnostic.
- Chaque paramètre externe doit être stocké dans un classeur versionné avec
  année, unité, champ, URL, page et date d'accès. Une valeur issue des anciens
  programmes Stata n'est jamais considérée comme une source primaire.
- L'incertitude de sondage est mesurée par bootstrap Rao--Wu avec 500
  réplications lorsque le coût de calcul le permet. Les calages administratifs
  et les paramètres unitaires font l'objet de scénarios distincts : le
  bootstrap ne représente pas leur incertitude.
- Chaque étape exporte une table de couverture, une réconciliation micro--macro
  et des contrôles d'identité. Aucun nouveau module ne doit modifier les sorties
  vérifiées des étapes 1 à 19.

La littérature de base est le *CEQ Handbook* (Lustig, dir., 2022), notamment
les chapitres consacrés aux subventions indirectes, à l'allocation des dépenses
d'éducation et de santé, aux concepts de revenu et à l'inférence. Le modèle
ivoirien est aussi comparé à Akim et al. (2020). La méthode d'incidence des
dépenses en nature suit Demery (2003), la décomposition de Shapley suit
Shorrocks (2013), et l'appauvrissement fiscal suit Higgins et Lustig (2016).

## Résultats de l'exécution

Les sept étapes sont exécutables dans l'orchestrateur et ont été lancées ensemble
de l'étape 20 à l'étape 26. Les identités comptables ferment au niveau de chaque
ménage à moins de 0,000001 FCFA.

- Les réductions publiques de prix représentent 25,15 milliards de FCFA dans le
  scénario central : 8,69 milliards pour l'électricité et 16,46 milliards pour
  l'eau. Aucun soutien aux carburants n'est imputé au centre faute de série 2021
  de prix de parité suffisamment comparable; une borne haute est publiée.
- Le service public d'éducation attribué aux ménages vaut 1 354,87 milliards de
  FCFA au coût public et 1 301,62 milliards après déduction des frais directement
  payés par les familles.
- Le service public de santé attribué vaut 108,53 milliards de FCFA au coût
  public et 81,85 milliards après déduction des paiements directs observés.
- Le Gini passe de 0,3414 pour le revenu primaire à 0,3168 pour le revenu final.
  Le taux de pauvreté est de 37,70 % au revenu primaire, 42,01 % au revenu
  consommable et 33,90 % après ajout des services d'éducation et de santé.
- La décomposition de Shapley attribue 34,1 % de la réduction totale du Gini aux
  impôts indirects, 28,6 % aux prélèvements directs, 27,7 % à l'éducation,
  7,3 % à la santé et 2,9 % aux paiements publics directs.
- L'analyse non anonyme identifie 4,34 % de nouveaux pauvres entre revenu
  primaire et revenu consommable. Les pertes monétaires sous le seuil atteignent
  142,73 milliards de FCFA et les gains 9,30 milliards.
- Le classeur CEQ_CIV_2021_master.xlsx réunit concepts, instruments, Shapley,
  appauvrissement fiscal, contrôles ANStat, procédure PMT et dictionnaire.

Les graphiques de ces étapes emploient uniquement bleu, vert, orange, rouge et
gris; aucun violet n'est utilisé.

## État observé des données d'enquête

L'audit des modules bruts confirme que l'enquête permet d'identifier les
bénéficiaires. Les chiffres ci-dessous ne sont pas encore des résultats
d'incidence; ils mesurent le support empirique disponible.

| Domaine | Variables EHCVM 2021 | Support observé pondéré |
|---|---|---:|
| Électricité | consommation `codpr=334`; abonnement `s11q35` | 2,19 millions de ménages avec dépense |
| Eau courante | `codpr=332` | 1,86 million de ménages avec dépense |
| Eau revendeur/borne | `codpr=333` | 0,92 million de ménages avec dépense |
| Carburants | `codpr=202,208,209,304` | 1,92 million de ménages pour les deux postes principaux |
| Public préprimaire/primaire | `s02q12`, `s02q14`, `s02q19` | 4,23 millions d'élèves |
| Public secondaire/technique | mêmes variables | 1,47 million d'élèves |
| Public supérieur | mêmes variables | 0,174 million d'étudiants |
| Soins ambulatoires publics | `s03q01`, `s03q05`, `s03q07`, `s03q12` | 42,09 millions de contacts annualisés |
| Hospitalisations publiques | `s03q19`, `s03q20`, `s03q23` | 0,871 million de séjours annualisés |

Les dépenses scolaires observées sont disponibles dans `s02q20` à `s02q27`;
les dépenses de santé dans `s03q13` à `s03q18c`, `s03q24` et les postes
connexes. Ces montants permettent de produire des bénéfices publics bruts et
nets des frais d'usager.

## Étape 20 — Subventions indirectes d'énergie et d'eau

**Module exécuté :** `05_scripts_R/19_subsidies.R`
**Identité :** compléter `Y_C = Y_D - I + S`.

### Données

Enquête : dépenses annuelles de consommation `codpr=332,333,334` pour l'eau et
l'électricité; `codpr=202,208,209,304` pour les carburants; type d'abonnement
électrique `s11q35`; milieu, région, poids, taille du ménage et déflateur
spatial. Le poste 333 est séparé du branchement direct : une dépense chez un
revendeur ne permet pas d'inverser automatiquement le tarif SODECI.

Externes : grille électrique 2021 de l'ANARE-CI par régime de paiement, tranche,
puissance et composantes fiscales; coût moyen de fourniture 2021 et compte de
stabilisation/couverture des coûts; grille SODECI et coût complet de l'eau 2021;
structure mensuelle officielle des prix pétroliers 2021, prix à la pompe et prix
de parité importation; masses budgétaires ou quasi-budgétaires comparables. Ces paramètres sont placés dans `01_data_sources/params_subsidies_2021.xlsx`.

### Mécanisme central

1. Inverser la facture observée à l'aide de la grille progressive pour estimer
   les kWh ou m3. Le régime prépayé/postpayé vient de `s11q35`; les cas sans
   compteur sont conservés dans un groupe non inversable et documenté.
2. Séparer énergie/eau, TVA, redevances et frais fixes. La subvention unitaire
   est le coût économique documenté moins le prix net acquitté. Une différence
   positive entre dans `S`; une différence négative est conservée séparément
   comme taxe ou subvention croisée et ne doit pas être tronquée silencieusement.
3. Pour les carburants, calculer chaque mois le prix sans soutien et le prix
   administré, puis multiplier l'écart par les litres imputés. L'effet direct
   concerne les achats des ménages; l'effet indirect est propagé avec le modèle
   de prix de Leontief déjà utilisé pour la TVA.
4. Additionner `subsidy_electricity_hh`, `subsidy_water_hh`,
   `subsidy_fuel_direct_hh` et `subsidy_fuel_embedded_hh`. Produire aussi les
   composantes signées avant séparation entre subvention et prélèvement.

Le carburant est soumis à une porte de validation : en l'absence d'une série
2021 auditable de prix de parité, il est déclaré « non estimé » et non remplacé
par les subventions unitaires de 2022 présentes dans l'ancien code Stata.

### Robustesse et validations

- coût de fourniture bas/central/haut; coût comptable contre coût économique;
- régime d'abonnement observé contre régime imputé à partir de la facture;
- eau du revendeur exclue, puis valorisée avec une marge basse/haute explicite;
- transmission indirecte du soutien carburant à 0, 20 et 100 %, avec 100 % comme
  hypothèse comptable centrale si aucune étude ivoirienne ne permet de l'estimer;
- quantités estimées par inversion contre quantités moyennes administratives par
  catégorie d'abonné;
- comparaison des masses à la compensation publique et aux comptes des
  opérateurs; contrôle du nombre d'abonnés par type et des consommations totales;
- bootstrap Rao--Wu pour incidence, concentration et variation de pauvreté.

### Sorties et critère de clôture

`02_data_intermediate/19/subsidies.parquet`, cinq tables (paramètres et
couverture, incidence par décile, concentration, validation macro,
sensibilités), une figure par décile. L'étape est close lorsque les inversions de
facture sont monotones, les identités sont exactes, les masses sont rapprochées
de références de même champ et chaque composante non estimée est explicitement
signalée.

### Littérature

CEQ Handbook, chapitres sur les taxes et subventions indirectes et sur les
effets indirects; Younger et al. sur les subventions énergétiques au Ghana et en
Tanzanie; Akim et al. (2020) pour le traitement régional. La grille électrique
provient de l'ANARE-CI; les comptes budgétaires de la DGBF fournissent le contrôle
macro.

## Étape 21 — Transferts en nature d'éducation

**Module exécuté :** `05_scripts_R/20_inkind_education.R`
**Identité :** construire `E` dans `Y_F = Y_C + H + E + O`.

### Données

Enquête : fréquentation formelle `s02q03` et `s02q12`, niveau `s02q14`, gestion
publique/privée `s02q19`, frais `s02q20` à `s02q27`, poids et caractéristiques
du ménage. Les huit niveaux sont regroupés en préprimaire/primaire,
secondaire général, technique-professionnel et supérieur lorsque les comptes
administratifs permettent cette ventilation.

Externes : dépenses exécutées 2021 par niveau du MENA et du MESRS, en séparant
fonctionnement, investissement, administration et transferts aux établissements;
effectifs publics 2020/21 ou 2021/22 par niveau; éventuels transferts publics aux
établissements privés. Le Budget citoyen ne suffit pas : les paramètres centraux
doivent venir de la loi de règlement, des rapports annuels de performance et des
annuaires statistiques sectoriels. Ils sont archivés dans
`params_education_2021.xlsx`.

### Mécanisme central

Calculer pour chaque niveau `k` un coût unitaire exécuté
`u_k = dépense_publique_k / effectif_public_k`. Allouer `u_k` à chaque élève
fréquentant un établissement public, agréger au ménage, puis calculer deux
mesures : bénéfice brut au coût public et bénéfice net des frais d'usager
observés. Le revenu final central utilise le bénéfice net afin de ne pas
présenter comme transfert la part financée directement par le ménage; le brut
reste la table standard d'incidence budgétaire. Les dépenses d'administration
non ventilables sont réparties au prorata des dépenses ventilées, et cette règle
est isolée dans les diagnostics.

Un élève du privé ne reçoit un bénéfice public que si un transfert public aux
écoles privées est documenté. Le coefficient de 17,6 % contenu dans l'ancien
code n'est pas repris sans source 2021.

### Robustesse et validations

- dépenses exécutées contre crédits votés; fonctionnement seul contre total y
  compris investissement;
- dénominateur administratif contre effectif public pondéré de l'enquête;
- regroupement trois niveaux contre quatre niveaux séparant le technique;
- bénéfice brut contre net de frais, et frais individuels contre moyenne par
  niveau-décile;
- exclusion centrale du privé contre allocation documentée des seuls transferts
  publics aux établissements privés;
- contrôles de couverture, âges atypiques, masse allouée égale au budget retenu,
  incidence des bénéficiaires et incidence des bénéfices;
- bootstrap Rao--Wu des parts par décile, coefficients de concentration et
  indicateurs de revenu final.

### Sorties et critère de clôture

`02_data_intermediate/20/inkind_education.parquet`, avec composantes par niveau,
brut, frais et net; tables d'effectifs, coûts unitaires, incidence, validation
budgétaire et robustesse; figure par niveau et décile. L'étape est close lorsque
la masse brute se réconcilie exactement avec le budget distribuable et que les
différences entre budgets total, courant et privé sont visibles.

### Littérature

CEQ Handbook, chapitre sur l'éducation en nature; Demery (2003), *Analyzing the
Incidence of Public Spending*; Akim et al. (2020). Le mécanisme est une analyse
d'incidence des bénéfices : utilisation observée multipliée par coût unitaire,
non une mesure de la qualité ou du rendement futur de l'éducation.

## Étape 22 — Transferts en nature de santé

**Module exécuté :** `05_scripts_R/21_inkind_health.R`
**Identité :** construire `H` dans le revenu final.

### Données

Enquête : épisodes et consultations `s03q01`, `s03q05`, `s03q07`, `s03q12`;
hospitalisations `s03q19`, `s03q20`, `s03q23`; paiements `s03q13` à
`s03q18c`, `s03q24` et frais connexes; âge, sexe, région, milieu et niveau de vie. Les établissements publics correspondent aux codes 1 à 6; les
codes privés, pharmacie et tradipraticien restent hors bénéfice public sauf
financement public explicitement observé.

Externes : comptes de la santé ou dépenses exécutées 2021 du MSHP-CMU, ventilés
entre soins primaires/ambulatoires, hôpitaux et administration; activité
administrative par type de structure; dépenses financées par partenaires et
assurance publique selon le périmètre retenu. Les paramètres vont dans
`params_health_2021.xlsx` avec une matrice de comparabilité.

### Mécanisme central

Le rappel court rend une allocation pure à l'usage très volatile. Le scénario central est donc hybride, conformément aux variantes décrites dans le manuel CEQ. Pour les soins ambulatoires, chaque personne reçoit la dépense publique moyenne attendue de son groupe d'âge, de sexe et de milieu. Cette expression décrit une moyenne statistique de recours et de coût; elle ne suppose ni contrat d'assurance ni couverture CMU. Les déclarations d'assurance maladie de l'EHCVM, trop incomplètes, ne déterminent jamais le bénéfice central :

1. dépense publique moyenne attendue pour les soins
   ambulatoires, attribuée à des cellules âge-sexe-région ou âge-sexe-milieu
   (regroupées si les effectifs sont insuffisants) à partir de la probabilité
   pondérée de recours public et du coût unitaire, sans utiliser le statut
   d'assurance déclaré;
2. allocation à l'usage pour les hospitalisations observées sur douze mois,
   nombre de séjours multiplié par le coût public unitaire;
3. dépenses générales réparties au prorata des bénéfices ambulatoires et
   hospitaliers, avec une variante uniforme par tête;
4. bénéfices brut et net des paiements directs aux structures publiques,
   agrégés au ménage.

### Robustesse et validations

- usage pur pour l'ambulatoire contre valeur attendue centrale;
- un bénéficiaire par épisode contre nombre de contacts annualisé;
- activité administrative contre activité pondérée de l'enquête comme
  dénominateur du coût unitaire;
- ventilation primaire/hôpital observée contre clés basse et haute lorsque les
  comptes sont insuffisamment détaillés;
- dépenses courantes contre total avec investissement; inclusion/exclusion des
  financements extérieurs;
- brut contre net des frais; frais individuels contre frais moyens par
  type-décile;
- contrôles de masses, taux de recours, cellules de valeur attendue, valeurs
  extrêmes, concentration et bootstrap Rao--Wu.

### Sorties et critère de clôture

`02_data_intermediate/21/inkind_health.parquet` avec ambulatoire,
hospitalisation, administration, brut, frais et net; tables de recours, coûts,
incidence, validation et sensibilités; figure par décile. L'étape est close
quand la dépense distribuable est entièrement réconciliée et que le résultat ne
dépend pas d'une cellule de valeur attendue à trop faible effectif.

### Littérature

CEQ Handbook, chapitre sur les méthodes de valorisation des transferts en
nature; Demery (2003); guides de la Banque mondiale sur l'équité en santé. La
valeur au coût de production mesure l'incidence budgétaire, non l'état de santé,
la qualité des soins ou le consentement à payer.

## Étape 23 — Assemblage des concepts de revenu

**Module exécuté :** `05_scripts_R/22_income_concepts.R`.

### Données et mécanisme

Joindre sur `hhid` les sorties des étapes 3, 14, 17, 18, 19, 20, 21 et 22 sans
recalculer les instruments. Construire en parallèle :

- PDI central, pensions comme revenu différé;
- PGT robuste : les pensions sont ajoutées aux paiements publics reçus et les cotisations retraite aux prélèvements obligatoires;
- `I = TVA_directe + TVA_enchâssée + accises + douanes + autres taxes
  d'utilité documentées`;
- `S = eau + électricité + carburants`, puis `Y_C = Y_D - I + S`;
- `Y_F = Y_C + E_net + H_net + O`, avec `O=0` tant qu'aucun autre transfert en
  nature monétairement identifiable n'est implémenté.

Les identités sont vérifiées ménage par ménage et en agrégat. Les revenus
négatifs restent dans les masses comptables; les indicateurs qui exigent des
valeurs non négatives publient le plancher et la part de population concernée.

### Robustesse, sorties et clôture

Comparer PDI/PGT, brut/net des frais, utilités avec/sans carburant et matrices
TRE/ICIO. Produire `02_data_intermediate/22/all_income_concepts.parquet`, une
table des sept concepts, une matrice d'identités, une réconciliation
micro--macro et les indicateurs Gini/FGT. Clôture : unicité de `hhid`, aucune
valeur manquante créée par jointure, erreur d'identité inférieure à `1e-6` FCFA
et scénario de chaque colonne traçable.

### Littérature

CEQ Handbook pour les définitions PDI/PGT et la construction des concepts;
Akim et al. (2020) pour la comparaison régionale.

## Étape 24 — Progressivité, contributions marginales et Shapley

**Module exécuté :** `05_scripts_R/23_marginal_contribution.R`.

### Mécanisme

Calculer par instrument la masse, le taux effectif et la concentration. Le
Kakwani `C_taxe - Gini(revenu pré-fiscal)` est réservé aux prélèvements; pour les
transferts, publier le coefficient de concentration et l'indice de ciblage
`Gini(revenu) - C_bénéfice`. Calculer les Reynolds--Smolensky aux transitions
CEQ complètes.

La contribution marginale « avec/sans » est publiée parce qu'elle est lisible,
mais elle dépend du point de comparaison. La décomposition principale de la
variation de Gini utilise la valeur de Shapley, moyenne de toutes les positions
possibles de chaque instrument. Elle est exacte pour des groupes d'instruments
(prélèvements directs, transferts directs, impôts indirects, subventions,
éducation, santé); au niveau détaillé, elle est exacte jusqu'à 12 instruments et
approchée par permutations au-delà, avec erreur Monte-Carlo publiée.

### Robustesse, sorties et clôture

PDI/PGT, classement fixe contre reclassement endogène, niveau groupe contre
instrument, Gini contre FGT0/FGT1. Bootstrap des contributions marginales et,
si le temps de calcul le permet, Shapley groupé sur 200 réplications. Sorties :
tables de concentration/progressivité, contributions avec/sans, Shapley et une
figure. Clôture : somme des Shapley égale à la variation totale à la tolérance
numérique près.

### Littérature

Kakwani (1977), Reynolds et Smolensky (1977), CEQ Handbook et Shorrocks (2013),
« Decomposition Procedures for Distributional Analysis: A Unified Framework
Based on the Shapley Value ».

## Étape 25 — Appauvrissement fiscal et gains aux pauvres

**Module exécuté :** `05_scripts_R/24_fiscal_impoverishment.R`.

### Mécanisme

Comparer le revenu pré-fiscal monétaire et le revenu consommable monétaire. Les
prestations d'éducation et de santé ne sont pas ajoutées à l'argent disponible
pour franchir le seuil de pauvreté. Pour chaque personne, calculer la perte sous
le seuil causée par le système et le gain sous le seuil, puis agréger : part de
population appauvrie, montant d'appauvrissement, part gagnante pauvre et montant
des gains. Publier simultanément la variation anonyme des FGT et les mesures
non anonymes de Higgins--Lustig : une baisse de la pauvreté moyenne peut masquer
des ménages pauvres rendus plus pauvres.

### Robustesse, sorties et clôture

PDI/PGT; seuil national et lignes internationales converties en prix 2021;
revenu par tête et équivalent-adulte; avec/sans effets indirects; décomposition
séquentielle et Shapley des pertes sous le seuil. Bootstrap Rao--Wu à 500
réplications. Sorties : tables FI/FGP, profils par décile et statut initial,
dominance sur une plage de seuils, figure. Clôture : la différence de pauvreté
se réconcilie algébriquement avec gains et pertes sous le seuil.

### Littérature

Higgins et Lustig (2016), *Journal of Development Economics*, DOI
`10.1016/j.jdeveco.2016.04.001`, et CEQ Handbook.

## Étape 26 — Tables CEQ, rapport et manifeste de réplication

**Module exécuté :** `05_scripts_R/25_ceq_report_tables.R`.

### Mécanisme et données

Cette étape n'introduit aucun nouveau paramètre économique. Elle lit les sorties
validées des étapes précédentes et produit : concepts de revenu par décile,
incidence des bénéficiaires et des bénéfices, taux effectifs, concentration,
Gini, FGT, Kakwani, Reynolds--Smolensky, FI/FGP, réconciliation micro--macro et
scénarios de réforme. Chaque onglet porte scénario, unité, déflateur, source et
date de construction.

### Robustesse, sorties et clôture

Comparer automatiquement les totaux du classeur aux tables sources, vérifier
les sommes à 100 %, les identités CEQ, les labels PDI/PGT et les unités. Exporter
`07_reports/tables/25/CEQ_CIV_2021_master.xlsx`, un dictionnaire, un manifeste
JSON/CSV (hash Git, version R, paramètres, fichiers sources) et les tables LaTeX
du working paper. La clôture exige une exécution `lance_pipeline(1,26)` depuis
les entrées documentées et une compilation du manuscrit sans référence
indéfinie.

### Littérature

Gabarits et tables standard du CEQ Institute; CEQ Handbook; Akim et al. (2020)
pour la comparabilité régionale.

## Validation effectivement réalisée

1. Les paramètres externes sont archivés avec année, unité, champ et source.
2. Les étapes 20 à 22 réconcilient exactement la masse distribuable retenue.
3. L'étape 23 vérifie toutes les identités au ménage à moins de 0,000001 FCFA.
4. L'étape 24 vérifie que la somme des valeurs de Shapley retrouve exactement
   la variation totale du Gini.
5. L'étape 25 réconcilie algébriquement gains et pertes sous le seuil avec la
   variation de la profondeur de pauvreté.
6. L'étape 26 rassemble les tables, les variables et le calage PMT, les
   contrôles ANStat et le manifeste de réplication.
7. Le document de travail a été enrichi de la méthode, des résultats, des
   robustesses, des limites et des références correspondantes.
## Références et sources de base

- Lustig, N. (dir.), 2022, *Commitment to Equity Handbook*, 2e éd. :
  <https://commitmentoequity.org/wp-content/uploads/2023/04/CEQ-Handbook-Volume-1-.pdf>.
- Akim, A.-M., Ben Jelloul, M., Czajka, L. et Robilliard, A.-S., 2020,
  *Collect More, Spend Better?* :
  <https://horizon.documentation.ird.fr/exl-doc/pleins_textes/2022-08/010085651.pdf>.
- Demery, L., 2003, « Analyzing the Incidence of Public Spending », Banque
  mondiale : <https://documents1.worldbank.org/curated/en/973661468739790876/pdf/multi0page.pdf>.
- Shorrocks, A. F., 2013, *Journal of Economic Inequality*, DOI
  `10.1007/s10888-011-9214-z`.
- Higgins, S. et Lustig, N., 2016, *Journal of Development Economics*, DOI
  `10.1016/j.jdeveco.2016.04.001`.
- DGBF, Budget citoyen 2021 et documents de loi de règlement :
  <https://www.dgbf.ci/budget-citoyen/> et
  <https://budget.gouv.ci/budget-publications.html>.
- ANARE-CI, tarifs de l'électricité et rapport d'activité 2021 :
  <https://anare.ci/le-marche/prix-de-lelectricite/> et
  <https://anare.ci/documents/rapports-dactivites/>.


- ANStat, *Comptes nationaux annuels définitifs 2023* :
  <https://www.anstat.ci/assets/publications/files/CNA_DEFINITIFS_2023.pdf>.
- ANStat, *Annuaire des statistiques économiques 2023* :
  <https://www.anstat.ci/assets/publications/files/File_val_indicateur1744101623.pdf>.
