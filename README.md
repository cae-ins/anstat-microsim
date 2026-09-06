# Fiscalité, informalité, transferts et pauvreté en Côte d’Ivoire

Microsimulation d’incidence fiscale fondée sur l’EHCVM 2021 et le cadre
*Commitment to Equity* (CEQ).

**Branche R :** <code>rewrite-r</code>

**État :** chaîne complète en 26 étapes, du revenu primaire au revenu final
**Document de travail :**
[PDF courant](00_documentation/working_paper/DT_CEQ_CIV2021.pdf) ·
[source LaTeX](00_documentation/working_paper/DT_CEQ_CIV2021.tex)

## Pourquoi ce projet ?

Le projet mesure comment les impôts, les cotisations, les transferts monétaires,
les réductions publiques de prix et les services publics d’éducation et de
santé modifient le niveau de vie des ménages en Côte d’Ivoire.

L’analyse suit chaque ménage de l’enquête à travers les différents concepts de
revenu du cadre CEQ. Elle permet de répondre à trois questions :

1. qui supporte chaque prélèvement et qui bénéficie de chaque dépense publique ;
2. dans quelle mesure chaque instrument modifie les inégalités et la pauvreté ;
3. quels résultats dépendent des hypothèses retenues sur l’informalité, les
   pensions, le ciblage des filets sociaux ou la transmission des taxes dans les
   prix.

Dans le scénario central, le coefficient de Gini passe de 0,3409 pour le revenu
primaire à 0,3167 pour le revenu final. Le taux de pauvreté monétaire passe
toutefois de 37,72 % au revenu primaire à 42,04 % au revenu consommable. Lorsque
les services publics d’éducation et de santé sont valorisés, l’indicateur
calculé sur le revenu final atteint 33,92 %. Ces résultats et leurs limites sont
interprétés dans le document de travail ; le README décrit surtout comment les
reproduire.

## Ce qui est mesuré

| Domaine | Instruments pris en compte |
|---|---|
| Impôts indirects | TVA facturée sur les achats, TVA enchâssée dans les prix, accises et droits de douane |
| Prélèvements directs | Impôts sur les revenus d’activité, cotisations sociales et cotisation maladie |
| Paiements publics monétaires | Pensions, filet social, bourses, prestations familiales et accidents du travail |
| Réductions publiques de prix | Électricité et eau |
| Services publics en nature | Éducation et santé, nets des paiements directs des ménages |
| Synthèse distributive | Inégalité, progressivité, pauvreté, appauvrissement fiscal et décomposition de Shapley |

La TVA non déductible est la TVA payée sur un intrant qu’une entreprise ne peut
pas récupérer. Lorsqu’elle se transmet d’un fournisseur à l’autre, elle entre
dans le prix payé par le ménage. Il ne s’agit donc pas d’un impôt supplémentaire,
mais d’une composante de coût déjà contenue dans le prix final.

Les pensions sont présentées selon deux conventions CEQ. Dans la convention
centrale PDI (*Pensions as Deferred Income*), une pension contributive est un
revenu différé acquis pendant la vie active. Dans la robustesse PGT (*Pensions
as Government Transfers*), la même pension est classée comme un transfert
public et les cotisations de retraite comme un prélèvement. Le revenu disponible
reste identique sous les deux conventions.

Pour le filet social, le scénario central utilise un score de ciblage PMT
(*Proxy Means Test*). Une régression pondérée prédit le logarithme du niveau de
vie par personne à partir de la taille du ménage, du milieu et de la région de
résidence, de l’âge, du sexe, de l’instruction et de la situation matrimoniale
du chef, puis du nombre de membres dans quatre groupes d’âge et du nombre de
personnes ayant un handicap déclaré. Les ménages sont classés du niveau de vie
prédit le plus faible au plus élevé. La sélection retient une cohorte présente
toute l’année et une cohorte partielle, au plus près des 192 000 ménages visés.
Les versements statutaires sont ensuite multipliés par 1,000739 pour reproduire
la dépense exécutée de 27,108 milliards de FCFA. Ce calage ajuste uniquement la
masse versée : il ne modifie ni le classement du PMT ni les poids d’enquête. Les
ménages déclarant un transfert social dans l’enquête sont utilisés dans une
analyse de robustesse, pas comme sélection centrale.

## Données mobilisées

### Enquête auprès des ménages

Le socle microéconomique est l’EHCVM 2021–2022 pour la Côte d’Ivoire :

