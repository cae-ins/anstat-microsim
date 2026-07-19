# Rapport du Rapporteur 2 — Premier tour

**Dr Ingrid Sørensen** — Development Economics Research Group, Université de
Copenhague. Spécialisation : économétrie appliquée de l'incidence fiscale,
inférence sur données d'enquête complexes.
*Manuscrit soumis à World Development.*

## Résumé

Le papier simule la TVA ivoirienne sous trois hypothèses d'informalité, mesure
la TVA enchâssée par un modèle de prix de Leontief sur deux matrices, et simule
les prélèvements directs sur les salariés formels. Les résultats sont présentés
avec soin et le pipeline paraît reproductible. Mon évaluation porte
exclusivement sur la rigueur statistique, qui présente quatre lacunes sérieuses.

## Commentaires majeurs

1. **L'inférence ignore le plan de sondage.** Le bootstrap des indices de
   Kakwani rééchantillonne les ménages de manière i.i.d. (500 réplications,
   percentile). Or l'EHCVM est une enquête stratifiée à deux degrés avec tirage
   de grappes ; l'inférence correcte exige un rééchantillonnage par grappes
   entières au sein des strates (rescaling bootstrap de Rao-Wu, ou linéarisation
   de Taylor comme dans `conindex` avec `svyset`). L'expérience montre que les
   erreurs-types i.i.d. sous-estiment la variance de 30 à 100 % sur ce type
   d'enquête. Les intervalles serrés du tableau 2 — par exemple
   $[-0{,}009\,;\,-0{,}003]$ pour le Kakwani strict — sont donc probablement
   trop optimistes, et la conclusion « significativement négatif » pourrait ne
   pas survivre. À refaire avec un bootstrap par grappes, et à appliquer aussi
   aux indices de l'étape des impôts directs.

2. **Aucune erreur-type sur les variations de FGT.** Les $\Delta P_0$ — le cœur
   du message du papier — sont présentés sans aucune mesure d'incertitude. Les
   variations de pauvreté entre concepts de revenu sur le même échantillon sont
   des statistiques corrélées dont la variance se calcule très bien par le même
   bootstrap par grappes. Je veux voir des intervalles de confiance sur
   +7,1 points (strict), +3,0 (S3) et surtout sur l'écart OCDE vs TRE
   (+11,3 vs +16,2 points), qui est la contribution phare.

3. **La winsorisation au P99 est faite au niveau ligne de dépense, tous
   produits confondus.** Cela tronque différemment les produits chers
   (électroménager, transport) et les produits fréquents bon marché, donc
   déforme la structure de l'assiette TVA elle-même — et pas de manière neutre
   selon les déciles. La pratique standard est de winsoriser par produit ou par
   fonction (au P99 de la distribution du produit), ou de montrer la robustesse
   des résultats à P95/P99/P99,5 et sans winsorisation. Au minimum, un tableau
   de sensibilité s'impose.

4. **Le choix du classement de bien-être doit être assumé, pas relégué en
   note.** Le papier admet que le Kakwani strict change de signe selon que l'on
   classe par consommation totale, par tête ou par adulte-équivalent — puis
   retient la consommation totale comme référence, ce qui est le choix le moins
   standard de la littérature (la pratique CEQ dominante est le par-tête ; cf.
   les tableaux types du CEQ Handbook). Il faut soit faire du par-tête le
   scénario central et de la consommation totale la robustesse, soit défendre
   explicitement le choix actuel. En l'état, le résultat mis en avant
   (« légèrement régressive sous transmission complète ») est celui de la
   spécification la plus fragile.

## Commentaires mineurs

1. Le texte donne le nombre de ménages basculant sous le seuil (« environ
   396 000 ») : préciser l'unité (ménages pondérés) et l'intervalle de
   confiance.
2. Les 19 ménages à revenu net négatif tronqués à zéro : donner la sensibilité
   du Reynolds-Smolensky à leur exclusion pure et simple.
3. Les régressions de déterminants (section 5.1) mentionnent des coefficients
   sans tableau dans le papier : soit un tableau en annexe, soit les retirer.
4. Préciser la version du logiciel et l'accès au code de réplication dès la
   première page (World Development l'exige à la soumission).
5. Le terme « quasi proportionnelle » est utilisé pour un Kakwani de −0,006 puis
   pour des charges de 17,3 à 20,2 % du revenu : réserver le terme à un usage
   défini une fois pour toutes.

## Recommandation

**Révisions majeures.** Aucune des demandes ne condamne les résultats — mais en
l'état, aucun intervalle de confiance du papier n'est valide au sens du plan de
sondage, ce qui est rédhibitoire pour publication.
