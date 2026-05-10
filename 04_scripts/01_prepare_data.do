********************************************************************************
* 01_prepare_data.do
*
* OBJECTIF :
* Construire un jeu de donnees de depenses propre, coherent et economiquement
* significatif pour l'analyse de l'incidence de la TVA base sur les donnees
* EHCVM (Enquete Harmonisee sur les Conditions de Vie des Menages).
*
* STRUCTURE DES DONNEES :
* - Unite d'observation : menage × produit × mode d'acquisition
* - Environ 60 observations par menage
* - Environ 422 items de consommation distincts
*
* VARIABLES CLES :
* - depan   : depense annuelle par item
* - modep   : mode d'acquisition (achat, autoconsommation, don, imputation)
* - inclus  : indicateur d'inclusion dans l'aggregat officiel de consommation finale
* - hhid    : identificateur du menage
*
* APPROCHE METHODOLOGIQUE :
*
* 1. Validation et nettoyage des donnees
*    - Inspecter la distribution des depenses
*    - Identifier les valeurs invalides ou non plausibles
*
* 2. Distinguer la consommation officielle de la depense relevante pour la TVA :
*    - L'aggregat officiel de consommation finale inclut les composantes
*      monetaires et non monetaires (autoconsommation, transferts en nature).
*    - Cependant, la TVA s'applique uniquement aux transactions marchandes.
*    - Par consequent, l'analyse de l'incidence de la TVA doit distinguer :
*         (i) la consommation finale officielle des menages (via la variable "inclus"),
*        (ii) la depense basee sur le marche,
*
* 3. Restriction aux transactions marchandes
*    - Garder uniquement les acquisitions sur le marche (modep == 1) afin d'approximer
*      la base d'imposition effective observee dans les donnees de depense des menages.
*    - Les composantes non monetaires sont exclues de la base TVA, incluant :
*         • autoconsommation
*         • recus en nature
*         • valeurs imputedes (loyer imputed, valeur d'usage des biens durables)
*
* 4. Traitement des valeurs extremes
*    - Appliquer la winsorisation au 99e percentile (depan_w)
*    - Conserver les versions brutes et winsorisees pour l'analyse de robustesse
*
* 5. Construction des agrégats au niveau menage
*    - Agreger les depenses du niveau item au niveau menage
*    - Calculer :
*         • depense totale (conso)
*         • depense totale winsorisee (conso_w)
*         • nombre d'items (n_items)
*
* 6. Jeu de donnees final
*    - Une observation par menage
*    - Inclut les agrégats de depenses et les caracteristiques du menage
*    - Variables transformées en log generées a des fins de diagnostic et d'analyse
*
* INTERPRETATION DU CADRE CEQ :
*
* - On passe de :
*       depense observee des menages
*   a :
*       depense basee sur le marche relevante pour l'incidence des taxes indirectes
*
* - La base d'imposition finale n'est pas definie uniquement par les regles
*   comptables de l'enquete, mais par la combinaison de :
*       • depense observee,
*       • mode d'acquisition,
*       • classification fiscale au niveau du produit.
*
* - Le jeu de donnees final est coherent avec un cadre CEQ partiel focalise sur
*   la taxation indirecte (incidence TVA).
 ********************************************************************************
set scheme s1color

di as text ">>> ETAPE 1 : Chargement des donnees de consommation brutes"
use "$DATA/ehcvm_conso_civ2021.dta", clear

 ********************************************************************************
* ETAPE 1 — Inspecter la structure du jeu de donnees
 ********************************************************************************

di as text ">>> Inspection de la structure du jeu de donnees"

describe
count

* Les identifiants cles doivent etre presents
assert !missing(hhid)
assert !missing(codpr)

 ********************************************************************************
* ETAPE 2 — Nettoyer les valeurs de depenses
 ********************************************************************************

di as text ">>> Nettoyage des valeurs de depenses (depan)"

* Inspecter la distribution (important pour detecter les valeurs aberrantes)
sum depan, detail
tabstat depan, ///
    stat(n mean sd p1 p5 p10 p25 p50 p75 p90 p95 p99 min max skewness kurtosis) ///
    save
matrix M = r(StatTotal)
preserve
clear
svmat M, names(col)
gen stat = ""

replace stat = "N"         in 1
replace stat = "Mean"      in 2
replace stat = "SD"        in 3
replace stat = "P1"        in 4
replace stat = "P5"        in 5
replace stat = "P10"       in 6
replace stat = "P25"       in 7
replace stat = "Median"    in 8
replace stat = "P75"       in 9
replace stat = "P90"       in 10
replace stat = "P95"       in 11
replace stat = "P99"       in 12
replace stat = "Min"       in 13
replace stat = "Max"       in 14
replace stat = "Skewness"  in 15
replace stat = "Kurtosis"  in 16
sort stat depan
export excel using "$TABLES/01/summary_depan_raw.xlsx", ///
    firstrow(variables) replace

restore
list if depan >= 25000000

 ********************************************************************************
* ETAPE 3 — Agregat de consommation officiel
 ********************************************************************************

di as text ">>> Diagnostic de l'aggregat de consommation officiel (concept SCN)"

* Variable 'inclus' :
* =1 → inclut dans l'aggregat officiel de consommation (concept SCN)
* =0 → exclu (investissement, cas speciaux, problemes de classification)

tab inclus
sum depan if inclus == 1
sum depan if inclus == 0

* IMPORTANT :
* La variable 'inclus' suit la logique des comptes nationaux (mesure du bien-etre),
* mais ne correspond pas parfaitement a la base d'imposition TVA.
*
* Certains items exclus (inclus == 0) peuvent toujours correspondre a des transactions
* marchandes imposables (ex. biens durables, equipements, electronique).
*
* Par consequent :
*  on NE supprime PAS inclus == 0

 ********************************************************************************


 ********************************************************************************
* ETAPE 4 — Restriction a la consommation basee sur le marche (base relevante TVA)
 ********************************************************************************

di as text ">>> Restriction a la consommation basee sur le marche (base relevante TVA)"

* Variable 'modep' :
* 1 = Achat (transaction marchande)
* 2 = Autoconsommation
* 3 = Don
* 4 = Valeur d'usage (biens durables)
* 5 = Loyer impute

tab modep

* Hypothese CEQ :
* La TVA s'applique uniquement aux transactions marchandes

keep if modep == 1

sum depan, detail

* IMPORTANT :
* Cette restriction definit la base fondamentale relevante pour la TVA :
*
* Inclus :
* - achats monetaires de biens et services
*
* Exclus :
* - autoconsommation (pas de transaction marchande)
* - dons et transferts en nature
* - loyer impute
* - valeur d'usage des biens durables (transactions non observees)
*
* NOTE :
* Certains items restants peuvent toujours etre :
* - non imposables (exoneres)
* - hors champ (non soumis a la TVA)
*
* Ces points seront trait later via le mapping TVA (classification au niveau du produit)
 ********************************************************************************


 ********************************************************************************
* ETAPE 5 — Diagnostics apres filtrage
 ********************************************************************************

di as text ">>> Diagnostics apres filtrage"

count
sum depan, detail

/*La distribution des depenses est tres inegale et dominee par quelques valeurs elevees.
Un menage "typique" depense environ 15 000 FCFA (mediane) par item (annualise).
Asymetrie = 57,19 & Kurtosis = 12 818,75 distribution extremement asymetrique avec une forte concentration de faibles observations et quelques valeurs extremement elevees.

Conclusion : La majorite des menages consomment peu, tandis qu'une minorite depense beaucoup,
refletant a la fois les inegalites de niveau de vie et la presence de depenses ponctuelles significatives.
*/

* Verifier la distribution COICOP
tab coicop

* Verifier la structure regionale
tab region

 ********************************************************************************
* ETAPE 6 — Gerer les valeurs extremes (robustesse)
 ********************************************************************************

di as text ">>> Gestion des valeurs extremes"

* Motivation :
* La distribution des depenses est tres asymetrique (forte queue),
* ce qui peut biaiser les resultats d'incidence

gen log_depan = log(depan)
histogram depan
histogram log_depan
graph save "$FIGS/log_depan_af_cleaning.gph" , replace
graph export "$FIGS/log_depan_af_cleaning.png", replace

/*La distribution des depenses des menages suit un pattern log-normal,
coherent avec les resultats standards de la litterature sur la consommation.
*/

sum depan, detail
local p99 = r(p99)

gen depan_w = depan

* Winsoriser au 99e percentile
replace depan_w = `p99' if depan > `p99'

* NOTE :
* - 'depan'  = valeurs brutes
* - 'depan_w' = version robuste

sum depan_w, detail
histogram depan_w


 ********************************************************************************
* ETAPE 7 — Sauvegarder le jeu de donnees nettoy detaille
 ********************************************************************************

di as text ">>> Sauvegarde du jeu de donnees de consommation nettoy"

save "$SILVER/01/conso_clean.dta", replace


 ********************************************************************************
* FIN
 ********************************************************************************