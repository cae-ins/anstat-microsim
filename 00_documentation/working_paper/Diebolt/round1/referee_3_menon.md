# Rapport du Rapporteur 3 — Premier tour

**Pr Rajiv Menon** — Delhi School of Economics. Spécialisation : finances
publiques des pays en développement, TVA et informalité.
*Manuscrit soumis à World Development.*

## Résumé

Le manuscrit propose une analyse CEQ de la TVA et des impôts directs ivoiriens
avec trois apports revendiqués : informalité paramétrée à la Bachas-Gadenne-
Jensen, TVA enchâssée sur matrice nationale, couverture documentée de l'impôt
direct. Le deuxième apport est réel et important. Mais le papier ignore la
littérature qui a déjà fait une bonne partie de ce qu'il présente comme neuf —
littérature publiée, pour l'essentiel, dans la revue même où il est soumis.

## Commentaires majeurs

1. **L'engagement avec Warwick et al. (2022, World Development) est
   indispensable — et absent.** Warwick, Harris, Phillips, Goldman, Jellema,
   Inchauste et Goraus-Tańska (« The redistributive power of cash transfers vs
   VAT exemptions: A multi-country study », *World Development* 151, 2022)
   mesurent, pour six pays à revenu faible et intermédiaire dont le Sénégal
   voisin, l'incidence des exonérations de TVA **en incorporant la TVA enchâssée
   via des tableaux entrées-sorties** — exactement la mécanique de la
   section 4.3 — dans le cadre des modèles TAXDEV de l'IFS. La revendication de
   nouveauté doit donc être repositionnée : ce qui est nouveau ici n'est pas de
   mesurer la TVA enchâssée par entrées-sorties, mais (i) de le faire pour la
   Côte d'Ivoire et (ii) de montrer que le passage d'une matrice internationale
   à la matrice nationale double la mesure. Ce second point est une vraie
   contribution méthodologique d'intérêt général — c'est lui qu'il faut mettre
   en avant, en dialoguant avec la pratique TAXDEV. Dans le même mouvement, la
   conclusion de Warwick et al. — l'élargissement d'assiette n'est défendable
   que recyclé en protection sociale — devrait discipliner la lecture de la
   simulation « 9 % » (voir point 3).

2. **Le modèle de prix de Leontief est sous-spécifié dans le texte.** Trois
   clarifications s'imposent. (a) La construction du vecteur $t$ : des taux
   statutaires moyens par secteur, moyennés sur les produits — pondérés
   comment ? Une moyenne non pondérée sur les codes produits n'a pas
   d'interprétation économique ; il faut pondérer par les valeurs de
   consommation ou de production. (b) Le mécanisme économique : la TVA enchâssée
   naît de la **rupture de la chaîne de déduction** chez les producteurs
   exonérés ; appliquer $(I-A')^{-1}t$ à tout le panier revient à supposer
   qu'aucun secteur ne déduit sa TVA d'amont, ce qui surestime l'enchâssement
   pour les chaînes taxées de bout en bout. La spécification correcte annule la
   composante amont des secteurs dont la production est taxée (droit à
   déduction) et ne propage que celle des secteurs exonérés. Il faut démontrer
   que c'est bien ce qui est fait, sinon le facteur deux du TRE pourrait être en
   partie mécanique. (c) L'articulation avec la TVA directe : « appliquer
   $\Delta p$ au panier hors TVA directe » doit exclure tout double comptage —
   un lemme d'une demi-page en annexe réglerait la question.

3. **La simulation de réforme ignore ses propres leçons sur l'informalité.**
   Toute la section 5.1 démontre que le pass-through effectif dépend de
   l'informalité ; puis la section 6.2 simule le passage à 9 % sous transmission
   complète uniquement. C'est incohérent : les produits exonérés (alimentaire de
   base) sont précisément les plus achetés dans l'informel, donc la recette
   « théorique » de 276 milliards et les 80 211 nouveaux pauvres sont des bornes
   hautes probablement très éloignées du réel. Il faut rejouer la réforme sous
   S2 et S3 — le pipeline le permet manifestement — et présenter l'éventail. Sur
   le pass-through lui-même, citer les preuves empiriques : Benedek, de Mooij,
   Keen et Wingender (« Varieties of VAT pass through », *International Tax and
   Public Finance*, 2020) trouvent un pass-through complet pour les changements
   de taux normal mais très incomplet pour les taux réduits et exonérations —
   directement pertinent ici.

4. **L'assiette « salaire harmonisé » est trop opaque pour porter l'impôt
   direct.** La variable `salaire` de l'EHCVM harmonisée agrège-t-elle primes et
   avantages en nature (champ de l'assiette de l'IS ivoirien) ou le seul salaire
   de base ? Les mois travaillés (variable s04q32) sont-ils pris en compte dans
   l'annualisation ? Selon la réponse, l'assiette bouge de 10 à 20 %. Le papier
   doit documenter la construction exacte et, idéalement, la borner par une
   reconstruction directe depuis les questions brutes s04q43/45/47.

## Commentaires mineurs

1. Jensen (2022) sur la structure de l'emploi et la capacité fiscale serait une
   meilleure ancre que Lustig (2017) pour l'argument « l'assiette directe est
   bornée par la formalité ».
2. La note du tableau 4 devrait rappeler que 39,2 % des ménages du décile 10 ont
   un salarié formel — le chiffre est dans le texte mais c'est la clé du
   tableau.
3. Le ratio « 290 nouveaux pauvres par milliard collecté » est parlant :
   le calculer aussi pour S_agri (280) et le mettre dans le tableau 5.
4. Préciser si les 9 % de la réforme s'appliquent aussi à la composante
   enchâssée (a priori non — le dire).
5. La bibliographie cite le CEQ Handbook 2018 ; l'édition à jour est 2023.

## Recommandation

**Révisions majeures.** La contribution « matrice nationale vs internationale »
mérite publication dans World Development ; elle exige d'être correctement
positionnée par rapport à Warwick et al. (2022) et techniquement blindée sur la
mécanique de déduction.
