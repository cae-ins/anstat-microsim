*Cote d'Ivoire 2021
*Postsimulation
*Ian Houts
*28 Aug, 2023

clear all 
set more off
set type double

use "$gdTemp\yd.dta", clear

merge 1:1 hhid using "$gdTemp\dtx_final.dta", keepusing(dtx_pitx_hh dtx_pyrl_hh dtx_prop_hh dtx_igrx_hh dtx_ibic_hh dtx_rent_hh dtx_capt_hh con_natn_hh dtx_fama_hh dtx_indu_hh cpn_cnps_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\dtr_final.dta", keepusing(dtr_pssn_hh oth_econ_hh)
drop if _merge==1
drop _merge
merge 1:1 hhid using "$gdTemp\dtr_famind_final.dta", keepusing(dtr_fama_hh dtr_indu_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\vat_final.dta", keepusing(itx_vatx_hh itx_dvat_hh itx_ivat_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\excise_final.dta", keepusing(itx_excs_hh itx_exca_hh itx_exct_hh itx_exco_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\customs_final.dta", keepusing(itx_cust_hh itx_dcus_hh itx_icus_hh)
drop _merge
merge 1:1 hhid using "$gdOut\itx_moto_final.dta", keepusing(itx_moto_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\sub_elec_final.dta", keepusing(sub_elec_hh itx_elec_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\sub_watr_final.dta", keepusing(sub_watr_hh itx_wsub_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\sub_fuel_final.dta", keepusing(sub_fuel_hh sub_dfuel_hh sub_ifuel_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\educ_final.dta", keepusing(edu_prim_hh edu_seco_hh edu_tert_hh fee_prim_hh fee_seco_hh fee_tert_hh dtr_schl_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\health_use_final.dta", keepusing(hlt_prim_hh hlt_hosp_hh fee_phlt_hh fee_hosp_hh)
drop _merge
merge 1:1 hhid using "$gdTemp\nhi_insu_final.dta", keepusing(con_hins_hh hlt_insu_hh)
drop _merge

save "$gdOut\merged_ceqincome.dta", replace

rename con_natn_hh dtx_natn_hh
rename dtx_fama_hh con_fama_hh
rename dtx_indu_hh con_indu_hh

loc varlist dtx_pitx dtx_pyrl dtx_igrx dtx_ibic dtx_rent dtx_prop dtx_capt dtx_natn con_fama con_indu cpn_cnps dtr_pssn oth_econ dtr_fama dtr_indu dtr_schl itx_vatx itx_dvat itx_ivat itx_moto itx_excs itx_exca itx_exct itx_exco itx_cust itx_dcus itx_icus itx_wsub itx_elec sub_elec sub_watr sub_fuel sub_dfuel sub_ifuel edu_prim edu_seco edu_tert fee_prim fee_seco fee_tert hlt_prim hlt_hosp fee_phlt fee_hosp con_hins hlt_insu

*Deflate variables by spatially and temporally so they match the consumption aggregate used.
 	foreach var of local varlist {
		replace `var'_hh = `var'_hh*def_spa	//def_temp already deflated temporally
		}
		
* Generate the adult equivalent and per capita variables, and change all missing values to 0 
	foreach var of local varlist {
		replace `var'_hh = 0 if `var'_hh == . 
		g `var'_pc = `var'_hh/hsize
		replace `var'_pc = 0 if `var'_pc == . 
	}

* Generate summary variables 
foreach scen in pc{
egen dtx_`scen' = rowtotal(dtx_pitx_`scen' dtx_pyrl_`scen' dtx_prop_`scen' dtx_natn_`scen')
egen itx_`scen' = rowtotal(itx_vatx_`scen' itx_excs_`scen' itx_cust_`scen' itx_moto_`scen' itx_wsub_`scen' itx_elec_`scen')	//itx_fuel_totl_`scen'
egen fee_hlth_`scen' = rowtotal(fee_hosp_`scen' fee_phlt_`scen')
egen fee_educ_`scen' = rowtotal(fee_prim_`scen' fee_seco_`scen' fee_tert_`scen')
egen hlt_`scen' = rowtotal(hlt_prim_`scen' hlt_hosp_`scen')	
egen edu_`scen' = rowtotal(edu_prim_`scen' edu_seco_`scen' edu_tert_`scen')
egen dtr_`scen' = rowtotal(dtr_pssn_`scen' dtr_schl_`scen' dtr_fama_`scen' dtr_indu_`scen' hlt_insu_`scen')
egen con_`scen' = rowtotal(con_fama_`scen' con_indu_`scen' con_hins_`scen')
egen sub_`scen' = rowtotal(sub_watr_`scen' sub_elec_`scen' sub_fuel_`scen')	
}


tempfile temp 
save `temp'
capture confirm file "$gdOut\yl.dta"   //this produces an error if yl.dta does not exist, and if there is an error will store information in a variable called _rc
if _rc{


*******
*PDI scenario
*******
* Moving backwards to market income 
	drop if yd_hh==. | yd_pc==.
	g yn_pc = yd_pc - dtr_pc
	g yg_pc = yd_pc + dtx_pc + con_pc
	g yp_pc = yd_pc + dtx_pc + con_pc - dtr_pc
	g yl_pc = yp_pc
	
* Moving forwards to consumable and final income 
	g yc_pc = yd_pc - itx_pc + sub_pc
	g yf_pc = yc_pc + hlt_pc + edu_pc + oth_econ_pc

	keep yl_pc hhid
	save "$gdOut\yl.dta", replace 
	use `temp'
}
else{
	use `temp'
}


merge 1:1 hhid using "$gdOut\yl.dta", keepusing(yl_pc)
drop _merge
drop yd_pc yd_hh 

	*******
	*PDI scenario
	*******
* starting from yl 
	g yp_pc = yl_pc 			 					//market income plus pensions (CIV does not have publically-subsidized contributory pensions, so yp and yl are equal)
	g yn_pc = yp_pc - dtx_pc - con_pc 				//net market income	= income before direct transfers are added, but after direct taxes are removed
	g yg_pc = yp_pc + dtr_pc						//gross market income = income before direct taxes are removed, but after direct transfers are added
	g yd_pc = yn_pc + dtr_pc 						//disposable income = equal to consumption, or income after pensions and direct transfers are added and direct taxes are removed
	g yc_pc = yd_pc - itx_pc + sub_pc				//consumable income	= indirect taxes are removed and indirect subsidies are added
	g yf_pc = yc_pc + hlt_pc + edu_pc + oth_econ_pc	//final income = in-kind transfers are added


* Generate the pc and hh income concepts 
	foreach inc in yd yn yg yp yl yc yf fee_hlth fee_educ{
		replace `inc'_pc = 0 if `inc'_pc<0
		g `inc'_hh = `inc'_pc*hsize
		}

* Label all the variables 
foreach var in dtx dtr itx hlt edu sub con{		
drop `var'_pc
}


*Per Capita Labels
lab var dtx_pitx_pc  	"Personal Income Tax, pc"
lab var dtx_pyrl_pc  	"Payroll Tax, pc"
lab var dtx_prop_pc  	"Property Tax, pc"
lab var dtr_pssn_pc		"Direct Transfer: PSSNP, pc"
lab var dtr_fama_pc		"Direct Transfer: family allowance benefit, pc"
lab var dtr_indu_pc		"Direct Transfer: industrial accident benefit, pc"
lab var dtr_schl_pc		"Direct Transfer: scholarships, pc"
lab var dtx_natn_pc  	"Contributions to social security: National Contribution, pc"
lab var con_indu_pc		"Contributions to industrial accident benefit, pc"
lab var con_fama_pc  	"Contributions to family accident, pc"
lab var con_hins_pc  	"Contributions to National Health Insurance: pilot program, pc"
lab var sub_watr_pc  	"Indirect subsidy: Water, pc"
lab var sub_elec_pc  	"Indirect subsidy: Electricity, pc"
lab var sub_fuel_pc  	"Indirect subsidy: Fuel, pc"
lab var itx_dvat_pc  	"Value Added Tax: direct effects, pc"
lab var itx_ivat_pc  	"Value Added Tax: indirect effects, pc"
lab var itx_vatx_pc  	"Value Added Tax, pc"
lab var itx_excs_pc  	"Excise Tax, pc"
lab var itx_cust_pc  	"Customs Duties: total, pc"
lab var itx_dcus_pc  	"Customs Duties: direct effects, pc"
lab var itx_icus_pc  	"Customs Duties: indirect effects, pc"
lab var itx_moto_pc		"Motor Vehicle Registration Tax, pc"
lab var itx_wsub_pc		"Water tax, pc"
lab var itx_elec_pc		"Electricity tax, pc"
lab var hlt_prim_pc  	"Healthcare: primary care, pc (usage approach)"
lab var hlt_hosp_pc  	"Healthcare: hospital care, pc (usage approach)"
lab var hlt_insu_pc		"Healthcare: NHI pilot benefits, pc"
lab var edu_prim_pc  	"Education, primary school, pc"
lab var edu_seco_pc  	"Education, secondary school, pc"
lab var edu_tert_pc  	"Education, tertiary education, pc"
lab var oth_econ_pc		"In-Kind Transfer: PSSNP Economic Inclusion training, pc"
lab var fee_hlth_pc  	"User Fees: healthcare, pc"
lab var fee_educ_pc  	"User fees: education, pc"

lab var yl_pc	 		"Market income (PDI), pc"
lab var yp_pc 			"Market income plus pensions (PDI), pc"
lab var yg_pc 			"Gross income (PDI), pc"
lab var yn_pc 			"Net market income (PDI), pc"
lab var yd_pc 			"Disposable income  (PDI), pc"
lab var yc_pc 			"Consumable income (PDI), pc"
lab var yf_pc	 		"Final income (PDI), pc"


*Household Labels
lab var dtx_pitx_hh  	"Personal Income Tax, hh"
lab var dtx_pyrl_hh  	"Payroll Tax, hh"
lab var dtx_prop_hh  	"Property Tax, hh"
lab var dtr_pssn_hh		"Direct Transfer: PSSNP, hh"
lab var dtr_fama_hh		"Direct Transfer: family allowance benefit, hh"
lab var dtr_indu_hh		"Direct Transfer: industrial accident benefit, hh"
lab var dtr_schl_hh		"Direct Transfer: scholarships, hh"
lab var dtx_natn_hh  	"Contributions to social security: National Contribution, hh"
lab var con_indu_hh		"Contributions to industrial accident benefit, hh"
lab var con_fama_hh  	"Contributions to family accident, hh"
lab var con_hins_hh  	"Contributions to National Health Insurance: pilot program, hh"
lab var sub_watr_hh  	"Indirect subsidy: Water, hh"
lab var sub_elec_hh  	"Indirect subsidy: Electricity, hh"
lab var sub_fuel_hh  	"Indirect subsidy: Fuel, hh"
lab var itx_dvat_hh  	"Value Added Tax: direct effects, hh"
lab var itx_ivat_hh  	"Value Added Tax: indirect effects, hh"
lab var itx_vatx_hh  	"Value Added Tax, hh"
lab var itx_excs_hh  	"Excise Tax, hh"
lab var itx_cust_hh  	"Customs Duties: total, hh"
lab var itx_dcus_hh  	"Customs Duties: direct effects, hh"
lab var itx_icus_hh  	"Customs Duties: indirect effects, hh"
lab var itx_moto_hh		"Motor Vehicle Registration Tax, hh"
lab var itx_wsub_hh		"Water tax, hh"
lab var itx_elec_hh		"Electricity tax, hh"
lab var hlt_prim_hh  	"Healthcare: primary care, hh (usage approach)"
lab var hlt_hosp_hh  	"Healthcare: hospital care, hh (usage approach)"
lab var hlt_insu_hh		"Healthcare: NHI pilot benefits, hh"
lab var edu_prim_hh  	"Education, primary school, hh"
lab var edu_seco_hh  	"Education, secondary school, hh"
lab var edu_tert_hh  	"Education, tertiary education, hh"
lab var oth_econ_hh		"In-Kind Transfer: PSSNP Economic Inclusion training, hh"
lab var fee_hlth_hh  	"User Fees: healthcare, hh"
lab var fee_educ_hh  	"User fees: education, hh"

lab var yl_hh	 		"Market income (PDI), hh"
lab var yp_hh 			"Market income plus pensions (PDI), hh"
lab var yg_hh 			"Gross income (PDI), hh"
lab var yn_hh 			"Net market income (PDI), hh"
lab var yd_hh 			"Disposable income  (PDI), hh"
lab var yc_hh 			"Consumable income (PDI), hh"
lab var yf_hh	 		"Final income (PDI), hh"


*Miscellaneous Labels
lab var year 			"Year"
lab var psu 			"Primary Sampling Unit"
lab var hhid			"Household ID"
lab var hsize			"Household size"
lab var urban			"Urban=1, Rural=0"
lab var weight			"Household sampling weight"
lab var pl_nat 			"National poverty line"
lab var def_spa			"Spatial deflator"
lab var def_temp		"Temporal deflator"
lab var pcweight		"Population weights"

*Putting taxable income in to see if it will help E9 and E14 run
g yt_pc = yg_pc

*Drop observations if all data is missing

save "$gdOut\CIV21WBN_ceqincome.dta", replace


