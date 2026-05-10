********************************************************************************
* 06_02_sensitivity_ranking.do
*
* OBJECTIF :
* Analyse de sensibilite de l'incidence TVA aux classements distributifs alternatifs.
*
* JUSTIFICATION EMPIRIQUE :
* Le classement de base utilise la consommation totale du menage. C'est standard quand
* la consommation est traitee comme un proxy du niveau de vie pre-fiscal. Cependant,
* la taille et la composition du menage peuvent affecter les comparaisons de bien-etre.
* On compare donc trois concepts de classement :
*   1) consommation totale du menage
*   2) consommation par tete
*   3) consommation par adulte equivalent
*
* Les classements par tete et adulte equivalent ne sont pas des charges fiscales alternatives ;
* ce sont des facons alternatives d'ordonner les menages dans la distribution.
*
* ENTREES REQUISES :
* Pour calculer le bien-etre par tete et adulte equivalent, le jeu de donnees doit contenir :
*   - hhsize  : taille du menage
*   - eqadu1  : nombre d'adultes 
*   - eqadu2 : nombre d'adultes 

 ********************************************************************************

use "$SILVER/06/fiscal_sensitivity_taxation.dta", clear
by hhid: gen hh_tag = (_n == 1)
keep if hh_tag == 1
drop hh_tag
merge 1:1 hhid using "$DATA/ehcvm_welfare_civ2021", keepusing(eqadu1 eqadu2 hgender hage hmstat heduc halfa2 halfa hbranch pcexp zref hhsize)
drop _merge
 ********************************************************************************
* ETAPE 0 — Variables requises
 ********************************************************************************

 ********************************************************************************
* ETAPE 1 — Validation
 ********************************************************************************

assert !missing(hhid, hhweight, conso_w, vat_strict)


 ********************************************************************************
* ETAPE 2 — Concepts de bien-etre
 ********************************************************************************

* Consommation par tete
gen conso_pc = conso_w / hhsize
label var conso_pc "Consommation par tete"

* Consommation par adulte equivalent (Echelle FAO)
gen conso_ae1 = conso_w / eqadu1
label var conso_ae1 "Consommation par adulte equivalent-1"

gen conso_ae2 = conso_w / eqadu2
label var conso_ae2 "Consommation par adulte equivalent-2"

 ********************************************************************************
* ETAPE 3 — Creer les deciles
 ********************************************************************************

xtile decile_total = conso_w  [pw=hhweight], n(10)
xtile decile_pc    = conso_pc [pw=hhweight], n(10)
xtile decile_ae1    = conso_ae1 [pw=hhweight], n(10)
xtile decile_ae2    = conso_ae2 [pw=hhweight], n(10)

label define dec_lbl 1 "D1 le plus pauvre" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 le plus riche", replace

foreach v in decile_total decile_pc decile_ae1 decile_ae2 {
    label values `v' dec_lbl
}

 ********************************************************************************
* ETAPE 4 — Taux TVA effectif par classement
 ********************************************************************************

foreach rank in total pc ae1 ae2 {
    preserve
    collapse (mean) eff_vat_strict eff_vat_s2  eff_vat_s3  ///
        [pw=hhweight], by(decile_`rank')
    rename decile_`rank' decile
    export excel using "$TABLES/06/06_02_eff_vat_`rank'.xlsx", ///
        firstrow(variables) replace
    restore
}

 ********************************************************************************
* ETAPE 5 — Resume CEQ (VERSION FINALE NETTOYEE)
 ********************************************************************************

capture which ineqdeco
if _rc ssc install ineqdeco

capture which conindex
if _rc ssc install conindex

tempname results
postfile ceq_handle str10 ranking str10 scenario ///
    double g_market g_after c_vat kakwani rs ///
    using "$SILVER/06/06_02_ceq_rankings.dta", replace

foreach rank in total pc ae1 ae2 {

    * Supprimer individuellement — chaque variable supprimee independamment
    foreach v in welfare vat_adj_strict vat_adj_s2 vat_adj_s3 consumable {
        capture drop `v'
    }

    if "`rank'" == "total" {
        gen welfare        = conso_w
        gen vat_adj_strict = vat_strict
        gen vat_adj_s2     = vat_s2
        gen vat_adj_s3     = vat_s3
    }
    if "`rank'" == "pc" {
        gen welfare        = conso_pc
        gen vat_adj_strict = vat_strict / hhsize
        gen vat_adj_s2     = vat_s2     / hhsize
        gen vat_adj_s3     = vat_s3     / hhsize
    }
    if "`rank'" == "ae1" {
        gen welfare        = conso_ae1
        gen vat_adj_strict = vat_strict / eqadu1
        gen vat_adj_s2     = vat_s2     / eqadu1
        gen vat_adj_s3     = vat_s3     / eqadu1
    }
    if "`rank'" == "ae2" {
        gen welfare        = conso_ae2
        gen vat_adj_strict = vat_strict / eqadu2
        gen vat_adj_s2     = vat_s2     / eqadu2
        gen vat_adj_s3     = vat_s3     / eqadu2
    }

    quietly ineqdeco welfare [aw=hhweight]
    scalar G_market = r(gini)

    foreach s in strict s2 s3 {
        capture drop consumable
        gen consumable = welfare - vat_adj_`s'
        quietly ineqdeco consumable [aw=hhweight]
        scalar G_after = r(gini)
        quietly conindex vat_adj_`s' [aw=hhweight], ///
            rankvar(welfare) truezero
        scalar C_vat   = r(CI)
        scalar Kakwani = C_vat - G_market
        scalar RS      = G_after - G_market
        post ceq_handle ("`rank'") ("`s'") ///
            (G_market) (G_after) (C_vat) (Kakwani) (RS)
        capture drop consumable
    }
}
postclose ceq_handle

 ********************************************************************************
* FIN
 ********************************************************************************