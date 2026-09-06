# Rapport d'évaluation — *Fiscalité, informalité, transferts et pauvreté en Côte d'Ivoire : une analyse d'incidence sur l'EHCVM 2021*

| | |
|---|---|
| **Document évalué** | `00_documentation/working_paper/DT_CEQ_CIV2021.tex` — PDF figé `DT_CEQ_CIV2021_v20.pdf` (53 pages) |
| **Version** | v20 (clôture de session, 20 juillet 2026) |
| **Date de l'évaluation** | 21 juillet 2026 |
| **Périmètre** | Manuscrit LaTeX + pipeline R de production (`05_scripts_R/`, 26 étapes) + appareil de reproductibilité (`replication_package/`, `quality_reports/`) |
| **Classification JEL** | H22, D31, I32, O17 |

> **Note de méthode.** Cette évaluation croise trois lectures : (i) le manuscrit,
> (ii) le code qui produit ses chiffres, (iii) l'appareil de vérification et de
> réplication. Chaque critique est adossée à une preuve traçable dans le dépôt
> (`fichier:ligne` ou valeur). Le référentiel est celui du cadre CEQ
> (Lustig, dir., *Commitment to Equity Handbook*, 2022).

---

## 1. Synthèse et recommandation

**Recommandation : révision majeure, avec potentiel de publication en revue de
champ** (économie publique du développement et incidence fiscale dans les pays à
revenu faible ou intermédiaire). Ce potentiel reste conditionnel à une révision du
statut du scénario central et à un positionnement plus précis face aux études les
plus proches.

Le papier est **techniquement abouti, transparent et intellectuellement honnête**.
Il apporte une contribution appliquée solide pour la Côte d'Ivoire : une TVA
« enchâssée » mesurée par un modèle de prix de Leontief sur le tableau
ressources-emplois (TRE) national, un traitement explicite de l'informalité des
achats par scénarios de transmission, et une séquence CEQ complète jusqu'aux
services publics en nature. Le message central — un système fiscalo-budgétaire
**égalisateur mais appauvrissant en liquidités** — est nuancé, correctement
défendu, et non survendu.

La révision demandée ne porte pas sur la rigueur formelle, qui est élevée (identités
comptables fermées, inférence de plan de sondage correcte, décomposition de Shapley
exacte). Elle porte d'abord sur **deux hypothèses structurantes** — l'ancrage des
concepts de revenu sur la consommation et le profil d'informalité S3 non identifié
par une donnée ivoirienne. La portée statique du modèle et la validation dans
l'échantillon du ciblage simulé doivent aussi être formulées plus précisément.
L'absence de calage forcé sur les recettes est, en revanche, un choix défendable :
le manuscrit publie déjà une réconciliation macroéconomique. Une série distincte de
correctifs de forme et de reproductibilité reste rapide à traiter.

---

## 2. Résumé du papier (tel que compris par l'évaluateur)

**Question.** Qui finance l'action publique, qui reçoit les paiements et services
qu'elle finance, et comment leur combinaison modifie *simultanément* l'inégalité et
la pauvreté en Côte d'Ivoire en 2021. C'est une analyse d'incidence fiscalo-budgétaire
de type CEQ sur l'EHCVM 2021 (12 965 ménages, 64 491 personnes).

**Contribution revendiquée** (trois apports, annoncés en introduction) : (1)
distinguer trois mécanismes de TVA souvent confondus — directe, non déductible, et
enchâssée par Leontief ; (2) traiter les achats informels par trois scénarios de
transmission effective (S1 intégrale, S2 par fonction × milieu, S3 par fonction ×
décile, central) ; (3) mener la séquence CEQ jusqu'aux transferts en nature
(éducation, santé au coût public net) via une reconstruction du ciblage PSSN par PMT.

