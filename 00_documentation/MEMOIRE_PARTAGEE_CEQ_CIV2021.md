# Mémoire partagée — CEQ Côte d'Ivoire 2021

Dernière mise à jour : 13 septembre 2026.

## 0 bis. Session du 13 septembre 2026 : recadrage du papier (non committé)

Le round 5 (référé JAE) a été annulé ; la référence est HEAD `5713d98`. Le cadrage
retenu est : un modèle de microsimulation fiscale réutilisable pour la Côte
d'Ivoire, dont la pertinence justifie quatre adaptations (ancrage sur la
consommation, part taxée par fonction et décile bornée par l'offre, TVA non
déductible par Leontief, PSSN par score), avec pour première application
l'incidence du système de 2021 et pour seconde les chocs de TVA (0→9 % ;
intrants avicoles, mesure réelle de la loi de finances 2026 et de l'ordonnance
n° 2026-03 du 7 janvier 2026 à 9 %). Réécrits : introduction, §2 (système
fiscal et social, figure d'architecture), §3 nouvelle (microsimulation et
informalité), §4 (données et paramètres, tableau fusionné), §5 réorganisée en
huit sous-sections avec 5.8 « Simuler un choc » ; lexique en annexe A. Chiffres
inchangés, sauf la ligne juridique du tableau de robustesse I/O (ΔP0 = 2,42).

Prochaine session : revue minutieuse, étape par étape, de la méthodologie
avant les résultats ; questions d'inflation pour les chocs et pour l'incidence
sous CGI 2025 et 2026 (§6 bis) ; puis recalcul de l'avicole à 9 %.

Cette note est le point de reprise du projet. Le working paper et les tables du
pipeline restent les sources de résultat.

## 0. Ce qui a changé en v22

La version v22 (61 pages) ajoute trois extensions analytiques sans modifier
aucun résultat central. Les chiffres de v21 sont reproduits à l'identique par la
reprise intégrale du 10 août 2026 (765,6 secondes).

1. **Symétrie inégalité / pauvreté.** La décomposition de Shapley, jusque-là
   réservée au Gini, est rejouée sur FGT0 et FGT1 (étape 24, tables 23_07 à
   23_09). L'éducation explique +7,09 points de réduction de la pauvreté, les
   impôts indirects −4,23 points. Ce résultat est nouveau et il retourne la
   hiérarchie des instruments par rapport à la lecture en Gini.
2. **Reclassement et efficacité.** La décomposition d'Atkinson-Plotnick (table
   23_10) montre que 21,8 % de l'effet vertical du système est absorbé par du
   reclassement, et 41,6 % pour la seule éducation. Les indicateurs d'efficacité
   d'Enami (table 23_11) rapportent chaque contribution au budget engagé.
3. **Ancrage ivoirien du profil S3** (`utils/informality_anchor.R`, tables 06_04
   et 06_05). Le module 10 de l'EHCVM borne par le haut la part des achats
   taxable; S3 respecte cette borne dans les sept fonctions exploitables. Le
   scénario S4, qui place α à la borne, remplace la borne haute théorique de S1.
   Les valeurs unitaires du module 7B contredisent en revanche l'ampleur de la
   pente alimentaire de S3. Ces deux résultats sont publiés en annexe~E.
4. **Validation croisée du PMT** (table 18_07) : l'optimisme dû à l'estimation
   dans l'échantillon ne dépasse pas 1,7 point de part de bénéficiaires pauvres.
5. Le tableau central porte désormais des intervalles de sondage (table 22_06),
   les macros de chiffres de tête sont réellement injectées dans le manuscrit et
   les décomptes d'exhibits sont calculés au lieu d'être écrits en dur.

## 1. Fichiers à lire en premier

- Papier source : 00_documentation/working_paper/DT_CEQ_CIV2021.tex
- PDF courant : 00_documentation/working_paper/DT_CEQ_CIV2021_v22.pdf
- Feuille de route achevée : 00_documentation/CEQ_ROADMAP.md
- Rapport méthodologique des étapes 20 à 26 :
  00_documentation/PLAN_ETAPES20_26_FINALISATION_CEQ.md
