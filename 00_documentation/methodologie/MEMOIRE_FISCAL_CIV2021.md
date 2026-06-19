# MÉMOIRE FISCALE : Barèmes et Règles Côte d'Ivoire (2021)
# Pour l'étape 16 du modèle CEQ (Impôts directs)

## 1. Concepts de base
*   **SBI (Salaire Brut Imposable)** : Somme des salaires, primes et avantages en nature.
*   **Base Imposable (BI)** : 80% du SBI (après abattement de 20% pour frais professionnels).

## 2. Impôts Cédulaires (Mensuels)
### A. Impôt sur les Salaires (IS)
*   **Formule** : BI * 1,5% (soit SBI * 1,2%)

### B. Contribution Nationale (CN)
*   S'applique sur la BI selon les tranches :
    *   0 - 50 000 : 0%
    *   50 001 - 130 000 : 1,5%
    *   130 001 - 200 000 : 5%
    *   > 200 000 : 10%

## 3. Impôt Général sur le Revenu (IGR)
### A. Base IGR (R)
*   **Formule** : 80% * (SBI - IS - CN)

### B. Quotient Familial (N)
*   Nombre de parts plafonné à 5 :
    *   Célibataire / Divorcé : 1 part
    *   Marié : 2 parts
    *   Veuf (sans enfant) : 1,5 part
    *   Enfant à charge : +0,5 part (1 part si infirme)

### C. Barème IGR (Tranches mensuelles de Q = R/N)
*   Q <= 25 000 : 0%
*   25 000 < Q <= 45 000 : (Q * 10/110) - 2 273
*   45 000 < Q <= 60 000 : (Q * 15/115) - 4 076
*   60 000 < Q <= 80 000 : (Q * 20/120) - 7 083
*   80 000 < Q <= 100 000 : (Q * 25/125) - 11 000
*   100 000 < Q <= 120 000 : (Q * 30/130) - 15 769
*   120 000 < Q <= 140 000 : (Q * 35/135) - 21 296
*   140 000 < Q <= 160 000 : (Q * 40/140) - 27 500
*   160 000 < Q <= 180 000 : (Q * 45/145) - 34 310
*   180 000 < Q <= 200 000 : (Q * 50/150) - 41 667
*   Q > 200 000 : (Q * 60/160) - 57 813

*Note : L'IGR final est (IGR_par_part * N) * 0,85 (réduction de 15%).*

## 4. Cotisations Sociales
### A. CNPS (Part Salariée)
*   **Retraite** : 6,3% du SBI plafonné à 1 647 315 FCFA / mois.

### B. CMU
*   **Montant** : 1 000 FCFA / mois par membre du ménage.
*   **Simulation** : Retenue de 500 FCFA sur le salaire (part salarié).

## 5. Identification dans l'EHCVM (Module s04)
*   **Revenu Brut** : `s04q43` (Base) + `s04q45` (Primes) + `s04q47` (Avantages).
*   **Formalité** : `s04q42 == 1` (Bulletin de paie) ET `s04q38 == 1` (Cotisation sociale).

---
*Date de mise à jour : 23 Mai 2026*
