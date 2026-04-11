# Extension par matrice entrées-sorties — Justification, source retenue et plan de travail

**ANStat — Cellule d'Analyses Économiques (CAE)**  
Note méthodologique · Avril 2026

---

## Statut

| | |
|---|---|
| **Source retenue** | OECD ICIO 2023 |
| **Téléchargement** | En cours |
| **Implémentation** | À démarrer |

---

## 1. Positionnement par rapport à l'analyse existante

L'analyse de première itération repose sur une **microsimulation fiscale de premier ordre** : le taux de TVA statutaire est appliqué directement à la consommation finale observée des ménages, en supposant un pass-through complet et statique. Cette approche est explicitement reconnue dans le code comme une approximation :

> *"VAT is assumed to be fully shifted to consumers (static incidence)"*  
> `03_compute_taxes.do`

> *"No input-output transmission effects"*  
> `README.md` — Limitations

Cette note décrit pourquoi une extension par matrice entrées-sorties (TES / IO) constitue l'étape suivante, et documente le plan de travail retenu.

---

## 2. Ce que la matrice IO permettrait de capturer

### 2.1 La TVA sur consommations intermédiaires

La TVA ne frappe pas seulement la consommation finale : elle frappe chaque transaction intermédiaire dans la chaîne de production. Le mécanisme de crédit de TVA entre entreprises formelles neutralise cet effet — mais cette neutralisation est **incomplète dans deux cas fréquents en CIV** :

**Cas 1 — Secteur informel (canal principal)**  
Les producteurs informels ne peuvent ni collecter ni récupérer la TVA sur leurs intrants. La TVA payée sur les intrants s'incorpore dans leurs coûts, puis dans leurs prix de vente. Résultat : même un bien acheté dans le secteur informel — nominalement "hors TVA" — porte une **TVA enchâssée implicite** via les intrants formels utilisés en amont.

**Cas 2 — Biens exonérés**  
Les producteurs de biens exonérés (alimentation de base, santé, éducation) ne récupèrent pas la TVA sur leurs intrants (énergie, emballage, transport, équipements). Le taux effectif réel d'un bien "exempté" n'est donc **pas zéro**.

### 2.2 Formalisation : le modèle de prix de Leontief

Soit :
- `A` : matrice des coefficients techniques `(n × n)`
- `t` : vecteur des taux de TVA effectifs par secteur `(n × 1)`
- `Δp` : vecteur de hausse de prix induite par la TVA dans chaque secteur

```
Δp = (I - A')⁻¹ × t
```

`(I - A')⁻¹` est la **matrice de Leontief inverse** — elle capture les effets directs et indirects à travers toutes les chaînes de production. Le vecteur `Δp` donne le **taux effectif implicite** pour chaque bien final, y compris les exonérés.

### 2.3 Impact attendu sur les résultats

| Aspect | Sans IO (analyse actuelle) | Avec IO |
|--------|---------------------------|---------|
| Biens exonérés (alimentation de base) | Taux effectif = 0% | Taux implicite > 0% (TVA sur intrants) |
| Alimentation informelle | Fardeau quasi-nul (alpha bas) | Légèrement plus élevé (TVA enchâssée dans prix informels) |
| Progressivité mesurée | Probablement surestimée | Plus conservatrice : les biens des pauvres portent aussi de la TVA implicite |
| Indice de Kakwani | Potentiellement surestimé | Plus proche du fardeau réel |
| Cohérence avec scénarios informalité | Cohérente en soi | Plus rigoureuse : alpha capte l'informalité à la vente, IO capte celle dans la production |

L'effet le plus important concerne les **ménages pauvres ruraux** : ils consomment une part élevée de biens alimentaires nominalement exonérés, mais produits avec des intrants taxés.

---

## 3. Source de données retenue — OECD ICIO 2023

### Décision

**Source choisie : OECD Inter-Country Input-Output Database, édition 2023.**

