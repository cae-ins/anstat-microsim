********************************************************************************
* 04_analysis.do
*
* OBJECTIVE:
* Produce the main CEQ-style distributive results for VAT incidence in Côte d'Ivoire.
*
* ANALYTICAL FRAMEWORK:
* This script uses household consumption as the welfare-ranking variable and
* estimated VAT payments as the indirect tax burden. It implements a partial
* CEQ framework focused on the transition from market-income proxy
* (consumption) to consumable income proxy (consumption net of VAT).
*
* MAIN OUTPUTS:
* 1. Distribution of household consumption and VAT burden
* 2. Effective VAT rate by decile and quintile
* 3. Share of total VAT borne by each group
* 4. Rural/urban and regional profiles
* 5. Tables and graphs for the main report
*
* KEY VARIABLES EXPECTED IN INPUT DATASET:
* - hhid
* - hhweight
* - region
* - milieu
* - conso / conso_w
* - vat / vat_w
* - eff_vat / eff_vat_w
* - market_income
* - consumable_income
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

use "$OUTPUT/final_data/03/fiscal_data.dta", clear

********************************************************************************
* STEP 1 — Basic validation
********************************************************************************

assert !missing(hhid, hhweight, conso, conso_w, vat, vat_w)
assert conso   > 0
assert conso_w > 0
assert vat   >= 0
assert vat_w >= 0

********************************************************************************
* STEP 2 — Ranking households by welfare
********************************************************************************
* Preferred ranking variable: winsorized household consumption
* This improves slightly robustness while preserving the welfare interpretation.

xtile decile = conso_w [pw=hhweight], n(10)
xtile quintile = conso_w [pw=hhweight], n(5)

label define dec_lbl 1 "D1 poorest" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 richest"
label values decile dec_lbl

tabstat eff_vat_w, by(decile) stat(mean sd)
********************************************************************************
* STEP 3 — Main distributive indicators
********************************************************************************
* Share of total VAT paid by each household (will later be aggregated)
egen total_vat_all = total(vat_w)

* VAT-to-consumption loss in level terms
gen tax_burden = vat_w


********************************************************************************
* STEP 4 — Summary statistics by decile
********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w  ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(decile)

egen total_vat = total(vat_sum)
gen vat_share_decile = vat_sum / total_vat

export excel using "$TABLES/04/04_main_results_by_decile.xlsx", firstrow(variables) replace
save "$OUTPUT/final_data/04/results_by_decile.dta", replace
restore

********************************************************************************
* STEP 5 — Summary statistics by quintile
********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w  ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(quintile)

egen total_vat = total(vat_sum)
gen vat_share_quintile = vat_sum / total_vat

export excel using "$TABLES/04/04_main_results_by_quintile.xlsx", firstrow(variables) replace
save "$OUTPUT/final_data/04/results_by_quintile.dta", replace
restore

********************************************************************************
* STEP 6 — Rural / urban profile
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
* STEP 7 — Regional profile
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
* STEP 10 — Save enriched analysis base
********************************************************************************

save "$OUTPUT/final_data/04/fiscal_data_analysis_ready.dta", replace