# État du projet CEQ Côte d'Ivoire 2021

Dernière mise à jour : 10 août 2026.

## Version v22 — trois extensions analytiques

- **Décomposition de Shapley de la pauvreté.** L'étape 24 décompose désormais la
  variation de l'incidence (FGT0) et de la profondeur (FGT1) de la pauvreté sur
  les mêmes six groupes d'instruments, avec bootstrap Rao-Wu. Éducation +7,09
  points de réduction, santé +0,60, paiements directs +0,39, réductions de prix
  +0,09; impôts indirects −4,23, prélèvements directs −0,14. Total +3,80. Aucun
  intervalle ne contient zéro.
- **Reclassement (Atkinson-Plotnick).** RS = équité verticale − reclassement.
  Sur toute la cascade, le reclassement absorbe 21,8 % de l'effet vertical; il
  atteint 43,8 % à l'étape des services en nature et 41,6 % pour l'éducation
  seule.
- **Indicateurs d'efficacité CEQ (Enami).** Efficacité d'impact : prélèvements
  directs 0,72, santé 0,28, impôts indirects 0,18, éducation 0,07, paiements
  directs 0,06, réductions de prix négative.
- **Intervalles de sondage sur le tableau central.** Les écarts entre concepts
  consécutifs sont tous significatifs; les niveaux de Gini ont en revanche un
  intervalle large (0,325 à 0,355 au revenu primaire).
- **Ancrage ivoirien du profil S3** (`05_scripts_R/utils/informality_anchor.R`).
  Le module 10 de l'EHCVM (entreprises non agricoles des ménages) fournit une
  borne supérieure nationale sur α : S3 la respecte dans les sept fonctions où
  elle est exploitable. Le scénario S4 place α à cette borne et remplace la
  borne haute théorique de S1 : la TVA directe accroît alors la pauvreté de
  3,52 points au lieu de 6,10. Les valeurs unitaires du module 7B donnent en
  revanche un gradient de prix par décile de −0,29 % (taxés moins non taxés,
  p = 0,012), incompatible avec les +0,55 % qu'impliquerait la pente
  alimentaire de S3.
- **Validation hors échantillon du PMT.** Validation croisée en cinq blocs par
  grappe : part de bénéficiaires pauvres 85,9 % en échantillon contre 84,2 %
  hors échantillon; R² pondéré 0,571 contre 0,561; corrélation des rangs 0,998.
  La sélection centrale est inchangée.
- **Appareil.** `\input{generated/ceq_summary_values}` est branché et le jeu de
  macros complété (Gini et pauvreté des six concepts, virgule décimale). Les
  décomptes « 34 » codés en dur de `01_verify_outputs.R` sont remplacés par des
  décomptes calculés. Prévol 41 PASS, vérification 47 PASS, 0 FAIL.
- **PDF v22** : 61 pages, aucune citation ni référence indéfinie, zéro
  débordement. Reprise intégrale du 10 août 2026 en 765,6 secondes; tous les
  résultats centraux de v21 sont reproduits à l'identique.

## État antérieur (23 juillet 2026)

## État général

- Le pipeline CEQ expose 26 étapes et la cascade est complète jusqu'au revenu
  final.
- La chaîne a été rejouée depuis les données préparées jusqu'au rapport final :
  les 26 étapes ont toutes abouti lors de la reprise intégrale du 23 juillet 2026.
- Deux jointures devenues ambiguës lors d'une reprise entièrement fraîche ont
  été corrigées aux étapes 7 et 13; elles ne changent ni les définitions ni les
  résultats, mais garantissent la reproductibilité depuis zéro.
- Le working paper courant est
  00_documentation/working_paper/DT_CEQ_CIV2021_v21.pdf (54 pages).
- La compilation ne contient aucune citation ni référence indéfinie.
- Révision éditoriale du 19 juillet : résumé ramené à 142 mots; introduction et
  conclusion recentrées sur le résultat économique; termes techniques définis;
  numéros de questions, modules, postes et tables internes retirés du texte
  principal et réservés à l'annexe de réplication.
- La version v15 a passé les contrôles de langue, de voix, de bibliographie, de
  cohérence numérique et une troisième simulation de rapporteurs.
- La version v16 regroupe les limites en cinq thèmes dans le corps du papier et
  conserve les dix diagnostics techniques dans une annexe dédiée.
- La version v17 répond aux neuf remarques Refine.ink : matrice S3 publiée,
  distinction entre taux légal, droit à déduction et collecte à la vente finale,
  sensibilité juridique de la TVA incorporée, scénarios d'impôts directs rendus
  comparables, robustesse PSSN « déclarations d'abord », unités CEQ harmonisées
  et protocole de réplication explicite pour un économiste ou un agent.
- La version v18 remplace l'ouverture de l'introduction par une formulation
  institutionnellement neutre et aligne le README de la branche rewrite-r sur
  la chaîne CEQ complète, ses données et son protocole de réplication.