La Côte d'Ivoire a été **intégrée pour la première fois dans cette édition** (parmi 10 nouveaux pays ajoutés : Bangladesh, Cameroun, Égypte, Jordanie, Nigéria, Pakistan, Sénégal, Biélorussie, Ukraine).

| Caractéristique | Détail |
|----------------|--------|
| Couverture temporelle | 1995–2020 |
| Nombre d'économies | 80 pays + reste du monde |
| Classification sectorielle | 45 industries (ISIC Rev.4) |
| Format | Tableaux IO inter-pays + matrice domestique extractible |
| Accès | Gratuit, téléchargement direct |
| Contact | icio-tiva.contact@oecd.org |

**Hypothèse de stabilité structurelle :** l'EHCVM est de 2021, la matrice IO la plus récente disponible est 2020. L'hypothèse que les coefficients techniques sont stables entre 2020 et 2021 est raisonnable sur une période aussi courte et en l'absence de choc structurel majeur.

### Téléchargement

**Page de téléchargement :**
> https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html

**Lien court :**
> http://oe.cd/icio

**Fichiers à télécharger :**
1. `ICIO2023_CSV.zip` — tables complètes en format CSV (tous pays, toutes années)
2. `ReadMe_ICIO2023.pdf` — documentation technique (structure des fichiers, codes secteurs)
3. `STANi4_List_of_Industries.xlsx` — liste des 45 secteurs ISIC Rev.4 avec codes

Le fichier CSV de la CIV pour 2020 s'appellera typiquement `CIV_2020.csv` une fois extrait.

---

## 4. Nombre de branches nécessaires

### 4.1 Point de départ : les 13 catégories COICOP de l'analyse

L'analyse actuelle (`06_01_sensitivity_taxation.do`) distingue 13 catégories de consommation finale :

| Code COICOP | Catégorie | Criticité pour l'IO |
|-------------|-----------|---------------------|
| 1 | Alimentation / boissons | **Haute** — exonérée mais gros intrants taxés |
| 2 | Alcool / tabac | Moyenne |
| 3 | Habillement / chaussures | Moyenne |
| 4 | Logement / utilities | **Haute** — énergie fortement taxée |
| 5 | Ameublement / équipement | Moyenne |
| 6 | Santé | Haute — exonérée, intrants taxés |
| 7 | Transport | **Haute** — carburant à 18%, très informel |
| 8 | Info / comm | Faible — secteur formel, peu d'effets IO |
| 9 | Loisirs | Faible |
| 10 | Éducation | Moyenne — exonérée, intrants taxés |
| 11 | Restaurants | **Haute** — très informel, chaîne alimentaire |
| 12 | Assurance | Faible — secteur formel |
| 13 | Soins personnels | Haute — très informel |

### 4.2 Branches amont critiques à ne pas agréger

En plus des 13 catégories de demande finale, 5 secteurs de production amont sont déterminants pour les effets indirects :

| Secteur amont | Raison |
|--------------|--------|
| **Agriculture vivrière** | Intrants taxés (engrais, carburant) enchâssés dans l'alimentation exonérée |
| **Énergie / pétrole** | TVA 18%, input de base pour presque tous les secteurs |
| **Transport de marchandises** | Fortement informel, input essentiel pour la distribution alimentaire |
| **Chimie / engrais** | Taxés, non récupérés par les agriculteurs |
| **Commerce de détail** | Point de vente final, formel vs. informel |

### 4.3 Conclusion sur le nombre de branches

| Niveau | Branches | Commentaire |
|--------|----------|-------------|
| Minimum viable | ~18–20 | En dessous, les effets indirects sont trop agrégés |
| Suffisant pour ce projet | **~26–30** | Capture tous les effets clés |
| Disponible dans OECD ICIO | **45** | Largement suffisant, confort analytique |

