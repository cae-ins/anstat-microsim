********************************************************************************
* 06_01_sensitivity_taxation_v2.do
*
* OBJECTIF :
* Analyse de sensibilite de l'incidence TVA a des hypotheses alternatives sur
* l'application effective de la TVA — basee sur le cadre de la Courbe d'Engel de l'Informel (IEC)
* de Bachas, Gadenne & Jensen (2024).

* ────────────────────────────────────────────────────────────────────────────
* JUSTIFICATION EMPIRIQUE
* ────────────────────────────────────────────────────────────────────────────

* Le scenario de base (strict) suppose alpha = 1, c'est-a-dire la taxation effective
* complete de tous les achats imposables. C'est la borne superieure theorique.


* ────────────────────────────────────────────────────────────────────────────
* REFERENCE PRINCIPALE : BACHAS, GADENNE & JENSEN (2024)
* ────────────────────────────────────────────────────────────────────────────

* Bachas P., Gadenne L., Jensen A. (2024). "Informality, Consumption Taxes,
* and Redistribution." Review of Economic Studies, 91(5): 2604–2634.
* https://doi.org/10.1093/restud/rdad095

* Resultat principal : la part budgetaire informelle DIMINUE FORTEMENT avec le revenu
* (Courbe d'Engel de l'Informel, IEC). Consequence : une taxe de consommation large
* appliquee uniquement aux achats formels est de facto PROGRESSIVE, car les menages
* pauvres achent proportionallement plus sur les marches informels.

