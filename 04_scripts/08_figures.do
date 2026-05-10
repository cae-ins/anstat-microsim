********************************************************************************
* 08_figures.do
*
* OBJECTIF :
* Produire toutes les figures pour l'analyse de l'incidence TVA.
*
* CONTENU :
* Fig 1 — Taux TVA effectif par decile : trois scenarios 
* Fig 2 — Courbes de concentration : trois scenarios + Lorenz + ligne d'egalite
* Fig 3 — TVA par categorie COICOP (descriptif)
* Fig 5 — Profils Alpha par decile : nourriture/boissons, restaurants, soins personnels,
*          info/comm (illustre le calibration CEI)
*
* SORTIES :
*   - $FIGS/fig1_eff_vat_three_scenarios.png
*   - $FIGS/fig2_concentration_curves.png
*   - $FIGS/fig3_vat_by_coicop.png
*   - $FIGS/fig4_alpha_profiles.png
*
* NOTE SUR LE SCHEMA :
* s1color est utilise pour la compatibilite.
 ********************************************************************************

set scheme s1color

 ********************************************************************************
* FIGURE 1 — Taux TVA effectif par decile : trois scenarios
*
* OBJECTIF :
* C'est la figure centrale de l'analyse. Elle montre visuellement pourquoi la
* conclusion distributive depend entierement de l'hypothese d'informelite :
*   - Strict : profil quasi-plat/legement regressif
*   - S2 (CEI × milieu) : profil croissant, gradient modere
*   - S3 (CEI × decile) : profil clairement croissant, gradient le plus fort
*
* SOURCE: fiscal_sensitivity_taxation.dta (niveau menage)
 ********************************************************************************

use "$SILVER/06/fiscal_sensitivity_taxation.dta", clear

preserve
collapse (mean) eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [pw=hhweight], by(decile)

* Verifier l'etiquetage monotonique
assert decile >= 1 & decile <= 10

twoway ///
    (line eff_vat_strict decile, ///
        lcolor(maroon)       lwidth(medthick) lpattern(solid))         ///
    (line eff_vat_s2     decile, ///
        lcolor(navy)         lwidth(medthick) lpattern(dash))          ///
    (line eff_vat_s3     decile, ///
        lcolor(forest_green) lwidth(medthick) lpattern(shortdash_dot)) ///
    , ///
    legend(order(                                                        ///
        1 "Strict ({&alpha}=1) — borne superieure theorique"               ///
        2 "S2: CEI x milieu urbain/rural (Bachas et al. 2024)"   ///
        3 "S3: CEI x decile — IEC calibree")          ///
        position(6) rows(3) size(small))                                 ///
    title("Taux TVA effectif par decile de consommation", size(medium))      ///
    subtitle("Trois scenarios d'informelite — Cote d'Ivoire EHCVM 2021",  ///
        size(small))                                                     ///
    ytitle("Taux TVA effectif (TVA / consommation)", size(small))        ///
    xtitle("Decile de consommation", size(small))                            ///
    ylabel(0(.02).16, angle(horizontal) labsize(small))                  ///
    xlabel(1(1)10, labsize(small))                                       ///
    note("Source: EHCVM 2021. Alpha calibration: Bachas, Gadenne & Jensen (2024, RestUD 91(5)).", ///
        size(vsmall))                                                    ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig1_eff_vat_three_scenarios.png", ///
    replace width(2400) height(1600)

restore

 ********************************************************************************
* FIGURE 2 — Courbes de concentration : trois scenarios + Lorenz + egalite
*
* OBJECTIF :
* Montre visuellement la position distributionnelle de chaque scenario par rapport a
* la courbe de Lorenz :
*   - Courbe de concentration SOUS Lorenz → regressif (Kakwani < 0)
*   - Courbe de concentration AU-DESSUS de Lorenz → progressif (Kakwani > 0)
* Les trois courbes illustrent la sensibilite de la conclusion.
*
* NOTE TECHNIQUE :
* Les courbes sont calculees sur les donnees au niveau menage triees par conso_w.
* Les ponderations sont utilisees pour la part cumulative de population et les sommes cumulatives.
 ********************************************************************************

use "$SILVER/06/fiscal_sensitivity_taxation.dta", clear