**Résultats clés.** L'inégalité baisse le long de la cascade (Gini 0,3409 en revenu
primaire → 0,3167 en revenu final) tandis que la pauvreté monétaire **augmente**
(37,72 % en primaire → 42,04 % en consommable), 4,35 % de la population franchissant
le seuil à la baisse. La décomposition de Shapley attribue la réduction du Gini
principalement aux impôts indirects (35,1 %), à l'éducation (28,2 %) et aux
prélèvements directs (26,9 %). Une réforme portant la TVA à 9 % ajoute +0,47 pt de
pauvreté sans compensation, mais −0,22 pt avec recyclage universel des recettes.

**Appréciation du positionnement.** La contribution est réelle et bien située face à
`akim2020` (OpenFisca / ENV 2014), dont le papier se distingue par l'ancrage sur la
consommation par tête, l'absence de recalage salarial et l'ajout de la TVA enchâssée.
La thèse est explicitement celle de `higgins2016` (« un système réducteur de pauvreté
peut appauvrir les pauvres »), appliquée avec soin.

---

## 3. Forces

1. **Contribution appliquée identifiable.** La TVA enchâssée
   par Leontief sur le TRE ivoirien, combinée au traitement scénarisé de l'informalité
   des achats (inspiré de `bachas2024`), constitue un apport net pour l'application
   ivoirienne et pour la mesure de l'incidence en Afrique de l'Ouest. La nouveauté
   méthodologique internationale doit toutefois être établie par une comparaison
   plus large que le seul précédent ivoirien. Le modèle de prix est techniquement propre :
   condition de Hawkins-Simon vérifiée (rayon spectral ρ(Aᵈ) = 0,346 < 1), résidu du
   point fixe de l'ordre de 10⁻¹⁷ (`utils/leontief_vat.R:129-151`).

2. **Rigueur comptable interne.** Les sept concepts de revenu CEQ ferment ménage par
   ménage à moins de 10⁻⁶ FCFA (`05_scripts_R/22_income_concepts.R:79-92`). La
   décomposition de Shapley est **exacte** sur les 2⁶ = 64 sous-ensembles et les 720
   ordres, avec réconciliation vérifiée (`23_marginal_contribution.R:45-73`). La
   cascade fiscale respecte l'ordre légal (douane → accise → TVA) et évite le
   double-comptage (chevauchement TVA/accise/douane retranché, 28,6 Mds,
   `17_indirect_other.R:186-206`).

3. **Inférence statistique correcte.** L'incertitude est propagée par bootstrap
   **Rao-Wu** à 500 réplications respectant la stratification et les grappes du plan
   de sondage (`utils/distributive.R`), et non par un bootstrap i.i.d. naïf. Un
   classeur de convergence compare 50/100/200/500 réplications.

4. **Transparence exceptionnelle sur les limites.** Chaque hypothèse forte est nommée
   dans les en-têtes de scripts *et* dans l'annexe D, qui détaille pour chacune des
   dix réserves le biais possible, le contrôle existant et la donnée nécessaire. Les
   auteurs répètent, à juste titre, que le revenu final n'est pas de la liquidité et
   que les paramètres S3 ne sont pas calés.

5. **Charpente de reproductibilité professionnelle.** Environnement figé
   (`renv.lock`, R 4.5.3, `sessionInfo.txt`), orchestration déterministe
   (`00_master.R`), pré-vol (40 contrôles PASS) et vérification finale (32 PASS),
   `exhibit_map.csv` reliant 33 exhibits à leur script et à la ligne productrice,
   manifeste MD5 des entrées, runbook agent et spécification JSON lisible par machine.

6. **Qualité rédactionnelle.** Français académique soigné ; le lexique
   (`tab:lexique`, l. 352-535) définit chaque terme, ce qui sert la transparence.
   L'argumentation distingue constamment progressivité relative et effet sur la
   pauvreté (sous-section « Une taxe progressive peut néanmoins accroître la
   pauvreté », l. 1289).

---