- Méthode de l'étape 19 :
  00_documentation/PLAN_ETAPE19_TRANSFERTS_PENSIONS.md
- Orchestrateur : 05_scripts_R/00_master.R
- Classeur final : 07_reports/tables/25/CEQ_CIV_2021_master.xlsx
- Manifeste : 07_reports/tables/25/CEQ_CIV_2021_manifest.csv

## 2. Position du modèle

Le pipeline comporte 26 étapes. Il mesure TVA directe et non déductible,
accises, droits de douane, impôts directs, cotisations, pensions, paiements
publics, filets sociaux, réductions de prix, éducation et santé. Les sept
concepts CEQ sont produits jusqu'au revenu final sous deux conventions de
pension. Les identités ferment ménage par ménage à moins de 0,000001 FCFA.

La chaîne a été rejouée depuis les données préparées : les étapes 1 à 13, puis
14 à 26, ont de nouveau toutes abouti le 23 juillet 2026. Deux jointures devenues ambiguës
dans une reprise entièrement fraîche ont été corrigées aux étapes 7 et 13;
elles ne modifient aucun choix économique. Une révision éditoriale a recentré la
conclusion sur les résultats économiques et supprimé du texte principal les
numéros de questions, modules, postes, tables et fichiers internes; ces détails
restent uniquement dans l'annexe de réplication. Le papier v14 (49 pages, sans
citation ni renvoi indéfini, zéro overfull) corrige ensuite : neuf mots corrompus
par un ancien remplacement global « item » → « produit » (« traproduitent »,
« imparfaproduitent », « explicproduitent »); le texte périmé de l'introduction
qui présentait encore le revenu final comme incomplet, ainsi que la feuille de
route; les formulations narratives liées aux versions (« désormais »,
« maintenant », « la version actuelle »); et trois fautes d'accord.

Le papier v15 (47 pages) ajoute une révision de fond de la rédaction : résumé
de 142 mots, introduction organisée autour de la tension entre inégalité et
pauvreté, lexique accessible, définitions de PDI, PGT et de la TVA enchâssée,
présentation explicite du PMT et du calage, conclusion sans tableau ni figure,
et bibliographie corrigée. Les contrôles éditoriaux, bibliographiques et
numériques sont archivés sous
00_documentation/working_paper/quality_reports et Diebolt/round3.

Le papier v16 (48 pages) regroupe les limites en cinq thèmes dans le texte
principal. Les dix réserves techniques sont conservées dans une annexe dédiée
qui précise, pour chacune, le biais possible, le contrôle existant et les
données nécessaires. La section commence sur une nouvelle page afin de ne pas
être interrompue par les flottants des simulations de réforme.

Le papier v17 (52 pages) traite les neuf remarques Refine.ink du 19 juillet
2026. Il publie la matrice S3 exacte, sépare le taux légal, le droit à déduction
et la collecte à la vente finale, ajoute une sensibilité juridique, rend les
scénarios d'impôts directs comparables, précise le statut des non-réponses,
distingue nettement le PMT central de la robustesse fondée sur les déclarations,
harmonise les unités des identités CEQ et ajoute un protocole de réplication
utilisable aussi bien manuellement que par un agent.

Le papier v18 (52 pages) ouvre l'introduction sur les effets distributifs
contrastés des impôts et des dépenses publiques, sans formuler d'appréciation
générale sur l'action gouvernementale. Le README de rewrite-r décrit désormais
la chaîne complète en 26 étapes, les sources d'enquête et administratives, la
procédure PMT et son calage, l'absence temporaire des données dans Git et le
protocole de réplication pour un économiste ou un agent.
Le papier v19 (53 pages) intègre les 25 remarques externes du 20 juillet 2026.
Il raccourcit l'introduction, précise que les passages sous le seuil sont à la
baisse, nomme S1/S2/S3, documente les valeurs d'usage exclues de l'assiette,
corrige la cascade multiplicative de TVA, la convention Reynolds--Smolensky et
la base IGR, ajoute les robustesses S3 +/-20 %, collecte amont 75/50 %, postes
non raccordés, électricité, santé, éducation, recyclage PMT/coûts, et archive la
réponse point par point dans `00_documentation/working_paper/Diebolt/round4/`.