- La version v19 intègre les remarques externes du 20 juillet 2026 : introduction plus courte, S1/S2/S3 explicités, assiettes et cascades de TVA clarifiées, convention Reynolds--Smolensky standard, base IGR corrigée, robustesses structurelles ajoutées, et rapport de réponse archivé sous 00_documentation/working_paper/Diebolt/round4/.
- La version v20 est la version de clôture de la session : elle allège le résumé, clarifie le premier paragraphe de l'introduction, rend la limite sur S3 plus lisible et reformule l'implication de réforme dans la conclusion. Le PDF compile en 53 pages sans erreur LaTeX ni renvoi manquant.
- La version v21 formalise le plan de sondage EHCVM dans les régressions de TVA : poids ménage, 66 strates et grappes via `survey::svyglm`. Les coefficients ponctuels sont stables, mais le terme quadratique S3 n'est plus significatif (`p = 0,157`). Le PDF compile en 54 pages sans citation, renvoi ou débordement indéfini.
- Le classeur final est
  07_reports/tables/25/CEQ_CIV_2021_master.xlsx.
- La reprise intégrale la plus récente s'est terminée le 23 juillet 2026 en
  452,17 secondes : 41 contrôles de prévol et 32 contrôles finaux réussis, aucun
  échec. Le journal est
eplication_package/output/logs/full_run_20260723_030556.log. Les 33 labels de tableaux et figures
  sont tous reliés à une sortie et à un script.

## Résultats centraux

- Régression de sondage S3 : coefficient du logarithme de la consommation 0,01251 (erreur-type 0,000447); terme quadratique non retenu (`p = 0,157`). Ces corrélations sont descriptives, non causales.
- TVA finale directe : 697,2 milliards; TVA enchâssée : 214,3 milliards;
  TVA totale ménages : 911,6 milliards de FCFA.
- Accises : 67,9 milliards; droits de douane : 185,1 milliards.
- Paiements publics directs : 125,798 milliards, dont PSSN 27,108,
  bourses 6,090, prestations familiales 84,324 et AT/MP 8,276 milliards.
- Réductions publiques de prix : 25,15 milliards, dont électricité 8,69
  et eau 16,46; le carburant central vaut zéro faute de prix de parité 2021
  comparable.
- Éducation publique : 1 354,87 milliards au coût public et 1 301,62
  milliards nets des paiements directs des familles.
- Santé publique : 108,53 milliards au coût public et 81,85 milliards nets.
- Gini : 0,3409 au revenu primaire, 0,3336 au revenu disponible,
  0,3247 au revenu consommable et 0,3167 au revenu final.
- Pauvreté : 37,72 % au revenu primaire, 42,04 % au revenu consommable et
  33,92 % au revenu final.
- Nouveaux pauvres entre revenu primaire et revenu consommable : 4,35 %.
  Pertes sous le seuil : 142,84 milliards; gains : 9,35 milliards.

## Choix méthodologiques à préserver

- Le scénario de pension central est PDI : pensions contributives déjà
  comprises dans les ressources initiales et cotisations retraite traitées
  comme épargne obligatoire. PGT est la robustesse.
- Le PSSN utilise un PMT pondéré expliquant le logarithme du revenu disponible
  par personne à partir de la taille, du milieu, de la région, des
  caractéristiques du chef et de la composition démographique. Le classement
  détermine deux cohortes proches de 177 000 et 192 000 ménages. Le montant
  trimestriel est de 36 000 FCFA; le facteur de calage monétaire est 1,000739.
- Les déclarations de réception d'un programme monétaire ne déterminent pas la
  sélection centrale du PSSN. Elles interviennent seulement dans une robustesse
  qui retient d'abord les ménages déclarants, puis complète la cible par le PMT.
- Une non-réponse à un indicateur d'emploi ne constitue jamais un indice
  d'emploi formel. Le diagnostic de non-réponse conserve le classement central
  et publie seulement les effectifs concernés.
- Le profil S3 est une hypothèse exogène, non une calibration sur une cible
  ivoirienne. La sensibilité juridique fait passer la TVA incorporée estimée de
  214,3 à 22,3 milliards de FCFA; elle révèle la dépendance au proxy de droit à
  déduction et ne désigne pas 22,3 milliards comme une nouvelle valeur centrale.
- Le statut d'assurance maladie déclaré dans l'EHCVM n'est jamais utilisé dans
  l'allocation centrale de santé.
- Les consultations publiques reçoivent une dépense publique moyenne attendue
  par âge, sexe et milieu; les hospitalisations suivent les séjours observés
  sur douze mois.
- Les agrégats ANStat sont des contrôles de périmètre, non des cibles de calage.
- Aucun graphique des étapes 18 à 25 n'utilise de violet.

## Contrôles macroéconomiques

Les sources officielles archivées sont les Comptes nationaux annuels définitifs
2023 et l'Annuaire des statistiques économiques 2023 de l'ANStat. Pour 2021,
la consommation finale des ménages vaut 26 754 milliards, les impôts nets sur
les produits 3 074 milliards, la branche enseignement 2 971 milliards et la
branche santé 743 milliards. Les comptes définitifs portent la consommation
des ménages à 34 059 milliards en 2023; l'annuaire antérieur indiquait encore
32 721 milliards. Le papier documente cette révision de millésime.

## Limites restantes

- Effets indirects des droits de douane et des accises carburant à propager.
- Prix de parité carburant 2021 insuffisamment documenté.
- Référence AT/MP encore issue du matériel technique CEQ.
- Revenus indépendants, fonciers et mobiliers encore incomplets.
- Comparabilité imparfaite entre budgets attribuables aux ménages et agrégats
  exhaustifs des comptes nationaux.

Le working tree contient des modifications de l'utilisateur : ne rien restaurer
ou écraser en dehors de la tâche.
