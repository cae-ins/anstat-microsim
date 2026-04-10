********************************************************************************
* 06_01_sensitivity_taxation_v2.do
*
* OBJECTIVE:
* Sensitivity analysis of VAT incidence to alternative assumptions about
* effective VAT application — grounded in the Informality Engel Curve (IEC)
* framework of Bachas, Gadenne & Jensen (2024).
*
* ────────────────────────────────────────────────────────────────────────────
* EMPIRICAL RATIONALE
* ────────────────────────────────────────────────────────────────────────────
*
* The baseline (strict) scenario assumes alpha = 1, i.e. full effective
* taxation of all taxable purchases. This is the theoretical upper bound.
*
*
* ────────────────────────────────────────────────────────────────────────────
* KEY REFERENCE: BACHAS, GADENNE & JENSEN (2024)
* ────────────────────────────────────────────────────────────────────────────
*
* Bachas P., Gadenne L., Jensen A. (2024). "Informality, Consumption Taxes,
* and Redistribution." Review of Economic Studies, 91(5): 2604–2634.
* https://doi.org/10.1093/restud/rdad095
*
* Main finding: the informal budget share STEEPLY DECLINES with income
* (Informality Engel Curve, IEC). Consequence: a broad consumption tax
* applied only to formal purchases is de facto PROGRESSIVE, because poor
* households buy proportionally more in informal markets.
*
* Quantitative benchmarks from Bachas et al. for low-income/lower-middle
* income countries (comparable to Côte d'Ivoire):
*   - D1 (poorest): informal budget share ≈ 75–90%
*   - D10 (richest): informal budget share ≈ 40–55%
*   → Implied effective alpha rises from ~0.10–0.25 (D1) to ~0.45–0.60 (D10)
*     for the most informal categories (food, restaurants, personal care)
*
* Secondary references:
*   - UNECA (2019). Economic Report on Africa, Chapter 3. VAT collection
*     efficiency below 50% in many African countries; VAT gaps 50–90%.
*   - WATAF/ECOWAS (2023). VAT Collection Efficiency in West Africa.
*     Niger VAT C-efficiency ratio = 0.24 (below SSA average of 0.27);
*     large informal sector is the main driver.
*   - World Bank (2024). Urban Informality in Sub-Saharan Africa (WPS 10703).
*     56–65% of urban workers in SSA are informal; informality persistent
*     in the 2010s with no systematic urban reduction.
*
* ────────────────────────────────────────────────────────────────────────────
* THREE SCENARIOS
* ────────────────────────────────────────────────────────────────────────────
*
* SCENARIO 1 — Strict (alpha = 1)
*   Full pass-through, full enforcement. Theoretical upper bound.
*   Serves as baseline for comparison.
*
* SCENARIO 2 — CEI × milieu urbain/rural
*   Alpha differentiated by COICOP category AND urban/rural status.
*   Rationale: informal sector access varies structurally between urban and
*   rural areas. Rural households have systematically higher informal budget
*   shares, especially for food, restaurants, and personal care. Urban
*   households have greater access to formal retail, utilities, and telecom.
*   Source: Bachas et al. (2024); World Bank WPS 10703 (2024).
*
* SCENARIO 3 — CEI × decile (Informality Engel Curve fully calibrated)
*   Alpha increases linearly with expenditure decile, by COICOP category.
*   This directly implements the IEC slope estimated by Bachas et al. (2024)
*   for lower-middle income countries:
*     alpha(d) = alpha_D1 + (d-1) × slope
*   where alpha_D1 and slope are calibrated per COICOP from the empirical
*   IEC literature.
*   This scenario tests whether the progressive structure of informal
*   consumption is sufficient to overturn the regressivity conclusion.
*
* IMPORTANT NOTE ON ALPHA INTERPRETATION:
*   These alphas are NOT compliance rates in the legal sense. They are
*   reduced-form approximations of the effective VAT pass-through at the
*   household level, incorporating:
*     (1) informality of the point of purchase (primary channel, Bachas et al.)
*     (2) administrative gaps and exemptions (UNECA 2019)
*     (3) input VAT embedded in informal prices (~10% pass-through,
*         estimated by Bachas et al. from Mexican census data; applied here
*         as a conservative lower bound)
*
* OUTPUTS:
*   - household-level VAT under each scenario
*   - effective VAT rates by decile under each scenario
*   - decile tables: effective rates + VAT shares
*   - CEQ-style summary indices (Gini, CI, Kakwani, Reynolds-Smolensky)
*   - Bootstrap confidence intervals on Kakwani
*   - sensitivity dataset saved for later use

*AUTHOR: Armand Kouakou Djaha, MSc

********************************************************************************

use "$OUTPUT/final_data/01/conso_clean.dta", clear

********************************************************************************
* STEP 0 — Validation
********************************************************************************

assert !missing(hhid, hhweight, depan_w, r_vat_official)
assert !missing(coicop, milieu)
assert depan_w > 0
assert r_vat_official >= 0

* coicop: 1=food/bev 2=alcohol/tobacco 3=clothing/footwear 4=housing/utilities
*         5=furnishings/equipment 6=health 7=transport 8=info/comm
*         9=recreation 10=education 11=restaurants 12=insurance
*         13=personal care 98=not included 99=NOT CONSUMPTION
* milieu: 1=Urbain 2=Rural

********************************************************************************
* STEP 1 — Baseline strict scenario (alpha = 1)
* Rationale: theoretical upper bound, full enforcement assumption.
* Serves as distributional reference.
********************************************************************************

gen vat_item_strict = depan_w * r_vat_official
label variable vat_item_strict ///
    "VAT item burden - strict scenario (alpha=1, full taxation)"


********************************************************************************
* STEP 2 — SCENARIO 2: CEI × milieu urbain/rural
*
* EMPIRICAL BASIS:
* Alpha values are calibrated from two sources:
*
* (A) Bachas, Gadenne & Jensen (2024): informal budget shares by category.
*     Food and restaurants: highly informal in rural areas (IEC > 80%),
*     moderately informal in urban areas (IEC ~50-60%).
*     Telecom (info/comm): near-fully formal regardless of milieu (licensed
*     operators collect VAT at source).
*     Clothing, transport, personal care: intermediate, with clear urban
*     premium in formality.
*
* (B) World Bank WPS 10703 (2024): urban informality in SSA.
*     56-65% of urban workers are informal — confirming that even urban
*     markets are not fully formal. The urban premium in alpha is thus
*     moderate (not a jump to near-1).
*
* Convention: alpha_rural < alpha_urban for all categories.
* The gap is largest for food/restaurants/personal care (strong IEC slope)
* and smallest for utilities/insurance/telecom (near-formal regardless).
*
* Categories coicop==98 and coicop==99: alpha=0 (non-taxable by definition).
********************************************************************************

gen alpha_2 = .

* ── food/bev (coicop 1) ──────────────────────────────────────────────────────
* Most informal category. Rural: predominantly traditional markets
* (IEC ~ 80-90%, Bachas et al.). Urban: mix of supermarkets + markets
* (IEC ~ 50-60%).
replace alpha_2 = 0.18 if coicop == 1  & milieu == 2   // rural
replace alpha_2 = 0.42 if coicop == 1  & milieu == 1   // urbain

* ── alcohol/tobacco (coicop 2) ───────────────────────────────────────────────
* Specific excise duties + more concentrated distribution chain.
* Relatively more formal than general food. Moderate urban premium.
replace alpha_2 = 0.55 if coicop == 2  & milieu == 2
replace alpha_2 = 0.72 if coicop == 2  & milieu == 1

* ── clothing/footwear (coicop 3) ─────────────────────────────────────────────
* Mix of formal boutiques and informal market stalls. Clear urban premium
* (supermarkets, brand stores). Rural: largely informal traders.
replace alpha_2 = 0.28 if coicop == 3  & milieu == 2
replace alpha_2 = 0.52 if coicop == 3  & milieu == 1

* ── housing/utilities (coicop 4) ─────────────────────────────────────────────
* Electricity (CIE/SODECI in Côte d'Ivoire), piped water, formal rent:
* largely formal operators who collect VAT directly. Highest alpha.
* Rural premium is smaller because rural areas have lower utility access,
* but infrastructure that exists is still formal.
replace alpha_2 = 0.68 if coicop == 4  & milieu == 2
replace alpha_2 = 0.84 if coicop == 4  & milieu == 1

* ── furnishings/equipment (coicop 5) ─────────────────────────────────────────
* Artisanal production, second-hand markets dominate in rural areas.
* Urban: mix of formal stores and informal artisans.
replace alpha_2 = 0.28 if coicop == 5  & milieu == 2
replace alpha_2 = 0.48 if coicop == 5  & milieu == 1

* ── health (coicop 6) ────────────────────────────────────────────────────────
* Formal clinics/hospitals vs. traditional medicine/informal pharmacies.
* Health is a mixed sector: formal private clinics in urban areas,
* traditional healers and informal drug vendors in rural areas.
replace alpha_2 = 0.38 if coicop == 6  & milieu == 2
replace alpha_2 = 0.66 if coicop == 6  & milieu == 1

* ── transport (coicop 7) ─────────────────────────────────────────────────────
* Dominated by informal taxis, bush taxis, motorbike taxis (woro-woro,
* gbaka in Côte d'Ivoire). Formal transport (buses, air) is urban and
* concentrated in higher deciles.
replace alpha_2 = 0.32 if coicop == 7  & milieu == 2
replace alpha_2 = 0.62 if coicop == 7  & milieu == 1

* ── info/comm (coicop 8) ─────────────────────────────────────────────────────
* HIGHEST ALPHA. Mobile operators (Orange, MTN, Moov), internet providers:
* all formally registered, VAT collected at source by licensed operators.
* OECD/WBG/ATAF VAT Digital Toolkit for Africa (2023) confirms near-full
* formality of telecom VAT collection.
* Small residual informality for second-hand phones etc.
replace alpha_2 = 0.82 if coicop == 8  & milieu == 2
replace alpha_2 = 0.94 if coicop == 8  & milieu == 1

* ── recreation (coicop 9) ────────────────────────────────────────────────────
* Very small share (0.15% of observations). Mix of formal/informal.
replace alpha_2 = 0.35 if coicop == 9  & milieu == 2
replace alpha_2 = 0.58 if coicop == 9  & milieu == 1

* ── education (coicop 10) ────────────────────────────────────────────────────
* Registered schools and universities issue receipts. Largely formal,
* but private informal tutoring and unregistered schools exist in rural areas.
replace alpha_2 = 0.62 if coicop == 10 & milieu == 2
replace alpha_2 = 0.78 if coicop == 10 & milieu == 1

* ── restaurants (coicop 11) ──────────────────────────────────────────────────
* Highly informal: street food, maquis, gargotes dominate at all income
* levels in Côte d'Ivoire, especially in rural areas. Formal restaurants
* (with bills/receipts) are concentrated in urban upper deciles.
* Strong IEC slope: very similar to food/bev.
replace alpha_2 = 0.18 if coicop == 11 & milieu == 2
replace alpha_2 = 0.52 if coicop == 11 & milieu == 1

* ── insurance (coicop 12) ────────────────────────────────────────────────────
* Formal by definition (licensed insurers). Very small share (0.15%).
replace alpha_2 = 0.88 if coicop == 12 & milieu == 2
replace alpha_2 = 0.95 if coicop == 12 & milieu == 1

* ── personal care (coicop 13) ────────────────────────────────────────────────
* Hair salons, barbers, cosmetics: highly informal sector.
* Large share (9.56% of observations). Strong IEC slope.
replace alpha_2 = 0.22 if coicop == 13 & milieu == 2
replace alpha_2 = 0.48 if coicop == 13 & milieu == 1

* ── not included / not consumption ──────────────────────────────────────────
replace alpha_2 = 0    if coicop == 98
replace alpha_2 = 0    if coicop == 99

* Verify no missing alpha for taxable items
assert !missing(alpha_2) if r_vat_official > 0

gen vat_item_s2 = alpha_2 * vat_item_strict
label variable vat_item_s2 ///
    "VAT item burden - Scenario 2: CEI × milieu (Bachas et al. 2024)"


********************************************************************************
* STEP 3 — SCENARIO 3: CEI × decile (Informality Engel Curve calibrated)
*
* EMPIRICAL BASIS:
* Bachas, Gadenne & Jensen (2024) estimate that in lower-middle income
* countries, the IEC slope (reduction in informal budget share per log-
* doubling of expenditure) ranges from -5 to -8 percentage points.
*
* We translate this into a linear approximation across deciles:
*   alpha(coicop, d) = alpha_D1(coicop) + (d-1) × slope(coicop)
*
* Where:
*   alpha_D1 = effective alpha for the poorest decile
*   slope    = increment per decile (derived from IEC slope)
*   d        = decile rank (1 to 10)
*
* The slope is STEEPER for categories with high IEC sensitivity:
*   - food/bev, restaurants, personal care: steepest slopes
*   - housing/utilities, insurance, telecom: flattest slopes
*
* Calibration note: alphas are capped at 1.
* This scenario DIRECTLY models the core mechanism of Bachas et al.:
* even within the same COICOP category, poor households buy informally
* more than rich households, implying a lower effective alpha at the bottom.
*
* NOTE: decile must be computed BEFORE this step (done in Step 8 of
* the original code; here we require it to already exist).
* If running standalone, compute: xtile decile = conso_w [pw=hhweight], n(10)
********************************************************************************
bys hhid: egen conso_w = total(depan_w)
xtile decile = conso_w [pw=hhweight], n(10)

label define dec_lbl 1 "D1 poorest" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 richest", replace

label values decile dec_lbl
label variable decile ///
"Decile of baseline welfare (winsorized total consumption)"


gen alpha_3 = .

* ── food/bev (coicop 1) ──────────────────────────────────────────────────────
* alpha_D1 = 0.12 | slope = 0.034
* → D1: 0.12, D5: 0.25, D10: 0.42
* Rationale: steepest IEC in Bachas et al. for low-income countries.
* Bottom decile buys almost entirely at traditional markets.
replace alpha_3 = 0.12 + (decile - 1) * 0.034 if coicop == 1

* ── alcohol/tobacco (coicop 2) ───────────────────────────────────────────────
* alpha_D1 = 0.48 | slope = 0.024
* More formal chain; flatter IEC.
replace alpha_3 = 0.48 + (decile - 1) * 0.024 if coicop == 2

* ── clothing/footwear (coicop 3) ─────────────────────────────────────────────
* alpha_D1 = 0.22 | slope = 0.030
* → D1: 0.22, D5: 0.34, D10: 0.49
replace alpha_3 = 0.22 + (decile - 1) * 0.030 if coicop == 3

* ── housing/utilities (coicop 4) ─────────────────────────────────────────────
* alpha_D1 = 0.62 | slope = 0.022
* Flattest profile: utilities are formal regardless of income level.
replace alpha_3 = 0.62 + (decile - 1) * 0.022 if coicop == 4

* ── furnishings/equipment (coicop 5) ─────────────────────────────────────────
* alpha_D1 = 0.22 | slope = 0.028
replace alpha_3 = 0.22 + (decile - 1) * 0.028 if coicop == 5

* ── health (coicop 6) ────────────────────────────────────────────────────────
* alpha_D1 = 0.30 | slope = 0.040
* Steep slope: rich households use private clinics (formal);
* poor households use traditional/informal care.
replace alpha_3 = 0.30 + (decile - 1) * 0.040 if coicop == 6

* ── transport (coicop 7) ─────────────────────────────────────────────────────
* alpha_D1 = 0.25 | slope = 0.038
* Poor: informal taxis, motorbikes. Rich: formal taxis, cars, air travel.
replace alpha_3 = 0.25 + (decile - 1) * 0.038 if coicop == 7

* ── info/comm (coicop 8) ─────────────────────────────────────────────────────
* alpha_D1 = 0.78 | slope = 0.015
* Very flat: telecom is formal at all income levels (licensed operators).
replace alpha_3 = 0.78 + (decile - 1) * 0.015 if coicop == 8

* ── recreation (coicop 9) ────────────────────────────────────────────────────
* alpha_D1 = 0.28 | slope = 0.032
replace alpha_3 = 0.28 + (decile - 1) * 0.032 if coicop == 9

* ── education (coicop 10) ────────────────────────────────────────────────────
* alpha_D1 = 0.55 | slope = 0.025
* Formal schools are used more by richer households; poor rely more on
* informal/unregistered schools or self-teaching.
replace alpha_3 = 0.55 + (decile - 1) * 0.025 if coicop == 10

* ── restaurants (coicop 11) ──────────────────────────────────────────────────
* alpha_D1 = 0.12 | slope = 0.038
* → D1: 0.12, D5: 0.27, D10: 0.46
* Same empirical profile as food/bev. Strong IEC.
replace alpha_3 = 0.12 + (decile - 1) * 0.038 if coicop == 11

* ── insurance (coicop 12) ────────────────────────────────────────────────────
* alpha_D1 = 0.85 | slope = 0.010
* Almost entirely formal at all deciles.
replace alpha_3 = 0.85 + (decile - 1) * 0.010 if coicop == 12

* ── personal care (coicop 13) ────────────────────────────────────────────────
* alpha_D1 = 0.15 | slope = 0.034
* → D1: 0.15, D5: 0.29, D10: 0.46
* Strong IEC: salons are overwhelmingly informal for low-income households;
* richer households use formal beauty salons with receipts.
replace alpha_3 = 0.15 + (decile - 1) * 0.034 if coicop == 13

* ── not included / not consumption ──────────────────────────────────────────
replace alpha_3 = 0    if coicop == 98
replace alpha_3 = 0    if coicop == 99

* Cap at 1 (theoretical maximum)
replace alpha_3 = min(alpha_3, 1)

* Verify no missing alpha for taxable items
assert !missing(alpha_3) if r_vat_official > 0

gen vat_item_s3 = alpha_3 * vat_item_strict
label variable vat_item_s3 ///
    "VAT item burden - Scenario 3: CEI × decile (IEC calibrated, Bachas 2024)"


********************************************************************************
* STEP 4 — Diagnostic: mean alpha by COICOP × scenario
* Verify that Scenario 3 produces a meaningful gradient across deciles
* and that Scenario 2 produces a meaningful urban/rural gap.
********************************************************************************

preserve
collapse (mean) alpha_2 alpha_3 [pw=hhweight], by(coicop decile)
export excel using "$TABLES/06/06_01_alpha_diagnostics_coicop_decile.xlsx", ///
    firstrow(variables) replace
restore

preserve
collapse (mean) alpha_2 [pw=hhweight], by(coicop milieu)
export excel using "$TABLES/06/06_01_alpha_diagnostics_coicop_milieu.xlsx", ///
    firstrow(variables) replace
restore


********************************************************************************
* STEP 5 — Aggregation to household level
********************************************************************************

sort hhid

foreach s in strict s2 s3 {
    by hhid: egen vat_`s' = total(vat_item_`s')
    label variable vat_`s' "Total VAT paid - scenario `s'"
}




********************************************************************************
* STEP 6 — Effective VAT rates
********************************************************************************

foreach s in strict s2 s3 {
    gen eff_vat_`s' = vat_`s' / conso_w
    label variable eff_vat_`s' "Effective VAT rate - scenario `s'"
}

save "$OUTPUT/final_data/06/fiscal_sensitivity_taxation.dta", replace

********************************************************************************
* STEP 7 — Effective VAT rates by decile
*
* KEY DIAGNOSTIC TABLE.
* If Scenario 3 (CEI × decile) produces a RISING profile of effective VAT
* rates, this confirms that accounting for informal consumption makes the
* tax progressive — consistent with Bachas et al. (2024).
* If the profile remains flat or declining, regressivity is robust.
********************************************************************************

preserve
collapse (mean) eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [pw=hhweight], by(decile)

* Rename for clarity in output
rename eff_vat_strict rate_strict
rename eff_vat_s2     rate_s2_milieu
rename eff_vat_s3     rate_s3_iec

export excel using "$TABLES/06/06_01_decile_effective_rates_by_scenario.xlsx", ///
    firstrow(variables) replace
restore


********************************************************************************
* STEP 8 — CEQ-style indices: Gini, Concentration Index, Kakwani,
*           Reynolds-Smolensky
*
* INTERPRETATION GUIDE:
*
* Kakwani index = CI(VAT) - Gini(pre-tax income)
*   > 0 : progressive (richer households bear proportionally more VAT)
*   < 0 : regressive (poorer households bear proportionally more VAT)
*   = 0 : proportional
*
* Reynolds-Smolensky = Gini_after - Gini_before
*   > 0 : tax INCREASES inequality (regressive + large enough)
*   < 0 : tax REDUCES inequality (progressive)
*
* ROBUSTNESS TEST LOGIC (Bachas et al. 2024 framework):
*   Scenario 1 (strict): distributional benchmark
*   Scenario 2 (CEI × milieu): does urban/rural informality gradient
*     change the sign of Kakwani?
*   Scenario 3 (CEI × decile): does the full IEC structure change
*     the sign of Kakwani?
*
* If Kakwani < 0 in ALL three scenarios → regressivity is robust.
* If sign changes in Scenario 3 → conclusion is sensitive to IEC
*   assumption; must be discussed carefully.
********************************************************************************
* Install packages if needed
capture which ineqdeco
if _rc ssc install ineqdeco

capture which conindex
if _rc ssc install conindex

* Define income
gen market_income = conso_w

foreach s in strict s2 s3 {
    gen consumable_`s' = market_income - vat_`s'
}

* Collapse to household level
preserve
bysort hhid: keep if _n == 1

* Pre-tax Gini
quietly ineqdeco market_income [aw=hhweight]
scalar G_market = r(gini)

* Postfile
postfile ceq_handle str30 scenario str80 description ///
    double g_market g_after c_vat kakwani rs ///
    using "$OUTPUT/final_data/06/06_01_ceq_summary_scenarios.dta", replace

* ── Scenario 1: strict ─────────────────────────────
quietly ineqdeco consumable_strict [aw=hhweight]
scalar G_after = r(gini)

quietly conindex vat_strict [pw=hhweight], rankvar(market_income) truezero
scalar C_vat   = r(CI)

scalar Kakwani = C_vat - G_market
scalar RS      = G_after - G_market

post ceq_handle ("strict") ///
    ("Alpha=1, full taxation") ///
    (G_market) (G_after) (C_vat) (Kakwani) (RS)

* ── Scenario 2: CEI × milieu ───────────────────────
quietly ineqdeco consumable_s2 [aw=hhweight]
scalar G_after = r(gini)

quietly conindex vat_s2 [pw=hhweight], rankvar(market_income) truezero
scalar C_vat   = r(CI)

scalar Kakwani = C_vat - G_market
scalar RS      = G_after - G_market

post ceq_handle ("s2_milieu") ///
    ("CEI x milieu (Bachas 2024 + WB WPS10703)") ///
    (G_market) (G_after) (C_vat) (Kakwani) (RS)

* ── Scenario 3: CEI × decile ───────────────────────
quietly ineqdeco consumable_s3 [aw=hhweight]
scalar G_after = r(gini)

quietly conindex vat_s3 [pw=hhweight], rankvar(market_income) truezero
scalar C_vat   = r(CI)

scalar Kakwani = C_vat - G_market
scalar RS      = G_after - G_market

post ceq_handle ("s3_iec_decile") ///
    ("CEI x decile, IEC calibree (Bachas 2024)") ///
    (G_market) (G_after) (C_vat) (Kakwani) (RS)

postclose ceq_handle

restore

********************************************************************************
* STEP 9 — Bootstrap confidence intervals on Kakwani
*
* OBJECTIVE:
* Test whether Kakwani indices are statistically distinguishable from zero
* and from each other across scenarios.
* Standard errors on conindex are not reported by default; bootstrap
* provides honest uncertainty quantification.
*
* 500 replications = standard for distributional indices in fiscal
* incidence analysis (Lustig 2018, CEQ Handbook).
********************************************************************************


********************************************************************************
* STEP 10 — Bootstrap manuel Kakwani 
********************************************************************************

bysort hhid: keep if _n == 1
set seed 20240901
local reps = 500

tempname bs_results
postfile `bs_results' ///
    double kak_strict kak_s2 kak_s3 ///
    using "$OUTPUT/final_data/06/bs_kakwani_raw.dta", replace

forvalues i = 1/`reps' {

    preserve

    * Bootstrap standard 
    bsample

    quietly ineqdeco market_income [aw=hhweight]
    local G = r(gini)

    quietly conindex vat_strict [aw=hhweight], ///
        rankvar(market_income) truezero
    local k1 = r(CI) - `G'

    quietly conindex vat_s2 [aw=hhweight], ///
        rankvar(market_income) truezero
    local k2 = r(CI) - `G'

    quietly conindex vat_s3 [aw=hhweight], ///
        rankvar(market_income) truezero
    local k3 = r(CI) - `G'

    post `bs_results' (`k1') (`k2') (`k3')

    restore
}

postclose `bs_results'

********************************************************************************
* IC bootstrap percentile
********************************************************************************

use "$OUTPUT/final_data/06/bs_kakwani_raw.dta", clear

foreach k in kak_strict kak_s2 kak_s3 {

    quietly summarize `k'
    local mean_k = r(mean)

    centile `k', centile(2.5 97.5)
    local lo = r(c_1)
    local hi = r(c_2)

    di as text "-----------------------------------------"
    di as result "Kakwani [`k']"
    di as text "Mean   = " %6.4f `mean_k'
    di as text "IC95%  = [" %6.4f `lo' " ; " %6.4f `hi' "]"
}

export excel using "$TABLES/06/06_01_bootstrap_kakwani.xlsx", ///
    firstrow(variables) replace


********************************************************************************
* STEP 11 — Finalize and annotate CEQ results
********************************************************************************

use "$OUTPUT/final_data/06/06_01_ceq_summary_scenarios.dta", clear

* Sign
gen progressive = (kakwani > 0)
gen regressive  = (kakwani < 0)

* Robust classification
egen min_kak = min(kakwani)
egen max_kak = max(kakwani)

gen robust_regressive  = (max_kak < 0)
gen robust_progressive = (min_kak > 0)
gen sign_unstable      = (min_kak < 0) & (max_kak > 0)

* Delta vs strict (robuste)
egen kak_strict = mean(kakwani) if scenario == "strict"
egen kak_strict_all = max(kak_strict)

gen delta_kakwani_vs_strict = kakwani - kak_strict_all

* Labels
label variable progressive "1 = Kakwani > 0 (progressive)"
label variable regressive  "1 = Kakwani < 0 (regressive)"
label variable robust_regressive "1 = regressive in all scenarios"
label variable robust_progressive "1 = progressive in all scenarios"
label variable sign_unstable "1 = sign changes across scenarios"
label variable delta_kakwani_vs_strict ///
    "Change in Kakwani relative to strict scenario"

export excel using "$TABLES/06/06_01_ceq_summary_scenarios.xlsx", ///
    firstrow(variables) replace

save "$OUTPUT/final_data/06/06_01_ceq_summary_scenarios.dta", replace


********************************************************************************
* END
********************************************************************************
