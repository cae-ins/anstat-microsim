# Accises et droits de douane — choix méthodologiques pour l'étape 18

## Périmètre CEQ

Le chapitre 7 du *CEQ Handbook* définit le revenu consommable comme le revenu
disponible augmenté des subventions indirectes et diminué de l'ensemble des
impôts indirects. Il recommande de distinguer les effets directs, observables à
partir des dépenses des ménages, des effets indirects transmis par les prix des
intrants, puis de relier les postes de consommation aux secteurs d'un tableau
entrées-sorties.

Akim, Ben Jelloul, Czajka et Robilliard (2020) simulent pour la Côte d'Ivoire la
TVA, les droits d'importation et les accises en associant les postes COICOP aux
règles fiscales. Leur application reste directe : l'informalité du lieu d'achat
et les impôts incorporés dans les consommations intermédiaires sont explicitement
laissés à des travaux ultérieurs. L'étape 18 conserve cette distinction : elle
produit une première mesure directe, compatible avec le revenu consommable, et
documente l'extension entrées-sorties qui restera à ajouter.

## Décomposition retenue

Pour une dépense TTC hors marges `x`, un taux de TVA `r`, un taux d'accise `e`,
un taux de droit de douane `d` et une part importée `m`, l'ordre légal est :

1. droit de douane sur la valeur CAF ;
2. accise sur la valeur augmentée des droits de douane ;
3. TVA sur la valeur augmentée des autres impôts.

La charge directe est donc récupérée à partir du prix observé par :

```text
accise = x * e / ((1 + e) * (1 + r))
douane = x * (d*m) / ((1 + d*m) * (1 + e) * (1 + r))
```

Les marges commerciales et de transport sont retirées avec le pont de
valorisation du TRE 2023. La part importée vaut `imports / (imports +
production_domestique)` au niveau des 48 produits du TRE. Cette utilisation du
TRE 2023 pour l'EHCVM 2021 est une approximation déjà encadrée par les scénarios
du pipeline.

## Paramètres 2021

- Le TEC CEDEAO comporte cinq bandes : 0, 5, 10, 20 et 35 %. Le mapping
  `codpr -> cusio` du modèle CEQ Côte d'Ivoire est repris, mais la redevance
  statistique de 1 point intégrée dans son do-file est séparée du droit de
  douane afin que la validation porte sur le poste budgétaire 7171.
- Les boissons non alcoolisées sont taxées à 14 % ; les bières et cidres à
  17 % ; les vins ordinaires à 35 % ; les alcools de 35 degrés et plus à
  45 %. Le code 164, qui mélange bière et vin traditionnel, conserve le choix
  prudent de 17 % du do-file CEQ national.
- Le taux global sur le tabac applicable en 2021 est 46 % : 39 % de taxe
  spéciale, 5 % pour le sport et 2 % de solidarité sida/tabagisme.
- Les produits cosmétiques identifiables sans ambiguïté (codes 321 et 417) sont
  taxés à 10 %. Les produits à l'hydroquinone ne sont pas isolables et ne sont
  donc pas portés à 50 %.
- Pour les carburants, l'EHCVM ne sépare pas essence et gasoil. La TSU moyenne
  de 55 FCFA/litre (85 sur le super et 25 sur le gasoil) est appliquée aux
  codes 208, 209 et 304 avec un prix de référence de 615 FCFA/litre. Son taux
  ad valorem équivalent est calculé sur le prix hors TVA à 9 %. Le pétrole
  lampant (202) et le gaz butane (303) restent à zéro. La subvention de prix
  des carburants appartient à l'étape 20 et ne doit pas annuler la TSU dans
  l'étape 18.
- Le repas ou la boisson pris hors ménage (197), la catégorie mixte
  savon-shampoing (317) et les véhicules sans information sur la puissance
  fiscale (626) sont exclus du scénario central et conservés dans le fichier
  de paramètres comme diagnostics.

## Incidence et sensibilités

Le scénario central retient une répercussion intégrale (`alpha = 1`) : les
droits sont prélevés au cordon douanier et les accises à la production ou à
l'importation. Pour l'alcool et le tabac seulement, les variantes S2 et S3
appliquent les coefficients d'informalité déjà utilisés pour la TVA. Les droits
de douane, les carburants, les boissons non alcoolisées et les cosmétiques ne
sont pas réduits par l'informalité du détaillant.

La version 1 ne propage pas encore la TSU ni les droits payés sur les intrants
importés à travers le Leontief national. Le diagnostic compare néanmoins les
taux statutaires aux taux implicites du TRE, et le retrait conjoint de la TVA,
des accises et des droits évite de compter deux fois la TVA incluse dans le prix
observé.

## Sources principales

- CEQ Institute, *CEQ Handbook*, chapitre 7 :
  <https://commitmentoequity.org/wp-content/uploads/2022/02/1.-CEQ-Handbook-2018-Nora-Lustig-Editor..pdf>
- Akim et al. (2020), *Collect more, spend better?* :
  <https://www.afd.fr/sites/default/files/2020-11-12-42-27/Collect%20more_spend%20better.pdf>
- Annexe fiscale à la loi de finances 2021, articles 4 et 26 :
  <https://cotedivoirepaie.ci/wp-content/uploads/2022/02/Annexe_fiscale_2021.pdf>
- Douanes ivoiriennes, présentation du TEC CEDEAO :
  <https://apps.douanes.ci/info/tec>
- Loi de règlement 2021, état de recouvrement des ressources :
  <https://budget.gouv.ci/doc/loi/LFR%20Loi%20de%20Reglement%202021-%20RAPPORT%20DE%20PRESENTATION.pdf>
- Direction générale des hydrocarbures, fiscalité et prix 2021 :
  <https://apisite.dgh.ci/Files/Annuaire_des_Statistiques_des_Hydrocarbures_en_C%C3%B4te_d%27Ivoire/62e8fecf09bad.pdf>
