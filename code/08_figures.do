********************************************************************************
* 08_figures.do
*
* OBJECTIVE:
* Produce all figures for VAT incidence analysis.
*
* CONTENT:
* Fig 1 — Effective VAT rates by decile: three scenarios 
* Fig 2 — Concentration curves: three scenarios + Lorenz + equality line
* Fig 3 — VAT by COICOP category (descriptive)
* Fig 5 — Alpha profiles by decile: food/bev, restaurants, personal care,
*          info/comm (illustrates CEI calibration)
*
* OUTPUTS:
*   - $FIGS/fig1_eff_vat_three_scenarios.png
*   - $FIGS/fig2_concentration_curves.png
*   - $FIGS/fig3_vat_by_coicop.png
*   - $FIGS/fig4_alpha_profiles.png
*
* NOTE ON SCHEME:
* s1color is used for compatibility.
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

set scheme s1color

********************************************************************************
* FIGURE 1 — Effective VAT rates by decile: three scenarios
*
* PURPOSE:
* This is the central figure of the analysis. It shows visually why the
* distributional conclusion depends entirely on the informality assumption:
*   - Strict: quasi-flat/slightly regressive profile
*   - S2 (CEI × milieu): rising profile, moderate gradient
*   - S3 (CEI × décile): clearly rising profile, strongest gradient
*
* SOURCE: fiscal_sensitivity_taxation.dta (household level)
********************************************************************************

use "$OUTPUT/final_data/06/fiscal_sensitivity_taxation.dta", clear

preserve
collapse (mean) eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [pw=hhweight], by(decile)

* Verify monotonic labeling
assert decile >= 1 & decile <= 10

twoway ///
    (line eff_vat_strict decile, ///
        lcolor(maroon)       lwidth(medthick) lpattern(solid))         ///
    (line eff_vat_s2     decile, ///
        lcolor(navy)         lwidth(medthick) lpattern(dash))          ///
    (line eff_vat_s3     decile, ///
        lcolor(forest_green) lwidth(medthick) lpattern(shortdash_dot)) ///
    , ///
    legend(order(                                                        ///
        1 "Strict ({&alpha}=1) — theoretical upper bound"               ///
        2 "S2: CEI x milieu urbain/rural (Bachas et al. 2024)"   ///
        3 "S3: CEI x decile — IEC calibrated")          ///
        position(6) rows(3) size(small))                                 ///
    title("Effective VAT rate by consumption decile", size(medium))      ///
    subtitle("Three informality scenarios — Côte d'Ivoire EHCVM 2021",  ///
        size(small))                                                     ///
    ytitle("Effective VAT rate (VAT / consumption)", size(small))        ///
    xtitle("Consumption decile", size(small))                            ///
    ylabel(0(.02).16, angle(horizontal) labsize(small))                  ///
    xlabel(1(1)10, labsize(small))                                       ///
    note("Source: EHCVM 2021. Alpha calibration: Bachas, Gadenne & Jensen (2024, RestUD 91(5)).", ///
        size(vsmall))                                                    ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig1_eff_vat_three_scenarios.png", ///
    replace width(2400) height(1600)

restore

********************************************************************************
* FIGURE 2 — Concentration curves: three scenarios + Lorenz + equality
*
* PURPOSE:
* Shows visually the distributional position of each scenario relative to
* the Lorenz curve:
*   - Concentration curve BELOW Lorenz → regressive (Kakwani < 0)
*   - Concentration curve ABOVE Lorenz → progressive (Kakwani > 0)
* The three curves illustrate the sensitivity of the conclusion.
*
* TECHNICAL NOTE:
* Curves are computed on household-level data sorted by conso_w.
* Weights are used for both population share and cumulative sums.
********************************************************************************

use "$OUTPUT/final_data/06/fiscal_sensitivity_taxation.dta", clear

* Sort by welfare
gsort conso_w

