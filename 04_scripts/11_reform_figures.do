********************************************************************************
* 11_reform_figures.do
*
* OBJECTIF :
* Produire toutes les figures pour la simulation de la reforme TVA sur les intrants avicoles.
*
* CONTENU :
* Fig R1 — Part budgetaire du poulet par decile (barres)
*           → montre qui consomme du poulet, en % du budget total
* Fig R2 — Variation du taux TVA effectif par decile : 3 scenarios (ligne)
*           → figure distributionnelle principale — regressif si pentes descendantes
* Fig R3 — Taux TVA effectif avant vs apres reforme — S2 central (ligne)
*           → montre l'ampleur du deplacement par decile
* Fig R4 — Part de la charge fiscale additionnelle par decile — S2 (barres)
*           → qui paie la nouvelle recette ? gauche-lourde = regressif
*
* DONNEES : $SILVER/06/reform_chicken_inputs.dta  (niveau decile, du script 10)
*
* SORTIES :
*   - $FIGS/figR1_poultry_budget_share.png
*   - $FIGS/figR2_delta_eff_vat_scenarios.png
*   - $FIGS/figR3_eff_vat_before_after.png
*   - $FIGS/figR4_burden_share_by_decile.png
*
* AUTEUR : CAE — ANStat · Avril 2026
 ********************************************************************************

set scheme s1color
use "$SILVER/06/reform_chicken_inputs.dta", clear

* Calculer la part budgetaire du poulet
gen budget_share_poultry = dpoul / conso_w_hh * 100
label variable budget_share_poultry "Part budgetaire du poulet (% de la consommation totale)"

* Etiquettes de decile pour l'axe x
label define dec_lbl 1 "D1" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10", replace
label values decile dec_lbl

 ********************************************************************************
* FIGURE R1 — Part budgetaire du poulet par decile
*
* OBJECTIF :
* Etablit le pattern de consommation de base : le poulet represente-t-il une
* plus grande part du budget pour les menages pauvres ou riches ?
* Cela determine qui sera le plus affecte par une augmentation de prix.
 ********************************************************************************

