# Travaux d'extension — ANStat Microsim

**ANStat — Cellule d'Analyses Économiques (CAE)**
Avril 2026

Ce document retrace l'ensemble des travaux menés sur les deux branches d'extension du projet :

| Branche | Objectif | Fichier central |
|---|---|---|
| `integration-IO-matrix` | Extension par matrice entrées-sorties (OECD ICIO) | `note_matrice_IO_extension.md` |
| `reform-scenarios` | Scénarios de réforme TVA sur les intrants avicoles | `10_reform_chicken_inputs.do` |

---

## Partie I — Branche `integration-IO-matrix`

### Contexte

L'analyse de première itération (branche `main`, Armand Djaha) repose sur une **microsimulation fiscale de premier ordre** :

```
Charge TVA ménage = Σ(depense_item × r_vat_official)
```

où `r_vat_official` est le taux statutaire appliqué directement à la consommation finale, avec un ajustement pour l'informalité via un paramètre `alpha`. Deux limites reconnues :

- **TVA enchâssée dans les intrants** : les producteurs de biens exonérés (alimentation, santé) ne récupèrent pas la TVA sur leurs intrants (énergie, emballage, transport). Cette taxe implicite n'est pas capturée.
- **Informalité dans la production** : le paramètre `alpha` capte l'informalité à la vente, mais pas l'informalité en amont dans les chaînes de production.

L'extension par matrice entrées-sorties (TES / IO) permet de modéliser ces deux canaux.

---

### 1.1 Modèle théorique — Prix de Leontief

Soit :

- `A` : matrice des coefficients techniques — `A[i,j]` = valeur de l'intrant `j` utilisé par unité de production du secteur `i` (dimension `n × n`)
- `t` : vecteur des taux de TVA effectifs par secteur (dimension `n × 1`)
- `Δp` : vecteur des hausses de prix induites par secteur (dimension `n × 1`)

**Prix de Leontief (Miller & Blair, 2009)** :

```
Δp = (I - A')⁻¹ × t
```

où `(I - A')⁻¹` est la **matrice de Leontief inverse**. Elle capte la transmission de la TVA à travers toutes les chaînes de production : effet direct (secteur taxé) + effets indirects (intrants taxés en amont).

Le vecteur `Δp` donne le **taux de taxation implicite total** pour chaque bien final — y compris les biens nominalement exonérés qui portent de la TVA enchâssée via leurs intrants.

**Application au contexte ivoirien** :

| Bien | Taux statutaire | Taux implicite attendu | Raison |
|---|---|---|---|
| Alimentation de base | 0% | > 0% | TVA sur énergie, emballage, transport |
| Santé | 0% | > 0% | TVA sur équipements, médicaments |
| Éducation | 0% | > 0% | TVA sur construction, services |
| Transport | 18% | >> 18% | Carburant taxé + intrants taxés |

---

### 1.2 Source de données retenue — OECD ICIO 2023

**Décision** : OECD Inter-Country Input-Output Database, édition 2023.

Critères de choix :

- La Côte d'Ivoire a été **intégrée pour la première fois** dans cette édition (parmi 10 nouveaux pays).
- **45 secteurs** ISIC Rev.4 — suffisant pour capturer les effets IO critiques.
- Téléchargement gratuit, accès direct.
- Années disponibles : 1995–2020.

| Caractéristique | Détail |
|---|---|
| Couverture temporelle | 1995–2020 |
| Nombre d'économies | 80 pays + reste du monde |
| Classification | 45 industries ISIC Rev.4 |
| Format | CSV, transactions domestiques + importations |
| Accès | Gratuit — http://oe.cd/icio |

**Hypothèse de stabilité** : l'EHCVM est de 2021, la matrice IO la plus récente est 2020. L'hypothèse que les coefficients techniques sont stables sur 1 an est raisonnable en l'absence de choc structurel majeur.

---

### 1.3 Structure des fichiers téléchargés

