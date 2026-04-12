********************************************************************************
* 10_reform_chicken_inputs.do
*
* OBJECTIVE:
* Simulate the distributional impact of a VAT increase on poultry production
* inputs (compound feed, day-old chicks, veterinary products) using a price
* pass-through approximation.
*
* ─────────────────────────────────────────────────────────────────────────────
* METHODOLOGICAL NOTE
* ─────────────────────────────────────────────────────────────────────────────
* Production inputs for poultry (aliments composés, poussins d'un jour,
* médicaments vétérinaires) are NOT observed in the EHCVM, which is a
* household FINAL CONSUMPTION survey.
*
* The reform is therefore modeled through its effect on the PRICE OF CHICKEN
* observed in the survey (codpr 34 — Viande de poulet).
*
* TRANSMISSION FORMULA:
*
*   r_reform = α_pt × s_inputs × ΔVAT_inputs
*
* Where:
*   ΔVAT_inputs  : change in VAT rate on production inputs (proportion)
*   s_inputs     : share of total production cost composed of taxable inputs
*   α_pt         : pass-through rate (share of cost increase passed to price)
*   r_reform     : implied effective additional price burden on chicken
*
* This r_reform is applied as an additional implicit effective VAT rate on
* household expenditures for chicken (codpr 34).
*
* ─────────────────────────────────────────────────────────────────────────────
* REFORM PARAMETERS
* ─────────────────────────────────────────────────────────────────────────────
*
* Reform: apply 18% standard TVA rate to previously exempt poultry inputs
*   - Aliments composés pour volailles : currently 0% → 18%
*   - Poussins d'un jour               : currently 0% → 18%
*   - Médicaments vétérinaires         : currently 0% → 18%
*
* Production cost structure (West African industrial poultry, typical):
*   - Aliments composés  : ~65% of total cost
*   - Poussins d'un jour : ~18%
*   - Médicaments/vaccins: ~6%
*   → Taxable input share (s_inputs): 0.65 / 0.75 / 0.89 (low/central/high)
*
* Three pass-through scenarios:
*   - Conservative (S1): α_pt = 0.50  (imperfect competition, partial absorption)
*   - Central      (S2): α_pt = 0.70  (reference scenario)
*   - Full         (S3): α_pt = 1.00  (perfectly competitive market, full shift)
*
* ─────────────────────────────────────────────────────────────────────────────
* PRODUCTS CONCERNED
* ─────────────────────────────────────────────────────────────────────────────
*   codpr 34 : Viande de poulet         (primary channel — market purchases)
*   codpr 33 : Poulet sur pied          (secondary — if purchased)
*   codpr 35 : Autres volailles         (secondary — if purchased)
*
* ─────────────────────────────────────────────────────────────────────────────
* OUTPUTS
* ─────────────────────────────────────────────────────────────────────────────
*   - Budget share of chicken by decile
*   - Implied effective tax rate on chicken by decile, for each scenario
*   - Change in household VAT burden by decile (FCFA and % of consumption)
*   - Estimated fiscal revenue gain
*   - Distributional assessment (progressive / regressive ?)
*
* AUTHOR: CAE — ANStat · Avril 2026
********************************************************************************

clear all
set more off

********************************************************************************
* STEP 0 — Reform parameters
********************************************************************************

* VAT change on inputs (proportion)
scalar delta_vat_inputs = 0.18     // 0% → 18% standard rate

* Input cost shares (proportion of total production cost)
scalar s_inputs_low     = 0.65     // conservative: only aliments composés
scalar s_inputs_central = 0.75     // central: aliments + poussins
scalar s_inputs_high    = 0.89     // high: aliments + poussins + médicaments

* Pass-through rates
scalar alpha_low        = 0.50     // partial absorption (imperfect competition)
scalar alpha_central    = 0.70     // reference scenario
scalar alpha_full       = 1.00     // full pass-through (competitive market)

