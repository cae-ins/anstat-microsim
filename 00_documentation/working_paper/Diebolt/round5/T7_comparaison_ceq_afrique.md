# T7 — Comparaison quantitative avec les applications CEQ africaines (M6)

Statut : **recherche documentaire terminée ; `references.bib` mis à jour ; `DT_CEQ_CIV2021.tex` NON modifié.**
Le plan subordonne l'édition du `.tex` par T7 à l'achèvement de T3 et T6, qui n'ont pas encore
été exécutés (seul T0 est fait). Le tableau LaTeX et les paragraphes de §5.11 sont donc livrés
ici, prêts à être collés tels quels par la tâche qui possédera §5.11.

Règle appliquée : **aucun chiffre estimé, interpolé ou reconstruit.** Chaque cellule renvoie au
document, au tableau et à la page où elle a été lue. Une cellule que la source ne publie pas est
laissée vide avec la mention « non publié ».

---

## 1. Pays retenus et documents dépouillés

Six applications, toutes lues intégralement dans leur version PDF d'origine :

| Pays | Document | Clé bib | Vérification |
|---|---|---|---|
| Ghana | Younger, Osei-Assibey & Oppong (2017), *Review of Development Economics* 21(4), e47–e66 | `youngerghana2017` | DOI 10.1111/rode.12299 (Crossref) ; texte intégral libre PMC7053389 |
| Tanzanie | Younger, Myamba & Mdadila, CEQ Working Paper 36, janvier 2016 | `youngertanzania2016` | PDF Tulane RePEc ; version publiée *African Development Review* 28(3), 264–276, DOI 10.1111/1467-8268.12204 (Crossref) |
| Éthiopie | Hill, Inchauste, Lustig, Tsehaye & Woldehanna, CEQ Working Paper 41, avril 2017 | `hill2017` (**déjà présent**) | PDF Tulane RePEc ; page de couverture conforme à la notice existante |
| Ouganda | Jellema, Lustig, Haas & Wolf, CEQ Working Paper 53, nov. 2016, rév. juin 2017 | `jellema2017uganda` | PDF Tulane RePEc |
| Afrique du Sud | Inchauste, Lustig, Maboshe, Purfield & Woolard, CEQ Working Paper 29, fév. 2015, rév. mai 2017 | `inchauste2017southafrica` | PDF Tulane RePEc ; version publiée dans Inchauste & Lustig (dir.), Banque mondiale, DOI 10.1596/978-1-4648-1091-6 |
| Togo | FMI, *Togo: Selected Issues*, IMF Country Report 17/128, mai 2017, chap. « Fiscal Incidence, Inequality and Poverty in Togo », p. 3–14 | `imftogo2017` | PDF imf.org ; chapitre préparé par Jon Jellema (CEQ), L. Erickson et T. Willems (FMI) |

Sources transversales pour l'appauvrissement fiscal et le RS :

- Higgins & Lustig (2016), *JDE* 122, tableau 2, p. 67 → clé existante `higgins2016`.
- Lustig, *CGD Working Paper 448*, janv. 2017, mise à jour juillet 2018, tableau 1, p. 25 → clé nouvelle `lustig2017cgd`.

**Le Togo dispose bien d'une application CEQ publiée** (rapport pays du FMI, réalisée avec le CEQ
Institute) : il n'a donc pas été nécessaire de se rabattre sur la Zambie, la Namibie ou les Comores.

---

## 2. Tableau comparatif, cellule par cellule

Toutes les valeurs de Gini et de RS sont exprimées en **points de Gini** (×100). Les $\Delta P_0$
sont en **points de pourcentage**.

### 2.1 Indicateur 1 — effet redistributif au revenu consommable

