*Cote d'Ivoire 2021/22 Presimulation Setup
*August 22, 2022
*Ian Houts

clear all
set more off
set type double


*Poverty matching and disposable income creation

use "$gdData\Dataout\ehcvm_welfare_CIV2021.dta", clear

*household consumption variables already annualized
g pcweight = hhweight*hhsize
rename hhsize hsize
rename grappe psu

rename zref pl_nat		//national poverty threshhold	(246,541.55 XOF)

/* nb. BA could not find the ceqppp2017 command, but it seems it is not necessary
	ceqppp2017, country("civ") b(2017) s(2021) l 
	disp `ppp'
	disp `cpibase'
	disp `cpisurvey'
	disp `ppp'*`cpisurvey'/`cpibase'	     //261.5054 for 2021	  275.30286  for 2022
*/

gen t = pcexp / (dollars*365) // Ratio between welfare aggregate in CFA francs and dollars per household (considers spatial differences)
gen pl_215 = t*2.15*365 // International poverty line $2.15 (2017 PPP) expressed in CFA francs. 
gen pl_365 = t*3.65*365 // International poverty line $2.15 (2017 PPP) expressed in CFA francs. 
gen pl_685 = t*6.85*365 // International poverty line $2.15 (2017 PPP) expressed in CFA francs. 
drop t

     foreach n in 215 365 685 nat{
          g poor_`n' = (pcexp < pl_`n')
          tab poor_`n' [w=int(pcweight)]
        }

*WB reports 37.47% national poverty (9.9m people) in 2018		//Rural poverty rate: 54.45 %    //Abidjan rate: 6.98 	//Other urban poverty rate: 32.23 %
* Looking for a poverty rate of 37.47%
  povdeco pcexp [w=pcweight], varpline(pl_nat)    	//37.5  	// spot on
  povdeco pcexp [w=pcweight], varpline(pl_215)  	//9.7		// spot on
  povdeco pcexp [w=pcweight], varpline(pl_365)   	//38.4		// spot on
  povdeco pcexp [w=pcweight], varpline(pl_685)   	//76.4		// spot on


* Looking for a Gini coefficient of 33.4 (source: Poverty Updates - CIV Draft)
ineqdeco pcexp [w=pcweight]   //0.33362
		
rename pcexp yd_pc
g yd_hh = yd_pc*hsize

quantiles yd_hh [w=hhweight], gen(dec_yd_hh) n(10)
quantiles yd_pc [w=pcweight], gen(dec_yd_pc) n(10)

*harmonize some variables for CEQ
rename hhweight weight
rename milieu	urban

keep year hhid hsize psu urban yd_* weight pcweight pl_* def_* dec_yd_* poor_nat

save "$gdTemp\yd.dta", replace


***************************************************************************************
***************************Direct Taxes************************************************
***************************************************************************************

************
*Step 1: Build formal employment roster to identify likely taxpayers
************

*use "$gdData\Datain\Menage/s04_me_CIV2021.dta", clear
use "$gdData\Datain\Menage/s04a_me_CIV2021.dta", clear
merge 1:1 grappe menage s01q00a using "$gdData\Datain/Menage/s04b_me_CIV2021.dta", nogen
merge 1:1 grappe menage s01q00a using "$gdData\Datain/Menage/s04c_me_CIV2021.dta", nogen  
destring grappe, replace
g hhid=grappe*100+menage 
rename s01q00a numind

preserve
	use "$gdData\Datain\Menage\s05_me_CIV2021.dta", clear
	destring grappe, replace
	g hhid=grappe*100+menage
	rename s01q00a numind
	rename s05q10 inc_rent
	rename s05q12 inc_capt
	tempfile othrincome
	save `othrincome'
restore

merge 1:1 vague grappe menage numind using `othrincome', keepusing(hhid inc_rent inc_capt)
drop _merge

preserve
	use "$gdData\Datain\Menage\s11_me_CIV2021.dta", clear
	destring grappe, replace
	clonevar psu = grappe
	g hhid=grappe*100+menage
	collapse (max)s11q04, by(hhid)
	tempfile propertytx
	save `propertytx'
restore

merge m:1 hhid using `propertytx', keepusing(s11q04)
drop _merge

merge 1:1 vague grappe menage numind using "$gdData\Dataout\ehcvm_individu_CIV2021.dta", keepusing(hhweight resid age mstat)
drop _merge
drop if hhid==.


preserve
	use "$gdData\Dataout\ehcvm_conso_CIV2021.dta", clear
	keep if modep==5		// keep only imputed rent
	rename depan imprent
	tempfile imprent
	save `imprent'
restore

merge m:1 hhid using `imprent', keepusing(imprent)
drop _merge
drop if hhweight==.

bysort hhid: gen rentid=_n
bysort hhid: replace imprent=0 if rentid>1

bysort hhid: egen num_memb = max(numind)
g pcweight = hhweight*num_memb

g vacation  = (s04q33==1)
g paidleave = (s04q34==1)
g sickleave	= (s04q35==1)
g pension	= (s04q38==1)
g maternity = (s04q40==1)
g payslip   = (s04q42==1) 
g employed  = ((s04q43>0 & s04q43!=.) & (s04q32>0 & s04q32!=.))		//receives a salary at a main place of employment and has been there at least 1 month (long enough to get paid/pay tax). The question about just having a job had very few responses..

g formal_prim = (vacation==1 | paidleave==1 | sickleave==1 | pension==1 | maternity==1 | payslip==1) & employed==1

*Identify primary gross income

g salary_prim = 0
replace salary_prim = s04q43*52 if s04q43_unite==1	
replace salary_prim = s04q43*12 if s04q43_unite==2		
replace salary_prim = s04q43*3 if s04q43_unite==3
replace salary_prim=0 if formal_prim==0
*IH: I will use this for gross income rather than the combined dataset's "salaire" variable, as they add in the estimated value of food and other non-cash benefits, which are probably not taxed. 

*Secondary employment
**no similar formality questions for the second job except for "do you receive benefits?". So I will identify by likely profession/employer
g employed_seco = (s04q50==1)
g formal_sector = inrange(s04q51b, 1, 4)		//EXECUTIVE AND LEGISLATION MEMBERS, INTELLECTUAL AND SCIENTIFIC PROFESSIONS, INTERMEDIATE PROFESSIONS, EXECUTIVE OFFICERS
replace formal_sector=1 if s04q51b==10			//army
g formal_prof	= inrange(s04q51d, 11, 401)

g formal_seco = (formal_sector==1 | formal_prof==1) & employed_seco==1		//About 2/3 of secondary jobs stayed formal. May need to be more selective if the final result is too high. 

*Identify secondary gross employment
g salary_seco = 0
replace salary_seco = s04q58*52 if s04q58_unite==1		
replace salary_seco = s04q58*12 if s04q58_unite==2		
replace salary_seco = s04q58*3 if s04q58_unite==3
replace salary_seco=0 if formal_seco==0

egen salary_tot = rowtotal(salary_prim salary_seco)


save "$gdTemp\formal.dta", replace


**********************************************************************************************************************************
*Business Income***************************************************************************************************************
**********************************************************************************************************************************

preserve
	use "$gdData\Datain\Menage\s10a_me_CIV2021.dta", clear
	destring grappe, replace
	g hhid=grappe*100+menage 
	g s10q11 = (s10q02==1 | s10q03==1 | s10q04==1 | s10q05==1 | s10q06==1 | s10q07==1 | s10q08==1 | s10q09==1 | s10q10==1)
	rename s10q11 owners
	rename s10q06 libs_own
	tempfile owners
	save `owners'

	use "$gdData\Datain\Menage\s10b_me_CIV2021.dta", clear
	destring grappe, replace
	g hhid=grappe*100+menage 
	merge m:1 hhid using `owners', keepusing(owners libs_own)
	drop _merge 

	keep if owners==1

	rename s10q59 ent_month //how many months has the business been in operation
	drop if ent_month==0
	rename s10q46 inc_goods	//What is the amount obtained on the resale of goods purchased and resold in the last 30 days or during the last month that the business has operated? 
	rename s10q47 cost_goods	//How much did you spend on the purchase of these goods resold in the state, without transformation, during the last 30 days or during the last month that the business operated? 
	rename s10q48 inc_prod	//What is the amount obtained on the sale of products processed by the company during the last 30 days or during the last month that the company has operated? 
	rename s10q49 cost_prod	//How much did you spend on purchasing raw materials for products sold in the last 30 days or in the last month the business was in operation?
	rename s10q50 inc_service //What is the amount obtained on services rendered by the business during the last 30 days or during the last month that the business has been in operation? 
	rename s10q51 cost_int //How much did you spend on other intermediate consumption (telephone, transport, supplies, etc.) during the last 30 days or during the last month that the business operated? 
	rename s10q52 cost_rent //How much did you spend on rent, water and electricity in the last 30 days or in the last month the business was in operation? 
	rename s10q53 cost_sfee //How much did you spend on service fees to use or rent equipment in the last 30 days or in the last month the business was in operation? 
	rename s10q54 cost_fees //How much did you spend on other fees and services in the last 30 days or in the last month the business was in operation? (equipment repair, etc.) 
	rename s10q55 cost_licn //What is the amount of license paid by the company during the last 12 months? 
	rename s10q56 cost_tax  //What is the amount of other taxes and duties paid by the company during the last 12 months? //These taxes look to be only company taxes, and most small businesses are exempt. This will not cover PIT on profits. 
	rename s10q57 cost_afee //What is the amount of non-regulatory administrative fees paid by the company during the last 12 months?

	egen cost_12m = rowtotal(cost_licn cost_tax cost_afee)
	egen cost_30d = rowtotal(cost_goods cost_prod cost_int cost_rent cost_sfee cost_fees)
	egen inc_30d  = rowtotal(inc_goods inc_prod inc_service)

	foreach var in cost inc{
		foreach num of numlist 2/12{
	replace `var'_30d = `var'_30d*`num' if ent_month==`num'			//annualize
						}
			}
			
	clonevar tps_30d = inc_30d
	g selfformal = (cost_licn>0 | cost_tax>0)	
	replace selfformal=0 if inc_30d<5000000					//Business turnover under 5million is not taxed
	replace cost_30d=0 if selfformal==0
	replace cost_12m=0 if selfformal==0
	gen inc_self = inc_30d - cost_30d - cost_12m
	replace inc_self=0 if selfformal==0
	replace inc_30d=0 if selfformal==0


	collapse (sum) inc_self inc_30d cost_30d cost_12m libs_own (max)selfformal, by(hhid)
	replace inc_self=0 if inc_self<0

	tempfile selfincome
	save `selfincome'
restore

merge m:1 hhid using `selfincome', keepusing(inc_self inc_30d)
drop _merge


bysort hhid: gen taxid=_n
bysort hhid: replace inc_self=0 if taxid>1		//business income was at household level in the merge, so I'm assigning the tax to the first member of the household only. 
bysort hhid: replace inc_30d=0 if taxid>1

****************************************************************************************************
*Property Tax
*3% of rental value for principal residence and first secondary residence
*9% of rental value for individuals, 11% for companies if not owner occupied and produce income
*For the principal residence, use Section 11. *11.04 What is your occupation status of the property? *11.
*For rental properties, use rental income as a measure of rental value.

replace inc_rent=0 if inc_rent==.
replace imprent=0 if imprent==.
g propown_lord = (inc_rent>0)					//we can only see if the respondent own their occupied house. So we assume they own all properties they receive rent from.

g dtx_prop_pc1 = 0
g dtx_prop_pc2 = 0

**********************************************************************************************************************************
**********************************************************************************************************************************
**********************************************************************************************************************************
clonevar GI = salary_tot
g dtx_pyrl_pc = 0

g con_fama_pc = 0
g con_inda_pc = 0
g cpn_cnps_pc = 0
g dtx_capt_pc = 0
g dtx_rent_pc = 0
g dtx_ibic_pc = 0

keep vague grappe menage numind hhid salary_tot GI dtx_* con_* cpn_* inc_self inc_30d inc_rent inc_capt resid hhweight imprent propown_lord s11q04 age mstat

rename hhweight weight
merge m:1 hhid using "$gdTemp\yd.dta", keepusing(dec_yd_* hsize pcweight)
drop _merge

g part = 0

save "$gdOut\dtx_base.dta", replace


************************************************************************************************************************************************************
*******************************************************************************Direct Transfers*************************************************************
************************************************************************************************************************************************************


********************************************************************************
* PRODUCE PMT INDICATORS FOR COTE D'IVOIRE BE USED FOR TARGETING			   *
********************************************************************************

clear*
drop _all
return clear
capture log close
set more off


// 
use "$gdData\Datain\Menage\s00_me_CIV2021.dta", clear
numlabel, add
count     // 12,992 hh

// administrative division
* rename b04_district 	adm1_district    
rename s00q04   milieu
rename s00q01 	adm2_region
rename s00q02 	adm3_dept
*rename s00q03 	adm4_souspref			//IH: we don't have this variable, so this hhid construction won't work. Going to see if it works with the hhid construction we used in the rest of the survey. 
*rename s00q05 	adm5_nomvilla			//IH: don't have this either

gen urban=(milieu==1)
label var urban "s00q04: urban=1, rural=0"
gen rural=(milieu==2)
label var rural "s00q04: rural=1, urban=0"

destring grappe, replace
g hhid=grappe*100+menage

// save data
local signlist grappe menage hhid adm* milieu urban rural 
order grappe menage `signlist'
keep grappe menage `signlist'
count
sort grappe menage
tempfile tfsign
save `tfsign'

*===============================================================================
// SOCIODEMOGRAPHIC CHARACTERISTICS OF HOUSEHOLD MEMBERS
use "$gdData\Datain\Menage\s01_me_CIV2021.dta", clear
merge 1:1 grappe menage s01q00a using "$gdData\Datain\Menage\s03_me_CIV2021.dta", keepusing(s03q41 s03q42 s03q43 s03q44 s03q45 s03q46) 
drop _m 
 
numlabel, add

* âge dans la génération 
g verifAge=s01q03c !=. | s01q04a !=.  
ta verifAge     // on dispose d'information pour calculer l'âge pour tous les individus
g age=2018-s01q03c if vague==1 & s01q03c !=.
replace age=2019-s01q03c if vague==2 & s01q03c !=.
replace age = s01q04a if s01q04a !=.    
codebook age    // Les âges sont compris entre 0 et 118 ans

clonevar numind=s01q00a
clonevar sex=s01q01
clonevar lien=s01q02 
clonevar residence=s01q11
clonevar agey=age   

preserve
	keep grappe menage numind  sex lien residence agey 
	sort grappe menage numind
	tempfile tfind
	save `tfind'		

	// keep grappe menage ind pond    *========== 
	sort grappe menage numind
	tempfile tfpondi
	save `tfpondi'					
restore

clonevar mstat=s01q07							 
g hcap_vue=inlist(s03q41,3,4)
g hcap_audition=inlist(s03q42,3,4) 
g hcap_parole=inlist(s03q46,3,4) 
g hcap_paralysie=inlist(s03q45,3,4)   // difficultés pour accomplir des tâches comme se laver ou s'habiller 
g hcap_psychique=inlist(s03q44,3,4)  
g hcap_parainf=inlist(s03q43,3,4)
  
g orph_mere=s01q31==2 & inrange(agey,0,18) 
g orph_pere=s01q24==2 & inrange(agey,0,18) 

gen hhsizev1=1  
gen hhsizev2=1 if lien<=8  // excludes domestique, pensionnaire, their parents, and non apparente 
gen nage0_5=(agey<=5)
gen nage6_10=(agey>=6 & agey<=10)
gen nage11_15=(agey>=11 & agey<=15)
gen nage0_15=(agey<=15)
gen nage65plus=(agey>=65)

gen hhfemale=(sex==2 & lien==1)
gen hhmale=(sex==1 & lien==1)
gen hhage=agey if lien==1		
gen hhveuf=(lien==1 & mstat==5)
gen hhceleb=(lien==1 & mstat==1)
gen handicap=(hcap_vue==1 | hcap_aud==1 | hcap_parole==1 | hcap_paralysie==1 | hcap_psychique==1 | hcap_parainf==1)
gen hh_handicap=(handicap==1 &  lien==1)
gen orphan=(orph_mere==1 | orph_pere==1)
gen orphan_d=(orph_mere==1 & orph_pere==1)

collapse (max) hhfemale hhmale hhage hhveuf hhceleb handicap hh_handicap orphan orphan_d (sum) hhsizev1 hhsizev2 nage0_5 nage6_10 nage11_15 nage0_15 nage65plus, by(grappe menage)

gen lnsizev1=ln(hhsizev1)
gen lnsizev2=ln(hhsizev2)

sort grappe menage
tempfile tfcompos
save `tfcompos'

