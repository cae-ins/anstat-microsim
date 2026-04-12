********************************************************************************
* 11_reform_figures.do
*
* OBJECTIVE:
* Produce all figures for the poultry input VAT reform simulation.
*
* CONTENT:
* Fig R1 — Budget share of poultry by decile (bar)
*           → shows who consumes chicken, as % of total budget
* Fig R2 — Change in effective VAT rate by decile: 3 scenarios (line)
*           → core distributional figure — regressive if slopes downward
* Fig R3 — Effective VAT rate before vs after reform — S2 central (line)
*           → shows the magnitude of the shift by decile
* Fig R4 — Share of additional fiscal burden by decile — S2 (bar)
*           → who pays the new revenue? left-heavy = regressive
*
* DATA: $SILVER/06/reform_chicken_inputs.dta  (decile-level, from script 10)
*
* OUTPUTS:
*   - $FIGS/figR1_poultry_budget_share.png
*   - $FIGS/figR2_delta_eff_vat_scenarios.png
*   - $FIGS/figR3_eff_vat_before_after.png
*   - $FIGS/figR4_burden_share_by_decile.png
*
* AUTHOR: CAE — ANStat · Avril 2026
********************************************************************************

set scheme s1color
use "$SILVER/06/reform_chicken_inputs.dta", clear

* Compute budget share of poultry
gen budget_share_poultry = dpoul / conso_w_hh * 100
label variable budget_share_poultry "Poultry budget share (% of total consumption)"

* Decile labels for x-axis
label define dec_lbl 1 "D1" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10", replace
label values decile dec_lbl

********************************************************************************
* FIGURE R1 — Budget share of poultry by decile
*
* PURPOSE:
* Establishes the baseline consumption pattern: does chicken represent a
* larger share of the budget for poor or for rich households?
* This determines who will be most affected by a price increase.
********************************************************************************

