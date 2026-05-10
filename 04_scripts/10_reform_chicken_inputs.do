********************************************************************************
* 10_reform_chicken_inputs.do
*
* OBJECTIF :
* Simuler l'impact distributionnel d'une augmentation de la TVA sur les intrants
* de la production avicole (aliment compose, poussins d'un jour, produits veterinaires)
* en utilisant une approximation du transfert de prix.
*
* ─────────────────────────────────────────────────────────────────────────────
* NOTE METHODOLOGIQUE
* ─────────────────────────────────────────────────────────────────────────────
* Les intrants de production pour la volaille (aliments composes, poussins d'un jour,
* medicaments veterinaires) ne sont PAS observes dans l'EHCVM, qui est une
* enquete de CONSOMMATION FINALE des menages.
*
* La reforme est donc modelisee via son effet sur le PRIX DU POULET
* observe dans l'enquete (codpr 34 — Viande de poulet).
*
* FORMULE DE TRANSMISSION :
*
*   r_reform = α_pt × s_inputs × ΔTVA_inputs
*
* Ou :
*   ΔTVA_inputs  : variation du taux TVA sur les intrants de production (proportion)
*   s_inputs     : part des couts de production composes d'intrants imposables
*   α_pt         : taux de transfert (part de l'augmentation des couts reportee sur le prix)
*   r_reform     : charge de prix effective implicite supplementaire sur le poulet
*
* Ce r_reform est applique comme un taux TVA effectif implicite additionnel sur les
* depenses des menages en poulet (codpr 34).
*
* ─────────────────────────────────────────────────────────────────────────────
* PARAMETRES DE LA REFORME
* ─────────────────────────────────────────────────────────────────────────────
*
* Reforme : appliquer le taux TVA standard de 18% aux intrants avicoles precedent exoneres
*   - Aliments composes pour volailles : actuellement 0% → 18%
*   - Poussins d'un jour               : actuellement 0% → 18%
*   - Medicaments veterinaires         : actuellement 0% → 18%
*
* Structure des couts de production (aviculture industrielle Ouest-Africaine, typique) :
*   - Aliments composes  : ~65% du cout total
*   - Poussins d'un jour : ~18%
*   - Medicaments/vaccins: ~6%
*   → Part des intrants imposables (s_inputs): 0.65 / 0.75 / 0.89 (bas/central/haut)
*
* Trois scenarios de transfert :
*   - Conservateur (S1): α_pt = 0.50  (concurrence imparfaite, absorption partielle)
*   - Central      (S2): α_pt = 0.70  (scenario de reference)
*   - Complet    (S3): α_pt = 1.00  (marche parfaitement concurrentiel, transfert complet)
*
* ─────────────────────────────────────────────────────────────────────────────
* PRODUITS CONCERNES
* ─────────────────────────────────────────────────────────────────────────────
*   codpr 34 : Viande de poulet         (canal principal — achats sur marche)
*   codpr 33 : Poulet sur pied          (secondaire — si achete)
*   codpr 35 : Autres volailles         (secondaire — si achete)
*
* ─────────────────────────────────────────────────────────────────────────────
* SORTIES
* ─────────────────────────────────────────────────────────────────────────────
*   - Part budgetaire du poulet par decile
*   - Taux TVA effectif implicite sur le poulet par decile, pour chaque scenario
*   - Variation de la charge TVA des menages par decile (FCFA et % de consommation)
*   - Gain de recette fiscale estime
*   - Evaluation distributionnelle (progressif / regressif ?)
*
* AUTEUR : CAE — ANStat · Avril 2026
 ********************************************************************************

clear all
set more off

 ********************************************************************************
* ETAPE 0 — Parametres de la reforme
 ********************************************************************************

* Variation de TVA sur les intrants (proportion)
scalar delta_vat_inputs = 0.18     // 0% → 18% taux standard

* Parts des couts d'intrants (proportion du cout total de production)
scalar s_inputs_low     = 0.65     // conservatif : uniquement aliments composes
scalar s_inputs_central = 0.75     // central : aliments + poussins
scalar s_inputs_high    = 0.89     // haut : aliments + poussins + medicaments

* Taux de transfert
scalar alpha_low        = 0.50     // absorption partielle (concurrence imperfaite)
scalar alpha_central    = 0.70     // scenario de reference
scalar alpha_full       = 1.00     // transfert complet (marche concurrentiel)

* Taux de reforme implicites : r_reform = alpha × s_inputs × delta_vat
* Scenario central (reference) :
scalar r_reform_central = alpha_central * s_inputs_central * delta_vat_inputs

di as text "─────────────────────────────────────────"
di as text " Scenarios de reforme — impact sur le prix"
di as text "─────────────────────────────────────────"
di as text " S1 Conservateur  : " %5.2f (alpha_low    * s_inputs_low    * delta_vat_inputs * 100) "%"
di as text " S2 Central      : " %5.2f (alpha_central * s_inputs_central * delta_vat_inputs * 100) "%"
di as text " S3 Transfert comp.: " %5.2f (alpha_full   * s_inputs_high   * delta_vat_inputs * 100) "%"
di as text "─────────────────────────────────────────"

 ********************************************************************************
* ETAPE 1 — Charger les donnees au niveau produit (post-mapping)
 ********************************************************************************

use "$SILVER/01/conso_clean.dta", clear

 ********************************************************************************
* ETAPE 2 — Identifier les produits poulet et calculer les parts budgetaires
 ********************************************************************************

* Flag les produits avicolas concernes par la reforme
gen poultry = inlist(code, 34, 33, 35)
label variable poultry "Produit avicole (affecte par la reforme)"

* Depense en poulet au niveau item
gen depan_poultry = depan_w * poultry
label variable depan_poultry "Depense en poulet (winsorisee)"

* TVA de base au niveau item (necessaire pour l'agregation au niveau menage plus tard)
gen vat_item_w = depan_w * r_vat_official

* Agregats au niveau menage a partir des donnees au niveau produit
bys hhid: egen conso_w_hh = total(depan_w)
label variable conso_w_hh "Consommation totale du menage (winsorisee)"

* Classement des deciles sur la consommation du menage
xtile decile = conso_w_hh [pw=hhweight], n(10)

label define dec_lbl 1 "D1 le plus pauvre" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 le plus riche", replace
label values decile dec_lbl

 ********************************************************************************
* ETAPE 3 — Part budgetaire du poulet par decile
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w                           ///
    (sum)  poul_tot   = depan_poultry         ///
    [pw=hhweight], by(decile)

gen share_poultry = poul_tot / conso_w * 100
label variable share_poultry "Part budgetaire du poulet (%)"

di as text ""
di as text "─────────────────────────────────────────────────────────────"
di as text " Part budgetaire du poulet par decile de bien-etre"
di as text "─────────────────────────────────────────────────────────────"
list decile share_poultry, noobs sep(0)

export excel using "$TABLES/10/10_poultry_budget_share.xlsx", ///
    firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 4 — Appliquer la reforme : calculer la charge TVA additionnelle sous 3 scenarios
 ********************************************************************************

* S1 — Conservateur
gen r_reform_s1 = (alpha_low    * s_inputs_low    * delta_vat_inputs) * poultry
gen vat_reform_s1 = depan_w * r_reform_s1
label variable vat_reform_s1 "Charge TVA additionnelle — S1 conservateur"

* S2 — Central (reference)
gen r_reform_s2 = (alpha_central * s_inputs_central * delta_vat_inputs) * poultry
gen vat_reform_s2 = depan_w * r_reform_s2
label variable vat_reform_s2 "Charge TVA additionnelle — S2 central"

* S3 — Transfert complet
gen r_reform_s3 = (alpha_full   * s_inputs_high   * delta_vat_inputs) * poultry
gen vat_reform_s3 = depan_w * r_reform_s3
label variable vat_reform_s3 "Charge TVA additionnelle — S3 transfert complet"

 ********************************************************************************
* ETAPE 5 — Agregation au niveau menage
 ********************************************************************************

sort hhid
by hhid: egen vat_baseline = total(vat_item_w)
by hhid: egen dpoul        = total(depan_poultry)
by hhid: gen  hh_tag       = (_n == 1)

by hhid: egen add_vat_s1 = total(vat_reform_s1)
by hhid: egen add_vat_s2 = total(vat_reform_s2)
by hhid: egen add_vat_s3 = total(vat_reform_s3)

keep if hh_tag == 1

* TVA totale apres reforme
gen vat_post_s1 = vat_baseline + add_vat_s1
gen vat_post_s2 = vat_baseline + add_vat_s2
gen vat_post_s3 = vat_baseline + add_vat_s3

* Taux TVA effectif
gen eff_vat_base = vat_baseline  / conso_w_hh
gen eff_vat_s1   = vat_post_s1   / conso_w_hh
gen eff_vat_s2   = vat_post_s2   / conso_w_hh
gen eff_vat_s3   = vat_post_s3   / conso_w_hh

* Variation du taux TVA effectif
gen delta_eff_s1 = eff_vat_s1 - eff_vat_base
gen delta_eff_s2 = eff_vat_s2 - eff_vat_base
gen delta_eff_s3 = eff_vat_s3 - eff_vat_base

label variable eff_vat_base "Taux TVA effectif — base"
label variable eff_vat_s1   "Taux TVA effectif — post-reforme S1"
label variable eff_vat_s2   "Taux TVA effectif — post-reforme S2"
label variable eff_vat_s3   "Taux TVA effectif — post-reforme S3"
label variable delta_eff_s1 "Variation du taux TVA effectif — S1"
label variable delta_eff_s2 "Variation du taux TVA effectif — S2"
label variable delta_eff_s3 "Variation du taux TVA effectif — S3"

 ********************************************************************************
* ETAPE 6 — Resultats distributionnels par decile
 ********************************************************************************

preserve
collapse ///
    (mean) conso_w_hh dpoul                            ///
    (mean) eff_vat_base eff_vat_s1 eff_vat_s2 eff_vat_s3 ///
    (mean) delta_eff_s1 delta_eff_s2 delta_eff_s3         ///
    (sum)  add_vat_tot_s1 = add_vat_s1                    ///
    (sum)  add_vat_tot_s2 = add_vat_s2                    ///
    (sum)  add_vat_tot_s3 = add_vat_s3                    ///
    [pw=hhweight], by(decile)

* Part de la charge fiscale additionnelle supportee par chaque decile
foreach s in s1 s2 s3 {
    egen total_add_`s' = total(add_vat_tot_`s')
    gen share_burden_`s' = add_vat_tot_`s' / total_add_`s' * 100
    label variable share_burden_`s' "Part de la charge TVA additionnelle — `s' (%)"
    drop total_add_`s'
}

di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Impact distributionnel — S2 Scenario central"
di as text " (α=0.70 × s_inputs=0.75 × ΔTVA=18% → ~9.45% impact prix)"
di as text "─────────────────────────────────────────────────────────────────────"
list decile eff_vat_base eff_vat_s2 delta_eff_s2 share_burden_s2, noobs sep(0)

cap mkdir "$TABLES/10"
export excel using "$TABLES/10/10_reform_distributional_results.xlsx", ///
    firstrow(variables) replace

save "$SILVER/06/reform_chicken_inputs.dta", replace
restore

 ********************************************************************************
* ETAPE 7 — Estimation de la recette fiscale
 ********************************************************************************

preserve
collapse ///
    (sum) add_vat_s1 add_vat_s2 add_vat_s3 ///
    [pw=hhweight]

di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Recette fiscale additionnelle estimee (unites d'enquete, ponderee)"
di as text "─────────────────────────────────────────────────────────────────────"
di as text " S1 Conservateur  : " add_vat_s1
di as text " S2 Central      : " add_vat_s2
di as text " S3 Complet      : " add_vat_s3
di as text "─────────────────────────────────────────────────────────────────────"
restore

 ********************************************************************************
* ETAPE 8 — Indice de Kakwani de progressivite de la reforme (3 scenarios)
*
* OBJECTIF :
* Mesure synthetique unique de l'impact distributionnel.
* Kakwani = CI(charge de la reforme) − Gini(consommation avant impots)
*   Kakwani < 0 → la reforme est REGRESSIVE (les pauvres supportent une charge relative plus grande)
*   Kakwani > 0 → la reforme est PROGRESSIVE
*
* METHODE :
* Indice de concentration via la formule generalisee (O'Donnell et al. 2008) :
*   CI = 2/μ × cov_w(t_i, F_i)
*     ou F_i = rang fractionnaire pondere dans la distribution de consommation
*     et   μ   = moyenne ponderee de la variable d'interet
*
* Calcule au niveau menage (avant l'agregation par decile) en utilisant les ponderations d'enquete.
 ********************************************************************************

* Trier par consommation pre-reforme pour definir le classement de bien-etre
sort conso_w_hh

* Rang fractionnaire pondere — regle du point median : F_i = (CW_{i-1} + w_i/2) / W
gen cumw_rank  = sum(hhweight)
local totw_kak = cumw_rank[_N]
gen frac_rank  = (cumw_rank - hhweight / 2) / `totw_kak'

* ── Gini de la consommation pre-impots ─────────────────────────────────────────────
sum conso_w_hh [aw=hhweight]
local mu_c = r(mean)

gen w_xF_c = hhweight * (conso_w_hh / `mu_c') * frac_rank
sum w_xF_c
local Gini_c = 2 * r(sum) / `totw_kak' - 1
drop w_xF_c

* ── Indice de concentration et Kakwani pour chaque scenario ───────────────────────
foreach sc in s1 s2 s3 {
    sum add_vat_`sc' [aw=hhweight]
    local mu_t = r(mean)
    gen w_tF_`sc' = hhweight * (add_vat_`sc' / `mu_t') * frac_rank
    sum w_tF_`sc'
    local CI_`sc'      = 2 * r(sum) / `totw_kak' - 1
    local Kakwani_`sc' = `CI_`sc'' - `Gini_c'
    drop w_tF_`sc'
}

drop cumw_rank frac_rank

* ── Affichage ─────────────────────────────────────────────────────────────────
di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Indice de Kakwani — progressivite de la reforme sur les intrants avicoles"
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Gini (consommation pre-reforme) : " as result %6.4f `Gini_c'
di as text ""
di as text "             CI(reforme)   Kakwani   Direction"
foreach sc in s1 s2 s3 {
    local dir = cond(`Kakwani_`sc'' < 0, "REGRESSIVE", ///
                cond(`Kakwani_`sc'' > 0, "PROGRESSIVE", "PROPORTIONNEL"))
    di as text " `sc'   " as result %9.4f `CI_`sc'' as text "  " ///
                          as result %9.4f `Kakwani_`sc'' as text "  `dir'"
}
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Note : Kakwani < 0 → les pauvres supportent une part proportionnellement plus grande de la charge."

* ── Exporter les resultats Kakwani ───────────────────────────────────────────────────
preserve
clear
set obs 3
gen str3 scenario     = ""
gen      gini_cons    = `Gini_c'
gen      ci_reform    = .
gen      kakwani      = .
replace scenario   = "S1" in 1
replace scenario   = "S2" in 2
replace scenario   = "S3" in 3
replace ci_reform  = `CI_s1'      in 1
replace ci_reform  = `CI_s2'      in 2
replace ci_reform  = `CI_s3'      in 3
replace kakwani    = `Kakwani_s1' in 1
replace kakwani    = `Kakwani_s2' in 2
replace kakwani    = `Kakwani_s3' in 3
gen str15 direction = cond(kakwani < 0, "Regressive", ///
                      cond(kakwani > 0, "Progressive", "Proportional"))
export excel using "$TABLES/10/10_reform_kakwani.xlsx", firstrow(variables) replace
restore

 ********************************************************************************
* ETAPE 9 — Evaluation distributionnelle : la reforme est-elle regressive ?
 ********************************************************************************
* Verif rapide au niveau decile : comparer D1 vs D10 variation du taux effectif.

use "$SILVER/06/reform_chicken_inputs.dta", clear
sort decile

di as text ""
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Verif de regressivite — S2 Scenario central"
di as text "─────────────────────────────────────────────────────────────────────"
di as text " Δ taux effectif D1  (le plus pauvre) : " %6.4f delta_eff_s2[1]
di as text " Δ taux effectif D10 (le plus riche) : " %6.4f delta_eff_s2[10]

if delta_eff_s2[1] > delta_eff_s2[10] {
    di as error " → REGRESSIVE : les menages pauvres supportent une charge proportionnellement plus grande"
}
else if delta_eff_s2[1] < delta_eff_s2[10] {
    di as result " → PROGRESSIVE : les menages riches supportent une charge proportionnellement plus grande"
}
else {
    di as text " → PROPORTIONNEL : la charge est egale a travers les deciles"
}
di as text "─────────────────────────────────────────────────────────────────────"

 ********************************************************************************
* ETAPE 10 — Tableau croise de sensibilite : grille α × s_inputs
*
* OBJECTIF :
* Cartographie tout l'espace des parametres (4 taux de transfert × 3 parts d'intrants).
* Montre que la direction de la regressivite est robuste a ces hypotheses :
* elle est determinee uniquement par les parts budgetaires (dpoul/conso), pas par les echelles.
* Le tableau rapport e la variation de grandeur utile pour une section de robustesse d'un document de travail.
*
* NOTE : les ratios de parts budgetaires (D1 vs D10) sont constants a travers toutes les combinaisons (α, s),
* donc le signe de Kakwani ne changera pas — seulement sa grandeur.
 ********************************************************************************

* Part budgetaire du poulet par decile (ratio dpoul / conso_w_hh)
* decile 1 = row 1, decile 10 = row 10 apres tri
local bs_d1  = dpoul[1]  / conso_w_hh[1]
local bs_d10 = dpoul[10] / conso_w_hh[10]

di as text ""
di as text " Part budgetaire poulet — D1 (le plus pauvre) : " as result %5.3f `bs_d1'  * 100 as text "%"
di as text " Part budgetaire poulet — D10 (le plus riche): " as result %5.3f `bs_d10' * 100 as text "%"

* Construire la matrice de resultats sur 12 lignes (4 alphas × 3 parts)
matrix SENS = J(12, 5, .)
local row = 0

foreach a_int in 30 50 70 100 {
    foreach s_int in 65 75 89 {
        local ++row
        local a = `a_int' / 100
        local s = `s_int' / 100
        local r = `a' * `s' * 0.18

        matrix SENS[`row', 1] = `a'
        matrix SENS[`row', 2] = `s'
        matrix SENS[`row', 3] = `r' * 100
        matrix SENS[`row', 4] = `bs_d1'  * `r' * 100   // Δeff D1  (pp)
        matrix SENS[`row', 5] = `bs_d10' * `r' * 100   // Δeff D10 (pp)
    }
}

* Affichage
di as text ""
di as text "───────────────────────────────────────────────────────────────────────────"
di as text " Tableau croise de sensibilite — variation du taux TVA effectif (pp) par scenario"
di as text "───────────────────────────────────────────────────────────────────────────"
di as text "  α(transfert)   s(part intrants)  Impact prix  Δeff_D1   Δeff_D10  Regress.?"
di as text "───────────────────────────────────────────────────────────────────────────"

forvalues row = 1/12 {
    local a_v   = SENS[`row', 1]
    local s_v   = SENS[`row', 2]
    local r_v   = SENS[`row', 3]
    local d1_v  = SENS[`row', 4]
    local d10_v = SENS[`row', 5]
    local reg   = cond(`d1_v' > `d10_v', "Oui", "Non")
    di as text "  " %4.2f `a_v' "        " %4.2f `s_v' "        " ///
               %5.2f `r_v' "%      " %6.4f `d1_v' "    " %6.4f `d10_v' "    `reg'"
}
di as text "───────────────────────────────────────────────────────────────────────────"

* Exporter
preserve
clear
svmat SENS, names(col)
rename (c1 c2 c3 c4 c5) (alpha s_inputs price_impact_pct delta_eff_d1_pp delta_eff_d10_pp)
gen str3 regressive = cond(delta_eff_d1_pp > delta_eff_d10_pp, "Oui", "Non")
export excel using "$TABLES/10/10_reform_sensitivity.xlsx", firstrow(variables) replace
restore

di as text ""
di as text " Tableau de sensibilite exporte → $TABLES/10/10_reform_sensitivity.xlsx"

 ********************************************************************************
* FIN
 ********************************************************************************
di as result "=================================================="
di as result " SIMULATION DE REFORME TERMINEE"
di as result "=================================================="