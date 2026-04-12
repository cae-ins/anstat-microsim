********************************************************************************
* 12_poverty_incidence.do
*
* OBJECTIF :
* Estimer l'impact de la TVA sur la pauvreté via les indices FGT
* (Foster, Greer & Thorbecke, 1984) : taux (P0), écart (P1), sévérité (P2).
*
* APPROCHE :
* Pour chaque scénario de taxation, on soustrait la charge TVA par tête à
* la dépense per capita officielle EHCVM (pcexp), puis on compare au seuil
* de pauvreté ménage-spécifique (zref).
*
*   pcexp_après = pcexp - vat_scénario / hhsize
*
* NOTE MÉTHODOLOGIQUE :
*   pcexp (agrégat officiel EHCVM) inclut tous les modes d'acquisition.
*   La TVA simulée ne porte que sur les achats marché (modep==1).
*   La soustraction est cohérente : l'autoconsommation et les dons ne sont
*   pas soumis à la TVA.
*
* INPUT :  $SILVER/06/fiscal_sensitivity_taxation.dta
*          $DATA/ehcvm_welfare_2b_CIV2021.dta
*          $SILVER/10/reform_chicken_hh.dta  (optionnel — réforme)
* OUTPUT : $TABLES/12/12_01_fgt_national.xlsx
*          $TABLES/12/12_02_fgt_milieu.xlsx
*          $TABLES/12/12_03_fgt_region.xlsx
*          $TABLES/12/12_04_poverty_impact_decile.xlsx
*          $TABLES/12/12_05_fgt_reform.xlsx  (si réforme disponible)
*
* AUTEUR : CAE — ANStat
********************************************************************************

di as text "--------------------------------------------------"
di as text "ETAPE 12 : Incidence de la TVA sur la pauvreté (FGT)"
di as text "--------------------------------------------------"


********************************************************************************
* SECTION 1 — Chargement et fusion des données
********************************************************************************

* Données de taxation par scénario (issues de l'étape 6.1)
use "$SILVER/06/fiscal_sensitivity_taxation.dta", clear

* Fusion avec les variables de bien-être
merge 1:1 hhid using "$DATA/ehcvm_welfare_2b_CIV2021.dta", ///
    keepusing(pcexp zref hhsize) ///
    keep(3) nogen

* Vérification
count if missing(pcexp) | missing(zref)
if r(N) > 0 {
    di as error "  Attention : " r(N) " ménages avec pcexp ou zref manquants — exclus"
    drop if missing(pcexp) | missing(zref)
}

* Dépense per capita post-TVA pour chaque scénario
gen pcexp_after_strict = pcexp - vat_strict / hhsize
gen pcexp_after_s2     = pcexp - vat_s2     / hhsize
gen pcexp_after_s3     = pcexp - vat_s3     / hhsize

label var pcexp              "Avant TVA (pcexp officiel)"
label var pcexp_after_strict "Après TVA — Strict (alpha=1)"
label var pcexp_after_s2     "Après TVA — S2 (CEI x milieu)"
label var pcexp_after_s3     "Après TVA — S3 (CEI x décile)"


********************************************************************************
* SECTION 2 — Variables FGT
********************************************************************************

foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {

    * Indicateurs pauvreté
    gen poor_`concept'  = (`concept' < zref)                     if !missing(`concept', zref)
    gen pgap_`concept'  = max(0, (zref - `concept') / zref)      if !missing(`concept', zref)
    gen psev_`concept'  = pgap_`concept'^2                       if !missing(pgap_`concept')

    label var poor_`concept' "P0 — `concept'"
    label var pgap_`concept' "P1 — `concept'"
    label var psev_`concept' "P2 — `concept'"
}

* Nouveaux pauvres : non pauvres avant TVA qui basculent sous le seuil
gen new_poor_strict = (poor_pcexp == 0 & poor_pcexp_after_strict == 1)
gen new_poor_s2     = (poor_pcexp == 0 & poor_pcexp_after_s2     == 1)
gen new_poor_s3     = (poor_pcexp == 0 & poor_pcexp_after_s3     == 1)


********************************************************************************
* SECTION 3 — Indices FGT nationaux
********************************************************************************

di as text ""
di as text "=== Indices FGT — niveau national ==="