Les 45 secteurs de l'OECD ICIO couvrent les besoins avec marge. La principale attention à porter sera sur la **table de concordance COICOP → ISIC** (voir Étape 1 du plan de travail).

---

## 5. Structure des fichiers téléchargés

Les fichiers téléchargés sont dans `01_data_sources/IO/` : **26 fichiers CSV**, un par année de 1995 à 2020, nommés `CIVyyyyttl.csv`.

### Structure d'un fichier (ex. `CIV2020ttl.csv`)

- **51 lignes × 55 colonnes**
- **45 lignes de secteurs** (préfixe `TTL_`) + 5 lignes comptables (`TXS_IMP_FNL`, `TXS_INT_FNL`, `TTL_INT_FNL`, `VALU`, `OUTPUT`)
- **45 colonnes de secteurs** (consommations intermédiaires) + 9 colonnes de demande finale

**Colonnes de demande finale :**

| Code | Description |
|------|-------------|
| `HFCE` | Consommation finale des ménages ← **colonne clé pour l'analyse** |
| `NPISH` | Consommation des ISBLM |
| `GGFC` | Consommation publique |
| `GFCF` | Formation brute de capital fixe |
| `INVNT` | Variation de stocks |
| `DPABR` | Achats directs à l'étranger |
| `CONS_NONRES` | Dépenses des non-résidents |
| `EXPO` | Exportations |
| `IMPO` | Importations (négatif) |

> **Note :** le suffixe `ttl` signifie "total" — la matrice inclut les flux domestiques **et** les importations intermédiaires. Pour le modèle de Leontief, on travaille avec cette matrice totale (la TVA sur intrants importés est aussi payée à la frontière).

### Les 45 secteurs ISIC Rev.4 et mapping vers COICOP

| Code ISIC | Description | COICOP correspondant |
|-----------|-------------|----------------------|
| `A01_02` | Agriculture, sylviculture | **1** (alimentation) |
| `A03` | Pêche | **1** (alimentation) |
| `B05_06` | Extraction charbon, pétrole, gaz | — (amont énergie) |
| `B07_08` | Extraction minerais | — (amont industrie) |
| `B09` | Services miniers | — |
| `C10T12` | Alimentation, boissons, tabac | **1** + **2** |
| `C13T15` | Textiles, habillement, cuir | **3** |
| `C16` | Bois et produits en bois | — |
| `C17_18` | Papier, imprimerie | — |
| `C19` | Coke, produits pétroliers raffinés | **7** (carburant transport) |
| `C20` | Produits chimiques | — (amont agriculture) |
| `C21` | Produits pharmaceutiques | **6** (santé) |
| `C22` | Caoutchouc et plastiques | — |
| `C23` | Minéraux non métalliques | — |
| `C24` | Métaux de base | — |
| `C25` | Produits métalliques | — |
| `C26` | Informatique, électronique | **5** (équipement) + **8** |
| `C27` | Équipements électriques | **5** (équipement) |
| `C28` | Machines et équipements | **5** (équipement) |
| `C29` | Véhicules automobiles | **7** (transport) |
| `C30` | Autres équipements de transport | **7** (transport) |
| `C31T33` | Meubles, autres manuf., réparation | **5** (ameublement) |
| `D` | Électricité, gaz, vapeur | **4** (logement/utilities) |
| `E` | Eau, assainissement, déchets | **4** (logement/utilities) |
| `F` | Construction | **4** (logement) |
| `G` | Commerce de gros et détail | — (distribution, amont clé) |
| `H49` | Transport terrestre | **7** (transport) |
| `H50` | Transport maritime | **7** |
| `H51` | Transport aérien | **7** |
| `H52` | Entreposage, auxiliaires transport | — |
| `H53` | Poste et courrier | — |
| `I` | Hébergement et restauration | **11** (restaurants) |
| `J58T60` | Édition, audiovisuel | **9** (loisirs) |
| `J61` | Télécommunications | **8** (info/comm) |
| `J62_63` | Informatique, services information | **8** (info/comm) |
| `K` | Finance et assurance | **12** (assurance) |
| `L` | Immobilier | **4** (logement) |
| `M` | Services professionnels et scientifiques | — |
| `N` | Services administratifs | — |
| `O` | Administration publique, défense | — |
| `P` | Éducation | **10** |
| `Q` | Santé humaine et action sociale | **6** |
| `R` | Arts, spectacles, loisirs | **9** |
| `S` | Autres services | **13** (soins personnels) |
| `T` | Activités des ménages employeurs | — |

