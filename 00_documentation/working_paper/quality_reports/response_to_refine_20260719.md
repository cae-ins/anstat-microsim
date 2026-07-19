# Réponse aux remarques de Refine.ink

**Manuscrit :** *Fiscalité, informalité, transferts et pauvreté en Côte d'Ivoire : une analyse d'incidence sur l'EHCVM 2021*
**Support :** Document de travail ANStat, version 17
**Évaluation :** Refine.ink, 19 juillet 2026
**Date de la réponse :** 19 juillet 2026

## Vue d'ensemble

Nous avons traité les neuf remarques méthodologiques. La révision publie la matrice exacte du scénario S3, sépare le taux statutaire, le droit à déduction et la collecte finale, ajoute une sensibilité juridique de la TVA incorporée, renomme le contrefactuel de taxe à 9 %, ajoute une allocation PSSN « déclarés d'abord » et reconstruit les scénarios d'impôts directs sur une assiette salariale commune. Elle précise aussi les dénominateurs de TVA, l'hypothèse de cascade dans les accises et les unités des identités CEQ. Les 26 étapes ont ensuite été rejouées depuis les entrées et les 32 contrôles numériques ont réussi.

## Réponses point par point

### R1.1 — Publication du paramétrage S3

**Remarque abrégée :**
> « Publier ces paramètres et montrer les profils implicites de formalité par décile. »

**Classification :** Addressed

**Réponse :** La méthode donne désormais la règle exacte $\alpha_{kd}=\min\{a_k+(d-1)s_k,1\}$ et dit explicitement que les paramètres sont exogènes, non estimés sur l'EHCVM et non calés sur une cible administrative. L'annexe C publie $a_k$, $s_k$ et les 150 cellules de la matrice COICOP par décile, puis le profil implicite pondéré, de 0,266 en D1 à 0,578 en D10. Le classeur `06_03_vat_informality_parameters.xlsx` fournit les mêmes objets sous forme lisible par machine. S3 est ainsi présenté comme une hypothèse structurante inspirée de Bachas, Gadenne et Jensen, et non comme une mesure ivoirienne estimée.

**Localisation :** manuscrit, section « TVA directe et probabilité de taxation effective », lignes 680–710; annexe C, lignes 2245–2299; tableau 18, p. 45. Code : `05_scripts_R/utils/vat_scenarios.R`; sortie : `07_reports/tables/06/06_03_vat_informality_parameters.xlsx`.

### R1.2 — Séparer les objets de la TVA incorporée

**Remarque abrégée :**
> « Séparer conceptuellement le taux statutaire, le droit à déduction et la transmission lors de la vente finale. »

**Classification :** Addressed

**Réponse :** La révision distingue maintenant trois objets : $\bar\tau_i$ mesure le taux statutaire moyen sur les intrants, $e_i$ approche la fraction de production ouvrant droit à déduction et $\alpha_{kh}$ décrit la collecte et la transmission à la vente finale. Une sensibilité remplace $e_i$ par un classement juridique binaire des produits structurellement exonérés. Elle ramène la TVA incorporée de 214,4 à 22,3 milliards de FCFA et la charge totale de 907,3 à 719,0 milliards. Le papier souligne que ce contrôle est volontairement grossier et que le résultat central n'est pas robuste au choix de $e_i$.

**Localisation :** méthode, lignes 749–791; résultats, lignes 1344–1388; tableau 7, p. 24. Code : `05_scripts_R/13b_leontief_local_io.R`; sortie : `07_reports/tables/13/13_07_legal_deduction_sensitivity.xlsx`.

### R1.3 — Mettre le nom de la réforme en accord avec le choc simulé

**Remarque abrégée :**
> « Renommer la simulation comme une taxation de la vente finale à vecteur c constant. »

**Classification :** Addressed

**Réponse :** Le manuscrit parle désormais d'une taxe de 9 % sur la vente finale à TVA incorporée constante. Il précise que le calcul ne simule pas une reclassification juridique complète et n'ouvre pas de nouveaux droits à déduction. Cette formulation est reprise dans le résumé, l'introduction, la méthode, les résultats, les légendes et la conclusion. Le script et ses messages utilisent le même libellé.

**Localisation :** résumé, lignes 43–58; méthode, lignes 1208–1235; résultats, lignes 1947–2012; tableau 15, p. 36. Code : `05_scripts_R/15_reform_vat_simulation.R`.

### R1.4 — Confronter le PMT aux bénéficiaires déclarés du PSSN

**Remarque abrégée :**
> « Intégrer en priorité les bénéficiaires déclarés, avant de combler les quotas via le PMT. »

**Classification :** Addressed

**Réponse :** Une robustesse « déclarés d'abord » retient les 24 989 ménages pondérés qui déclarent le programme dans S15, puis complète la cible par ordre de PMT. Elle sélectionne 192 544 ménages, retrouve exactement 27,108 milliards de FCFA après calage et ramène la part de bénéficiaires pauvres de 85,9 % à 79,5 %. Le PMT reste central parce que S15 ne permet de vérifier ni l'identité administrative exacte du programme ni le montant reçu. Le texte ne présente donc plus le ciblage PMT comme l'incidence observée du registre.

**Localisation :** méthode, lignes 966–1026; résultats, lignes 1620–1626; tableau 11, p. 29. Code : `05_scripts_R/18_transfers.R`; sortie : feuille `robustesse_declares_dabord` de `07_reports/tables/18/18_02_coverage_targeting.xlsx`.

### R1.5 — Expliquer et corriger l'inversion des scénarios d'impôts directs