*===============================================================================
// Section D - Education
use "$gdData\Datain\Menage\s02_me_CIV2021.dta", clear
rename s01q00a numind
sort grappe menage numind
merge 1:1 grappe menage numind using `tfind'
g lit_fr=s02q01__1==1 | s02q02__1==1
gen hhlit=(lien==1 & lit_fr==1)

collapse (sum) lit_fr, by(grappe menage)

sort grappe menage
tempfile tfeduc
save `tfeduc'

*===============================================================================
// Section G - Elevage
use "$gdData\Datain\Menage\s17_me_CIV2021.dta", clear
count		// 142 912 obs.
numlabel, add
gen g1=1	
replace g1=0 if s17q03==.		
label var g1 "own animals (g1)"

label define yesAnimal 0 non 1 oui
label values g1 yesAnimal

tab g1 s17q02, m				// NOTE: category "poisson" is missing in data

ren (s17q02 s17q03 s17q06) (g2 g3 g4) 

keep grappe menage g1 g2 g3 g4	// KEEP only ownership and number of animals for PMT
keep if g1==1
ren g1 elevage

encode g2, gen(g2_x)
drop g2
rename g2_x g2
drop if g2==.

tostring g2, replace force
forvalues i=1/11 {		
	local x : word `i' of ane autVolaille boeuf chameau chevre cheval lapins mouton pintades cochon poulet 
	replace g2="`x'" if g2=="`i'"
}

recode g3 (2=0)
label values g3 oui
ren g3 el_		

recode g4 (. =0)
ren g4 nb_		// n=number of animals

reshape wide el_ nb_, i(grappe menage) j(g2) string
/*
g el_chameau = 0
g nb_chameau = 0
g el_cheval  = 0
g nb_cheval  = 0		//No instances of camels or horses in the survey responses. 
*/
sort grappe menage
merge 1:1 grappe menage using `tfsign'
recode elevage (. =0)
forvalues i=1/11 {
	local x : word `i' of ane autVolaille boeuf chameau chevre cheval lapins mouton pintades cochon poulet 
	replace el_`x'=0 if elevage==0
	replace nb_`x'=0 if elevage==0
	label var el_`x' "elevage de `x': 1=oui, 0=non"
	label var nb_`x' "nombre des betails: `x'"
}
global evlist  el_ane el_autVolaille el_boeuf el_chameau el_chevre el_cheval el_lapins el_mouton el_pintades el_cochon el_poulet
di "$evlist" 
keep grappe menage elevage el* nb*
sort grappe menage
tempfile tfelevage
save `tfelevage'

*===============================================================================
// Section 12 Household assets
use "$gdData\Datain\Menage\s12_me_CIV2021.dta", clear													// REPLACE WITH K only data file???
numlabel , add

clonevar asset=s12q01       // kname=asset
tostring asset, replace force
forvalues i=1/45 {
	local x : word `i' of salon	tableAmanger lit matela	armoir_aut_meubl	tapis   ///
	fer_a_repElec	ferArepCharb cuisAgazElec	bonbonneGaz rechGazElec             ///
	fourMicroOndeElec foyerAmeliore	robotCuisElec	mixeurNonElec	refrigerateur   ///
	congelateur	ventSurPied	radio tv magnetoscope antParabDecod	lavLingSechLing     ///
	aspirateur	climatiseur	tondeuseGazon	groupElectrog voiture	moto	velo    ///
	appPhoto camescope chaineHiFi	telFixe	telPortable	tablette ordinateur	        ///
	imprim_Fax	cameraVideo	pirogHorsBord	fusilChass	guitare	pianoAutAppMus	    ///
	imb_maison	terrainNonBati

	replace asset="`x'" if asset=="`i'"
	local assetlist `assetlist' a_`x' 
}

di "`assetlist'"
global assetlist `assetlist'

recode s12q02 (2=0), gen(a_)

keep a_ grappe menage asset 
reshape wide a_, i(grappe menage) j(asset) string

forvalues i=1/45 {
	local x : word `i' of salon	tableAmanger lit matela	armoir_aut_meubl	tapis   ///
	fer_a_repElec	ferArepCharb cuisAgazElec	bonbonneGaz rechGazElec             ///
	fourMicroOndeElec foyerAmeliore	robotCuisElec	mixeurNonElec	refrigerateur   ///
	congelateur	ventSurPied	radio tv magnetoscope antParabDecod	lavLingSechLing     ///
	aspirateur	climatiseur	tondeuseGazon	groupElectrog voiture	moto	velo    ///
	appPhoto camescope chaineHiFi	telFixe	telPortable	tablette ordinateur	        ///
	imprim_Fax	cameraVideo	pirogHorsBord	fusilChass	guitare	pianoAutAppMus	    ///
	imb_maison	terrainNonBati	
	label variable a_`x' "`x' en bon etat"
}

sort grappe menage
tempfile tfavoir
save `tfavoir'

*===============================================================================
// Section 11 - Housing
use "$gdData\Datain\Menage\s11_me_CIV2021.dta", clear

clonevar l_type=s11q01
clonevar l_murs=s11q18
clonevar l_sol=s11q20
clonevar l_toit=s11q19
clonevar l_piece=s11q02
clonevar l_eau=s11q26a
clonevar l_eclair=s11q37
clonevar l_ordure=s11q53
clonevar l_toilette=s11q54
*clonevar l_tabouret=o24a
*clonevar l_chaise=o24b
*clonevar l_table=o24c
*clonevar l_fauteuil=o24d
*clonevar l_douche=o27

global loge_vlist l_type l_murs l_sol l_toit l_piece l_eau l_eclair l_ordure l_toilette 

keep grappe menage $loge_vlist 

gen l_type_appart=(l_type==1)
gen l_type_villa=(l_type==2)
gen l_type_bandeImm=(l_type==3)
gen l_type_bandePart=(l_type==4)
gen l_type_ccom=(l_type==5)
gen l_type_msisole=(l_type==6)
gen l_type_case=(l_type==7)
gen l_type_barraq=(l_type==8)

gen l_murs_cimBetonPier=(l_murs==1)  
gen l_murs_briqCuite=(l_murs==2)  
gen l_murs_bacAluVitre=(l_murs==3)  
gen l_murs_bancoAmSemidur=(l_murs==4)  
gen l_murs_planchTole=(l_murs==5)  
gen l_murs_pierreTrad=(l_murs==6)  
gen l_murs_pailleBanco=(l_murs==7)  
gen l_murs_autre=(l_murs==8)  
				
gen l_sol_carrMarb=(l_sol==1) 
gen l_sol_ciment=(l_sol==2) 
gen l_sol_terre=(l_sol==3)
gen l_sol_bouse=(l_sol==4)
gen l_sol_autre=(l_sol==5) 
			
gen l_toit_dalle=(l_toit==1)
gen l_toit_tuile=(l_toit==2)
gen l_toit_tole=(l_toit==3)
gen l_toit_paille=(l_toit==4)
gen l_toit_banco=(l_toit==5)
gen l_toit_chaume=(l_toit==6)
gen l_toit_natte=(l_toit==7)
gen l_toit_autre=(l_toit==8)

gen l_lnpiece=ln(l_piece)  

gen l_eau_robinloge=(l_eau==1)
gen l_eau_robincour=(l_eau==2)
gen l_eau_robinextr=inlist(l_eau,3,4)
gen l_eau_puitcour=inlist(l_eau,5,7)  // puit ouvert ou fermé dans la cour
gen l_eau_puitext=inlist(l_eau,6,8)   // puit ouvert ou fermé dans la cour   
gen l_eau_foragecour=(l_eau==9)
gen l_eau_forageext=(l_eau==10)
gen l_eau_surface=inlist(l_eau,11,12,13)
gen l_eau_autre=inrange(l_eau,14,17)   // revoir s'il faudra eclater
  
gen l_eclair_elecRes=(l_eclair==1)
gen l_eclair_elecGen=(l_eclair==2)
gen l_eclair_lampePetrole=(l_eclair==3)
gen l_eclair_lampePile=(l_eclair==4)
gen l_eclair_parBoisPlch=(l_eclair==5)
gen l_eclair_solaire=(l_eclair==6)
gen l_eclair_autre=(l_eclair==7)

gen l_ordure_public=(l_ordure==1)  
gen l_ordure_ramassg=(l_ordure==2)  
gen l_ordure_brule=(l_ordure==3)  
gen l_ordure_enterre=(l_ordure==4)  
gen l_ordure_depSauvg=(l_ordure==5) 
gen l_ordure_autr=(l_ordure==6)  
 
gen l_toilet_wcint=(l_toilette==1)
gen l_toilet_wcext=(l_toilette==2)
gen l_toilet_intManuel=(l_toilette==3)
gen l_toilet_extManuel=(l_toilette==4) 
gen l_toilet_latVIP=(l_toilette==5)
gen l_toilet_latECOSAN=(l_toilette==6)
gen l_toilet_SANPLAT=(l_toilette==7)
gen l_toilet_latDalSimple=(l_toilette==8)
gen l_toilet_fossRud=(l_toilette==9)
gen l_toilet_toilPub=(l_toilette==10)
gen l_toilet_nature=(l_toilette==11)
gen l_toilet_autre=(l_toilette==12)

sort grappe menage
tempfile tfloge
save `tfloge'


*===============================================================================
// Consommation et Pauvrete
use "$gdData\Dataout\ehcvm_welfare_CIV2021.dta", clear
g poor = pcexp<= zref
ta poor [aw= hhweight*hhsize]     // p0=39.45  
keep grappe menage pcexp zref hhweight hhsize milieu zae
g milieu2 = 0
replace milieu2 = 1 if milieu==1 & zae==6		//Abidjan urban
replace milieu2 = 2 if milieu==1 & zae!=6		//Other urban
replace milieu2 = 3 if milieu==2 				//Rural

ren hhweight pond     
tempfile tfaggINS
save `tfaggINS'

// merge in weights and location variables
use `tfpondi', clear
sort grappe menage
merge m:1 grappe menage using `tfaggINS'
tab _m
drop _m
merge m:1 grappe menage using `tfsign'
tab _m
drop _m

gen lnpce = ln(pcexp)
label var lnpce "ln(pcexp)"

g lnzref=ln(zref)   // 12.75281

sort grappe menage
tempfile tfconsom
bys grappe menage : keep if _n==1 
save `tfconsom'

*===============================================================================
// MERGE files

use `tfsign', clear
*sort grappe menage

merge 1:1 grappe menage using `tfconsom'
tab _m
drop _m
*sort grappe menage

merge 1:1 grappe menage using `tfcompos'
tab _m
drop _m
*sort grappe menage

merge 1:1 grappe menage using `tfelevage'
tab _m
drop _m
*sort grappe menage

merge 1:1 grappe menage using `tfavoir'
tab _m
drop _m
sort grappe menage

