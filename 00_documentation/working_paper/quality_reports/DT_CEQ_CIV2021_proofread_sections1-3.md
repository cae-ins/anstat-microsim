# Relecture des sections 1 à 3 du DT_CEQ_CIV2021.tex

Fichier relu : `00_documentation/working_paper/DT_CEQ_CIV2021.tex`
Périmètre : lignes 72 à 535 (Introduction ; Contexte ; Approches de modélisation). Rien n'a été relu au-delà de `\section{Données}` (ligne 537), sauf pour vérifier la cohérence des chiffres et des termes repris ailleurs.
Mode : lecture seule, aucun fichier source modifié.

Conventions respectées et non signalées : macros injectées (`\GiniPrimaire{}`, etc.), `~\%`, « ; » et « : » simples, séparateur de milliers `~`, usage général de natbib.

Les numéros de ligne renvoient au fichier `.tex`. Gravité : haute (erreur factuelle ou contradiction interne visible par un lecteur), moyenne (gêne la lecture ou la compréhension), faible (polissage).

---

## Section 1 : Introduction (lignes 72–85)

| N° | Ligne | Catégorie | Gravité | Texte actuel (extrait) | Correction proposée |
|---|---|---|---|---|---|
| 1 | 75 | COHÉRENCE | moyenne | « modèles de microsimulation socio-fiscale de type INES » | Harmoniser avec la ligne 407 (« le modèle Ines de l'Insee et de la Drees ») : écrire « de type Ines (Insee-Drees) ». Le sigle apparaît ici sans définition et avec une casse différente de celle utilisée en section 3. |
| 2 | 75 | QUALITÉ | moyenne | « les règles du système fiscal et social de 2021, impôts indirects, prélèvements et transferts directs, réductions de prix, éducation et santé, selon la séquence de revenus » | Phrase d'environ 50 mots dont l'énumération appositive entre virgules se confond avec le reste. Couper : « ... les règles du système fiscal et social de 2021 selon la séquence de revenus du cadre CEQ \citep{lustig2022}. Ces règles couvrent les impôts indirects, les prélèvements et transferts directs, les réductions de prix, l'éducation et la santé. » |
| 3 | 75 | QUALITÉ | moyenne | « La production relève des modèles d'équilibre général calculable. » | Sujet elliptique : le lecteur ne sait pas de quelle « production » il s'agit. Proposer « Les ajustements de la production et des prix relatifs relèvent des modèles d'équilibre général calculable. » |
| 4 | 77 | GRAMMAIRE | faible | « Sous ces adaptations, le système de 2021 réduit l'inégalité » | « Avec ces adaptations » ou « Une fois ces adaptations faites ». |
| 5 | 79 | QUALITÉ | faible | « Trois résultats de cette première application structurent la suite. » | « cette première application » n'a pas d'antécédent ; la « seconde application » n'apparaît qu'à la ligne 81. Écrire « Trois résultats de la première application du modèle, l'incidence du système de 2021, structurent la suite. » |
| 6 | 79 | COHÉRENCE | moyenne | « le premier facteur de hausse de la pauvreté, avec 4,23 points » | Le même paragraphe attribue 3,54 points à la TVA. Les 4,23 points (ligne 2212) sont la contribution de Shapley de l'ensemble des impôts indirects entre revenu primaire et revenu final. Préciser : « avec 4,23 points en décomposition de Shapley, accises et droits de douane compris ». |
| 7 | 79 | GRAMMAIRE | faible | « un cinquième du pouvoir égalisateur du système est absorbé par du reclassement entre ménages, et deux cinquièmes pour l'éducation seule » | Ellipse bancale (« deux cinquièmes pour »). Proposer « ... et deux cinquièmes de celui de l'éducation seule ». |
| 8 | 81 | GRAMMAIRE | moyenne | « Rétablir la TVA sur les intrants de la filière avicole, simulé en premier tour par la transmission du surcoût au prix du poulet, est une charge progressive » | Anacoluthe : l'infinitif sujet reçoit un participe (« simulé ») puis un attribut (« est une charge ») qui ne lui convient pas. Proposer « Le rétablissement de la TVA sur les intrants de la filière avicole, simulé en premier tour par la transmission du surcoût au prix du poulet, produit une charge progressive ». |
| 9 | 81 | QUALITÉ | faible | « Rétablir la TVA [...] qu'au premier. » | Phrase d'environ 60 mots. Couper après « 45~\% » : « Son effet sur la pauvreté est de l'ordre de 0,01 point, la part budgétaire du poulet étant quinze fois plus élevée au dixième décile qu'au premier. » |
| 10 | 81 | GRAMMAIRE | faible | « Le modèle est enfin préparé à une troisième interrogation » | « préparé pour une troisième interrogation » ou « prêt pour une troisième interrogation ». |
| 11 | 81 | COHÉRENCE | faible | « aux ventes finales aujourd'hui exonérées » | Le document est daté de 2026 et décrit le droit de 2021, que la loi de finances 2026 a modifié (lignes 356–360). Écrire « aux ventes finales exonérées en 2021 ». |

---

## Section 2 : Contexte : le système fiscal et social ivoirien (lignes 88–361)

| N° | Ligne | Catégorie | Gravité | Texte actuel (extrait) | Correction proposée |
|---|---|---|---|---|---|
| 12 | 99–108 | QUALITÉ | faible | « Les impôts indirects frappent la consommation : la TVA, [...] sur les produits agricoles exportés. » | Phrase d'environ 60 mots. Couper avant la fiscalité de porte : « ... les droits d'enregistrement et de timbre. S'y ajoute la fiscalité de porte : droits de douane du Tarif extérieur commun, prélèvements communautaires et droit unique de sortie sur les produits agricoles exportés. » |
| 13 | 107, 149, 334 | COHÉRENCE | moyenne | « Tarif extérieur commun » (l. 107) ; « Droits de douane du TEC » (l. 149) ; « les droits de douane du TEC » (l. 334) | Le sigle TEC est utilisé dans la figure et dans le texte avant sa définition (ligne 748, section Méthodologie). Écrire « Tarif extérieur commun (TEC) » à la première mention, ligne 107. |
| 14 | 116 | QUALITÉ | faible | « et le Trésor pour un résidu » | « et le Trésor pour le reste ». |
| 15 | 118–119, 157 | COHÉRENCE | moyenne | Texte : « réduit certains prix par les tarifs sociaux de l'eau et de l'électricité » ; figure, nœud e6 en gris : « Soutien aux carburants; autres subventions » | La sous-section 1326 s'intitule « Réductions publiques de prix sur l'électricité, l'eau et les carburants » et traite un soutien au carburant nul au centre mais présent en robustesse (80 FCFA/litre). La figure et le texte de contexte le classent hors champ sans nuance. Préciser dans la légende « hors champ au scénario central » et libeller le nœud « Soutien aux carburants (robustesse seulement); autres subventions ». |
| 16 | 137, 150, 152 | COHÉRENCE | moyenne | Nœuds : « BIC, BNC, BA, IMF » ; « Redevance statistique, PCS, PCC » ; « PSSN : transferts monétaires » | IMF, PCS et PCC ne sont définis nulle part dans le document ; PSSN n'est défini qu'à la ligne 776. Dans le texte, l'impôt minimum forfaitaire (l. 204), le prélèvement communautaire de solidarité et le prélèvement communautaire CEDEAO (l. 329–330) et le programme de filets sociaux (l. 117) sont nommés en toutes lettres sans sigle. Ajouter les sigles entre parenthèses dans le texte (« impôt minimum forfaitaire (IMF) », « prélèvement communautaire de solidarité (PCS) », « prélèvement communautaire de la CEDEAO (PCC) », « Programme de filets sociaux productifs (PSSN) ») ou les expliciter dans la légende. Noter que « IMF » prête à confusion avec le Fonds monétaire international cité ligne 301. |
| 17 | 138, 185, 270 | COHÉRENCE | moyenne | Figure : « Impôts sur les salaires : IS, CN, IGR » ; texte : « l'impôt sur les salaires ne concerne que les salariés du secteur formel » (l. 185) ; « l'impôt sur les salaires sous ses trois cédules » (l. 270) | « Impôt sur les salaires (IS) » désigne à la ligne 213 l'une des trois cédules seulement. Employer « l'imposition des salaires » (comme à la ligne 212) pour l'ensemble IS + CN + IGR, et réserver « impôt sur les salaires » à l'IS. Dans la figure, « Imposition des salaires : IS, CN, IGR ». |
| 18 | 167–168 et 277–280 | COHÉRENCE | haute | « Les recettes fiscales encaissées en 2021 s'élèvent à 4~246 milliards de FCFA dans la loi de règlement » puis « 1~117 milliards de FCFA, soit 22,8~\% des recettes fiscales » | 1 117 / 4 246 = 26,3 %, non 22,8 %. Le 22,8 % correspond aux recettes fiscales du TOFE (environ 4 900 milliards, cohérent avec le taux de pression de 12,3 % du PIB). Le lecteur ne peut pas le deviner. Écrire « soit 22,8~\% des recettes fiscales du tableau des opérations financières de l'État et 2,8~\% du PIB », ou rapporter le chiffre aux 4 246 milliards de la loi de règlement (26,3 %). |
| 19 | 174 et 278–279 | COHÉRENCE | haute | « dont 637 de TVA en douane » (loi de règlement, l. 174) ; « la TVA perçue en douane, 560 milliards » (l. 278–279, \citep{anstat2023}) | Deux montants pour la même TVA à l'importation de 2021, à 60 lignes d'écart, sans explication. Indiquer la source et le périmètre de chacun (loi de règlement contre TOFE, TVA brute contre nette de remboursements) ou retenir un seul chiffre dans la section. La ligne 2332 utilise 556,3 pour la TVA intérieure DGI, cohérente avec la ligne 278. |
| 20 | 188 | QUALITÉ | faible | « dans les comptes nationaux définitifs de 2023, le secteur informel fournit 45,5~\% » | Ambigu : comptes de l'année 2023 ou comptes publiés en 2023 ? Préciser « dans les comptes nationaux définitifs de l'année 2023 » (ou l'année visée) et signaler que l'année de référence de l'étude est 2021. |
| 21 | 182–187 | QUALITÉ | faible | « Le premier est l'étroitesse [...] qui subissent la retenue à la source. » | Phrase d'environ 55 mots. Couper après « retracer » : « L'impôt sur les salaires ne concerne, lui, que les salariés du secteur formel, administration et entreprises enregistrées, qui subissent la retenue à la source. » |
| 22 | 204–206 | GRAMMAIRE | moyenne | « Un impôt minimum forfaitaire de 0,5~\% du chiffre d'affaires, plafonné, garantit une contribution aux entreprises déficitaires. » | Contresens : « garantit une contribution aux entreprises » se lit comme un versement aux entreprises. Écrire « impose une contribution minimale aux entreprises déficitaires » ou « garantit une contribution des entreprises déficitaires ». |
| 23 | 228–234 | QUALITÉ | moyenne | « Depuis l'année de référence, les trois impôts cédulaires [...] annoncée en introduction devra porter. » | Phrase d'environ 75 mots. Couper en trois : la fusion en un impôt unique ; le barème ; « Le modèle applique le droit de 2021. Cette réforme est l'une des règles que l'application des codes de 2025 et 2026, annoncée en introduction, devra porter. » |
| 24 | 231 | QUALITÉ | moyenne | « de 0~\% jusqu'à 75~000 FCFA à 32~\% au-delà de 8 millions » | La construction « de ... jusqu'à ... à ... » est illisible et l'unité de « 8 millions » manque. Écrire « dont les taux vont de 0~\% (revenu mensuel inférieur à 75~000 FCFA) à 32~\% (au-delà de 8 millions de FCFA) ». |
| 25 | 245–247 | QUALITÉ | faible | « L'enquête recense les loyers [...] mais trop peu pour asseoir une simulation; ces impôts restent hors du modèle et sont recensés parmi ses prolongements. » | Répétition « recense / recensés » et ellipse « mais trop peu ». Proposer « L'enquête relève les loyers et les revenus du capital déclarés par les ménages, mais en trop petit nombre pour asseoir une simulation ; ces impôts restent hors du modèle et figurent parmi ses prolongements. » |
| 26 | 264–266 | QUALITÉ | faible | « Les effectifs de référence proviennent du code CEQ archivé avec le projet » | Formulation opaque pour un lecteur externe. Préciser « proviennent des paramètres de couverture retenus dans le code de réplication (annexe~\ref{annexe:pipeline}) ». |
| 27 | 298 | COHÉRENCE | moyenne | « La Banque mondiale \citep{worldbank2019} estime » | L'entrée bib a pour auteur « Banque mondiale » : la sortie sera « La Banque mondiale (Banque mondiale, 2019) estime ». Utiliser `\citeyearpar{worldbank2019}` ou écrire « \citet{worldbank2019} estime ». |
| 28 | 301–302 | COHÉRENCE | faible | « le Fonds monétaire international inscrit leur rationalisation parmi les mesures du programme financier \citep{imf2023} » | Même redondance (auteur bib « Fonds Monétaire International »). Utiliser `\citeyearpar{imf2023}` juste après le nom de l'institution. |
| 29 | 300 | QUALITÉ | faible | « et en fait le premier gisement de mobilisation fiscale du pays » | « en fait » peut se lire comme « en réalité ». Écrire « et y voit le premier gisement de mobilisation fiscale du pays ». |
| 30 | 304 | COHÉRENCE | faible | « très inférieur au taux légal » | Le reste de la section et du document emploie « taux statutaire » (l. 343, 440, 445, 450 ; lexique l. 700–702). Harmoniser : « très inférieur au taux statutaire ». |
| 31 | 313 | QUALITÉ | faible | « valaient en 2021 14~\% pour les boissons non alcoolisées » | Juxtaposition de deux nombres. Écrire « s'élevaient en 2021 à 14~\% pour les boissons non alcoolisées ». |
| 32 | 348–349 | QUALITÉ | moyenne | « Les intrants de l'élevage relevaient de ce champ d'exonérations. En 2021, l'article 355 [...] exonère » | « ce champ » renvoie à la liste de l'article 355 (l. 286–295), à deux paragraphes de distance, après les accises et la fiscalité de porte. Réécrire « Les intrants de l'élevage relèvent, en 2021, du champ d'exonérations de l'article 355 ». Cela règle aussi le passage de l'imparfait au présent entre les deux phrases. |
| 33 | 286–295 | QUALITÉ | faible | « L'article 355 exonère un vaste champ : les produits alimentaires [...] enfin les exportations » | Énumération d'environ 90 mots en une phrase. Acceptable pour une liste juridique, mais un découpage en deux phrases (produits alimentaires et agricoles ; services et exportations) faciliterait la lecture. |

---

## Section 3 : Approches de modélisation : la microsimulation et l'informalité (lignes 364–534)

| N° | Ligne | Catégorie | Gravité | Texte actuel (extrait) | Correction proposée |
|---|---|---|---|---|---|
| 34 | 372–376 | QUALITÉ | faible | « Les règles fiscales et sociales sont définies au niveau de l'unité, [...] qui n'a de sens qu'à ce niveau. » | Phrase d'environ 50 mots. Couper après « effacent » : « La question de l'incidence, qui paie et qui reçoit, est une question de distribution qui n'a de sens qu'à ce niveau. » |
| 35 | 390 | QUALITÉ | moyenne | « pour les chocs assez gros pour déplacer les prix relatifs » | Registre familier. Écrire « pour les chocs d'ampleur suffisante pour déplacer les prix relatifs ». |
| 36 | 392–398 | QUALITÉ | moyenne | « Le choix n'est pas une question de sophistication mais d'objet : [...] une incertitude d'estimation propre \citep{bourguignonspadaro2006}. » | Phrase d'environ 65 mots. Couper après « réformes fiscales » : « Les réponses comportementales, quand on les ajoute, changent rarement le signe des résultats distributifs de premier tour et introduisent une incertitude d'estimation propre \citep{bourguignonspadaro2006}. » |
| 37 | 398–399 | QUALITÉ | faible | « Le modèle de ce document est statique par construction » | Reprise mot pour mot de la ligne 75 (« Il est statique par construction »). Varier : « Le modèle de ce document se rattache à cette tradition des modèles de règles statiques. » |
| 38 | 402 | QUALITÉ | faible | « ont une tradition longue » | « ont une longue tradition ». |
| 39 | 422 | GRAMMAIRE | faible | « Le revenu courant y est mal mesuré et la consommation mieux » | Ellipse trop forte. Écrire « Le revenu courant y est mal mesuré et la consommation l'est mieux ». |
| 40 | 424, 430 | COHÉRENCE | faible | « \citep{deatonzaidi2002,deaton1997} » ; « \citep{lustig2022,lustig2017} » | Ordre non chronologique dans deux appels groupés alors que les autres (l. 83, 433) sont chronologiques. Écrire « \citep{deaton1997,deatonzaidi2002} » et « \citep{lustig2017,lustig2022} ». |
| 41 | 452–459 | QUALITÉ | moyenne | « \citet{bachas2024} établissent [...] se répercute dans les prix. » | Phrase de près de 90 mots enchaînant trois résultats par points-virgules. Faire trois phrases, une par référence. |
| 42 | 455 | QUALITÉ | faible | « plus progressives qu'on ne le pensait » | Formulation orale. Écrire « plus progressives que ne l'indique l'application du taux statutaire ». |
| 43 | 459 | COHÉRENCE | faible | « dont la TVA rémanente se répercute dans les prix » | Seule occurrence de « rémanente » ; le document dit partout « enchâssée » (et « incorporée » en section Méthodologie). Écrire « dont la TVA rémanente, la TVA enchâssée de ce document, se répercute dans les prix » pour faire le lien. |
| 44 | 476 | COHÉRENCE | moyenne | « c'est la solution des scénarios S2 et S3 » | S2 et S3 ne sont définis qu'aux lignes 943–945 (section Méthodologie). Ajouter « définis en section~\ref{sec:methode} » ou une parenthèse (« taxation par fonction et milieu, S2, ou par fonction et décile, S3 »). Même remarque, moins gênante, pour « ses variantes à 75 et 50~\% » (l. 496) et « des variantes stricte et élargie » (l. 508). |
| 45 | 477 | COHÉRENCE | haute | « Une voie complémentaire tire de l'enquête des informations que le modèle n'utilise pas : les prix unitaires implicites [...] et les modules d'entreprises des ménages [...] bornent par le haut la part de l'offre » | Contradiction interne : la ligne 527 dit la probabilité de taxation « éprouvée par les prix unitaires et bornée par l'offre des entreprises des ménages », et l'introduction (l. 77) la dit « bornée par l'offre des entreprises des ménages que l'enquête recense ». Écrire « des informations qui n'entrent pas dans le calcul de la charge mais servent à l'éprouver ». |
| 46 | 478 | QUALITÉ | faible | « comme proxy de prix et de qualité » | Anglicisme. Écrire « comme indicateur indirect de prix et de qualité ». |
| 47 | 482–483 | TYPO | faible | « L'annexe » en fin de ligne 482, « \ref{annexe:ancrage} » en début de ligne 483 | Espace sécable entre « annexe » et le numéro ; le reste du fichier écrit « annexe~\ref ». Écrire « L'annexe~\ref{annexe:ancrage} ». |
| 48 | 485–490 | COHÉRENCE | moyenne | « \citet{keen2008} montre que [...], et \citet{emranstiglitz2005} en tirent que remplacer les droits de douane par la TVA n'est pas nécessairement efficace » | « en tirent » fait dériver Emran et Stiglitz (2005) d'un résultat de Keen (2008), soit trois ans plus tard. Écrire « et \citet{emranstiglitz2005} montrent que remplacer... », ou inverser l'ordre des deux références. |
| 49 | 491 | QUALITÉ | faible | « les taux effectifs de la tradition Ahmad et Stern » | Nom d'auteurs sans appel de citation, alors que la ligne 443 les cite. Écrire « de la tradition d'\citet{ahmadstern1984} ». |
| 50 | 493 | COHÉRENCE | faible | « jusqu'au prix des biens finals » | La ligne 708 écrit « achats finaux ». Les deux pluriels sont admis ; harmoniser sur « finaux » dans tout le document. |
| 51 | 499–507 | QUALITÉ | moyenne | « Les modèles de règles construits sur des enquêtes africaines [...] conformité, ajustement au seuil et informalité. » | Phrase d'environ 80 mots. Couper après « \citep{decoster2019,gasior2018} » et après « \citep{matsaganis2010} ». |
| 52 | 531–534 | QUALITÉ | faible | « et son application à un pays que ni SOUTHMOD ni les comparaisons CEQ publiées ne couvrent avec ce degré de détail » | Formule valorisante, contraire au registre voulu, et fragilisée par \citet{akim2020}, application CEQ à la Côte d'Ivoire citée trois fois plus haut. Écrire « et son application à la Côte d'Ivoire, absente de SOUTHMOD et des comparaisons CEQ multi-pays publiées ». |

---

## Décompte

### Par catégorie

| Catégorie | Nombre |
|---|---|
| GRAMMAIRE | 6 |
| TYPO | 1 |
| COHÉRENCE | 18 |
| QUALITÉ | 27 |
| **Total** | **52** |

### Par gravité

| Gravité | Nombre |
|---|---|
| haute | 3 |
| moyenne | 20 |
| faible | 29 |

### Par section

| Section | GRAMMAIRE | TYPO | COHÉRENCE | QUALITÉ | Total |
|---|---|---|---|---|---|
| 1. Introduction | 4 | 0 | 3 | 4 | 11 |
| 2. Contexte | 1 | 0 | 9 | 12 | 22 |
| 3. Approches de modélisation | 1 | 1 | 6 | 11 | 19 |
| **Total** | **6** | **1** | **18** | **27** | **52** |

---

## Les cinq constats les plus importants

1. **N° 18, lignes 167–168 et 277–280 (COHÉRENCE, haute).** « 4~246 milliards » de recettes fiscales puis « 1~117 milliards, soit 22,8~\% des recettes fiscales » : 1 117 / 4 246 = 26,3 %. Le 22,8 % se rapporte aux recettes fiscales du TOFE, dénominateur différent et non nommé. Préciser le dénominateur ou recalculer.
2. **N° 19, lignes 174 et 278–279 (COHÉRENCE, haute).** Deux montants pour la TVA en douane de 2021 : 637 milliards (loi de règlement) et 560 milliards (ANStat). Expliquer l'écart de source et de périmètre ou n'en garder qu'un.
3. **N° 45, ligne 477 (COHÉRENCE, haute).** « des informations que le modèle n'utilise pas » contredit la ligne 527 (« éprouvée par les prix unitaires et bornée par l'offre ») et l'introduction (ligne 77). Reformuler en « qui n'entrent pas dans le calcul de la charge mais servent à l'éprouver ».
4. **N° 16 et 13, lignes 137, 150, 152, 107/149/334 (COHÉRENCE, moyenne).** La figure TikZ utilise IMF, PCS, PCC, PSSN et TEC sans qu'aucun ne soit défini dans les sections 1–3 (IMF, PCS, PCC ne le sont nulle part) ; IMF se confond avec le Fonds monétaire international. Définir les sigles dans le texte ou la légende.
5. **N° 6, ligne 79 (COHÉRENCE, moyenne).** L'introduction attribue 3,54 points de pauvreté à la TVA puis 4,23 points aux impôts indirects sans dire que le second chiffre est une contribution de Shapley incluant accises et droits de douane, mesurée entre revenu primaire et revenu final. Ajouter cette précision.

À noter, juste derrière : n° 8 (ligne 81, anacoluthe « Rétablir la TVA ..., simulé ..., est une charge »), n° 22 (lignes 204–206, contresens « garantit une contribution aux entreprises déficitaires »), n° 27 (ligne 298, « La Banque mondiale (Banque mondiale, 2019) ») et n° 48 (lignes 485–490, Emran et Stiglitz 2005 présentés comme dérivant de Keen 2008).