## 4. Questions scientifiques et portée

### F1 — L'ancre « consommation = revenu disponible »

**Description.** Le choix le plus structurant de tout l'édifice pose le revenu
disponible par tête égal à la dépense de consommation par tête :
`yd_pc = pcexp` (`05_scripts_R/03_compute_taxes.R:86`). Toute la cascade « revenu »
est ensuite reconstruite *à rebours* depuis cette ancre : le revenu de marché
s'obtient en rajoutant les prélèvements directs, le consommable en retranchant les
impôts indirects.

**Preuve.** `03_compute_taxes.R:86-87` (`yd_pc = pcexp`, `yd_hh = pcexp * hhsize`) ;
commentaire assumé `16_direct_taxes.R:504-506` (« L'agrégat de consommation officiel
est l'ancre du revenu disponible ») ; variable diagnostique `yp_pc_no_dtr` nommée
« Gini Y_P reconstitué à rebours (hypothèse dtr=0) » (`16_direct_taxes.R:764-766`).

**Impact sur les conclusions.** L'épargne est nulle par construction et les concepts
antérieurs au revenu disponible sont reconstruits plutôt qu'observés. Il serait
toutefois inexact de qualifier tous les indicateurs obtenus de simples « Gini de
consommation » : les prélèvements et transferts reconstruisent des contrefactuels CEQ
distincts autour d'une mesure de bien-être ancrée sur la consommation. Le classement
des ménages repose bien sur cette consommation observée, et non sur un revenu courant
mesuré indépendamment. Le vocabulaire doit rendre cette convention visible sans
effacer les différences entre concepts CEQ.

**Piste de réponse.** Présenter l'étude comme une **analyse CEQ ancrée sur la
consommation** ; préciser que les revenus primaire, net et brut sont des concepts
contrefactuels reconstruits ; rappeler cette convention au point de lecture des
Gini, pas seulement en annexe.

### F2 — Le profil d'informalité S3, central mais exogène et non identifié

**Description.** Le scénario **central** S3 module la transmission effective de la TVA
par un coefficient α variant par fonction de consommation (COICOP) et par décile :
`alpha = alpha_d1 + (decile-1)*slope` (`utils/vat_scenarios.R:46-51`). Ces coefficients
sont **écrits à la main** (matrice de valeurs en dur, `vat_scenarios.R:7-26`),
inspirés qualitativement des courbes d'Engel de l'informalité de `bachas2024`, mais
**ni estimés sur l'EHCVM ivoirienne ni calés sur une cible administrative**.

**Preuve.** En-tête sans ambiguïté du fichier (`utils/vat_scenarios.R:1-4`) : « Ces
profils sont des hypothèses exogènes […] ils ne sont pas estimés sur l'EHCVM
ivoirienne et ne sont calés sur aucune cible administrative. » Confirmé par
le manuscrit (`DT_CEQ_CIV2021.tex:636-654`). Valeurs *p. ex.* : alimentation
α_d1 = 0,120, pente = 0,034 ; alcool/tabac 0,480 ; communication 0,780.

**Impact sur les conclusions.** C'est la principale vulnérabilité du papier. Le signe
du résultat résiste aux scénarios publiés : la TVA totale accroît la pauvreté de
3,54 points sous S3, 3,96 points sous S2 et 7,07 points sous S1
(`DT_CEQ_CIV2021.tex:1289-1312`). Son **amplitude**, en revanche, n'est pas identifiée
par une donnée ivoirienne. La sensibilité juridique du droit à déduction constitue
une seconde incertitude, distincte de l'informalité : elle fait passer la TVA
enchâssée de 214,3 à 22,3 milliards de FCFA
(`13b_leontief_local_io.R:507-530`). Le manuscrit ne recalcule pas la pauvreté dans
cette variante juridique; il ne faut donc pas transposer mécaniquement le facteur dix
à l'effet sur la pauvreté.

**Piste de réponse.** Les auteurs publient honnêtement des robustesses (S3 ±20 %,
collecte amont 75/50 %), mais aucune n'est ancrée à une donnée ivoirienne. Il serait
décisif d'ancrer **au moins une borne** sur une source nationale — si l'EHCVM renseigne
le lieu ou le mode d'achat, ou par recoupement avec la facturation électronique et les
comptes. À défaut, S3 doit rester une hypothèse centrale explicitement conditionnelle,
S2 une robustesse paramétrique et S1 une borne haute de transmission; le papier doit
mettre l'intervalle de résultats au même niveau que l'estimation S3.

### F3 — Absence de calage fiscal : choix défendable, sensibilité de niveau à préciser

**Description.** Les agrégats officiels (DGI, ANStat) sont utilisés comme **contrôles
de périmètre**, jamais comme cibles de calage. Le modèle n'est donc pas contraint de
reproduire les recettes encaissées. Ce choix est explicite et le manuscrit contient
déjà une sous-section de validation externe ainsi qu'un tableau de rapprochement
simulé/référence (`DT_CEQ_CIV2021.tex:1831-1906`).

**Preuve.** Insistance répétée dans le code (`13b_leontief_local_io.R:446-451` ;
`16_direct_taxes.R:801-806` ; `25_ceq_report_tables.R:112-114`). Écarts substantiels
non corrigés : TVA directe simulée **697,2 Mds** contre TVA intérieure DGI encaissée
**556,3 Mds** (`13b:451, 478-482`) ; IRPP simulé rapporté en simple ratio diagnostic
vs DGI (`16_direct_taxes.R:789-800`).

**Impact.** Le non-calage limite surtout l'interprétation des **niveaux agrégés** et de
la couverture des masses simulées. Il ne suffit pas, à lui seul, à invalider leur
profil distributif; inversement, un calage macroéconomique ne garantirait pas que ce
profil corresponde à l'incidence réelle. Les écarts de champ entre ménages,
entreprises, administrations et non-résidents rendent un facteur de calage global
difficile à interpréter.

**Piste de réponse.** Conserver le principe « pas de calage forcé » et le tableau de
réconciliation existant. Renforcer, si les données le permettent, la comparaison sur
des périmètres véritablement appariés et publier une sensibilité de mise à l'échelle
pour les seuls instruments comparables. Cette sensibilité doit rester une robustesse,
pas remplacer le scénario central.

### F4 — Nature statique du modèle

**Description.** Quantités consommées, coefficients techniques et offre sont fixes ;
aucune substitution comportementale ni bouclage d'équilibre général. L'analyse est une
incidence « au premier jour ».

**Impact.** Cette convention est standard et assumée en CEQ. Des quantités fixes
peuvent surestimer la recette par rapport à une demande qui se contracte, mais cet
effet n'est pas mécanique dès que les ménages substituent entre produits ou lieux
d'achat. L'effet sur la pauvreté est plus ambigu encore : substitution,
formalisation, répercussion sur les prix et incidence sur les producteurs peuvent
agir dans des directions différentes. La simulation mesure donc un effet comptable
de court terme, pas une prévision comportementale.

**Piste de réponse.** Conserver la formulation prudente déjà présente dans la section
des limites et l'appliquer systématiquement aux simulations de TVA à 9 %. Éviter les
termes causaux ou prédictifs lorsqu'ils dépassent l'incidence au premier tour.

### F5 — Validation dans l'échantillon de la sélection PMT

**Description.** Le ciblage du PSSN repose sur une régression pondérée de
`log(yd_pc)` — donc de la log-consommation — sur des covariables observables, suivie
d'un classement et de deux coupures (`18_transfers.R:269-310`). Prédire une mesure de
bien-être à partir de caractéristiques observables est précisément la logique d'un
test indirect de niveau de vie (PMT); ce n'est pas une circularité. La fragilité vient
du fait que le modèle est estimé et évalué sur les mêmes ménages.

**Impact.** L'évaluation dans l'échantillon peut surestimer la qualité prédictive et
donc la part de bénéficiaires classés pauvres. La robustesse « déclarations S15
d'abord » (`18_transfers.R:359-403`) fait passer cette part de 85,9 % à 79,5 %. Elle
montre la sensibilité à une autre règle d'allocation, mais ne constitue pas une
validation hors échantillon; les déclarations S15 ne permettent d'ailleurs pas
d'identifier parfaitement le programme administratif ni son montant.

**Piste de réponse.** Estimer une validation croisée pondérée ou un *cross-fitting*,
puis publier la performance de ciblage hors échantillon. Présenter aussi la variante
« déclarations d'abord ». À défaut de ce contrôle, décrire le PMT comme une règle
simulée et non comme une mesure de la performance réelle du registre PSSN. Un
appariement au registre administratif reste le test décisif.

---

## 5. Préoccupations mineures (forme et reproductibilité — corrigibles rapidement)

### R1 — Injection automatique des chiffres « en trompe-l'œil »

Le script `25_ceq_report_tables.R:283-292` génère bien
`00_documentation/working_paper/generated/ceq_summary_values.tex` (macros
`\GiniDisponible{0.3336}`, `\GiniConsommable{0.3247}`, `\GiniFinal{0.3167}`,
`\PartAppauvrie{37.50\%}`, `\PartNouveauxPauvres{4.35\%}`). **Mais ce fichier n'est
jamais `\input`-é** dans `DT_CEQ_CIV2021.tex`, et ces macros n'apparaissent nulle part
ailleurs. Tous les chiffres du papier sont donc **codés en dur** (*p. ex.*
`DT_CEQ_CIV2021.tex:50, 1756-1761, 1811`). Le garde-fou contre la désynchronisation
code↔papier n'existe pas réellement ; il manque même une macro `\GiniPrimaire` pour le
0,3409 de tête de gondole. **Correctif :** brancher `\input{generated/ceq_summary_values}`,
compléter le jeu de macros, et remplacer en priorité les valeurs de première ligne et
du tableau des concepts. Viser « zéro chiffre en dur » dans tout le texte serait peu
réaliste; les autres nombres peuvent rester protégés par l'audit automatisé des
affirmations.

### R2 — Audit bibliographique périmé

`bib_audit_semantic.md` annonce « 33 notices / 26 citées / 7 inutilisées », alors que
`references.bib` en compte aujourd'hui **36**, dont **29** citées. L'audit sous-compte
de 3 sur les deux lignes. **Correctif :** régénérer l'audit sur le fichier courant ;
confirmer et retirer (ou justifier) les ~7 entrées orphelines candidates
(`santossilva2006`, `decoster2021`, `imf2023`, `oecd2023`, `lustig2017`,
`reynolds1977`, `civref2023` — à vérifier contre les `\citep` réels).

### R3 — Messages de parité des exhibits codés en dur

`exhibit_map.csv` contient **33** lignes et **33** labels uniques, en parité avec les
33 labels du fichier LaTeX auxiliaire. Il n'existe donc pas un écart réel de 33 contre
34 exhibits. En revanche, `01_verify_outputs.R:47-66` écrit littéralement « 34 sorties
accessibles » et « 34 labels en parité », sans calculer ces nombres. Une même exhibit
peut en outre pointer vers plusieurs fichiers de sortie. **Correctif :** calculer et
afficher séparément le nombre d'exhibits, de labels uniques et de chemins de sortie;
supprimer les deux chaînes codées en dur.

### R4 — 11/27 affirmations hors du vérificateur automatique

L'audit de reproductibilité conclut à 16 PASS, 0 FAIL, **11 EXPLAINED**
(`reproducibility_audit_DT_CEQ_CIV2021.md:11-21`). Les 11 « EXPLAINED » sont tous
justifiés par la précision d'affichage ou l'arrondi : la valeur non arrondie produit
bien la valeur publiée. L'arrondi n'est donc pas un échec de reproductibilité et une
égalité stricte avec la sortie brute n'est pas le bon critère. Le vrai défaut est que
ces 11 comparaisons **ne figurent pas** dans `01_verify_outputs.R`. **Correctif :** les
intégrer au pipeline avec, selon le cas, une règle d'arrondi déclarée ou une tolérance
documentée. Une affirmation doit alors devenir PASS automatiquement dès que son
affichage est reproduit.

### R5 — Reproductibilité externe non opérationnelle aujourd'hui

La charpente est exemplaire, mais trois obstacles empêchent un reproducteur externe de
tourner le pipeline **à ce jour** :
- le canal de distribution des données (MinIO) est « prévu ultérieurement » et non
  configuré (`data/access-restricted-data.md:18-25`) ; les 6 classeurs `params_*` et
  la table TVA internes sont marqués `access = "MinIO interne prévu"`,
  `licence = "à approuver"` (`data/data_manifest.csv:12-18`) ;
- l'étape de préparation dépend de **Stata**, dont la version n'est pas capturée dans
  l'environnement de réplication (README:95) ;
- la licence du code et des paramètres n'est pas encore approuvée
  (`LICENSE_ACTION_REQUIRED.md`).

**Correctif :** activer le canal de distribution; un jeu de paramètres synthétique
peut en complément tester le fonctionnement du pipeline, mais ne remplace pas la
réplication numérique. Documenter/verrouiller la version Stata et résoudre la licence.

### R6 — Déséquilibre méthode/résultats

La section 4 (méthodologie, l. 341-1224) est longue et exigeante ; le ratio
méthode/résultats penche fortement vers la méthode, au risque de noyer le lecteur non
spécialiste. **Correctif :** déplacer une partie des dérivations (passerelle prix de
base, séparation domestique/importé) vers l'annexe, en gardant dans le corps l'intuition
et les équations décisives.

---

## 6. Remarques éditoriales et ligne à ligne

- **Portée de la contribution.** Le rapprochement avec `akim2020` établit la valeur
  ajoutée par rapport au principal précédent ivoirien, mais pas encore une nouveauté
  méthodologique internationale. Le texte devrait comparer plus explicitement la
  combinaison TRE--TVA enchâssée--informalité aux trois à cinq travaux les plus proches.
- **Terminologie de l'abstract.** L'abstract résume « 4,35 % franchit le seuil à la
  baisse », tandis que le corps distingue soigneusement les **appauvris** (37,50 % de
  la population subissant une perte sous le seuil) et les **nouveaux pauvres** (4,35 %).
  La compression dans l'abstract peut prêter à confusion : préciser « nouveaux pauvres »
  et, si l'espace le permet, mentionner le 37,50 %.
- **Paramètre « une hospitalisation = 10 consultations »** (l. 1114-1117) : centre
  géométrique arrondi, choisi sans ancrage empirique. Assumé mais fragile ; une phrase
  de justification (ou une borne de sensibilité) serait utile.
- **Hétérogénéité d'ingénierie du pipeline.** Les étapes 13-15 sont des scripts à effet
  de bord exécutés par `source()` et pilotés par variable d'environnement
  (`IO_LOCAL_BASIS`), là où le reste du pipeline expose des fonctions. Sans effet sur
  les résultats, mais fragilise la maintenance et la reprise à froid.
- **Revenu final ≠ liquidité.** Le rappel est présent et bienvenu (l. 118-121,
  1741-1743) ; le conserver visible à chaque mention du Gini/pauvreté « final ».

---

## 7. Recommandations priorisées

**Priorité 1 — réponses scientifiques avant soumission :**

1. Ancrer au moins une borne du profil S3 sur une source ivoirienne; à défaut,
   présenter conjointement le signe robuste et la fourchette S3/S2/S1 (F2).
2. Renforcer le cadrage « concepts CEQ ancrés sur la consommation » et, si possible,
   publier une sensibilité de niveau sur des périmètres fiscaux appariés (F1, F3).
3. Valider le PMT hors échantillon ou réduire les affirmations sur sa performance
   réelle (F5).
4. Maintenir le vocabulaire d'incidence comptable de court terme dans toutes les
   simulations de réforme (F4).

**Priorité 2 — appareil de vérification et réplication externe :**

5. Intégrer les 11 affirmations arrondies au pipeline avec une règle d'affichage ou
   une tolérance explicite (R4).
6. Activer/documenter la distribution des paramètres, verrouiller Stata et résoudre
   la licence (R5).

**Priorité 3 — correctifs mécaniques :**

7. Brancher réellement l'injection des chiffres de première ligne (`\input` + macros
   + `\GiniPrimaire`) et laisser l'audit automatisé protéger les autres valeurs (R1).
