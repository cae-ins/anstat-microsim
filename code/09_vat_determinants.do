********************************************************************************
* 09_determinants.do
*
* OBJECTIVE:
* Analyze the socio-demographic determinants of household exposure to VAT,
* coherently with the informality framework established in 06_01.
*
* ────────────────────────────────────────────────────────────────────────────
* ANALYTICAL RATIONALE
* ────────────────────────────────────────────────────────────────────────────
*
* The robustness analysis (06_01) showed that the distributional conclusion
* depends entirely on the effective VAT pass-through (alpha). The natural
* next question is:
*
*   "What household characteristics predict a lower effective alpha
*    — i.e., greater insulation from VAT through informal purchasing?"
*
* This reframes the analysis from "who pays more VAT?" (strict scenario,
* mechanically driven by consumption level) to "who is effectively shielded
* from VAT by informality?" — a more policy-relevant question.
*
* ────────────────────────────────────────────────────────────────────────────
* DEPENDENT VARIABLES
* ────────────────────────────────────────────────────────────────────────────
*
* Three dependent variables, one per scenario:
*
*   (1) eff_vat_strict : effective VAT rate under full taxation (alpha=1)
*        baseline, captures structural tax exposure
*
*   (2) eff_vat_s2 : effective VAT rate under CEI × milieu
*        captures urban/rural informality channel
*
*   (3) eff_vat_s3 : effective VAT rate under CEI × decile (IEC calibrated)
*        captures income-gradient informality channel
*
* Comparing coefficients across the three specifications tests whether
* determinants of tax exposure are robust to the informality assumption.
*
* ────────────────────────────────────────────────────────────────────────────
* KEY VARIABLES
* ────────────────────────────────────────────────────────────────────────────
*
* Independent variables of interest:
*   - lconso_w   : log total consumption (welfare proxy)
*   - milieu     : urban/rural (1=urbain, 2=rural)
*   - hhsize     : household size
*   - heduc      : education of household head
*   - hgender    : gender of household head
*   - region     : geographic region (fixed effects)
*   - n_items    : consumption diversification (number of items reported)
*
* NOTE ON n_items:
* n_items is retained as a proxy for consumption diversification but its
* interpretation requires caution: it is correlated with lconso_w
* (richer households report more items). VIF is checked systematically.
*
* ────────────────────────────────────────────────────────────────────────────
* ESTIMATION STRATEGY
* ────────────────────────────────────────────────────────────────────────────
*
* OLS with cluster-robust standard errors at the grappe (PSU) level.
* Survey weights (hhweight) throughout.
* Data collapsed to household level BEFORE regressions.
*
* Four nested models per dependent variable:
*   M1 : bivariate (lconso_w only)
*   M2 : + household demographics
*   M3 : + milieu + region fixed effects
*   M4 : M3 + n_items (diversification)
*
* Robustness: coefficients compared across three dependent variables.
* If coefficients stable across eff_vat_strict / s2 / s3 → robust.
* If coefficients change sign → informality assumption matters.
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

use "$OUTPUT/final_data/06/fiscal_sensitivity_taxation.dta", clear
by hhid: egen n_items = count(produit)
by hhid: gen hh_tag = (_n == 1)
keep if hh_tag == 1
drop hh_tag
sort hhid
* Merge socio-demographic variables
merge 1:1 hhid using "$DATA/ehcvm_welfare_civ2021", ///
    keepusing(hhsize hgender hage heduc  halfa2 grappe region) ///
    keep(3) nogen

********************************************************************************
* STEP 0 — Validation
********************************************************************************

assert !missing(hhid, hhweight, conso_w)
assert !missing(eff_vat_strict, eff_vat_s2, eff_vat_s3)
assert !missing(milieu, region, hhsize)

* Confirm household-level data 
duplicates report hhid

********************************************************************************
* STEP 1 — Variable construction
********************************************************************************

* Log consumption
gen lconso_w = log(conso_w)
label variable lconso_w "Log total consumption (winsorized)"

* Household head education — binary: secondary or above
gen educ_high = (heduc >= 4) if !missing(heduc)
label variable educ_high "Head has secondary education or above"
label define educ_lbl 0 "Primary or less" 1 "Secondary or above"
label values educ_high educ_lbl

* Gender of head
gen head_female = (hgender == 2) if !missing(hgender)
label variable head_female "Female-headed household"

