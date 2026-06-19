# Note d'analyse : Impact de la TVA avec matrice I/O locale (TRE 2023)

**Date** : 23 mai 2026
**Objet** : Comparaison de l'incidence fiscale entre le modele OCDE (2020) et le modele local (TRE 2023).

---

## 1. Principaux resultats

L'utilisation des **Tableaux des Ressources et des Emplois (TRE) de 2023** de Cote d'Ivoire montre que la TVA enchassee (indirecte) est nettement sous-estimee dans les modeles internationaux standards.

| Indicateur | Modele OCDE (Step 13) | Modele local courant (Step 13b) |
|---|---:|---:|
| TVA enchassee moyenne (FCFA/menage) | 128 997 | **255 956** |
| Total TVA enchassee (FCFA) | 831e9 | **1,65e12** |

**Conclusion** : La structure productive locale integre beaucoup plus de taxes indirectes dans les prix de consommation finale que ce que suggerait la matrice OCDE.

---

## 2. Impact sur la pauvrete

L'inclusion de la TVA enchassee locale change fortement le diagnostic de pauvrete.

| Concept de revenu | Taux de pauvrete (P0) | Ecart de pauvrete (P1) |
|---|---:|---:|
| Marche (avant taxes) | 37,5% | 10,4% |
| Consommable (TVA directe) | 44,5% | 13,0% |
| **Total (TVA directe + enchassee)** | **53,7%** | **17,0%** |

Note : la TVA totale reduit le pouvoir d'achat au point de faire basculer 16,2 points de population supplementaire sous le seuil de pauvrete.

---

## 3. Analyse de la charge par quintile

La charge fiscale est quasi proportionnelle, avec une composante indirecte tres lourde.

| Quintile | Charge directe (% revenu) | Charge enchassee (% revenu) | Total |
|---|---:|---:|---:|
| Q1 (plus pauvres) | 8,0% | **9,3%** | 17,3% |
| Q2 | 8,6% | 9,9% | 18,5% |
| Q3 | 9,0% | 10,3% | 19,3% |
| Q4 | 9,7% | 10,7% | 20,4% |
| Q5 (plus riches) | 9,8% | 10,4% | 20,2% |

---

## 4. Recommandations pour la suite

1. **Reforme TVA (Step 15)** : utiliser la matrice locale pour simuler les reformes de passage de 0% a 9% sur les produits agricoles. L'impact sera probablement plus fort que prevu initialement.
2. **Mapping fin** : affiner la correspondance `codpr` <-> `Produits TRE` pour les secteurs cles comme le cacao et l'energie.
3. **Impots directs (Step 16)** : calculer l'IRPP pour obtenir le *Net Market Income* et verifier si la progressivite de l'impot direct compense la charge TVA.

---

## 5. Ajout du TRE constant 2023

Le fichier `01_data_sources/IO/TRE_CONSTANT_2023.XLS` peut servir pour l'etape Input/Output, mais comme **scenario de robustesse** plutot que comme remplacement direct du TRE courant.

- Baseline recommandee : `TRE_COURANT_2023.XLS`, car l'incidence TVA et le modele de prix de Leontief travaillent sur des flux monetaires et des taux ad valorem.
- Scenario de sensibilite : `TRE_CONSTANT_2023.XLS`, utile pour verifier si les resultats dependent de la structure des prix courants.

Usage :

```r
# Extraction des deux matrices
source("05_scripts_R/extract_local_io.R")

# Baseline courant
source("05_scripts_R/13b_leontief_local_io.R")
source("05_scripts_R/14b_leontief_poverty_local.R")

# Scenario constant
Sys.setenv(IO_LOCAL_BASIS = "constant")
source("05_scripts_R/13b_leontief_local_io.R")
source("05_scripts_R/14b_leontief_poverty_local.R")
Sys.unsetenv("IO_LOCAL_BASIS")
```

Resultats rapides obtenus apres integration :

| Base TRE | TVA enchassee moyenne (FCFA/menage) | Total TVA enchassee | P0 total |
|---|---:|---:|---:|
| Courant | 255 956 | 1,65e12 FCFA | 53,7% |
| Constant | 269 581 | 1,74e12 FCFA | 54,2% |
