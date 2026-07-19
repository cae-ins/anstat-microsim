# Guide d’exécution pour un agent

Objectif : reproduire le document sans modifier les hypothèses, sans exfiltrer les données et sans masquer les échecs.

1. Se placer à la racine et lire `replication_package/README.md`, `data/data_manifest.csv`, `data/access-restricted-data.md` et `replication_spec.json`.
2. Exécuter `Rscript replication_package/code/00_preflight.R`.
3. Si une donnée à accès conditionnel manque, arrêter et indiquer son chemin, son producteur et la procédure d’accès. Ne jamais créer un substitut ni renommer un fichier différent.
4. Si un paramètre du projet manque ou si son empreinte diffère, arrêter et signaler la divergence de version.
5. Restaurer l’environnement avec `renv::restore()` lorsque `renv.lock` est disponible; ne pas mettre à niveau un paquet pendant la reproduction.
6. Exécuter `Rscript replication_package/code/00_run_all.R`.
7. Lire `replication_package/output/verification_report.csv`. Une ligne `FAIL` rend la reproduction non conforme même si R s’est terminé.
8. Comparer les sorties au `exhibit_map.csv`; ne pas modifier le manuscrit pour forcer une concordance.
9. Rapporter le commit, la version de R, la durée, le nombre de contrôles PASS/FAIL et tout écart.

Commandes autorisées : lectures, empreintes, restauration de l’environnement, exécution du pipeline et compilation locale. Interdictions : publication des microdonnées, copie hors du dépôt, modification des données sources, suppression d’un échec, installation non consignée ou envoi vers un service externe.
