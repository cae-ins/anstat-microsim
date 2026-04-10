********************************************************************************
* 01_prepare_data.do
*
* OBJECTIVE:
* Construct a clean, consistent, and economically meaningful expenditure dataset
* for VAT incidence analysis based on EHCVM (Harmonised Survey on Household
* Living Conditions) data.
*
* DATA STRUCTURE:
* - Unit of observation: household × product × acquisition method
* - Approximately 60 observations per household
* - Around 422 distinct consumption items
*
* KEY VARIABLES:
* - depan   : annual expenditure per item
* - modep   : mode of acquisition (purchase, own-consumption, gift, imputation)
* - inclus  : indicator for inclusion in the official final consumption aggregate
* - hhid    : household identifier
*
* METHODOLOGICAL APPROACH:
*
* 1. Data validation and cleaning
*    - Inspect the distribution of expenditures
*    - Identify invalid or implausible values
*
* 2. Distinguish official consumption from VAT-relevant expenditure :
*    - The official final consumption aggregate includes both monetary and
*      non-monetary components, such as self-consumption and in-kind transfers.
*    - However, VAT applies only to market transactions.
*    - Therefore, VAT incidence analysis must distinguish:
*         (i) official household final consumption (through variable "inclus"),
*        (ii) market-based expenditure,
*
* 3. Restriction to market-based transactions
*    - Keep market acquisitions only (modep == 1) in order to approximate
*      the effective tax base observed in household expenditure data.
*    - Non-monetary components are excluded from the VAT base, including:
*         • own-consumption
*         • gifts received in kind
*         • imputed values (e.g. imputed rent, use value of durables)
*
* 4. Treatment of extreme values
*    - Apply winsorization at the 99th percentile (depan_w)
*    - Preserve both raw and winsorized versions for robustness analysis
*
* 5. Construction of household-level aggregates
*    - Aggregate expenditures from item-level to household-level
*    - Compute:
*         • total expenditure (conso)
*         • total winsorized expenditure (conso_w)
*         • number of items (n_items)
*
* 6. Final dataset
*    - One observation per household
*    - Includes expenditure aggregates and household characteristics
*    - Log-transformed variables generated for diagnostic and analytical purposes
*
* CEQ FRAMEWORK INTERPRETATION:
*
* - We move from:
*       observed household expenditure
*   to:
*       market-based expenditure relevant for indirect tax incidence
*
* - The final taxable base is not defined solely by survey accounting rules,
*   but by the combination of:
*       • observed expenditure,
*       • method acquisition,
*       • product-level fiscal classification.
*
* - The final dataset is consistent with a partial CEQ framework focusing on
*   indirect taxation (VAT incidence).
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************
set scheme s1color

di as text ">>> STEP 1: Loading raw consumption data"
use "$DATA/ehcvm_conso_civ2021.dta", clear

********************************************************************************
* STEP 1 — Inspect dataset structure
********************************************************************************

di as text ">>> Inspecting dataset structure"

describe
count

* Key identifiers must be present
assert !missing(hhid)
assert !missing(codpr)

********************************************************************************
* STEP 2 — Clean expenditure values
********************************************************************************

di as text ">>> Cleaning expenditure values (depan)"

* Inspect distribution (important for detecting outliers)
sum depan, detail
tabstat depan, ///
    stat(n mean sd p1 p5 p10 p25 p50 p75 p90 p95 p99 min max skewness kurtosis) ///
    save
matrix M = r(StatTotal)
preserve
clear
svmat M, names(col)
gen stat = ""

