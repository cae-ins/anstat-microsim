# Instructions aux agents — réplication CEQ CIV 2021

Le dépôt contient une microsimulation économique et des données à accès conditionnel. Pour toute tâche de réplication :

- lire d’abord `replication_package/AGENT_RUNBOOK.md` et `replication_package/replication_spec.json`;
- exécuter le pré-contrôle avant le pipeline;
- ne jamais téléverser, résumer ligne par ligne ou déplacer hors du dépôt les microdonnées EHCVM et les fichiers TRE;
- ne jamais inventer une donnée manquante ni remplacer silencieusement une version;
- conserver les graines, pondérations, déflateurs et paramètres fiscaux;
- écrire les journaux dans `replication_package/output/logs/`;
- considérer la reproduction réussie seulement si `verification_report.csv` ne contient aucun `FAIL`;
- présenter les résultats en français courant, en définissant les sigles et en distinguant clairement hypothèse centrale, robustesse et borne.

Commande standard depuis la racine :

```text
Rscript replication_package/code/00_run_all.R
```
