# Revue à lire — CEQ Côte d'Ivoire

> Documents à lire avant de continuer le développement du modèle.
> Organisés par priorité et par thème. Pour chaque document : ce qu'on cherche précisément.

---

## Priorité 1 — Lire en premier (fondations du modèle)

### 1. CEQ Handbook Volume 1 — Chapitres 1 & 6
**Pourquoi** : le manuel de référence. Chapitre 1 = définition des 7 concepts de revenu.
Chapitre 6 = comment construire les concepts quand le revenu est difficile à mesurer
(secteur informel, sous-déclaration). C'est la justification méthodologique de tous nos choix.

**Ce qu'on cherche précisément** :
- Définition exacte de Market Income, Consumable Income, Final Income
- Traitement recommandé quand "income aggregates are difficult to obtain"
- Comment proxier le revenu de marché par la consommation
- Règles pour décider quels instruments inclure vs exclure

**Lien** : https://commitmentoequity.org/wp-content/uploads/2023/04/CEQ-Handbook-Volume-1-.pdf

---

### 2. Akim, Ben Jelloul, Czajka & Robilliard — "Collect More, Spend Better?", AFD (2020)
**Pourquoi** : la **seule analyse CEQ publiée directement sur la Côte d'Ivoire**.
Même cadre conceptuel que notre pipeline. Nos résultats EHCVM 2021 devront être
comparés à leurs résultats ENV 2014.

