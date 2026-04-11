********************************************************************************
* 02_mapping_tax_clean.do
*
* OBJECTIVE:
* Build a clean and auditable VAT mapping by product code (codpr),
* starting from:
*   (1) an official Excel mapping imported from the CGI 2026 VAT table
*
* FINAL OUTPUT:
* A final product-level VAT mapping file ready to merge with consumption data.
*
* CORE PRINCIPLES:
* - codpr and "produit" is the merge keys
*
* ECONOMIC INTERPRETATION:
* - r_vat_official: final VAT rate used in analysis
* - hors_champ: product outside VAT scope in the original official mapping
*
* NOTES:
* - VAT rates are stored as proportions: 0, 0.09, 0.18
* - manual VAT entered in Excel is assumed to be in percentage points: 0, 9, 18
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

clear all
set more off

********************************************************************************
* STEP 1 — Import official Excel VAT mapping
********************************************************************************
* Expected Excel file contains at least:
*  code, produit,mode d'acquisition, ...


import excel "$DATA\COPR_EHCVM_TVA_renseigne.xlsx", sheet("TVA_detail") firstrow clear

********************************************************************************
* STEP 2 — Handle "Hors champ"
********************************************************************************
* "Hors champ" means outside the VAT scope.
* We preserve this information with an indicator, but set the raw rate to 0
* so it can be converted numerically.

gen hors_champ = (trim(TVA_statutaire) == "Hors champ")

replace hors_champ = 1 if mode != "Achat"
replace TVA_statutaire = "9999" if trim(TVA_statutaire) == "Hors champ"

********************************************************************************
* STEP 3 — Clean raw VAT rate string
********************************************************************************
* Remove %, *, spaces, then convert to numeric.


* Remove %, *, spaces, then convert to numeric.

replace TVA_statutaire = subinstr(TVA_statutaire, "%", "", .)
replace TVA_statutaire = subinstr(TVA_statutaire, "*", "", .)
replace TVA_statutaire = trim(TVA_statutaire)

destring TVA_statutaire, replace force
ta TVA_statutaire
* Convert from percent to proportion
gen r_vat_official = TVA_statutaire / 100

drop TVA_statutaire

********************************************************************************
* STEP 4 — Validate imported official VAT rates
********************************************************************************

di as text ">>> Summary of official VAT rates"
sum r_vat_official

di as text ">>> Distribution of official VAT rates"
tab r_vat_official

di as text ">>> Distribution of hors_champ indicator"
tab hors_champ


********************************************************************************
* STEP 5 — Check uniqueness of codpr in official mapping
********************************************************************************
* Each codpr should map to one unique official VAT profile.

duplicates report code produit

********************************************************************************
* STEP 6 — Keep only relevant variables from official mapping
********************************************************************************

keep code produit hors_champ r_vat_official

* Add explicit source
gen source = "official"

sort code produit
save "$SILVER/02/mapping_fiscal_official.dta", replace

di as result ">>> Official VAT mapping cleaned and saved"


********************************************************************************
* STEP 7 — Merge final mapping into consumption data
********************************************************************************
* This is the final operational merge used for incidence analysis.

use "$SILVER/01/conso_clean.dta", clear
gen code = codpr
decode codpr, gen(produit)
drop codpr 
order code produit
sort code produit
merge m:1  code produit using "$SILVER/02/mapping_fiscal_official.dta"

di as text ">>> Final merge results"
tab _merge

tab hors_champ if _merge==2 // Therefore, those who did not find a match are the ones who are out of scope.

* Strong expectation:
* - _merge==1 should be 0
* - _merge==3 should cover all consumption observations
* - _merge==2 can exist and is harmless for final analysis


********************************************************************************
* STEP 8 — Diagnostics after merge
********************************************************************************

* Products in consumption still missing from mapping (should be zero)
count if _merge == 1
br code r_vat_official produit if _merge == 1

* Products in mapping not observed in conso (not a problem)
count if _merge == 2
br code r_vat_official produit if _merge == 2

list code produit if _merge == 2


********************************************************************************
* STEP 9 — keep only relevant observations for analysis
********************************************************************************
keep if _merge == 3
drop _merge
keep if  hors_champ ==0

********************************************************************************
* STEP 10 — LABELING DATASET
********************************************************************************

*-------------------------------
* 1. LABEL VARIABLES 
*-------------------------------

label variable country        "Country code"
label variable year           "Survey year"
label variable hhid           "Household unique identifier"
label variable vague          "Survey wave"
label variable grappe         "Sampling cluster"
label variable menage         "Household number within cluster"

label variable region         "Region of residence"
label variable milieu         "Area of residence (urban/rural)"

label variable hhweight       "Household sampling weight"

label variable code          "Product code (EHCVM nomenclature)"
label variable produit        "Product / Service label"

label variable inclus         "Included in final consumption aggregate"
label variable coicop         "COICOP classification"
label variable modep          "Mode of acquisition"

label variable depan          "Annual consumption expenditure (CFA)"
label variable log_depan      "Log of annual consumption expenditure"
label variable depan_w        "Winsorized consumption expenditure"

* VAT / fiscal variables
label variable hors_champ     "Out of VAT scope (1=yes, 0=no)"
label variable r_vat_official "Official VAT rate (CGI 2026)"
label variable source         "Source of VAT assignment (official)"

*-------------------------------
* 1. LABEL VALUES 
*-------------------------------
* Inclus
label define inclus_lbl 0 "No" 1 "Yes"
label values inclus inclus_lbl


/*
* final VAT
gen vat_cat = round(r_vat_final*100)

replace vat_cat = 0  if vat_cat==0
replace vat_cat = 9  if vat_cat==9
replace vat_cat = 18 if vat_cat==18

label define vat_cat_lbl 0 "Exempt (0%)" 1"Reduced(9%)" 2"Standard (18%)"

label values vat_cat vat_cat_lbl
label variable vat_cat "VAT category"
*/


*format r_vat_official %9.2f
*format depan %15.0fc
*format depan_w %15.0fc


********************************************************************************
* STEP 11 — Saving
********************************************************************************


save "$SILVER/01/conso_clean", replace
di as result ">>> Dataset labeled and ready for analysis"


********************************************************************************
* END
********************************************************************************