Le papier v20 (53 pages) est la version de clôture de la session. Il conserve
les résultats v19, mais polit le résumé, le premier paragraphe de l'introduction,
la limite sur S3 et le paragraphe de conclusion sur la réforme à 9 %. Le PDF
compile sans erreur LaTeX, citation ou référence indéfinie; le prévol donne 40
PASS et la vérification finale 32 PASS.

Le papier v21 (54 pages) formalise le plan de sondage dans les régressions du
taux effectif de TVA. Les modèles `svyglm` utilisent `hhweight`, 66 strates et
les grappes EHCVM. Les coefficients ponctuels restent stables; l'inférence de
sondage ne retient plus le terme quadratique S3 (`p = 0,157`). Le texte présente
ces résultats comme des corrélations descriptives et maintient S3 comme
hypothèse centrale, S2 comme robustesse et S1 comme borne haute.

## 3. Méthodes stabilisées

### TVA, accises et douane

Le scénario TVA central est S3, où la transmission effective varie par fonction
de consommation et décile. S1, la transmission intégrale, et S2, la variante par milieu, sont des robustesses. S3 est une hypothèse exogène : sa matrice de 15 fonctions par dix
déciles et son profil implicite sont publiés, mais aucun de ses paramètres n'est
estimé ou calé sur une cible ivoirienne. La TVA non déductible est propagée par
un modèle de prix de Leontief fondé sur le TRE ivoirien 2023; le TRE constant et
ICIO 2020 sont des robustesses. Une sensibilité juridique binaire fait passer
la TVA incorporée de 214,3 à 22,3 milliards de FCFA. Cet écart mesure la
fragilité au proxy de droit à déduction; 22,3 milliards n'est pas une nouvelle
valeur centrale. Les accises et droits de douane suivent la cascade droits de
douane, accise, puis TVA, avec parts importées du TRE.

### Pensions et paiements publics

PDI est central : la pension contributive est un revenu différé déjà acquis et
la cotisation retraite une épargne obligatoire. PGT est la robustesse : la
pension devient un paiement public et la cotisation retraite un prélèvement.
Les deux conventions retrouvent exactement le même revenu disponible. Les
pensions alimentaires et envois de fonds sont des transferts entre ménages et
ne sont pas des paiements publics.

Les scénarios d'impôts directs utilisent tous la même rémunération annualisée et
ne diffèrent que par le critère d'assujettissement. Une non-réponse au bulletin,
à la cotisation ou à tout autre marqueur ne vaut jamais réponse positive et ne
constitue jamais une preuve d'emploi formel. Le diagnostic de non-réponse
conserve exactement la sélection centrale et publie séparément les effectifs
concernés; il ne crée aucun assujetti.

Le PSSN est imputé par un test indirect de niveau de vie, PMT. Une régression
linéaire pondérée explique le logarithme du revenu disponible par personne à
partir des variables suivantes : logarithme de la taille du ménage; milieu;
région; âge du chef et son carré; sexe, éducation et statut matrimonial du
chef; nombres de membres de 0 à 5 ans, 6 à 10 ans, 11 à 15 ans et 65 ans ou
plus; nombre de personnes avec handicap déclaré. Les caractéristiques du chef
et la composition viennent du fichier individus; taille, milieu et région du
fichier ménage.

Les ménages sont classés par niveau de vie prédit, avec identifiant ménage pour
départager les égalités. Deux coupures retiennent 177 142 ménages pondérés en
cohorte annuelle et 14 625 en cohorte partielle, soit 191 767 au total. Le
barème vaut 36 000 FCFA par trimestre, quatre paiements pour la première cohorte
et trois pour la seconde. Un facteur commun de 1,000739 ramène la masse à
27,108 milliards. Le rang et les déciles ne sont pas modifiés par ce calage.
Les déclarations du module 15 ne déterminent jamais la sélection centrale :
24 989 ménages pondérés déclarent le programme monétaire et 972 chevauchent la
sélection PMT. Dans la robustesse « déclarations d'abord », ces ménages sont
retenus en priorité, puis la cible est complétée par ordre de PMT. Cette variante
retient 192 544 ménages pondérés et ramène la part des bénéficiaires pauvres de
85,9 % à 79,5 %, à masse budgétaire inchangée.

