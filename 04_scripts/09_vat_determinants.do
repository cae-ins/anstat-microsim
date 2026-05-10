********************************************************************************
* 09_determinants.do
*
* OBJECTIF :
* Analyser les determinants socio-demographiques de l'exposition des menages a la TVA,
* coheremment avec le cadre d'informelite etabli en 06_01.
*
* ────────────────────────────────────────────────────────────────────────────
* JUSTIFICATION ANALYTIQUE
* ────────────────────────────────────────────────────────────────────────────
*
* L'analyse de robustesse (06_01) a montre que la conclusion distributive
* depend entierement du transfert effectif de TVA (alpha). La question naturelle
* suivante est :
*
*   "Quelles caracteristiques du menage predisent un alpha effectif plus faible
*    — c'est-a-dire une plus grande protection de la TVA par l'achat informel ?"
*
* Cela reformule l'analyse de "qui paie plus de TVA ?" (scenario strict,
* mecaniquement determine par le niveau de consommation) a "qui est effectivement protege
* de la TVA par l'informelite ?" — une question plus pertinente pour les politiques.
*
* ────────────────────────────────────────────────────────────────────────────
* VARIABLES DEPENDANTES
* ────────────────────────────────────────────────────────────────────────────
*
* Trois variables dependantes, un par scenario :
*
*   (1) eff_vat_strict : taux TVA effectif sous taxation complete (alpha=1)
*        reference, capture l'exposition fiscale structurelle
*
*   (2) eff_vat_s2 : taux TVA effectif sous CEI × milieu
*        capture le canal informelite urbain/rural
*
*   (3) eff_vat_s3 : taux TVA effectif sous CEI × decile (IEC calibree)
*        capture le canal informelite lie au revenu
*
* La comparaison des coefficients a travers les trois specifications teste si les
* determinants de l'exposition fiscale sont robustes a l'hypothese d'informelite.
*
* ────────────────────────────────────────────────────────────────────────────
* VARIABLES CLES
* ────────────────────────────────────────────────────────────────────────────
*
* Variables independantes d'interet :
*   - lconso_w   : log de la consommation totale (proxy du bien-etre)
*   - milieu     : urbain/rural (1=urbain, 2=rural)
*   - hhsize     : taille du menage
*   - heduc      : education du chef de menage
*   - hgender    : genre du chef de menage
*   - region     : region geographique (effets fixes)
*   - n_items    : diversification de la consommation (nombre d'items declares)
*
* NOTE SUR n_items :
* n_items est retenu comme proxy de la diversification de la consommation mais son
* interpretation necessite precaution : il est correle avec lconso_w
* (les menages plus riches declarent plus d'items). Le VIF est verifie systematiquement.
*
* ────────────────────────────────────────────────────────────────���───────────
* STRATEGIE D'ESTIMATION
* ────────────────────────────────────────────────────────────────────────────
*
* MCO avec erreurs types robustes par grappe (PSU).
* Pondurations d'enquete (hhweight) tout au long.
* Donnees reduites au niveau menage AVANT les regressions.
*
* Quatre modeles embotes par variable dependante :
*   M1 : bivarie (lconso_w seulement)
*   M2 : + demographiques du menage
*   M3 : + milieu + effets fixes region
*   M4 : M3 + n_items (diversification)
*
* Robustesse : coefficients compares a travers les trois variables dependantes.
* Si coefficients stables entre eff_vat_strict / s2 / s3 → robustes.
* Si coefficients changent de signe → l'hypothese d'informelite importe.
 ********************************************************************************

use "$SILVER/06/fiscal_sensitivity_taxation.dta", clear
by hhid: egen n_items = count(produit)
by hhid: gen hh_tag = (_n == 1)
keep if hh_tag == 1
drop hh_tag
sort hhid
* Fusionner les variables socio-demographiques
merge 1:1 hhid using "$DATA/ehcvm_welfare_civ2021", ///
    keepusing(hhsize hgender hage heduc  halfa2 grappe region) ///
    keep(3) nogen

 ********************************************************************************
* ETAPE 0 — Validation
 ********************************************************************************

assert !missing(hhid, hhweight, conso_w)
assert !missing(eff_vat_strict, eff_vat_s2, eff_vat_s3)
assert !missing(milieu, region, hhsize)

* Confirmer les donnees au niveau menage
duplicates report hhid

 ********************************************************************************
* ETAPE 1 — Construction des variables
 ********************************************************************************

* Log de la consommation
gen lconso_w = log(conso_w)
label variable lconso_w "Log de la consommation totale (winsorisee)"

* Education du chef de menage — binaire : secondaire ou plus
gen educ_high = (heduc >= 4) if !missing(heduc)
label variable educ_high "Le chef a un education secondaire ou plus"
label define educ_lbl 0 "Primaire ou moins" 1 "Secondaire ou plus"
label values educ_high educ_lbl

* Genre du chef
gen head_female = (hgender == 2) if !missing(hgender)
label variable head_female "Menage dirige par une femme"

* Categories de taille du menage
gen hhsize_cat = .
replace hhsize_cat = 1 if hhsize <= 2
replace hhsize_cat = 2 if hhsize >= 3 & hhsize <= 5
replace hhsize_cat = 3 if hhsize >= 6 & hhsize <= 9
replace hhsize_cat = 4 if hhsize >= 10
label define hhs_lbl 1 "1-2 personnes" 2 "3-5 personnes" ///
    3 "6-9 personnes" 4 "10+ personnes"
label values hhsize_cat hhs_lbl
label variable hhsize_cat "Categorie de taille du menage"

* Dummy urbain
gen urban = (milieu == 1) if !missing(milieu)
label variable urban "Menage urbain (milieu=1)"
label define urb_lbl 0 "Rural" 1 "Urbain"
label values urban urb_lbl

 ********************************************************************************
* ETAPE 2 — Statistiques descriptives
 ********************************************************************************

* Verifier la collinearite entre n_items et lconso_w
corr n_items lconso_w
di "Correlation n_items / lconso_w = " r(rho)

* Resume des variables dependantes
sum eff_vat_strict eff_vat_s2 eff_vat_s3, detail

* Taux effectifs moyens par milieu
tabstat eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [aw=hhweight], by(milieu) stat(mean sd) nototal

* Taux effectifs moyens par education
tabstat eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [aw=hhweight], by(educ_high) stat(mean sd) nototal

 ********************************************************************************
* ETAPE 3 — Regressions de base : taux TVA effectif (strict)
*
* OBJECTIF :
* Etablit les determinants structurels de l'exposition fiscale sous
* taxation complete. Point de reference pour la comparaison avec S2 et S3.
 ********************************************************************************

di as result "══════════════════════════════════════════════════"
di as result "  PANEL A — Variable dependante : eff_vat_strict"
di as result "══════════════════════════════════════════════════"

* M1 : bivarie — gradient de revenu uniquement
eststo m1_strict: reg eff_vat_strict ///
    lconso_w ///
    [pw=hhweight], vce(cluster grappe)

* M2 : + demographiques du menage
eststo m2_strict: reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high ///
    [pw=hhweight], vce(cluster grappe)

* M3 : + milieu + region FE
eststo m3_strict: reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

* M4 : + diversification
eststo m4_strict: reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high ///
    urban i.region n_items ///
    [pw=hhweight], vce(cluster grappe)

* VIF check sur M4
quietly reg eff_vat_strict ///
    lconso_w hhsize head_female educ_high urban n_items ///
    [pw=hhweight]
estat vif
* Regle empirique : VIF > 10 signale une collinearite problematique

 ********************************************************************************
* ETAPE 4 — Regressions : taux TVA effectif (S2 — CEI × milieu)
*
* OBJECTIF :
* Teste si les memes determinants held lorsque l'informelite urbain/rural
* est incorpore. Question cle : le coefficient urbain change-t-il de signe
* ou de grandeur par rapport a strict ?
* Si le coefficient urbain augmente → premium urbain en formalite confirme.
 ********************************************************************************

di as result "══════════════════════════════════════════════════"
di as result "  PANEL B — Variable dependante : eff_vat_s2"
di as result "══════════════════════════════════════════════════"

eststo m1_s2: reg eff_vat_s2 ///
    lconso_w ///
    [pw=hhweight], vce(cluster grappe)

eststo m2_s2: reg eff_vat_s2 ///
    lconso_w hhsize head_female educ_high ///
    [pw=hhweight], vce(cluster grappe)

eststo m3_s2: reg eff_vat_s2 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

eststo m4_s2: reg eff_vat_s2 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region n_items ///
    [pw=hhweight], vce(cluster grappe)

 ********************************************************************************
* ETAPE 5 — Regressions : taux TVA effectif (S3 — CEI × decile)
*
* OBJECTIF :
* Teste les determinants sous le scenario calibree IEC.
* Question cle : le gradient de revenu (coefficient lconso_w) augmente-t-il
* par rapport a strict et S2 ?
* Si oui → les menages plus riches font face a un taux effectif proportionnellement plus eleve
* via l'achat formel, independamment des demographiques.
 ********************************************************************************

di as result "══════════════════════════════════════════════════"
di as result "  PANEL C — Variable dependante : eff_vat_s3"
di as result "══════════════════════════════════════════════════"

eststo m1_s3: reg eff_vat_s3 ///
    lconso_w ///
    [pw=hhweight], vce(cluster grappe)

eststo m2_s3: reg eff_vat_s3 ///
    lconso_w hhsize head_female educ_high ///
    [pw=hhweight], vce(cluster grappe)

eststo m3_s3: reg eff_vat_s3 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

eststo m4_s3: reg eff_vat_s3 ///
    lconso_w hhsize head_female educ_high ///
    urban i.region n_items ///
    [pw=hhweight], vce(cluster grappe)

 ********************************************************************************
* ETAPE 6 — Exporter les tableaux de regression
*
* Trois panneaux exportes : strict, s2, s3
* Chaque panneau : M1 a M4
* Coefficients comparables entre panneaux pour evaluer la sensibilite a l'informelite
 ********************************************************************************

capture which esttab
if _rc ssc install estout

* Panel A — strict
esttab m1_strict m2_strict m3_strict m4_strict ///
    using "$TABLES/09_reg_panel_strict.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    order(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    title("Panel A: Determinants of eff_vat_strict") ///
    mtitles("M1" "M2" "M3" "M4") ///
    note("Cluster-robust SE at grappe level. Survey weights.")

* Panel B — s2
esttab m1_s2 m2_s2 m3_s2 m4_s2 ///
    using "$TABLES/09/09_reg_panel_s2.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    order(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    title("Panel B: Determinants of eff_vat_s2 (CEI x milieu)") ///
    mtitles("M1" "M2" "M3" "M4") ///
    note("Cluster-robust SE at grappe level. Survey weights.")

* Panel C — s3
esttab m1_s3 m2_s3 m3_s3 m4_s3 ///
    using "$TABLES/09/09_reg_panel_s3.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    order(lconso_w hhsize head_female educ_high urban n_items _cons) ///
    title("Panel C: Determinants of eff_vat_s3 (CEI x decile)") ///
    mtitles("M1" "M2" "M3" "M4") ///
    note("Cluster-robust SE at grappe level. Survey weights.")

* Tableau comparatif : 
esttab m3_strict m3_s2 m3_s3 ///
    using "$TABLES/09/09_reg_comparison_M3.csv", ///
    replace b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 r2_a, labels("N" "R2" "R2 adj.")) ///
    keep(lconso_w hhsize head_female educ_high urban _cons) ///
    order(lconso_w hhsize head_female educ_high urban _cons) ///
    title("Comparison M3: strict vs S2 vs S3") ///
    mtitles("Strict" "S2 milieu" "S3 IEC") ///
    note("TABLEAU CLE : stabilite des coefficients a travers les scenarios d'informelite.")

 ********************************************************************************
* ETAPE 7 — Effets marginaux : gradient de revenu par milieu
*
* OBJECTIF :
* Teste si le gradient de revenu dans eff_vat_s3 differe entre
* menages urbains et ruraux. Si le gradient est plus fort dans les zones urbaines,
* cela suggere que les menages urbains plus riches sont plus exposes a la TVA formelle
* que les menages ruraux plus riches — coherent avec le cadre IEC.
 ********************************************************************************

* Modele d'interaction : revenu × milieu
reg eff_vat_s3 ///
    c.lconso_w##urban hhsize head_female educ_high ///
    i.region ///
    [pw=hhweight], vce(cluster grappe)

* Effet marginal de lconso_w a chaque milieu
margins urban, dydx(lconso_w)

* Marges Predites : eff_vat_s3 a la grille lconso_w × milieu
margins urban, at(lconso_w=(11(0.5)15))

marginsplot, ///
    title("Taux TVA effectif predit par revenu et milieu", ///
        size(medium)) ///
    subtitle("Scenario 3 (CEI x decile) — Cote d'Ivoire EHCVM 2021", ///
        size(small)) ///
    ytitle("Taux TVA effectif predit (S3)", size(small)) ///
    xtitle("Log de la consommation totale", size(small)) ///
    legend(order(1 "Rural" 2 "Urbain") position(6) rows(1)) ///
    note("Cluster-robust SE. Survey weights. Region FE included.", ///
        size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "$FIGS/fig6_margins_income_milieu.png", ///
    replace width(2400) height(1600)

 ********************************************************************************
* ETAPE 8 — Verit robustesse : effet de revenu non-lineaire
*
* OBJECTIF :
* Teste si le gradient de revenu dans eff_vat_s3 est vraiment lineaire ou
* s'il y a un pattern concave/convexe (rendements decroissants de la formalite
* aux niveaux de revenu eleves).
*
* Test formel : H0 : coefficient sur lconso_w^2 = 0
* Si rejete → forme non-lineaire justifiee
* Si non rejete → forme lineaire preferee (parcimonie)
 ********************************************************************************

gen lconso_w2 = lconso_w^2
label variable lconso_w2 "Carre du log de consommation (test de non-linearite)"

reg eff_vat_s3 ///
    lconso_w lconso_w2 hhsize head_female educ_high ///
    urban i.region ///
    [pw=hhweight], vce(cluster grappe)

* Test formel de non-linearite
test lconso_w2
di "F = " r(F) "  p = " r(p)
if r(p) < 0.10 {
    di "H0 rejetee → forme NON-LINEAIRE justifiee, conserver lconso_w2"
}

reg eff_vat_s3 lconso_w lconso_w2 hhsize head_female educ_high ///
    urban i.region [pw=hhweight], vce(cluster grappe)

lincom lconso_w
lincom lconso_w2

 ********************************************************************************
* FIN
 ********************************************************************************