* Referencees quantitatives de Bachas et al. pour les pays a revenu faible/moyen-inf.
* (comparables a la Cote d'Ivoire) :
*   - D1 (le plus pauvre) : part budgetaire informelle ≈ 75–90%
*   - D10 (le plus riche) : part budgetaire informelle ≈ 40–55%
*   → Alpha effectif implye augmente de ~0,10–0,25 (D1) a ~0,45–0,60 (D10)
*     pour les categories les plus informelles (food, restaurants, soins personnels)

* References secondaires :
*   - UNECA (2019). Economic Report on Africa, Chapter 3. Efficacite de la collecte TVA
*     inferieure a 50% dans de nombreux pays africains ; ecarts TVA 50–90%.
*   - WATAF/ECOWAS (2023). Efficacite de la collecte TVA en Afrique de l'Ouest.
*     Ratio d'efficacite TVA du Niger = 0,24 (inferieur a la moyenne SSA de 0,27) ;
*     le grand secteur informel est le principal moteur.
*   - World Bank (2024). Urban Informality in Sub-Saharan Africa (WPS 10703).
*     56–65% des travailleurs urbains en SSA sont informels ; informelite persistante
*     dans les annees 2010 sans reduction urbaine systematique.

* ────────────────────────────────────────────────────────────────────────────
* TROIS SCENARIOS
* ────────────────────────────────────────────────────────────────────────────

* SCENARIO 1 — Strict (alpha = 1)
*   Transfert complet, application complete. Borne superieure theorique.
*   Sert de reference de base pour la comparaison.

* SCENARIO 2 — CEI × milieu urbain/rural
*   Alpha differencie par categorie COICOP ET statut urbain/rural.
*   Justification : l'acces au secteur informel varie structurellement entre zones urbaines et
*   rurales. Les menages ruraux ont des parts budgetaires informelles systematiquement plus elevees,
*   surtout pour la nourriture, les restaurants et les soins personnels. Les menages urbains
*   ont un meilleur acces a la distribution formelle, aux services publics et aux telecommunications.
*   Source : Bachas et al. (2024); World Bank WPS 10703 (2024).

* SCENARIO 3 — CEI × decile (Courbe d'Engel de l'Informel entierement calibree)
*   Alpha augmente lineairement avec le decile de depense, par categorie COICOP.
*   Cela implemente directement la pente IEC estimee par Bachas et al. (2024)
*   pour les pays a revenu moyen-inf. :
*     alpha(d) = alpha_D1 + (d-1) × slope
*   ou alpha_D1 et slope sont calibres par COICOP a partir de la litterature
*   IEC empirique.
*   Ce scenario teste si la structure progressive de la consommation informelle
*   est suffisante pour inverser la conclusion de regressivite.

* NOTE IMPORTANTE SUR L'INTERPRETATION D'ALPHA :
*   Ces alphas ne sont PAS des taux de conformite au sens legal. Ce sont des
*   approximations en forme reduite du transfert effectif de TVA au
*   niveau menage, incorporant :
*     (1) informel du point d'achat (canal principal, Bachas et al.)
*     (2) lacunes administratives et exonorations (UNECA 2019)
*     (3) TVA inseree dans les prix informels (~10% de transfert,
*         estimee par Bachas et al. a partir des donnees de census mexicain ;
*         appliquee ici comme borne inferieure conservative)

* SORTIES :
*   - TVA au niveau menage sous chaque scenario
*   - Taux TVA effectifs par decile sous chaque scenario
*   - Tableaux par decile : taux effectifs + parts de TVA
*   - Indices resume style CEQ (Gini, CI, Kakwani, Reynolds-Smolensky)
*   - Intervalles de confiance bootstrap sur Kakwani
*   - Jeu de donnees de sensibilite sauvegarde pour usage ulterieur

 ********************************************************************************

use "$SILVER/01/conso_clean.dta", clear

 ********************************************************************************
* ETAPE 0 — Validation
 ********************************************************************************

assert !missing(hhid, hhweight, depan_w, r_vat_official)
assert !missing(coicop, milieu)
assert depan_w > 0
assert r_vat_official >= 0

* coicop: 1=nourriture/boissons 2=alcool/tabac 3=vêtements/chaussures 4=logement/services
*         5=ameublement/equipement 6=sante 7=transport 8=info/comm
*         9=loisir 10=education 11=restaurants 12=assurance
*         13=soins personnels 98=non inclut 99=PAS CONSOMMATION
* milieu: 1=Urbain 2=Rural

 ********************************************************************************
* ETAPE 1 — Scenario de base strict (alpha = 1)
* Justification : borne superieure theorique, hypothese d'application complete.
* Sert de reference distributionnelle.
 ********************************************************************************

gen vat_item_strict = depan_w * r_vat_official
label variable vat_item_strict ///
    "Charge TVA item - scenario strict (alpha=1, taxation complete)"


 ********************************************************************************
* ETAPE 2 — SCENARIO 2: CEI × milieu urbain/rural
*
* BASE EMPIRIQUE :
* Les valeurs alpha sont calibrees a partir de deux sources :
*
* (A) Bachas, Gadenne & Jensen (2024) : parts budgetaires informelles par categorie.
*     Nourriture et restaurants : tres informels en zones rurales (IEC > 80%),
*     moderement informels en zones urbaines (IEC ~50-60%).
*     Telecommunications (info/comm) : quasi-totalement formelles independamment du milieu
*     (operateurs licences collectivisent la TVA a la source).
*     Vetements, transport, soins personnels : intermediaires, avec clairement plus de formalite
*     en milieu urbain.
*
* (B) World Bank WPS 10703 (2024) : informelite urbaine en SSA.
*     56-65% des travailleurs urbains sont informels — confirmant que meme les
*     marches urbains ne sont pas entierement formels. Le premium urbain en alpha
*     est donc modere (pas un saut vers pres de 1).
*
* Convention: alpha_rural < alpha_urban pour toutes les categories.
* L'ecart est le plus grand pour nourriture/restaurants/soins personnels (forte pente IEC)
* et le plus petit pour services/assurance/telecom (quasi-formels independamment).
*
* Categories coicop==98 et coicop==99 : alpha=0 (non taxable par definition).
 ********************************************************************************

gen alpha_2 = .

* ── nourriture/boissons (coicop 1) ──────────────────────────────────────────────────────
* Categorie la plus informelle. Rural : predominantly marches traditionnels
* (IEC ~ 80-90%, Bachas et al.). Urbain : melange de supermarches + marches
* (IEC ~ 50-60%).
replace alpha_2 = 0.18 if coicop == 1  & milieu == 2   // rural
replace alpha_2 = 0.42 if coicop == 1  & milieu == 1   // urbain

* ── alcool/tabac (coicop 2) ───────────────────────────────────────────────
* Accises specifiques + chaine de distribution plus concentree.
* Relativement plus formelle que la nourriture generale. Premium urbain modere.
replace alpha_2 = 0.55 if coicop == 2  & milieu == 2
replace alpha_2 = 0.72 if coicop == 2  & milieu == 1

* ── vetements/chaussures (coicop 3) ─────────────────────────────────────────────
* Melange de boutiques formelles et etals de marche informels. Premium urbain clair
* (supermarches, magasins de marque). Rural : en grand partie commercants informels.
replace alpha_2 = 0.28 if coicop == 3  & milieu == 2
replace alpha_2 = 0.52 if coicop == 3  & milieu == 1

* ── logement/services publics (coicop 4) ─────────────────────────────────────────────
* Electricite (CIE/SODECI en Cote d'Ivoire), eau canalisee, loyer formel :
* en grand partie operateurs formels qui collectivisent la TVA directement. Alpha le plus eleve.
* Le premium rural est plus petit car les zones rurales ont moins d'acces aux services publics,
* mais l'infrastructure qui existe est toujours formelle.
replace alpha_2 = 0.68 if coicop == 4  & milieu == 2
replace alpha_2 = 0.84 if coicop == 4  & milieu == 1

* ── ameublement/equipement (coicop 5) ─────────────────────────────────────────
* Production artisanale, marches d'occasion dominent en zones rurales.
* Urbain : melange de magasins formels et artisans informels.
replace alpha_2 = 0.28 if coicop == 5  & milieu == 2
replace alpha_2 = 0.48 if coicop == 5  & milieu == 1

* ── sante (coicop 6) ────────────────────────────────────────────────────────
* Cliniques hopitaux formels vs medecine traditionnelle/pharmacies informelles.
* La sante est un secteur mixte : cliniques privees formelles en zones urbaines,
* guerisseurs traditionnels et debitants de drogueries informelles en zones rurales.
replace alpha_2 = 0.38 if coicop == 6  & milieu == 2
replace alpha_2 = 0.66 if coicop == 6  & milieu == 1

* ── transport (coicop 7) ─────────────────────────────────────────────────────
* Domine par taxis informels, taxis bush, taxis moto (woro-woro,
* gbaka en Cote d'Ivoire). Transport formel (bus, avion) est urbain et
* concentre dans les deciles superieurs.
replace alpha_2 = 0.32 if coicop == 7  & milieu == 2
replace alpha_2 = 0.62 if coicop == 7  & milieu == 1

* ── info/comm (coicop 8) ─────────────────────────────────────────────────────
* ALPHA LE PLUS ELEVE. Operateurs mobiles (Orange, MTN, Moov), fournisseurs internet :
* tous enregistres formellement, TVA collectee a la source par operateurs licences.
* OECD/WBG/ATAF VAT Digital Toolkit for Africa (2023) confirme une quasi-totalite
* de la formalite de la collecte TVA telecommunications.
* Petit residu d'informel pour les telephones d'occasion etc.
replace alpha_2 = 0.82 if coicop == 8  & milieu == 2
replace alpha_2 = 0.94 if coicop == 8  & milieu == 1

* ── loisir (coicop 9) ────────────────────────────────────────────────────
* Tres petite part (0,15% des observations). Melange formel/informel.
replace alpha_2 = 0.35 if coicop == 9  & milieu == 2
replace alpha_2 = 0.58 if coicop == 9  & milieu == 1

* ── education (coicop 10) ────────────────────────────────────────────────────
* Ecoles et universites enregistrees emettent des recu. En grande partie formelles,
* mais cours particulier informels et ecoles non enregistrees existent en zones rurales.
replace alpha_2 = 0.62 if coicop == 10 & milieu == 2
replace alpha_2 = 0.78 if coicop == 10 & milieu == 1

* ── restaurants (coicop 11) ──────────────────────────────────────────────────
* Tres informels : rue, maquis, gargotes dominent a tous les niveaux
* de revenu en Cote d'Ivoire, specialement en zones rurales. Restaurants formels
* (avec facture/recus) sont concentres dans les deciles urbains superieurs.
* Forte pente IEC : tres similaire a nourriture/boissons.
replace alpha_2 = 0.18 if coicop == 11 & milieu == 2
replace alpha_2 = 0.52 if coicop == 11 & milieu == 1

* ── assurance (coicop 12) ────────────────────────────────────────────────────
* Formelle par definition (assureurs licences). Tres petite part (0,15%).
replace alpha_2 = 0.88 if coicop == 12 & milieu == 2
replace alpha_2 = 0.95 if coicop == 12 & milieu == 1

* ── soins personnels (coicop 13) ────────────────────────────────────────────────
* Salons de coiffure, barbiers, cosmetiques : secteur tres informel.
* Grande part (9,56% des observations). Forte pente IEC.
replace alpha_2 = 0.22 if coicop == 13 & milieu == 2
replace alpha_2 = 0.48 if coicop == 13 & milieu == 1

* ── non inclut / pas consommation ──────────────────────────────────────────
replace alpha_2 = 0    if coicop == 98
replace alpha_2 = 0    if coicop == 99

* Verifier pas de alpha manquant pour les items imposables
assert !missing(alpha_2) if r_vat_official > 0

gen vat_item_s2 = alpha_2 * vat_item_strict
label variable vat_item_s2 ///
    "Charge TVA item - Scenario 2: CEI × milieu (Bachas et al. 2024)"


 ********************************************************************************
* ETAPE 3 — SCENARIO 3: CEI × decile (Courbe d'Engel de l'Informel calibree)
*
* BASE EMPIRIQUE :
* Bachas, Gadenne & Jensen (2024) estiment que dans les pays a revenu
* moyen-inf., la pente IEC (reduction de la part budgetaire informelle par
* doublement logarithmique de la depense) varie de -5 a -8 points de pourcentage.
*
* On translate ceci en une approximation lineaire a travers les deciles :
*   alpha(coicop, d) = alpha_D1(coicop) + (d-1) × slope(coicop)
*
* Ou :
*   alpha_D1 = alpha effectif pour le decile le plus pauvre
*   slope    = increment par decile (derive de la pente IEC)
*   d        = rang du decile (1 a 10)
*
* La pente est PLUS FORTE pour les categories a forte sensibilite IEC :
*   - nourriture/boissons, restaurants, soins personnels : pentes les plus fortes
*   - logement/services publics, assurance, telecom : pentes les plus plates
*
* Note de calibration : les alphas sont caps a 1.
* Ce scenario modelise DIRECTEMENT le mecanisme central de Bachas et al. :
* meme au sein de la meme categorie COICOP, les menages pauvres achetent informellement
* plus que les menages riches, impliquant un alpha effectif plus faible en bas.
*
* NOTE : le decile doit etre calcule AVANT cette etape (fait dans l'Etape 8 du
* code original ; ici on requer qu'il existe deja).
* Si execution independante, calculer : xtile decile = conso_w [pw=hhweight], n(10)
 ********************************************************************************
bys hhid: egen conso_w = total(depan_w)
xtile decile = conso_w [pw=hhweight], n(10)

label define dec_lbl 1 "D1 le plus pauvre" 2 "D2" 3 "D3" 4 "D4" 5 "D5" ///
                     6 "D6" 7 "D7" 8 "D8" 9 "D9" 10 "D10 le plus riche", replace

label values decile dec_lbl
label variable decile ///
"Decile du bien-etre de base (consommation totale winsorisee)"


gen alpha_3 = .

* ── nourriture/boissons (coicop 1) ──────────────────────────────────────────────────────
* alpha_D1 = 0.12 | slope = 0.034
* → D1: 0.12, D5: 0.25, D10: 0.42
* Justification : IEC la plus forte dans Bachas et al. pour les pays a revenu faible.
* Le decile le plus pauvre achats presque entierement aux marches traditionnels.
replace alpha_3 = 0.12 + (decile - 1) * 0.034 if coicop == 1

* ── alcool/tabac (coicop 2) ───────────────────────────────────────────────
* alpha_D1 = 0.48 | slope = 0.024
* Chaine plus formelle ; IEC plus plate.
replace alpha_3 = 0.48 + (decile - 1) * 0.024 if coicop == 2

* ── vetements/chaussures (coicop 3) ─────────────────────────────────────────────
* alpha_D1 = 0.22 | slope = 0.030
* → D1: 0.22, D5: 0.34, D10: 0.49
replace alpha_3 = 0.22 + (decile - 1) * 0.030 if coicop == 3

* ── logement/services publics (coicop 4) ─────────────────────────────────────────────
* alpha_D1 = 0.62 | slope = 0.022
* Profil le plus plat : services publics sont formels independamment du niveau de revenu.
replace alpha_3 = 0.62 + (decile - 1) * 0.022 if coicop == 4

* ── ameublement/equipement (coicop 5) ─────────────────────────────────────────
* alpha_D1 = 0.22 | slope = 0.028
replace alpha_3 = 0.22 + (decile - 1) * 0.028 if coicop == 5

* ── sante (coicop 6) ────────────────────────────────────────────────────────
* alpha_D1 = 0.30 | slope = 0.040
* Pente forte : menages riches utilisent cliniques privees (formelles) ;
* menages pauvres utilisent soins traditionnels/informels.
replace alpha_3 = 0.30 + (decile - 1) * 0.040 if coicop == 6

* ── transport (coicop 7) ─────────────────────────────────────────────────────
* alpha_D1 = 0.25 | slope = 0.038
* Pauvres : taxis informels, motos. Riches : taxis formels, voiture, avion.
replace alpha_3 = 0.25 + (decile - 1) * 0.038 if coicop == 7

* ── info/comm (coicop 8) ─────────────────────────────────────────────────────
* alpha_D1 = 0.78 | slope = 0.015
* Tres plat : telecom est formel a tous niveaux de revenu (operateurs licences).
replace alpha_3 = 0.78 + (decile - 1) * 0.015 if coicop == 8

* ── loisir (coicop 9) ────────────────────────────────────────────────────
* alpha_D1 = 0.28 | slope = 0.032
replace alpha_3 = 0.28 + (decile - 1) * 0.032 if coicop == 9

* ── education (coicop 10) ────────────────────────────────────────────────────
* alpha_D1 = 0.55 | slope = 0.025
* Les ecoles formelles sont plus utilisees par les menages riches ; les pauvres
* dependent plus des ecoles/non enregistrees informelles ou de l'auto-formation.
replace alpha_3 = 0.55 + (decile - 1) * 0.025 if coicop == 10

* ── restaurants (coicop 11) ──────────────────────���─���─────────────────────────
* alpha_D1 = 0.12 | slope = 0.038
* → D1: 0.12, D5: 0.27, D10: 0.46
* Profil empirique similaire a nourriture/boissons. Forte IEC.
replace alpha_3 = 0.12 + (decile - 1) * 0.038 if coicop == 11

* ── assurance (coicop 12) ────────────────────────────────────────────────────
* alpha_D1 = 0.85 | slope = 0.010
* Presque entierement formel a tous les deciles.
replace alpha_3 = 0.85 + (decile - 1) * 0.010 if coicop == 12

* ── soins personnels (coicop 13) ────────────────────────────────────────────────
* alpha_D1 = 0.15 | slope = 0.034
* → D1: 0.15, D5: 0.29, D10: 0.46
* Forte IEC : salons vastement informels pour les menages a faible revenu ;
* menages plus riches utilisent salons de beaute formels avec recu.
replace alpha_3 = 0.15 + (decile - 1) * 0.034 if coicop == 13

* ── non inclut / pas consommation ──────────────────────────────────────────
replace alpha_3 = 0    if coicop == 98
replace alpha_3 = 0    if coicop == 99

* Caper a 1 (maximum theorique)
replace alpha_3 = min(alpha_3, 1)

* Verifier pas de alpha manquant pour les items imposables
assert !missing(alpha_3) if r_vat_official > 0

gen vat_item_s3 = alpha_3 * vat_item_strict
label variable vat_item_s3 ///
    "Charge TVA item - Scenario 3: CEI × decile (IEC calibree, Bachas 2024)"


 ********************************************************************************
* ETAPE 4 — Diagnostique : alpha moyen par COICOP × scenario
* Verifier que le Scenario 3 produit un gradient significatif a travers les deciles
* et que le Scenario 2 produit un ecart urbain/rural significatif.
 ********************************************************************************

preserve
collapse (mean) alpha_2 alpha_3 [pw=hhweight], by(coicop decile)
export excel using "$TABLES/06/06_01_alpha_diagnostics_coicop_decile.xlsx", ///
    firstrow(variables) replace
restore

preserve
collapse (mean) alpha_2 [pw=hhweight], by(coicop milieu)
export excel using "$TABLES/06/06_01_alpha_diagnostics_coicop_milieu.xlsx", ///
    firstrow(variables) replace
restore


 ********************************************************************************
* ETAPE 5 — Agregation au niveau menage
 ********************************************************************************

sort hhid

foreach s in strict s2 s3 {
    by hhid: egen vat_`s' = total(vat_item_`s')
    label variable vat_`s' "TVA totale payee - scenario `s'"
}



 ********************************************************************************
* ETAPE 6 — Taux TVA effectifs
 ********************************************************************************

foreach s in strict s2 s3 {
    gen eff_vat_`s' = vat_`s' / conso_w
    label variable eff_vat_`s' "Taux TVA effectif - scenario `s'"
}

save "$SILVER/06/fiscal_sensitivity_taxation.dta", replace

 ********************************************************************************
* ETAPE 7 — Taux TVA effectifs par decile
*
* TABLEAU DIAGNOSTIQUE CLE.
* Si le Scenario 3 (CEI × decile) produit un PROFIL CROISSANT des taux TVA
* effectifs, cela confirme que prise en compte de la consommation informelle rend
* la taxe progressive — coherente avec Bachas et al. (2024).
* Si le profil reste plat ou decroissant, la regressivite est robuste.
 ********************************************************************************

preserve
collapse (mean) eff_vat_strict eff_vat_s2 eff_vat_s3 ///
    [pw=hhweight], by(decile)

* Renommer pour clarte en sortie
rename eff_vat_strict rate_strict
rename eff_vat_s2     rate_s2_milieu
rename eff_vat_s3     rate_s3_iec

export excel using "$TABLES/06/06_01_decile_effective_rates_by_scenario.xlsx", ///
    firstrow(variables) replace
restore


 ********************************************************************************
* ETAPE 8 — Indices style CEQ : Gini, Indice de Concentration, Kakwani,
*           Reynolds-Smolensky
*
* GUIDE D'INTERPRETATION :
*
* Indice de Kakwani = CI(TVA) - Gini(revenu avant impôt)
*   > 0 : progressif (les menages riches supportent proportionallement plus de TVA)
*   < 0 : regressif (les menages pauvres supportent proportionallement plus de TVA)
*   = 0 : proportionnel
*
* Reynolds-Smolensky = Gini_apres - Gini_avant
*   > 0 : la taxe AUGMENTE l'inegalite (regressive + assez large)
*   < 0 : la taxe REDUIT l'inegalite (progressive)
*
* LOGIQUE DU TEST DE ROBUSTESSE (cadre Bachas et al. 2024) :
*   Scenario 1 (strict) : reference distributionnelle
*   Scenario 2 (CEI × milieu) : le gradient d'informelite urbain/rural
*     change-t-il le signe de Kakwani ?
*   Scenario 3 (CEI × decile) : la structure IEC complete change-t-elle
*     le signe de Kakwani ?
*
* Si Kakwani < 0 dans LES TROIS scenarios → regressivite robuste.
* Si le signe change dans le Scenario 3 → la conclusion est sensible a l'hypothese IEC
*   ; doit etre discutee soigneusement.
 ********************************************************************************
* Installer les packages si necessaire
capture which ineqdeco
if _rc ssc install ineqdeco

capture which conindex
if _rc ssc install conindex

* Definir le revenu
gen market_income = conso_w

foreach s in strict s2 s3 {
    gen consumable_`s' = market_income - vat_`s'
}

* Reduire au niveau menage
preserve
bysort hhid: keep if _n == 1

* Gini avant impôt
quietly ineqdeco market_income [aw=hhweight]
scalar G_market = r(gini)

* Postfile
postfile ceq_handle str30 scenario str80 description ///
    double g_market g_after c_vat kakwani rs ///
    using "$SILVER/06/06_01_ceq_summary_scenarios.dta", replace

* ── Scenario 1: strict ─────────────────────────────
quietly ineqdeco consumable_strict [aw=hhweight]
scalar G_after = r(gini)

quietly conindex vat_strict [pw=hhweight], rankvar(market_income) truezero
scalar C_vat   = r(CI)

scalar Kakwani = C_vat - G_market
scalar RS      = G_after - G_market

post ceq_handle ("strict") ///
    ("Alpha=1, taxation complete") ///
    (G_market) (G_after) (C_vat) (Kakwani) (RS)

* ── Scenario 2: CEI × milieu ───────────────────────
quietly ineqdeco consumable_s2 [aw=hhweight]
scalar G_after = r(gini)

quietly conindex vat_s2 [pw=hhweight], rankvar(market_income) truezero
scalar C_vat   = r(CI)

scalar Kakwani = C_vat - G_market
scalar RS      = G_after - G_market

post ceq_handle ("s2_milieu") ///
    ("CEI x milieu (Bachas 2024 + WB WPS10703)") ///
    (G_market) (G_after) (C_vat) (Kakwani) (RS)

* ── Scenario 3: CEI × decile ───────────────────────
quietly ineqdeco consumable_s3 [aw=hhweight]
scalar G_after = r(gini)

quietly conindex vat_s3 [pw=hhweight], rankvar(market_income) truezero
scalar C_vat   = r(CI)

scalar Kakwani = C_vat - G_market
scalar RS      = G_after - G_market

post ceq_handle ("s3_iec_decile") ///
    ("CEI x decile, IEC calibree (Bachas 2024)") ///
    (G_market) (G_after) (C_vat) (Kakwani) (RS)

postclose ceq_handle

restore

 ********************************************************************************
* ETAPE 9 — Intervalles de confiance bootstrap sur Kakwani
*
* OBJECTIF :
* Tester si les indices Kakwani sont statistiquement distinguables de zero
* et les uns des autres a traves les scenarios.
* Les erreurs types sur conindex ne sont pas rapportees par defaut ; le bootstrap
* fournit une quantification honnete de l'incertitude.
*
* 500 replicatiops = standard pour les indices distributionnels en analyse
* d'incidence fiscale (Lustig 2018, CEQ Handbook).
 ********************************************************************************


 ********************************************************************************
* ETAPE 10 — Bootstrap manuel Kakwani 
 ********************************************************************************

bysort hhid: keep if _n == 1
set seed 20240901
local reps = 500

tempname bs_results
postfile `bs_results' ///
    double kak_strict kak_s2 kak_s3 ///
    using "$SILVER/06/bs_kakwani_raw.dta", replace

forvalues i = 1/`reps' {

    preserve

    * Bootstrap standard 
    bsample

    quietly ineqdeco market_income [aw=hhweight]
    local G = r(gini)

    quietly conindex vat_strict [aw=hhweight], ///
        rankvar(market_income) truezero
    local k1 = r(CI) - `G'

    quietly conindex vat_s2 [aw=hhweight], ///
        rankvar(market_income) truezero
    local k2 = r(CI) - `G'

    quietly conindex vat_s3 [aw=hhweight], ///
        rankvar(market_income) truezero
    local k3 = r(CI) - `G'

    post `bs_results' (`k1') (`k2') (`k3')

    restore
}

postclose `bs_results'

 ********************************************************************************
* IC bootstrap percentile
 ********************************************************************************

use "$SILVER/06/bs_kakwani_raw.dta", clear

foreach k in kak_strict kak_s2 kak_s3 {

    quietly summarize `k'
    local mean_k = r(mean)

    centile `k', centile(2.5 97.5)
    local lo = r(c_1)
    local hi = r(c_2)

    di as text "-----------------------------------------"
    di as result "Kakwani [`k']"
    di as text "Moyenne = " %6.4f `mean_k'
    di as text "IC95%  = [" %6.4f `lo' " ; " %6.4f `hi' "]"
}

export excel using "$TABLES/06/06_01_bootstrap_kakwani.xlsx", ///
    firstrow(variables) replace


 ********************************************************************************
* ETAPE 11 — Finaliser et annoter les resultats CEQ
 ********************************************************************************

use "$SILVER/06/06_01_ceq_summary_scenarios.dta", clear

* Signe
gen progressive = (kakwani > 0)
gen regressive  = (kakwani < 0)

* Classification robuste
egen min_kak = min(kakwani)
egen max_kak = max(kakwani)

gen robust_regressive  = (max_kak < 0)
gen robust_progressive = (min_kak > 0)
gen sign_unstable      = (min_kak < 0) & (max_kak > 0)

* Delta vs strict (robuste)
egen kak_strict = mean(kakwani) if scenario == "strict"
egen kak_strict_all = max(kak_strict)

gen delta_kakwani_vs_strict = kakwani - kak_strict_all

* Etiquettes
label variable progressive "1 = Kakwani > 0 (progressif)"
label variable regressive  "1 = Kakwani < 0 (regressif)"
label variable robust_regressive "1 = regressif dans tous les scenarios"
label variable robust_progressive "1 = progressif dans tous les scenarios"
label variable sign_unstable "1 = le signe change a travers les scenarios"
label variable delta_kakwani_vs_strict ///
    "Variation de Kakwani relativement au scenario strict"

export excel using "$TABLES/06/06_01_ceq_summary_scenarios.xlsx", ///
    firstrow(variables) replace

save "$SILVER/06/06_01_ceq_summary_scenarios.dta", replace


 ********************************************************************************
* FIN
 ********************************************************************************