**Remarque abrégée :**
> « Le scénario strict génère paradoxalement davantage d'IRPP que le scénario central. »

**Classification :** Addressed

**Réponse :** L'inversion provenait de définitions salariales différentes entre les variantes. Les scénarios utilisent maintenant la même rémunération annualisée et ne diffèrent que par le critère d'assujettissement. Le scénario strict retient 616 327 personnes et 192,0 milliards d'IRPP; l'élargi 902 080 personnes et 215,6 milliards; le central 1 087 154 personnes et 225,5 milliards. Le nouveau tableau publie aussi la masse salariale et les cotisations de chaque scénario. Une non-réponse n'est jamais considérée comme un emploi formel : elle reste manquante, et le diagnostic de non-réponse ne crée aucun assujetti.

**Localisation :** méthode, lignes 897–931; tableau 10, p. 27; discussion, lignes 1551–1562. Code : `05_scripts_R/16_direct_taxes.R`; sortie : feuille `profils_scenarios` de `07_reports/tables/16/16_07_robustness_diagnostics.xlsx`.

### R1.6 — Définir la convention additive du vecteur c

**Remarque abrégée :**
> « Les fractions sont cohérentes seulement si c est une composante additive du prix. »

**Classification :** Addressed

**Réponse :** Le texte définit maintenant $c$ comme une part additive du prix final, au même niveau que la TVA finale, et non comme un multiplicateur de coût appliqué avant la TVA. Il explique que cette convention produit le dénominateur $1+\tau+c$ sans terme croisé $\tau c$. Une convention multiplicative est reconnue comme un autre modèle de prix.

**Localisation :** méthode, lignes 824–829, équation 16, p. 14.

### R1.7 — Distinguer la formule de TVA directe isolée du calcul central

**Remarque abrégée :**
> « La différence rend ambiguë la formule effectivement utilisée pour les résultats centraux. »

**Classification :** Addressed

**Réponse :** L'équation 8 porte désormais l'exposant « isolée » et ne s'applique qu'aux diagnostics sans TVA incorporée. Le texte indique immédiatement que les résultats centraux utilisent la décomposition conjointe de l'équation 16 et son dénominateur commun $1+\tau+c$. L'ambiguïté entre les deux étapes du calcul est ainsi supprimée.

**Localisation :** méthode, lignes 680–693, équation 8, p. 12; équation 16, p. 14.

### R1.8 — Expliciter l'interaction entre alpha et la TVA dans les accises

**Remarque abrégée :**
> « Le calcul semble supposer que le prix hors marges inclut toujours la TVA de la cascade amont. »

**Classification :** Addressed

**Réponse :** La méthode énonce désormais cette hypothèse. Le facteur $(1+r_k)$ représente une couche de TVA payée en amont qui reste contenue dans le prix hors marges, tandis que $\alpha_{kh}$ porte seulement sur la collecte à la vente finale. Le texte précise aussi le sens du biais si l'informalité supprimait cette couche amont du prix observé.

**Localisation :** méthode, lignes 859–884, équation 18, p. 15.

### R1.9 — Rendre homogènes les unités des identités CEQ

**Remarque abrégée :**
> « Les identités laissent une ambiguïté d'unités entre revenu par tête et taxes du ménage. »

**Classification :** Addressed

**Réponse :** Toutes les variables $Y_{\cdot h}$ sont maintenant définies comme des montants annuels réels par personne. Les taxes, réductions de prix, services d'éducation et services de santé sont d'abord agrégés et déflatés au ménage, puis divisés par sa taille : $i_h=I_h/n_h$, $s_h=S_h/n_h$, $e_h=E_h^{net}/n_h$ et $q_h=H_h^{net}/n_h$. Les identités ne mélangent donc plus un total du ménage et un revenu par personne.

**Localisation :** méthode, lignes 627–650, équation 7, p. 11.

## Matrice de suivi

| ID | Importance | Objet | Classification | Localisation principale |
|---|---|---|---|---|
| R1.1 | Majeure | Paramètres S3 | Addressed | §4.3; annexe C; tableau 18 |
| R1.2 | Majeure | TVA incorporée et droit à déduction | Addressed | §4.5–4.6; tableau 7 |
| R1.3 | Majeure | Libellé du contrefactuel à 9 % | Addressed | §4.15; §6.2; tableau 15 |
| R1.4 | Majeure | PSSN déclarés d'abord | Addressed | §4.9; §5.6 |
| R1.5 | Majeure | Scénarios d'impôts directs | Addressed | §4.8; tableau 10 |
| R1.6 | Technique | Convention additive de c | Addressed | §4.6 |
| R1.7 | Technique | Dénominateur de TVA directe | Addressed | §4.3 et §4.6 |
| R1.8 | Technique | Couche de TVA dans les accises | Addressed | §4.7 |
| R1.9 | Technique | Unités des identités CEQ | Addressed | §4.2 |

## Vérification post-révision

- Les neuf remarques ont une classification et une localisation.
- Les chiffres cités ci-dessus ont été relus dans les classeurs produits par le pipeline.
- La reproduction complète a donné 40 contrôles préalables réussis, puis 32 contrôles numériques réussis et aucun échec.
- Le manuscrit v17 compile en 52 pages sans référence manquante ni débordement de boîte.

## Post-Flight Verification

**Claims extracted:** 9
**Verified against source files and generated outputs:** 9
**Outcome:** PASS

La vérification a été exécutée séquentiellement, car la délégation à un sous-agent était désactivée pour cette session. Les neuf affirmations correspondent au manuscrit, aux classeurs et aux rapports de reproduction. Le détail probant figure dans `postflight_verification_refine_20260719.md`.
