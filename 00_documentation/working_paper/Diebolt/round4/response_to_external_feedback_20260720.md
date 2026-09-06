# Réponse aux remarques externes du 20 juillet 2026

## Révision d’ensemble

Les 25 remarques ont été examinées dans le manuscrit et, lorsque nécessaire, dans les programmes R. La révision ne se limite pas à la rédaction : la convention de Reynolds–Smolensky, la formule de l’IGR et la décomposition de la TVA ont été corrigées, puis les 26 étapes ont été réexécutées. Le document utilise désormais exclusivement les résultats de cette nouvelle exécution.

L’introduction a été raccourcie et distingue maintenant clairement les passages du revenu primaire au revenu disponible, puis du revenu disponible au revenu consommable. L’hypothèse d’informalité est encadrée par S1, S2, S3, deux déplacements de S3, deux taux de collecte amont et une imputation des dépenses non raccordées. Les simulations de réforme comparent le transfert universel et le ciblage PMT, avec ou sans coût de distribution. Enfin, les conventions de valorisation de l’éducation, de la santé et de l’électricité sont quantifiées dans une table de robustesse du revenu final.

## Réponses point par point

1. **Direction du franchissement du seuil — corrigé.** Le résumé, l’introduction, les résultats et la conclusion indiquent désormais que 4,35 % de la population « franchit le seuil national à la baisse ».

2. **Base de comparaison du taux de pauvreté — corrigé.** Le texte distingue la variation de 4,32 points entre revenu primaire et revenu consommable, qui couvre toute la cascade monétaire, de l’effet de 3,54 points des seuls impôts indirects à partir du revenu disponible.

3. **S1 non nommé — corrigé.** S1 désigne partout la transmission intégrale. S2 et S3 sont définis symétriquement dans l’introduction, le lexique, la méthode, les résultats et les limites.

4. **Valeurs d’usage — corrigé dans les données et le code.** L’étape 1 ne retient que le mode d’acquisition « achat ». Valeurs d’usage, autoconsommation, dons et loyers imputés restent dans le niveau de vie officiel mais ne reçoivent aucune taxe simulée. Les lignes 98 et 99 de la matrice S3 sont conservées uniquement pour documenter les paramètres.

5. **Winsorisation — documenté et quantifié.** Elle est appliquée avant agrégation sur les lignes ménage × produit, à partir de quantiles non pondérés propres à chaque produit. Par rapport au P99, P95 réduit la masse de 5,59 % et la pauvreté après TVA de 0,23 point; P99,5 les relève de 0,99 % et 0,05 point; sans winsorisation, les écarts sont de 1,96 % et 0,07 point. Sortie : `07_reports/tables/03/03_02_winsorization_sensitivity.xlsx`.

6. **Population pondérée — expliqué et sourcé.** Les 30,09 millions sont comparés aux 29,389 millions du RGPH 2021, soit +2,4 %. Les poids officiels EHCVM sont conservés, car leur calibration et leur période de référence diffèrent du recensement; aucun recalage ex post n’est imposé.

7. **Taille moyenne des ménages — expliqué.** Le tableau précise que 4,62 est une moyenne pondérée par le poids ménage, alors que 64 491 / 12 965 = 4,97 est le rapport brut.

8. **Ordre de la cascade des accises — corrigé.** Le lexique et la méthode indiquent l’ordre droits de douane → accise → TVA; l’accise entre dans la base de la TVA mais n’est pas calculée après celle-ci.

9. **Sens du terme IRPP — clarifié.** IRPP est défini comme un agrégat de restitution propre au papier, égal à IS + CN + IGR simulés, et non comme un impôt juridique ivoirien unifié.

10. **Convention de Reynolds–Smolensky — corrigée dans le code et le texte.** Le papier suit désormais `RS = G_avant − G_après`; une valeur positive indique une baisse de l’inégalité. Les scripts 05, 06_01, 06_02 et la fonction distributive partagée ont été corrigés, puis réexécutés.

11. **Équation de charge des ménages — corrigé.** L’équation emploie « TVA enchâssée » pour la charge propagée jusqu’au prix du ménage. « TVA non déductible » reste réservé au coût qui naît chez l’entreprise.

12. **Réaffectation des marges — formule ajoutée.** Les marges retirées de chaque produit sont sommées par branche utilisatrice, puis ajoutées aux lignes commerce et transport de la même colonne. La règle n’est ni uniforme entre colonnes ni une disparition hors matrice.

13. **Hypothèse de technologie — clarifié.** Avec les orientations utilisées dans le code, `B` est produits × branches et `T = V' ĝ⁻¹` est branches × produits; `A = B T` est donc produits × produits. Le manuscrit donne maintenant les dimensions et cite le manuel d’Eurostat. Une écriture `D B` suppose l’orientation transposée des matrices et ne peut pas être substituée littéralement à ces dimensions.

