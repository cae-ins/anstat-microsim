# Données non redistribuées et procédure d’accès

## EHCVM Côte d’Ivoire 2021–2022

Producteurs : ANStat et partenaires de l’EHCVM. La version publique anonymisée est référencée `CIV_2021_EHCVM-2_v01_M` dans le catalogue de microdonnées de la Banque mondiale : https://microdata.worldbank.org/index.php/catalog/6273. L’utilisateur doit accepter les conditions de confidentialité et de citation du catalogue. Le portail statistique de l’ANStat est également indiqué dans le README principal.

Le pipeline R utilise trois fichiers harmonisés dans `01_data_sources/Dataout/` et sept modules détaillés dans `01_data_sources/Datain/Menage/`. Les fichiers `Dataout` sont des sorties des programmes officiels EHCVM conservés dans `01_data_sources/Programs/`; ils ne doivent pas être remplacés par un simple renommage des modules téléchargés. Si l’utilisateur part des modules bruts, il doit adapter les chemins dans une copie locale des programmes Stata, exécuter la préparation et documenter sa version de Stata.

## Tableaux ressources-emplois de l’ANStat

Les fichiers `TRE_COURANT_2023.XLS` et `TRE_CONSTANT_2023.XLS` doivent être placés dans `01_data_sources/IO/`. Ils proviennent des publications de comptabilité nationale de l’ANStat. Le script `extract_local_io_v4.R` les convertit automatiquement lorsque les fichiers extraits sont absents. Vérifier les conditions de réutilisation avant redistribution.

## Matrice internationale CIV2020ttl.csv

`01_data_sources/IO/CIV2020ttl.csv` est une matrice internationale utilisée seulement comme robustesse. La redistribution doit respecter les conditions du producteur. Son absence empêche la reproduction de la variante ICIO, mais pas la lecture des résultats archivés.

## Stockage MinIO prévu

Aucun fichier du répertoire `01_data_sources` n'est inclus dans le commit du
papier de la branche `rewrite-r`. L'équipe prévoit de distribuer les fichiers autorisés depuis MinIO
dans une étape ultérieure, en conservant exactement les chemins du manifeste.
Tant que cette synchronisation n'est pas configurée, le reproducteur doit
placer localement les fichiers autorisés à ces chemins. Les URL privées, clés
d'accès et secrets MinIO restent dans un fichier `.env` local et ne doivent
jamais être versionnés.

## Règle de sécurité

Aucun de ces fichiers ne doit être ajouté à un dépôt public sans autorisation explicite. Les empreintes du manifeste servent à identifier une version locale; elles ne confèrent aucun droit de diffusion.