* Cumulative population share (weighted)
gen w = hhweight
gen cum_pop = sum(w)
replace cum_pop = cum_pop / cum_pop[_N]

* Lorenz curve (consumption)
gen cum_conso = sum(conso_w * w)
replace cum_conso = cum_conso / cum_conso[_N]

* Concentration curve — strict
gen cum_vat_strict = sum(vat_strict * w)
replace cum_vat_strict = cum_vat_strict / cum_vat_strict[_N]

* Concentration curve — S2
gen cum_vat_s2 = sum(vat_s2 * w)
replace cum_vat_s2 = cum_vat_s2 / cum_vat_s2[_N]

* Concentration curve — S3
gen cum_vat_s3 = sum(vat_s3 * w)
replace cum_vat_s3 = cum_vat_s3 / cum_vat_s3[_N]

twoway ///
    (line cum_conso      cum_pop, ///
        lcolor(black)        lwidth(thick)    lpattern(longdash))       ///
    (line cum_vat_strict cum_pop, ///
        lcolor(maroon)       lwidth(thin)     lpattern(solid))           ///
    (line cum_vat_s2     cum_pop, ///
        lcolor(navy)         lwidth(medthick) lpattern(dash))            ///
    (line cum_vat_s3     cum_pop, ///
        lcolor(forest_green) lwidth(medthick) lpattern(shortdash_dot))   ///
    (line cum_pop        cum_pop, ///
        lcolor(gs10)         lwidth(thin)     lpattern(dot))             ///
    , ///
    legend(order(                                                         ///
        2 "Concentration — Strict (a=1)"                                 ///
        3 "Concentration — S2 (CEI x milieu)"                            ///
        4 "Concentration — S3 (CEI x decile)"                            ///
        1 "Lorenz — consommation"                                         ///
        5 "Equality line")                                                ///
        position(5) ring(0) cols(1) size(small))                          ///
    title("Concentration curves — VAT under three scenarios")             ///
    subtitle("Curve above Lorenz = progressive | Curve below = regressive") ///
    ytitle("Cumulative share")                                            ///
    xtitle("Cumulative population share (ranked by consumption)")         ///
    ylabel(0(.2)1, angle(horizontal) labsize(small))                      ///
    xlabel(0(.2)1, labsize(small))                                        ///
    note("Source: EHCVM 2021. Bachas, Gadenne & Jensen (2024, RestUD 91(5)).", ///
        size(vsmall))                                                     ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig2_concentration_curves.png", ///
    replace width(2400) height(1600)
graph save "$FIGS/fig2_concentration_curves.gph"
, ///
    replace width(2400) height(1600)


********************************************************************************
* FIGURE 3 — Total VAT by COICOP category (descriptive)
*
* PURPOSE:
* Shows which consumption categories contribute most to total VAT revenue.
* Purely descriptive — independent of informality assumptions.
* Useful to explain why food/restaurants/personal care are the pivotal
* categories in the sensitivity analysis (large share + high IEC slope).
*
* SOURCE: conso_clean.dta (item level)
********************************************************************************

use "$OUTPUT/final_data/01/conso_clean.dta", clear

gen vat_item_w = depan_w * r_vat_official

preserve
collapse (sum) vat_total = vat_item_w ///
    (sum) conso_total = depan_w ///
    [pw=hhweight], by(coicop)

* Effective rate by category
gen eff_rate_coicop = vat_total / conso_total

* Share of total VAT
egen grand_vat = total(vat_total)
gen vat_share = vat_total / grand_vat * 100

* Drop non-consumption
drop if coicop == 98 | coicop == 99

gsort -vat_share