8. Régénérer l'audit bibliographique sur le fichier courant (36/29) et purger les
   entrées orphelines (R2).
9. Remplacer les messages « 34 » codés en dur par des décomptes calculés (R3).

**Avant soumission :** demander un second rapport indépendant, calibré sur une revue
cible précise, afin d'évaluer le positionnement dans la littérature et la portée
internationale de la contribution.

---

## Annexe — éléments quantitatifs de contrôle

**Résultats centraux (sorties du pipeline et tableau des concepts CEQ).**

| Indicateur | Primaire | Disponible | Consommable | Final |
|---|---|---|---|---|
| Gini | 0,3409 | 0,3336 | 0,3247 | 0,3167 |
| Pauvreté (%) | 37,72 | 37,47 | 42,04 | 33,92 |

Nouveaux pauvres monétaires (primaire → consommable) : 4,35 %. Pertes sous le seuil :
142,84 Mds ; gains : 9,35 Mds FCFA.

**Masses fiscales.** TVA finale directe 697,2 Mds ; TVA enchâssée 214,3 Mds ; TVA
totale ménages 911,6 Mds ; accises 67,9 Mds ; droits de douane 185,1 Mds ; paiements
publics directs 125,798 Mds ; pensions observées 252,603 Mds ; réductions de prix
25,15 Mds ; éducation nette 1 301,62 Mds ; santé nette 81,85 Mds.

