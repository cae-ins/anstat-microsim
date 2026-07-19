# Contrôle de conformité au Data and Code Availability Standard

| Exigence | État | Preuve ou action |
|---|---|---|
| Déclaration d’accès aux données | Oui | `data/access-restricted-data.md` |
| Inventaire des données | Oui | `data/data_manifest.csv` |
| Code et transformations | Oui | 05_scripts_R, étapes 1 à 26 versionnées sur rewrite-r |
| Script maître | Oui | `code/00_run_all.R` appelle les 26 étapes |
| Environnement et versions | Oui | `renv.lock`, `environment/` |
| Graines et aléa | Oui | graines explicites dans les modules; RNG enregistré |
| Carte tableaux/figures vers le code | Oui | `exhibit_map.csv` couvre les 34 labels du papier |
| Tests de résultats | Oui | 32 PASS, 0 FAIL dans `output/verification_report.csv` |
| Journal et durée | Oui | Exécution intégrale du 19 juillet 2026 : 350,4 secondes; journal `output/logs/full_run_20260719_220317.log` |
| Licence du code | Action auteur/institution | `LICENSE_ACTION_REQUIRED.md` |
| Archive pérenne et DOI | Action avant soumission | Déposer la version figée sur l’archive choisie |
| Vérification sur clone propre | Après configuration MinIO | Relancer sur un clone neuf lorsque les données autorisées seront distribuées par MinIO |