* Implied effective reform rates: r_reform = alpha × s_inputs × delta_vat
* Central scenario (reference):
scalar r_reform_central = alpha_central * s_inputs_central * delta_vat_inputs

di as text "─────────────────────────────────────────"
di as text " Reform scenarios — implied price impact"
di as text "─────────────────────────────────────────"
di as text " S1 Conservative : " %5.2f (alpha_low    * s_inputs_low    * delta_vat_inputs * 100) "%"
di as text " S2 Central      : " %5.2f (alpha_central * s_inputs_central * delta_vat_inputs * 100) "%"
di as text " S3 Full pass-th.: " %5.2f (alpha_full   * s_inputs_high   * delta_vat_inputs * 100) "%"
di as text "─────────────────────────────────────────"

********************************************************************************
* STEP 1 — Load product-level data (post-mapping)
********************************************************************************

use "$SILVER/01/conso_clean.dta", clear

********************************************************************************
* STEP 2 — Identify chicken products and compute budget shares
********************************************************************************

* Flag poultry products concerned by the reform
gen poultry = inlist(code, 34, 33, 35)
label variable poultry "Poultry product (reform-affected)"

* Poultry expenditure at item level
gen depan_poultry = depan_w * poultry
label variable depan_poultry "Expenditure on poultry (winsorized)"

* Baseline VAT at item level (needed for household-level aggregation later)
gen vat_item_w = depan_w * r_vat_official

* Household-level aggregates from product-level data
bys hhid: egen conso_w_hh = total(depan_w)
label variable conso_w_hh "Total household consumption (winsorized)"

* Decile ranking on household consumption
xtile decile = conso_w_hh [pw=hhweight], n(10)

label define dec_lbl 1 "D1 poorest" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 richest", replace
label values decile dec_lbl

********************************************************************************
* STEP 3 — Budget share of chicken by decile
********************************************************************************

preserve
collapse ///
    (mean) conso_w                           ///
    (sum)  poul_tot   = depan_poultry         ///
    [pw=hhweight], by(decile)

gen share_poultry = poul_tot / conso_w * 100
label variable share_poultry "Budget share of poultry (%)"

di as text ""
di as text "─────────────────────────────────────────────────────────────"
di as text " Budget share of chicken by welfare decile"
di as text "─────────────────────────────────────────────────────────────"
list decile share_poultry, noobs sep(0)

export excel using "$TABLES/10/10_poultry_budget_share.xlsx", ///
    firstrow(variables) replace
restore

********************************************************************************
* STEP 4 — Apply reform: compute additional VAT burden under 3 scenarios
********************************************************************************

* S1 — Conservative
gen r_reform_s1 = (alpha_low    * s_inputs_low    * delta_vat_inputs) * poultry
gen vat_reform_s1 = depan_w * r_reform_s1
label variable vat_reform_s1 "Additional VAT burden — S1 conservative"

* S2 — Central (reference)
gen r_reform_s2 = (alpha_central * s_inputs_central * delta_vat_inputs) * poultry
gen vat_reform_s2 = depan_w * r_reform_s2
label variable vat_reform_s2 "Additional VAT burden — S2 central"

* S3 — Full pass-through
gen r_reform_s3 = (alpha_full   * s_inputs_high   * delta_vat_inputs) * poultry
gen vat_reform_s3 = depan_w * r_reform_s3
label variable vat_reform_s3 "Additional VAT burden — S3 full pass-through"

********************************************************************************
* STEP 5 — Aggregate to household level
********************************************************************************

sort hhid
by hhid: egen vat_baseline = total(vat_item_w)
by hhid: egen dpoul        = total(depan_poultry)
by hhid: gen  hh_tag       = (_n == 1)

by hhid: egen add_vat_s1 = total(vat_reform_s1)
by hhid: egen add_vat_s2 = total(vat_reform_s2)
by hhid: egen add_vat_s3 = total(vat_reform_s3)

