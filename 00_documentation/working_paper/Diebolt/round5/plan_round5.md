# Plan de correction — Round 5 (rapport de référé *Journal of African Economies*)

Planificateur : Fable (cycle team_claude). Date : 2026-09-06.
Cahier des charges : `00_documentation/working_paper/Diebolt/round5/referee_JAE.md` (sections 7, 8, 9).
Document cible : `00_documentation/working_paper/DT_CEQ_CIV2021.tex` (reste en **français** ; la traduction §6.3 est exclue de ce tour).

## 0. Cadrage et écarts signalés

Périmètre : M1 à M9 et points mineurs 1 à 20, hors traduction. Deux écarts par rapport au cadrage initial (« seuls M1 et M2 exigent des calculs ») :

1. **M3 exige aussi un calcul.** S4 n'existe que dans `06_01_sensitivity_taxation.R` (TVA directe seule) et `12_poverty_incidence.R`. La chaîne I/O (`13b_leontief_local_io.R` → `14_leontief_poverty.R`) qui produit le tableau 4 « directe + enchâssée » ne connaît que S1, S2, S3. Pour publier S4 dans le tableau 4 avec le même périmètre que S1–S3, il faut porter $\alpha_{kd}^{S4}$ dans 13b et 14. Coût faible, regroupé dans la tâche T1.
2. **M4(ii) exige un petit calcul.** `06_02_sensitivity_ranking.R` ne produit que des classements fondés sur la consommation (par tête, équivalent-adulte). Un classement indépendant de l'assiette taxée ($Y_P$ reconstruit à l'étape 22) doit être ajouté (tâche T2, légère).
3. **Point mineur 1** (2,17 vs 2,35 pour la TVA directe S3) : l'étape 12 soustrait `vat_s3` **nominal** de `pcexp` alors que l'étape 14 utilise `vat_direct_local_s3_real` (déflaté par `def_spa`). Il s'agit vraisemblablement d'une incohérence de convention entre scripts, à diagnostiquer et harmoniser dans T1, pas d'un « changement de périmètre » à expliquer.

Correspondance entre identifiants d'étapes de `00_master.R` et scripts (indispensable pour relancer le pipeline) :

| Étape | Script | Étape | Script |
|---|---|---|---|
| 6 | 06_01_sensitivity_taxation.R | 15 | 14_leontief_poverty.R |
| 7 | 06_02_sensitivity_ranking.R | 16 | 15_reform_vat_simulation.R |
| 9 | 08_figures.R | 23 | 22_income_concepts.R |
| 13 | 12_poverty_incidence.R | 24 | 23_marginal_contribution.R |
| 14 | 13_leontief_io.R puis 13b (current, constant) | 25 | 24_fiscal_impoverishment.R |
| | | 26 | 25_ceq_report_tables.R (écrit `generated/ceq_summary_values.tex`) |

Commande de relance depuis la racine du dépôt : `Rscript -e "source('05_scripts_R/00_master.R'); lance_pipeline(a, b)"`. Compilation LaTeX : pdflatex (MiKTeX) ×2 + bibtex + pdflatex, depuis `00_documentation/working_paper/` (skill `compiletex` disponible).

Contraintes communes à toutes les tâches de rédaction (à recopier dans chaque brief) :
- Prose continue, registre académique, **aucune liste à puces ni énumération verticale dans le corps du texte** ; citations natbib (`\citep`, `\citet`) ; tableaux booktabs + threeparttable ; flottants `[t]`.
- Se repérer par `\label{...}` et titres de `\subsection`, jamais par numéros de ligne (ils bougent d'une tâche à l'autre).
- Aucune valeur numérique existante ne change sans raison documentée ; toute nouvelle valeur est lue dans une sortie `07_reports/tables/**` ou une source citée, jamais inventée.
- Ne toucher qu'aux sections que la tâche possède (indiquées dans chaque brief) ; ne pas éditer résumé, introduction, conclusion et page de titre sauf T9.
- Compiler à la fin, vérifier zéro erreur, zéro `undefined reference`, zéro `Citation undefined`, et rendre compte des sections modifiées.

Ordre d'exécution strict : T0 → T1 → T2 → T3 → T4 → T5 → T6 → T7 → T8 → T10 → T9 → T11 → T12 (audit). Aucune parallélisation sur le `.tex` ; T7 (recherche documentaire) peut démarrer en parallèle de T1–T2 à condition de ne pas éditer le `.tex` ni `references.bib` avant la fin de T3.

---

## T0 — Référentiel de départ (sonnet, difficulté faible)

Objectif : figer un état de référence pour l'audit d'invariance.

Actions : noter `git rev-parse HEAD` et `git status --short` dans `Diebolt/round5/T0_baseline.md` ; copier dans `Diebolt/round5/baseline/` : `generated/ceq_summary_values.tex`, `DT_CEQ_CIV2021.pdf`, et les dossiers `07_reports/tables/06`, `12`, `13`, `14`, `22`, `23`, `24`, `25` ; compter les flottants du corps (`\begin{table}`, `\begin{figure}`, `longtable` avant `\appendix`) et les pages du PDF ; compter les mots du résumé. Ne rien modifier d'autre.

---

## T1 — Calculs : S5 (pente alimentaire réestimée), S4 dans la chaîne I/O, $e_i^L \to \Delta P_0$, harmonisation 12/14 (opus, difficulté élevée)