14. **Rayon spectral — clarifié.** `A^m` n’est jamais inversée : elle n’entre que dans le coût importé du premier tour. Seule `A^d` est itérée; `ρ(A^d) < 1` est donc la condition suffisante.

15. **Dépenses non raccordées — explicité et testé.** Au centre, elles supportent leur TVA finale éventuelle mais une TVA enchâssée nulle. Une robustesse leur impute le taux moyen de leur fonction COICOP, puis la moyenne nationale si nécessaire. La masse passe de 911,6 à 926,2 milliards et l’effet pauvreté de 3,54 à 3,58 points.

16. **Cascade additive — corrigée.** La décomposition utilise maintenant la cascade multiplicative `(1+c)(1+τ)`. La TVA finale est `d τ/(1+τ)` et la TVA enchâssée formelle est `d/(1+τ) × c/(1+c)`. Les sorties des étapes 13 à 26 ont été recalculées.

17. **Informalité amont — hypothèse déclarée et robustesses ajoutées.** Le centre suppose les chaînes retracées par le TRE déclarées. Des variantes fixent la collecte amont à 75 % et 50 %; l’augmentation de pauvreté reste respectivement de 3,29 et 3,04 points, contre 3,54 au centre.

18. **Base de l’IGR — corrigée dans le code, la méthode et l’annexe.** La formule est désormais `B_IGR = [0,8 SBI − IS − CN] × 0,85`, puis l’impôt par part est multiplié par le nombre de parts sans second facteur de 0,85. L’IRPP central recalculé vaut 206,9 milliards de FCFA.

19. **Quotient familial — défini.** `N` est le nombre de parts fiscales, plafonné à cinq. Au centre, tous les enfants du ménage sont affectés au salarié assujetti le mieux rémunéré; une robustesse répartit également les demi-parts entre assujettis. Cette variante relève l’IRPP de 0,46 %.

20. **Paramètres CMU — provenance corrigée.** Les valeurs 75 000 et 1 425 000 proviennent du programme CEQ `11. CIV21WBN_nhi.do` archivé avec les sources. Faute de document administratif daté, elles sont traitées comme paramètres de référence et non comme cibles officielles. Le texte souligne aussi la mesure imparfaite de l’assurance dans l’EHCVM.

21. **Aide électrique — périmètre explicité et testé.** Le centre répartit 8,69 milliards entre les abonnés du groupe social imputé. Une robustesse distribue la même enveloppe à tous les clients ayant une facture positive; le Gini du revenu final ne change que de 0,00010.

22. **Poids d’hospitalisation — justifié comme convention et testé.** Dix est présenté comme le milieu géométrique des bornes cinq et vingt, non comme un ratio de coût observé. Les bénéfices nets sont 85,51, 81,85 et 77,89 milliards pour les poids 5, 10 et 20; les taux de pauvreté finale correspondants sont 33,85 %, 33,92 % et 34,02 %.

23. **Bootstrap de Shapley — porté à 500 et convergence publiée.** Les moyennes et intervalles sont recalculés à 50, 100, 200 et 500 réplications dans `07_reports/tables/23/23_06_shapley_convergence.xlsx`.

24. **Indice de strate — corrigé.** La strate est maintenant indexée par `s`, le ménage restant indexé par `h`.

25. **Base de la réforme à 9 % — clarifié, sans division artificielle par `1+c`.** Le prix d’un produit à taux final nul peut contenir une TVA enchâssée; ce coût fait partie de la base légale sur laquelle la TVA finale est facturée. La réforme maintient `c` constant et applique 9 % au prix avant TVA finale observé. Une reclassification des droits à déduction nécessiterait un contrefactuel entrées–sorties distinct, désormais explicitement signalé.

## Principales sorties nouvelles ou modifiées

- `07_reports/tables/03/03_02_winsorization_sensitivity.xlsx`
- `07_reports/tables/13/13_08_structure_sensitivities.xlsx`
- `07_reports/tables/14/14_01_fgt_comparison.xlsx`
- `07_reports/tables/16/16_07_robustness_diagnostics.xlsx`
- `07_reports/tables/19/19_05_sensitivity.xlsx`
- `07_reports/tables/22/22_04_robustness.xlsx`
- `07_reports/tables/23/23_06_shapley_convergence.xlsx`
- `07_reports/tables/25/25_02_reform_delivery_sensitivity.xlsx`

## Résultat de l’exécution

La chaîne complète a été exécutée de l’étape 1 à l’étape 26 après les corrections. Toutes les étapes aboutissent. Les valeurs du manuscrit doivent encore être contrôlées par l’audit de reproductibilité avant gel de la version révisée.