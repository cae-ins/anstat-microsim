# État du projet CEQ Côte d'Ivoire 2021

Dernière mise à jour : 19 juillet 2026.

## État général

- Le pipeline CEQ expose 26 étapes et la cascade est complète jusqu'au revenu
  final.
- La chaîne a été rejouée depuis les données préparées jusqu'au rapport final :
  les étapes 1 à 13, puis 14 à 26, ont toutes abouti le 19 juillet 2026.
- Deux jointures devenues ambiguës lors d'une reprise entièrement fraîche ont
  été corrigées aux étapes 7 et 13; elles ne changent ni les définitions ni les
  résultats, mais garantissent la reproductibilité depuis zéro.
- Le working paper courant est
  00_documentation/working_paper/DT_CEQ_CIV2021_v17.pdf (52 pages).
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
- Le classeur final est
  07_reports/tables/25/CEQ_CIV_2021_master.xlsx.
- La reprise intégrale la plus récente s'est terminée le 19 juillet 2026 en
  350,4 secondes : 40 contrôles de prévol et 32 contrôles finaux réussis, aucun
  échec ni avertissement dans le journal. Les 34 labels de tableaux et figures
  sont tous reliés à une sortie et à un script.

## Résultats centraux

- TVA directe et non déductible : 907,3 milliards de FCFA.
- Accises : 67,9 milliards; droits de douane : 185,1 milliards.
- Paiements publics directs : 125,798 milliards, dont PSSN 27,108,
  bourses 6,090, prestations familiales 84,324 et AT/MP 8,276 milliards.
- Réductions publiques de prix : 25,15 milliards, dont électricité 8,69
  et eau 16,46; le carburant central vaut zéro faute de prix de parité 2021
  comparable.
- Éducation publique : 1 354,87 milliards au coût public et 1 301,62
  milliards nets des paiements directs des familles.
- Santé publique : 108,53 milliards au coût public et 81,85 milliards nets.
- Gini : 0,3414 au revenu primaire, 0,3336 au revenu disponible,
  0,3248 au revenu consommable et 0,3168 au revenu final.
- Pauvreté : 37,70 % au revenu primaire, 42,01 % au revenu consommable et
  33,90 % au revenu final.
- Nouveaux pauvres entre revenu primaire et revenu consommable : 4,34 %.
  Pertes sous le seuil : 142,73 milliards; gains : 9,30 milliards.

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
  214,4 à 22,3 milliards de FCFA; elle révèle la dépendance au proxy de droit à
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