* Trier par bien-etre
gsort conso_w

* Part cumulative de population (ponderee)
gen w = hhweight
gen cum_pop = sum(w)
replace cum_pop = cum_pop / cum_pop[_N]

* Courbe de Lorenz (consommation)
gen cum_conso = sum(conso_w * w)
replace cum_conso = cum_conso / cum_conso[_N]

* Courbe de concentration — strict
gen cum_vat_strict = sum(vat_strict * w)
replace cum_vat_strict = cum_vat_strict / cum_vat_strict[_N]

* Courbe de concentration — S2
gen cum_vat_s2 = sum(vat_s2 * w)
replace cum_vat_s2 = cum_vat_s2 / cum_vat_s2[_N]

* Courbe de concentration — S3
gen cum_vat_s3 = sum(vat_s3 * w)
replace cum_vat_s3 = cum_vat_s3 / cum_vat_s3[_N]

twoway ///
    (line cum_conso      cum_pop, ///
        lcolor(black)        lwidth(thick)    lpattern(longdash))       ///
    (line cum_vat_strict cum_pop, ///
        lcolor(maroon)       lwidth(thin)     lpattern(solid))           ///
    (line cum_vat_s2     cum_pop, ///
        lcolor(navy)         lwidth(medthick) lpattern(dash))            ///
    (line cum_vat_s3     cum_pop, ///
        lcolor(forest_green) lwidth(medthick) lpattern(shortdash_dot))   ///
    (line cum_pop        cum_pop, ///
        lcolor(gs10)         lwidth(thin)     lpattern(dot))             ///
    , ///
    legend(order(                                                         ///
        2 "Concentration — Strict (a=1)"                                 ///
        3 "Concentration — S2 (CEI x milieu)"                            ///
        4 "Concentration — S3 (CEI x decile)"                            ///
        1 "Lorenz — consommation"                                         ///
        5 "Ligne d'egalite")                                                ///
        position(5) ring(0) cols(1) size(small))                          ///
    title("Courbes de concentration — TVA sous trois scenarios")             ///
    subtitle("Courbe au-dessus de Lorenz = progressive | Courbe en dessous = regressive") ///
    ytitle("Part cumulative")                                            ///
    xtitle("Part cumulative de la population (classee par consommation)")         ///
    ylabel(0(.2)1, angle(horizontal) labsize(small))                      ///
    xlabel(0(.2)1, labsize(small))                                        ///
    note("Source: EHCVM 2021. Bachas, Gadenne & Jensen (2024, RestUD 91(5)).", ///
        size(vsmall))                                                     ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig2_concentration_curves.png", ///
    replace width(2400) height(1600)
graph save "$FIGS/fig2_concentration_curves.gph"
, ///
    replace width(2400) height(1600)


 ********************************************************************************
* FIGURE 3 — TVA totale par categorie COICOP (descriptif)
*
* OBJECTIF :
* Montre quelles categories de consommation contribuent le plus a la recette TVA totale.
* Totalement descriptif — independant des hypotheses d'informelite.
* Utile pour expliquer pourquoi nourriture/restaurants/soins personnels sont les categories
* pivotales dans l'analyse de sensibilite (grande part + forte pente IEC).
*
* SOURCE: conso_clean.dta (niveau item)
 ********************************************************************************

use "$SILVER/01/conso_clean.dta", clear

gen vat_item_w = depan_w * r_vat_official

preserve
collapse (sum) vat_total = vat_item_w ///
    (sum) conso_total = depan_w ///
    [pw=hhweight], by(coicop)

* Taux effectif par categorie
gen eff_rate_coicop = vat_total / conso_total

* Part de la TVA totale
egen grand_vat = total(vat_total)
gen vat_share = vat_total / grand_vat * 100

* Supprimer non-consommation
drop if coicop == 98 | coicop == 99

gsort -vat_share

