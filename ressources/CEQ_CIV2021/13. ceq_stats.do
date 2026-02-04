*CeqStats for CIV AppTool

clear all
set type double
set more off

/*===============================================================================
		*Define variables of CEQ following the set of lists 
*===============================================================================*/

/* Defining locals of direct and indirect taxes and direct and indirect transfers at HH level */
	 
	global tax dtx_pitx dtx_pyrl dtx_natn
	global tax_pc dtx_pitx_pc dtx_pyrl_pc dtx_natn_pc
	global indtax itx_vatx itx_excs itx_cust itx_wsub itx_elec
	global indtax_pc itx_vatx_pc itx_excs_pc itx_cust_pc itx_wsub_pc itx_elec_pc
	global inkind hlt_prim hlt_hosp edu_prim edu_seco edu_tert
	global inkind_pc hlt_prim_pc hlt_hosp_pc edu_prim_pc edu_seco_pc edu_tert_pc
	global transfer dtr_pssn dtr_schl dtr_fama dtr_indu hlt_insu
	global sub sub_watr sub_elec sub_fuel
	global alltransfer sub_watr sub_elec sub_fuel dtr_pssn dtr_schl dtr_fama dtr_indu hlt_insu
	global alltransfer_pc sub_watr_pc sub_elec_pc sub_fuel_pc dtr_pssn_pc dtr_schl_pc dtr_fama_pc dtr_indu_pc hlt_insu_pc
	global health hlt_prim hlt_hosp
	global edu edu_prim edu_seco edu_tert
	global cpn cpn_cnps
	global cpn_pc cpn_cnps_pc
	global con con_fama con_indu con_hins
	global con_pc con_fama_pc con_indu_pc con_hins_pc
	
	global income yl yp yn yg yd yc yf   //
	global income_pc yl_pc yp_pc yn_pc yg_pc yd_pc yc_pc yf_pc   //
	global concs $tax $indtax $transfer $sub $inkind $income $cpn $con

	foreach x in $tax $indtax $inkind $alltransfer $income $concs {
		local `x'_pc
		foreach y of local `x' {
			local `x'_pc ``x'_pc' `y'_pc 	
		} // end of elements of each list 
	} // end of set of lists

/*Defining ranking variable and poverty lines */

	global rank yp_pc
	global pline pl_nat pl_215 pl_365 pl_685
	
/*Load user data*/ 
use "$gdOut\CIV21WBN_ceqincome.dta", clear

foreach var in itx_vatx itx_excs itx_cust itx_wsub itx_elec cpn_cnps dtx_natn con_fama con_indu con_hins{
	replace `var'_pc = `var'_pc*-1
	}
	
	
	
*==================================================================================*
*Poverty
*==================================================================================*
povdeco yd_pc [fw=int(pcweight)], varpline(pl_nat) 

foreach inc in $income {
	qui povdeco `inc'_pc [fw=int(pcweight)] , varpl(pl_nat)
		loc `inc'_nat_pov = r(fgt0)
		disp "Poverty national pl: `inc' = "``inc'_nat_pov'
	}
	
foreach inc in $income {
	qui povdeco `inc'_pc [fw=int(pcweight)] , varpl(pl_365)
		loc `inc'_320_pov = r(fgt0)
		disp "Poverty 320pl: `inc' = "``inc'_320_pov'
	}

*==================================================================================*
*Inequality
*==================================================================================*
foreach inc in $income {
	qui ineqdeco `inc'_pc [w=pcweight] 
	loc `inc'_gini = r(gini)
	disp "Gini: `inc' = "``inc'_gini'
	}
/*===============================================================================*
		*A. Produce Concentration by centile_pc
*===============================================================================*

dis " `concs_pc' "


	foreach x of local concs_pc {
		covconc `x' [aw=weight] , rank(`rank')	//gini and concentration coefficients
		local _`x' = r(conc)
	}
	
	groupfunction [aw=weight], sum(`concs_pc') by(centile) norestore
		qui count
		local _1 =r(N)
		local nnn=`_1'+ 1  //add one more obs, the total obs goes from 100 to 101
		set obs `nnn'
		replace centile = 0 in `nnn'
	
		sort centile
		putmata x = (`concs_pc') if centile!=0, replace 
		mata: x = J(1,cols(x),0) \ x  //generate a constant row, add to the top
		mata: x = x:/quadcolsum(x)  //divide each element by the column total
		mata: for(i=1; i<=cols(x);i++) x[.,i] = quadrunningsum(x[.,i])  //replace exisiting matrix by new elements
		
		getmata (`concs_pc') = x, replace
		
		qui count
		local _1 =r(N)
		local nnn=`_1'+ 1 //add one more obs, the total obs goes to 102
		set obs `nnn'
		
		replace centile = 999 in `nnn'
		foreach x of local concs_pc {
			replace `x' = `_`x'' in `nnn'  //replace the last observation with gini/concentration coefficient
		}	
	order centile, first
	
	*Display
	
	export excel using "xls_sn", sheet(concentration) sheetreplace first(variable)

*/
	
	
*==================================================================================*
*Incidence by decile
*==================================================================================*
use "$gdOut\CIV21WBN_ceqincome.dta", clear

* collapse (sum) $tax $indtax $transfer $sub $health $edu yd,  by (dec_yd_pc)

foreach fi in $tax $cpn $con $indtax $transfer $sub $health $edu yd{
	qui sum `fi'_pc [w=pcweight]
	loc `fi'_totl = r(sum)
	}
	
foreach fi in $tax $cpn $con $indtax $transfer $sub $health $edu yd{	
	foreach dec of numlist 1/10{
		qui sum `fi'_pc [w=pcweight] if dec_yd_pc==`dec'
		loc `fi'_`dec' = r(sum)
		disp "`fi' in `dec' = " ``fi'_`dec'' 
		}
	}