tempname fgt_nat
postfile `fgt_nat' str60 concept double p0 p1 p2 using ///
    "$TABLES/12/fgt_national_temp.dta", replace

foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
    qui sum poor_`concept' [aw=hhweight]
    local p0 = r(mean)
    qui sum pgap_`concept' [aw=hhweight]
    local p1 = r(mean)
    qui sum psev_`concept' [aw=hhweight]
    local p2 = r(mean)

    di as result "  `concept' : P0=`p0', P1=`p1', P2=`p2'"
    post `fgt_nat' ("`concept'") (`p0') (`p1') (`p2')
}

postclose `fgt_nat'

* Export national
use "$TABLES/12/fgt_national_temp.dta", clear
export excel using "$TABLES/12/12_01_fgt_national.xlsx", ///
    firstrow(variables) replace
di as text "  -> exporté : 12_01_fgt_national.xlsx"

* Revenir aux données principales
use "$SILVER/06/fiscal_sensitivity_taxation.dta", clear
merge 1:1 hhid using "$DATA/ehcvm_welfare_2b_CIV2021.dta", ///
    keepusing(pcexp zref hhsize) keep(3) nogen
drop if missing(pcexp) | missing(zref)

foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
    gen pcexp_`concept'2 = `concept'   // pour éviter conflit de noms
    cap drop pcexp_`concept'2
    gen poor_`concept'  = (`concept' < zref)
    gen pgap_`concept'  = max(0, (zref - `concept') / zref)
    gen psev_`concept'  = pgap_`concept'^2
}
// Recharger proprement
restore


********************************************************************************
* SECTION 3 (bis) — approche propre avec preserve/restore
********************************************************************************

* Recharger
use "$SILVER/06/fiscal_sensitivity_taxation.dta", clear
merge 1:1 hhid using "$DATA/ehcvm_welfare_2b_CIV2021.dta", ///
    keepusing(pcexp zref hhsize) keep(3) nogen
drop if missing(pcexp) | missing(zref)

gen pcexp_after_strict = pcexp - vat_strict / hhsize
gen pcexp_after_s2     = pcexp - vat_s2     / hhsize
gen pcexp_after_s3     = pcexp - vat_s3     / hhsize

foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
    gen poor_`concept' = (`concept' < zref)
    gen pgap_`concept' = max(0, (zref - `concept') / zref)
    gen psev_`concept' = pgap_`concept'^2
}

gen new_poor_strict = (poor_pcexp == 0 & poor_pcexp_after_strict == 1)
gen new_poor_s2     = (poor_pcexp == 0 & poor_pcexp_after_s2     == 1)
gen new_poor_s3     = (poor_pcexp == 0 & poor_pcexp_after_s3     == 1)


********************************************************************************
* SECTION 4 — FGT par milieu
********************************************************************************

di as text ""
di as text "=== Indices FGT par milieu ==="

preserve
    * Construire la table par milieu manuellement via collapse
    foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
        gen w_poor_`concept' = poor_`concept' * hhweight
        gen w_pgap_`concept' = pgap_`concept' * hhweight
        gen w_psev_`concept' = psev_`concept' * hhweight
    }
    gen w_total = hhweight

    collapse (sum) w_poor_* w_pgap_* w_psev_* w_total, by(milieu)

    foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
        gen p0_`concept' = w_poor_`concept' / w_total
        gen p1_`concept' = w_pgap_`concept' / w_total
        gen p2_`concept' = w_psev_`concept' / w_total
        drop w_poor_`concept' w_pgap_`concept' w_psev_`concept'
    }
    drop w_total

    export excel using "$TABLES/12/12_02_fgt_milieu.xlsx", ///
        firstrow(variables) replace
    di as text "  -> exporté : 12_02_fgt_milieu.xlsx"
restore


********************************************************************************
* SECTION 5 — FGT par région
********************************************************************************

di as text ""
di as text "=== Indices FGT par région ==="

preserve
    foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
        gen w_poor_`concept' = poor_`concept' * hhweight
        gen w_pgap_`concept' = pgap_`concept' * hhweight
        gen w_psev_`concept' = psev_`concept' * hhweight
    }
    gen w_total = hhweight

    collapse (sum) w_poor_* w_pgap_* w_psev_* w_total, by(region)

    foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
        gen p0_`concept' = w_poor_`concept' / w_total
        gen p1_`concept' = w_pgap_`concept' / w_total
        gen p2_`concept' = w_psev_`concept' / w_total
        drop w_poor_`concept' w_pgap_`concept' w_psev_`concept'
    }
    drop w_total

    export excel using "$TABLES/12/12_03_fgt_region.xlsx", ///
        firstrow(variables) replace
    di as text "  -> exporté : 12_03_fgt_region.xlsx"