**Emplacement** : `01_data_sources/IO/`

**Contenu** : 26 fichiers CSV (un par année), nommés `CIVyyyyttl.csv`, ex. `CIV2020ttl.csv`.

**Structure vérifiée** (script Python de contrôle) :

```
Sectors: 46 (45 secteurs + 1 ligne totales)
Columns: 54 (45 secteurs intermediates + 9 colonnes demande finale)
```

Les **46 lignes** se décomposent en :

- 45 lignes de secteurs (préfixe `TTL_` dans le fichier, ex. `TTL_A01_02`, `TTL_G`)
- 5 lignes comptables : `TXS_IMP_FNL`, `TXS_INT_FNL`, `TTL_INT_FNL`, `VALU`, `OUTPUT`
- 1 ligne vide (`TTL_T` — ménages employeurs, normal qu'elle soit vide)

Les **54 colonnes** se décomposent en :

- 45 colonnes d'intrants intermédiaires (consommation inter-sectorielle)
- 9 colonnes de demande finale :

| Code | Description |
|---|---|
| `HFCE` | Consommation finale des ménages — **colonne clé** |
| `NPISH` | Consommation des ISBLM |
| `GGFC` | Consommation publique |
| `GFCF` | Formation brute de capital fixe |
| `INVNT` | Variation de stocks |
| `DPABR` | Achats directs à l'étranger |
| `CONS_NONRES` | Dépenses des non-résidents |
| `EXPO` | Exportations |
| `IMPO` | Importations (négatif) |

> **Note** : le suffixe `ttl` signifie "total" — la matrice inclut les flux domestiques **et** les importations intermédiaires. Pour le modèle de Leontief, on travaille avec cette matrice totale (la TVA sur intrants importés est aussi payée à la frontière).

**Contrôle de qualité** (script Python) :

```python
# Vérification de la matrice CIV 2020
python -c "
    import csv
    with open('01_data_sources/IO/CIV2020ttl.csv') as f:
        rows = list(csv.reader(f))
    sectors = [r[0] for r in rows[1:]]
    empty_rows = [s for s in sectors if all(v == '' for v in rows[sectors.index(s)+1][1:])]
    print(f'Sectors: {len(rows)-1}, Columns: {len(rows[0])}')
    print(f'Empty rows: {empty_rows}')
"
# Result: Sectors: 46, Columns: 54, Empty rows: ['TTL_T']
```

---

### 1.4 Consommation finale des ménages (HFCE) par secteur

**Question** : quels secteurs pèsent le plus dans le budget des ménages ivoiriens ? Les 4 premiers = 62% de la consommation.

| Rang | Secteur | Code ISIC | HFCE (unité ICIO) | Part | COICOP |
|---|---|---|---|---|---|
| 1 | Commerce de détail | `G` | 7 865 | 20.1% | distribution |
| 2 | Agriculture | `A01_02` | 7 070 | 18.0% | 1 (Alimentation) |
| 3 | Alimentation transformée | `C10T12` | 5 871 | 15.0% | 1+2 |
| 4 | Restaurants / hébergement | `I` | 3 722 | 9.5% | 11 |
| 5 | Immobilier | `L` | 2 507 | 6.4% | 4 |
| 6 | Transport terrestre | `H49` | 1 362 | 3.5% | 7 |
| 7 | Télécommunications | `J61` | 1 045 | 2.7% | 8 |
| 8 | Autres services | `S` | 776 | 2.0% | 13 |
| 9 | Pétrole raffiné | `C19` | 773 | 2.0% | 7 |
| 10 | Chimie | `C20` | 764 | 1.9% | amont |

**Total HFCE : 39 184 M** (unité ICIO)

**Note** : les codes `C19` (coke, produits pétroliers raffinés) et `C20` (produits chimiques) ne correspondent pas directement à un COICOP de consommation finale — ils sont consommés comme **intrants de production** (carburant pour transport et agriculture, engrais pour agriculture). Ils constituent le canal de transmission principal de la TVA enchâssée.

---

### 1.5 Table de concordance COICOP × ISIC

Cette table est le point de départ de l'étape 2. Elle mappe chaque secteur IO à la catégorie COICOP de l'EHCVM.

| Code ISIC | Description | COICOP | Criticité |
|---|---|---|---|
| `A01_02` | Agriculture, sylviculture | **1** | Haute — exonéré, gros intrants taxés |
| `A03` | Pêche | **1** | Haute |
| `B05_06` | Extraction charbon, pétrole, gaz | — | Amont énergie |
| `C10T12` | Alimentation, boissons, tabac | **1** + **2** | Haute |
| `C13T15` | Textiles, habillement, cuir | **3** | Moyenne |
| `C16` | Bois et produits en bois | — | |
| `C17_18` | Papier, imprimerie | — | |
| `C19` | Coke, produits pétroliers raffinés | **7** (carburant) | **Amont clé — 18% TVA** |
| `C20` | Produits chimiques | — | **Amont clé — engrais taxés** |
| `C21` | Produits pharmaceutiques | **6** | Haute |
| `C22` | Caoutchouc et plastiques | — | |
| `C23` | Minéraux non métalliques | — | |
| `C24` | Métaux de base | — | |
| `C25` | Produits métalliques | — | |
| `C26` | Informatique, électronique | **5** + **8** | |
| `C27` | Équipements électriques | **5** | |
| `C28` | Machines et équipements | **5** | |
| `C29` | Véhicules automobiles | **7** | |
| `C30` | Autres équipements de transport | **7** | |
| `C31T33` | Meubles, autres manuf., réparation | **5** | Moyenne |
| `D` | Électricité, gaz, vapeur | **4** | Haute — 18% TVA |
| `E` | Eau, assainissement, déchets | **4** | Moyenne |
| `F` | Construction | **4** | |
| `G` | Commerce de gros et détail | — | **Amont clé — distribution, informel** |
| `H49` | Transport terrestre | **7** | **Haute — très informel** |
| `H50` | Transport maritime | **7** | |
| `H51` | Transport aérien | **7** | |
| `H52` | Entreposage, auxiliaires transport | — | |
| `H53` | Poste et courrier | — | |
| `I` | Hébergement et restauration | **11** | Haute — très informel |
| `J58T60` | Édition, audiovisuel | **9** | Faible |
| `J61` | Télécommunications | **8** | Faible — formel |
| `J62_63` | Informatique, services information | **8** | Faible |
| `K` | Finance et assurance | **12** | Faible |
| `L` | Immobilier | **4** | |
| `M` | Services professionnels et scientifiques | — | |
| `N` | Services administratifs | — | |
| `O` | Administration publique, défense | — | |
| `P` | Éducation | **10** | Moyenne — exonérée |
| `Q` | Santé humaine et action sociale | **6** | Haute — exonérée |
| `R` | Arts, spectacles, loisirs | **9** | |
| `S` | Autres services | **13** | Haute — très informel |
| `T` | Activités des ménages employeurs | — | (exclu du modèle) |

---

### 1.6 Plan de travail — Étapes restantes

7 étapes planifiées, dont l'étape 1 (téléchargement et exploration) est terminée :

| Étape | Description | Statut |
|---|---|---|
| **1** | Télécharger et explorer les fichiers OECD ICIO | ✅ Complète |
| **2** | Construire la table de concordance COICOP × ISIC | ⬜ À faire |
| **3** | Extraire la matrice domestique CIV et calculer Leontief | ⬜ À faire |
| **4** | Construire le vecteur de taux TVA par secteur ISIC | ⬜ À faire |
| **5** | Calculer les prix implicites `Δp = L × t` | ⬜ À faire |
| **6** | Créer `02b_mapping_tax_IO.do` et ré-imputer dans l'EHCVM | ⬜ À faire |
| **7** | Relancer le pipeline et comparer résultats | ⬜ À faire |

**Limites connues** :

- Hypothèse de prix fixes (équilibre partiel, pas de substitution)
- Agrégation sectorielle : 45 ISIC vs 422 COICOP — hétérogénéité perdue
- Informalité dans la matrice : la matrice IO officielle sous-estime probablement les transactions informelles
- Année de référence : ICIO 2020, EHCVM 2021

---

## Partie II — Branche `reform-scenarios`

### Contexte

Sur la branche `main`, l'analyse calcule la charge fiscale sous le **système actuel** (taux statutaires + scénarios d'informalité). La question nouvelle est : **que se passerait-il si on modifiait les taux ?**