**Secteurs amont critiques pour les effets IO** (sans COICOP direct mais TVA enchâssée) :
- `C19` — pétrole raffiné : 18% TVA, input de base pour transport et agriculture
- `C20` — chimie : engrais taxés, input agriculture non récupéré en aval
- `G` — commerce de détail : point de vente, capte l'informalité de distribution
- `H49` — transport terrestre : fortement informel, input clé pour la filière alimentaire

---

## 6. Plan de travail détaillé

### Étape 1 — Télécharger et explorer les fichiers OECD ICIO `[x]`

- [x] Télécharger les fichiers CIV 1995–2020 → `01_data_sources/IO/`
- [x] Vérifier la structure : 45 secteurs × 45 secteurs + demande finale — **confirmé**
- [x] Identifier les codes secteurs ISIC et leur mapping COICOP — **fait ci-dessus**
- [x] Vérifier les valeurs — matrice non-nulle, flux intermédiaires totaux : **74 578 M (unité ICIO)**, 1 seul secteur vide : `TTL_T` (ménages employeurs — normal)

**Consommation finale des ménages (HFCE) par secteur — top 10 :**

| Secteur | ISIC | HFCE | Part | COICOP |
|---------|------|------|------|--------|
| Commerce de détail | `G` | 7 865 | 20.1% | distribution |
| Agriculture | `A01_02` | 7 070 | 18.0% | 1 |
| Alimentation transformée | `C10T12` | 5 871 | 15.0% | 1+2 |
| Restaurants / hébergement | `I` | 3 722 | 9.5% | 11 |
| Immobilier | `L` | 2 507 | 6.4% | 4 |
| Transport terrestre | `H49` | 1 362 | 3.5% | 7 |
| Télécommunications | `J61` | 1 045 | 2.7% | 8 |
| Autres services | `S` | 776 | 2.0% | 13 |
| Pétrole raffiné | `C19` | 773 | 2.0% | 7 |
| Chimie | `C20` | 764 | 1.9% | amont |

> Total HFCE : **39 184 M** · Les 4 premiers secteurs = 62% de la consommation, tous fortement concernés par les effets IO.

### Étape 2 — Construire la table de concordance COICOP × ISIC `[ ]`

C'est l'étape **la plus critique** : la qualité de l'analyse IO dépend entièrement de cette correspondance.

- [ ] Partir de `00_documentation/EHCVM_products/` — classification des produits existante
- [ ] Construire une table de correspondance : `codpr` EHCVM → COICOP → secteur ISIC Rev.4
- [ ] Traiter les cas ambigus (ex. alimentation informelle : ISIC A "Agriculture" ou C10 "Food processing" ?)
- [ ] Valider la concordance sur les parts de dépenses (les secteurs à plus fort poids doivent être bien mappés)
- [ ] Sauvegarder dans `00_documentation/methodologie/concordance_COICOP_ISIC.xlsx`

### Étape 3 — Extraire la matrice domestique CIV et calculer Leontief `[ ]`

