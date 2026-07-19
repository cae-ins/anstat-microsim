# Cascade CEQ et inventaire du questionnaire EHCVM 2021

## Décision méthodologique

La construction des concepts de revenu suit le scénario PDI des do-files
Banque mondiale, en particulier `01. CIV21WBN_presimulation_setup.do` et
`12. CIV21WBN_ceqincome.do`. Le fichier de bien-être renomme `pcexp` en
`yd_pc` : la consommation par tête est donc le proxy du revenu disponible.
Le montant `conso_w`, construit seulement à partir des postes retenus pour
l'imputation fiscale, n'est ni l'agrégat de bien-être officiel ni un revenu de
marché.

La cascade à reproduire est la suivante :

```text
yp_pc = yl_pc
yn_pc = yp_pc - dtx_pc - con_pc
yg_pc = yp_pc + dtr_pc
yd_pc = yn_pc + dtr_pc
yc_pc = yd_pc - itx_pc + sub_pc
yf_pc = yc_pc + hlt_pc + edu_pc + oth_econ_pc
```

Pour la Côte d'Ivoire, la convention centrale pose `yp_pc = yl_pc`, car les
pensions contributives ne sont pas traitées comme des transferts publics
subventionnés. Le questionnaire permet néanmoins d'observer ces pensions ;
elles serviront de contrôle et de scénario alternatif. Le revenu imposable est
une variable de calcul de l'impôt et non un concept de revenu CEQ.

## Position actuelle du pipeline

La cascade est maintenant complète. Elle part du revenu disponible observé,
reconstruit le revenu primaire sous les conventions de pension PDI et PGT, puis
intègre les impôts directs, les paiements publics monétaires, la TVA, les
accises, les droits de douane, les réductions de prix, l'éducation publique et
la santé publique. Les sept concepts de revenu sont produits et leurs identités
sont vérifiées ménage par ménage.

Le statut d'assurance maladie déclaré dans l'EHCVM ne détermine pas la
valorisation des services de santé. Les consultations publiques utilisent une
dépense publique moyenne attendue par âge, sexe et milieu; les hospitalisations
utilisent les séjours publics observés sur douze mois.
## Variables utiles du questionnaire

### Revenus de marché, pensions et impôts directs

| Module | Variables | Utilisation selon la démarche Banque mondiale |
|---|---|---|
| S04 Emploi | `s04q32`, `s04q33`, `s04q34`, `s04q35`, `s04q38`, `s04q40`, `s04q42`, `s04q43`, unité de `s04q43` | Durée d'emploi, marqueurs de formalité et salaire principal taxable |
| S04 Emploi | `s04q50`, `s04q51b`, `s04q51d`, `s04q58`, unité de `s04q58` | Emploi secondaire et salaire secondaire formel |
| S05 Revenus | `s05q01`-`s05q06` | Pensions de retraite, veuvage/orphelinat et invalidité ; contrôle et scénario pension alternatif |
| S05 Revenus | `s05q09`, `s05q10` | Revenu locatif et impôt sur revenu foncier |
| S05 Revenus | `s05q11`, `s05q12` | Dividendes et intérêts, assiette de l'impôt sur revenus mobiliers |
| S10 Entreprises | `s10q46`-`s10q57`, `s10q59` | Chiffre d'affaires, consommations intermédiaires, taxes et bénéfice des indépendants |
| S11 Logement | `s11q04`, valeur locative imputée issue de la consommation | Taxe foncière sur résidence principale et propriétés louées |

Le do-file de référence définit l'emploi principal formel si au moins un des
avantages `s04q33`, `s04q34`, `s04q35`, `s04q38`, `s04q40` ou `s04q42` est
présent et si un salaire est déclaré pendant au moins un mois. Le scénario
strict bulletin et cotisation de l'étape 16 reste utile, mais devient une
robustesse plus restrictive.

Cette règle est un **proxy fiscal Banque mondiale**, et non la définition de
l'emploi formel de l'OIT. La résolution de la 21e CIST définit l'emploi formel
comme un emploi effectivement reconnu dans le cadre légal et administratif et
couvert en pratique par des dispositifs formels. Pour un salarié, la
cotisation de l'employeur à un régime légal de sécurité sociale caractérise
l'emploi formel; l'accès effectif aux congés annuel et maladie payés constitue
une information complémentaire. Le bulletin de paie, la retenue d'impôt et le
congé maternité peuvent appuyer l'opérationnalisation nationale, mais ne sont
pas à eux seuls la définition internationale.

L'étape 16 conserve donc trois variables distinctes : `formel_fiscal_bm` pour
la simulation centrale conforme aux do-files, `formel_fiscal_strict` pour la
borne fiscale basse, et `formel_oit` pour décrire l'emploi principal salarié.
La variante `formel_oit_elargi` ajoute le cas où les deux congés payés sont
effectivement accessibles. L'emploi secondaire n'est pas classé selon l'OIT,
car l'EHCVM ne recueille pas pour ce poste les trois informations harmonisées.
La formalité OIT des indépendants devra être établie séparément à partir du
statut et de l'enregistrement de leur unité de production; elle ne relève pas
du seul critère de cotisation salariale.

