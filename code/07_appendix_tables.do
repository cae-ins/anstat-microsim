********************************************************************************
* 07_appendix_tables.do
*
* OBJECTIVE:
* Produce supplementary tables for appendix and robustness documentation.
*
* CONTENT:
* - Full distribution statistics
* - Detailed decile and quintile profiles
* - VAT decomposition by COICOP
* - Regional and rural/urban breakdowns
* - Diagnostics for data quality
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

use "$OUTPUT/final_data/04/fiscal_data_analysis_ready.dta", clear

********************************************************************************
* STEP 1 — Full distribution diagnostics
********************************************************************************

sum conso conso_w vat vat_w eff_vat eff_vat_w, detail

* Export summary manually if needed

********************************************************************************
* STEP 2 — Detailed decile profile (extended)
********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (p50) median_conso = conso_w ///
    (p90) p90_conso = conso_w ///
    (p10) p10_conso = conso_w ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(decile)

egen total_vat = total(vat_sum)
gen vat_share = vat_sum / total_vat

export excel using "$TABLES/07/07_decile_detailed.xlsx", firstrow(variables) replace
restore

********************************************************************************
* STEP 3 — Detailed quintile profile
********************************************************************************

*xtile quintile = conso_w [pw=hhweight], n(5)

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(quintile)

egen total_vat = total(vat_sum)
gen vat_share = vat_sum / total_vat

export excel using "$TABLES/07/07_quintile_detailed.xlsx", firstrow(variables) replace
restore

********************************************************************************
* STEP 4 — VAT decomposition by COICOP
********************************************************************************

use "$OUTPUT/final_data/01/conso_clean.dta", clear

* Ensure VAT computed at item level
gen vat_item_w = depan_w * r_vat_official

preserve
collapse ///
    (sum) vat_w = vat_item_w ///
    (sum) conso_w = depan_w ///
    [pw=hhweight], by(coicop)

gen vat_rate_coicop = vat_w / conso_w

export excel using "$TABLES/07/07_vat_by_coicop.xlsx", firstrow(variables) replace
restore

********************************************************************************
* STEP 5 — Regional breakdown (extended)
********************************************************************************

use "$OUTPUT/final_data/04/fiscal_data_analysis_ready.dta", clear

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(region)

gsort -eff_vat

export excel using "$TABLES/07/07_region_detailed.xlsx", firstrow(variables) replace
restore

********************************************************************************
* STEP 6 — Rural vs Urban (extended)
********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (p50) median_conso = conso_w ///
    [pw=hhweight], by(milieu)

export excel using "$TABLES/07/07_milieu_detailed.xlsx", replace
restore

********************************************************************************
* STEP 7 — Diagnostics: data quality
********************************************************************************

* Number of items per household
sum n_items, detail

* Extreme VAT rates
sum eff_vat, detail

* Identify potential outliers
gen flag_high_vat = eff_vat > 0.2
tab flag_high_vat

********************************************************************************
* END
********************************************************************************

di as result ">>> Appendix tables successfully generated"