| Pays | RS marché+pensions → consommable (pts) | Source exacte | $\Delta$Gini disponible → consommable (pts) | Source exacte |
|---|---|---|---|---|
| Côte d'Ivoire | 1,62 (= 0,3409 − 0,3247) | `generated/ceq_summary_values.tex`, macros `\GiniPrimaire` / `\GiniConsommable` (étape 25) | −0,89 (= 0,3336 − 0,3247) | mêmes macros, `\GiniDisponible` / `\GiniConsommable` |
| Ghana | 1,6 | Lustig, CGD WP 448, tab. 1, p. 25, col. « Reynolds–Smolensky », ligne Ghana (2013) | −0,1 (0,424 → 0,423) | Younger et al. (2017), *RDE*, tab. 3 (= CEQ WP 35, tab. 6, p. 15) |
| Tanzanie | 4,1 | Lustig, CGD WP 448, tab. 1, p. 25, ligne Tanzania (2011) | −1,2 (0,357 → 0,345) | CEQ WP 36, tab. 6, p. 15 |
| Éthiopie | 2,3 | Lustig, CGD WP 448, tab. 1, p. 25, ligne Ethiopia (2011) | −0,3 (0,305 → 0,302) | CEQ WP 41, tab. 3, p. 16 |
| Ouganda | *non publié* | absent du tab. 4 de CEQ WP 53 (colonne RS non reproduite) et du tab. 1 de Lustig | −0,2 (0,400 → 0,398) | CEQ WP 53, tab. 3, p. 26 |
| Afrique du Sud | 8,3 | Higgins & Lustig (2016), *JDE*, tab. 2, p. 67, ligne South Africa (2010–2011) ; identique dans Lustig, CGD WP 448, tab. 1, p. 25 | **+0,1** (0,694 → 0,695) | CEQ WP 29, tab. 4, p. 17 |
| Togo | *non publié* | le revenu de marché n'est pas estimé (note 6, p. 7 : « these estimates are not yet available in Togo ») | *non publié* | figure 2, p. 7, sans étiquettes de données ; le texte ne chiffre que le Gini du revenu disponible (0,38) |

### 2.2 Indicateur 2 — $\Delta P_0$ du revenu disponible au revenu consommable

