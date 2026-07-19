# Mémoire partagée — CEQ Côte d'Ivoire 2021

Dernière mise à jour : 19 juillet 2026.

Cette note est le point de reprise du projet. Le working paper et les tables du
pipeline restent les sources de résultat.

## 1. Fichiers à lire en premier

- Papier source : 00_documentation/working_paper/DT_CEQ_CIV2021.tex
- PDF courant : 00_documentation/working_paper/DT_CEQ_CIV2021_v17.pdf
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
14 à 26, ont toutes abouti le 19 juillet 2026. Deux jointures devenues ambiguës
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

## 3. Méthodes stabilisées

### TVA, accises et douane

Le scénario TVA central est S3, où la transmission effective varie par fonction
de consommation et décile. S2 et la transmission intégrale sont des
robustesses. S3 est une hypothèse exogène : sa matrice de 15 fonctions par dix
déciles et son profil implicite sont publiés, mais aucun de ses paramètres n'est
estimé ou calé sur une cible ivoirienne. La TVA non déductible est propagée par
un modèle de prix de Leontief fondé sur le TRE ivoirien 2023; le TRE constant et
ICIO 2020 sont des robustesses. Une sensibilité juridique binaire fait passer
la TVA incorporée de 214,4 à 22,3 milliards de FCFA. Cet écart mesure la
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
les 720 ordres. Cinquante réplications Rao--Wu encadrent la décomposition
complète; les principaux indicateurs utilisent 500 réplications.

L'appauvrissement fiscal compare le revenu primaire monétaire au revenu
consommable. L'éducation et la santé ne sont pas traitées comme de l'argent
permettant de franchir le seuil. Les pertes et gains sous le seuil réconcilient
exactement la variation de profondeur de pauvreté.

## 4. Résultats centraux

- TVA directe et non déductible : 907,3 milliards de FCFA.
- Accises : 67,9 milliards; droits de douane : 185,1 milliards.
- Paiements publics directs : 125,798 milliards.
- Pensions observées : 252,603 milliards.
- Réductions de prix : 25,15 milliards.
- Éducation brute : 1 354,87 milliards; nette : 1 301,62 milliards.
- Santé brute : 108,53 milliards; nette : 81,85 milliards.
- Gini primaire : 0,3414; disponible : 0,3336; consommable : 0,3248;
  final : 0,3168.
- Pauvreté primaire : 37,70 %; consommable : 42,01 %; finale : 33,90 %.
- Nouveaux pauvres monétaires : 4,34 %.
- Pertes sous le seuil : 142,73 milliards; gains : 9,30 milliards.
- Parts Shapley de la réduction du Gini : impôts indirects 34,1 %,
  prélèvements directs 28,6 %, éducation 27,7 %, santé 7,3 %, paiements
  publics directs 2,9 %; les réductions de prix ont une petite contribution
  négative.

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
- Compilation : BibTeX et trois passes PDFLaTeX, aucune citation ni référence
  indéfinie, aucun dépassement de marge signalé.
- Prévol de réplication : 40 contrôles réussis, aucun avertissement ni échec.
- Vérification des sorties : 32 contrôles réussis, aucun échec; les 34 tableaux
  et figures du papier sont reliés à leur script et à leur fichier de sortie.
- Reprise intégrale du 19 juillet 2026 : 350,4 secondes, journal
  `replication_package/output/logs/full_run_20260719_220317.log`, sans
  avertissement logiciel. L'audit de 15 affirmations numériques principales
  conclut à 7 PASS, 8 EXPLAINED par le seul arrondi d'affichage, 0 FAIL et
  0 UNMATCHED.
- PDF figé : DT_CEQ_CIV2021_v17.pdf (52 pages, résumé de 146 mots).

## 7. Limites et prolongements

La structure CEQ n'a plus de module manquant. Les prolongements concernent la
qualité des sources : propagation des droits de douane et des accises
carburant, prix de parité carburant 2021, référence administrative AT/MP,
comptes de santé plus détaillés, appariement du registre PSSN et extension des
impôts aux revenus indépendants, fonciers et mobiliers.

Le working tree est très modifié et contient des travaux de l'utilisateur. Ne
restaurer ni supprimer aucun fichier sans vérifier précisément son origine.