* Household size categories
gen hhsize_cat = .
replace hhsize_cat = 1 if hhsize <= 2
replace hhsize_cat = 2 if hhsize >= 3 & hhsize <= 5
replace hhsize_cat = 3 if hhsize >= 6 & hhsize <= 9
replace hhsize_cat = 4 if hhsize >= 10
label define hhs_lbl 1 "1-2 persons" 2 "3-5 persons" ///
    3 "6-9 persons" 4 "10+ persons"
label values hhsize_cat hhs_lbl
label variable hhsize_cat "Household size category"

* Urban dummy
gen urban = (milieu == 1) if !missing(milieu)
label variable urban "Urban household (milieu=1)"
label define urb_lbl 0 "Rural" 1 "Urban"
label values urban urb_lbl

********************************************************************************
* STEP 2 — Descriptive statistics
********************************************************************************

* Check collinearity between n_items and lconso_w
corr n_items lconso_w
di "Correlation n_items / lconso_w = " r(rho)

* Summary of dependent variables
sum eff_vat_strict eff_vat_s2 eff_vat_s3, detail

* Mean effective rates by milieu
tabstat eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [aw=hhweight], by(milieu) stat(mean sd) nototal

* Mean effective rates by education
tabstat eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [aw=hhweight], by(educ_high) stat(mean sd) nototal

********************************************************************************
* STEP 3 — Baseline regressions: effective VAT rate (strict)
*
* PURPOSE:
* Establishes the structural determinants of tax exposure under
* full taxation. Reference point for comparison with S2 and S3.
********************************************************************************

di as result "══════════════════════════════════════════════════"
di as result "  PANEL A — Dependent variable: eff_vat_strict"
di as result "══════════════════════════════════════════════════"

* M1 : bivariate — income gradient only
eststo m1_strict: reg eff_vat_strict ///
    lconso_w ///
    [pw=hhweight], vce(cluster grappe)

* M2 : + household demographics
eststo m2_strict: reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high ///
    [pw=hhweight], vce(cluster grappe)

* M3 : + milieu + region FE
eststo m3_strict: reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

* M4 : + diversification
eststo m4_strict: reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high ///
    urban i.region n_items ///
    [pw=hhweight], vce(cluster grappe)

* VIF check on M4
quietly reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high urban n_items ///
    [pw=hhweight]
estat vif
* Rule of thumb: VIF > 10 signals problematic collinearity

********************************************************************************
* STEP 4 — Regressions: effective VAT rate (S2 — CEI × milieu)
*
* PURPOSE:
* Tests whether the same determinants hold when urban/rural informality
* is incorporated. Key question: does the urban coefficient change sign
* or magnitude relative to strict?
* If urban coefficient increases → urban premium in formality confirmed.
********************************************************************************

di as result "══════════════════════════════════════════════════"
di as result "  PANEL B — Dependent variable: eff_vat_s2"
di as result "══════════════════════════════════════════════════"

eststo m1_s2: reg eff_vat_s2 ///
    lconso_w ///
    [pw=hhweight], vce(cluster grappe)

eststo m2_s2: reg eff_vat_s2 ///
    lconso_w hhsize head_female educ_high ///
    [pw=hhweight], vce(cluster grappe)

eststo m3_s2: reg eff_vat_s2 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

eststo m4_s2: reg eff_vat_s2 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region n_items ///
    [pw=hhweight], vce(cluster grappe)

********************************************************************************
* STEP 5 — Regressions: effective VAT rate (S3 — CEI × décile)
*
* PURPOSE:
* Tests determinants under the IEC-calibrated scenario.
* Key question: does the income gradient (lconso_w coefficient) increase
* relative to strict and S2?
* If yes → richer households face a disproportionately higher effective
* rate through formal purchasing, independently of demographics.
********************************************************************************

di as result "══════════════════════════════════════════════════"
di as result "  PANEL C — Dependent variable: eff_vat_s3"
di as result "══════════════════════════════════════════════════"

eststo m1_s3: reg eff_vat_s3 ///
    lconso_w ///
    [pw=hhweight], vce(cluster grappe)

eststo m2_s3: reg eff_vat_s3 ///
    lconso_w hhsize head_female educ_high ///
    [pw=hhweight], vce(cluster grappe)

eststo m3_s3: reg eff_vat_s3 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

eststo m4_s3: reg eff_vat_s3 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region n_items ///
    [pw=hhweight], vce(cluster grappe)