Le cas d'étude choisi est la **filière avicole** : simuler l'impact d'une hausse de TVA sur les intrants de production (aliments composés, poussins d'un jour, médicaments vétérinaires) via un mécanisme d'approximation du pass-through sur les prix.

### 2.1 Pourquoi les intrants avicoles ?

L'EHCVM est une enquête de **consommation finale** — elle ne recense pas les intrants de production. Il est donc impossible de observer directement ce que les ménages achètent comme facteurs de production.

Les produits avicoles présents dans l'EHCVM :

| Codpr | Produit | Mode | TVH actuelle |
|---|---|---|---|
| 33 | Poulet sur pied | Don | exonérée |
| 34 | Viande de poulet | Achat | exonérée |
| 35 | Autres volailles | Don | exonérée |
| 171 | Autres volailles domestiques sur pied | Autoconso | exonérée |

Aucun intrant avicole (aliments composés, poussins, vétérinaires) n'est présent dans l'enquête — ce qui confirme la limite de l'EHCVM pour l'analyse de la production.

Le canal de transmission est donc : **hausse TVA intrants → hausse coût production → répercussion sur prix poulet → charge supplémentaire pour les ménages**.

### 2.2 Modèle théorique — Approximation du pass-through

**Formule de transmission** :

```
r_reform = α × s_inputs × ΔVAT_inputs
```

