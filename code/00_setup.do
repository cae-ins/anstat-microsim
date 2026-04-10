********************************************************************************
* IMPORTANT NOTE:
*
* This file (00_setup.do) must be executed from the project root directory.
*
* Recommended usage:
*   - Open Stata directly in the project root folder, OR
*   - Set the working directory manually using the "cd" command before running.
*
* Alternatively, opening and running this file directly in Stata will set up
* the correct project paths and prevent path-related errors in the code.
* This ensures that all relative paths used in the project remain valid and
* the code does not break across different machines or environments.
*AUTHOR: Armand Kouakou Djaha, MSc
********************************************************************************
clear all
set more off
set varabbrev off

* Vérification robuste
capture confirm file "code/00_master.do"

if _rc != 0 {
    di as error "--- wrong work folder"
    di as error "--- Run Stata from the project's root folder"
    exit 198
}

* folder
global ROOT = c(pwd)

global DATA   "$ROOT/data/EHCVM/EHCVM2122"
global CODE   "$ROOT/code"
global OUTPUT "$ROOT/output"
global LOGS   "$OUTPUT/logs"
global TABLES "$OUTPUT/tables"
global FIGS   "$OUTPUT/figures"

dir DATA/EHCVM/EHCVM2122/

* gen inexistant folder
cap mkdir "$OUTPUT"
cap mkdir "$OUTPUT/final_data/01"
cap mkdir "$OUTPUT/final_data/02"
cap mkdir "$OUTPUT/final_data/03"
cap mkdir "$OUTPUT/final_data/04"
cap mkdir "$OUTPUT/final_data/05"
cap mkdir "$OUTPUT/final_data/06"
cap mkdir "$OUTPUT/final_data/07"
cap mkdir "$OUTPUT/final_data/08"
cap mkdir "$OUTPUT/final_data/09"
cap mkdir "$LOGS"
cap mkdir "$TABLES"
cap mkdir "$TABLES/01"
cap mkdir "$TABLES/02"
cap mkdir "$TABLES/03"
cap mkdir "$TABLES/04"
cap mkdir "$TABLES/05"
cap mkdir "$TABLES/06"
cap mkdir "$TABLES/07"
cap mkdir "$TABLES/08"
cap mkdir "$TABLES/09"
cap mkdir "$FIGS"

* Log
cap log close
log using "$LOGS/master.log", replace text