**Parts Shapley de la réduction du Gini.** Impôts indirects 35,1 % ; prélèvements
directs 26,9 % ; éducation 28,2 % ; santé 7,5 % ; paiements publics directs 3,0 % ;
réductions de prix −0,7 %.

**Appareil de vérification.** Audit de 27 affirmations : 16 PASS, 11 EXPLAINED
(arrondi), 0 FAIL, 0 UNMATCHED. Preflight 40 PASS ; vérification finale 32 PASS.
Reprise intégrale du 19 juillet 2026 : 350,4 s, sans avertissement logiciel.
Tolérances (`expected_metrics.csv`) : Gini ±5·10⁻⁵ ; taux de pauvreté ±5·10⁻⁴ ;
Shapley ±5·10⁻⁷ pt de Gini ; masses ±0,05–0,2 Md.

**Écarts internes signalés.** TVA directe simulée 697,2 Mds vs DGI encaissée
556,3 Mds. Sensibilité juridique de la TVA enchâssée : 214,3 → 22,3 Mds. La carte et
le manuscrit contiennent 33 exhibits; les mentions « 34 » du rapport de vérification
proviennent de chaînes codées en dur et non d'un décompte contradictoire.

---

*Rapport établi à partir de la lecture croisée du manuscrit, du pipeline R et de
l'appareil de reproductibilité au 21 juillet 2026. Toutes les critiques sont
constructives et adossées à une preuve du dépôt.*
