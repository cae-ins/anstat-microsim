*Cote d'Ivoire 2021 Education
*25 Aug 2023
*Ian Houts

*Section 2 of survey data
********************************************
clear all
set more off
set type double

use "$gdOut\educ_base.dta", clear

* Total public education expenditures is taken from budget year 2022". 
*by level expenditure as stated in budget		//prek and prim are aggregated; secondary and vocational are aggregated. 
global edu_prim_exp = 587500000000		//Total operational budget for preprimary and primary education (XOF)
global edu_seco_exp = 509900000000		//Total operational budget for secondary and vocational education (XOF)			
global edu_tert_exp = 282400000000		//Total operational budget for tertiary education (XOF)
global edu_othr_exp =    600000000		//Total operational budget for nonlevel education expenditure (XOF)


*Student populations for each level from admin figures (source: UNICEF for primary and secondary; Education Information Management System for Tertiary) :			
global enroll_prim_na =     4280111		//admin 2927081  		//Total public school student population for preprimary and primary education		//77% of primary age population (82% of total primary enrolment)
global enroll_seco_na =   	1416161		//admin 1213282  		//Total public school student population for secondary and vocational education		//40% of lsec age population; 17% of usec (42% of total secondary enrolment)	
global enroll_tert_na =      171656		//admin 157064			//Total public school student population for tertiary education
global enroll_totl_na = $enroll_prim_na + $enroll_seco_na + $enroll_tert_na

global enroll_prim_priv =    1102392	//admin 642530  		//Total private school student population for preprimary and primary education		//18% of total primary enrolment
global enroll_seco_priv =    1440189	//admin 845813 		//Total private school student population for secondary and vocational education	//58% of total secondary enrolment		
global enroll_totl_priv = $enroll_prim_priv + $enroll_seco_priv 
*************************************************************************************************************************************

* Budget expenditure as per level of school per person *
	loc exp_prim_sub = ( $edu_prim_exp * 0.824337091) / $enroll_prim_na 	//   
	loc exp_seco_sub = ( $edu_seco_exp * 0.824337091) / $enroll_seco_na	 	//   
	loc exp_tert_sub = $edu_tert_exp / $enroll_tert_na 						// 
	loc exp_othr_sub = ( $edu_othr_exp * 0.824337091) / $enroll_totl_na	 	// 
	
	loc priv_prim_sub = ( $edu_prim_exp * 0.175662909) / $enroll_prim_priv 	//   
	loc priv_seco_sub = ( $edu_seco_exp * 0.175662909) / $enroll_seco_priv  //   
	loc priv_othr_sub = ( $edu_othr_exp * 0.175662909) / $enroll_totl_priv  //   	
	
* STEP 4: Apply the subsidy 

	replace edu_prim_ind = `exp_prim_sub' + `exp_othr_sub' if edu_prim_ri == 1   
	replace edu_seco_ind = `exp_seco_sub' + `exp_othr_sub' if edu_seco_ri == 1    
	replace edu_tert_ind = `exp_tert_sub' + `exp_othr_sub' if edu_tert_ri == 1   
	replace edu_prim_ind = `priv_prim_sub' + `priv_othr_sub' if edu_prim_priv_ri == 1   
	replace edu_seco_ind = `priv_seco_sub' + `priv_othr_sub' if edu_seco_priv_ri == 1    
	gen subsidy=0
	replace subsidy=1 if edu_prim_ri==1 | edu_seco_ri==1 | edu_tert_ri==1 | edu_prim_priv_ri == 1 | edu_seco_priv_ri == 1

*Step 5: collapse dataset, save
collapse (sum) edu_*_ind fee_*_in dtr_schl_hh=dtr_schl_in (max) edu_*_ri, by(hhid hhweight)
ren edu_*_ind edu_*_hh
ren fee_*_in fee_*_hh

egen edu_hh = rowtotal(edu_prim_hh edu_seco_hh edu_tert_hh)
egen fee_edu_hh = rowtotal(fee_prim_hh fee_seco_hh fee_tert_hh)
		
	
save "$gdTemp\educ_final.dta", replace