graph bar budget_share_poultry, over(decile, label(angle(0) labsize(small))) ///
    bar(1, color(maroon%75))                                                  ///
    title("Budget share of poultry by welfare decile",                        ///
        size(medium))                                                         ///
    subtitle("Côte d'Ivoire EHCVM 2021 — market purchases only",              ///
        size(small))                                                          ///
    ytitle("Share of household budget (%)", size(small))                      ///
    xtitle("Consumption decile (D1=poorest, D10=richest)", size(small))       ///
    blabel(bar, format(%4.2f) size(vsmall))                                   ///
    note("Products: codpr 34 (viande de poulet), 33 (poulet sur pied), 35 (autres volailles)." ///
         " Source: EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR1_poultry_budget_share.png", replace width(2400) height(1600)
graph save   "$FIGS/figR1_poultry_budget_share.gph", replace

********************************************************************************
* FIGURE R2 — Change in effective VAT rate by decile: 3 scenarios
*
* PURPOSE:
* Core distributional figure of the reform analysis.
* A downward-sloping profile means the reform is REGRESSIVE — poor households
* bear a larger additional burden as a share of their total consumption.
* The spread between scenarios illustrates sensitivity to pass-through
* and input cost share assumptions.
********************************************************************************

twoway ///
    (line delta_eff_s1 decile,                                               ///
        lcolor(navy)        lwidth(medthick) lpattern(dash))                  ///
    (line delta_eff_s2 decile,                                               ///
        lcolor(maroon)      lwidth(thick)    lpattern(solid))                 ///
    (line delta_eff_s3 decile,                                               ///
        lcolor(forest_green) lwidth(medthick) lpattern(shortdash_dot))        ///
    (scatteri 0 1 0 10, recast(line) lcolor(gs12) lwidth(thin) lpattern(dot)) ///
    , ///
    legend(order(                                                             ///
        1 "S1 Conservative ({&alpha}=0.50, s=0.65) — ~5.9% price impact"    ///
        2 "S2 Central ({&alpha}=0.70, s=0.75) — ~9.5% price impact"         ///
        3 "S3 Full pass-through ({&alpha}=1.00, s=0.89) — ~16.0% price impact") ///
        position(6) rows(3) size(small))                                      ///
    title("Change in effective VAT rate — poultry input reform",              ///
        size(medium))                                                         ///
    subtitle("Impact of applying 18% VAT to compound feed, day-old chicks & veterinary products", ///
        size(small))                                                          ///
    ytitle("{&Delta} Effective VAT rate (pp)", size(small))                   ///
    xtitle("Consumption decile (D1=poorest, D10=richest)", size(small))       ///
    xlabel(1(1)10, labsize(small))                                            ///
    ylabel(, angle(horizontal) labsize(small))                                ///
    yline(0, lcolor(black) lwidth(vthin))                                     ///
    note("Reform: 0% → 18% VAT on poultry production inputs." ///
         " Transmission: {&Delta}p = {&alpha} {&times} s_inputs {&times} {&Delta}VAT." ///
         " Source: EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR2_delta_eff_vat_scenarios.png", replace width(2400) height(1600)
graph save   "$FIGS/figR2_delta_eff_vat_scenarios.gph", replace

********************************************************************************
* FIGURE R3 — Effective VAT rate before vs after reform (S2 central)
*
* PURPOSE:
* Shows the absolute shift in effective VAT rate from baseline to post-reform
* under the central scenario. Puts the reform in context of the overall
* tax burden already borne by each decile.
********************************************************************************

twoway ///
    (line eff_vat_base decile,                                               ///
        lcolor(gs8)    lwidth(medthick) lpattern(longdash))                   ///
    (line eff_vat_s2   decile,                                               ///
        lcolor(maroon) lwidth(thick)    lpattern(solid))                      ///
    , ///
    legend(order(                                                             ///
        1 "Baseline (pre-reform)"                                             ///
        2 "Post-reform — S2 Central ({&alpha}=0.70)")                         ///
        position(6) rows(2) size(small))                                      ///
    title("Effective VAT rate before and after reform — S2 Central",          ///
        size(medium))                                                         ///
    subtitle("Côte d'Ivoire EHCVM 2021", size(small))                         ///
    ytitle("Effective VAT rate (VAT / total consumption)", size(small))       ///
    xtitle("Consumption decile (D1=poorest, D10=richest)", size(small))       ///
    xlabel(1(1)10, labsize(small))                                            ///
    ylabel(, angle(horizontal) labsize(small))                                ///
    note("Reform: 18% VAT on poultry production inputs, 70% pass-through, 75% input cost share." ///
         " Source: EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR3_eff_vat_before_after.png", replace width(2400) height(1600)
graph save   "$FIGS/figR3_eff_vat_before_after.gph", replace

********************************************************************************
* FIGURE R4 — Share of additional fiscal burden by decile (S2 central)
*
* PURPOSE:
* Answers: who pays the new revenue?
* If D1–D5 bear more than 50% of the total additional burden → regressive.
* Complements Fig R2 (which shows rates) with absolute shares of the revenue.
********************************************************************************

* Cumulative burden for D1-D5 annotation
egen cum_d1d5 = total(share_burden_s2) if decile <= 5
qui sum cum_d1d5
local cum_poor = string(round(r(mean), 0.1))

graph bar share_burden_s2, over(decile, label(angle(0) labsize(small)))       ///
    bar(1, color(navy%75))                                                    ///
    title("Share of additional fiscal burden by decile — S2 Central",         ///
        size(medium))                                                         ///
    subtitle("Who pays the additional revenue from the reform?",               ///
        size(small))                                                          ///
    ytitle("Share of total additional VAT revenue (%)", size(small))          ///
    xtitle("Consumption decile (D1=poorest, D10=richest)", size(small))       ///
    blabel(bar, format(%4.1f) size(vsmall))                                   ///
    yline(10, lcolor(gs12) lpattern(dot)                                      ///
        text(10.3 5.5 "Equal share = 10%/decile", size(vsmall) color(gs8)))  ///
    note("D1–D5 (bottom half) cumulative share: `cum_poor'%." ///
         " Reform: 18% VAT on poultry inputs, {&alpha}=0.70, s=0.75." ///
         " Source: EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR4_burden_share_by_decile.png", replace width(2400) height(1600)
graph save   "$FIGS/figR4_burden_share_by_decile.gph", replace

********************************************************************************
* END
********************************************************************************

di as result "=================================================="
di as result " REFORM FIGURES COMPLETED — 4 figures exported"
di as result "  figR1 : Poultry budget share by decile"
di as result "  figR2 : Delta effective VAT rate — 3 scenarios"
di as result "  figR3 : Effective VAT before vs after — S2"
di as result "  figR4 : Fiscal burden share by decile — S2"
di as result "=================================================="
