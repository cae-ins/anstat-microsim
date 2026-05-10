********************************************************************************
* 05_progressivity.do
*
* OBJECTIF :
* Mesurer la progressivite de la TVA en utilisant des indicateurs bases sur la concentration
* coherents avec l'analyse distributive de style CEQ.
 ********************************************************************************

use "$SILVER/04/fiscal_data_analysis_ready.dta", clear

* Classement par bien-etre
sort conso_w
gen w = hhweight

 ********************************************************************************
* ETAPE 1 — Inegalite et concentration
 ********************************************************************************
preserve
capture postclose ceq_handle
postfile ceq_handle str30 scenario str80 description ///
    double g_market g_after c_vat kakwani rs ///
    using "$SILVER/05/05_progressivity.dta", replace

* Gini avant impôt
ineqdeco conso_w [aw=hhweight]
scalar G_market = r(gini)

* Gini après impôt
ineqdeco consumable_income [aw=hhweight]
scalar G_consumable = r(gini)

* Indice de concentration
conindex vat_w [pw=hhweight], rankvar(conso_w) truezero
scalar C_vat = r(CI)

* Kakwani
scalar Kakwani = C_vat - G_market

* Effet redistributif 
scalar RS = G_market - G_consumable

* Affichage
di "--------------------------------"
di "Gini avant   = " %6.4f G_market
di "Gini apres  = " %6.4f G_consumable
di "C TVA      = " %6.4f C_vat
di "Kakwani   = " %6.4f Kakwani
di "Redistrib.= " %6.4f RS
di "--------------------------------"

* Sauvegarder le resultat
post ceq_handle ("baseline") ///
    ("Systeme TVA") ///
    (G_market) (G_consumable) (C_vat) (Kakwani) (RS)

postclose ceq_handle

* Exporter Excel
use "$SILVER/05/05_progressivity.dta", clear

export excel using "$TABLES/05/05_progressivity.xlsx", ///
    firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 1 — Distribution groupee de type Lorenz de la consommation
 ********************************************************************************
preserve

collapse (sum) conso_sum = conso_w [pw=hhweight], by(decile)

sort decile

egen total_conso = total(conso_sum)

gen conso_share = conso_sum / total_conso
gen cum_conso_share = sum(conso_share)

* Part de la population (robuste)
gen pop_share = _n / _N

* Ajouter le point (0,0)
expand 2 if _n==1
replace conso_share = 0 if _n==1
replace cum_conso_share = 0 if _n==1
replace pop_share = 0 if _n==1

sort pop_share

export excel using "$TABLES/05/05_lorenz_grouped_consumption.xlsx", ///
    firstrow(variables) replace

restore
 ********************************************************************************
* ETAPE 2 — Distribution groupee de type concentration de la TVA
 ********************************************************************************
 ********************************************************************************
* ETAPE — Courbe de concentration de la TVA (groupee)
 ********************************************************************************

preserve

collapse (sum) vat_sum = vat_w [pw=hhweight], by(decile)

sort decile

egen total_vat = total(vat_sum)

gen vat_share = vat_sum / total_vat
gen cum_vat_share = sum(vat_share)

* Part de la population (robuste)
gen pop_share = _n / _N

* Ajouter le point (0,0)
expand 2 if _n==1
replace vat_share = 0 if _n==1
replace cum_vat_share = 0 if _n==1
replace pop_share = 0 if _n==1
replace decile = 0 if pop_share == 0

sort pop_share

export excel using "$TABLES/05/05_concentration_grouped_vat.xlsx", ///
    firstrow(variables) replace

restore