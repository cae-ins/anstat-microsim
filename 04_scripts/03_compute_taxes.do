********************************************************************************
* 03_compute_taxes.do
*
* OBJECTIF :
* Calculer l'incidence de la TVA au niveau menage en utilisant les microdonnees EHCVM.
*
* APPROCHE :
* Le script applique les taux TVA au niveau produit a la consommation observee afin
* d'estimer la charge fiscale supportee par chaque menage. Le processus suit une
* approche de microsimulation standard coherente avec la methode CEQ.
*
* ETAPES CLES :
* 1. Calculer la TVA au niveau produit (consommation × taux TVA).
* 2. Agreger la consommation et la TVA au niveau menage.
* 3. Deriver les taux TVA effectifs (TVA / consommation totale).
*
* INTERPRETATION ECONOMIQUE :
* - La TVA est supposee entierement reportée sur les consommateurs (incidence statique).
* - Le taux TVA effectif mesure la part de la consommation capturee par la TVA.
* - Les resultats peuvent etre utilises pour evaluer la regressivite ou la progressivite de la TVA.
*
* STRUCTURE DES DONNEES :
* - Unite d'observation (entree) : menage × produit
* - Unite d'observation (sortie) : menage
*
* HYPOTHESES IMPORTANTES :
* - Seules les transactions marchandes sont inclues (modep == 1 applique).
* - Les taux TVA sont correctement assignes via le fichier de mapping.
*
* SORTIE :
* Jeu de donnees au niveau menage incluant :
* - consommation totale (brute et winsorisee)
* - TVA totale payee
* - taux TVA effectif
* - concepts de revenu proxy CEQ
 ********************************************************************************

 ********************************************************************************
* 03_compute_taxes.do
 ********************************************************************************

use "$SILVER/01/conso_clean.dta", clear


 ********************************************************************************
* ETAPE 1 — Calculer la TVA au niveau item
 ********************************************************************************

gen vat_item   = depan   * r_vat_official
label variable vat_item "TVA payee au niveau item (consommation brute)"
gen vat_item_w = depan_w * r_vat_official
label variable vat_item_w "TVA payee au niveau item (consommation winsorisee)"

 ********************************************************************************
* ETAPE 2 — Agreger au niveau menage
 ********************************************************************************

di as text ">>> Agregation au niveau menage"

sort hhid

* Consommation totale
by hhid: egen conso   = total(depan)
label variable conso "Consommation totale du menage (brute)"
by hhid: egen conso_w = total(depan_w)
label variable conso_w "Consommation totale du menage (winsorisee)"
* TVA totale
by hhid: egen vat   = total(vat_item)
label variable vat "TVA totale payee par le menage (brute)"
by hhid: egen vat_w = total(vat_item_w)
label variable vat_w "TVA totale payee par le menage (winsorisee)"
* Nombre d'items
by hhid: egen n_items = count(produit)
label variable n_items "Nombre d'items de consommation declares par le menage"
sum n_items, detail
histogram n_items
graph save "$FIGS/n_items.gph" , replace
graph export "$FIGS/n_items.png", replace

 ********************************************************************************
* ETAPE 3 — Taux TVA effectif
 ********************************************************************************

gen eff_vat   = vat   / conso
label variable eff_vat "Taux TVA effectif (TVA / consommation, brut)"
gen eff_vat_w = vat_w / conso_w
label variable eff_vat_w "Taux TVA effectif (TVA / consommation, winsorise)"

 ********************************************************************************
* ETAPE 4 — Reduire a une observation par menage
 ********************************************************************************

by hhid: gen hh_tag = (_n == 1)
keep if hh_tag == 1
drop hh_tag

 ********************************************************************************
* ETAPE 5 — Variables logarithmiques
 ********************************************************************************

gen lconso   = log(conso)
label variable lconso "log de la consommation du menage (brute)"

gen lconso_w = log(conso_w)
label variable lconso_w "log de la consommation du menage (winsorisee)"

histogram lconso, normal
graph save "$FIGS/log_conso.gph" , replace
graph export "$FIGS/log_conso.png", replace
histogram lconso_w, normal
graph save "$FIGS/log_conso_w.gph" , replace
graph export "$FIGS/log_conso_w.png", replace

 ********************************************************************************
* ETAPE 6 — Concepts proxy CEQ
 ********************************************************************************
gen market_income     = conso_w
label variable market_income "Proxy du revenu de marche (consommation winsorisee)"

gen consumable_income = conso_w - vat_w
label variable consumable_income "Revenu utilisable (winsorise, net de TVA)"

 ********************************************************************************
* ETAPE 7 — Diagnostics
 ********************************************************************************

sum conso_w vat_w eff_vat_w, detail



 ********************************************************************************
* ETAPE 8 — Garder uniquement les variables au niveau menage
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
La consommation au niveau menage presente une asymetrie moderee a droite,
avec une mediane d'environ 1,4 million de FCA (conso) et une moyenne de 1,8 million de FCA.
La queue superieure reste presente mais controlee, avec le top 1% atteignant 6 millions de CFA.
Par rapport aux distributions au niveau item, l'agregation au niveau menage reduit significativement
la variabilite extreme, resultant en une distribution plus stable et interpretable.*/

 ********************************************************************************
* ETAPE 9 — Sauvegarder le jeu de donnees final
 ********************************************************************************

save "$SILVER/03/fiscal_data.dta", replace

des, full