# Exigences de calcul

- Système de référence : Windows 11 x86_64.
- R : 4.5.3 (ucrt).
- Gestionnaire : renv 1.2.3; `renv.lock` à la racine.
- Aléa : Mersenne-Twister; inversion pour les lois continues; rejection pour l'échantillonnage discret. Chaque bootstrap ou tirage possède une graine explicite dans le script correspondant.
- Mémoire recommandée : 16 Go ou plus.
- Espace libre recommandé : 10 Go pour les sources, bibliothèques, fichiers parquet, classeurs et journaux.
- Stata : requis uniquement pour reconstruire les sorties harmonisées EHCVM depuis les modules bruts; non requis lorsque les trois fichiers `Dataout` autorisés sont déjà produits.
- La version exacte de Stata et les extensions ado utilisées par les programmes officiels doivent être consignées par la personne qui refait cette préparation amont; les programmes hérités ne portent pas encore de directive `version` homogène.
- Compilation du document : distribution TeX Live/MiKTeX avec `pdflatex`, `bibtex`, TikZ, booktabs, longtable, natbib et dépendances déclarées dans le préambule.
- Temps observé pour les 26 étapes sur la machine de référence : 350,4 secondes (environ 5 minutes 50 secondes); la durée varie selon le matériel.