Références normatives : [résolution de la 21e CIST sur l'économie
informelle](https://www.ilo.org/sites/default/files/wcmsp5/groups/public/%40dgreports/%40stat/documents/normativeinstrument/wcms_901516.pdf),
paragraphes 64 et 76--88, et [définitions opérationnelles
ILOSTAT](https://ilostat.ilo.org/methods/concepts-and-definitions/description-labour-force-statistics/).

### Transferts directs

| Module | Variables | Traitement central |
|---|---|---|
| S15 Filets | `s15q01`, `s15q03`, `s15q05`, `s15q07`-`s15q11b` | Validation de la participation et des paiements observés |
| S02 Éducation | `s02q28` | Bourse ou prise en charge scolaire, classée en transfert direct |
| S04, S02 et S01 | ancienneté, maternité, âge, scolarisation et lien | Éligibilité simulée aux allocations familiales et prestations d'accident du travail |
| Données administratives PSSN | bénéficiaires et montant trimestriel | Imputation PDI centrale par PMT, région et milieu, comme dans les do-files 01 et 03 |

Les transferts de la section 13 (`s13q22a`, `s13q22b`) proviennent de parents
ou d'autres personnes privées. Ils appartiennent au revenu de marché et ne
doivent pas être ajoutés à `dtr_pc`, qui ne contient que les transferts publics
non contributifs. Les réponses de S15 seront utilisées pour valider la
simulation PSSN ; la méthode Banque mondiale reste centrale afin de respecter
les effectifs administratifs et de limiter la sous-déclaration.

### Éducation et santé en nature

| Module | Variables | Traitement central |
|---|---|---|
| S02 Éducation | `s02q03`, `s02q12`, `s02q14`, `s02q19` | Scolarisation, niveau et gestion publique/privée |
| S02 Éducation | `s02q20`, `s02q22`, `s02q24`, `s02q26`, `s02q27` | Frais d'usager par niveau, lissés par décile dans la référence |
| S03 Santé | `s03q01`, `s03q05`, `s03q07`, `s03q12`-`s03q14` | Recours ambulatoire et établissement public |
| S03 Santé | `s03q19`, `s03q20`, `s03q23`, `s03q24` | Hospitalisations, nombre de visites, établissement et frais |
| S03 Santé | questions 32 à 37 | Diagnostic de couverture seulement; jamais utilisé dans l'allocation centrale |

Les bénéfices d'éducation seront imputés par niveau à partir des dépenses
publiques et des effectifs. Pour la santé, la référence applique une approche
d'usage aux hospitalisations annuelles et annualise les consultations à rappel
court ; les frais d'usager sont déduits ou publiés séparément.

### Taxes et subventions indirectes

| Source | Variables ou postes | Traitement central |
|---|---|---|
| Consommation détaillée | `codpr`, `modep`, `depan` | Assiette des taxes indirectes ; la référence conserve `modep` 1 et 4 puis exclut explicitement les postes hors champ |
| S11 Logement | `s11q21`-`s11q24`, `s11q33`-`s11q36a` | Accès, type de compteur, factures d'eau et d'électricité |
| Consommation détaillée | produits 202, 208, 209 et 304 | Quantités de carburant imputées à partir des prix administrés |
| Matrices entrées-sorties | coefficients domestiques/importés, taux et exemptions | TVA, accises, droits de douane et subventions indirectes propagés dans les chaînes de production |

Pour la TVA, la méthode centrale doit reproduire le modèle de déplacement des
prix de `04. CIV21WBN_vat_in.do`. Elle sépare les effets directs et indirects,
propage ces derniers par l'inverse de Leontief, combine les parts domestiques
et importées, puis applique l'informalité par bien et décile. La TVA contenue
dans une dépense TTC est extraite avec un dénominateur `1 + taux`, comme dans
le do-file. Les matrices locales TRE servent de robustesse et doivent être
converties aux prix de base avant le calcul.

## Séquence réalisée

1. Ancrage du revenu disponible sur la consommation par personne de l'EHCVM.
2. Calcul des impôts directs, cotisations, accises et droits de douane.
3. Imputation des pensions, paiements publics et filets sociaux, dont le PSSN
   par PMT et calage administratif.
4. Estimation des réductions de prix de l'électricité et de l'eau.
5. Attribution des services publics d'éducation et de santé.
6. Assemblage des sept concepts de revenu sous PDI et PGT.
7. Décomposition de Shapley, appauvrissement fiscal et classeur CEQ final.
8. Contrôles de périmètre avec les comptes ANStat 2021 et comparaison des
   millésimes 2022-2023.
## Contrôles obligatoires

- Les montants fiscaux et transferts doivent recevoir le même ajustement
  spatial et temporel que `pcexp` avant d'être combinés aux concepts de revenu.
- Les identités `yd = yn + dtr`, `yd = yg - dtx - con` et
  `yc = yd - itx + sub` doivent être vérifiées observation par observation.
- Les transferts privés de S13 ne doivent jamais entrer dans `dtr`.
- Les pensions observées de S05 ne doivent pas être comptées deux fois dans le
  scénario PDI où `yp = yl`.
- Les masses pondérées doivent être comparées aux recettes ou dépenses
  administratives avant toute interprétation distributive.
