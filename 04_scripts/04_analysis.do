********************************************************************************
* 04_analysis.do
*
* OBJECTIF :
* Produire les principaux resultats de style CEQ pour l'incidence de la TVA en Cote d'Ivoire.
*
* CADRE ANALYTIQUE :
* Ce script utilise la consommation des menages comme variable de classement de bien-etre
* et les paiements TVA estimes comme charge fiscale indirecte. Il implemente un cadre
* CEQ partiel focalise sur la transition du revenu proxy de marche
* (consommation) au revenu utilisable proxy (consommation nette de TVA).
*
* SORTIES PRINCIPALES :
* 1. Distribution de la consommation des menages et de la charge TVA
* 2. Taux TVA effectif par decile et quintile
* 3. Part de la TVA totale supportee par chaque groupe
* 4. Profils rural/urbain et regional
* 5. Tableaux et graphiques pour le rapport principal
*
* VARIABLES CLEES ATTENDUES DANS LE JEU DE DONNEES D'ENTREE :
* - hhid
* - hhweight
* - region
* - milieu
* - conso / conso_w
* - vat / vat_w
* - eff_vat / eff_vat_w
* - market_income
* - consumable_income
 ********************************************************************************

use "$SILVER/03/fiscal_data.dta", clear

 ********************************************************************************
* ETAPE 1 — Validation basique
 ********************************************************************************

assert !missing(hhid, hhweight, conso, conso_w, vat, vat_w)
assert conso   > 0
assert conso_w > 0
assert vat   >= 0
assert vat_w >= 0

 ********************************************************************************
* ETAPE 2 — Classement des menages par bien-etre
 ********************************************************************************
* Variable de classement preferee : consommation des menages winsorisee
* Cela améliore légèrement la robustesse tout en preservant l'interpretation du bien-etre.

xtile decile = conso_w [pw=hhweight], n(10)
xtile quintile = conso_w [pw=hhweight], n(5)

label define dec_lbl 1 "D1 le plus pauvre" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 le plus riche"
label values decile dec_lbl

tabstat eff_vat_w, by(decile) stat(mean sd)
 ********************************************************************************
* ETAPE 3 — Indicateurs distributifs principaux
 ********************************************************************************
* Part de la TVA totale payee par chaque menage (sera ensuite aggrege)
egen total_vat_all = total(vat_w)

* Perte TVA-en termes de niveau
gen tax_burden = vat_w


 ********************************************************************************
* ETAPE 4 — Statistiques resumees par decile
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w  ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(decile)

egen total_vat = total(vat_sum)
gen vat_share_decile = vat_sum / total_vat

export excel using "$TABLES/04/04_main_results_by_decile.xlsx", firstrow(variables) replace
save "$SILVER/04/results_by_decile.dta", replace
restore

 ********************************************************************************
* ETAPE 5 — Statistiques resumees par quintile
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w  ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(quintile)

egen total_vat = total(vat_sum)
gen vat_share_quintile = vat_sum / total_vat

export excel using "$TABLES/04/04_main_results_by_quintile.xlsx", firstrow(variables) replace
save "$SILVER/04/results_by_quintile.dta", replace
restore

 ********************************************************************************
* ETAPE 6 — Profil Rural / Urbain
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w ///
	(sum)  vat_sum = vat_w ///
    [pw=hhweight], by(milieu)

egen total_vat = total(vat_sum)
gen vat_share_milieu = vat_sum / total_vat	
	
export excel using "$TABLES/04/04_results_by_milieu.xlsx", firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 7 — Profil Regional
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w ///
	(sum)  vat_sum = vat_w ///
    [pw=hhweight], by(region)

egen total_vat = total(vat_sum)
gen vat_share_region = vat_sum / total_vat	
	
gsort -vat_w
export excel using "$TABLES/04/04_results_by_region.xlsx", firstrow(variables) replace
restore


 ********************************************************************************
* ETAPE 10 — Sauvegarder la base d'analyse enrichie
 ********************************************************************************

save "$SILVER/04/fiscal_data_analysis_ready.dta", replace