graph bar vat_share, over(coicop, sort(1) descending                    ///
        relabel(                                                          ///
            1 "Food/bev"        2 "Alcohol/tob"  3 "Clothing"           ///
            4 "Housing"         5 "Furnishings"  6 "Health"              ///
            7 "Transport"       8 "Telecom"      9 "Recreation"          ///
            10 "Education"      11 "Restaurants" 12 "Insurance"          ///
            13 "Personal care") label(angle(45)))                         ///
    bar(1, color(navy%80))                                               ///
    title("Share of total VAT revenue by COICOP category",               ///
        size(medium))                                                     ///
    subtitle("Côte d'Ivoire EHCVM 2021 — strict scenario",               ///
        size(small))                                                      ///
    ytitle("Share of total VAT (%)", size(small))                        ///
    note("Source: EHCVM 2021. VAT computed at item level (r_vat_official).", ///
        size(vsmall))                                                     ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig3_vat_by_coicop.png", ///
    replace width(2400) height(1600)

restore

********************************************************************************
* FIGURE 4 — Alpha profiles by decile for key categories
*
* PURPOSE:
* Illustrates the CEI calibration (Scenario 3) for the four most analytically
* important COICOP categories:
*   - food/bev (coicop=1)     : steepest IEC slope, largest budget share
*   - restaurants (coicop=11) : steepest IEC slope, semi-formal
*   - personal care (coicop=13): steep IEC slope, large share (9.56%)
*   - info/comm (coicop=8)    : flattest IEC slope, near-formal throughout
*
* This figure justifies why the informality assumption matters most for
* food, restaurants, and personal care — the categories that drive the
* reversal of the Kakwani sign between strict and S3.
*
* SOURCE: computed directly from alpha calibration formulas
********************************************************************************

* Build alpha_3 profile analytically (same formulas as 06_01)
clear
set obs 10
gen decile = _n

* food/bev : alpha_D1=0.12, slope=0.034
gen alpha_food = 0.12 + (decile - 1) * 0.034

* restaurants : alpha_D1=0.12, slope=0.038
gen alpha_rest = 0.12 + (decile - 1) * 0.038

* personal care : alpha_D1=0.15, slope=0.034
gen alpha_care = 0.15 + (decile - 1) * 0.034

* info/comm : alpha_D1=0.78, slope=0.015
gen alpha_tel  = 0.78 + (decile - 1) * 0.015

* Cap at 1
foreach v in alpha_food alpha_rest alpha_care alpha_tel {
    replace `v' = min(`v', 1)
}

twoway ///
    (line alpha_food decile, ///
        lcolor(maroon)       lwidth(medthick) lpattern(solid))          ///
    (line alpha_rest decile, ///
        lcolor(navy)         lwidth(medthick) lpattern(dash))           ///
    (line alpha_care decile, ///
        lcolor(orange)       lwidth(medthick) lpattern(shortdash_dot))  ///
    (line alpha_tel  decile, ///
        lcolor(forest_green) lwidth(medthick) lpattern(longdash))       ///
    , ///
    legend(order(                                                         ///
        1 "Food/beverages (coicop=1)"                                    ///
        2 "Restaurants (coicop=11)"                                      ///
        3 "Personal care (coicop=13)"                                    ///
        4 "Telecom/info-comm (coicop=8)")                                ///
        position(5) ring(0) cols(1) size(small))                         ///
    title("Effective alpha by consumption decile — Scenario 3",          ///
        size(medium))                                                    ///
    subtitle("Informality Engel Curve calibration (Bachas et al. 2024)", ///
        size(small))                                                     ///
    ytitle("Effective alpha ({&alpha})", size(small))                    ///
    xtitle("Consumption decile", size(small))                            ///
    ylabel(0(.1)1, angle(horizontal) labsize(small))                     ///
    xlabel(1(1)10, labsize(small))                                       ///
    yline(1, lcolor(gs12) lpattern(dot))                                 ///
    note("Alpha = effective VAT pass-through rate (0 = fully informal, 1 = fully formal)." ///
         " Slopes calibrated from IEC estimates for lower-middle income countries.",       ///
        size(vsmall))                                                    ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig4_alpha_profiles_iec.png", ///
    replace width(2400) height(1600)

********************************************************************************
* END
********************************************************************************