replace stat = "N"         in 1
replace stat = "Mean"      in 2
replace stat = "SD"        in 3
replace stat = "P1"        in 4
replace stat = "P5"        in 5
replace stat = "P10"       in 6
replace stat = "P25"       in 7
replace stat = "Median"    in 8
replace stat = "P75"       in 9
replace stat = "P90"       in 10
replace stat = "P95"       in 11
replace stat = "P99"       in 12
replace stat = "Min"       in 13
replace stat = "Max"       in 14
replace stat = "Skewness"  in 15
replace stat = "Kurtosis"  in 16
sort stat depan
export excel using "$TABLES/01/summary_depan_raw.xlsx", ///
    firstrow(variables) replace

restore
list if depan >= 25000000

********************************************************************************
* STEP 3 — Official consumption aggregate
********************************************************************************

di as text ">>> Diagnosing official consumption aggregate (SCN concept)"

* Variable 'inclus':
* =1 → included in official consumption aggregate (SCN concept)
* =0 → excluded (investment, special cases, classification issues)

tab inclus
sum depan if inclus == 1
sum depan if inclus == 0

* IMPORTANT:
* The variable 'inclus' follows national accounts logic (welfare measurement),
* but does not perfectly match the VAT tax base.
*
* Some excluded items (inclus == 0) may still correspond to taxable market
* transactions (e.g. durable goods, equipment, electronics).
*
* Therefore:
*  we do NOT drop inclus == 0 

********************************************************************************

********************************************************************************
* STEP 4 — Restrict to market-based consumption (VAT-relevant base)
********************************************************************************

di as text ">>> Restricting to market-based consumption (VAT-relevant)"

* Variable 'modep':
* 1 = Purchase (market transaction)
* 2 = Own-consumption
* 3 = Gift
* 4 = Use value (durables)
* 5 = Imputed rent

tab modep

* CEQ assumption:
* VAT applies only to market transactions

keep if modep == 1

sum depan, detail

* IMPORTANT:
* This restriction defines the core VAT-relevant base:
*
* Included:
* - monetary purchases of goods and services
*
* Excluded:
* - own-consumption (no market transaction)
* - gifts and transfers in kind
* - imputed rent
* - use value of durables (non-observed transactions)
*
* NOTE:
* Some remaining items may still be:
* - non-taxable (exempt)
* - out of scope (not subject to VAT)
*
* These will be handled later through VAT mapping (product-level classification)
********************************************************************************


********************************************************************************
* STEP 5 — Diagnostics after filtering
********************************************************************************

di as text ">>> Diagnostics after filtering"

count
sum depan, detail

/*The distribution of spending is highly unequal and dominated by a few high values. A "typical" household spends approximately 15,000 FCFA (median) per item (annualized).
Skewness = 57.19 & Kurtosis = 12818.75 extremely asymmetrical distribution with a high concentration of low observations and some extremely high values.

Conclusion : The majority of households consume little, while a minority make very high expenditures, reflecting both inequalities in living standards and the presence of significant one-off expenditures.
*/

* Check COICOP distribution
tab coicop

* Check regional structure
tab region

********************************************************************************
* STEP 6 — Handle extreme values (robustness)
********************************************************************************

di as text ">>> Handling extreme values"

* Motivation:
* Expenditure distribution is highly skewed (heavy tail),
* which may bias incidence results

gen log_depan = log(depan)
histogram depan
histogram log_depan
graph save "$FIGS/log_depan_af_cleaning.gph" , replace
graph export "$FIGS/log_depan_af_cleaning.png", replace

/*The distribution of household expenditures exhibits a log-normal pattern,
consistent with standard findings in the consumption literature.
*/

sum depan, detail
local p99 = r(p99)

gen depan_w = depan

* Winsorize at the 99th percentile
replace depan_w = `p99' if depan > `p99'

* NOTE:
* - 'depan'  = raw values
* - 'depan_w' = robust version

sum depan_w, detail
histogram depan_w


********************************************************************************
* STEP 7 — Save cleaned detailed dataset
********************************************************************************

di as text ">>> Saving cleaned consumption dataset"

save "$OUTPUT/final_data/01/conso_clean.dta", replace


********************************************************************************
* END
********************************************************************************
