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

use "$SILVER/03/fiscal_data.dta", clear

********************************************************************************
* STEP 2 — Identify chicken products and compute budget shares
********************************************************************************

* Flag poultry products concerned by the reform
gen poultry = inlist(code, 34, 33, 35)
label variable poultry "Poultry product (reform-affected)"

* Poultry expenditure at item level
gen depan_poultry = depan_w * poultry
label variable depan_poultry "Expenditure on poultry (winsorized)"

* Compute decile ranking (use existing conso_w variable)
xtile decile = conso_w [pw=hhweight], n(10)

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
by hhid: egen dpoul = total(depan_poultry)
by hhid: gen  hh_tag = (_n == 1)

by hhid: egen add_vat_s1 = total(vat_reform_s1)
by hhid: egen add_vat_s2 = total(vat_reform_s2)
by hhid: egen add_vat_s3 = total(vat_reform_s3)

keep if hh_tag == 1

* Use existing household-level baseline VAT (from 03_compute_taxes.do)
clonevar vat_baseline = vat_w

* Total VAT after reform
gen vat_post_s1 = vat_baseline + add_vat_s1
gen vat_post_s2 = vat_baseline + add_vat_s2
gen vat_post_s3 = vat_baseline + add_vat_s3

* Effective VAT rates (use total household consumption)
gen eff_vat_base = vat_baseline  / conso_w
gen eff_vat_s1   = vat_post_s1   / conso_w
gen eff_vat_s2   = vat_post_s2   / conso_w
gen eff_vat_s3   = vat_post_s3   / conso_w

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
    (mean) conso_w dpoul                               ///
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
* STEP 8 — Distributional assessment : is the reform regressive ?
********************************************************************************
* A reform is regressive if the additional burden (as % of consumption)
* is larger for poorer deciles — i.e., delta_eff_s2 decreasing with decile.
*
* Quick check: compare D1 vs D10 effective rate change.

use "$SILVER/06/reform_chicken_inputs.dta", clear

di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Regressivity check — S2 Central scenario"
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Δ effective rate D1  (poorest) : " %6.4f delta_eff_s2[1]
di as text " Δ effective rate D10 (richest) : " %6.4f delta_eff_s2[10]

* If D1 > D10 → regressive reform
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
* END
********************************************************************************
di as result "=================================================="
di as result " REFORM SIMULATION COMPLETED"
di as result "=================================================="