- 12 965 ménages ;
- 64 491 personnes ;
- 787 410 lignes de dépenses ;
- modules de consommation, bien-être, emploi, revenus, éducation, santé,
  logement et transferts.

La version publique anonymisée est référencée
<code>CIV_2021_EHCVM-2_v01_M</code>. Elle peut être demandée auprès du
[Centre de données de l’ANStat](https://centredecalcul.anstat.ci/index.php/welcome)
ou du
[catalogue de microdonnées de la Banque mondiale](https://microdata.worldbank.org/index.php/catalog/6273),
sous réserve d’accepter les conditions du producteur.

Les trois fichiers harmonisés placés dans <code>01_data_sources/Dataout/</code>
sont produits par les programmes officiels EHCVM conservés dans
<code>01_data_sources/Programs/</code>. Ils ne doivent pas être remplacés par de
simples renommages des modules bruts. La préparation initiale requiert Stata ;
la microsimulation proprement dite est ensuite exécutée en R.

### Sources administratives et macroéconomiques

Le modèle complète l’enquête avec :

- les barèmes fiscaux et sociaux applicables en 2021 ;
- le Tarif extérieur commun de la CEDEAO et les taux d’accises ;
- les effectifs et budgets exécutés des programmes sociaux ;
- les dépenses publiques d’éducation et de santé ;
- le tableau des ressources et des emplois (TRE) ivoirien de 2023 ;
- les comptes nationaux et annuaires économiques publiés par
  [l’ANStat](https://www.anstat.ci/).

Les agrégats macroéconomiques servent à contrôler les ordres de grandeur et les
différences de périmètre. Ils ne sont pas utilisés pour forcer les résultats des
ménages à reproduire toute l’économie nationale.

### Données non versionnées dans Git

Les microdonnées, les tableaux de comptabilité nationale et les classeurs de
paramètres ne sont pas inclus dans Git. Leur dépôt sur le stockage MinIO du
projet est prévu ultérieurement. En attendant, le reproducteur doit les obtenir
auprès des producteurs autorisés et les placer localement aux chemins exacts du
[manifeste des données](replication_package/data/data_manifest.csv).

Les identifiants et secrets MinIO ne doivent jamais être ajoutés au dépôt.
<code>.env.example</code> documente les variables qui seront utilisées lorsque
la synchronisation sera activée.

## Méthode et organisation des 26 étapes

La branche <code>rewrite-r</code> contient l’implémentation R complète. Les
étapes sont regroupées ainsi :

| Étapes | Contenu |
|---|---|
| 1–3 | préparation de la consommation, correspondance fiscale des produits et calcul de la TVA sur les achats |
| 4–9 | incidence distributive, progressivité, scénarios d’informalité, diagnostics et figures |
| 10–16 | simulations de réforme, pauvreté et transmission de la TVA par les relations entre branches |
| 17–18 | impôts directs, cotisations, accises et droits de douane |
| 19–22 | pensions, filets sociaux, autres paiements publics, réductions de prix, éducation et santé |
| 23–26 | concepts de revenu CEQ, décomposition de Shapley, appauvrissement fiscal et rapport final |

L’orchestrateur se trouve dans
[<code>05_scripts_R/00_master.R</code>](05_scripts_R/00_master.R). La description
détaillée de chaque étape, de ses données et de ses contrôles figure dans
[<code>00_documentation/CEQ_ROADMAP.md</code>](00_documentation/CEQ_ROADMAP.md).

Le scénario central d’informalité, appelé S3, fait varier la transmission
effective de la TVA selon la fonction de consommation et le niveau de vie du
ménage. La transmission intégrale (S1) et une variante par milieu de résidence (S2)
encadrent cette hypothèse. Des contrôles déplacent aussi S3 de 20 %, réduisent
la collecte dans les chaînes amont et imputent la TVA enchâssée aux dépenses
non raccordées au TRE. Ces coefficients sont des hypothèses explicites :
ils ne sont ni estimés sur l’EHCVM ni calés sur une recette administrative.

## Reproduire les résultats

Le protocole détaillé se trouve dans le
[paquet de réplication](replication_package/README.md). Il est conçu pour être
suivi aussi bien par un économiste que par un agent de programmation. Les
instructions destinées aux agents sont dans
[<code>AGENTS.md</code>](AGENTS.md) et
[<code>replication_package/AGENT_RUNBOOK.md</code>](replication_package/AGENT_RUNBOOK.md).

### 1. Obtenir le code

~~~bash
git clone --branch rewrite-r --single-branch https://github.com/cae-ins/anstat-microsim.git
cd anstat-microsim
git rev-parse HEAD
~~~

Conserver le hash affiché avec les résultats afin d’identifier exactement la
version du code utilisée.

### 2. Restaurer l’environnement R

~~~bash
Rscript --vanilla replication_package/code/00_restore_environment.R
~~~

Cette commande restaure les versions enregistrées dans <code>renv.lock</code>.
L’exécution de référence a utilisé R 4.5.3 sous Windows 11 ; les versions
complètes sont archivées dans <code>replication_package/environment/</code>.

### 3. Préparer et contrôler les données

Placer les vingt entrées attendues aux chemins du manifeste, puis lancer :

~~~bash
Rscript --vanilla replication_package/code/00_preflight.R
~~~

Sous PowerShell Windows, si R affiche `Setting LC_COLLATE=(null) failed` au démarrage, fixer d'abord la locale de tri avec `$env:LC_COLLATE='C'`. Ce réglage évite un avertissement de démarrage et ne change pas les résultats.

Le rapport
<code>replication_package/output/preflight_report.csv</code> ne doit contenir
aucun échec. Le pré-contrôle vérifie notamment les chemins, tailles, empreintes,
paquets, droits d’écriture et espace disque.

### 4. Exécuter toute la chaîne

~~~bash
Rscript --vanilla replication_package/code/00_run_all.R
~~~

Ce programme prépare les matrices du TRE si nécessaire, exécute les 26 étapes,
conserve un journal horodaté et lance la vérification finale.

Pour contrôler des sorties déjà calculées sans relancer toute la chaîne :

~~~bash
Rscript --vanilla replication_package/code/01_verify_outputs.R
~~~

La dernière reprise complète a produit 41 contrôles de prévol et 32 contrôles
finaux réussis, sans échec. Elle a aussi vérifié la correspondance des 33
tableaux et figures du papier avec leurs scripts et leurs fichiers de sortie.

## Principales sorties

- document de travail :
  <code>00_documentation/working_paper/DT_CEQ_CIV2021.pdf</code> ;
- classeur final :
  <code>07_reports/tables/25/CEQ_CIV_2021_master.xlsx</code> ;
- manifeste des résultats :
  <code>07_reports/tables/25/CEQ_CIV_2021_manifest.csv</code> ;
- tableaux intermédiaires : <code>07_reports/tables/</code> ;
- figures : <code>07_reports/figures/</code> ;
- audit des affirmations numériques :
  <code>00_documentation/working_paper/quality_reports/reproducibility_audit_DT_CEQ_CIV2021.md</code> ;
- correspondance tableau/figure–script :
  <code>replication_package/exhibit_map.csv</code>.

## Structure du dépôt

~~~text
00_documentation/       papier, méthode, feuille de route et rapports de qualité
01_data_sources/        données et paramètres locaux non versionnés
02_data_intermediate/   données de travail au format Parquet
05_scripts_R/           pipeline R et fonctions partagées
07_reports/             tableaux et figures produits
08_lit_review/          références et notes de lecture
replication_package/    protocole, manifeste et contrôles de réplication
~~~

## Limites à garder en tête

- la consommation par tête sert de point d’entrée parce qu’elle est mieux
  mesurée que le revenu courant dans l’enquête ;
- l’informalité fiscale est représentée par des scénarios, pas observée
  directement ;
- le TRE de référence est celui de 2023, tandis que l’enquête porte sur 2021 ;
- les services publics d’éducation et de santé améliorent un revenu final
  valorisé, mais ne procurent pas de liquidités aux ménages ;
- les agrégats de l’ANStat couvrent toute l’économie et ne sont donc pas
  directement comparables au seul champ des ménages de l’EHCVM.

Les hypothèses, robustesses et besoins de données supplémentaires sont détaillés
dans le document de travail et dans ses annexes.

## Références méthodologiques principales

- Lustig, N. (dir.), 2022, *Commitment to Equity Handbook*, deuxième édition.
- Akim, A.-M., Ben Jelloul, M., Czajka, L. et Robilliard, A.-S., 2020,
  *Collect More, Spend Better?*, AFD Research Paper 190.
- Demery, L., 2003, *Analyzing the Incidence of Public Spending*.
- Higgins, S. et Lustig, N., 2016, « Can a Poverty-Reducing and Progressive Tax
  and Transfer System Hurt the Poor? », *Journal of Development Economics*.
- Shorrocks, A. F., 2013, « Decomposition Procedures for Distributional
  Analysis », *Journal of Economic Inequality*.
