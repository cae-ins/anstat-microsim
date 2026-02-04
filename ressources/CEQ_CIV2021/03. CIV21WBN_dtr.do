*Cote d'Ivoire 2021
*October 20, 2022
*Ian Houts
*Direct Transfer

clear all 
set more off
set type double

global allocation = 36000		//Quarterly household benefit allocated to each household enrolled in the Productive Social Safety Net Program (XOF)
global econinclu  = 83.1		//Per capita benefit allocated to each household enrolled in the additional PSSN economic inclusion program (XOF)

global dtr_fama1 = 1666.66		//Monthly household benefit for each child eligible for the family allowance benefit (XOF)
global dtr_fama2 = 13500		//Total Household benefit for the Prenatal Allowance (total of three installments, XOF)
global dtr_fama3 = 18000		//Lump sum household benefit for a newborn eligible child under the Birth Grant (XOF)
global dtr_fama4 = 18000		//Total Household benefit for the Maternity Allowance (total of three installments, XOF)

global indfund_na = 8275831514	//Total annual expenditure to beneficiaries from industrial accident fund (XOF)

********************************************************************************************************************************************
*Productive Social Saftey Net Program
********************************************************************************************************************************************
use "$gdOut\dtr_base.dta", clear

replace dtr_pssn_hh = $allocation * 4 if dtr_elig==1
replace dtr_pssn_hh = $allocation if dtr_elig2==1
replace oth_econ_hh = $econinclu if dtr_elig2==1			//The economic inclusion component of this transfer is calculated as the total annual budget divided by the remaining households in the cohort in 2019. Don't know if the 36,000 per household includes this already? 


save "$gdTemp\dtr_final.dta", replace

********************************************************************************************************************************************
*Family Allowance and Industrial Accident Fund
********************************************************************************************************************************************

clear all
use "$gdOut\dtr_famind_base.dta", clear

merge 1:1 vague grappe menage numind using "$gdTemp\dtx_ind.dta", keepusing(con_inda_pc)
drop _merge

g con_indu_ri = (con_inda_pc>0 & con_inda_pc!=.)
g dtr_indu_hh = 0 

replace dtr_fama1 = $dtr_fama1 *12 if child_elig==1 & fama_elig==1

*prenatal allowance
replace dtr_fama2 = $dtr_fama2 if newborn==1 & fama_elig==1		//we can't identify pregnant women in the survey that I can find, so we will use newborns to proxy for the same rate of pregnancy in the year. 

*birth grant
replace dtr_fama3 = $dtr_fama3 if fama_elig==1 & fama_elig3==1 & total_child<=3

*maternity allowance
replace dtr_fama4 = $dtr_fama4 if yearold==1 & fama_elig==1

*Sum
egen dtr_fama_hh = rowtotal(dtr_fama1 dtr_fama2 dtr_fama3 dtr_fama4)
replace dtr_fama_hh = 0 if dtr_fama_hh==.



**********************************************************
*Industrial accident
loc indfund_na = $indfund_na
qui sum con_indu_ri [w=hhweight]
loc ind_contributors = r(sum)

display "`ind_contributors'"

loc insuval_dtr = `indfund_na' / `ind_contributors'

display "`insuval_dtr'"

replace dtr_indu_hh = `insuval_dtr' if con_indu_ri==1

save "$gdTemp\dtr_famind_temp.dta", replace

collapse (sum) dtr_fama_hh dtr_indu_hh, by(hhid hhweight)
merge 1:1 hhid using "$gdTemp\yd.dta", keepusing(dec_yd_pc)
drop _merge

save "$gdTemp\dtr_famind_final.dta", replace
