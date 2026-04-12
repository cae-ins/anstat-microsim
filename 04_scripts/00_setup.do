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
capture confirm file "04_scripts/00_master.do"

if _rc != 0 {
    di as error "--- wrong work folder"
    di as error "--- Run Stata from the project's root folder"
    exit 198
}

* folder
global ROOT = c(pwd)

* ── Sources ─────────────────────────────────────────────────────────────────
global DATA    "$ROOT/01_data_sources/Dataout"
global CODE    "$ROOT/04_scripts"

* ── Medallion layers ─────────────────────────────────────────────────────────
global SILVER  "$ROOT/02_data_intermediate"   // cleaned intermediate datasets
global GOLD    "$ROOT/03_data_output"          // final analytic datasets

* ── Reports ──────────────────────────────────────────────────────────────────
global LOGS    "$ROOT/06_logs"
global TABLES  "$ROOT/07_reports/tables"
global FIGS    "$ROOT/07_reports/figures"

* ── Create folders if missing ────────────────────────────────────────────────
cap mkdir "$SILVER"
cap mkdir "$SILVER/01"
cap mkdir "$SILVER/02"
cap mkdir "$SILVER/03"
cap mkdir "$SILVER/04"
cap mkdir "$SILVER/05"
cap mkdir "$SILVER/06"

cap mkdir "$GOLD"

cap mkdir "$ROOT/06_logs"

cap mkdir "$ROOT/07_reports"
cap mkdir "$TABLES"
cap mkdir "$TABLES/01"
cap mkdir "$TABLES/04"
cap mkdir "$TABLES/05"
cap mkdir "$TABLES/06"
cap mkdir "$TABLES/07"
cap mkdir "$TABLES/09"
cap mkdir "$TABLES/10"
cap mkdir "$FIGS"

* Log
cap log close
log using "$LOGS/master.log", replace text
