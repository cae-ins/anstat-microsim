---
date: 2026-07-19
branch: rewrite-r
plan: (none on disk; implementation plan is documented in 00_documentation/CEQ_ROADMAP.md)
session-log: (none on disk)
status: paused
---

# Checkpoint — Refine.ink et reproductibilité CEQ

## Goal

Achever les corrections Refine.ink, rendre le papier et les 26 étapes cohérents,
et livrer une réplication utilisable par un économiste ou par un agent.

## Where I am

Le travail analytique est achevé sur l'arbre courant. Les neuf remarques
Refine.ink sont traitées dans le code et le papier v17. La réplication intégrale
du 19 juillet 2026 a duré 350,4 secondes : 40 PASS au prévol, 32 PASS à la
vérification, aucun échec. Le PDF v17 compte 52 pages. Le code, le papier et le paquet de réplication sont destinés à la branche
rewrite-r; les données seront distribuées séparément par MinIO après
configuration et contrôle des droits.

## File pointers

- `00_documentation/working_paper/DT_CEQ_CIV2021.tex:923` — une non-réponse ne constitue jamais une preuve d'emploi formel.
- `05_scripts_R/16_direct_taxes.R:190` — le diagnostic de non-réponse conserve exactement le classement central.
- `00_documentation/working_paper/DT_CEQ_CIV2021.tex:968` — procédure PMT, variables, coupures et calage PSSN.
- `05_scripts_R/18_transfers.R:759` — PMT seul comme scénario central; déclarations utilisées uniquement en robustesse.
- `00_documentation/working_paper/quality_reports/response_to_refine_20260719.md:14` — réponse point par point aux neuf remarques.
- `00_documentation/working_paper/quality_reports/reproducibility_audit_DT_CEQ_CIV2021.md:1` — audit numérique : 0 FAIL, 0 UNMATCHED.
- `replication_package/README.md:1` — instructions humaines et instructions pour agent.
- `project_state.md:1` et `00_documentation/MEMOIRE_PARTAGEE_CEQ_CIV2021.md:1` — état et mémoire de reprise.

## Recent decisions

- Le PMT détermine seul l'allocation centrale du PSSN; les déclarations de
  l'enquête n'entrent que dans une robustesse « déclarations d'abord ».
- Un marqueur d'emploi manquant reste manquant et n'est jamais recodé positif.
- S3 est une hypothèse exogène publiée sous forme de matrice 15 × 10, pas une
  calibration ivoirienne.
- La valeur de 22,3 milliards est une sensibilité juridique de la TVA
  incorporée, pas une nouvelle estimation centrale.
- La réplication publique ne doit pas redistribuer les microdonnées restreintes.

## Open questions

Aucune question méthodologique ouverte. Les seules actions restantes relèvent
de la diffusion : périmètre du commit, licence institutionnelle et archive DOI.

## Next 1–3 actions

1. Faire approuver la licence du code et préparer l'archive pérenne.
2. Configurer l'accès MinIO sans versionner les identifiants.
3. Exécuter le protocole sur un clone propre avec les données autorisées et
   consigner le résultat dans le contrôle DCAS.

## Resume prompt

> Resuming from checkpoint `quality_reports/checkpoints/2026-07-19_refine-reproductibilite-ceq.md`. Read it, then continue with action 1.