graph bar vat_share, over(coicop, sort(1) descending                    ///
        relabel(                                                          ///
            1 "Nourriture/boissons" 2 "Alcool/tabac"  3 "Vetements"           ///
            4 "Logement"          5 "Ameublement" 6 "Sante"              ///
            7 "Transport"        8 "Telecom"      9 "Loisir"          ///
            10 "Education"       11 "Restaurants" 12 "Assurance"          ///
            13 "Soins personnels") label(angle(45)))                         ///
    bar(1, color(navy%80))                                               ///
    title("Part de la recette TVA totale par categorie COICOP",               ///
        size(medium))                                                     ///
    subtitle("Cote d'Ivoire EHCVM 2021 — scenario strict",               ///
        size(small))                                                      ///
    ytitle("Part de la TVA totale (%)", size(small))                        ///
    note("Source: EHCVM 2021. TVA calculee au niveau item (r_vat_official).", ///
        size(vsmall))                                                     ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig3_vat_by_coicop.png", ///
    replace width(2400) height(1600)

restore

 ********************************************************************************
* FIGURE 4 — Profils Alpha par decile pour les categories cles
*
* OBJECTIF :
* Illustre le calibration CEI (Scenario 3) pour les quatre categories COICOP
* les plus analytiquement importantes :
*   - nourriture/boissons (coicop=1)     : pendiente IEC la plus forte, plus grande part budgetaire
*   - restaurants (coicop=11) : pendiente IEC la plus forte, semi-formel
*   - soins personnels (coicop=13): forte pente IEC, grande part (9,56%)
*   - info/comm (coicop=8)    : pendiente IEC la plus plate, quasi-formel partout
*
* Cette figure justifie pourquoi l'hypothese d'informelite importe le plus pour
* nourriture, restaurants et soins personnels — les categories qui驱动ent
* le renversement du signe de Kakwani entre strict et S3.
*
* SOURCE: calcule directement a partir des formules de calibration alpha
 ********************************************************************************

* Construire le profil alpha_3 analytiquement (memes formules qu'en 06_01)
clear
set obs 10
gen decile = _n

* nourriture/boissons : alpha_D1=0.12, slope=0.034
gen alpha_food = 0.12 + (decile - 1) * 0.034

* restaurants : alpha_D1=0.12, slope=0.038
gen alpha_rest = 0.12 + (decile - 1) * 0.038

* soins personnels : alpha_D1=0.15, slope=0.034
gen alpha_care = 0.15 + (decile - 1) * 0.034

* info/comm : alpha_D1=0.78, slope=0.015
gen alpha_tel  = 0.78 + (decile - 1) * 0.015

* Caper a 1
foreach v in alpha_food alpha_rest alpha_care alpha_tel {
    replace `v' = min(`v', 1)
}

twoway ///
    (line alpha_food decile, ///
        lcolor(maroon)       lwidth(medthick) lpattern(solid))          ///
    (line alpha_rest decile, ///
        lcolor(navy)         lwidth(medthick) lpattern(dash))           ///
    (line alpha_care decile, ///
        lcolor(orange)       lwidth(medthick) lpattern(shortdash_dot))  ///
    (line alpha_tel  decile, ///
        lcolor(forest_green) lwidth(medthick) lpattern(longdash))       ///
    , ///
    legend(order(                                                         ///
        1 "Nourriture/boissons (coicop=1)"                                    ///
        2 "Restaurants (coicop=11)"                                      ///
        3 "Soins personnels (coicop=13)"                                    ///
        4 "Telecom/info-comm (coicop=8)")                                ///
        position(5) ring(0) cols(1) size(small))                         ///
    title("Alpha effectif par decile de consommation — Scenario 3",          ///
        size(medium))                                                    ///
    subtitle("Calibration de la Courbe d'Engel de l'Informel (Bachas et al. 2024)", ///
        size(small))                                                     ///
    ytitle("Alpha effectif ({&alpha})", size(small))                    ///
    xtitle("Decile de consommation", size(small))                            ///
    ylabel(0(.1)1, angle(horizontal) labsize(small))                     ///
    xlabel(1(1)10, labsize(small))                                       ///
    yline(1, lcolor(gs12) lpattern(dot))                                 ///
    note("Alpha = taux de transfert effectif de la TVA (0 = entierement informel, 1 = entierement formel)." ///
         " Pentes calibrees a partir des estimations IEC pour les pays a revenu moyen-inf.",       ///
        size(vsmall))                                                    ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig4_alpha_profiles_iec.png", ///
    replace width(2400) height(1600)

 ********************************************************************************
* FIN
 ********************************************************************************