merge 1:1 grappe menage using `tfloge'
tab _m
drop _m
*sort grappe menage

ren pond pondm	
gen popwt=pondm*hhsizev2


g rdepend1=((nage0_15)/(hhsizev2))							
g rdepend2=((nage0_15+nage65plus)/(hhsizev2)) // 
g lnrdepend1=ln(rdepend1+1)
g lnrdepend2=ln(rdepend2+1)

g lnnage0_15=ln(nage0_15+1) 
g lnnage65plus=ln(nage65plus+1)


count
*12,992 obs. at household level
isid grappe menage


************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************
*Now run the national model
************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************

merge 1:1 grappe menage using "$gdData\Dataout\ehcvm_welfare_CIV2021.dta"
*ok
drop _m

//  ADD administrative area variables
*tab adm1, gen(district)
tab milieu2, gen(strate)	
tab adm2, gen(region)
tab adm3, gen(depart)
*global adm1list district2-district14
global amd0list strate1 strate2 strate3
global amd2list region1-region33
global amd3list depart1-depart108

*check national poverty rate estimate

*histogram pcexp
*histogram lnpce

gen pauvre = (pcexp < zref)
*mean pauvre [pw=hhweight*hhsize]
*39.448%


gen cond = 1 if milieu2==3 //rural
replace cond = 2 if milieu2==1 & adm2_region==1 //Abidjan
replace cond = 3 if milieu2==2 & adm2_region!=1

tab milieu2 cond
*ok


gl dvarlist "lnsizev2 strate1 strate2 strate3 nage0_5 hhceleb nage65plus hhfemale"
gl living "l_sol_carrMarb l_eclair_elecRes l_lnpiece l_toilet_wcint l_ordure_ramassg l_sol_terre l_toit_dalle l_type_appart l_murs_cimBetonPier l_toilet_intManuel l_toilet_extManuel l_toilet_wcext l_type_case l_ordure_depSauvg l_eclair_lampePile l_type_villa l_eau_robinloge l_eau_robincour l_toilet_latECOSAN l_eclair_lampePetrole l_toilet_latDalSimple l_eau_autre"
gl possession "a_ventSurPied a_ordinateur a_climatiseur a_velo a_tapis a_refrigerateur a_bonbonneGaz a_cuisAgazElec a_telPortable a_voiture a_fer_a_repElec a_tv a_mixeurNonElec a_lit a_magnetoscope a_salon a_fusilChass"
gl adminregional "region1 region2 region3 region4 region5 region6 region7 region8 region9 region10 region11 region12 region13 region14 region15 region16 region17 region18 region19 region20 region21 region22 region23 region24 region25 region26 region27 region28 region29 region30 region31 region32 region33"

gl xcontrol "$dvarlist $living $possession $adminregional"


#delimit;
estimates drop _all;
reg lnpce $xcontrol [pw=hhweight*hhsize], vce(robust);  
estimates store National;
	predict lnPredCons;
	gen pmtPredCons=exp(lnPredCons);
gen r2=e(r2);
#delimit cr

*outreg2 [National] using "$d4\PMT_RobustOLS_june20201.rtf",  replace label word 
	
*estimates drop _all
*scatter lnPredCons lnpce


************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************
*Now create the imputed PMT score, to identify households for targeting
************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************
*-------------------------------------------------------------------------------
*OPEN MASTER FILE WITH KEY VARIABLES AND WELFARE INDICATORS
*-------------------------------------------------------------------------------

isid grappe menage
count
*12,992 households

drop _est_National r2
*----------------------------------------------------------------------

tab adm2_region
tab pauvre

sum pcexp if pauvre==0
sum pcexp if pauvre==1

/*ACTUAL POVERTY
. povdeco pcexp [aw=hhweight*hhsize], pl(345520.3)
 
Foster-Greer-Thorbecke poverty indices, FGT(a)

----------------------------------------------
  All obs |        a=0         a=1         a=2
----------+-----------------------------------
          |    0.39448     0.11595     0.04702
----------------------------------------------
FGT(0): headcount ratio (proportion poor)
FGT(1): average normalised poverty gap
FGT(2): average squared normalised poverty gap
*/




/*PMT-based poverty
. povdeco pmtPredCons [aw=hhweight*hhsize], pl(345520.3)
 
Foster-Greer-Thorbecke poverty indices, FGT(a)

----------------------------------------------
  All obs |        a=0         a=1         a=2
----------+-----------------------------------
          |    0.38996     0.08599     0.02679
----------------------------------------------
FGT(0): headcount ratio (proportion poor)
FGT(1): average normalised poverty gap
FGT(2): average squared normalised poverty gap
*/

tab milieu,m
tab milieu2,m
tab region milieu,m
tab adm3_dept milieu,m

egen region_urbrur = group(milieu region), label


*-------------------------------------------------------------------------------
*ACTUAL POVERTY

/*Poverty line: 345520.3 FCFA
povdeco pcexp [aw=hhweight*hhsize], pl(345520.3)
povdeco pcexp [aw=hhweight*hhsize], pl(345520.3) by(milieu)
povdeco pcexp [aw=hhweight*hhsize], pl(345520.3) by(milieu2)
povdeco pcexp [aw=hhweight*hhsize], pl(345520.3) by(region)
povdeco pcexp [aw=hhweight*hhsize], pl(345520.3) by(region_urbrur)

*Extreme Poverty line: 238225.5 FCFA
povdeco pcexp [aw=hhweight*hhsize], pl(238225.5)
povdeco pcexp [aw=hhweight*hhsize], pl(238225.5) by(milieu)
povdeco pcexp [aw=hhweight*hhsize], pl(238225.5) by(milieu2)
povdeco pcexp [aw=hhweight*hhsize], pl(238225.5) by(region)
povdeco pcexp [aw=hhweight*hhsize], pl(238225.5) by(region_urbrur)
*/


gen x = hhweight*hhsize
egen y = sum(x)
*25511452
display 25511452*0.39448 //Poor
*10063758
display 25511452*0.17374 //Extreme poor
*4432359.7
**display 10063758/0.39448 //25511453
gen z = 25511452/y
gen pop_weight = hhweight*hhsize*z

drop x y z

sum hhsize
*4.648


/*NOTE: estimation de la population pauvre: 12992 menages, 61116 individus dans l'echantillon 
		Population pauvre: 10 063 758 
		Population pauvrete exreme: 4 432 359.7 ~= 4 432 360 */
				
*-------------------------------------------------------------------------------		
tabstat pmtPredCons[aw=hhweight*hhsize], s(n min mean max) by(pauvre)
egen pmtp50 =median(pmtPredCons), by(region)
gen pmtimput = pmtPredCons
replace pmtimput=pmtp50 if (pmtPredCons==.)
*2 changes made
la var pmtimput "Imputed predicted PMT score"
drop pmtp50


local list "20 25 30 35 40 50 75"
foreach t of numlist `list' {
	foreach x of varlist pmtimput {
		_pctile `x' [aw=hhweight], p(`t') 
		gen cut_`x'_`t'=r(r1) // here we define the cutoffs 
		gen poor_`x'_`t'=(`x'<=cut_`x'_`t') // here we define everyone who has a score below the cutoff as poor
	}
}

*NOTE: WE KEEP poor_pmtimput_40 as per analysis of the PMT, undercoverage and inclusion error reach optimal points
drop cut_pmtimput_20 poor_pmtimput_20 cut_pmtimput_25 poor_pmtimput_25 cut_pmtimput_30 poor_pmtimput_30 cut_pmtimput_35 poor_pmtimput_35 cut_pmtimput_50 poor_pmtimput_50 cut_pmtimput_75 poor_pmtimput_75

collapse (max)poor_pmtimput_40, by(hhid)

save "$gdTemp\CIV_PMT_2021.dta", replace

************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************
*Now simulate the beneficiaries from the survey 
************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************

*use "$gdData\Datain\Menage/s04_me_CIV2021.dta", clear
use "$gdData\Datain\Menage/s04a_me_CIV2021.dta", clear
merge 1:1 grappe menage s01q00a using "$gdData\Datain/Menage/s04b_me_CIV2021.dta", nogen
merge 1:1 grappe menage s01q00a using "$gdData\Datain/Menage/s04c_me_CIV2021.dta", nogen  
destring grappe, replace
g hhid=grappe*100+menage 
rename s01q00a numind

merge 1:1 vague grappe menage numind using "$gdData\Dataout\ehcvm_individu_CIV2021.dta", keepusing(hhweight region milieu educ_hi)
drop _merge
drop if hhid==.
rename hhweight weight
rename milieu urban
recode urban (2=0)
g hoh_educ = (numind==1 & educ_hi>3) //hoh has an education higher than primary school >=6 is graduated secondary
g ambition = 0
replace ambition = 1 if s04q18==8 //household is waiting to start own business (359 obs)


merge m:1 hhid using "$gdData\Dataout\ehcvm_welfare_CIV2021.dta", keepusing(pcexp)
drop _merge

******************************************************************************************
*Step 1 - Describe Program Parameters
******************************************************************************************
/*

Program beneficiaries receive 36,000 FCFA each quarter over 3 years period, i.e., 12 transfers over the project cycle. Each household in this analysis will then receive 144,000
*IH: are the "cohorts" divided by different year start dataes? So that the total distribution of households will not exactly be this way? 
*/ 
*Total beneficiary households * regional beneficiary share, taken as proportion of survey population.
loc reghh_1   = 0			//  50,000 * 0.000 
loc reghh_2   = 4			//  50,000 * 0.039 
loc reghh_3   = 10			//  50,000 * 0.088 
loc reghh_4   = 8			//  50,000 * 0.079 
loc reghh_5   = 0			//  50,000 * 0.000 
loc reghh_6   = 19			//  50,000 * 0.187 
loc reghh_7   = 0			//  50,000 * 0.000 
loc reghh_8   = 0			//  50,000 * 0.000 
loc reghh_9   = 0			//  50,000 * 0.000 
loc reghh_10  = 11			//  50,000 * 0.033 
loc reghh_11  = 0			//  50,000 * 0.000 
loc reghh_12  = 11			//  50,000 * 0.098 
loc reghh_13  = 0			//  50,000 * 0.000 
loc reghh_14  = 8			//  50,000 * 0.033 
loc reghh_15  = 0			//  50,000 * 0.000 
loc reghh_16  = 0			//  50,000 * 0.000 
loc reghh_17  = 0			//  50,000 * 0.000 
loc reghh_18  = 0			//  50,000 * 0.000 
loc reghh_19  = 7			//  50,000 * 0.025 
loc reghh_20  = 8			//  50,000 * 0.042 
loc reghh_21  = 20			//  50,000 * 0.100 
loc reghh_22  = 10			//  50,000 * 0.053 
loc reghh_23  = 9			//  50,000 * 0.040 
loc reghh_24  = 11			//  50,000 * 0.016 
loc reghh_25  = 0			//  50,000 * 0.000 
loc reghh_26  = 0			//  50,000 * 0.000 
loc reghh_27  = 0			//  50,000 * 0.000 
loc reghh_28  = 6			//  50,000 * 0.040 
loc reghh_29  = 10			//  50,000 * 0.063 
loc reghh_30  = 0			//  50,000 * 0.000 
loc reghh_31  = 0			//  50,000 * 0.000
loc reghh_32  = 11			//  50,000 * 0.062 
loc reghh_33  = 0			//  50,000 * 0.000  

******************************************************************************************
*Step 2 - Identify vulnerable households by PMT
******************************************************************************************
merge m:1 hhid using "$gdTemp\CIV_PMT_2021.dta", keepusing(poor_pmtimput_40)
drop _merge
drop if weight==.

tab poor_pmtimput_40
gen poor_act = (pcexp < 345520.3)			//1,919 households in survey -- matching WB
gen extrempoor_act = (pcexp < 238225.5)		//4,547 households in survey -- matching WB

*Collapse to household level
collapse (max)poor_act extrempoor_act poor_pmtimput_40 region urban, by(hhid weight)

*Randomly identify poor households with the lowest PMT score until we reach the target number of households in each region and in each milieu
g dtr_elig = 0