********************************************************************************
* STEP 6 — Export regression tables
*
* Three panels exported: strict, s2, s3
* Each panel: M1 to M4
* Coefficients comparable across panels to assess informality sensitivity
********************************************************************************

capture which esttab
if _rc ssc install estout

* Panel A — strict
esttab m1_strict m2_strict m3_strict m4_strict ///
    using "$TABLES/09_reg_panel_strict.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    order(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    title("Panel A: Determinants of eff_vat_strict") ///
    mtitles("M1" "M2" "M3" "M4") ///
    note("Cluster-robust SE at grappe level. Survey weights.")

* Panel B — s2
esttab m1_s2 m2_s2 m3_s2 m4_s2 ///
    using "$TABLES/09/09_reg_panel_s2.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    order(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    title("Panel B: Determinants of eff_vat_s2 (CEI x milieu)") ///
    mtitles("M1" "M2" "M3" "M4") ///
    note("Cluster-robust SE at grappe level. Survey weights.")

* Panel C — s3
esttab m1_s3 m2_s3 m3_s3 m4_s3 ///
    using "$TABLES/09/09_reg_panel_s3.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    order(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    title("Panel C: Determinants of eff_vat_s3 (CEI x decile)") ///
    mtitles("M1" "M2" "M3" "M4") ///
    note("Cluster-robust SE at grappe level. Survey weights.")

* comparative table : 
esttab m3_strict m3_s2 m3_s3 ///
    using "$TABLES/09/09_reg_comparison_M3.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban _cons) ///
    order(lconso_w hhsize head_female educ_high urban _cons) ///
    title("Comparison M3: strict vs S2 vs S3") ///
    mtitles("Strict" "S2 milieu" "S3 IEC") ///
    note("KEY TABLE: coefficient stability across informality scenarios.")

********************************************************************************
* STEP 7 — Marginal effects: income gradient by milieu
*
* PURPOSE:
* Tests whether the income gradient in eff_vat_s3 differs between
* urban and rural households. If the gradient is steeper in urban areas,
* this suggests that richer urban households are more exposed to formal
* VAT than richer rural households — consistent with the IEC framework.
********************************************************************************

* Interaction model: income × milieu
reg eff_vat_s3 ///
    c.lconso_w##urban hhsize head_female educ_high ///
    i.region ///
    [pw=hhweight], vce(cluster grappe)

* Marginal effect of lconso_w at each milieu
margins urban, dydx(lconso_w)

* Predictive margins: eff_vat_s3 at lconso_w × milieu grid
margins urban, at(lconso_w=(11(0.5)15))

marginsplot, ///
    title("Predicted effective VAT rate by income and milieu", ///
        size(medium)) ///
    subtitle("Scenario 3 (CEI x decile) — Côte d'Ivoire EHCVM 2021", ///
        size(small)) ///
    ytitle("Predicted eff. VAT rate (S3)", size(small)) ///
    xtitle("Log total consumption", size(small)) ///
    legend(order(1 "Rural" 2 "Urban") position(6) rows(1)) ///
    note("Cluster-robust SE. Survey weights. Region FE included.", ///
        size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig6_margins_income_milieu.png", ///
    replace width(2400) height(1600)

********************************************************************************
* STEP 8 — Robustness check: non-linear income effect
*
* PURPOSE:
* Tests whether the income gradient in eff_vat_s3 is truly linear or
* whether there is a concave/convex pattern (diminishing returns to
* formality at high income levels).
*
* Formal test: H0: coefficient on lconso_w^2 = 0
* If rejected → non-linear form justified
* If not rejected → linear form preferred (parsimony)
********************************************************************************

gen lconso_w2 = lconso_w^2
label variable lconso_w2 "Square of log consumption (non-linearity test)"

reg eff_vat_s3 ///
    lconso_w lconso_w2 hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

* Formal test of non-linearity
test lconso_w2
di "F = " r(F) "  p = " r(p)
if r(p) < 0.10 {
    di "H0 rejetée → forme NON-LINÉAIRE justifiée, conserver lconso_w2"
}

reg eff_vat_s3 lconso_w lconso_w2 hhsize head_female educ_high ///
    urban i.region [pw=hhweight], vce(cluster grappe)

lincom lconso_w
lincom lconso_w2

********************************************************************************
* END
********************************************************************************