keep if hh_tag == 1

* Total VAT after reform
gen vat_post_s1 = vat_baseline + add_vat_s1
gen vat_post_s2 = vat_baseline + add_vat_s2
gen vat_post_s3 = vat_baseline + add_vat_s3

* Effective VAT rates
gen eff_vat_base = vat_baseline  / conso_w_hh
gen eff_vat_s1   = vat_post_s1   / conso_w_hh
gen eff_vat_s2   = vat_post_s2   / conso_w_hh
gen eff_vat_s3   = vat_post_s3   / conso_w_hh

* Change in effective VAT rate
gen delta_eff_s1 = eff_vat_s1 - eff_vat_base
gen delta_eff_s2 = eff_vat_s2 - eff_vat_base
gen delta_eff_s3 = eff_vat_s3 - eff_vat_base

label variable eff_vat_base "Effective VAT rate — baseline"
label variable eff_vat_s1   "Effective VAT rate — post-reform S1"
label variable eff_vat_s2   "Effective VAT rate — post-reform S2"
label variable eff_vat_s3   "Effective VAT rate — post-reform S3"
label variable delta_eff_s1 "Change in effective VAT rate — S1"
label variable delta_eff_s2 "Change in effective VAT rate — S2"
label variable delta_eff_s3 "Change in effective VAT rate — S3"

********************************************************************************
* STEP 6 — Distributional results by decile
********************************************************************************

preserve
collapse ///
    (mean) conso_w_hh dpoul                            ///
    (mean) eff_vat_base eff_vat_s1 eff_vat_s2 eff_vat_s3 ///
    (mean) delta_eff_s1 delta_eff_s2 delta_eff_s3         ///
    (sum)  add_vat_tot_s1 = add_vat_s1                    ///
    (sum)  add_vat_tot_s2 = add_vat_s2                    ///
    (sum)  add_vat_tot_s3 = add_vat_s3                    ///
    [pw=hhweight], by(decile)