*I think this is only for rural households in the first cohort. At least the beneficiary household figures do not differentiate in the first cohort as they do for the rest. 
set seed 5989
foreach reg of numlist 1/33{
		gen runif=runiform() if (region== `reg' & poor_act==1 & urban==0 & poor_pmtimput_40==1)
		sort runif 
		replace dtr_elig=1 if _n<= `reghh_`reg'' & urban==0 & region==`reg'
		drop runif
	}

	gen runif=runiform() if dtr_elig==1
	sort runif
	g dtr_elig2 = 0
	replace dtr_elig2 = 1 if _n<= 50 & dtr_elig==1
	drop runif
	
	replace dtr_elig=0 if dtr_elig2==1

*Allocate benefits to households
g dtr_pssn_hh = 0
g oth_econ_hh = 0

*WB 2022 (PSSN Status and Result Report)
*1,260,326 beneficiaries of safety net
*  227,000 beneficiaries of cash transfers
*  125,000 participants in economic inclusion

*$96m USD: cash transfers	/	4 = annual expenditure of $24m	=    XOF 14,430,513,600.00	/ 227,000 = 63,570.54		(source: Social Protection and Economic Inclusion Project Execution Manual)
*$35m USD: economic inclusion / 3 = annual expenditure of $11.666m = XOF  7,098,113,927.73	/ 125,000 = 56,784.90

********
*But the SP calculation has 177,000 beneficiaries receiving 4 quarterly cash transfer payments, an additional 15,000 receiving only 3
*And an economic inclusion has 15,000 participants getting 110.8, and 77,000 getting 83.1

save "$gdOut\dtr_base.dta", replace

**********************************************************************************************************************************
******************************************************************************************
*For Family Allowance, I think we can distibute the statutory benefits to those eligible families. For the Industrial Accident, I think we should use the insurance-value approach and distribute the admin amount among all workers eligible. 
clear all
use "$gdTemp\formal.dta", clear

merge 1:1 vague grappe menage numind using "$gdData\Dataout\ehcvm_individu_CIV2021.dta", keepusing(mstat age sex lien)
drop _merge

*Family Allowance - the only source of funds comes from employer contributions, so the eligible families must have a maternity insurance benefit. No self-employed persons are funded.
/*F Allowance includes 
	1. Family Allowance -  1,500 CFA francs a month is paid for each child age 2-13 (18 if apprentice or 21 if a student or disabled)
	2. Prenatal Allowance -  13,500 CFA francs is paid in three installments
	3. Birth Grant - A lump sum of 18,000 CFA francs is paid on the birth of each of the first three children
	4. Maternity Allowance - 18,000 CFA francs is paid in three installments
*/
g fama_elig=0
replace fama_elig = 1 if s04q32>=3		//To benefit the recipient must have been employed for 3 or more months

bysort hhid: egen maternity2 = max(maternity)
replace maternity2 = 0 if inlist(lien,4,5,6,7,8,9,10) //restricting benefits to immediate family within household
replace fama_elig=1 if maternity2==1

foreach num of numlist 1/4{
g fama_elig`num'=0
g dtr_fama`num'=0
}

*family allowance
preserve
	use "$gdData\Datain\Menage/s02_me_CIV2021.dta", clear
	destring grappe, replace
	g hhid=grappe*100+menage 
	rename s01q00a numind
	gen enrolled = 0
	replace enrolled = 1 if s02q03==1 & s02q12==1	//attending school in formal institution
	replace enrolled = 2 if s02q03==2		//attending school in informal school
	g enrolled_voca = (s02q14==4 | s02q14==6) & enrolled==1
	tempfile educenrollment
	save `educenrollment', replace
restore

merge 1:1 vague grappe menage numind using `educenrollment' , keepusing(enrolled enrolled_voca)
drop _merge
drop if hhid==.

g child_elig = (age>1 & age<14 & age!=.) 
replace child_elig = 1 if (age>13 & age<19) & enrolled_voca==1
replace child_elig = 1 if (age>13 & age<22) & enrolled==1
g newborn = (age<1)
g yearold = (age>=1 & age<2)
g child = (lien==3)
bysort hhid: egen total_child = sum(child)
replace fama_elig3 = 1 if newborn==1
replace mstat=0 if mstat!=2 		//only children born in 1st marriages are eligible for birth grant
replace fama_elig3=0 if mstat==0

save "$gdOut\dtr_famind_base.dta", replace


***************************************************************************************
***************************Indirect Taxes**********************************************
***************************************************************************************
****************VAT******************
use "$gdData\Dataout\ehcvm_conso_CIV2021.dta", clear
keep if modep==1 | modep==4		// keep only purchased items

rename codpr itemid
rename depan cons_val
rename milieu urban
rename hhweight weight

*cluster = ea = psu? 
*annualize	//already annualized

*drop if items are not relevant
drop if itemid==205 | itemid==331 | itemid==630 | itemid==653	//firewood collected; house rent; motor vehicle tax; housing taxes
 
**********************************************************************
gen io = .

replace io = 2  if itemid== 1      //Local coarse grain rice
replace io = 2  if itemid== 2      //Local long grain rice
replace io = 1  if itemid== 3      //Popular imported rice (dénicachia)
replace io = 1  if itemid== 4      //Luxury imported long grain rice
replace io = 2  if itemid== 5      //Corn on the cob
replace io = 2  if itemid== 6      //Dried corn kernels (excluding popcorn corn
replace io = 2  if itemid== 7      //Millet
replace io = 2  if itemid== 8      //Sorghum
replace io = 2  if itemid== 10     //Fonio
replace io = 2  if itemid== 11     //Other grain cereals (to be specified) i
replace io = 11 if itemid== 12     //Corn flour
replace io = 11 if itemid== 13     //Cornmeal
replace io = 11 if itemid== 14     //Millet flour
replace io = 11 if itemid== 15     //Millet semolina
replace io = 11 if itemid== 16     //Local or imported wheat flour
replace io = 11 if itemid== 17     //Wheat couscous
replace io = 12 if itemid== 20     //Pasta
replace io = 12 if itemid== 21     //Modern bread
replace io = 12 if itemid== 22     //Traditional bread
replace io = 12 if itemid== 23     //Croissants
replace io = 12 if itemid== 24     //Cookies
replace io = 12 if itemid== 25     //Cakes
replace io = 12 if itemid== 26     //Donuts, pancakes
replace io = 9  if itemid== 27     //Beef
replace io = 9  if itemid== 29     //Mutton
replace io = 9  if itemid== 30     //Goat meat
replace io = 9  if itemid== 31     //Other offal (liver, kidney, head, leg
replace io = 9  if itemid== 32     //Pork meat
replace io = 4  if itemid== 33     //Chicken on foot
replace io = 9  if itemid== 34     //Chicken meat
replace io = 9  if itemid== 35     //Meat of other domestic poultry (
replace io = 9  if itemid== 36     //Cold meats (ham, sausage), conser
replace io = 9  if itemid== 37     //Dried meat (beef, mutton, camel,
replace io = 9  if itemid== 38     //Game (bush meat)
replace io = 9  if itemid== 39     //Other meats n.e.s. (to be specified lapi
replace io = 7  if itemid== 40     //Fresh Appolo fish
replace io = 7  if itemid== 41     //White carp
replace io = 7  if itemid== 42     //Fresh fish Red carp
replace io = 7  if itemid== 43     //Captain fresh fish
replace io = 7  if itemid== 44     //Smoked fish Herring (Mangni)
replace io = 7  if itemid== 45     //Smoked fish Mackerel
replace io = 7  if itemid== 46     //Smoked sardinella
replace io = 7  if itemid== 47     //Crabs
replace io = 7  if itemid== 48     //Fresh shrimp
replace io = 7  if itemid== 49     //Dried shrimp
replace io = 7  if itemid== 50     //Other seafood (crayfish, etc.)
replace io = 7  if itemid== 51     //Canned fish
replace io = 14 if itemid== 52     //Fresh cow's milk
replace io = 15 if itemid== 53     //Curd, yogurt, disgusting
replace io = 15 if itemid== 54     //Sweetened condensed milk
replace io = 15 if itemid== 55     //Unsweetened condensed milk
replace io = 14 if itemid== 56     //Powdered milk
replace io = 15 if itemid== 57     //Cheese
replace io = 14 if itemid== 58     //Baby milk and flour
replace io = 15 if itemid== 59     //Other dairy products (crème fraîche
replace io = 15 if itemid== 60     //Eggs
replace io = 10 if itemid== 61     //Butter and Margarine
replace io = 10 if itemid== 62     //Shea Butter
replace io = 10 if itemid== 63     //Red palm oil
replace io = 10 if itemid== 64     //Refined peanut oil
replace io = 10 if itemid== 67     //Cottonseed oil
replace io = 10 if itemid== 68     //Refined palm oil
replace io = 2  if itemid== 69     //Palm nut (palm seed)
replace io = 10 if itemid== 70     //Other oils n.e.s. (corn, palm oil
replace io = 2  if itemid== 71     //Mango
replace io = 2  if itemid== 72     //Pineapple
replace io = 2  if itemid== 73     //Orange
replace io = 2  if itemid== 74     //Lemon
replace io = 2  if itemid== 75     //Other citrus fruits (mandarin, grapefruit
replace io = 2  if itemid== 76     //Sweet banana
replace io = 2  if itemid== 77     //Lawyer
replace io = 2  if itemid== 78     //Watermelon
replace io = 2  if itemid== 79     //Melon
replace io = 2  if itemid== 80     //Dates
replace io = 2  if itemid== 81     //Coconut
replace io = 2  if itemid== 82     //Sugar cane
replace io = 2  if itemid== 83     //Apples
replace io = 2  if itemid== 84     //Papaya
replace io = 2  if itemid== 85     //Baobab fruit
replace io = 2  if itemid== 86     //Nere
replace io = 2  if itemid== 87     //Other fruits (black tamarind, wild liana
replace io = 2  if itemid== 88     //Salad (lettuce)
replace io = 2  if itemid== 89     //Cabbage
replace io = 2  if itemid== 90     //Carrot
replace io = 2  if itemid== 91     //Green bean
replace io = 2  if itemid== 92     //Cucumber
replace io = 2  if itemid== 93     //Eggplant
replace io = 2  if itemid== 94     //Squash/Zucchini
replace io = 2  if itemid== 95     //Fresh pepper
replace io = 2  if itemid== 96     //Fresh tomato
replace io = 2  if itemid== 97     //Dried tomato
replace io = 2  if itemid== 98     //Fresh okra
replace io = 2  if itemid== 99     //Dry/dried/pounded/powdered okra (djoumgbé
replace io = 2  if itemid== 100    //Fresh onion
replace io = 2  if itemid== 101    //Garlic
replace io = 2  if itemid== 102    //Sorrel leaves (dah)
replace io = 2  if itemid== 103    //Potato leaves
replace io = 2  if itemid== 104    //Spinach
replace io = 2  if itemid== 105    //Kplala
replace io = 2  if itemid== 106    //Other leaves (cassava, taro, baobab,
replace io = 2  if itemid== 107    //Other fresh vegetables n.e.s. (eggplant v
replace io = 15 if itemid== 108    //Tomato concentrate
replace io = 2  if itemid== 109    //Peas
replace io = 2  if itemid== 110    //Dried peas
replace io = 2  if itemid== 111    //Other dried vegetables n.e.s. (soy, pista
replace io = 2  if itemid== 112    //Cowpea/Dried beans
replace io = 2  if itemid== 113    //Fresh peanuts in shells
replace io = 2  if itemid== 114    //Dried peanuts in shells
replace io = 2  if itemid== 115    //Shelled peanuts
replace io = 2  if itemid== 116    //Pounded/crushed peanuts
replace io = 2  if itemid== 117    //Roasted peanut
replace io = 15 if itemid== 118    //Peanut paste
replace io = 15 if itemid== 119    //Soy-based cheese
replace io = 2  if itemid== 120    //Sesame
replace io = 2  if itemid== 121    //Cashew nuts
replace io = 2  if itemid== 123    //Cassava
replace io = 2  if itemid== 124    //Yam
replace io = 2  if itemid== 125    //Plantain
replace io = 2  if itemid== 126    //Potato
replace io = 2  if itemid== 127    //Taro, macabo
replace io = 2  if itemid== 128    //Yam
replace io = 2  if itemid== 130    //Cassava flours
replace io = 2  if itemid== 131    //Gari, tapioca
replace io = 2  if itemid== 132    //Attiéke/Atoukpou
replace io = 15 if itemid== 134    //Powdered sugar
replace io = 15 if itemid== 135    //Sugar pieces
replace io = 15 if itemid== 136    //Honey
replace io = 15 if itemid== 137    //Chewable chocolate, spread
replace io = 15 if itemid== 138    //Caramel, sweets, confectionery, etc.
replace io = 15 if itemid== 139    //Salt
replace io = 15 if itemid== 140    //Dried chili pepper/powder
replace io = 2  if itemid== 141    //Fresh chili pepper
replace io = 2  if itemid== 142    //Fresh ginger
replace io = 2  if itemid== 143    //Grounded ginger
replace io = 15 if itemid== 144    //Food cube (Maggi, Jumbo, )
replace io = 15 if itemid== 145    //Flavor (Maggi, aromatic, adja, etc.)
replace io = 15 if itemid== 146    //Soumbala (African mustard)
replace io = 15 if itemid== 147    //Mayonnaise
replace io = 15 if itemid== 149    //Other vinegars
replace io = 15 if itemid== 150    //Mustard
replace io = 2  if itemid== 151    //Pepper
replace io = 15 if itemid== 152    //Other condiments (akpi etc)
replace io = 15 if itemid== 153    //Cola nuts
replace io = 15 if itemid== 154    //Other food products (mushroom
replace io = 13 if itemid== 155    //Coffee powder (ground)
replace io = 13 if itemid== 156    //Soluble coffee (instant)
replace io = 13 if itemid== 157    //Tea (instant)
replace io = 13 if itemid== 158    //Chocolate powder
replace io = 13 if itemid== 159    //Other herbal teas and infusions n.e.s. (which
replace io = 16 if itemid== 160    //Traditional fruit juice (orange, bis
replace io = 16 if itemid== 161    //Mineral/filtered water
replace io = 16 if itemid== 162    //Carbonated drinks (cokes, etc.)
replace io = 16 if itemid== 163    //Juice powder
replace io = 16 if itemid== 164    //Traditional beers and wines (Tchapalo,
replace io = 16 if itemid== 165    //Industrial beers (Bock, Guinness, I
replace io = 1  if itemid== 166    //Imported broken rice
replace io = 11 if itemid== 167    //Breakfast cereals (Quaker
replace io = 12 if itemid== 168    //Other bakery products (bread
replace io = 12 if itemid== 169    //Sweet bread
replace io = 9  if itemid== 170    //Tripe (intestine and stomach)
replace io = 4  if itemid== 171    //Other live domestic poultry (
replace io = 9  if itemid== 172    //Snails
replace io = 14 if itemid== 173    //Fresh sterilized milk without sugar, half-soured
replace io = 15 if itemid== 174    //Cassava paste (placali)
replace io = 15 if itemid== 175    //Dried fish as a condiment (adjovan)
replace io = 13 if itemid== 176    //Tea Leaf (Black Tea)
replace io = 16 if itemid== 177    //Manufactured fruit juice (orange, mango
replace io = 40 if itemid== 191    //Breakfast outside the household
replace io = 40 if itemid== 192    //Lunch outside the household
replace io = 40 if itemid== 193    //Dinner outside the household
replace io = 40 if itemid== 194    //Non-household snack
replace io = 40 if itemid== 195    //Hot drinks outside the household
replace io = 40 if itemid== 196    //Non-alcoholic drink outside household
replace io = 40 if itemid== 197    //Non-household alcoholic beverage
replace io = 17 if itemid== 201    //Cigarettes/Tobacco
replace io = 23 if itemid== 202    //Lamp oil
replace io = 8  if itemid== 203    //Charcoal/mineral
replace io = 20 if itemid== 204    //Firewood purchased
replace io = 38 if itemid== 206    //Candles
replace io = 38 if itemid== 207    //Matches
replace io = 23 if itemid== 208    //Vehicle fuel
replace io = 23 if itemid== 209    //Motorcycle fuel
replace io = 39 if itemid== 210    //Urban transport by taxi
replace io = 39 if itemid== 211    //Urban transport by bus
replace io = 39 if itemid== 212    //Urban transport by motorbike taxi
replace io = 39 if itemid== 213    //Urban transport by train
replace io = 39 if itemid== 214    //Urban transport waterway
replace io = 39 if itemid== 215    //Urban transport animal traction
replace io = 22 if itemid== 216    //Newspapers
replace io = 11 if itemid== 217    //Fresh cereal molding
replace io = 16 if itemid== 301    //Whiskey/other liqueurs
replace io = 16 if itemid== 302    //Modern wines
replace io = 8  if itemid== 303    //Domestic gas
replace io = 23 if itemid== 304    //Fuel for electric group.
replace io = 38 if itemid== 305    //Electric batteries
replace io = 24 if itemid== 306    //Soap/detergents
replace io = 24 if itemid== 307    //Insecticide, anti-mosquito twist
replace io = 51 if itemid== 308    //Housekeeping salary
replace io = 50 if itemid== 309    //Clothes laundering costs
replace io = 36 if itemid== 310    //Garbage collection fees
replace io = 50 if itemid== 311    //Vehicle washing
replace io = 39 if itemid== 312    //Parking fees
replace io = 41 if itemid== 313    //Telephone communication cabin
replace io = 46 if itemid== 314    //Lottery/PMU ticket
replace io = 22 if itemid== 315    //Magazines, newspaper or magazine
replace io = 50 if itemid== 316    //Hairdressing fees, manicure, pedicure
replace io = 38 if itemid== 317    //Toilet soap, shampoo
replace io = 38 if itemid== 318    //Toothpaste
replace io = 21 if itemid== 319    //Toilet paper
replace io = 38 if itemid== 320    //Serv. hyg., disposable baby diapers
replace io = 38 if itemid== 321    //Body milk, makeup products
replace io = 18 if itemid== 322    //Disposable COVID-19 mask
replace io = 36 if itemid== 332    //Running water bill
replace io = 36 if itemid== 333    //Water from dealer
replace io = 35 if itemid== 334    //Electricity bill
replace io = 41 if itemid== 335    //Landline phone bill
replace io = 41 if itemid== 336    //Internet bill
replace io = 41 if itemid== 337    //Cable subscription invoice
replace io = 41 if itemid== 338    //Mobile phone recharge
replace io = 50 if itemid== 401    //Shoe care costs
replace io = 38 if itemid== 402    //Electric light bulbs
replace io = 23 if itemid== 403    //Lubricants
replace io = 34 if itemid== 404    //Vehicle repair and maintenance
replace io = 39 if itemid== 405    //Inter-locality car transport
replace io = 39 if itemid== 406    //Inter-locality transport traction anima
replace io = 39 if itemid== 407    //Interlocal water transport
replace io = 50 if itemid== 408    //Postal stamp, money order shipping
replace io = 41 if itemid== 409    //Fax sending costs
replace io = 38 if itemid== 410    //Gardening products
replace io = 38 if itemid== 411    //Pet Food/Care
replace io = 50 if itemid== 412    //Entrance fee for sporting events
replace io = 50 if itemid== 413    //Cinema/concert/theater entry fee, and
replace io = 50 if itemid== 414    //Other recreational services (photo)
replace io = 18 if itemid== 415    //Washable mask against COVID-19
replace io = 25 if itemid== 416    //Medicines in pharmacies without a prescription
replace io = 24 if itemid== 417    //Scent
replace io = 38 if itemid== 418    //Toothbrush
replace io = 18 if itemid== 501    //Clothing fabrics
replace io = 18 if itemid== 502    //Women clothes
replace io = 18 if itemid== 503    //Women's underwear
replace io = 18 if itemid== 504    //Children's clothing
replace io = 18 if itemid== 505    //Men's clothing
replace io = 18 if itemid== 506    //Men's underwear
replace io = 50 if itemid== 507    //Cost of making men's clothing
replace io = 50 if itemid== 508    //Freshly made women's clothing
replace io = 50 if itemid== 509    //Cost of making children's clothing
replace io = 19 if itemid== 510    //Men's shoes
replace io = 19 if itemid== 511    //Women's shoes
replace io = 19 if itemid== 512    //Children's shoes
replace io = 18 if itemid== 521    //Party clothes/shoes
replace io = 37 if itemid== 601    //Equipment maintenance/repair. housing
replace io = 37 if itemid== 602    //Maintenance/repair labor. accommodation
replace io = 37 if itemid== 603    //Mast. const. (cement, bricks, etc.)
replace io = 37 if itemid== 604    //Aut. mast. const. (sheet metal, wood, electricity)
replace io = 37 if itemid== 605    //Construction labor
replace io = 37 if itemid== 606    //Well/drilling costs
replace io = 43 if itemid== 607    //Housing land acquisition costs
replace io = 37 if itemid== 608    //Architect study fees
replace io = 36 if itemid== 609    //Water network subscription fees
replace io = 35 if itemid== 610    //Electricity subscription fees
replace io = 36 if itemid== 611    //Water connection costs
replace io = 35 if itemid== 612    //Electricity connection costs
replace io = 33 if itemid== 613    //Living room furniture
replace io = 33 if itemid== 614    //Bed/mattress and other. bedroom furniture
replace io = 34 if itemid== 615    //Furniture repair
replace io = 18 if itemid== 616    //Household linens
replace io = 31 if itemid== 617    //Appliances
replace io = 30 if itemid== 618    //Solar plate
replace io = 30 if itemid== 619    //Solar plate battery/aut. equip. ground
replace io = 34 if itemid== 620    //Repair of household appliances
replace io = 38 if itemid== 621    //Dishes
replace io = 38 if itemid== 622    //Kitchen utensils
replace io = 38 if itemid== 623    //Other household utensils
replace io = 38 if itemid== 624    //Home tools
replace io = 38 if itemid== 625    //Lamps (electric, storms, torches)
replace io = 32 if itemid== 626    //Purchase of personal car
replace io = 32 if itemid== 627    //Personal motorcycle purchase
replace io = 32 if itemid== 628    //Medium locomotive spare parts.
replace io = 42 if itemid== 629    //Average locomotive insurance costs
replace io = 34 if itemid== 631    //Other vehicle services
replace io = 39 if itemid== 632    //Vehicle rental for personal use.
replace io = 39 if itemid== 633    //Inter-city transportation. by train
replace io = 39 if itemid== 634    //Airplane transportation
replace io = 39 if itemid== 635    //Moving expenses
replace io = 46 if itemid== 636    //Visa fees, airport taxes
replace io = 29 if itemid== 637    //Cell phone purchase
replace io = 29 if itemid== 638    //Music/image devices
replace io = 29 if itemid== 639    //Computer/printer/tablet, etc.
replace io = 34 if itemid== 640    //Electronic device repair
replace io = 29 if itemid== 641    //Small mate. electronic personal use.
replace io = 22 if itemid== 642    //Sports and relaxation articles
replace io = 22 if itemid== 643    //Non-school book, comic book
replace io = 21 if itemid== 644    //Paper ream/envelope/drawing item
replace io = 40 if itemid== 645    //Pilgrimage costs
replace io = 47 if itemid== 646    //Professional training
replace io = 47 if itemid== 647    //Private lesson fees for adults
replace io = 40 if itemid== 648    //Accommodation services: hotel, etc.
replace io = 38 if itemid== 649    //Watches, alarm clocks
replace io = 38 if itemid== 650    //Jewelry
replace io = 38 if itemid== 651    //Other personal effects
replace io = 42 if itemid== 652    //Home insurance costs/means trans.
replace io = 47 if itemid== 701    //Registration/tuition fees preschool
replace io = 47 if itemid== 702    //Preschool contributions
replace io = 22 if itemid== 703    //Preschool books/workbooks
replace io = 47 if itemid== 704    //Aut. preschool material
replace io = 18 if itemid== 705    //Preschool uniforms
replace io = 47 if itemid== 706    //Preschool canteen fees
replace io = 39 if itemid== 707    //Preschool transportation costs
replace io = 47 if itemid== 708    //Aut. (support, repeat.) preschool
replace io = 47 if itemid== 709    //Registration/tuition fees primary
replace io = 47 if itemid== 710    //Primary contributions
replace io = 22 if itemid== 711    //Primary books/notebooks
replace io = 47 if itemid== 712    //Aut. primary material
replace io = 18 if itemid== 713    //Primary uniforms
replace io = 47 if itemid== 714    //Primary canteen fees
replace io = 39 if itemid== 715    //Primary transport costs
replace io = 47 if itemid== 716    //Aut. (support, repeat.) primary
replace io = 47 if itemid== 717    //Registration/tuition fees secondary 1
replace io = 47 if itemid== 718    //Secondary contributions 1
replace io = 22 if itemid== 719    //Secondary 1 books/notebooks
replace io = 47 if itemid== 720    //Aut. secondary material 1
replace io = 18 if itemid== 721    //Secondary 1 uniforms
replace io = 47 if itemid== 722    //Secondary canteen fees 1
replace io = 39 if itemid== 723    //Secondary transport costs 1
replace io = 47 if itemid== 724    //Aut. (support, repeat.) secondary 1
replace io = 47 if itemid== 725    //Registration/tuition fees secondary 2
replace io = 47 if itemid== 726    //Secondary contributions 2
replace io = 22 if itemid== 727    //Secondary 2 books/notebooks
replace io = 47 if itemid== 728    //Aut. secondary material 2
replace io = 18 if itemid== 729    //Secondary 2 uniforms
replace io = 47 if itemid== 730    //Secondary canteen fees 2
replace io = 39 if itemid== 731    //Secondary transport costs 2
replace io = 47 if itemid== 732    //Aut. (support, repeat.) secondary 2
replace io = 47 if itemid== 733    //Registration/tuition fees post-secondary
replace io = 47 if itemid== 734    //Post-secondary contributions
replace io = 22 if itemid== 735    //Post-secondary books/notebooks
replace io = 47 if itemid== 736    //Aut. post-secondary material
replace io = 18 if itemid== 737    //Post-secondary uniforms
replace io = 47 if itemid== 738    //Post-secondary canteen fees
replace io = 39 if itemid== 739    //Post-secondary transportation costs
replace io = 47 if itemid== 740    //Aut. (support, repeat.) post-secondary
replace io = 47 if itemid== 741    //Registration/tuition fees superior
replace io = 47 if itemid== 742    //Higher contributions
replace io = 22 if itemid== 743    //Superior books/notebooks
replace io = 47 if itemid== 744    //Aut. superior material
replace io = 18 if itemid== 745    //Superior uniforms
replace io = 47 if itemid== 746    //Higher canteen fees
replace io = 39 if itemid== 747    //Higher transport costs
replace io = 47 if itemid== 748    //Aut. (support, repeat.) superior
replace io = 48 if itemid== 761    //Generalist consultation
replace io = 48 if itemid== 762    //Specialist consultation
replace io = 48 if itemid== 763    //Dentist consultation
replace io = 48 if itemid== 764    //Healer consultation
replace io = 48 if itemid== 765    //Medical examinations outside the hospital.
replace io = 48 if itemid== 766    //Medic. modern public outside hosp.
replace io = 48 if itemid== 767    //Medic. modern private outside hosp.
replace io = 48 if itemid== 768    //Medic. tradi. outside hosp.
replace io = 48 if itemid== 769    //Vaccinations
replace io = 48 if itemid== 770    //Circumcision
replace io = 48 if itemid== 771    //Health check
replace io = 48 if itemid== 772    //Covid test
replace io = 48 if itemid== 773    //Ambulance transport, etc.
replace io = 48 if itemid== 774    //Hospitalization
replace io = 48 if itemid== 775    //Delivery costs
replace io = 48 if itemid== 776    //Prescription lens/frame fees
replace io = 48 if itemid== 777    //Crutches/roller chairs/prosthetics, etc.
replace io = 33 if itemid== 801    //VU Living room (Armchairs/coffee table)
replace io = 33 if itemid== 802    //VU Dining table (table/chairs)
replace io = 33 if itemid== 803    //VU Bed
replace io = 33 if itemid== 804    //VU Single mattress
replace io = 33 if itemid== 805    //VU Cabinets and other furniture
replace io = 33 if itemid== 806    //VU Carpet
replace io = 38 if itemid== 807    //VU Electric iron
replace io = 38 if itemid== 808    //VU Charcoal iron
replace io = 38 if itemid== 809    //VU Gas/electric cooker
replace io = 38 if itemid== 810    //VU Gas cylinder
replace io = 38 if itemid== 811    //VU Gas/electric stove (hob)
replace io = 38 if itemid== 812    //VU Microwave/electric oven
replace io = 38 if itemid== 813    //VU Improved fireplaces
replace io = 38 if itemid== 814    //VU Electric food processor
replace io = 38 if itemid== 815    //VU Non-electric blender/fruit press.
replace io = 38 if itemid== 816    //VU Refrigerator
replace io = 38 if itemid== 817    //VU Freezer
replace io = 38 if itemid== 818    //VU Pedestal fan
replace io = 29 if itemid== 819    //VU Single radio/Radiocassette
replace io = 29 if itemid== 820    //VU TV device
replace io = 29 if itemid== 821    //VU Magnetoscope/CD/DVD
replace io = 29 if itemid== 822    //VU Parabolic antenna/decoder
replace io = 38 if itemid== 823    //VU Washing machine, dryer
replace io = 38 if itemid== 824    //VU Vacuum cleaner
replace io = 38 if itemid== 825    //VU Air conditioners/splits
replace io = 38 if itemid== 826    //VU Lawn/gardening mower
replace io = 38 if itemid== 827    //VU Generator
replace io = 32 if itemid== 828    //SUV Personal car
replace io = 32 if itemid== 829    //SUV Moped/Moped
replace io = 32 if itemid== 830    //SUV Bicycle
replace io = 29 if itemid== 831    //VU Camera
replace io = 29 if itemid== 832    //VU Camcorder
replace io = 29 if itemid== 833    //VU Hi Fi System
replace io = 29 if itemid== 834    //VU Landline
replace io = 29 if itemid== 835    //VU Mobile phone
replace io = 29 if itemid== 836    //VU Tablet
replace io = 29 if itemid== 837    //VU Computer
replace io = 29 if itemid== 838    //VU Printer/Fax
replace io = 29 if itemid== 839    //VU Camera Video
replace io = 38 if itemid== 842    //VU Guitar
replace io = 38 if itemid== 843    //VU Piano/music device
replace io = 40 if itemid== 901    //Party food
replace io = 40 if itemid== 902    //Wedding/baptism/comm supply.
replace io = 40 if itemid== 903    //Funeral/other food
replace io = 40 if itemid== 904    //Holiday drink
replace io = 40 if itemid== 905    //Wedding/baptism/comm drink
replace io = 40 if itemid== 906    //Funeral drink/others
replace io = 18 if itemid== 908    //Clothes/shoes mar./bapt./comm.
replace io = 18 if itemid== 909    //Funeral clothing/shoes/others
replace io = 40 if itemid== 910    //Party room/chair rental
replace io = 40 if itemid== 911    //Room/chair rental for mar./bapt./comm.
replace io = 40 if itemid== 912    //Rental of room/funeral chair/others

save "$gdOut\cons_vat.dta", replace


g cusio=0
**********************************************************************************************************************
*STEP 4:cus remap consumption items to new IOT
replace cusio = 5    if itemid== 1      //Local coarse grain rice
replace cusio = 5    if itemid== 2      //Local long grain rice
replace cusio = 4    if itemid== 3      //Popular imported rice (dénicachia)
replace cusio = 4    if itemid== 4      //Luxury imported long grain rice
replace cusio = 4    if itemid== 5      //Corn on the cob
replace cusio = 4    if itemid== 6      //Dried corn kernels (excluding popcorn corn
replace cusio = 4    if itemid== 7      //Millet
replace cusio = 4    if itemid== 8      //Sorghum
replace cusio = 4    if itemid== 10     //Fonio
replace cusio = 4    if itemid== 11     //Other grain cereals (to be specified) i
replace cusio = 18   if itemid== 12     //Corn flour
replace cusio = 18   if itemid== 13     //Cornmeal
replace cusio = 18   if itemid== 14     //Millet flour
replace cusio = 18   if itemid== 15     //Millet semolina
replace cusio = 18   if itemid== 16     //Local or imported wheat flour
replace cusio = 18   if itemid== 17     //Wheat couscous
replace cusio = 20   if itemid== 20     //Pasta
replace cusio = 20   if itemid== 21     //Modern bread
replace cusio = 20   if itemid== 22     //Traditional bread
replace cusio = 20   if itemid== 23     //Croissants
replace cusio = 20   if itemid== 24     //Cookies
replace cusio = 20   if itemid== 25     //Cakes
replace cusio = 20   if itemid== 26     //Donuts, pancakes
replace cusio = 13   if itemid== 27     //Beef
replace cusio = 13   if itemid== 29     //Mutton
replace cusio = 13   if itemid== 30     //Goat meat
replace cusio = 13   if itemid== 31     //Other offal (liver, kidney, head, leg
replace cusio = 13   if itemid== 32     //Pork meat
replace cusio = 7    if itemid== 33     //Chicken on foot
replace cusio = 13   if itemid== 34     //Chicken meat
replace cusio = 13   if itemid== 35     //Meat of other domestic poultry (
replace cusio = 13   if itemid== 36     //Cold meats (ham, sausage), conser
replace cusio = 14   if itemid== 37     //Dried meat (beef, mutton, camel,
replace cusio = 14   if itemid== 38     //Game (bush meat)
replace cusio = 14   if itemid== 39     //Other meats n.e.s. (to be specified lapi
replace cusio = 11   if itemid== 40     //Fresh Appolo fish
replace cusio = 11   if itemid== 41     //White carp
replace cusio = 11   if itemid== 42     //Fresh fish Red carp
replace cusio = 11   if itemid== 43     //Captain fresh fish
replace cusio = 10   if itemid== 44     //Smoked fish Herring (Mangni)
replace cusio = 10   if itemid== 45     //Smoked fish Mackerel
replace cusio = 10   if itemid== 46     //Smoked sardinella
replace cusio = 10   if itemid== 47     //Crabs
replace cusio = 10   if itemid== 48     //Fresh shrimp
replace cusio = 10   if itemid== 49     //Dried shrimp
replace cusio = 10   if itemid== 50     //Other seafood (crayfish, etc.)
replace cusio = 11   if itemid== 51     //Canned fish
replace cusio = 24   if itemid== 52     //Fresh cow's milk
replace cusio = 23   if itemid== 53     //Curd, yogurt, disgusting
replace cusio = 26   if itemid== 54     //Sweetened condensed milk
replace cusio = 25   if itemid== 55     //Unsweetened condensed milk
replace cusio = 26   if itemid== 56     //Powdered milk
replace cusio = 24   if itemid== 57     //Cheese
replace cusio = 26   if itemid== 58     //Baby milk and flour
replace cusio = 23   if itemid== 59     //Other dairy products (crème fraîche
replace cusio = 24   if itemid== 60     //Eggs
replace cusio = 16   if itemid== 61     //Butter and Margarine
replace cusio = 16   if itemid== 62     //Shea Butter
replace cusio = 17   if itemid== 63     //Red palm oil
replace cusio = 15   if itemid== 64     //Refined peanut oil
replace cusio = 16   if itemid== 67     //Cottonseed oil
replace cusio = 15   if itemid== 68     //Refined palm oil
replace cusio = 2    if itemid== 69     //Palm nut (palm seed)
replace cusio = 16   if itemid== 70     //Other oils n.e.s. (corn, palm oil
replace cusio = 2    if itemid== 71     //Mango
replace cusio = 2    if itemid== 72     //Pineapple
replace cusio = 2    if itemid== 73     //Orange
replace cusio = 2    if itemid== 74     //Lemon
replace cusio = 2    if itemid== 75     //Other citrus fruits (mandarin, grapefruit
replace cusio = 2    if itemid== 76     //Sweet banana
replace cusio = 2    if itemid== 77     //Lawyer
replace cusio = 2    if itemid== 78     //Watermelon
replace cusio = 2    if itemid== 79     //Melon
replace cusio = 2    if itemid== 80     //Dates
replace cusio = 2    if itemid== 81     //Coconut
replace cusio = 2    if itemid== 82     //Sugar cane
replace cusio = 2    if itemid== 83     //Apples
replace cusio = 2    if itemid== 84     //Papaya
replace cusio = 2    if itemid== 85     //Baobab fruit
replace cusio = 2    if itemid== 86     //Nere
replace cusio = 2    if itemid== 87     //Other fruits (black tamarind, wild liana
replace cusio = 2    if itemid== 88     //Salad (lettuce)
replace cusio = 2    if itemid== 89     //Cabbage
replace cusio = 2    if itemid== 90     //Carrot
replace cusio = 2    if itemid== 91     //Green bean
replace cusio = 2    if itemid== 92     //Cucumber
replace cusio = 2    if itemid== 93     //Eggplant
replace cusio = 2    if itemid== 94     //Squash/Zucchini
replace cusio = 2    if itemid== 95     //Fresh pepper
replace cusio = 2    if itemid== 96     //Fresh tomato
replace cusio = 2    if itemid== 97     //Dried tomato
replace cusio = 2    if itemid== 98     //Fresh okra
replace cusio = 2    if itemid== 99     //Dry/dried/pounded/powdered okra (djoumgbé
replace cusio = 1    if itemid== 100    //Fresh onion
replace cusio = 2    if itemid== 101    //Garlic
replace cusio = 2    if itemid== 102    //Sorrel leaves (dah)
replace cusio = 2    if itemid== 103    //Potato leaves
replace cusio = 2    if itemid== 104    //Spinach
replace cusio = 2    if itemid== 105    //Kplala
replace cusio = 2    if itemid== 106    //Other leaves (cassava, taro, baobab,
replace cusio = 2    if itemid== 107    //Other fresh vegetables n.e.s. (eggplant v
replace cusio = 24   if itemid== 108    //Tomato concentrate
replace cusio = 2    if itemid== 109    //Peas
replace cusio = 2    if itemid== 110    //Dried peas
replace cusio = 2    if itemid== 111    //Other dried vegetables n.e.s. (soy, pista
replace cusio = 4    if itemid== 112    //Cowpea/Dried beans
replace cusio = 2    if itemid== 113    //Fresh peanuts in shells
replace cusio = 4    if itemid== 114    //Dried peanuts in shells
replace cusio = 2    if itemid== 115    //Shelled peanuts
replace cusio = 2    if itemid== 116    //Pounded/crushed peanuts
replace cusio = 2    if itemid== 117    //Roasted peanut
replace cusio = 24   if itemid== 118    //Peanut paste
replace cusio = 24   if itemid== 119    //Soy-based cheese
replace cusio = 4    if itemid== 120    //Sesame
replace cusio = 2    if itemid== 121    //Cashew nuts
replace cusio = 2    if itemid== 123    //Cassava
replace cusio = 2    if itemid== 124    //Yam
replace cusio = 2    if itemid== 125    //Plantain
replace cusio = 2    if itemid== 126    //Potato
replace cusio = 2    if itemid== 127    //Taro, macabo
replace cusio = 2    if itemid== 128    //Yam
replace cusio = 3    if itemid== 130    //Cassava flours
replace cusio = 2    if itemid== 131    //Gari, tapioca
replace cusio = 2    if itemid== 132    //Attiéke/Atoukpou
replace cusio = 26   if itemid== 134    //Powdered sugar
replace cusio = 26   if itemid== 135    //Sugar pieces
replace cusio = 24   if itemid== 136    //Honey
replace cusio = 23   if itemid== 137    //Chewable chocolate, spread
replace cusio = 23   if itemid== 138    //Caramel, sweets, confectionery, etc.
replace cusio = 24   if itemid== 139    //Salt
replace cusio = 24   if itemid== 140    //Dried chili pepper/powder
replace cusio = 2    if itemid== 141    //Fresh chili pepper
replace cusio = 2    if itemid== 142    //Fresh ginger
replace cusio = 2    if itemid== 143    //Grounded ginger
replace cusio = 24   if itemid== 144    //Food cube (Maggi, Jumbo, )
replace cusio = 24   if itemid== 145    //Flavor (Maggi, aromatic, adja, etc.)
replace cusio = 24   if itemid== 146    //Soumbala (African mustard)
replace cusio = 24   if itemid== 147    //Mayonnaise
replace cusio = 24   if itemid== 149    //Other vinegars
replace cusio = 24   if itemid== 150    //Mustard
replace cusio = 2    if itemid== 151    //Pepper
replace cusio = 24   if itemid== 152    //Other condiments (akpi etc)
replace cusio = 24   if itemid== 153    //Cola nuts
replace cusio = 24   if itemid== 154    //Other food products (mushroom
replace cusio = 22   if itemid== 155    //Coffee powder (ground)
replace cusio = 22   if itemid== 156    //Soluble coffee (instant)
replace cusio = 22   if itemid== 157    //Tea (instant)
replace cusio = 21   if itemid== 158    //Chocolate powder
replace cusio = 22   if itemid== 159    //Other herbal teas and infusions n.e.s. (which
replace cusio = 29   if itemid== 160    //Traditional fruit juice (orange, bis
replace cusio = 27   if itemid== 161    //Mineral/filtered water
replace cusio = 28   if itemid== 162    //Carbonated drinks (cokes, etc.)
replace cusio = 28   if itemid== 163    //Juice powder
replace cusio = 28   if itemid== 164    //Traditional beers and wines (Tchapalo,
replace cusio = 28   if itemid== 165    //Industrial beers (Bock, Guinness, I
replace cusio = 4    if itemid== 166    //Imported broken rice
replace cusio = 18   if itemid== 167    //Breakfast cereals (Quaker
replace cusio = 20   if itemid== 168    //Other bakery products (bread
replace cusio = 20   if itemid== 169    //Sweet bread
replace cusio = 13   if itemid== 170    //Tripe (intestine and stomach)
replace cusio = 7    if itemid== 171    //Other live domestic poultry (
replace cusio = 14   if itemid== 172    //Snails
replace cusio = 24   if itemid== 173    //Fresh sterilized milk without sugar, half-soured
replace cusio = 24   if itemid== 174    //Cassava paste (placali)
replace cusio = 25   if itemid== 175    //Dried fish as a condiment (adjovan)
replace cusio = 22   if itemid== 176    //Tea Leaf (Black Tea)
replace cusio = 28   if itemid== 177    //Manufactured fruit juice (orange, mango
replace cusio = 59   if itemid== 191    //Breakfast outside the household
replace cusio = 59   if itemid== 192    //Lunch outside the household
replace cusio = 59   if itemid== 193    //Dinner outside the household
replace cusio = 59   if itemid== 194    //Non-household snack
replace cusio = 59   if itemid== 195    //Hot drinks outside the household
replace cusio = 59   if itemid== 196    //Non-alcoholic drink outside household
replace cusio = 59   if itemid== 197    //Non-household alcoholic beverage
replace cusio = 30   if itemid== 201    //Cigarettes/Tobacco
replace cusio = 36   if itemid== 202    //Lamp oil
replace cusio = 12   if itemid== 203    //Charcoal/mineral
replace cusio = 33   if itemid== 204    //Firewood purchased
replace cusio = 55   if itemid== 206    //Candles
replace cusio = 55   if itemid== 207    //Matches
replace cusio = 37   if itemid== 208    //Vehicle fuel
replace cusio = 37   if itemid== 209    //Motorcycle fuel
replace cusio = 58   if itemid== 210    //Urban transport by taxi
replace cusio = 58   if itemid== 211    //Urban transport by bus
replace cusio = 58   if itemid== 212    //Urban transport by motorbike taxi
replace cusio = 58   if itemid== 213    //Urban transport by train
replace cusio = 58   if itemid== 214    //Urban transport waterway
replace cusio = 58   if itemid== 215    //Urban transport animal traction
replace cusio = 34   if itemid== 216    //Newspapers
replace cusio = 19   if itemid== 217    //Fresh cereal molding
replace cusio = 28   if itemid== 301    //Whiskey/other liqueurs
replace cusio = 28   if itemid== 302    //Modern wines
replace cusio = 12   if itemid== 303    //Domestic gas
replace cusio = 36   if itemid== 304    //Fuel for electric group.
replace cusio = 55   if itemid== 305    //Electric batteries
replace cusio = 39   if itemid== 306    //Soap/detergents
replace cusio = 40   if itemid== 307    //Insecticide, anti-mosquito twist
replace cusio = 72   if itemid== 308    //Housekeeping salary
replace cusio = 71   if itemid== 309    //Clothes laundering costs
replace cusio = 52   if itemid== 310    //Garbage collection fees
replace cusio = 71   if itemid== 311    //Vehicle washing
replace cusio = 58   if itemid== 312    //Parking fees
replace cusio = 60   if itemid== 313    //Telephone communication cabin
replace cusio = 65   if itemid== 314    //Lottery/PMU ticket
replace cusio = 34   if itemid== 315    //Magazines, newspaper or magazine
replace cusio = 71   if itemid== 316    //Hairdressing fees, manicure, pedicure
replace cusio = 55   if itemid== 317    //Toilet soap, shampoo
replace cusio = 55   if itemid== 318    //Toothpaste
replace cusio = 35   if itemid== 319    //Toilet paper
replace cusio = 55   if itemid== 320    //Serv. hyg., disposable baby diapers
replace cusio = 55   if itemid== 321    //Body milk, makeup products
replace cusio = 31   if itemid== 322    //Disposable COVID-19 mask
replace cusio = 52   if itemid== 332    //Running water bill
replace cusio = 52   if itemid== 333    //Water from dealer
replace cusio = 51   if itemid== 334    //Electricity bill
replace cusio = 60   if itemid== 335    //Landline phone bill
replace cusio = 60   if itemid== 336    //Internet bill
replace cusio = 60   if itemid== 337    //Cable subscription invoice
replace cusio = 60   if itemid== 338    //Mobile phone recharge
replace cusio = 71   if itemid== 401    //Shoe care costs
replace cusio = 55   if itemid== 402    //Electric light bulbs
replace cusio = 36   if itemid== 403    //Lubricants
replace cusio = 50   if itemid== 404    //Vehicle repair and maintenance
replace cusio = 58   if itemid== 405    //Inter-locality car transport
replace cusio = 58   if itemid== 406    //Inter-locality transport traction anima
replace cusio = 58   if itemid== 407    //Interlocal water transport
replace cusio = 71   if itemid== 408    //Postal stamp, money order shipping
replace cusio = 60   if itemid== 409    //Fax sending costs
replace cusio = 57   if itemid== 410    //Gardening products
replace cusio = 55   if itemid== 411    //Pet Food/Care
replace cusio = 71   if itemid== 412    //Entrance fee for sporting events
replace cusio = 71   if itemid== 413    //Cinema/concert/theater entry fee, and
replace cusio = 71   if itemid== 414    //Other recreational services (photo)
replace cusio = 31   if itemid== 415    //Washable mask against COVID-19
replace cusio = 38   if itemid== 416    //Medicines in pharmacies without a prescription
replace cusio = 38   if itemid== 417    //Scent
replace cusio = 55   if itemid== 418    //Toothbrush
replace cusio = 31   if itemid== 501    //Clothing fabrics
replace cusio = 31   if itemid== 502    //Women clothes
replace cusio = 31   if itemid== 503    //Women's underwear
replace cusio = 31   if itemid== 504    //Children's clothing
replace cusio = 31   if itemid== 505    //Men's clothing
replace cusio = 31   if itemid== 506    //Men's underwear
replace cusio = 70   if itemid== 507    //Cost of making men's clothing
replace cusio = 70   if itemid== 508    //Freshly made women's clothing
replace cusio = 70   if itemid== 509    //Cost of making children's clothing
replace cusio = 32   if itemid== 510    //Men's shoes
replace cusio = 32   if itemid== 511    //Women's shoes
replace cusio = 32   if itemid== 512    //Children's shoes
replace cusio = 31   if itemid== 521    //Party clothes/shoes
replace cusio = 54   if itemid== 601    //Equipment maintenance/repair. housing
replace cusio = 54   if itemid== 602    //Maintenance/repair labor. accommodation
replace cusio = 53   if itemid== 603    //Mast. const. (cement, bricks, etc.)
replace cusio = 53   if itemid== 604    //Aut. mast. const. (sheet metal, wood, electricity)
replace cusio = 54   if itemid== 605    //Construction labor
replace cusio = 54   if itemid== 606    //Well/drilling costs
replace cusio = 62   if itemid== 607    //Housing land acquisition costs
replace cusio = 54   if itemid== 608    //Architect study fees
replace cusio = 52   if itemid== 609    //Water network subscription fees
replace cusio = 51   if itemid== 610    //Electricity subscription fees
replace cusio = 52   if itemid== 611    //Water connection costs
replace cusio = 51   if itemid== 612    //Electricity connection costs
replace cusio = 49   if itemid== 613    //Living room furniture
replace cusio = 49   if itemid== 614    //Bed/mattress and other. bedroom furniture
replace cusio = 50   if itemid== 615    //Furniture repair
replace cusio = 31   if itemid== 616    //Household linens
replace cusio = 46   if itemid== 617    //Appliances
replace cusio = 45   if itemid== 618    //Solar plate
replace cusio = 45   if itemid== 619    //Solar plate battery/aut. equip. ground
replace cusio = 50   if itemid== 620    //Repair of household appliances
replace cusio = 55   if itemid== 621    //Dishes
replace cusio = 55   if itemid== 622    //Kitchen utensils
replace cusio = 55   if itemid== 623    //Other household utensils
replace cusio = 56   if itemid== 624    //Home tools
replace cusio = 55   if itemid== 625    //Lamps (electric, storms, torches)
replace cusio = 47   if itemid== 626    //Purchase of personal car
replace cusio = 47   if itemid== 627    //Personal motorcycle purchase
replace cusio = 48   if itemid== 628    //Medium locomotive spare parts.
replace cusio = 61   if itemid== 629    //Average locomotive insurance costs
replace cusio = 50   if itemid== 631    //Other vehicle services
replace cusio = 58   if itemid== 632    //Vehicle rental for personal use.
replace cusio = 58   if itemid== 633    //Inter-city transportation. by train
replace cusio = 58   if itemid== 634    //Airplane transportation
replace cusio = 58   if itemid== 635    //Moving expenses
replace cusio = 65   if itemid== 636    //Visa fees, airport taxes
replace cusio = 44   if itemid== 637    //Cell phone purchase
replace cusio = 44   if itemid== 638    //Music/image devices
replace cusio = 44   if itemid== 639    //Computer/printer/tablet, etc.
replace cusio = 50   if itemid== 640    //Electronic device repair
replace cusio = 44   if itemid== 641    //Small mate. electronic personal use.
replace cusio = 34   if itemid== 642    //Sports and relaxation articles
replace cusio = 34   if itemid== 643    //Non-school book, comic book
replace cusio = 34   if itemid== 644    //Paper ream/envelope/drawing item
replace cusio = 59   if itemid== 645    //Pilgrimage costs
replace cusio = 66   if itemid== 646    //Professional training
replace cusio = 66   if itemid== 647    //Private lesson fees for adults
replace cusio = 59   if itemid== 648    //Accommodation services: hotel, etc.
replace cusio = 55   if itemid== 649    //Watches, alarm clocks
replace cusio = 55   if itemid== 650    //Jewelry
replace cusio = 55   if itemid== 651    //Other personal effects
replace cusio = 61   if itemid== 652    //Home insurance costs/means trans.
replace cusio = 66   if itemid== 701    //Registration/tuition fees preschool
replace cusio = 66   if itemid== 702    //Preschool contributions
replace cusio = 34   if itemid== 703    //Preschool books/workbooks
replace cusio = 66   if itemid== 704    //Aut. preschool material
replace cusio = 31   if itemid== 705    //Preschool uniforms
replace cusio = 66   if itemid== 706    //Preschool canteen fees
replace cusio = 58   if itemid== 707    //Preschool transportation costs
replace cusio = 66   if itemid== 708    //Aut. (support, repeat.) preschool
replace cusio = 66   if itemid== 709    //Registration/tuition fees primary
replace cusio = 66   if itemid== 710    //Primary contributions
replace cusio = 34   if itemid== 711    //Primary books/notebooks
replace cusio = 66   if itemid== 712    //Aut. primary material
replace cusio = 31   if itemid== 713    //Primary uniforms
replace cusio = 66   if itemid== 714    //Primary canteen fees
replace cusio = 58   if itemid== 715    //Primary transport costs
replace cusio = 66   if itemid== 716    //Aut. (support, repeat.) primary
replace cusio = 66   if itemid== 717    //Registration/tuition fees secondary 1
replace cusio = 66   if itemid== 718    //Secondary contributions 1
replace cusio = 34   if itemid== 719    //Secondary 1 books/notebooks
replace cusio = 66   if itemid== 720    //Aut. secondary material 1
replace cusio = 31   if itemid== 721    //Secondary 1 uniforms
replace cusio = 66   if itemid== 722    //Secondary canteen fees 1
replace cusio = 58   if itemid== 723    //Secondary transport costs 1
replace cusio = 66   if itemid== 724    //Aut. (support, repeat.) secondary 1
replace cusio = 66   if itemid== 725    //Registration/tuition fees secondary 2
replace cusio = 66   if itemid== 726    //Secondary contributions 2
replace cusio = 34   if itemid== 727    //Secondary 2 books/notebooks
replace cusio = 66   if itemid== 728    //Aut. secondary material 2
replace cusio = 31   if itemid== 729    //Secondary 2 uniforms
replace cusio = 66   if itemid== 730    //Secondary canteen fees 2
replace cusio = 58   if itemid== 731    //Secondary transport costs 2
replace cusio = 66   if itemid== 732    //Aut. (support, repeat.) secondary 2
replace cusio = 66   if itemid== 733    //Registration/tuition fees post-secondary
replace cusio = 66   if itemid== 734    //Post-secondary contributions
replace cusio = 34   if itemid== 735    //Post-secondary books/notebooks
replace cusio = 66   if itemid== 736    //Aut. post-secondary material
replace cusio = 31   if itemid== 737    //Post-secondary uniforms
replace cusio = 66   if itemid== 738    //Post-secondary canteen fees
replace cusio = 58   if itemid== 739    //Post-secondary transportation costs
replace cusio = 66   if itemid== 740    //Aut. (support, repeat.) post-secondary
replace cusio = 66   if itemid== 741    //Registration/tuition fees superior
replace cusio = 66   if itemid== 742    //Higher contributions
replace cusio = 34   if itemid== 743    //Superior books/notebooks
replace cusio = 66   if itemid== 744    //Aut. superior material
replace cusio = 31   if itemid== 745    //Superior uniforms
replace cusio = 66   if itemid== 746    //Higher canteen fees
replace cusio = 58   if itemid== 747    //Higher transport costs
replace cusio = 66   if itemid== 748    //Aut. (support, repeat.) superior
replace cusio = 68   if itemid== 761    //Generalist consultation
replace cusio = 68   if itemid== 762    //Specialist consultation
replace cusio = 68   if itemid== 763    //Dentist consultation
replace cusio = 68   if itemid== 764    //Healer consultation
replace cusio = 68   if itemid== 765    //Medical examinations outside the hospital.
replace cusio = 67   if itemid== 766    //Medic. modern public outside hosp.
replace cusio = 67   if itemid== 767    //Medic. modern private outside hosp.
replace cusio = 67   if itemid== 768    //Medic. tradi. outside hosp.
replace cusio = 67   if itemid== 769    //Vaccinations
replace cusio = 68   if itemid== 770    //Circumcision
replace cusio = 68   if itemid== 771    //Health check
replace cusio = 68   if itemid== 772    //Covid test
replace cusio = 68   if itemid== 773    //Ambulance transport, etc.
replace cusio = 68   if itemid== 774    //Hospitalization
replace cusio = 68   if itemid== 775    //Delivery costs
replace cusio = 67   if itemid== 776    //Prescription lens/frame fees
replace cusio = 67   if itemid== 777    //Crutches/roller chairs/prosthetics, etc.
replace cusio = 49   if itemid== 801    //VU Living room (Armchairs/coffee table)
replace cusio = 49   if itemid== 802    //VU Dining table (table/chairs)
replace cusio = 49   if itemid== 803    //VU Bed
replace cusio = 49   if itemid== 804    //VU Single mattress
replace cusio = 49   if itemid== 805    //VU Cabinets and other furniture
replace cusio = 49   if itemid== 806    //VU Carpet
replace cusio = 55   if itemid== 807    //VU Electric iron
replace cusio = 55   if itemid== 808    //VU Charcoal iron
replace cusio = 55   if itemid== 809    //VU Gas/electric cooker
replace cusio = 55   if itemid== 810    //VU Gas cylinder
replace cusio = 55   if itemid== 811    //VU Gas/electric stove (hob)
replace cusio = 55   if itemid== 812    //VU Microwave/electric oven
replace cusio = 55   if itemid== 813    //VU Improved fireplaces
replace cusio = 55   if itemid== 814    //VU Electric food processor
replace cusio = 55   if itemid== 815    //VU Non-electric blender/fruit press.
replace cusio = 55   if itemid== 816    //VU Refrigerator
replace cusio = 55   if itemid== 817    //VU Freezer
replace cusio = 55   if itemid== 818    //VU Pedestal fan
replace cusio = 44   if itemid== 819    //VU Single radio/Radiocassette
replace cusio = 44   if itemid== 820    //VU TV device
replace cusio = 44   if itemid== 821    //VU Magnetoscope/CD/DVD
replace cusio = 44   if itemid== 822    //VU Parabolic antenna/decoder
replace cusio = 55   if itemid== 823    //VU Washing machine, dryer
replace cusio = 55   if itemid== 824    //VU Vacuum cleaner
replace cusio = 55   if itemid== 825    //VU Air conditioners/splits
replace cusio = 55   if itemid== 826    //VU Lawn/gardening mower
replace cusio = 55   if itemid== 827    //VU Generator
replace cusio = 47   if itemid== 828    //SUV Personal car
replace cusio = 47   if itemid== 829    //SUV Moped/Moped
replace cusio = 47   if itemid== 830    //SUV Bicycle
replace cusio = 44   if itemid== 831    //VU Camera
replace cusio = 44   if itemid== 832    //VU Camcorder
replace cusio = 44   if itemid== 833    //VU Hi Fi System
replace cusio = 44   if itemid== 834    //VU Landline
replace cusio = 44   if itemid== 835    //VU Mobile phone
replace cusio = 44   if itemid== 836    //VU Tablet
replace cusio = 44   if itemid== 837    //VU Computer
replace cusio = 44   if itemid== 838    //VU Printer/Fax
replace cusio = 44   if itemid== 839    //VU Camera Video
replace cusio = 55   if itemid== 842    //VU Guitar
replace cusio = 55   if itemid== 843    //VU Piano/music device
replace cusio = 59   if itemid== 901    //Party food
replace cusio = 59   if itemid== 902    //Wedding/baptism/comm supply.
replace cusio = 59   if itemid== 903    //Funeral/other food
replace cusio = 59   if itemid== 904    //Holiday drink
replace cusio = 59   if itemid== 905    //Wedding/baptism/comm drink
replace cusio = 59   if itemid== 906    //Funeral drink/others
replace cusio = 31   if itemid== 908    //Clothes/shoes mar./bapt./comm.
replace cusio = 31   if itemid== 909    //Funeral clothing/shoes/others
replace cusio = 59   if itemid== 910    //Party room/chair rental
replace cusio = 59   if itemid== 911    //Room/chair rental for mar./bapt./comm.
replace cusio = 59   if itemid== 912    //Rental of room/funeral chair/others

save "$gdOut\cons_cus.dta", replace

*********Excise********	
use "$gdOut\cons_vat.dta", clear
	g exc_item = 0
	replace exc_item = 1 if inlist(itemid,160,162,163,164,165,177,201,301,302,626) & cons_val>0
	g itx_exco_hh=0
	g itx_exca_hh = 0
	g itx_exct_hh = 0
save "$gdOut\excise_base.dta", replace



********Fuel Excise**************
use "$gdOut\cons_vat.dta", clear

keep if itemid==202 | itemid==208 | itemid==209 | itemid==304
********************************************************************************
/*Step 1: Calculate excise tax (average petrol, diesel)

In Côte d’Ivoire, three main taxes are collected: 
    (i) custom duties of 10 percent on the taxable base; 
   (ii) the excise tax on the volume of imports (FCFA 85 per liter of gasoline and DDO and FCFA 45 per liter of diesel); and 
  (iii) VAT at a reduced rate of 9 percent collected on the taxable base.  

*Consumption data does not include quantity purchased, so it can be estimated from the average pump price
	*Gasoline: 599 CFA per liter 	(source:Managing Oil Markets)	
	*Diesel:   598 CFA per liter 	(source:Managing Oil Markets)
	*Domestic fuel oil: 529 CFA per kg (considering a liter of kerosene weighs about .8kg, 423.2 CFA/liter)
	
*******************************************************/

g hh_fuel_exp = cons_val if itemid==208 | itemid==209 | itemid==304				// vehicle and motorcycle fuel; fuel for generators
g hh_fuel_qty = (cons_val/598.5) if itemid==208 | itemid==209 |itemid==304	//How many liters of petrol household consumed (year)
g exc_hh_fuel=0

g hh_kero_exp = cons_val if itemid==202
g hh_kero_qty = (cons_val/423.2) if itemid==202
g exc_hh_kero=0

save "$gdOut\fuel_excise_base.dta", replace

************************Motor Vehicle Registration Tax*********************************
use "$gdData\Dataout\ehcvm_conso_CIV2021.dta", clear
merge m:1 hhid using "$gdData\Dataout\ehcvm_welfare_CIV2021.dta", keepusing(pcexp hhsize)
drop _merge

keep if modep==1 | modep==4		// keep only purchased items and durable use value (drop donations, autoconsumption, and imputed rent)

rename codpr itemid
rename depan cons_val
rename milieu urban
recode urban (2=0)

g itx_moto_ri = (cons_val>0 & cons_val!=. & itemid==630)
g itx_moto_in = cons_val if itx_moto_ri==1

collapse (sum)itx_moto_hh=itx_moto_in (max) itx_moto_rh=itx_moto_ri, by(hhid hhweight)

save "$gdOut\itx_moto_final.dta", replace


***************************************************************************************
***************************Indirect Subsidies******************************************
***************************************************************************************
*Electricity

use "$gdOut\cons_vat.dta", clear

g elec_exp = cons_val if itemid==334		//electrcity bill. 609 is electricity network subscription bill
g elec_access = (elec_exp>0 & elec_exp!=.)
g postpay=0
g prepay=0

preserve
	use "$gdData\Datain\Menage\s11_me_CIV2021.dta", clear
	destring grappe, replace
	g hhid=grappe*100+menage

	rename s11q35 connection
	collapse (max)connection, by(hhid)

	tempfile connection
	save `connection', replace
restore

merge m:1 hhid using `connection', keepusing(connection)
drop _merge

replace postpay = 1 if inlist(connection, 1, 4)		//classic connection, adder/subtractor
replace prepay = 1 if inlist(connection, 2, 3)		//prepaid card meter or a household with both

*Idenfity kWh per household by estimating the maximum amount a household would pay under the social tariff.
g takataka = 0					  //Other region
replace takataka = 1 if region==1 //Abidjan

g elec_kwh = 0
g elecost = 0
g sub_elec_in = 0

save "$gdOut\sub_elec_base.dta", replace


*Water
use "$gdOut\cons_vat.dta", clear
g watr_exp = cons_val if itemid==332		//running water bill
g stand_exp = cons_val if itemid==333		//water from reseller (assuming standpipe water)
replace watr_exp=0 if watr_exp==.
replace stand_exp=0 if stand_exp==.

/* 
Designation							Share SODCI. H.T.			VAT (18%) (*)			Part F.D. E			Part F.N.E.				Selling price incl. VAT
Package up to 6 m3 (**)					299							0,0						0					0							 1824
Tranche 1 (Social) 7 to 18 m3			299							0,0						5,00				0,00						304,0
Unit 2 (domestic) 19 to 54 m3			299							53,8					100,00				10,00						462,8
Unit 3 (normal) 55 to 140 m3			299							53,8					340,00				20,00						712,8
Unit 4 (Superior) > 140 m3				299							53,8					450,00				80,00						882,8
Commercial Slice						299							53,8					380,00				40,00						772,8
Industrial Band (average rate)			299							53,8					380,00				40,00						772,8
Administrative tranche					299							53,8					380,00				40,00						772,8
PM: fixed prepayment per m3 Social		299							0,0						181,00				20,00						500,0
Five-year weighted price new tariff 	299							31,1					143,1				21,3						476,9
Direct Pumping – Abidjan (***)			63,0						11,34					40,00				380,00 						494,3

(*) A. is based on the Concessionaire's share excluding VAT at the rate of 18% in all brackets except the social portion which is exempt.La T.V
(**) Any consumption of drinking water of less than 6 m3 is billed at a flat rate of 6 m3 or 1,794 FCFA.
(***) Alignment of charges with other consumers

			
2018 AVERAGE UNIT COST 
PRODUCTION COST 		299 CFA/m3		//The production cost is only the operational cost, so we need to know the capital cost portion before we can estimate the subsidy, 
*/

g wtr_qty = 0
g sub_watr_in= 0

save "$gdOut\sub_watr_base.dta", replace



*********************************************************************************
********Fuel Subsidy**************
use "$gdOut\cons_vat.dta", clear

keep if itemid==202 | itemid==208 | itemid==209 | itemid==304
********************************************************************************
/*Step 1: Calculate excise tax (average petrol, diesel)

In Côte d’Ivoire, three main taxes are collected: **2022 update: all fuel taxes eliminated in early 2022**
    (i) custom duties of 10 percent on the taxable base; 
   (ii) the excise tax on the volume of imports (FCFA 85 per liter of gasoline and DDO and FCFA 45 per liter of diesel); and 
  (iii) VAT at a reduced rate of 9 percent collected on the taxable base.  

*Consumption data does not include quantity purchased, so it can be estimated from the average pump price
	*Gasoline: 735 CFA per liter 	(source:https://openknowledge.worldbank.org/server/api/core/bitstreams/54eb895b-3cb3-4322-b342-af377b52e3bd/content)	
	*Diesel:   615 CFA per liter 	
	
*******************************************************/

g hh_fuel_exp = cons_val if itemid==208 | itemid==209 | itemid==304				// vehicle and motorcycle fuel; fuel for generators
g hh_fuel_qty = (cons_val/675) if itemid==208 | itemid==209 |itemid==304		//How many liters of petrol household consumed (year)
g sub_hh_fuel=0

save "$gdOut\fuel_subsidy_base.dta", replace


***************************************************************************************
***************************Healthcare**************************************************
***************************************************************************************

*************************************************************
*Usage-based Approach
*Section 3 of survey data
clear all
set more off
set type double


use "$gdData\Datain\Menage\s03_me_CIV2021.dta", clear
destring grappe, replace
g hhid=grappe*100+menage 
rename s01q00a numind

merge 1:1 vague grappe menage numind using "$gdData\Dataout\ehcvm_individu_CIV2021.dta", keepusing(hhweight)
drop _merge
drop if hhid==.
merge m:1 hhid using "$gdData\Dataout\ehcvm_welfare_CIV2021.dta", keepusing(pcexp hhsize)
drop _merge
merge m:1 hhid using "$gdTemp\yd.dta", keepusing(dec_yd_pc)
drop _merge	
drop if hhweight==.

/*****STEP - I****** The recall period is 4 weeks for primary care, so we are recommended to use the Bastagli Insurance Value approach (p260 of the handbook): 
		This approach assigns the same per capita spending to everybody sharing the same characteristic such as age, state, type of care, gender, etc
		The Bastagli Usage-Based approach should be used for the 1 year recall period for hospital visits*/

		/* generate a variable for whether or not an individual used a public, or private, healthcare service 
		TREATMENT_PLACE:
		*Public:
		1) CHU    2)CHR, y compris hôpital de police, hôpital militaire   3)Hôpital général
        4) Centre de santé urbain   5)Centre de santé rural/Dispensaire rural     6)Autre public
		*Private:
		7) Hôpital/Clinique privée  8)Cabinet médical/dentaire/ ophtalmologie    9)Cabinet de soins
        10) Pharmacie      11)Clinique d'entreprise, autre privé ou ONG    12)Chez le guérisseur/ tradipraticien 13)Home visit
		*/
		recode s03q07 (1 2 3 4 5 6=1 "Public service") (7 8 9 10 11 12 13=2 "Private") (.d=.), gen(type_healthfacility_prim)  
		replace type_healthfacility_prim = 0 if type_healthfacility_prim==. 
		lab var type_healthfacility_prim "Public, private, or other health service used in past 3 months"
		
	   /*HOSPITALIZATION_PLACE:
		*Public:
		1) CHU    2)CHR, y compris hôpital de police, hôpital militaire   3)Hôpital général
        4) Centre de santé urbain   5)Centre de santé rural/Dispensaire rural     6)Autre public
		*Private:
		7) Hôpital/Clinique privée  8)Cabinet médical/dentaire/ ophtalmologie    9)Cabinet de soins
        10)Pharmacie 11)Clinique d'entreprise, autre privé ou ONG    11)Chez le guérisseur/ tradipraticien 13)Home visit
		*/
		recode s03q23 (1 2 3 4 5 6=1 "Public service") (7 8 9 10 11 12 13=2 "Private") (.d=.), gen(type_healthfacility_hosp)  
		replace type_healthfacility_hosp = 0 if type_healthfacility_hosp==. 
		lab var type_healthfacility_hosp "Public, private, or other hospital service used in past year"		
		

		* generate a variable for whether an individual used a hospital or other health care service in past year
		g primary_care = ((s03q01==1 & s03q05==1) | s03q12==1 | (s03q13>0 & s03q13!=.d) | (s03q14>0 & s03q14!=.d))
		replace primary_care = 0 if s03q08==11		//attended to by traditional medicine
		g hospital_care = (s03q19==1)
		lab var primary_care "Primary level health care service used" 
		lab var hospital_care "Hospital care service used" 
		
	//Identify patients from survey	
		g hlt_hosp_ri =0
		replace hlt_hosp_ri= 1 if (hospital_care==1 & type_healthfacility_hosp ==1)		
		lab var hlt_hosp_ri "Individual used public hospital for inpatient care in last year"
		
		g hlt_prim_ri =0
		replace hlt_prim_ri = 1 if (primary_care==1 & type_healthfacility_prim==1)
		lab var hlt_prim_ri "Individual used primary healthcare for outpatient care in last month"
		
	//Identify visits per facility type from survey
		g hlt_hosp_visits = 0 
		replace hlt_hosp_visits = s03q20 if hlt_hosp_ri==1 & s03q20!=.
		lab var hlt_hosp_visits "How many times hospitalized in the past 12 months"
		
		g hlt_prim_visits = 0
		g primary_30d = (s03q01==1 & s03q05==1)
		replace primary_30d = primary_30d*12
		g primary_3m = s03q12==1
		replace primary_3m = primary_3m*4				
		replace hlt_prim_visits = primary_30d+primary_3m if hlt_prim_ri==1 		//Not picking up any of the 3 month visits, because there is no question for the place of treatment here. So not identified as hlt_prim_ri. Are these separate from the 30 day visits? Don't know. 
		lab var hlt_prim_visits "How many times accessed primary care in the past 12 months"

* Step 4: Userfees ************************************************************
		
	rename s03q18b fee_hlth_medi						//medicine (public) 3 months
	rename s03q13  fee_hlth_cons						//consultation 3 months
	rename s03q15  fee_hlth_dent						//dentist consultation 3 months
	rename s03q17  fee_hlth_exam						//exams and treatment 3 months
	rename s03q24  fee_hlth_hosp						//hospital costs 12 month
	rename s03q29  fee_hlth_vacc						//vaccinations 12 month
	rename s03q30  fee_hlth_circ						//circumcision 12 months
	rename s03q31  fee_hlth_chku						//checkup 12 months

		
		egen fee_hosp_in_yr = rowtotal(fee_hlth_hosp fee_hlth_vacc fee_hlth_circ fee_hlth_chku) if hlt_hosp_ri==1
		egen fee_phlt_in_yr = rowtotal(fee_hlth_medi fee_hlth_cons fee_hlth_dent fee_hlth_exam) if hlt_prim_ri==1
		replace fee_phlt_in_yr = fee_phlt_in_yr*4
		replace fee_hlth_medi = fee_hlth_medi*4
		replace fee_hlth_cons = fee_hlth_cons*4
		replace fee_hlth_dent = fee_hlth_dent*4
		replace fee_hlth_exam = fee_hlth_exam*4
		
		
save "$gdOut\health_use_base.dta", replace


***************************************************************************************
***************************Education***************************************************
***************************************************************************************
*Section 2 of survey data
********************************************
use "$gdData\Datain\Menage/s02_me_CIV2021.dta", clear
destring grappe, replace
g hhid=grappe*100+menage 
rename s01q00a numind

merge 1:1 vague grappe menage numind using "$gdData\Dataout\ehcvm_individu_CIV2021.dta", keepusing(hhweight age)
drop _merge
drop if hhid==.
merge m:1 hhid using "$gdData\Dataout\ehcvm_welfare_CIV2021.dta", keepusing(pcexp hhsize)
drop _merge
drop if hhweight==.

*Step 1: Identify what level of schooling people are attending

/* School Level Survey Categories:
	(1) Maternelle, (2) Primary, (3) Junior secondary general, (4) Junior secondary technical, (5) Senior secondary general, (6) Senior Secondary technical, (7) Post-secondary non-tertiary, (8)
	Tertiary
*/
g seco_scholar = (s02q14==3 | s02q14==5)
recode s02q14 (. =0) (1 2=1) (3 4 5 4 6 7=2) (8=3) , g(level_school)		//this is for the 17/18 school year, so for the first wave of survey it works, but may be slightly out od date in some cases for wave 2. Cannot differentiate by year level within grade category, unfortunatey. 

lab var level_school "Level of school student is attending"
*label define level 0"None" 1"Pre-primary" 2"Primary" 3"Secondary" 4"Vocational" 5"Tertiary"
label define level 0"None" 1"Primary" 2"Secondary" 3"Tertiary"
label values level_school level		


*Step 2: Identify whether public or private school
gen enrolled = 0
replace enrolled = 1 if s02q03==1 & s02q12==1		//attending school in formal institution in 2017/2018
replace enrolled = 2 if s02q03==2					//not attending formal school

gen public = 0
replace public =1 if s02q19==1 & enrolled==1
gen private = 0
replace private =1 if s02q19==2 | s02q19==3 | s02q19==4		//private religious, non-religious, or international school

*Step 3: Calculate a subsidy based on administrative data: Budget per school level / numbers of children enrolled at that level

gen edu_prim_ri = 1 if public == 1 & level_school==1	
*attending primary school
gen edu_seco_ri = 1 if public == 1 & level_school==2 	
* attending secondary
gen edu_tert_ri = 1 if public == 1 & level_school==3 	
* attending university

gen edu_prim_priv_ri = 1 if public == 0 & level_school==1	
*attending private primary school
gen edu_seco_priv_ri = 1 if public == 0 & level_school==2 	
* attending private secondary

*Some weird age ranges
replace edu_seco_ri= 0 if public==1 & level_school==2 & age<12		//it should not be possible for younger students to be in secondary. I will leave the older students (they go up to 38) because we include vocational here. 
replace edu_prim_ri= 1 if public==1 & level_school==2 & age<12		//assume the school level is meant to be primary
replace edu_prim_ri= 0 if public==1 & level_school==1 & age>40		//assume this is meant to be "highest attained" and take off the 41 yr old in primary (leave the 20 yr olds because I don't know the leniency for adult learners.)
replace edu_seco_priv_ri= 0 if public==0 & level_school==2 & age<12		//it should not be possible for younger students to be in secondary. I will leave the older students (they go up to 38) because we include vocational here. 
replace edu_prim_priv_ri= 1 if public==0 & level_school==2 & age<12		//assume the school level is meant to be primary
replace edu_prim_priv_ri= 0 if public==0 & level_school==1 & age>40		//assume this is meant to be "highest attained" and take off the 41 yr old in primary (leave the 20 yr olds because I don't know the leniency for adult learners.)

replace level_school = 1 if level_school==2 & age<12
replace seco_scholar = 0 if age<12

g edu_prim_ind = 0
g edu_seco_ind = 0
g edu_tert_ind = 0

*Enrolment figures
/*We did not receive official enrolment figures from the government; they sent us to UNICEF. UNICEF reports enrolment rates by level. 
Primary: 77%				population aged 6-11: 	13.715%		3,768,882,000			enrolled pop: 2,902,039,140			private: 57.87% 	enrolled public: 1,222,629,090		enrolled private: 1,679,410,050	
Lower Secondary: 40%		population aged 12-15: 	12.62%		3,467,976,000			enrolled pop: 1,387,190,400			private: 18.13%		enrolled public: 1,135,692,781		enrolled private: 251,497,619
Upper Secondary: 17% 		population aged 16-18:  11.175%		3,070,890,000			enrolled pop:   522,051,300			private: 18.13% 	enrolled public:   427,403,399		enrolled private: 94,647,901
Tertiary: 10%				population aged 19-22:   9.62%		2,643,576,000			enrolled pop:   264,357,600				

*/
*******************************************************************************************************************************************
*Scholarship identification
*The scholarships are for junior high and senior high school students with high test scores and higher-ed students with high scores. The total expenditure for secondary is about 1b; we dont have exp for tertiary. 
*There is a question for scholarships received in the education module. 
replace s02q28=0 if s02q28==.
rename s02q28 dtr_schl_in			//61,105 scholarships; 10,190 to public school students. Are these scholarships for anyone? 

g schl_rvcd = (dtr_schl_in>0)

g dtr_schl_ri = (dtr_schl_in>0 & seco_scholar==1 & public==1)
replace dtr_schl_ri = 1 if dtr_schl_in>0 & level_school==3 & public==1

replace dtr_schl_in=0 if dtr_schl_ri==0

save "$gdTemp\students.dta", replace


*Calculate user fees (directly identified)
merge m:1 hhid using "$gdTemp\yd.dta", keepusing (dec_yd_pc pcweight hsize)
	drop _merge	
	
rename s02q20 fee_educ_tuit
rename s02q22 fee_educ_supp
rename s02q24 fee_educ_unif
rename s02q26 fee_educ_tran
rename s02q27 fee_educ_othr

egen fee_educ_totl = rowtotal(fee_educ_tuit fee_educ_supp fee_educ_unif fee_educ_tran fee_educ_othr)

recode fee_educ_* (. =0)

foreach dec of numlist 1/10{
	foreach type in prim seco tert {
		gen fee_`type'_`dec'_in = 0
		replace fee_`type'_`dec'_in = fee_educ_totl if edu_`type'_ri==1 & fee_educ_totl !=. & dec_yd_pc==`dec'
		qui sum fee_`type'_`dec'_in [w=hhweight] if fee_`type'_`dec'_in>0 & fee_`type'_`dec'_in!=.
			loc fee_`type'_`dec'_mean = r(mean) 		//calculate the mean of the userfees for each level of education 
			disp `fee_`type'_`dec'_mean'
			replace fee_`type'_`dec'_in = `fee_`type'_`dec'_mean' if edu_`type'_ri==1 & dec_yd_pc==`dec'
		}
	}
    egen fee_prim_in = rowtotal(fee_prim_1_in fee_prim_2_in fee_prim_3_in fee_prim_4_in fee_prim_5_in fee_prim_6_in fee_prim_7_in fee_prim_8_in fee_prim_9_in fee_prim_10_in)
    egen fee_seco_in = rowtotal(fee_seco_1_in fee_seco_2_in fee_seco_3_in fee_seco_4_in fee_seco_5_in fee_seco_6_in fee_seco_7_in fee_seco_8_in fee_seco_9_in fee_seco_10_in)
    egen fee_tert_in = rowtotal(fee_tert_1_in fee_tert_2_in fee_tert_3_in fee_tert_4_in fee_tert_5_in fee_tert_6_in fee_tert_7_in fee_tert_8_in fee_tert_9_in fee_tert_10_in)
	drop fee_prim_1_in-fee_tert_10_in

save "$gdOut\educ_base.dta", replace



************************************************************************************************************************************************
***************************************************************************************
***************************NHI Pilot***************************************************
***************************************************************************************


use "$gdTemp\students.dta", clear
drop s02*

gen indid = _n

*Healthcare costs: The health fees are already estimated elsewhere. Does it make sense to estimate this as a transfer on-paper, so that in the marginal changes we can see this individually and in an accounting sense
*we can see the net benefit of the respondent?


merge 1:1 vague grappe menage numind using "$gdOut\health_use_base.dta", keepusing(fee_hosp_in_yr fee_phlt_in_yr hlt_hosp_ri hlt_prim_ri fee_hlth_medi fee_hlth_cons fee_hlth_exam)
drop _merge

foreach var in medi cons exam{
	replace fee_hlth_`var' = 0 if hlt_prim_ri==0
	}

egen hlth_fees = rowtotal(fee_hlth_medi fee_hlth_cons fee_hlth_exam fee_hosp_in_yr)
replace hlth_fees=0 if hlth_fees==.

*bring in public health insurance information
preserve 
	use "$gdData\Datain\Menage\s03_me_CIV2021.dta", clear
	destring grappe, replace
	g hhid=grappe*100+menage 
	rename s01q00a numind
	
	rename s03q32 hasinsurance
	rename s03q33 percentcov
	rename s03q34 ins_payer
	rename s03q35 ins_period

	g nhi_ins_ri = (hasinsurance==1 & (ins_payer==2 | ins_payer==3))
	
	tempfile nhi_elig
	save `nhi_elig'
restore

merge 1:1 hhid numind using `nhi_elig', keepusing(nhi_ins_ri hasinsurance ins_payer percentcov)
drop _merge
merge m:1 hhid using "$gdTemp\yd.dta", keepusing (poor_nat dec_yd_pc pcweight hsize)
drop _merge
drop if hhweight==.	

	g nhi_p_elig = 2
	replace nhi_p_elig=1 if nhi_ins_ri==1 & poor_nat==1
	g nhi_np_elig = 2
	replace nhi_np_elig=1 if nhi_ins_ri==1 & poor_nat==0

*Randomly select 75,000 poor; 1,425,000 non poor
set seed 74375322
	g rand = uniform()
	bysort indid: replace rand = rand[1]
	gsort -rand
	bysort nhi_p_elig: gen pelig= sum(pcweight)
	bysort nhi_np_elig: gen npelig= sum(pcweight)

	replace hlth_fees= 0 if hlth_fees==.
	replace fee_phlt_in_yr= 0 if fee_phlt_in_yr==.

save "$gdOut\nhi_base.dta", replace