**Ce qu'on cherche précisément** :
- Comment ils traitent la qualité du revenu dans les données ivoiriennes
- Quels instruments fiscaux ils simulent (IRPP ? CNPS ? ou seulement TVA ?)
- Leurs résultats sur l'incidence TVA par décile (à comparer avec les nôtres)
- Leurs résultats sur les dépenses éducation/santé (méthode d'allocation)
- Les limites documentées — notamment sur la couverture des impôts directs
- Quelle enquête ménage utilisée (ENV 2014 vs notre EHCVM 2021)

**Lien** : https://www.afd.fr/en/ressources/collect-more-spend-better-assessing-incidence-fiscal-systems-and-public-spending-three-francophone-west-african-countries

---

### 3. Younger, Osei-Assibey & Oppong — "Fiscal Incidence in Ghana", CEQ WP35 (2015/2016)
**Pourquoi** : le cas le plus proche de la CIV en Afrique de l'Ouest. Contexte
similaire : économie francophone/anglophone comparable, informalité élevée, TVA à 15-18 %.
C'est la référence pour comment appliquer le CEQ dans notre environnement.

**Ce qu'on cherche précisément** :
- Comment ils proxient le Market Income par la consommation (justification)
- Comment ils traitent le secteur informel pour les impôts directs
- Résultats sur la régressivité TVA (Kakwani, Reynolds-Smolensky)
- Méthode d'allocation des dépenses éducation et santé
- Limites et mises en garde méthodologiques

**Lien** : http://www.commitmentoequity.org/publications_files/Ghana/CEQ%20WP35%20Fiscal%20Incidence%20in%20Ghana%20Nov%202016.pdf

---

## Priorité 2 — Lire avant d'attaquer les étapes 16–18

### 4. SOUTHMOD Editorial — "Modelling tax-benefit systems in developing countries", IJM (2021)
**Pourquoi** : document de référence sur le traitement de la qualité des données
revenu dans les microsimulations africaines (Ghana, Éthiopie, Tanzanie, Mozambique).
Décrit exactement les problèmes qu'on va rencontrer à l'étape 16.

**Ce qu'on cherche précisément** :
- Comment les équipes SOUTHMOD nettoient et imputent les données revenu
- Méthodes d'imputation multiple pour les revenus manquants ou aberrants
- Traitement du secteur formel vs informel dans chaque pays modèle
- Pourquoi ils ont repoussé la simulation des impôts directs dans une phase ultérieure
- Comment ils valident leurs résultats sans données administratives

**Lien** : https://microsimulation.pub/articles/00192

---

### 5. Hill et al. — "A Fiscal Incidence Analysis for Ethiopia", CEQ WP41 (2017)
**Pourquoi** : pays africain à fort secteur informel, enquête consommation comme
base. Montre comment le CEQ est appliqué quand le revenu est proxié par la
consommation totale — très proche de ce qu'on fait.

**Ce qu'on cherche précisément** :
- Justification de l'utilisation de `disposable income ≈ consommation totale`
- Comment ils simulent (ou n'incluent pas) l'impôt sur le revenu
- Traitement des pensions contributives dans le Market Income
- Méthode d'allocation des transferts en nature (éducation, santé)
- Mise en garde sur la qualité du revenu dans l'ESS éthiopienne

**Lien** : http://www.commitmentoequity.org/wp-content/uploads/2017/09/CEQ-WP41_Hill-Inchauste-Lustig-Tsehaye-Woldehanna_Ethiopia_April2017.pdf

---

### 6. Lustig — "Fiscal Policy, Inequality and the Poor in the Developing World", CEQ WP23 (2017)
**Pourquoi** : synthèse sur 29 pays. Montre que dans les pays africains,
les impôts directs ont un impact redistributif marginal — ce qui justifie
l'approche minimaliste (ne pas simuler l'IRPP si la couverture est trop faible).

**Ce qu'on cherche précisément** :
- Résultats comparatifs sur l'impact des impôts directs vs indirects en Afrique subsaharienne
- Seuil de couverture en dessous duquel simuler l'IRPP n'apporte rien
- Résultats sur la régressivité de la TVA dans les pays africains (benchmark pour nos résultats)
- Recommandations méthodologiques pour les pays à données revenu faibles

**Lien** : http://www.commitmentoequity.org/wp-content/uploads/2017/08/CEQ_WP23_Lustig_July2017v2.pdf

---

## Priorité 3 — Lire avant les étapes 19–21 (subsidies + in-kind)

### 7. World Bank — "Relever le Défi de la Mobilisation Fiscale en CIV" (2019)
**Pourquoi** : analyse Banque Mondiale du système TVA ivoirien. Quantifie les
exonérations et régimes préférentiels — utile pour comprendre pourquoi notre
taux effectif est bien en dessous du taux légal de 18 %.

**Ce qu'on cherche précisément** :
- Ampleur des exonérations TVA (manque à gagner estimé)
- Quels secteurs bénéficient des régimes préférentiels
- Analyse du taux de compliance TVA (écart recettes réelles vs potentiel)
- Recommandations sur les réformes — pour contextualiser notre step 15

**Lien** : https://documents1.worldbank.org/curated/en/422701569525983969/pdf/Cote-d-Ivoire-Relever-le-Defi-de-la-Mobilisation-Fiscale.pdf

---

### 8. Younger — "Impact of Reforming Energy Subsidies, Cash Transfers, and Taxes", CEQ WP55 (2017)
**Pourquoi** : traite spécifiquement du Ghana et de la Tanzanie — deux pays
avec des subventions énergie actives. Donne la méthode pour quantifier les
subventions implicites dans les données ménage (étape 19 de notre roadmap).

**Ce qu'on cherche précisément** :
- Comment calculer la subvention implicite carburant/eau à partir des données ménage
- Méthode de comparaison prix marché vs prix administré
- Impact distributif des subventions énergie (régressif ou progressif ?)
- Comment les intégrer dans le concept Consumable Income

**Lien** : http://www.commitmentoequity.org/wp-content/uploads/2017/08/CEQ_WP55_EnergySubsidiesCashTransfersTaxesGhanaTanzania_Younger_June2017.pdf

---

### 9. Barofsky & Younger — "Effect of Government Health Expenditure on Income Distribution in Ghana", CEQ WP66 (2019)
**Pourquoi** : compare différentes méthodes de valorisation des transferts en
nature santé (insurance value vs government cost vs willingness-to-pay).
Directement applicable à notre étape 21.

**Ce qu'on cherche précisément** :
- Quelle méthode de valorisation est recommandée et pourquoi
- Comment identifier les utilisateurs des services publics de santé dans l'enquête
- Comment allouer le coût unitaire par type d'établissement
- Sensibilité des résultats d'incidence selon la méthode de valorisation

**Lien** : https://ideas.repec.org/p/tul/ceqwps/66.html

---

## Priorité 4 — Lire avant la synthèse CEQ (étapes 22–24)

### 10. Higgins & Lustig — "Can a poverty-reducing and progressive tax and transfer system hurt the poor?", JDE (2016)
**Pourquoi** : papier fondateur des indicateurs d'appauvrissement fiscal
(fiscal impoverishment) et de gains pour les pauvres. Étape 24 du roadmap
est entièrement basée sur ce papier.

**Ce qu'on cherche précisément** :
- Définition formelle du fiscal impoverishment et du fiscal gains to the poor
- Décomposition du poverty gap en ces deux composantes
- Comment calculer ces indicateurs à partir des concepts de revenu CEQ
- Résultats empiriques : dans combien de pays le système fiscal appauvrit-il ?

**Lien** : https://commitmentoequity.org/publications_files/wps/WP%2033%20Higgins_and_Lustig_JDE_Jan_2017.pdf

---

### 11. FMI — Country Report Côte d'Ivoire n°23/406 (2023)
**Pourquoi** : contexte macro fiscal récent. Contient les données sur les
réformes TVA post-2021 et les programmes de protection sociale actifs —
utile pour calibrer les étapes 18 et 22.

**Ce qu'on cherche précisément** :
- Programmes de transferts sociaux actifs en CIV en 2021-2023 (PFISP, etc.)
- Réformes TVA post-EHCVM 2021 (à noter comme limites de notre modèle)
- Données sur le ratio recettes fiscales/PIB et sa décomposition
- Objectifs de réduction de la pauvreté officiels (pour benchmarker nos P0/P1/P2)

**Lien** : https://www.imf.org/-/media/files/publications/cr/2023/english/1civea2023004.pdf

---

## Ressources à explorer (secondaire)

| Document | Utilité | Lien |
|---|---|---|
| OpenFisca-CIV (GitHub) | Barèmes ITS/IGR/CNPS déjà codés — vérifier pour étape 16 | https://github.com/openfisca/openfisca-cote-d-ivoire |
| DGI — "Le Système Fiscal Ivoirien" | Référence officielle barèmes et taux | https://www.dgi.gouv.ci/assets/documents/LE%20SYSTEME%20FISCAL%20IVOIRIEN.pdf |
| FMI — Poverty Reduction Strategy CIV (2023) | Programmes sociaux officiels pour étape 18 | https://www.imf.org/en/Publications/CR/Issues/2023/12/12/Cote-d-Ivoire-Poverty-Reduction-and-Growth-Strategy-542434 |
| OCDE — Examen Multidimensionnel CIV Vol.2 Ch.6 | Recommandations politique fiscale | https://shs.cairn.info/examen-multidimensionnel-de-la-cote-d-ivoire-vol2--9789264251670-page-259?lang=fr |
| CEQ Handbook Volume 2 | Frontières méthodologiques (imputation, comportemental) | https://commitmentoequity.org/wp-content/uploads/2023/04/CEQ-Handbook-Volume-2-.pdf |
| GhaSim — World Bank Ghana Microsimulation (2024) | Modèle complet Ghana, formel/informel | https://documents1.worldbank.org/curated/en/099060524110661406/pdf/P1798581f83f1b011933b1b7277f088b63.pdf |
| Lustig WP54 — Redistribution and Poverty (2017) | Version synthèse régions du monde | http://www.commitmentoequity.org/wp-content/uploads/2017/08/CEQ_WP54_Lustig_June2017.pdf |

---

## Ordre de lecture recommandé

```
Avant d'attaquer les prochaines étapes du code :

  1. CEQ Handbook Vol.1, Ch.1 & 6    ← 1 journée
  2. Akim et al. AFD 2020 (CIV)      ← 2-3 heures
  3. Younger et al. Ghana WP35       ← 2-3 heures

Avant étapes 16–18 (impôts directs + transferts) :

  4. SOUTHMOD Editorial IJM 2021     ← 2 heures
  5. Hill et al. Ethiopia WP41       ← 2 heures
  6. Lustig WP23 (29 pays)           ← 1-2 heures

Avant étapes 19–21 (subsidies + in-kind) :

  7. World Bank Mobilisation fiscale CIV  ← 1 heure
  8. Younger WP55 (énergie + transferts)  ← 2 heures
  9. Barofsky & Younger WP66 (santé)      ← 2 heures

Avant étapes 22–24 (synthèse) :

 10. Higgins & Lustig JDE 2016        ← 2 heures
 11. FMI CIV Country Report 2023      ← 1 heure
```

---

*Document créé le 2026-04-19. Cocher chaque entrée au fur et à mesure.*