- [ ] Créer `04_scripts/10_io_setup.do` (ou script Python/R si plus pratique pour l'algèbre matricielle)
- [ ] Extraire la sous-matrice domestique `Z_dom` (transactions intermédiaires CIV × CIV)
- [ ] Calculer le vecteur de production totale `x`
- [ ] Calculer la matrice des coefficients techniques : `A = Z_dom × diag(x)⁻¹`
- [ ] Calculer la matrice de Leontief inverse : `L = (I - A)⁻¹`

### Étape 4 — Construire le vecteur de taux TVA par secteur ISIC `[ ]`

- [ ] Agréger le mapping fiscal de `02_mapping_tax.do` (taux par `codpr`) au niveau ISIC
- [ ] Pondérer par les parts de dépenses observées dans l'EHCVM (`depan_w`)
- [ ] Construire le vecteur `t` (45 × 1) — taux TVA moyen effectif par secteur ISIC
- [ ] Vérifier la cohérence : secteurs formels (utilities, telecom) ≈ taux élevés ; alimentation ≈ proche de 0

### Étape 5 — Calculer les prix implicites `[ ]`

```
Δp = L × t
```

- [ ] Appliquer la formule de Leontief inverse
- [ ] Obtenir le vecteur `Δp` (45 × 1) — taux de taxation implicite total par secteur
- [ ] Comparer `Δp` aux taux statutaires `t` — l'écart révèle l'ampleur des effets IO
- [ ] Documenter les secteurs où l'écart est le plus significatif (attendu : alimentation, santé, éducation)

### Étape 6 — Créer `02b_mapping_tax_IO.do` et ré-imputer dans l'EHCVM `[ ]`

- [ ] Créer `04_scripts/02b_mapping_tax_IO.do` (ne pas modifier `02_mapping_tax.do` — préserver la comparabilité)
- [ ] Remplacer `r_vat_official` par `r_vat_IO` (taux implicite issu de `Δp`) via la concordance COICOP/ISIC
- [ ] Merger dans la base de consommation ménage

### Étape 7 — Relancer le pipeline et comparer `[ ]`

- [ ] Relancer `03_compute_taxes.do` avec `r_vat_IO`
- [ ] Relancer `04_analysis.do` → nouveaux tableaux déciles
- [ ] Relancer `05_progressivity.do` → Kakwani IO vs Kakwani premier ordre
- [ ] Relancer `06_01` avec les 3 scénarios d'informalité × taux IO
- [ ] Produire un tableau comparatif synthétique : indices clés avec vs sans IO, par scénario

---

## 6. Limites connues

- **Hypothèse de prix fixes** : modèle de Leontief en équilibre partiel — pas d'effets de substitution.
- **Agrégation sectorielle** : 45 secteurs ISIC vs 422 produits COICOP — hétérogénéité intra-sectorielle perdue.
- **Informalité dans la matrice** : le TES officiel capture imparfaitement le secteur informel. La matrice OECD ICIO sous-estime probablement les transactions informelles.
- **Année de référence** : ICIO 2020, EHCVM 2021 — hypothèse de stabilité structurelle requise.

Ces limites sont à documenter explicitement dans les notes méthodologiques du papier final.

---

## 7. Références

- Miller, R.E., & Blair, P.D. (2009). *Input-Output Analysis: Foundations and Extensions* (2nd ed.). Cambridge University Press. ← **référence de base pour le modèle de prix**
- OECD (2023). *Development of the OECD Inter-Country Input-Output Database, 2023 edition*. https://doi.org/10.1787/5a5d0665-en
- OECD (2023). *Guide to OECD Trade in Value Added (TiVA) Indicators*. https://stats.oecd.org/wbos/fileview2.aspx?IDFile=afa5c684-c31d-49dd-87db-6fd674f29a43
- Bachas, P., Gadenne, L., & Jensen, A. (2024). *Informality, Consumption Taxes, and Redistribution*. American Economic Review, 114(1).
- UNECA (2019). *Economic Report on Africa, Chapter 3: Fiscal Policy for Financing Sustainable Development*.
- World Bank (2024). *Urban Informality in Sub-Saharan Africa*. Policy Research Working Paper No. 10703.