### Réductions de prix

L'électricité répartit 8,69 milliards d'aide d'exploitation ANARE selon les
quantités estimées à partir des factures et des tarifs. L'eau inverse le barème
par tranches et valorise la différence entre tarif social et tarif domestique,
soit 16,46 milliards. Le soutien carburant central vaut zéro faute de prix de
parité 2021 suffisamment comparable; une borne haute est isolée.

### Éducation et santé

L'éducation attribue à chaque élève du public la dépense exécutée moyenne de son
niveau, puis retranche les frais scolaires directement payés pour le bénéfice
net. La masse brute se réconcilie exactement par niveau.

La santé n'utilise aucune déclaration d'assurance maladie des questions 32 à
37. Les consultations publiques à rappel court sont lissées par une dépense
publique moyenne attendue dans des cellules âge, sexe et milieu; une moyenne
âge-sexe nationale remplace les cellules de moins de 30 observations. Les
hospitalisations utilisent les séjours publics observés sur douze mois. Le
résultat central est net des paiements directs aux structures publiques.

### Distribution, Shapley et pauvreté

Le Gini est décomposé exactement entre six groupes sur les 64 sous-ensembles et
les 720 ordres. Cinq cents réplications Rao--Wu encadrent la décomposition complète; un classeur de convergence compare 50, 100, 250 et 500 réplications.

L'appauvrissement fiscal compare le revenu primaire monétaire au revenu
consommable. L'éducation et la santé ne sont pas traitées comme de l'argent
permettant de franchir le seuil. Les pertes et gains sous le seuil réconcilient
exactement la variation de profondeur de pauvreté.

## 4. Résultats centraux

- TVA finale directe : 697,2 milliards; TVA enchâssée : 214,3 milliards;
  TVA totale ménages : 911,6 milliards de FCFA.
- Accises : 67,9 milliards; droits de douane : 185,1 milliards.
- Paiements publics directs : 125,798 milliards.
- Pensions observées : 252,603 milliards.
- Réductions de prix : 25,15 milliards.
- Éducation brute : 1 354,87 milliards; nette : 1 301,62 milliards.
- Santé brute : 108,53 milliards; nette : 81,85 milliards.
- Gini primaire : 0,3409; disponible : 0,3336; consommable : 0,3247;
  final : 0,3167.
- Pauvreté primaire : 37,72 %; consommable : 42,04 %; finale : 33,92 %.
- Nouveaux pauvres monétaires : 4,35 %.
- Pertes sous le seuil : 142,84 milliards; gains : 9,35 milliards.
- Parts Shapley de la réduction du Gini : impôts indirects 35,1 %,
  prélèvements directs 26,9 %, éducation 28,2 %, santé 7,5 %, paiements
  publics directs 3,0 %; les réductions de prix ont une petite contribution
  négative (-0,7 %).

## 5. Sources externes et contrôle ANStat
Les fichiers officiels sont archivés sous
01_data_sources/reference_external. Les principales références sont :

- CEQ Handbook, Lustig, dir., 2022;
- Akim, Ben Jelloul, Czajka et Robilliard, 2020;
- Demery, 2003, pour l'incidence des dépenses publiques;
- Shorrocks, 2013, pour la décomposition de Shapley;
- Higgins et Lustig, 2016, pour l'appauvrissement fiscal;
- rapports budgétaires et loi de règlement 2021;
- rapport ANARE-CI 2021;
- ANStat, Comptes nationaux annuels définitifs 2023;
- ANStat, Annuaire des statistiques économiques 2023.

Pour 2021, les contrôles retiennent notamment 26 754 milliards de consommation
finale des ménages, 3 074 milliards d'impôts nets sur les produits,
2 971 milliards de valeur ajoutée de l'enseignement et 743 milliards de santé
et action sociale. La consommation des ménages 2023 vaut 34 059 milliards dans
les comptes définitifs, contre 32 721 dans le millésime antérieur de l'annuaire.
Les agrégats ANStat servent à expliquer les écarts de périmètre, jamais à forcer
les résultats ménages.

