********************************************************************************
* 00_master.do
* Script maitre — execute le pipeline complet
*
* Ce script doit etre execute depuis le dossier racine du projet.
* Il execute toutes les etapes dans l'ordre :
*   1. Configuration de l'environnement
*   2. Preparation des donnees brutes
*   3. Application du mapping fiscal
*   4. Calcul des taxes et variables CEQ
*   5. Analyse et export des resultats
 ********************************************************************************

clear all
set more off

 ********************************************************************************
* ETAPE 0 — Configuration de l'environnement
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 0 : Configuration de l'environnement"
di as text "--------------------------------------------------"

* Executer ce script depuis le dossier racine du projet.
* 00_setup.do s'arretera avec une erreur si le dossier de travail est incorrect.
do "04_scripts/00_setup.do"

 ********************************************************************************
* ETAPE 1 — Preparation des donnees
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 1 : Preparation des donnees"
di as text "--------------------------------------------------"

capture noisily do "$CODE/01_prepare_data.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 01_prepare_data.do"
    exit 1
}

 ********************************************************************************
* ETAPE 2 — Mapping fiscal
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 2 : Application du mapping fiscal"
di as text "--------------------------------------------------"

capture noisily do "$CODE/02_mapping_tax.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 02_mapping_tax.do"
    exit 1
}

 ********************************************************************************
* ETAPE 3 — Calcul des taxes
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 3 : Calcul des taxes"
di as text "--------------------------------------------------"

capture noisily do "$CODE/03_compute_taxes.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 03_compute_taxes.do"
    exit 1
}

 ********************************************************************************
* ETAPE 4 — Analyse
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 4 : Execution de l'analyse"
di as text "--------------------------------------------------"

capture noisily do "$CODE/04_analysis.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 04_analysis.do"
    exit 1
}

 ********************************************************************************
* ETAPE 5 — Progressivite
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 5 : Progressivite"
di as text "--------------------------------------------------"

capture noisily do "$CODE/05_progressivity.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 05_progressivity.do"
    exit 1
}

 ********************************************************************************
* ETAPE 6.1 — Robustesse
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 6.1 : Robustesse"
di as text "--------------------------------------------------"

capture noisily do "$CODE/06_01_sensitivity_taxation.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 06_01_sensitivity_taxation.do"
    exit 1
}

 ********************************************************************************
* ETAPE 6.2 — Robustesse
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 6.2 : Robustesse"
di as text "--------------------------------------------------"

capture noisily do "$CODE/06_02_sensitivity_ranking.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 06_02_sensitivity_ranking.do"
    exit 1
}

 ********************************************************************************
* ETAPE 7 — Annexes
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 7 : Annexes"
di as text "--------------------------------------------------"

capture noisily do "$CODE/07_appendix_tables.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 07_appendix_tables.do"
    exit 1
}

 ********************************************************************************
* ETAPE 8 — Figures
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 8 : Figures"
di as text "--------------------------------------------------"

capture noisily do "$CODE/08_figures.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 08_figures.do"
    exit 1
}

 ********************************************************************************
* ETAPE 9 — Determinants
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 9 : Determinants"
di as text "--------------------------------------------------"

capture noisily do "$CODE/09_vat_determinants.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 09_vat_determinants.do"
    exit 1
}

 ********************************************************************************
* ETAPE 10 — Scenarios de reforme
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 10 : Scenarios de reforme"
di as text "--------------------------------------------------"

capture noisily do "$CODE/10_reform_chicken_inputs.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 10_reform_chicken_inputs.do"
    exit 1
}

 ********************************************************************************
* ETAPE 11 — Figures de reforme
 ********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 11 : Figures de reforme"
di as text "--------------------------------------------------"

capture noisily do "$CODE/11_reform_figures.do"
if _rc != 0 {
    di as error "❌ ERREUR dans 11_reform_figures.do"
    exit 1
}

 ********************************************************************************
* FIN
 ********************************************************************************

di as result "=================================================="
di as result " PROJET TERMINE AVEC SUCCES"
di as result "=================================================="

log close