foreach fi in $tax $cpn $con $indtax $transfer $sub $health $edu yd{	
	foreach dec of numlist 1/10{
		loc incd_`fi'_`dec' = ``fi'_`dec'' / `yd_`dec''
		disp "`fi' in `dec' = " `incd_`fi'_`dec''
		}
	}

*==================================================================================*
*Concentration Share by decile
*==================================================================================*

foreach fi in $tax $cpn $con $indtax $transfer $sub $health $edu{	
	foreach dec of numlist 1/10{
		loc conc_`fi'_`dec' = ``fi'_`dec'' / ``fi'_totl'
		disp "`fi' in `dec' = " `conc_`fi'_`dec''
		}
	}

*drop sum_*


/*===============================================================================
		*B. Netcash Position
*===============================================================================*/


*net cash market income + pensions 
use "$gdOut\CIV21WBN_ceqincome.dta", clear
	
		foreach x in $tax $indtax $cpn $con  {
			gen share_`x'_pc= -`x'_pc/yp_pc
		}		
	
		foreach x in $alltransfer $inkind {
			gen share_`x'_pc= `x'_pc/yp_pc
		}
		
	
		*replace share_snit_hh_ae = - share_snit_hh_ae
		keep dec_yd_pc share* weight	
		
	*groupfunction [aw=weight], mean (share*) by(dec_yd_pc) norestore
	collapse (mean) share_dtx_pitx_pc-share_edu_tert_pc [aw=weight], by(dec_yd_pc)
	
	*reshape long share_, i(dec_yd_pc) j(variable) string
	*gen measure = "netcash" 
	*rename share_ value
	
	tempfile netcash_ymp
	save `netcash_ymp'

*net cash as disposable income  	
	
use "$gdOut\CIV21WBN_ceqincome.dta", clear
	
		foreach x in $tax $indtax $cpn $con  {
			gen share_`x'_pc= -`x'_pc/yd_pc
		}		
	
		foreach x in $alltransfer $inkind {
			gen share_`x'_pc= `x'_pc/yd_pc
		}
		
		*replace share_snit_hh_ae = - share_snit_hh_ae
		keep dec_yd_pc share* weight	
		
	*groupfunction [aw=weight], mean (share*) by(dec_yd_pc) norestore
	collapse (mean) share_dtx_pitx_pc-share_edu_tert_pc [aw=weight], by(dec_yd_pc)
	
*reshape long share_, i(dec_yd_pc) j(variable) string
*gen measure = "netcash" 
*rename share_ value
	
	tempfile netcash_yd
	save `netcash_yd'
		
	
	

/*===============================================================================
		*C. Produce Gini, Theil, and Poverty  measure to measure 
		 Marginal Contribution
*===============================================================================*/


use "$gdOut\CIV21WBN_ceqincome.dta", clear

gen all = 1
local income2 ""

local aux1 $tax $cpn $con 
foreach var of local aux1 {
	
	gen inc_`var'=yp_pc-`var'_pc // (DV) here ypc is the world without the policy 
	
	local income2 `income2' inc_`var'   // Store incomes to marignal contribution calculation
	
	}


local aux4 $alltransfer
foreach var of local aux4 {
	
	gen inc_`var'=yp_pc+`var'_pc // (DV) here ypc is the world without the policy 
	
	local income2 `income2' inc_`var'   // Store incomes to marignal contribution calculation
	
	}

local aux2 $indtax 
foreach var of local aux2 {
	
	gen inc_`var'=yd_pc-`var'_pc // (DV) here yd_pc is the world with the policy 
	
	local income2 `income2' inc_`var'   // Store incomes to marignal contribution calculation
	
	}
	
local  	aux3 $inkind
foreach var of local aux3 {
	
	gen inc_`var'=yc_pc+`var'_pc // (DV) change from market income to disposable income 
	
	local income2 `income2' inc_`var' // Store incomes to marignal contribution calculation
}

sp_groupfunction [aw=weight], gini($income_pc `income2') theil($income_pc  `income2') poverty($income_pc  `income2') povertyline($pline)  by(all) 

tempfile poverty
save `poverty'


/*===============================================================================
		*D. Kakwani
*===============================================================================*/
*Set locals for gini at different income concepts
use "$gdOut\CIV21WBN_ceqincome.dta", clear

foreach inc in $income {
	qui ineqdeco `inc'_pc [w=pcweight] 
	loc `inc'_gini = r(gini)
	disp "Gini: `inc' = "``inc'_gini'
	}
	
foreach x in $tax $indtax $cpn $con $alltransfer $inkind {
	qui ineqdeco `x'_pc [w=pcweight] 
	loc `x'_gini = r(gini)
	disp "Gini: `x' = "``x'_gini'
	}	
	
foreach inc in $income {
	foreach x in $tax $indtax $cpn $con {
		loc `x'_kakwani = ``x'_gini' - ``inc'_gini'
		disp "Kakwani: `inc'_`x' =" ``x'_kakwani'
		}
	}

foreach inc in $income {
	foreach x in $alltransfer $inkind {
		loc `x'_kakwani = ``inc'_gini' - ``x'_gini'
		disp "Kakwani: `inc'_`x' =" ``x'_kakwani'
	}
}


/*===============================================================================
		*E. Total revenue and Expenditure
*===============================================================================*/

 egen	total_revenue = rowtotal($tax_pc $indtax_pc $cpn_pc $con_pc )
 sum total_revenue [w=pcweight]
 disp %20.0f r(sum)
 
 egen   total_expend  = rowtotal($alltransfer_pc $inkind_pc)
 sum total_expend [w=pcweight]
  disp %20.0f r(sum)
 
