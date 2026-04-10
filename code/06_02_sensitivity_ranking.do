********************************************************************************
* 06_02_sensitivity_ranking.do
*
* OBJECTIVE:
* Sensitivity analysis of VAT incidence to alternative distributive rankings.
*
* EMPIRICAL RATIONALE:
* The baseline ranking uses total household consumption. This is standard when
* consumption is treated as a proxy for pre-fiscal living standards. However,
* household size and composition can affect welfare comparisons. We therefore
* compare three ranking concepts:
*   1) total household consumption
*   2) consumption per capita
*   3) consumption per adult equivalent
*
* The per capita and adult-equivalent rankings are not alternative tax burdens;
* they are alternative ways of ordering households in the distribution.
*
* REQUIRED INPUTS:
* To compute per capita and adult-equivalent welfare, the dataset must contain:
*   - hhsize  : household size
*   - eqadu1  : number of adults 
*   - eqadu2 : number of adults 

*AUTHOR: Armand Kouakou Djaha, MSc

********************************************************************************

use "$OUTPUT/final_data/06/fiscal_sensitivity_taxation.dta", clear
by hhid: gen hh_tag = (_n == 1)
keep if hh_tag == 1
drop hh_tag
merge 1:1 hhid using "$DATA/ehcvm_welfare_civ2021", keepusing(eqadu1 eqadu2 hgender hage hmstat heduc halfa2 halfa hbranch pcexp zref hhsize)
drop _merge
********************************************************************************
* STEP 0 — Required variables
********************************************************************************

********************************************************************************
* STEP 1 — Validation
********************************************************************************

assert !missing(hhid, hhweight, conso_w, vat_strict)


********************************************************************************
* STEP 2 — Welfare concepts
********************************************************************************

* Per capita consumption
gen conso_pc = conso_w / hhsize
label var conso_pc "Consumption per capita"

* Adult-equivalent consumption (FAO scale)
gen conso_ae1 = conso_w / eqadu1
label var conso_ae1 "Consumption per adult equivalent-1"

gen conso_ae2 = conso_w / eqadu2
label var conso_ae2 "Consumption per adult equivalent-2"

********************************************************************************
* STEP 3 — Create deciles
********************************************************************************

xtile decile_total = conso_w  [pw=hhweight], n(10)
xtile decile_pc    = conso_pc [pw=hhweight], n(10)
xtile decile_ae1    = conso_ae1 [pw=hhweight], n(10)
xtile decile_ae2    = conso_ae2 [pw=hhweight], n(10)

label define dec_lbl 1 "D1 poorest" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 richest", replace

foreach v in decile_total decile_pc decile_ae1 decile_ae2 {
    label values `v' dec_lbl
}

********************************************************************************
* STEP 4 — Effective VAT rates by ranking
********************************************************************************

foreach rank in total pc ae1 ae2 {
    preserve
    collapse (mean) eff_vat_strict eff_vat_s2  eff_vat_s3  ///
        [pw=hhweight], by(decile_`rank')
    rename decile_`rank' decile
    export excel using "$TABLES/06/06_02_eff_vat_`rank'.xlsx", ///
        firstrow(variables) replace
    restore
}

********************************************************************************
* STEP 5 — CEQ summary (FINAL CLEAN VERSION)
********************************************************************************

capture which ineqdeco
if _rc ssc install ineqdeco

capture which conindex
if _rc ssc install conindex

tempname results
postfile ceq_handle str10 ranking str10 scenario ///
    double g_market g_after c_vat kakwani rs ///
    using "$OUTPUT/final_data/06/06_02_ceq_rankings.dta", replace

foreach rank in total pc ae1 ae2 {

    * Drop individuel — chaque variable supprimée indépendamment
    foreach v in welfare vat_adj_strict vat_adj_s2 vat_adj_s3 consumable {
        capture drop `v'
    }

    if "`rank'" == "total" {
        gen welfare        = conso_w
        gen vat_adj_strict = vat_strict
        gen vat_adj_s2     = vat_s2
        gen vat_adj_s3     = vat_s3
    }
    if "`rank'" == "pc" {
        gen welfare        = conso_pc
        gen vat_adj_strict = vat_strict / hhsize
        gen vat_adj_s2     = vat_s2     / hhsize
        gen vat_adj_s3     = vat_s3     / hhsize
    }
    if "`rank'" == "ae1" {
        gen welfare        = conso_ae1
        gen vat_adj_strict = vat_strict / eqadu1
        gen vat_adj_s2     = vat_s2     / eqadu1
        gen vat_adj_s3     = vat_s3     / eqadu1
    }
    if "`rank'" == "ae2" {
        gen welfare        = conso_ae2
        gen vat_adj_strict = vat_strict / eqadu2
        gen vat_adj_s2     = vat_s2     / eqadu2
        gen vat_adj_s3     = vat_s3     / eqadu2
    }

    quietly ineqdeco welfare [aw=hhweight]
    scalar G_market = r(gini)

    foreach s in strict s2 s3 {
        capture drop consumable
        gen consumable = welfare - vat_adj_`s'
        quietly ineqdeco consumable [aw=hhweight]
        scalar G_after = r(gini)
        quietly conindex vat_adj_`s' [aw=hhweight], ///
            rankvar(welfare) truezero
        scalar C_vat   = r(CI)
        scalar Kakwani = C_vat - G_market
        scalar RS      = G_after - G_market
        post ceq_handle ("`rank'") ("`s'") ///
            (G_market) (G_after) (C_vat) (Kakwani) (RS)
        capture drop consumable
    }
}
postclose ceq_handle

********************************************************************************
* END
********************************************************************************