Couvre : M1(i), M2, M3 (volet calcul), point mineur 1.

**À lire avant d'agir** : `referee_JAE.md` §3.2, §3.3, M1–M3, mineur 1 ; `replication_package/README.md` ; `05_scripts_R/00_master.R` ; `utils/vat_scenarios.R` ; `utils/informality_anchor.R` (fonctions `vat_unit_value_gradient`, `build_informality_anchor`, construction de `alpha_s4` l. 482–502) ; `06_01_sensitivity_taxation.R` ; `12_poverty_incidence.R` ; `13b_leontief_local_io.R` (bloc `conso_local`, `hh_local`, `io_scenarios`, `summary_macro`, `legal_sensitivity`) ; `14_leontief_poverty.R` (tribble `concepts`) ; `22_income_concepts.R` l. 1–60 (colonnes lues dans le parquet de 13b) ; `07_reports/tables/06/06_05_unit_value_gradient.xlsx` (feuilles `gradient`, `confrontation_s3`).

**Contrainte de données confirmée par le coordinateur (ne pas chercher ce qui n'existe pas)** : un scan exhaustif des 53 fichiers `.dta` de l'EHCVM 2021 (ménage, communauté, auxiliaires ; mots-clés lieu, marché, boutique, circuit, formel, informel, etc.) établit qu'**aucune variable ne code le lieu d'achat ni le mode d'acquisition formel/informel** des produits de consommation (modules 7A, 7B, 9). L'enquête ne pose pas cette question. Le canal formel/informel ne peut donc être identifié qu'indirectement, par les valeurs unitaires du module 7B ; T1 ne doit consacrer aucun temps à rechercher une variable de circuit d'achat.

**Étape préalable obligatoire : réestimer la pente de l'annexe B avec un contrôle de quantité.** Le modèle actuel de `vat_unit_value_gradient()` (`lm(prix_relatif ~ decile * taxe, weights = hhweight)`, l. ~375 de `informality_anchor.R`) ne contrôle pas la quantité achetée en une fois (`s07bq07a`, chargée dans `echantillon` sous le nom `quantite` mais absente du modèle). Un ménage aisé qui achète en plus grande quantité au même point de vente obtient un prix unitaire plus bas par simple remise de gros, sans lien avec le circuit taxé : la pente brute actuelle ($-0{,}29$ % par décile, IC $[-0{,}52 ; -0{,}06]$) confond cet effet de quantité avec l'effet de circuit. Avant toute construction de S5/S5′ :
1. Construire `log_quantite_relatif` = $\log(\text{quantite})$ centré à l'intérieur de chaque cellule produit × unité × conditionnement × région (même transformation intra-cellule que `prix_relatif`, pour que le contrôle reste un contrôle intra-cellule) ; ajouter ce régresseur au modèle : spécification principale `prix_relatif ~ decile * taxe + log_quantite_relatif`, et spécification de contrôle `prix_relatif ~ decile * taxe + log_quantite_relatif * taxe` (la remise de gros peut différer selon le groupe). Erreurs types agrégées par grappe comme aujourd'hui.
2. Publier dans `06_05_unit_value_gradient.xlsx` un tableau à trois colonnes (pente brute, pente avec contrôle de quantité, pente avec contrôle interagi) pour les produits non taxés, les produits taxés et la différence, avec erreurs types, $p$, IC à 95 %, coefficient de la quantité, et refaire la ligne « la pente impliquée par S3 est dans l'intervalle observé » pour chaque spécification.
3. La **pente corrigée** (spécification principale, coefficient `decile:taxe`) devient $\hat\pi$ pour S5′ et pour la confrontation à S3. Documenter explicitement si elle change de signe ou d'ampleur par rapport à la pente brute, et si l'IC corrigé contient ou non la valeur impliquée par S3 ($+0{,}55$ %). **Contingence** : si l'IC corrigé contient $+0{,}55$ %, le test de pente ne rejette plus S3 ; S5 (pente nulle) reste publié comme scénario de sensibilité, mais le mémo doit le dire en tête pour que T5 et T9 adaptent le message (le résultat de l'annexe B devient « non concluant après contrôle de quantité », pas « infirmé »). Si la pente corrigée reste négative et exclut $+0{,}55$ %, le message du rapporteur est confirmé et renforcé.

**Définition de S5 (à implémenter sur la pente corrigée, sauf raison documentée)** : pour la seule fonction COICOP 1 (alimentation), remplacer le profil S3 $\alpha_1(d) = 0{,}12 + (d-1)\times 0{,}034$ par un profil de **même niveau moyen mais de pente différente** : $\alpha_1^{S5}(d) = \bar\alpha_1 + (d - 5{,}5)\,s_5$, avec $\bar\alpha_1 = 0{,}12 + 4{,}5 \times 0{,}034 = 0{,}273$ (valeur de S3 au rang médian). Deux variantes : **S5** (« pente nulle ») avec $s_5 = 0$, et **S5′** (« pente estimée ») avec $s_5 = \hat\pi\,(1 + \bar\alpha_1 \tau)/\tau$, où $\hat\pi$ est la **pente corrigée** de l'étape préalable (différence taxés moins non taxés, avec contrôle de quantité) et $\tau$ le « taux de TVA moyen des produits taxés retenus » (inverse exacte de la formule des l. 414–415 de `informality_anchor.R`). Borner $\alpha$ dans $[0,1]$. Toutes les autres fonctions gardent S3. Tenir le niveau moyen constant isole l'effet de pente, ce que demande le rapporteur ; le dire dans le mémo. S5 est la variante à publier dans les tableaux ; S5′ est rapportée en texte/annexe.

