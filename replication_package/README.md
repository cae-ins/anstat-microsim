# Paquet de réplication — CEQ Côte d’Ivoire 2021

Ce dossier permet à un économiste de reconstruire les résultats du document de travail à partir des données autorisées. Il ne contient pas les microdonnées EHCVM ni les tableaux ressources-emplois dont la redistribution dépend de leurs conditions d’accès.

## Résultat attendu

Une exécution complète produit les fichiers intermédiaires dans `02_data_intermediate/`, les tableaux et figures dans `07_reports/`, puis vérifie les identités comptables et un noyau de résultats publiés. Le rapport final de contrôle est écrit dans `replication_package/output/verification_report.csv`.

## 1. Obtenir le code

```bash
git clone --branch rewrite-r --single-branch https://github.com/cae-ins/anstat-microsim.git
cd anstat-microsim
```

Conserver le résultat de `git rev-parse HEAD` avec les résultats reproduits.

## 2. Obtenir les données

Lire `data/access-restricted-data.md`, accepter les conditions des producteurs et placer chaque fichier au chemin exact indiqué dans `data/data_manifest.csv`. Aucun fichier de données ni classeur de paramètres n'est versionné dans ce commit. Leur distribution par le stockage MinIO du projet sera configurée ultérieurement; jusque-là, les fichiers autorisés doivent être placés localement aux chemins du manifeste. Les identifiants MinIO ne doivent jamais être ajoutés au dépôt.

## 3. Restaurer l’environnement

R 4.5.3 est l’environnement de référence. Une fois `renv` 1.2.3 installé :

```bash
Rscript --vanilla replication_package/code/00_restore_environment.R
```

Le fichier `environment/package_versions.csv` donne aussi les versions effectivement utilisées. Stata n’est requis que pour reconstruire les trois fichiers harmonisés `Dataout` à partir des modules bruts; l’analyse principale R commence à partir de ces fichiers harmonisés.

## 4. Préparer puis exécuter

Depuis la racine du dépôt :

```bash
Rscript --vanilla replication_package/code/00_preflight.R
Rscript --vanilla replication_package/code/00_run_all.R
```

Sous PowerShell Windows, si R affiche `Setting LC_COLLATE=(null) failed`, définir d'abord `$env:LC_COLLATE='C'`. Cela évite seulement un avertissement de démarrage; les sorties vérifiées restent identiques.

Le premier script ne modifie aucune donnée. Il vérifie les fichiers, empreintes, paquets, espace disque et droits d'écriture. Le second lance les 26 étapes, enregistre un journal horodaté et exécute les contrôles finaux.

Pour vérifier des sorties déjà construites sans recalculer le modèle :

```bash
Rscript --vanilla replication_package/code/01_verify_outputs.R
```

## Temps et ressources

La machine de référence utilise Windows 11, R 4.5.3 et 16 Go de mémoire ou davantage. Le dernier test complet a duré 452,17 secondes, soit environ 7 minutes 32 secondes, sur la machine de référence. Le temps exact est enregistré dans `output/runtime.txt` et varie avec le processeur, le disque et les 500 réplications Rao–Wu.

## Ce qui est vérifié automatiquement

- présence et empreinte MD5 des entrées attendues;
- fermeture, ménage par ménage, des identités de revenu consommable et final;
- fermeture de la décomposition de Shapley;
- présence du classeur final et des quatre fichiers maîtres;
- reproduction, dans les tolérances publiées, des principaux Gini, taux de pauvreté, masses et diagnostics de ciblage;
- absence de chemin absolu propre à la machine dans le code d’analyse principal.

Le dernier contrôle donne 41 PASS au pré-contrôle et 32 PASS à la vérification finale, sans échec. La vérification confirme aussi la présence des sorties et la parité des 33 labels de tableaux et figures avec `exhibit_map.csv`. L'audit des affirmations numériques principales se trouve dans `../00_documentation/working_paper/quality_reports/reproducibility_audit_DT_CEQ_CIV2021.md`; son fichier structuré est `reproducibility_claims_DT_CEQ_CIV2021.json` dans le même dossier.

## Reproduction par un agent

Un agent doit suivre `AGENT_RUNBOOK.md` et le fichier `AGENTS.md` à la racine. Il ne doit jamais téléverser les microdonnées, contourner une condition d’accès ni remplacer silencieusement un fichier absent. Le fichier `replication_spec.json` fournit les mêmes instructions dans un format lisible par machine.

## Périmètre de diffusion

La licence du code et la licence des petits paramètres doivent être approuvées par les auteurs ou l’institution avant publication. Voir `LICENSE_ACTION_REQUIRED.md`. Les données tierces restent régies par leurs propres licences.
