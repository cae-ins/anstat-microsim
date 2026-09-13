# T0 — Référentiel de départ (round 5)

Date : 2026-09-06. Objectif : figer un état de référence pour l'audit d'invariance du round 5 (rapport de référé *Journal of African Economies*). Aucun fichier autre que ce mémo et les copies décrites ci-dessous n'a été modifié.

## Référentiel git

```
git rev-parse HEAD
90515e7207105457bf3b59803a1a2c0f1fcf0dec

git status --short
```

Sortie complète de `git status --short` au moment du figeage (branche `rewrite-r`) : uniquement des fichiers non suivis, aucune modification de fichier suivi.

```
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v10.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v11.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v12.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v13.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v14.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v15.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v16.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v18.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v19.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v2.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v20.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v21.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v22.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v3.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v4.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v5.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v6.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v7.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v8.pdf
?? 00_documentation/working_paper/DT_CEQ_CIV2021_v9.pdf
?? 00_documentation/working_paper/Diebolt/round5/
```

(La dernière ligne, le dossier `Diebolt/round5/`, est celle créée par cette tâche T0 elle-même — il n'existait pas d'entrée `M` ou `??` autre au moment de `git status`.)

## Copies en lecture seule (`Diebolt/round5/baseline/`)

Tous les éléments demandés existaient et ont été copiés avec succès :

| Source | Copie |
|---|---|
| `00_documentation/working_paper/generated/ceq_summary_values.tex` | `baseline/ceq_summary_values.tex` |
| `00_documentation/working_paper/DT_CEQ_CIV2021.pdf` | `baseline/DT_CEQ_CIV2021.pdf` |
| `07_reports/tables/06/` | `baseline/07_reports_tables_06/` |
| `07_reports/tables/12/` | `baseline/07_reports_tables_12/` |
| `07_reports/tables/13/` | `baseline/07_reports_tables_13/` |
| `07_reports/tables/14/` | `baseline/07_reports_tables_14/` |
| `07_reports/tables/22/` | `baseline/07_reports_tables_22/` |
| `07_reports/tables/23/` | `baseline/07_reports_tables_23/` |
| `07_reports/tables/24/` | `baseline/07_reports_tables_24/` |
| `07_reports/tables/25/` | `baseline/07_reports_tables_25/` |

Aucun dossier manquant.

## Comptages

### Flottants dans le corps de `DT_CEQ_CIV2021.tex`

`\appendix` apparaît à la ligne 2264. Recensement de `\begin{table}`, `\begin{figure}` et `\begin{longtable}` avant cette ligne :

- Tables (`\begin{table}`) : 15 (lignes 177, 241, 1156, 1235, 1276, 1354, 1414, 1444, 1531, 1701, 1754, 1825, 1941, 2020, 2092)
- Figures (`\begin{figure}`) : 15 (lignes 517, 720, 1212, 1334, 1394, 1512, 1601, 1634, 1656, 1678, 1783, 1802, 1858, 1908, 2142)
- Longtables (`\begin{longtable}`) : 1 (ligne 300)

**Total flottants du corps : 31** (15 tables + 15 figures + 1 longtable).

Pour référence, après `\appendix` (annexes) : 6 flottants supplémentaires (`table` aux lignes 2284, 2402, 2495 ; `longtable` aux lignes 2349, 2790, 2871).

### Pages du PDF compilé

`pdfinfo DT_CEQ_CIV2021.pdf` → **62 pages** (A4, 595.276 × 841.89 pts ; MiKTeX pdfTeX-1.40.28 ; compilé le 2026-09-06 11:52:08).

### Résumé (abstract)

Commande utilisée dans le document : environnement `\begin{abstract}...\end{abstract}` standard (lignes 60–62), texte introduit par `\noindent`, un seul paragraphe.

Comptage par découpage sur les espaces (macros LaTeX telles que `\GiniPrimaire{}`, `\PauvretePrimaire{}`, `\PauvreteConsommable{}`, `\PartNouveauxPauvres{}`, `\PauvreteFinale{}` comptées comme un seul mot chacune, cohérent avec le fait qu'elles s'évaluent à une seule valeur numérique après compilation) :

**238 mots.**

## Prochaine étape

Ce fichier et le dossier `baseline/` servent de référence pour les vérifications d'invariance de T1, T2 et de l'audit T12 (comparaison des masses S1–S3, indices Kakwani/RS, ΔP0, macros de tête de `ceq_summary_values.tex`, nombre de pages et de flottants après restructuration T10).