**Modifications de code** :
1. `utils/vat_scenarios.R` : ajouter `vat_alpha_decile_s5(coicop, decile, slope_food)` (ou paramétrer `vat_alpha_decile`) sans changer le comportement des fonctions existantes.
2. `utils/informality_anchor.R` : (a) réestimation avec contrôle de quantité décrite ci-dessus, en conservant la pente brute dans les sorties pour comparaison ; (b) faire remonter la table `confrontation` (et $\tau$, $\hat\pi$ brut et corrigé) dans la liste renvoyée par `build_informality_anchor()`.
3. `06_01_sensitivity_taxation.R` : calculer `alpha_5`, `alpha_5b`, `vat_item_s5`, `vat_item_s5b`, agrégats `vat_s5*`, `_real`, `_pc`, `eff_vat_s5*`, `consumable_s5*`, ajouter S5 et S5′ à `scenarios`, à `bs_list` (bootstrap Kakwani 500 rép.) et aux exports ; **persister** une table `SILVER/06/alpha_scenarios_s4_s5.parquet` (colonnes `coicop_num`, `decile`, `alpha_4`, `alpha_5`, `alpha_5b`) pour la chaîne I/O ; ajouter les paramètres S5 à `06_03_vat_informality_parameters.xlsx`.
4. `12_poverty_incidence.R` : ajouter S5/S5′ partout où S4 apparaît ; corriger `total_new_poor` qui n'énumère que strict/s2/s3. **Diagnostiquer** l'écart 2,17/2,35 : comparer `pcexp - vat_s3/hhsize` (nominal) à `yd_pc - vat_direct_local_s3_real/hhsize` (étape 14) ; si la déflation explique l'écart, aligner l'étape 12 sur la convention réelle de l'étape 14 (celle du corps du texte) et documenter dans le mémo les nouvelles valeurs S1/S3/S4 de l'annexe B (aujourd'hui 6,10 / 2,17 / 3,52). Si un autre facteur subsiste (p. ex. `depan_w` vs périmètre TRE), le quantifier.
5. `13b_leontief_local_io.R` : lire la table persistée, joindre par (`coicop_num`, `decile`) après avoir **vérifié que `fiscal$decile` (13b) et `hh_decile$decile` (06_01, `weighted_ntile(pcexp, pcweight)`) coïncident** ; créer `alpha_s4`, `alpha_s5` et les colonnes `vat_direct_local_{s4,s5}_item`, `vat_emb_local_{s4,s5}_item`, agrégats et totaux, ajouter `"s4"`, `"s5"` à `io_scenarios` ; ne rien changer aux colonnes existantes.
6. `14_leontief_poverty.R` : ajouter au tribble `concepts` les lignes `cur_direct_s4`, `cur_total_s4`, `cur_direct_s5`, `cur_total_s5` et **`cur_total_s3_legal`** (`tax_var = "vat_total_local_s3_legal_real"`, M2) ; ajouter, pour chaque concept TVA, l'effectif pondéré de nouveaux pauvres (personnes) et la part de population appauvrie au sens Higgins–Lustig à l'étape TVA (perte et sous le seuil après TVA) dans une sortie `14_04_new_poor_by_scenario.xlsx` ; laisser S3 comme spécification centrale.

**Relances** : `lance_pipeline(6, 7)`, puis `lance_pipeline(13, 16)`, puis `lance_pipeline(23, 26)`. Vérifier ensuite : (a) `git diff --stat 00_documentation/working_paper/generated/ceq_summary_values.tex` vide (les 17 macros de tête sont invariantes) ; (b) `07_reports/tables/22/22_03_identity_checks.xlsx` toutes lignes `valide = TRUE` (tolérance 1e-6) et `18_05_ceq_identity_checks.xlsx` OK ; (c) valeurs S3 inchangées : masses 697,2 / 214,3 / 911,6 ; Kakwani 0,165 [0,157 ; 0,173] ; $\Delta P_0$ 2,35 [1,89 ; 2,87] et 3,54 [3,02 ; 4,10] ; Shapley 0,00849 etc. (comparer aux copies de T0) ; (d) `13_07_legal_deduction_sensitivity.xlsx` inchangé pour les masses.

**Livrable** : `Diebolt/round5/T1_resultats_calculs.md` contenant, avec chemin de la sortie source pour chaque nombre : en tête, le tableau des pentes (brute, corrigée, corrigée interagie) avec IC et le verdict sur la valeur impliquée par S3 ; pour S4, S5, S5′ — masse de TVA directe (13b), Kakwani + IC, RS, $\Delta P_0$ directe et directe + enchâssée + IC, nouveaux pauvres ; pour $e_i^L$ — $\Delta P_0$ + IC et écart à S3 ; le diagnostic 2,17/2,35 et les nouvelles valeurs de l'annexe B ; la confirmation d'invariance et d'identités ; la liste des scripts modifiés. Ne pas éditer le `.tex`, mais transmettre à T5 (qui possède l'annexe B) deux éléments de texte à intégrer en prose : (i) l'EHCVM 2021 ne contient aucune variable de lieu d'achat ou de mode d'acquisition formel/informel (modules 7A, 7B, 9), si bien que le canal ne peut être identifié qu'indirectement par les valeurs unitaires ; (ii) le contrôle intra-cellule de la quantité achetée est la meilleure correction disponible avec les données existantes contre la confusion entre remise de gros et circuit taxé, et la pente présentée est celle obtenue avec ce contrôle, la pente brute étant rapportée pour comparaison. Ces phrases présentent la correction comme un raffinement méthodologique de l'exercice, non comme une réponse au rapporteur.

