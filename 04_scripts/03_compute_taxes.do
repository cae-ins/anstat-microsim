********************************************************************************
* 03_compute_taxes.do
*
* OBJECTIVE:
* Compute household-level VAT incidence using microdata from EHCVM.
*
* APPROACH:
* The script applies product-level VAT rates to observed consumption in order
* to estimate the tax burden borne by each household. The process follows a
* standard microsimulation approach consistent with CEQ methodology.
*
* KEY STEPS:
* 1. Compute VAT at the product level (consumption × VAT rate).
* 2. Aggregate consumption and VAT to the household level.
* 3. Derive effective VAT rates (VAT / total consumption).
**
* ECONOMIC INTERPRETATION:
* - VAT is assumed to be fully shifted to consumers (static incidence).
* - Effective VAT rate measures the share of consumption captured by VAT.
* - Results can be used to assess the regressivity or progressivity of VAT.
*
* DATA STRUCTURE:
* - Unit of observation (input): household × product
* - Unit of observation (output): household
*
* IMPORTANT ASSUMPTIONS:
* - Only market transactions are included (modep == 1 applied).
* - VAT rates are correctly assigned through the mapping file.

*
* OUTPUT:
* Household-level dataset including:
* - total consumption (raw and winsorized)
* - total VAT paid
* - effective VAT rate
* - CEQ proxy income concepts
*
* AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

********************************************************************************
* 03_compute_taxes.do
********************************************************************************

use "$SILVER/01/conso_clean.dta", clear


********************************************************************************
* STEP 1 — Compute VAT at item level
********************************************************************************

gen vat_item   = depan   * r_vat_official
label variable vat_item "VAT paid at item level (raw consumption)"
gen vat_item_w = depan_w * r_vat_official
label variable vat_item_w "VAT paid at item level (winsorized consumption)"

********************************************************************************
* STEP 2 — Aggregate to household level
********************************************************************************

di as text ">>> Aggregating to household level"

sort hhid

* Total consumption
by hhid: egen conso   = total(depan)
label variable conso "Total household consumption (raw)"
by hhid: egen conso_w = total(depan_w)
label variable conso_w "Total household consumption (winsorized)"
* Total VAT
by hhid: egen vat   = total(vat_item)
label variable vat "Total VAT paid by household (raw)"
by hhid: egen vat_w = total(vat_item_w)
label variable vat_w "Total VAT paid by household (winsorized)"
* Number of items
by hhid: egen n_items = count(produit)
label variable n_items "Number of consumption items reported by household"
sum n_items, detail
histogram n_items
graph save "$FIGS/n_items.gph" , replace
graph export "$FIGS/n_items.png", replace

********************************************************************************
* STEP 3 — Effective VAT rate
********************************************************************************

gen eff_vat   = vat   / conso
label variable eff_vat "Effective VAT rate (VAT / consumption, raw)"
gen eff_vat_w = vat_w / conso_w
label variable eff_vat_w "Effective VAT rate (VAT / consumption, winsorized)"

********************************************************************************
* STEP 4 — Reduce to one observation per household
********************************************************************************

by hhid: gen hh_tag = (_n == 1)
keep if hh_tag == 1
drop hh_tag

********************************************************************************
* STEP 5 — Log variables
********************************************************************************

gen lconso   = log(conso)
label variable lconso "log of household consumption (raw)"

gen lconso_w = log(conso_w)
label variable lconso_w "log of household consumption (winsorized)"

histogram lconso, normal
graph save "$FIGS/log_conso.gph" , replace
graph export "$FIGS/log_conso.png", replace
histogram lconso_w, normal
graph save "$FIGS/log_conso_w.gph" , replace
graph export "$FIGS/log_conso_w.png", replace

********************************************************************************
* STEP 6 — CEQ proxy concepts
********************************************************************************
gen market_income     = conso_w
label variable market_income "Market income proxy (winsorized consumption)"

gen consumable_income = conso_w - vat_w
label variable consumable_income "Consumable income (winsorized, net of VAT)"

********************************************************************************
* STEP 7 — Diagnostics
********************************************************************************

sum conso_w vat_w eff_vat_w, detail



********************************************************************************
* STEP 8 — Keep only household-level variables
********************************************************************************

keep ///
    hhid year ///
    hhweight ///
    region milieu ///
    conso conso_w ///
    vat vat_w ///
    eff_vat eff_vat_w ///
    n_items ///
    lconso lconso_w ///
    market_income consumable_income

order hhid conso vat eff_vat hhweight

sum conso, detail
sum conso_w, detail
/*
Household-level consumption exhibits moderate right-skewness,
with a median of approximately 1.4 million FCFA (conso) and a mean of 1.8 million FCFA.
The upper tail remains present but controlled, with the top 1% reaching 6 million FCFA.
Compared to item-level distributions, aggregation at the household level significantly reduces
extreme variability, resulting in a more stable and interpretable distribution.*/

********************************************************************************
* STEP 9 — Save final dataset
********************************************************************************

save "$SILVER/03/fiscal_data.dta", replace

des, full