| Pays | Seuil | $P_0$ disponible | $P_0$ consommable | $\Delta P_0$ | Source exacte |
|---|---|---|---|---|---|
| Côte d'Ivoire | national, 369 516 FCFA/pers./an | 37,47 % | 42,04 % | **+4,57** | macros `\PauvreteDisponible` / `\PauvreteConsommable` (étape 25) |
| Ghana | national, GH₵1 314/éq.-ad./an | 24,2 % | 26,2 % | **+2,0** | Younger et al. (2017), tab. 3, lignes *Disposable*/*Consumable* |
| Ghana | 1,25 $ PPA/j | 5,9 % | 6,8 % | +0,9 | idem |
| Tanzanie | national, 36 482 TZS/éq.-ad./mois | 28,2 % | 34,8 % | **+6,6** | CEQ WP 36, tab. 6, p. 15 |
| Tanzanie | 1,25 $ PPA/j | 43,6 % | 51,5 % | +7,9 | idem |
| Éthiopie | national | 30,2 % | 32,4 % | **+2,2** | CEQ WP 41, tab. 3, p. 16 |
| Éthiopie | 1,25 $ PPA/j | 30,9 % | 33,2 % | +2,3 | idem |
| Ouganda | national | 19,7 % | 19,9 % | **+0,2** | CEQ WP 53, tab. 3, p. 26 |
| Afrique du Sud | national *lower bound* | 34,2 % | 39,6 % | **+5,4** | CEQ WP 29, tab. 4, p. 17 |
| Afrique du Sud | 2,50 $ PPA/j | 29,6 % | 35,2 % | +5,6 | idem |
| Togo | national | 55 % | 59 % | **+4** | IMF CR 17/128, §D, ¶6, p. 7 (« increases the share of the population living under the poverty line from 55 percent to 59 percent ») et figure 3, p. 7 |

Les valeurs en gras sont celles retenues dans le tableau du papier (seuil national, comparable au
seuil ivoirien). Les lignes en seuil PPA sont conservées ici parce que ce sont elles qui gouvernent
la colonne « appauvrissement ».

### 2.3 Indicateur 3 — appauvrissement fiscal au sens Higgins–Lustig

Définition : individu dont le revenu consommable est à la fois inférieur au seuil **et** inférieur à
son revenu pré-fiscal (pauvre rendu plus pauvre, ou non-pauvre rendu pauvre).

| Pays (enquête) | Seuil | Appauvris, % pop. | Appauvris, % des pauvres post-fiscaux | Source exacte |
|---|---|---|---|---|
| Côte d'Ivoire (2021) | national | **37,50** | 89,2 (= 37,50/42,04, calcul des auteurs) | macro `\PartAppauvrie` ; sortie `24_01_fiscal_impoverishment.xlsx`, ligne « PDI, système monétaire complet », colonne `part_population_appauvrie` = 0,375009 |
| Ghana (2013) | 1,25 $ PPA/j | 5,1 | 76,6 | Lustig, CGD WP 448, tab. 1, p. 25 ; valeurs identiques dans Jellema et al., CEQ WP 53, tab. 4, p. 31 |
| Tanzanie (2011) | 1,25 $ PPA/j | 50,9 | 98,6 | idem |
| Éthiopie (2011) | 1,25 $ PPA/j | 28,5 | 83,2 | idem |
| Ouganda (2012/13) | 1,25 $ PPA/j | 12,2 | 67,7 | Jellema et al., CEQ WP 53, tab. 4, p. 31 (calculs propres des auteurs, seule source) ; corroboré par le texte p. 30 et la note 24 |
| Afrique du Sud (2010–11) | 2,50 $ PPA/j | 5,9 | 13,3 | Higgins & Lustig (2016), *JDE*, tab. 2, p. 67 |
| Togo (2015) | — | *non publié* | *non publié* | le rapport ne calcule aucun indice d'appauvrissement |

**Point de vigilance sur la provenance.** Le tableau 2 publié de Higgins & Lustig (2016), p. 67,
**n'inclut ni le Ghana, ni l'Éthiopie, ni la Tanzanie, ni l'Ouganda** ; sa note précise que
« Ethiopia and Ghana are not included in the table because poverty with a $1.25 per day poverty line
increased from pre-fisc to post-fisc income ». Ces quatre lignes proviennent de deux reprises
ultérieures — Lustig (CGD WP 448, tab. 1, p. 25) et Jellema et al. (CEQ WP 53, tab. 4, p. 31) —
qui les attribuent à Higgins & Lustig (2016) et donnent des valeurs strictement identiques entre
elles. La citation correcte est donc `\citep{lustig2017cgd}` (ou `\citep{jellema2017uganda}` pour
l'Ouganda), et non `\citep{higgins2016}` seul. Ne pas écrire que ces chiffres figurent dans le *JDE*.

**Nota sur la ligne ivoirienne.** Le 37,50 % est bien l'indice d'appauvrissement de Higgins–Lustig
(pauvres appauvris + nouveaux pauvres) ; le 4,35 % cité dans le rapport de référé et dans le plan
est le **sous-ensemble** des seuls nouveaux pauvres (`part_nouveaux_pauvres` = 0,043504). C'est
37,50 % qui est comparable aux colonnes des autres pays, et il faut le dire explicitement, sans quoi
le papier sous-déclarerait son propre appauvrissement d'un facteur huit.

---

## 3. Différences de champ à signaler dans la note du tableau

1. **Seuil.** La colonne appauvrissement des cinq comparateurs est calculée au seuil international
   1,25 $ PPA 2005 (2,50 $ pour l'Afrique du Sud, pays à revenu intermédiaire supérieur) ; la ligne
   ivoirienne est au seuil national de l'EHCVM 2021 (369 516 FCFA/personne/an). L'écart de seuil
   déplace mécaniquement l'indice ; la comparaison est ordinale, pas exacte.
2. **Année et enquête.** 2010–2013 pour les comparateurs, 2021 pour la Côte d'Ivoire.
3. **Concept de classement.** Toutes les applications classent par revenu par tête ; la Côte
   d'Ivoire aussi.
4. **Pensions.** Le tableau 1 de Lustig traite les pensions contributives comme du revenu différé
   (PDI), convention retenue également par le papier ivoirien.
5. **TVA enchâssée.** Contrairement à ce que suggère la rédaction actuelle de l'apport 1, la
   propagation entrées–sorties **n'est pas nouvelle** : le Ghana utilise la MCS 2005 et la technique
   de Roland-Holst & Sancho (1995) pour calculer des taux effectifs directs + indirects (CEQ WP 35,
   p. 10) ; l'Éthiopie calcule explicitement les « second-round effects » via le tableau
   entrées–sorties de la MCS 2006 de l'EDRI (CEQ WP 41, p. 13) ; l'Afrique du Sud utilise la matrice
   entrées–sorties 2009 du National Treasury et un modèle de report de prix (CEQ WP 29, p. 11). La
   Tanzanie a renoncé au tableau entrées–sorties, jugé trop ancien, et applique les taux statutaires
   recalés sur les totaux administratifs (CEQ WP 36, p. 9). Le Togo et l'Ouganda ne documentent pas
   de propagation.
6. **Hétérogénéité de la probabilité de taxation.** En revanche, **aucune** de ces applications ne
   fait varier la part taxée par décile : le Ghana, l'Éthiopie et l'Afrique du Sud appliquent des
   taux « effectifs » uniformes tirés de la comptabilité nationale ou de la MCS (Afrique du Sud,
   CEQ WP 29, p. 11 : « Evasion of consumption taxes was taken into account implicitly by using
   "effective" rates … rather than statutory rates ») ; la Tanzanie recale proportionnellement
   (CEQ WP 36, p. 9 : « assuming that all consumers' effective tax paid declines proportionally to
   their consumption »). **C'est là, et là seulement, que se situe la nouveauté du papier
   ivoirien** — ce qui confirme la reformulation de l'apport 1 demandée par M5 et doit être
   transmis à T3 et à T9.

---

## 4. Tableau LaTeX prêt à coller en §5.11

```latex
\begin{table}[t]
\centering
\begin{threeparttable}
\caption{La Côte d'Ivoire au regard des applications CEQ africaines}
\label{tab:comparaison-ceq-afrique}
\small
\begin{tabular}{llrrr}
\toprule
Pays (enquête) & Seuil & RS & $\Delta P_0$ & Appauvris \\
               &       & (points de Gini) & (points) & (\% pop.) \\
\midrule
Côte d'Ivoire (EHCVM 2021)      & national   & 1,62 & $+4,57$ & 37,5 \\
Ghana (GLSS-6, 2012--13)        & national   & 1,6  & $+2,0$  & 5,1  \\
Tanzanie (HBS, 2011--12)        & national   & 4,1  & $+6,6$  & 50,9 \\
Éthiopie (HCES--WMS, 2011)      & national   & 2,3  & $+2,2$  & 28,5 \\
Ouganda (UNHS, 2012--13)        & national   & ---  & $+0,2$  & 12,2 \\
Afrique du Sud (IES, 2010--11)  & national   & 8,3  & $+5,4$  & 5,9  \\
Togo (QUIBB, 2015)              & national   & ---  & $+4$    & ---  \\
\bottomrule
\end{tabular}
\begin{tablenotes}\footnotesize
\item \emph{Notes} : RS désigne la variation du coefficient de Gini entre le revenu de marché
augmenté des pensions et le revenu consommable, en points de Gini ; une valeur positive indique
une baisse de l'inégalité. $\Delta P_0$ est la variation du taux de pauvreté entre revenu
disponible et revenu consommable, au seuil national de chaque pays, en points de pourcentage.
La dernière colonne est l'indice d'appauvrissement fiscal de \citet{higgins2016} : part de la
population dont le revenu consommable est à la fois inférieur au seuil et inférieur au revenu
pré-fiscal. Elle est calculée au seuil de 1,25 dollar PPA 2005 par jour pour le Ghana, la
Tanzanie, l'Éthiopie et l'Ouganda, au seuil de 2,50 dollars pour l'Afrique du Sud et au seuil
national pour la Côte d'Ivoire, ce qui interdit une lecture strictement cardinale. Un tiret
signale une valeur non publiée par la source : le rapport togolais n'estime pas le revenu de
marché et ne calcule aucun indice d'appauvrissement, et l'application ougandaise ne publie pas
d'indice de Reynolds--Smolensky. Sources : Côte d'Ivoire, calculs des auteurs ; Ghana,
\citet[tab.~3]{youngerghana2017} ; Tanzanie, \citet[tab.~6, p.~15]{youngertanzania2016} ;
Éthiopie, \citet[tab.~3, p.~16]{hill2017} ; Ouganda, \citet[tab.~3, p.~26 et tab.~4,
p.~31]{jellema2017uganda} ; Afrique du Sud, \citet[tab.~4, p.~17]{inchauste2017southafrica} et
\citet[tab.~2, p.~67]{higgins2016} ; Togo, \citet[p.~7]{imftogo2017} ; colonnes RS et
appauvrissement du Ghana, de la Tanzanie et de l'Éthiopie, \citet[tab.~1, p.~25]{lustig2017cgd}.
\end{tablenotes}
\end{threeparttable}
\end{table}
```

---

## 5. Paragraphes rédigés pour §5.11 (prose continue, aucune liste)

> Le seul repère externe mobilisé jusqu'ici concerne le même pays à une date antérieure. Les
> applications CEQ conduites ailleurs en Afrique offrent un second point de comparaison, et le
> tableau~\ref{tab:comparaison-ceq-afrique} y situe la Côte d'Ivoire sur les trois grandeurs que
> ces travaux publient de façon homogène : l'effet redistributif mesuré au revenu consommable,
> l'effet de la fiscalité indirecte sur le taux de pauvreté, et l'indice d'appauvrissement fiscal
> de \citet{higgins2016}. La lecture doit rester ordinale : les seuils, les années d'enquête et
> le traitement des taxes en cascade diffèrent d'une application à l'autre, et la comparaison
> ne dit rien de plus que le rang du cas ivoirien dans une distribution de cas voisins.
>
> Sur le premier indicateur, la redistribution ivoirienne est faible mais non atypique. La baisse
> de 1,6 point de Gini entre revenu primaire et revenu consommable place la Côte d'Ivoire au même
> niveau que le Ghana, au-dessous de la Tanzanie et de l'Éthiopie, et très loin de l'Afrique du
> Sud, dont les 8,3 points reflètent à la fois une inégalité initiale exceptionnelle et un système
> de transferts sans équivalent sur le continent. Sur le deuxième indicateur, en revanche, la
> Côte d'Ivoire se situe dans le haut de la distribution : le passage du revenu disponible au
> revenu consommable accroît la pauvreté de 4,57 points, davantage que le Togo, l'Éthiopie, le
> Ghana et l'Ouganda, moins que la Tanzanie. Le cas ougandais, où le taux de pauvreté ne bouge que
> de deux dixièmes de point, montre que ce résultat n'est pas mécanique : il dépend de l'ampleur
> de la fiscalité indirecte rapportée à la consommation des ménages pauvres.
>
> C'est le troisième indicateur qui situe le mieux le résultat central de ce travail. L'indice
> d'appauvrissement fiscal ne retient pas les seuls franchissements de seuil, mais l'ensemble des
> personnes dont le revenu consommable est à la fois inférieur au seuil et inférieur au revenu
> pré-fiscal : en Côte d'Ivoire, 37,5~\% de la population, soit près de neuf pauvres sur dix après
> impôts. Ce niveau est du même ordre que celui de l'Éthiopie, nettement supérieur à celui de
> l'Ouganda et du Ghana, et inférieur au seul cas tanzanien, où l'indice atteint la moitié de la
> population. Il contraste surtout avec les 4,35~\% de nouveaux pauvres, c'est-à-dire avec la
> mesure anonyme que rapportent d'ordinaire les évaluations d'incidence : l'écart entre les deux
> chiffres est précisément l'objet de la mesure de \citet{higgins2016}, et il rappelle que
> l'essentiel du dommage fiscal subi par les pauvres ivoiriens ne se voit pas dans la variation
> du taux de pauvreté. Enfin, l'appareil entrées--sorties mobilisé ici n'est pas propre à ce
> travail — le Ghana, l'Éthiopie et l'Afrique du Sud l'utilisent également pour tenir compte des
> taxes sur les consommations intermédiaires — mais aucune de ces applications ne fait dépendre du
> niveau de vie la probabilité qu'un achat soit effectivement taxé, hypothèse dont la section~5.1
> a montré qu'elle commandait l'essentiel des conclusions distributives.

---

## 6. Notices ajoutées à `references.bib`

Ajoutées en fin de fichier, sous un commentaire de bloc identifiant la tâche :
`youngerghana2017`, `youngertanzania2016`, `jellema2017uganda`, `inchauste2017southafrica`,
`lustig2017cgd`, `imftogo2017`. Aucune clé existante n'a été modifiée ou supprimée.

**Avertissement pour T3.** La notice `younger2016` du fichier désigne en réalité le document de
travail CEQ 35 (Ghana, décembre 2015) et non un article de 2016. La version publiée
— Younger, Osei-Assibey & Oppong (2017), *Review of Development Economics* 21(4), e47–e66 — est
désormais présente sous la clé **`youngerghana2017`** : T3 doit résoudre `younger2016` en
s'appuyant sur cette clé et **ne pas créer une seconde notice** pour le même article. Le tableau 3
de l'article publié reproduit à l'identique le tableau 6 du document de travail (vérifié ligne à
ligne pour les revenus disponible et consommable), la substitution est donc sans effet sur les
chiffres. La notice `younger2017` (document de travail CEQ 55, Ghana et Tanzanie, réformes) est un
document distinct et n'est pas un doublon.

## 7. Pays sans donnée vérifiable

Aucun pays du périmètre demandé n'a dû être abandonné : les six pays cités par le rapporteur
(Ghana, Tanzanie, Éthiopie, Ouganda, Afrique du Sud, Togo) disposent tous d'une application CEQ
publiée. Les seules cellules vides sont le RS et l'appauvrissement pour le Togo, et le RS pour
l'Ouganda, faute de publication par la source.