---

## T2 — Classement alternatif indépendant de l'assiette (opus, difficulté moyenne)

Couvre : M4(ii) volet calcul. Dépend de T1.

**À lire** : `referee_JAE.md` §3.1(a), M4 ; `06_02_sensitivity_ranking.R` ; `22_income_concepts.R` (colonnes `yp_pc`, `yn_pc`, `yd_pc` du parquet `SILVER/22/…`) ; `utils/distributive.R` (`weighted_gini`, `weighted_conindex`, `bootstrap_kakwani`).

**Actions** : étendre `06_02_sensitivity_ranking.R` (ou ajouter un bloc en fin de script) pour calculer Kakwani et RS de la TVA (S1, S2, S3, S4, S5 ; TVA directe seule comme au tableau 3, et directe + enchâssée si les colonnes `vat_total_local_*_real` sont accessibles) sous trois classements : $Y_D$ (référence, doit reproduire 0,165 / 0,0076 sous S3), $Y_P$ reconstruit par tête (étape 22), et équivalent-adulte (déjà là). Optionnel, seulement si les variables logement/biens durables sont déjà dans `SILVER/01` : un indice d'actifs par ACP ; sinon l'écrire explicitement comme non fait. IC bootstrap Rao–Wu (500) sur le Kakwani sous $Y_P$ pour S3. Exporter `06_02_ceq_rankings_extended.xlsx`. Relancer `lance_pipeline(7, 7)` uniquement.

**Livrable** : `Diebolt/round5/T2_classements.md` avec le tableau Kakwani/RS par classement × scénario, l'écart au classement $Y_D$, et une phrase d'interprétation factuelle (de combien les indices se déplacent). Ne pas éditer le `.tex`.

---

## T3 — Bibliographie et insertions de littérature hors introduction (opus, difficulté moyenne)