## 6. Sorties et vérifications

- Étapes 19 à 26 : exécution intégrée réussie.
- Identités CEQ : erreur maximale inférieure à 0,000001 FCFA.
- Shapley : somme égale à la variation totale.
- Appauvrissement : réconciliation exacte gains/pertes/profondeur.
- Graphiques nouveaux : bleu, vert, orange, rouge et gris; aucun violet.
- Compilation : BibTeX et passes XeLaTeX, aucune citation ni référence
  indéfinie, aucun dépassement de marge signalé.
- Prévol de réplication : 41 contrôles réussis, aucun avertissement ni échec.
- Vérification des sorties : 32 contrôles réussis, aucun échec; les 33 tableaux
  et figures du papier sont reliés à leur script et à leur fichier de sortie.
- Reprise intégrale du 23 juillet 2026 : 452,17 secondes, journal
  `replication_package/output/logs/full_run_20260723_030556.log`. L'audit de
  30 affirmations numériques principales conclut à 19 PASS, 11 EXPLAINED par
  le seul arrondi d'affichage, 0 FAIL et 0 UNMATCHED.
- PDF figé : DT_CEQ_CIV2021_v21.pdf (54 pages, résumé de 142 mots).

## 6 bis. Revalorisation des prix 2021 → 2025 (13 septembre 2026)

Pour appliquer les CGI 2025 et 2026 aux données EHCVM 2021, les dépenses nominales
sont revalorisées poste par poste avec un facteur annuel par fonction COICOP,
calculé à partir des bulletins IHPC de l'ANStat (moyenne 2025 en base 2023 sur
moyenne 2021 raccordée ; fichiers `01_data_sources/reference_external/ANSTAT_IHPC_*`,
script `05_scripts_R/utils/ihpc_facteurs_coicop.R`). Les facteurs vont de 1,018
(loisirs) à 1,226 (alimentation), pour 1,137 en moyenne. Un facteur global est
exclu : les fonctions n'évoluent pas ensemble.

La revalorisation se fait à quantités fixes, sans substitution face aux prix
relatifs : ce n'est pas une limite à corriger mais une propriété du cadre, le
modèle étant statique par construction (incidence de premier tour, comportements
constants). Les questions de production dépassent le champ CEQ, les questions
d'emploi relèvent de modèles de type INES, et les réactions des ménages relèvent
d'un modèle comportemental, qui est un autre objet. À corriger avant publication
de ce volet : (i) la moyenne annuelle ignore le calendrier de collecte de l'EHCVM
(2021–2022) et la date d'entrée en vigueur des mesures ; (ii) pour 2026 seuls les
mois de janvier à août sont publiés ; (iii) l'ancienne division 12 est raccordée
aux divisions 12 et 13 de la COICOP 2018 sans distinction.

## 6 ter. Améliorations potentielles, hors tâches centrales (13 septembre 2026)

Notées pour mémoire, sans engagement dans le papier courant :

- Scénario exogène de formalisation : faire passer la part des salariés couverts
  par un tiers déclarant (42,7 % au centre) à une valeur cible, et mesurer recettes,
  cotisations et incidence. Variante de règle statique sur population observée,
  cohérente avec le cadre ; pas une prédiction de l'emploi.
- Chaînage descendant à un modèle d'équilibre général calculable sur une matrice
  de comptabilité sociale ivoirienne, pour les chocs assez gros pour déplacer les
  prix relatifs de toute l'économie. Second projet, distinct du modèle statique.

## 7. Limites et prolongements

La structure CEQ n'a plus de module manquant. Les prolongements concernent la
qualité des sources : propagation des droits de douane et des accises
carburant, prix de parité carburant 2021, référence administrative AT/MP,
comptes de santé plus détaillés, appariement du registre PSSN et extension des
impôts aux revenus indépendants, fonciers et mobiliers.

Le working tree est très modifié et contient des travaux de l'utilisateur. Ne
restaurer ni supprimer aucun fichier sans vérifier précisément son origine.