graph bar budget_share_poultry, over(decile, label(angle(0) labsize(small))) ///
    bar(1, color(maroon%75))                                                  ///
    title("Part budgetaire du poulet par decile de bien-etre",                        ///
        size(medium))                                                         ///
    subtitle("Cote d'Ivoire EHCVM 2021 — achats sur marche uniquement",              ///
        size(small))                                                          ///
    ytitle("Part du budget du menage (%)", size(small))                      ///
    xtitle("Decile de consommation (D1=le plus pauvre, D10=le plus riche)", size(small))       ///
    blabel(bar, format(%4.2f) size(vsmall))                                   ///
    note("Produits : codpr 34 (viande de poulet), 33 (poulet sur pied), 35 (autres volailles)." ///
         " Source : EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR1_poultry_budget_share.png", replace width(2400) height(1600)
graph save   "$FIGS/figR1_poultry_budget_share.gph", replace

 ********************************************************************************
* FIGURE R2 — Variation du taux TVA effectif par decile : 3 scenarios
*
* OBJECTIF :
* Figure distributionnelle principale de la reforme.
* Un profil descendant signifie que la reforme est REGRESSIVE — les menages pauvres
* supportent une charge additionnelle plus grande en part de leur consommation totale.
* L'ecart entre les scenarios illustre la sensibilite aux hypotheses de transfert
* et de part des couts d'intrants.
 ********************************************************************************

twoway ///
    (line delta_eff_s1 decile,                                               ///
        lcolor(navy)        lwidth(medthick) lpattern(dash))                  ///
    (line delta_eff_s2 decile,                                               ///
        lcolor(maroon)      lwidth(thick)    lpattern(solid))                 ///
    (line delta_eff_s3 decile,                                               ///
        lcolor(forest_green) lwidth(medthick) lpattern(shortdash_dot))        ///
    (scatteri 0 1 0 10, recast(line) lcolor(gs12) lwidth(thin) lpattern(dot)) ///
    , ///
    legend(order(                                                             ///
        1 "S1 Conservateur ({&alpha}=0.50, s=0.65) — ~5.9% impact prix"    ///
        2 "S2 Central ({&alpha}=0.70, s=0.75) — ~9.5% impact prix"         ///
        3 "S3 Transfert complet ({&alpha}=1.00, s=0.89) — ~16.0% impact prix") ///
        position(6) rows(3) size(small))                                      ///
    title("Variation du taux TVA effectif — reforme sur les intrants avicoles",              ///
        size(medium))                                                         ///
    subtitle("Impact de l'application de la TVA 18% aux aliments composes, poussins d'un jour et produits veterinaires", ///
        size(small))                                                          ///
    ytitle("{&Delta} Taux TVA effectif (pp)", size(small))                   ///
    xtitle("Decile de consommation (D1=le plus pauvre, D10=le plus riche)", size(small))       ///
    xlabel(1(1)10, labsize(small))                                            ///
    ylabel(, angle(horizontal) labsize(small))                                ///
    yline(0, lcolor(black) lwidth(vthin))                                     ///
    note("Reforme : 0% → 18% TVA sur les intrants de production avicole." ///
         " Transmission : {&Delta}p = {&alpha} {&times} s_inputs {&times} {&Delta}VAT." ///
         " Source : EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR2_delta_eff_vat_scenarios.png", replace width(2400) height(1600)
graph save   "$FIGS/figR2_delta_eff_vat_scenarios.gph", replace

 ********************************************************************************
* FIGURE R3 — Taux TVA effectif avant vs apres reforme (S2 central)
*
* OBJECTIF :
* Montre le deplacement absolu du taux TVA effectif de la base a la post-reforme
* sous le scenario central. Place la reforme dans le contexte de la charge
* fiscale globale deja supportee par chaque decile.
 ********************************************************************************

twoway ///
    (line eff_vat_base decile,                                               ///
        lcolor(gs8)    lwidth(medthick) lpattern(longdash))                   ///
    (line eff_vat_s2   decile,                                               ///
        lcolor(maroon) lwidth(thick)    lpattern(solid))                      ///
    , ///
    legend(order(                                                             ///
        1 "Base (pre-reforme)"                                             ///
        2 "Post-reforme — S2 Central ({&alpha}=0.70)")                         ///
        position(6) rows(2) size(small))                                      ///
    title("Taux TVA effectif avant et apres reforme — S2 Central",          ///
        size(medium))                                                         ///
    subtitle("Cote d'Ivoire EHCVM 2021", size(small))                         ///
    ytitle("Taux TVA effectif (TVA / consommation totale)", size(small))       ///
    xtitle("Decile de consommation (D1=le plus pauvre, D10=le plus riche)", size(small))       ///
    xlabel(1(1)10, labsize(small))                                            ///
    ylabel(, angle(horizontal) labsize(small))                                ///
    note("Reforme : TVA 18% sur les intrants de production avicole, 70% de transfert, 75% de cout d'intrants." ///
         " Source : EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR3_eff_vat_before_after.png", replace width(2400) height(1600)
graph save   "$FIGS/figR3_eff_vat_before_after.gph", replace

 ********************************************************************************
* FIGURE R4 — Part de la charge fiscale additionnelle par decile (S2 central)
*
* OBJECTIF :
* Repond a la question : qui paie la nouvelle recette ?
* Si D1–D5 supportent plus de 50% de la charge additionnelle totale → regressif.
* Complete la Figure R2 (qui montre les taux) avec les parts absolues de la recette.
 ********************************************************************************

* Charge cumulative pour D1-D5 annotation
egen cum_d1d5 = total(share_burden_s2) if decile <= 5
qui sum cum_d1d5
local cum_poor = string(round(r(mean), 0.1)

graph bar share_burden_s2, over(decile, label(angle(0) labsize(small)))       ///
    bar(1, color(navy%75))                                                    ///
    title("Part de la charge fiscale additionnelle par decile — S2 Central",         ///
        size(medium))                                                         ///
    subtitle("Qui paie la recette additionnelle de la reforme ?",               ///
        size(small))                                                          ///
    ytitle("Part de la recette TVA additionnelle totale (%)", size(small))          ///
    xtitle("Decile de consommation (D1=le plus pauvre, D10=le plus riche)", size(small))       ///
    blabel(bar, format(%4.1f) size(vsmall))                                   ///
    yline(10, lcolor(gs12) lpattern(dot)                                      ///
        text(10.3 5.5 "Part egale = 10%/decile", size(vsmall) color(gs8)))  ///
    note("D1–D5 (moitie inferieure) part cumulative : `cum_poor'%." ///
         " Reforme : TVA 18% sur les intrants avicoles, {&alpha}=0.70, s=0.75." ///
         " Source : EHCVM 2021.", size(vsmall))                                ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/figR4_burden_share_by_decile.png", replace width(2400) height(1600)
graph save   "$FIGS/figR4_burden_share_by_decile.gph", replace

 ********************************************************************************
* FIN
 ********************************************************************************

di as result "=================================================="
di as result " FIGURES DE REFORME TERMINEES — 4 figures exportees"
di as result "  figR1 : Part budgetaire du poulet par decile"
di as result "  figR2 : Variation du taux TVA effectif — 3 scenarios"
di as result "  figR3 : Taux TVA effectif avant vs apres — S2"
di as result "  figR4 : Part de la charge fiscale par decile — S2"
di as result "=================================================="