Couvre : M5 (a)(b)(c), points mineurs 10, 11, 12, 14. Ne touche ni résumé, ni introduction, ni conclusion (T9 reformulera l'apport 1 avec les clés créées ici).

**À lire** : `referee_JAE.md` §5, M5, mineurs 10–14 ; `references.bib` en entier (38 notices ; noter que `younger2016` **et** `younger2017` existent déjà : vérifier s'il s'agit d'un doublon et résoudre) ; dans le `.tex` : §4.3 (`\subsection{TVA non déductible et propagation…}`), §4.2 (`\subsection{La séquence de revenus CEQ…}`, phrase sur la consommation mieux mesurée), §4.9 (`\subsection{Pensions, transferts directs et filets sociaux}`, passage PMT et `groshbaker1995`), §5.7 (`sec:res-transfers`, validation croisée, $R^2 = 0{,}571$), §5.3 (passage citant `chandler2025` s'il y en a un hors intro ; sinon noter que l'intro est du ressort de T9), `sec:limites`.

**Notices à ajouter, chacune vérifiée à la source (DOI/URL/éditeur, via WebSearch/WebFetch ; skill `bibcheck` ou `kris` pour contrôle)** : Ahmad & Stern 1984 (*Journal of Public Economics*, « The theory of reform and Indian indirect taxes ») ; Ahmad & Stern 1991 (CUP, *The Theory and Practice of Tax Reform in Developing Countries*) ; Rajemison & Younger 2000 (CFNPP Working Paper, Madagascar, I/O) ; Chen, Matovu & Reinikka 2001 (IMF WP, Ouganda) ; Sahn & Younger 2000 (*Fiscal Studies* 21(3)) ; Brown, Ravallion & van de Walle 2018 (*JDE* 134) ; Coady, Grosh & Hoddinott 2004 (Banque mondiale) ; Deaton & Zaidi 2002 (LSMS WP 135) ; Deaton 1997 (*The Analysis of Household Surveys*). Corriger `younger2016` (préférer Younger, Osei-Assibey & Oppong 2017, *Review of Development Economics*, et harmoniser la clé/l'année partout dans le `.tex`) ; basculer `atkinson1980` en `@incollection` (Aaron & Boskin dir., *The Economics of Taxation*, Brookings, avec titre de chapitre exact vérifié). Aucune notice sans source vérifiée.

**Insertions en prose** : en §4.3, un paragraphe situant la propagation I/O dans la tradition Ahmad–Stern et ses applications africaines (Madagascar, Ouganda), et précisant que la nouveauté est l'articulation à des probabilités de taxation hétérogènes par décile ; en §4.2, appui Deaton–Zaidi/Deaton à l'hypothèse d'ancrage ; en §4.9 et §5.7, Coady–Grosh–Hoddinott et Brown–Ravallion–van de Walle, avec comparaison explicite du $R^2 = 0{,}571$ aux ordres de grandeur de cette littérature (citer les valeurs exactes trouvées dans Brown et al., pas « 0,3 à 0,5 » sans source) et une explication candidate à vérifier dans `18_transfers.R` (région et variables corrélées à l'agrégat par construction) ; pour `chandler2025`, soit une confrontation factuelle de son contenu aux résultats du §5.3 (après lecture réelle du document), soit signaler à T9 que la revendication doit être atténuée. Compiler.

**Livrable** : compte rendu des clés ajoutées/modifiées avec sources de vérification, sections modifiées, et une note à l'intention de T9 (clés à citer pour l'apport 1 ; verdict sur `chandler2025`).

---

## T4 — Circularité classement/assiette, ancrage et limites (opus, difficulté moyenne)

Couvre : M4(i), correction de l'affirmation « se propage identiquement sans modifier les écarts », M4(ii) volet texte, point mineur 15, réserve sur la répercussion intégrale (§3.2 du rapport). Dépend de T2 et T3.

**À lire** : `referee_JAE.md` §3.1, §3.2 dernier paragraphe, M4, mineur 15 ; `T2_classements.md` ; dans le `.tex` : §4.2 (`\subsection{La séquence de revenus CEQ…}`, paragraphe nommant l'hypothèse d'ancrage), §5.1 (tableau `tab:vat-scenarios` et sa note), `sec:limites` paragraphe « Mesure des ressources… », `annexe:limites` point 3.

**Actions** : (i) en §4.2, un paragraphe discutant la circularité partielle : $Y_D$ est la consommation, la TVA en est une fonction, donc Kakwani et RS mesurent en partie une propriété du dispositif ; (ii) remplacer la phrase sur la propagation identique par une formulation exacte : vrai pour un décalage additif uniforme, faux pour une erreur corrélée au niveau de vie comme l'épargne, qui comprime l'inégalité au sommet et affaiblit la régressivité mesurée ; (iii) en §5.1, rapporter les Kakwani/RS sous classement $Y_P$ (et équivalent-adulte) issus de T2 et dire de combien ils se déplacent, soit dans la note du tableau 3, soit en un court paragraphe ; (iv) en `sec:limites` et `annexe:limites` point 3, ajouter l'hypothèse de répercussion intégrale de la TVA non déductible (marges fixes) et préciser que les variantes 75/50 % testent la collecte amont, non la répercussion. Compiler.

---

## T5 — Intégration textuelle des résultats S4, S5 et $e_i^L$ (opus, difficulté élevée)

Couvre : M1(i)(ii) hors résumé/intro, M2 volet texte, M3 volet texte, point mineur 1. Dépend de T1 (et de T4 pour l'ordre d'édition).

**À lire** : `referee_JAE.md` §3.2, §3.3, M1–M3, mineur 1 ; `T1_resultats_calculs.md` ; dans le `.tex` : §4.2 bis (`\subsection{TVA directe et probabilité de taxation effective}`, présentation des scénarios et renvoi à `annexe:ancrage`), §5.1 (`tab:vat-scenarios`), §5.2 (`tab:fgt-io`), §5.3 (`tab:io-robustness`, prose sur la sensibilité juridique), `annexe:s3-parameters`, `annexe:ancrage` (B.1 et B.2), `sec:limites` paragraphes « Incidence statique » et « Matrice de production ».

**Actions** : (i) tableau 3 : ajouter les lignes S4 et S5 (masse 13b, Kakwani + IC, RS) ; tableau 4 : ajouter S4 et S5 en « directe » et « directe + enchâssée » avec IC ; tableau 5 : remplir la case $\Delta P_0$ de la ligne $e_i^L$ avec IC et retirer la note « non recalculé » ; (ii) définir S4 et S5 dans §4.2 bis comme scénarios du corps du texte (S4 = borne haute ancrée sur l'offre remplaçant S1 comme borne de référence ; S5 = pente alimentaire compatible avec l'annexe B, niveau moyen conservé ; S5′ mentionnée) ; (iii) en §5.2, un paragraphe énonçant le sens du biais : une pente plus plate charge davantage le bas de la distribution, donc progressivité surestimée et appauvrissement sous-estimé sous S3, ce qui renforce la thèse ; chiffrer avec S5 ; (iv) en §5.3, réécrire le passage sur $e_i^L$ selon le résultat : si l'écart de $\Delta P_0$ est faible, en faire un argument de robustesse explicite ; s'il est grand, le présenter comme la principale incertitude du papier, ici et dans `sec:limites` ; (v) annexe B : mettre à jour les valeurs 6,10 / 2,17 / 3,52 selon le diagnostic de T1, expliciter la convention (réelle, identique au corps) pour clore le mineur 1, et ajouter une phrase renvoyant à S5 comme conséquence tirée du test de pente ; (vi) `annexe:s3-parameters` : ajouter les paramètres de S5/S5′. Ne pas modifier les chiffres S3. Compiler.

---

## T6 — Requalification de la décomposition de Shapley sur la pauvreté et de l'efficacité d'impact (opus, difficulté moyenne)

Couvre : M7(i)(ii), points mineurs 2 et 4. Dépend de T5 (ordre).

**À lire** : `referee_JAE.md` §4.2(a)(b), M7, mineurs 2 et 4 ; dans le `.tex` : `\subsection{Du revenu primaire au revenu final…}` (texte autour de `tab:shapley-pauvrete`, `fig:shapley-poverty`, passage Atkinson–Plotnick, passage Enami et la phrase « seuls impôts indirects … 3,54 points ») ; sorties `07_reports/tables/23/` (Shapley pauvreté, efficacité d'impact, budgets utilisés) et `20_03_budget_reconciliation.xlsx`.

**Actions** : (i) réorganiser `tab:shapley-pauvrete` en deux blocs avec sous-totaux : bloc monétaire (impôts indirects −4,23, prélèvements directs −0,14, paiements directs +0,39, réductions de prix +0,09 ; somme −3,89, hausse nette de la pauvreté monétaire) et bloc en nature (éducation +7,09, santé +0,60) ; vérifier les sous-totaux à partir des sorties de l'étape 24 ; (ii) réécrire le paragraphe « c'est là le point central » pour faire porter le message sur le bloc monétaire et qualifier la contribution de l'éducation comme un contrefactuel de versement en espèces au coût de production ; (iii) efficacité d'impact : soit la retirer, soit la restreindre au bloc monétaire (préférer la seconde option si les sorties permettent de la recalculer sans nouveau code ; sinon retirer et le dire) ; (iv) mineur 2 : retrouver dans les sorties de l'étape 24 l'origine du « 1 316 milliards » et remplacer par la valeur exacte avec sa définition (brut 1 354,87, net 1 301,62, ou budget réel utilisé par l'indicateur) ; (v) mineur 4 : « l'étape des seuls impôts indirects accroît la pauvreté de 3,54 points » → « la seule TVA » (l'ensemble des impôts indirects donne +4,72). Compiler.

---

## T7 — Comparaison quantitative avec les applications CEQ africaines (opus, difficulté élevée)

Couvre : M6. Recherche documentaire réelle. Peut commencer en parallèle de T1–T2 (lecture, collecte), mais n'édite `references.bib` et le `.tex` qu'après T3 et T6.

**À lire** : `referee_JAE.md` §4.2(c), M6 ; dans le `.tex` : `\subsection{Validation externe et comparaison avec l'ENV 2014}` (`tab:akim`) ; `references.bib` (clés existantes : `younger2016`/`younger2017`, `hill2017`, `higgins2016`, `lustig2017`, `akim2020`).

**Actions** : charger WebSearch/WebFetch via ToolSearch ; constituer pour quatre à six pays (Ghana, Tanzanie, Éthiopie, Ouganda, Afrique du Sud, Togo si une application CEQ publiée existe, sinon Zambie/Namibie/Comores) trois indicateurs : RS (ou variation de Gini) du passage au revenu consommable, $\Delta P_0$ disponible → consommable, part de population appauvrie au sens Higgins–Lustig. Sources à privilégier : les articles CEQ par pays (Younger, Osei-Assibey & Oppong 2017 ; Younger, Myamba & Mdadila 2016 ; Hill et al. 2017 ; Jellema, Lustig, Haas & Wolf ; Inchauste et al. pour l'Afrique du Sud), Higgins & Lustig 2016 (*JDE*, indicateurs d'appauvrissement pour plusieurs pays), Lustig 2016/2018 (*Fiscal policy, inequality and the poor…*), le CEQ Data Center (Standard Indicators). **Chaque chiffre doit être lu dans la source** (page/tableau notés) ; toute valeur introuvable est laissée vide avec mention « non publié », jamais estimée. Noter les différences de champ (seuil de pauvreté utilisé, année, concept de revenu de classement, TVA enchâssée incluse ou non). Ajouter les notices vérifiées à `references.bib` (pas de doublon avec T3). Rédiger, dans §5.11, un tableau `tab:comparaison-ceq-afrique` et deux ou trois paragraphes situant le cas ivoirien (4,35 % appauvris, RS, $\Delta P_0$) ; renommer la sous-section si nécessaire. Compiler.

**Livrable** : compte rendu avec, pour chaque cellule du tableau, la source et l'emplacement exact ; liste des notices ajoutées.

---

## T8 — Développer la section 6 (Simulations de réformes) et aligner le passage PMT (opus, difficulté moyenne)

Couvre : M8(v), M9 volet corps de texte, point mineur 5. Possède `sec:reformes` uniquement.

**À lire** : `referee_JAE.md` §6.2(f), M8(v), M9, mineur 5 ; `sec:reformes` en entier ; `07_reports/tables/15/`, `25/25_02_reform_delivery_sensitivity.xlsx` ; notice `worldbankpssn2015` et `18_transfers.R` (paramètres PSSN : 191 767 ménages, 27,1 milliards).

**Actions** : (i) mineur 5 : uniformiser l'ordre agricole/large dans le paragraphe des recettes et des nouveaux pauvres (1 455 et 1 404 doivent correspondre au bon ordre ; vérifier dans les sorties de l'étape 16) ; (ii) développer la sous-section 9 % en trois directions, en prose sourcée : faisabilité administrative d'un transfert universel forfaitaire (registre, canal de paiement mobile, couverture), coût de gestion observé du PSSN (chercher le ratio coûts administratifs/transferts dans les documents Banque mondiale du projet Filets sociaux productifs Côte d'Ivoire — PAD 2015, rapports d'achèvement ou de supervision — via WebSearch/WebFetch, et citer précisément ; à défaut, citer les fourchettes documentées par Coady–Grosh–Hoddinott 2004 ou Grosh et al. 2008 et ajouter la notice vérifiée), ordre de grandeur de la fuite (erreurs d'inclusion/exclusion du PMT simulé dans `18_02_coverage_targeting.xlsx` comme borne interne, littérature Brown et al. 2018 comme repère externe) ; (iii) M9 : dans le passage comparant universel et ciblé, expliciter que le 37,21 % du ciblage est obtenu sur les mêmes observations que l'estimation du score et ne constitue pas une performance de registre. Ne pas toucher aux chiffres du tableau `tab:reforme`. Compiler.

---

## T10 — Restructuration : matériel supplémentaire, réduction des flottants, figures exploitées (opus, difficulté élevée)

Couvre : M8(iii)(iv), points mineurs 16 et 19. Dépend de T5–T8. Précède T9.

**À lire** : `referee_JAE.md` §4.3, §6.2(a), M8, mineurs 16 et 19 ; la liste des 37 flottants (`grep -n "\\label{tab:\|\\label{fig:" DT_CEQ_CIV2021.tex`) ; `replication_package/exhibit_map.csv` ; préambule du `.tex` (l. 1–55, `\graphicspath`, `\input{generated/…}`, `\thanks` citant `annexe:pipeline`).

**Actions** :
1. Créer `00_documentation/working_paper/DT_CEQ_CIV2021_supplement.tex` (même préambule, même `references.bib`, même `\input{generated/ceq_summary_values}`, titre « Matériel supplémentaire », sections numérotées S1, S2…) et y déplacer, sans perte de contenu : le lexique (`tab:lexique`), le tableau des informations du questionnaire (`tab:variables-questionnaire`), la passerelle 52 → 48 (`tab:mapping-52-48`, avec le texte de `annexe:mapping-io` qui l'accompagne), l'inventaire du pipeline (`tab:inventaire-pipeline`) et l'ensemble de `annexe:pipeline` (`tab:acces-replication` inclus). Dans le corps, remplacer chaque `\ref` vers ces objets par une mention textuelle « matériel supplémentaire, section S.x » ; mettre à jour le `\thanks` de la page de titre.
2. Ramener les flottants du corps (avant `\appendix`) à dix à douze. Proposition de conservation, à ajuster avec justification écrite : `tab:vat-scenarios`, `tab:fgt-io` (fusionner éventuellement avec `tab:io-robustness`), `tab:income-complete`, `tab:concepts-inference`, `tab:shapley-pauvrete`, `tab:comparaison-ceq-afrique` (T7), `tab:reforme`, `fig:vat-scenarios`, `fig:income-complete` ou `fig:shapley-poverty`, `fig:fiscal-impoverishment`, `fig:reform-recycling`. Les autres (`tab:descriptif`, `tab:other-indirect`, `tab:direct`, `tab:direct-scenarios`, `tab:transfers`, `tab:macro-validation`, `tab:akim`, figures `ceq-cascade`, `vat-chain`, `io`, `other-indirect`, `direct`, `transfers`, `subsidies`, `education-inkind`, `health-inkind`, `shapley`) sont déplacés en annexe du même PDF (nouvelle annexe « Tableaux et figures complémentaires », labels conservés pour que tous les `\ref` restent valides) ou supprimés seulement si le texte n'y renvoie plus et si l'information est intégralement portée par la prose ; chaque suppression est listée. La prose qui les commentait doit rester cohérente (renvois « en annexe »).
3. Mineur 16 : chaque figure conservée dans le corps reçoit une phrase disant ce qu'on y lit qui n'est pas dans le texte ; les figures 8, 9 et 11 signalées par le rapporteur (`fig:other-indirect`, `fig:direct`, `fig:transfers`) sont soit exploitées soit déplacées.
4. Mineur 19 : `[h]` → `[t]` pour `tab:bareme-igr` et `tab:s3-matrix` ; vérifier la mise en page après compilation.
5. Compiler les deux documents ; zéro référence indéfinie ; pages et nombre de flottants du corps consignés.

**Livrable** : tableau des flottants (label → corps / annexe / supplément / supprimé, justification) pour T11 (exhibit_map) et pour l'audit.

---

## T9 — Cadrage : titre, résumé, introduction, conclusion, page de titre (opus, difficulté élevée)

Couvre : M8(i)(ii), M1(iii), M3 (résumé et conclusion), M5 (reformulation de l'apport 1), M9 (conclusion), points mineurs 6, 7, 8, 9, 13, 17, 18, 20. Dépend de tout ce qui précède. Possède : `\title`, `\author`, `\date`, `\thanks`, `abstract`, mots-clés, codes JEL, `sec:intro`, `sec:conclusion`.

**À lire** : `referee_JAE.md` §2.2, §6.2(b)(c)(d)(e), M1(iii), M3, M5, M8(i)(ii), M9, mineurs 6–9, 13, 17, 18, 20 ; `T1_resultats_calculs.md`, `T2_classements.md`, le compte rendu de T3 (clés, verdict `chandler2025`), de T7 (repères africains) et de T10 (structure finale) ; skill `econ-write` pour la structure résumé/introduction.

**Actions** : (i) titre recentré sur la thèse « le critère de mesure détermine le classement des instruments », Côte d'Ivoire comme cas ; (ii) résumé **sous 150 mots** contenant : l'inversion de hiérarchie Gini/pauvreté, le reclassement démographique induit par l'éducation (43,8 %), l'appauvrissement monétaire (macros `\PauvretePrimaire`, `\PauvreteConsommable`, `\PartNouveauxPauvres`), et la réserve de l'annexe B (le gradient alimentaire postulé n'est pas soutenu par les prix payés ; S5 chiffré) ; (iii) introduction réécrite pour poser question, tension et contribution sans répéter le résumé : apports reformulés (l'articulation I/O × probabilités hétérogènes par décile est ce qui est neuf, avec les clés de T3 ; la matrice S3 est une hypothèse imposée, testée en annexe B, infirmée pour l'alimentation, S5 en tire la conséquence ; S4 remplace S1 comme borne haute de référence, avec ses chiffres), résultats transportables mis en avant, repères africains de T7 en une phrase, paragraphe de plan sans le fragment corrompu (mineur 6) ; corriger « quantities » (mineur 7) ; (iv) conclusion : remplacer « +7,07 sous S1 » par la borne S4 (M3), aligner le passage PMT sur la réserve de §6.2 (M9 : renoncer à la comparaison chiffrée universel/ciblé ou la qualifier explicitement), refondre la dernière phrase (mineur 8, « intégrait » → « intégrant » ou refonte), intégrer le résultat $e_i^L$ selon T1 ; (v) page de titre : auteur correspondant et adresse électronique (demander au relayeur la valeur ; sinon `franckmigone@gmail.com` pour Franck Migone si le contexte l'identifie comme auteur principal), JEL ajouter H23 et H53, date « Septembre 2026 ». Compiler ; recompter les mots du résumé.

---

## T11 — Synchronisation finale et point mineur 3 (sonnet, difficulté moyenne)

Dépend de T9.

**Actions** : (i) mineur 3 : dans `sec:res-direct`, expliciter le dénominateur des « 42,7 % des salariés rémunérés » à partir de `07_reports/tables/16/16_07_robustness_diagnostics.xlsx` et `16_08_sample_description.xlsx` (2,413 millions ⇒ 45,0 % ; ou autre dénominateur à nommer) ; (ii) resynchroniser `replication_package/exhibit_map.csv` avec le tableau de T10 (nouveaux labels, objets déplacés vers le supplément, nouveaux producteurs : `14_04_new_poor_by_scenario.xlsx`, `06_02_ceq_rankings_extended.xlsx`, tableau comparatif T7 avec sources externes) ; (iii) ajouter à `quality_reports/reproducibility_claims_DT_CEQ_CIV2021.json` les claims C31+ pour toutes les nouvelles valeurs (S4, S5, S5′, $e_i^L$, classements, sous-totaux Shapley) avec leurs sources, disposition à remplir par l'audit ; (iv) mettre à jour `replication_package/README.md`, `output/expected_metrics.csv` si le vérificateur `01_verify_outputs.R` en dépend, `00_documentation/MEMOIRE_PARTAGEE_CEQ_CIV2021.md` et `project_state.md` (nouveaux scénarios, nouvelle convention de l'étape 12, supplément) ; (v) compilation finale des deux PDF, copie `DT_CEQ_CIV2021_v23.pdf`, sweep orthographique rapide (`adulte contributif participant`, anglicismes). Ne pas committer.

---

## T12 — Audit global (opus)

**Modèle proposé : opus.** Justification : l'audit de ce tour n'est plus une relecture d'invariance numérique ; il doit (a) relire les diffs R de T1/T2 et rejouer les vérifications d'identités (`22_03`, `18_05`, tolérance 1e-6) et l'invariance des sorties S3 et des 17 macros contre la référence T0 ; (b) contrôler la définition de S5 (niveau moyen conservé, formule de pente inverse de celle de `informality_anchor.R`, bornes) et la cohérence décile 06_01/13b ; (c) reproduire les nouveaux chiffres du texte à partir des xlsx (claims C31+) ; (d) vérifier à la source les notices ajoutées par T3 et T7 (skill `bibcheck`/`kris`) et chaque cellule du tableau comparatif ; (e) juger la restructuration au standard *JAE* (résumé < 150 mots, corps ≈ 10–12 flottants, intro non redondante, aucune liste dans le corps, renvois valides, supplément compilable) ; (f) vérifier point par point M1–M9 et mineurs 1–20 contre `referee_JAE.md` et produire une matrice de couverture (traité / partiellement / non traité, avec emplacement). Opus a produit le rapport de référé : il est calibré sur ce standard, dispose des outils d'exécution R et web nécessaires, et l'audit reste ainsi indépendant du planificateur (Fable), qui n'a pas à auditer son propre découpage. Fable n'intervient qu'ensuite pour arbitrer les corrections que l'audit propose.

**Livrable de l'audit** : `Diebolt/round5/audit_round5.md` avec la matrice de couverture, les vérifications numériques (PASS/FAIL par claim), les identités, la liste des corrections à appliquer classées par gravité, et la mise à jour de `quality_reports/reproducibility_audit_DT_CEQ_CIV2021.md`.