restore


********************************************************************************
* SECTION 6 — Impact par décile
********************************************************************************

di as text ""
di as text "=== Impact sur la pauvreté par décile ==="

preserve
    foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
        gen w_poor_`concept' = poor_`concept' * hhweight
    }
    gen w_new_strict = new_poor_strict * hhweight
    gen w_new_s2     = new_poor_s2     * hhweight
    gen w_new_s3     = new_poor_s3     * hhweight
    gen w_total      = hhweight

    collapse (sum) w_poor_* w_new_* w_total, by(decile)

    foreach concept in pcexp pcexp_after_strict pcexp_after_s2 pcexp_after_s3 {
        gen p0_`concept' = w_poor_`concept' / w_total
        drop w_poor_`concept'
    }

    gen n_new_poor_strict = w_new_strict
    gen n_new_poor_s2     = w_new_s2
    gen n_new_poor_s3     = w_new_s3

    gen delta_p0_strict = p0_pcexp_after_strict - p0_pcexp
    gen delta_p0_s2     = p0_pcexp_after_s2     - p0_pcexp
    gen delta_p0_s3     = p0_pcexp_after_s3     - p0_pcexp

    drop w_total w_new_*

    di as text ""
    di as text "  Delta P0 par décile (scénario Strict) :"
    list decile p0_pcexp p0_pcexp_after_strict delta_p0_strict n_new_poor_strict, ///
        noobs sep(0)

    * Totaux
    qui sum n_new_poor_s2
    di as result "  Nouveaux pauvres total S2 : " %12.0fc r(sum)

    export excel using "$TABLES/12/12_04_poverty_impact_decile.xlsx", ///
        firstrow(variables) replace
    di as text "  -> exporté : 12_04_poverty_impact_decile.xlsx"
restore


********************************************************************************
* SECTION 7 — Composante réforme avicole (conditionnelle)
********************************************************************************

capture confirm file "$SILVER/10/reform_chicken_hh.dta"
if _rc == 0 {
    di as text ""
    di as text "=== Impact pauvreté — réforme TVA intrants avicoles ==="

    preserve
        merge 1:1 hhid using "$SILVER/10/reform_chicken_hh.dta", ///
            keepusing(add_vat_s1 add_vat_s2 add_vat_s3) keep(1 3) nogen

        * Post-réforme : on part du baseline strict et on ajoute la charge réforme
        gen pcexp_reform_s1 = pcexp_after_strict - add_vat_s1 / hhsize
        gen pcexp_reform_s2 = pcexp_after_strict - add_vat_s2 / hhsize
        gen pcexp_reform_s3 = pcexp_after_strict - add_vat_s3 / hhsize

        gen poor_reform_s1 = (pcexp_reform_s1 < zref)
        gen poor_reform_s2 = (pcexp_reform_s2 < zref)
        gen poor_reform_s3 = (pcexp_reform_s3 < zref)

        * FGT national — réforme
        foreach concept in pcexp_after_strict pcexp_reform_s1 pcexp_reform_s2 pcexp_reform_s3 {
            qui sum poor_`concept' [aw=hhweight]
            di as result "  P0 `concept' : " r(mean)
        }

        * Export
        keep hhid poor_pcexp_after_strict poor_reform_s1 poor_reform_s2 poor_reform_s3 hhweight
        gen w = hhweight
        collapse (mean) poor_pcexp_after_strict poor_reform_s1 poor_reform_s2 poor_reform_s3 ///
            [aw=w]

        gen byte ordre = 1
        reshape long poor_, i(ordre) j(concept) string

        rename poor_ p0
        replace concept = "Référence : après TVA Strict"    if concept == "pcexp_after_strict"
        replace concept = "Réforme S1 — conservateur"       if concept == "reform_s1"
        replace concept = "Réforme S2 — central"            if concept == "reform_s2"
        replace concept = "Réforme S3 — complet"            if concept == "reform_s3"
        drop ordre

        export excel using "$TABLES/12/12_05_fgt_reform.xlsx", ///
            firstrow(variables) replace
        di as text "  -> exporté : 12_05_fgt_reform.xlsx"
    restore
}
else {
    di as text ""
    di as text "  Réforme avicole : $SILVER/10/reform_chicken_hh.dta absent."
    di as text "  Lancez d'abord l'étape 10 (10_reform_chicken_inputs.do)."
}


********************************************************************************
* FIN
********************************************************************************

di as text ""
di as result "  ETAPE 12 TERMINÉE — tableaux dans $TABLES/12/"
