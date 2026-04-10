********************************************************************************
* 05_progressivity.do
*
* OBJECTIVE:
* Measure VAT progressivity using concentration-based indicators
* consistent with CEQ-style distributive analysis.
**AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

use "$OUTPUT/final_data/04/fiscal_data_analysis_ready.dta", clear

* Ranking by welfare
sort conso_w
gen w = hhweight

********************************************************************************
* STEP 1 — Inequality and concentration
********************************************************************************
preserve
capture postclose ceq_handle
postfile ceq_handle str30 scenario str80 description ///
    double g_market g_after c_vat kakwani rs ///
    using "$OUTPUT/final_data/05/05_progressivity.dta", replace

* Gini before tax
ineqdeco conso_w [aw=hhweight]
scalar G_market = r(gini)

* Gini after tax
ineqdeco consumable_income [aw=hhweight]
scalar G_consumable = r(gini)

* Concentration index
conindex vat_w [pw=hhweight], rankvar(conso_w) truezero
scalar C_vat = r(CI)

* Kakwani
scalar Kakwani = C_vat - G_market

* Redistributive effect 
scalar RS = G_market - G_consumable

* Display
di "--------------------------------"
di "Gini before  = " %6.4f G_market
di "Gini after   = " %6.4f G_consumable
di "C VAT        = " %6.4f C_vat
di "Kakwani      = " %6.4f Kakwani
di "Redistribut. = " %6.4f RS
di "--------------------------------"

* Save result
post ceq_handle ("baseline") ///
    ("VAT system") ///
    (G_market) (G_consumable) (C_vat) (Kakwani) (RS)

postclose ceq_handle

* Export Excel
use "$OUTPUT/final_data/05/05_progressivity.dta", clear

export excel using "$TABLES/05/05_progressivity.xlsx", ///
    firstrow(variables) replace
restore

********************************************************************************
* STEP 1 — Lorenz-style grouped distribution of consumption
********************************************************************************
preserve

collapse (sum) conso_sum = conso_w [pw=hhweight], by(decile)

sort decile

egen total_conso = total(conso_sum)

gen conso_share = conso_sum / total_conso
gen cum_conso_share = sum(conso_share)

* Population share (robuste)
gen pop_share = _n / _N

* Add point (0,0)
expand 2 if _n==1
replace conso_share = 0 if _n==1
replace cum_conso_share = 0 if _n==1
replace pop_share = 0 if _n==1

sort pop_share

export excel using "$TABLES/05/05_lorenz_grouped_consumption.xlsx", ///
    firstrow(variables) replace

restore
********************************************************************************
* STEP 2 — Concentration-style grouped distribution of VAT
********************************************************************************
********************************************************************************
* STEP — Concentration curve of VAT (grouped)
********************************************************************************

preserve

collapse (sum) vat_sum = vat_w [pw=hhweight], by(decile)

sort decile

egen total_vat = total(vat_sum)

gen vat_share = vat_sum / total_vat
gen cum_vat_share = sum(vat_share)

* Population share (robust)
gen pop_share = _n / _N

* Add point (0,0)
expand 2 if _n==1
replace vat_share = 0 if _n==1
replace cum_vat_share = 0 if _n==1
replace pop_share = 0 if _n==1
replace decile = 0 if pop_share == 0

sort pop_share

export excel using "$TABLES/05/05_concentration_grouped_vat.xlsx", ///
    firstrow(variables) replace

restore