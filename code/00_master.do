********************************************************************************
* 00_master.do
* Master script — run the full pipeline
*
* This script must be run from the project root directory.
* It executes all steps in sequence:
*   1. Setup environment
*   2. Prepare raw data
*   3. Apply fiscal mapping
*   4. Compute taxes and CEQ variables
*   5. Run analysis and export outputs
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************

clear all
set more off

********************************************************************************
* STEP 0 — Setup environment
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 0: Setting up environment"
di as text "--------------------------------------------------"

* Run this script from the project root directory.
* 00_setup.do will exit with an error if the working directory is incorrect.
do "code/00_setup.do"

********************************************************************************
* STEP 1 — Data preparation
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 1: Preparing data"
di as text "--------------------------------------------------"

capture noisily do "$CODE/01_prepare_data.do"
if _rc != 0 {
    di as error "❌ ERROR in 01_prepare_data.do"
    exit 1
}

********************************************************************************
* STEP 2 — Fiscal mapping
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 2: Applying fiscal mapping"
di as text "--------------------------------------------------"

capture noisily do "$CODE/02_mapping_tax.do"
if _rc != 0 {
    di as error "❌ ERROR in 02_mapping_tax.do"
    exit 1
}

********************************************************************************
* STEP 3 — Compute taxes 
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 3: Computing taxes"
di as text "--------------------------------------------------"

capture noisily do "$CODE/03_compute_taxes.do"
if _rc != 0 {
    di as error "❌ ERROR in 03_compute_taxes.do"
    exit 1
}

********************************************************************************
* STEP 4 — Analysis
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 4: Running analysis"
di as text "--------------------------------------------------"

capture noisily do "$CODE/04_analysis.do"
if _rc != 0 {
    di as error "❌ ERROR in 04_analysis.do"
    exit 1
}

********************************************************************************
* STEP 5 — Progressivity
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 5 : Progressivity"
di as text "--------------------------------------------------"

capture noisily do "$CODE/05_progressivity.do"
if _rc != 0 {
    di as error "❌ ERROR in 05_progressivity.do"
    exit 1
}


********************************************************************************
* STEP 6.1 — Robustness
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 6.1 : Robustness"
di as text "--------------------------------------------------"

capture noisily do "$CODE/06_01_sensitivity_taxation.do"
if _rc != 0 {
    di as error "❌ ERROR in 06_01_sensitivity_taxation.do"
    exit 1
}


********************************************************************************
* STEP 6.2 — Robustness
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 6.2 : Robustness"
di as text "--------------------------------------------------"

capture noisily do "$CODE/06_02_sensitivity_ranking.do"
if _rc != 0 {
    di as error "❌ ERROR in 06_02_sensitivity_ranking.do"
    exit 1
}


********************************************************************************
* STEP 7 — Appendix
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 7 : Appendix"
di as text "--------------------------------------------------"

capture noisily do "$CODE/07_appendix_tables.do"
if _rc != 0 {
    di as error "❌ ERROR in 07_appendix_tables.do"
    exit 1
}

********************************************************************************
* STEP 8 — Figures
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 7 : figures"
di as text "--------------------------------------------------"

capture noisily do "$CODE/08_figures.do"
if _rc != 0 {
    di as error "❌ ERROR in 08_figures.do"
    exit 1
}

********************************************************************************
* STEP 9 — Determinants
********************************************************************************

di as text "--------------------------------------------------"
di as text "STEP 9 : determinants"
di as text "--------------------------------------------------"

capture noisily do "$CODE/09_vat_determinants.do"
if _rc != 0 {
    di as error "❌ ERROR in 09_vat_determinants.do"
    exit 1
}


********************************************************************************
* END
********************************************************************************

di as result "=================================================="
di as result " PROJECT COMPLETED SUCCESSFULLY"
di as result "=================================================="

log close