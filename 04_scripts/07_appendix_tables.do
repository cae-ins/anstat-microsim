********************************************************************************
* 07_appendix_tables.do
*
* OBJECTIF :
* Produire les tableaux supplementaires pour l'annexe et la documentation de robustesse.
*
* CONTENU :
* - Statistiques completes de distribution
* - Profils deciles et quintiles detailles
* - Decomposition TVA par COICOP
* - Decompositions regionales et rural/urbain
* - Diagnostics pour la qualite des donnees
 ********************************************************************************

use "$SILVER/04/fiscal_data_analysis_ready.dta", clear

 ********************************************************************************
* ETAPE 1 — Diagnostics complets de distribution
 ********************************************************************************

sum conso conso_w vat vat_w eff_vat eff_vat_w, detail

* Exporter le resume manuellement si necessaire

 ********************************************************************************
* ETAPE 2 — Profil decile detendu (etendu)
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (p50) median_conso = conso_w ///
    (p90) p90_conso = conso_w ///
    (p10) p10_conso = conso_w ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(decile)

egen total_vat = total(vat_sum)
gen vat_share = vat_sum / total_vat

export excel using "$TABLES/07/07_decile_detailed.xlsx", firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 3 — Profil quintile detendu
 ********************************************************************************

*xtile quintile = conso_w [pw=hhweight], n(5)

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(quintile)

egen total_vat = total(vat_sum)
gen vat_share = vat_sum / total_vat

export excel using "$TABLES/07/07_quintile_detailed.xlsx", firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 4 — Decomposition TVA par COICOP
 ********************************************************************************

use "$SILVER/01/conso_clean.dta", clear

* S'assurer que la TVA est calculee au niveau item
gen vat_item_w = depan_w * r_vat_official

preserve
collapse ///
    (sum) vat_w = vat_item_w ///
    (sum) conso_w = depan_w ///
    [pw=hhweight], by(coicop)

gen vat_rate_coicop = vat_w / conso_w

export excel using "$TABLES/07/07_vat_by_coicop.xlsx", firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 5 — Decomposition regionale (etendue)
 ********************************************************************************

use "$SILVER/04/fiscal_data_analysis_ready.dta", clear

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (sum) vat_sum = vat_w ///
    [pw=hhweight], by(region)

gsort -eff_vat

export excel using "$TABLES/07/07_region_detailed.xlsx", firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 6 — Rural vs Urbain (etendu)
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w vat_w eff_vat ///
    (p50) median_conso = conso_w ///
    [pw=hhweight], by(milieu)

export excel using "$TABLES/07/07_milieu_detailed.xlsx", replace
restore

 ********************************************************************************
* ETAPE 7 — Diagnostics : qualite des donnees
 ********************************************************************************

* Nombre d'items par menage
sum n_items, detail

* Taux TVA extremes
sum eff_vat, detail

* Identifier les valeurs aberrantes potentielles
gen flag_high_vat = eff_vat > 0.2
tab flag_high_vat

 ********************************************************************************
* FIN
 ********************************************************************************

di as result ">>> Tableaux d'annexe generes avec succes"