* Share of additional fiscal burden borne by each decile
foreach s in s1 s2 s3 {
    egen total_add_`s' = total(add_vat_tot_`s')
    gen share_burden_`s' = add_vat_tot_`s' / total_add_`s' * 100
    label variable share_burden_`s' "Share of additional VAT burden — `s' (%)"
    drop total_add_`s'
}

di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Distributional impact — S2 Central scenario"
di as text " (α=0.70 × s_inputs=0.75 × ΔVAT=18% → ~9.45% price impact)"
di as text "─────────────────────────────────────────────────────────────────────"
list decile eff_vat_base eff_vat_s2 delta_eff_s2 share_burden_s2, noobs sep(0)

cap mkdir "$TABLES/10"
export excel using "$TABLES/10/10_reform_distributional_results.xlsx", ///
    firstrow(variables) replace

save "$SILVER/06/reform_chicken_inputs.dta", replace
restore

********************************************************************************
* STEP 7 — Fiscal revenue estimate
********************************************************************************

preserve
collapse ///
    (sum) add_vat_s1 add_vat_s2 add_vat_s3 ///
    [pw=hhweight]

di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Estimated additional fiscal revenue (weighted, survey units)"
di as text "─────────────────────────────────────────────────────────────────────"
di as text " S1 Conservative : " add_vat_s1
di as text " S2 Central      : " add_vat_s2
di as text " S3 Full         : " add_vat_s3
di as text "─────────────────────────────────────────────────────────────────────"
restore

********************************************************************************
* STEP 8 — Kakwani index of reform progressivity (3 scenarios)
*
* PURPOSE:
* Single synthetic measure of distributional impact.
* Kakwani = CI(reform burden) − Gini(pre-tax consumption)
*   Kakwani < 0 → reform is REGRESSIVE (poor bear larger relative burden)
*   Kakwani > 0 → reform is PROGRESSIVE
*
* METHOD:
* Concentration index via the generalized formula (O'Donnell et al. 2008):
*   CI = 2/μ × cov_w(t_i, F_i)
*     where F_i = weighted fractional rank in the consumption distribution
*     and   μ   = weighted mean of the variable of interest
*
* Computed at household level (before decile collapse) using survey weights.
********************************************************************************

* Sort by pre-reform consumption to define welfare ranking
sort conso_w_hh

* Weighted fractional rank — midpoint rule: F_i = (CW_{i-1} + w_i/2) / W
gen cumw_rank  = sum(hhweight)
local totw_kak = cumw_rank[_N]
gen frac_rank  = (cumw_rank - hhweight / 2) / `totw_kak'

* ── Gini of pre-tax consumption ─────────────────────────────────────────────
sum conso_w_hh [aw=hhweight]
local mu_c = r(mean)

gen w_xF_c = hhweight * (conso_w_hh / `mu_c') * frac_rank
sum w_xF_c
local Gini_c = 2 * r(sum) / `totw_kak' - 1
drop w_xF_c

* ── Concentration index and Kakwani for each scenario ───────────────────────
foreach sc in s1 s2 s3 {
    sum add_vat_`sc' [aw=hhweight]
    local mu_t = r(mean)
    gen w_tF_`sc' = hhweight * (add_vat_`sc' / `mu_t') * frac_rank
    sum w_tF_`sc'
    local CI_`sc'      = 2 * r(sum) / `totw_kak' - 1
    local Kakwani_`sc' = `CI_`sc'' - `Gini_c'
    drop w_tF_`sc'
}

drop cumw_rank frac_rank

* ── Display ─────────────────────────────────────────────────────────────────
di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Kakwani index — progressivity of poultry input reform"
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Gini (pre-reform consumption) : " as result %6.4f `Gini_c'
di as text ""
di as text "             CI(reform)   Kakwani   Direction"
foreach sc in s1 s2 s3 {
    local dir = cond(`Kakwani_`sc'' < 0, "REGRESSIVE", ///
                cond(`Kakwani_`sc'' > 0, "PROGRESSIVE", "PROPORTIONAL"))
    di as text " `sc'   " as result %9.4f `CI_`sc'' as text "  " ///
                          as result %9.4f `Kakwani_`sc'' as text "  `dir'"
}
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Note: Kakwani < 0 → poor bear a proportionally larger share of the burden."

* ── Export Kakwani results ───────────────────────────────────────────────────
preserve
clear
set obs 3
gen str3 scenario     = ""
gen      gini_cons    = `Gini_c'
gen      ci_reform    = .
gen      kakwani      = .
replace scenario   = "S1" in 1
replace scenario   = "S2" in 2
replace scenario   = "S3" in 3
replace ci_reform  = `CI_s1'      in 1
replace ci_reform  = `CI_s2'      in 2
replace ci_reform  = `CI_s3'      in 3
replace kakwani    = `Kakwani_s1' in 1
replace kakwani    = `Kakwani_s2' in 2
replace kakwani    = `Kakwani_s3' in 3
gen str15 direction = cond(kakwani < 0, "Regressive", ///
                      cond(kakwani > 0, "Progressive", "Proportional"))
export excel using "$TABLES/10/10_reform_kakwani.xlsx", firstrow(variables) replace
restore

********************************************************************************
* STEP 9 — Distributional assessment: is the reform regressive?
********************************************************************************
* Quick decile-level check: compare D1 vs D10 effective rate change.

use "$SILVER/06/reform_chicken_inputs.dta", clear
sort decile

di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Regressivity check — S2 Central scenario"
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Δ effective rate D1  (poorest) : " %6.4f delta_eff_s2[1]
di as text " Δ effective rate D10 (richest) : " %6.4f delta_eff_s2[10]

if delta_eff_s2[1] > delta_eff_s2[10] {
    di as error " → REGRESSIVE: poor households bear a proportionally larger burden"
}
else if delta_eff_s2[1] < delta_eff_s2[10] {
    di as result " → PROGRESSIVE: rich households bear a proportionally larger burden"
}
else {
    di as text " → PROPORTIONAL: burden is equal across deciles"
}
di as text "─────────────────────────────────────────────────────────────────────"

********************************************************************************
* STEP 10 — Sensitivity cross-table: α × s_inputs grid
*
* PURPOSE:
* Maps the full parameter space (4 pass-through rates × 3 input cost shares).
* Shows that the direction of regressivity is robust to these assumptions:
* it is determined solely by budget shares (dpoul/conso), not by scale factors.
* The table reports magnitude variation useful for a working paper robustness section.
*
* NOTE: budget share ratios (D1 vs D10) are constant across all (α, s) combinations,
* so the sign of Kakwani will not change — only its magnitude.
********************************************************************************

* Budget share of poultry by decile (ratio dpoul / conso_w_hh)
* decile 1 = row 1, decile 10 = row 10 after sort
local bs_d1  = dpoul[1]  / conso_w_hh[1]
local bs_d10 = dpoul[10] / conso_w_hh[10]

di as text ""
di as text " Poultry budget share — D1 (poorest) : " as result %5.3f `bs_d1'  * 100 as text "%"
di as text " Poultry budget share — D10 (richest): " as result %5.3f `bs_d10' * 100 as text "%"

* Build 12-row results matrix (4 alphas × 3 shares)
matrix SENS = J(12, 5, .)
local row = 0

foreach a_int in 30 50 70 100 {
    foreach s_int in 65 75 89 {
        local ++row
        local a = `a_int' / 100
        local s = `s_int' / 100
        local r = `a' * `s' * 0.18

        matrix SENS[`row', 1] = `a'
        matrix SENS[`row', 2] = `s'
        matrix SENS[`row', 3] = `r' * 100
        matrix SENS[`row', 4] = `bs_d1'  * `r' * 100   // Δeff D1  (pp)
        matrix SENS[`row', 5] = `bs_d10' * `r' * 100   // Δeff D10 (pp)
    }
}

* Display
di as text ""
di as text "───────────────────────────────────────────────────────────────────────────"
di as text " Sensitivity cross-table — delta effective VAT rate (pp) by scenario"
di as text "───────────────────────────────────────────────────────────────────────────"
di as text "  α(pass-thru)  s(input share)  Price impact  Δeff_D1   Δeff_D10  Regress.?"
di as text "───────────────────────────────────────────────────────────────────────────"

forvalues row = 1/12 {
    local a_v   = SENS[`row', 1]
    local s_v   = SENS[`row', 2]
    local r_v   = SENS[`row', 3]
    local d1_v  = SENS[`row', 4]
    local d10_v = SENS[`row', 5]
    local reg   = cond(`d1_v' > `d10_v', "Yes", "No")
    di as text "  " %4.2f `a_v' "        " %4.2f `s_v' "        " ///
               %5.2f `r_v' "%      " %6.4f `d1_v' "    " %6.4f `d10_v' "    `reg'"
}
di as text "───────────────────────────────────────────────────────────────────────────"

* Export
preserve
clear
svmat SENS, names(col)
rename (c1 c2 c3 c4 c5) (alpha s_inputs price_impact_pct delta_eff_d1_pp delta_eff_d10_pp)
gen str3 regressive = cond(delta_eff_d1_pp > delta_eff_d10_pp, "Yes", "No")
export excel using "$TABLES/10/10_reform_sensitivity.xlsx", firstrow(variables) replace
restore

di as text ""
di as text " Sensitivity table exported → $TABLES/10/10_reform_sensitivity.xlsx"

********************************************************************************
* END
********************************************************************************
di as result "=================================================="
di as result " REFORM SIMULATION COMPLETED"
di as result "=================================================="