où :

- `ΔVAT_inputs` : variation du taux de TVA sur les intrants (0 → 18% = 0.18)
- `s_inputs` : part des coûts de production composée d'intrants taxés
- `α` : taux de transmission (pass-through rate) — part de la hausse de coût répercutée sur le prix
- `r_reform` : taux implicite supplémentaire appliqué à la dépense de poulet des ménages

Cette approximation est transparente mais forte : elle suppose un pass-through **symétrique** (les baisses de coût se répercutent aussi) et **homogène** (même taux pour tous les producteurs).

**Paramètres retenus** :

| Paramètre | Valeur | Justification |
|---|---|---|
| `ΔVAT_inputs` | 0.18 | Passage du taux 0% au taux normal 18% |
| `s_inputs` | 0.65 / 0.75 / 0.89 | Structure de coût typique aviculture industrielle ouest-africaine |
| `α` | 0.50 / 0.70 / 1.00 | Résultats de la littérature sur le pass-through en Afrique |

**Structure de coût de l'aviculture industrielle ouest-africaine** (sources : littérature sectorielle, adapté) :

| Composante | Part du coût total | TVA actuelle | TVH proposée |
|---|---|---|---|
| Aliments composés | ~65% | 0% | 18% |
| Poussins d'un jour | ~18% | 0% | 18% |
| Médicaments / vaccins | ~6% | 0% | 18% |
| Autres (main d'œuvre, foncier, énergie) | ~11% | variable | inchangé |

**Scénarios** :

| Scénario | α (pass-through) | s_inputs | Impact prix implicite |
|---|---|---|---|
| S1 Conservateur | 50% | 65% | 0.50 × 0.65 × 0.18 = **5.85%** |
| S2 Central (référence) | 70% | 75% | 0.70 × 0.75 × 0.18 = **9.45%** |
| S3 Pass-through complet | 100% | 89% | 1.00 × 0.89 × 0.18 = **16.02%** |

### 2.3 Code — `10_reform_chicken_inputs.do`

**Emplacement** : `04_scripts/10_reform_chicken_inputs.do`

**Dépendances** : nécessite `02_mapping_tax.do` et `03_compute_taxes.do` exécutés au préalable.

**Structure du script** (10 étapes) :

**Étapes 0 — Paramètres de réforme** :

```stata
* VAT change on inputs (proportion)
scalar delta_vat_inputs = 0.18     // 0% → 18% standard rate

* Input cost shares (proportion of total production cost)
scalar s_inputs_low     = 0.65     // conservative: only aliments composés
scalar s_inputs_central = 0.75     // central: aliments + poussins
scalar s_inputs_high    = 0.89     // high: aliments + poussins + médicaments

* Pass-through rates
scalar alpha_low        = 0.50     // partial absorption (imperfect competition)
scalar alpha_central    = 0.70     // reference scenario
scalar alpha_full       = 1.00     // full pass-through (competitive market)

* Implied effective reform rates
scalar r_reform_central = alpha_central * s_inputs_central * delta_vat_inputs
```

**Étape 1 — Chargement des données** :

```stata
use "$SILVER/03/fiscal_data.dta", clear
```

Charge la sortie de `03_compute_taxes.do` qui contient :
- `depan_w` : dépense winsorisée par item
- `r_vat_official` : taux TVA statutaire par produit
- `coicop` : catégorie COICOP
- `conso_w` : consommation totale winsorisée par ménage
- `vat_w` : charge TVA totale par ménage

**Étape 2 — Identification des produits avicoles** :

```stata
gen poultry = inlist(code, 34, 33, 35)
gen depan_poultry = depan_w * poultry
xtile decile = conso_tot [pw=hhweight], n(10)
```

**Étape 3 — Part budgétaire du poulet par décile** :

```stata
collapse (mean) conso_tot (sum) poul_tot = depan_poultry [pw=hhweight], by(decile)
gen share_poultry = poul_tot / conso_tot * 100
```

**Étape 4 — Calcul de la charge additionnelle sous 3 scénarios** :

```stata
* S1 — Conservative
gen r_reform_s1 = (alpha_low    * s_inputs_low    * delta_vat_inputs) * poultry
gen vat_reform_s1 = depan_w * r_reform_s1

* S2 — Central
gen r_reform_s2 = (alpha_central * s_inputs_central * delta_vat_inputs) * poultry
gen vat_reform_s2 = depan_w * r_reform_s2

* S3 — Full pass-through
gen r_reform_s3 = (alpha_full   * s_inputs_high   * delta_vat_inputs) * poultry
gen vat_reform_s3 = depan_w * r_reform_s3
```

**Étape 5 — Agrégation au niveau ménage** :

```stata
sort hhid
by hhid: egen dpoul = total(depan_poultry)
by hhid: gen  hh_tag = (_n == 1)

by hhid: egen add_vat_s1 = total(vat_reform_s1)
by hhid: egen add_vat_s2 = total(vat_reform_s2)
by hhid: egen add_vat_s3 = total(vat_reform_s3)

keep if hh_tag == 1
clonevar vat_baseline = vat_w
```

**Étape 6 — Résultats distributifs par décile** :

```stata
collapse (mean) conso_tot dpoul                               ///
    (mean) eff_vat_base eff_vat_s1 eff_vat_s2 eff_vat_s3     ///
    (mean) delta_eff_s1 delta_eff_s2 delta_eff_s3             ///
    (sum)  add_vat_tot_s1 = add_vat_s1                        ///
    (sum)  add_vat_tot_s2 = add_vat_s2                        ///
    (sum)  add_vat_tot_s3 = add_vat_s3                        ///
    [pw=hhweight], by(decile)
```

**Étape 7 — Estimation de recette fiscale additionnelle** :

```stata
collapse (sum) add_vat_s1 add_vat_s2 add_vat_s3 [pw=hhweight]
```

**Étape 8 — Test de progressivité / régressivité** :

```stata
di "Δ effective rate D1  (poorest) : " %6.4f delta_eff_s2[1]
di "Δ effective rate D10 (richest) : " %6.4f delta_eff_s2[10]

if delta_eff_s2[1] > delta_eff_s2[10] {
    di as error " → REGRESSIVE"
}
```

**Résultat attendu** : si `Δ_eff[D1] > Δ_eff[D10]`, la réforme est **régressive** — les ménages les plus pauvres supportent proportionnellement une charge plus lourde car ils consacrent une part plus élevée de leur budget au poulet.

### 2.4 Limites de l'approche

| Limite | Description |
|---|---|
| Pass-through linéaire | Suppose un ajustement symétrique et instantané des prix — la réalité est plus complexe (marchés imparfaits, délais d'ajustement) |
| Paramètres exogènes | `α` et `s_inputs` sont fixés à partir de la littérature, non estimés sur données ivoiriennes |
| Hétérogénéité ignorée | Tous les producteurs avicoles sont traités de la même manière — en réalité, grands élevages vs. petites exploitations ont des structures de coût différentes |
| Channel unique | La réforme n'affecte pas que les prix du poulet — les œufs, les autres volailles, les aliments pour bétail seraient aussi impactés |

**Pour lever ces limites** : l'approche IO (Partie I) permettrait de modéliser l'ensemble des chaînes d'approvisionnement de manière cohérente.

---

## Partie III — Prochaines étapes

### 3.1 Branche `integration-IO-matrix`

- **Étape 2** : Construire la concordance fine `codpr EHCVM → ISIC` (avec cas ambigus documentés)
- **Étape 3** : Extraire la matrice domestique CIV et calculer `L = (I - A)⁻¹`
- **Étapes 4–7** : Intégration dans le pipeline existant

### 3.2 Branche `reform-scenarios`

- **Exécuter `10_reform_chicken_inputs.do`** après avoir lancé `02` et `03`
- **Interpréter les résultats** : vérifier si la réforme est régressive ou non
- **Généraliser** : créer un framework générique pour tester d'autres réformes (autres secteurs, autres taux)
- **Valider par l'IO** : une fois l'approche Partie I prête, reproduire le même exercice avec la matrice Leontief pour comparer

### 3.3 Intégration future

Lorsque l'approche IO sera opérationnelle, les deux branches convergeront :

```
Réforme (ex. hausse TVA intrants avicoles)
        ↓
Matrice Leontief CIV (OECD ICIO 2020)
        ↓
Δp = (I - A)⁻¹ × t  (taux de TVA modifiés par secteur ISIC)
        ↓
Taux implicite sur codpr 34 (viande de poulet)
        ↓
Ré-imputation dans l'EHCVM → charge fiscale distributive finale
```

Cette chaîne est plus rigoureuse que l'approximation pass-through car elle capture **tous les effets indirects** à travers la structure productive complète — y compris les rétroactions multiples (ex. : le soja utilisé pour les aliments composés →、运输 → énergie → etc.).

---

## Références

- Miller, R.E., & Blair, P.D. (2009). *Input-Output Analysis: Foundations and Extensions* (2nd ed.). Cambridge University Press.
- OECD (2023). *Development of the OECD Inter-Country Input-Output Database, 2023 edition*. https://doi.org/10.1787/5a5d0665-en
- Bachas, P., Gadenne, L., & Jensen, A. (2024). *Informality, Consumption Taxes, and Redistribution*. American Economic Review, 114(1).
- Lenzen, M. et al. (2013). *Building Eora: A Global Multi-Region Input-Output Database*. Economic Systems Research, 25(1).
- World Bank (2024). *Urban Informality in Sub-Saharan Africa*. Policy Research Working Paper No. 10703.
- UNECA (2019). *Economic Report on Africa, Chapter 3: Fiscal Policy for Financing Sustainable Development*.
