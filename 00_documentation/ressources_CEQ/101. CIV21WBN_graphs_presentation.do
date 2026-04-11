********************************************************************************************************************************************************************
**Graphs 
*********************************************************************************************************************************************************************
	set scheme white_tableau
	global labelsize 1.5
	global titlesize small
	global barlblsize small
	global notesize vsmall
	*global source "Authors' estimates based on EHCVM 2018/19 & Cameroon's ECAM4."
	global source ""
	global note_ph1 "The official national poverty headcount of 39.45 matches poverty at Disposable Income [total consumption temporally and spatially adjusted]."
	global note_ph2 "We do not calculate poverty at Final income because we value the health and education transfers at the average cost of provision."
	global note_gi1 "The official Gini coefficient of 37.2 does not match at Disposable Income. See annex for more information."
	global note_income "To calculate Net market income from Pre-fiscal income we subtract the direct taxes; we add the Direct transfers to calculate Disposable income; we subtract the indirect taxes and add the indirect subsidies to calculate Consumable income and we add the in-kind health and education transfers to calculate Final income."
	global note_netben1 "Net cash benefit refers to the system including all direct and indirect taxes, transfers and subsidies, and excluding in-kind health and education transfers."
	global note_netben2 "Net total benefit refers to the system including all elements, including in-kind health and education transfers."
	global note_inc1 "Incidence is a measure of size and distribution relative to a reference income."
	global note_inc2 "Transfers are shown as a positive bar and taxes are shown as a negative bar."
	global note_kk1 "The Kakwani Index is a summary statistic of progressivity [>0 = progressive]." 
	global note_kk2 "It is calculated for taxes by subtracting the Gini coefficient from the concentration coefficient."
	global note_kk3 "It is calculated for transfers by subtracting the concentration coefficient from the Gini coefficient."
	global note_mc1 "Marginal contributions are calculated as the change in a poverty or inequality indicator that results with the inclusion of a tax or transfer of interest."
	global note_mc2_yc "Marginal contributions are estimated at Consumable income."
	global note_mc2_yd "Marginal contributions are estimated at Disposable income."
	global note_mc2_yf "Marginal contributions are estimated at Final income."
	global note_mc3 "A positive bar represents a reduction in poverty or inequality, while a negative bar represents an increase."
	global note_mc4 "We don't calculate contributions to poverty for in-kind subsidies."
	global note_yd "Households are ranked over Disposable income"
	global note_cc1 "Concentration shares show the proportion of each tax/transfer paid by / benefitting each decile. They sum to 100%."
	global note_fi1 "Fiscal impoverishment: Percent of population i) poor at post-fiscal income and ii) made poorer by the fiscal system."
	global note_fi2 "Fiscal gains to the poor: Percent of population i) poor at pre-fiscal income and ii) experience gains in income due to the fiscal system."
	global note_fi3 "Pre-fiscal income is excluded from the graph because no fiscal impoverishment or fiscal gains can occur, by definition."
	global note_fi4 "Final income is excluded from the graph because we don’t measure changes in poverty at Final income."
	global note_fi5 "A positive bar represents the population experiencing fiscal gains, while a negative bar represents the population experiencing fiscal impoverishment."
	global note_fi6 "Sum of absolute value of bars doesn't add to 100 because percentages are calculated over poor populations at different income concepts."
	global note_fi7 "Sum of absolute value of bars doesn't add to total poverty headcount because percentages are calculated over poor populations at different income concepts."
	global conc_ytit "Concentration shares (%)"

*********************************************************************************************************************************************************************
* Poverty & inequality 
*********************************************************************************************************************************************************************

	use "$gdOut\gini_pov.dta", clear 
	
	// 1) Gini coefficient by income concept (slide 15)

	graph bar gi_pdis if inrange(y,1,6), over(y, gap(150)) blabel(bar, size($barlblsize) format(%9.1f)) bargap(0) title("Gini coefficient by income concept", size($titlesize)) ytitle("Gini coefficient") ///
	note({break} ///
	"Notes: [1] $note_gi1", size($notesize)) 
	graph save "$gdFig\gini_pdi", replace
	graph close

	order y 
	tabstat gi_pdis, by(y)

	// 2)  Poverty headcount by income concept (slide 17)
	
	graph bar ph_natl_pdis pg_natl_pdis if inrange(y,1,4) | y == 6, over(y) blabel(bar, size($barlblsize) format(%9.1f)) title("Poverty by income concept", size($titlesize)) ytitle("Poverty (percentage points)") ///
		legend(label(1 "Headcount") label(2 "Gap") pos(6) row(1)) note({break} ///
	"Notes:" "[1] $note_ph1" "[2] $note_ph2", size($notesize)) 
	graph save "$gdFig\pov_pdi", replace
	graph close

	tabstat ph_natl_pdis_ch pg_natl_pdis_ch ph_intl_pdis, by(y)



*********************************************************************************************************************************************************************
* Progressivity & Marginal contributions
*************************************************************************************************************************************************************************
use "$gdOut\c1.dta", clear
	//We need to multiply these amounts by the inverse of the ratio of the amount allocated in the survey to the amount in the budget. 

global pit_svy = dtx_pitx_pc_bn[1]
global pit_bdg = 476
global factor = ${pit_bdg}/${pit_svy}
disp $factor
disp ${factor}*dtx_pitx_pc_bn
g fisc_dtx_pitx_pc_bn = dtx_pitx_pc_bn*$factor  //baseline 
graph bar fisc_dtx_pitx_pc_bn, name("dtx_size", replace) asyvars blabel(bar, size($barlblsize) format(%9.1f)) bargap(50) title("b. Estimated fiscal position", size($titlesize)) ytitle("Billion francs)") ///
legend(label(1 "Baseline") label(2 "PITX") label(3 "IGRX") pos(6) row(1))

*********************************************************************************************************************************************************************
* Progressivity & Marginal contributions
*************************************************************************************************************************************************************************

** 1. Kakwani index (slide 21) 
	use "$gdOut\cc_kk_mc.dta", replace
	*numlabel, add
	*tabstat kk_yp, by(instrument)
	global barlblsize small
	
** Taxes and Transfers 
	graph hbar kk_yp if inlist(instrument,2,3,8,9,10,12,13,14,16,17,18,19,20,22,23,24,25,26,27,28,30,33,34,36,37,38,39,41,42), over(instrument, sort(kk_yp)) blabel(bar, size($barlblsize) format(%9.1f)) bargap(50) ytitle("Kakwani Index") // title("Progressivity of taxes and transfers", size($titlesize)) //note({break} ///
	// "Notes:" "[1] $note_kk1" "[2] $note_kk2" "[3] $note_kk3", size($notesize))
	graph save "$gdFig\kkw", replace 
	graph close

	graph bar kk_yp if inlist(instrument,2,43,44), name("dtxsim_kkw", replace) over(instrument) asyvars blabel(bar, size($barlblsize) format(%9.1f)) ytitle("Kakwani Index") title("a. Progressivity of PIT scenarios", size($titlesize)) bargap(50) ///
	legend(label(1 "Baseline") label(2 "PITX") label(3 "IGRX") pos(6) row(1))

 ** Taxes (this also includes userfees & contributions). 
 	graph hbar kk_yp if inlist(instrument,2,3,8,9,10,12,13,14,22,23,24,25,26,27,28,41,42), /// 
	over(instrument, sort(kk_yp)) blabel(bar, size($barlblsize) format(%9.1f)) bargap(50) ///
	ytitle("Kakwani Index") title("Progressivity of taxes", size($titlesize)) // title("Progressivity of taxes and transfers", size($titlesize)) //note({break} ///
	graph save "$gdFig\kkw_taxes", replace 
	graph close

** Transfers (this also includes subsidies)
 	graph hbar kk_yp if inlist(instrument,16,17,18,19,20,30,33,34,36,37,38,39), /// 
	over(instrument, sort(kk_yp)) blabel(bar, size($barlblsize) format(%9.1f)) bargap(50) ///
	ytitle("Kakwani Index") title("Progressivity of transfers", size($titlesize)) // title("Progressivity of taxes and transfers", size($titlesize)) //note({break} ///
	graph save "$gdFig\kkw_transfers", replace 
	graph close

  
  
*************************************************************************************************************************************************************************
** 2. Marginal contributions to poverty and inequality: taxes (slide 27)
*************************************************************************************************************************************************************************

** Direct Taxes and Contribution
gen mc_ph_rounded = round(mc_ph, 0.01)
	global barlblsize vsmall
	*MC to Poverty Headcount
	graph hbar mc_ph if inlist(instrument,2,3,8,9,10,12,13,14), ylabel(none) over(instrument, sort(mc_ph)label (labsize(*1.0) labcolor(black))) ///
	blabel(bar, size($barlblsize) format(%9.2f)) bargap(50)  title({bf: Poverty Reduction: Direct Taxes and Contributions }, ///
	color(black) size($titlesize)) ytitle({bf: Marginal contributions (percentage points)}) 
	graph save "$gdFig\dtx_&_con_mc_ph", replace
	graph close
	
	*MC to Inequality
	graph hbar mc_gi if inlist(instrument,2,3,8,9,10,12,13,14), ylabel(none) over(instrument, sort(mc_gi) /// 
	label(labsize(*1.0) labcolor(black))) blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) ///
	title({bf: Inequality Reduction: Direct Taxes and Contributions}, size($titlesize))  ytitle({bf: Marginal contribution (Gini points)}) 
	graph save "$gdFig\dtx_&_con_mc_gi", replace
	graph close
	
	*Combine 
	graph combine "$gdFig\dtx_&_con_mc_ph" "$gdFig\dtx_&_con_mc_gi", ///
	note({break} "Notes:" "[1] $note_mc1" "[2] $note_mc3" "[3] $note_mc2_yd", span size($notesize)) 
	graph save "$gdFig\comb_dtx_&_con_mc_ph_&_gi", replace
	graph close

	
** Direct Transfers

	*MC to Poverty Headcount
	graph hbar mc_ph if inlist(instrument,16,17,18,19), ylabel(none) over(instrument, sort(mc_ph) label(labsize(*1.0) labcolor(black))) ///
	blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) title({bf: Poverty Reduction: Direct Transfers}, size($titlesize)) ///
	ytitle({bf: Marginal contribution (percentage points)})
	graph save "$gdFig\dtr_mc_ph", replace
	graph close
	
	*MC to Inequality
	graph hbar mc_gi if inlist(instrument,16,17,18,19), ylabel(none) over(instrument, sort(mc_gi) label(labsize(*1.0))) ///
	blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) title({bf: Inequality Reduction: Direct Transfers}, size($titlesize)) ///
	ytitle({bf:Marginal contribution (Gini points)})
	graph save "$gdFig\dtr_mc_gi", replace
	graph close
	
	*Combine
	graph combine "$gdFig\dtr_mc_ph" "$gdFig\dtr_mc_gi", note({break} ///
	"Notes:" "[1] $note_mc1" "[2] $note_mc3" "[3] $note_mc2_yd", span size($notesize)) 
	graph save "$gdFig\comb_dtr_mc_ph_&_gi", replace
	graph close
	
** Indirect Taxes

	*MC to Poverty Headcount
	graph hbar mc_ph if inlist(instrument,22,23,24,25,26,27,28), ylabel(none) over(instrument, sort(mc_ph) label(labsize(*1.0) labcolor(black))) ///
	blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) title({bf: Poverty Reduction: Indirect Taxes}, color(black) size($titlesize)) ///
	ytitle({bf:Marginal contribution (percentage points)})
	graph save "$gdFig\itx_mc_ph", replace
	graph close
	
	*MC to Inequality
	graph hbar mc_gi if inlist(instrument,22,23,24,25,26,27,28), ylabel(none) over(instrument, sort(mc_gi) label(labsize(*1.0) labcolor(black))) ///
	blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) title({bf: Inequality Reduction: Indirect Taxes}, color(black) size($titlesize)) ///
	ytitle({bf: Marginal contribution (Gini points)})
	graph save "$gdFig\itx_mc_gi", replace
	graph close


	*Combine
	graph combine "$gdFig\itx_mc_ph" "$gdFig\itx_mc_gi", note({break} ///
	"Notes:" "[1] $note_mc1" "[2] $note_mc3" "[3] $note_mc2_yc", span size($notesize)) 
	graph save "$gdFig\comb_itx_mc_ph_&_gi", replace
	graph close 
	
	
**Inkind Transfers and Fees 
	
	*MC to Inequality
	graph hbar mc_gi if inlist(instrument,33,34,36,37,38,39,41,42), ylabel(none) over(instrument, sort(mc_gi) label(labsize(*1.0))) ///
	blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) title({bf:Inequality Reduction: In-Kind Transfers & User-fees}, size($titlesize)) ///
	ytitle({bf:Marginal contribution (Gini points)}) note({break} ///
	"Notes:" "[1] $note_mc1" "[2] $note_mc3" "[3] $note_mc2_yf", span size($notesize)) 
	graph save "$gdFig\ink_&_fee_mc_gi", replace
	graph close
	
** Subsidies (This does not look good. The fact that the MC's are virtually zero does not help either. Suggestion: Let us combine itx and sub mc's since they both use yc.)
	*MC to Poverty Headcount
	graph hbar mc_ph if inlist(instrument,30), ylabel(none) over(instrument, sort(mc_ph) label(labsize(*0.8))) ///
	blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) title({bf: Poverty Reduction: Indirect Subsidies}, size($titlesize)) ///
	ytitle({bf: Marginal contribution (percentage points)})
	graph save "$gdFig\sub_mc_ph", replace
	graph close

	*MC to Inequality
	graph hbar mc_gi if inlist(instrument,30), ylabel(none) over(instrument, sort(mc_gi) label(labsize(*0.8))) ///
	blabel(bar, size($barlblsize) format(%9.2f))  bargap(50) title({bf: Poverty Reduction: Indirect Subsidies}, size($titlesize)) ///
	ytitle({bf: Marginal contribution (Gini points)})
	graph save "$gdFig\sub_mc_gi", replace
	graph close

*************************************************************************************************************************************************************************
* Fiscal Impoverishment  
*************************************************************************************************************************************************************************

use "$gdOut\fiscimp", clear 
//36.7 and 30.4 

graph bar fi_poor fg_poor if income!=0, over(income) stack title("Fiscal impoverishment / Gains to the Poor", size($titlesize)) yscale(range(-100 100)) ylabel(-100 -50 0 50 100) ///
yline(-100, lcolor(grey)) yline(100, lcolor(grey)) ytitle("Percentage (%) of poor population") blabel(bar, size($barlblsize) format(%9.1f)) ///
 legend(label(1 "Fiscal Impoverishment") label(2 "Fiscal Gains to the Poor") pos(6) row(1)) note({break} ///
	"$source" "Notes:" "[1] $note_fi1" "[2] $note_fi2" "[3] $note_fi3" "[4] $note_fi4" "[5] $note_fi5" "[6] $note_fi6", span size($notesize)) 
 graph save "$gdFig\FIFGP_poor", replace
 graph close

graph bar fi_pop fg_pop if income!=0, over(income) stack title("Fiscal impoverishment / Gains to the Poor", size($titlesize)) yscale(range(-50 50)) ylabel(-50 0 50) ///
yline(-36.7, lcolor(grey)) yline(-30.4, lcolor(blue)) yline(36.7, lcolor(grey)) yline(30.4, lcolor(blue)) ytitle("Percentage (%) of total population") blabel(bar, size($barlblsize) format(%9.1f)) ///
legend(label(1 "Fiscal Impoverishment") label(2 "Fiscal Gains to the Poor") pos(6) row(1)) note({break} ///
	"$source" "Notes:" "[1] $note_fi1" "[2] $note_fi2" "[3] $note_fi3" "[4] $note_fi4" "[5] $note_fi5" "[6] $note_fi7" "[7] Blue and black lines represents pre- and post-fiscal poor populations respectively.", span size($notesize))
graph save "$gdFig\FIFGP_pop", replace
graph close


*************************************************************************************************************************************************************************
* Net cash beneficiaries 
*************************************************************************************************************************************************************************
** Figure 4: Taxes and transfers as a share of pre fiscal income (slide 22)

	global decile dec_yd
	lab def decile_lbl 1"Poorest" 10"Richest", replace 
	
	
	use "$gdOut\inci_conc_yd.dta", clear 
	ren inc_yd_* inc_*
	lab val $decile decile_lbl

	lab var inc_edu_pc "Education"
	*lab var inc_sub_pc "Indirect subsidies"

	local y yd
	gen inc_itx_dtx = inc_itx_pc + inc_dtx_pc
	gen inc_itx_dtx_con = inc_itx_dtx + inc_con_pc
	gen inc_itx_dtx_con_hfee = inc_itx_dtx_con + inc_fee_hlth_pc
	gen inc_itx_dtx_con_hfee_efee = inc_itx_dtx_con_hfee + inc_fee_educ_pc
	gen inc_hlt_edu = inc_hlt_pc + inc_edu_pc      //hlt + edu 
	gen inc_hlt_edu_dtr = inc_hlt_edu + inc_dtr_pc  //hlt + edu + dtr 
	gen inc_hlt_edu_dtr_sub = inc_hlt_edu_dtr + inc_sub_pc   //hlt + edu + dtr 

	listsome inc_itx_dtx_con_hfee inc_fee_hlth_pc inc_fee_educ_pc inc_itx_dtx_con_hfee_efee

	lab var inc_itx_pc "Indirect taxes"
	lab var inc_itx_dtx "Direct taxes"
	lab var inc_itx_dtx_con "Contributions"
	lab var inc_itx_dtx_con_hfee "Hlth userfees"
	lab var inc_itx_dtx_con_hfee_efee "Educ userfees"
	lab var inc_hlt_pc "Health"
	lab var inc_hlt_edu "Education"
	lab var inc_hlt_edu_dtr "Direct transfers"
	lab var inc_hlt_edu_dtr_sub "Indirect subsidies"
	
	lab var inc_net_totl_pc "Net total benefit"
	lab var inc_net_cash_pc "Net cash benefit"



	global barw 0.5
	twoway bar inc_itx_dtx_con_hfee_efee dec_yd, barw($barw) ///
	|| bar inc_itx_dtx_con_hfee dec_yd, barw($barw)  ///
	|| bar inc_itx_dtx_con dec_yd, barw($barw)  ///
	|| bar inc_itx_dtx dec_yd, barw($barw)  ///
	|| bar inc_itx_pc dec_yd, barw($barw)  ///
	|| bar inc_hlt_edu_dtr_sub dec_yd, barw($barw)  ///
	|| bar inc_hlt_edu_dtr dec_yd, barw($barw)  ///
	|| bar inc_hlt_edu dec_yd, barw($barw)  ///
	|| bar inc_hlt_pc dec_yd, barw($barw) ///
	|| connected inc_net_totl_pc $decile ///
	|| connected inc_net_cash_pc $decile ///
	, ytitle("Percent of disposable income") xtitle("Decile of disposable income") title("Net cash beneficiary", size($titlesize)) yscale(range(-30 30)) yline(0, lstyle(foreground)) note({break} ///
	"Notes:" "[1] $note_netben1" "[2] $note_netben2", span size($notesize))
	graph save "$gdFig\netcashben_line", replace 
	graph close

** Figure 4: Taxes and transfers as a share of pre fiscal income (slide 22)
	//without a line - for comparison 

	local y yd
	graph bar inc_dtx_pc inc_con_pc inc_itx_pc inc_dtr_pc inc_hlt_pc inc_edu_pc inc_fee_hlth_pc inc_fee_educ_pc, ///
	title("Net cash beneficiary") over(dec_`y') stack asyvars legend(label(1 "Direct taxes") label(2 "Contributions") label(3 "Indirect taxes") label(4 "Direct transfers") label(5 "Indirect subsidies") ///
	label(6 "Health") label(7 "Education") label(8 "Hlth userfees") label(9 "Educ. userfees") pos(3)) ytitle("Incidence (share of Disposable income)", size($titlesize)) 
	graph save "$gdFig\netcashben_noline", replace 
	graph close
*/	   

*****************************************************************************************************************************************************************
* Detailed incidence graphs
*************************************************************************************************************************************************************************
/** Direct Taxes and Contributions // NB: does not run because variable "inc_dtx_stax_pc" not found
	graph bar inc_dtx_pitx_pc inc_dtx_pyrl_pc inc_dtx_prop_pc inc_dtx_stax_pc inc_dtx_natn_pc ///
	graph bar inc_dtx_pitx_pc inc_dtx_pyrl_pc inc_dtx_prop_pc inc_dtx_natn_pc ///
	inc_con_hins_pc inc_con_fama_pc inc_con_indu_pc, ///
	title({bf: Incidence: Direct Taxes & Contributions}, size($titlesize)) over(dec_yd) stack asyvars ///
	legend(label(1 "PIT") label(2 "Payroll") label(3 "Property") label(4 "Tax on salaries") ///
	label(5 "Nat. cont.") label(6 "NHI cont.") label (7 "Family Allowance Fund cont.") label (8 "Industrial Accident Fund cont.") ///
	pos(3)) b1title({bf:Decile of Disposible Income},  size($titlesize)) ytitle({bf: Incidence (% of Disposable income)}, size($titlesize)) 
	//note({break} "Notes:" "[1] $note_inc1" "[2] $note_yd", span size($notesize)) 
	graph save "$gdFig\inc_dtx_&_con", replace 
	graph close
*/
		
** Direct Transfers
	graph bar inc_dtr_pssn_pc inc_dtr_schl_pc inc_dtr_fama_pc inc_dtr_indu_pc, ///
	title({bf: Incidence: Direct Transfers}, size($titlesize)) over(dec_yd) stack asyvars ///
	legend(label(1 "Cash transfers (PSSN)") label(2 "Scholarships") label(3 "Family allowance ben.")  label(4 "Industrial accident ben.") ///
	pos(3)) b1title({bf: Decile of Disposible Income},  size($titlesize)) ytitle({bf: Incidence (% of Disposable income)}, size($titlesize)) 
	//note({break} "Notes:" "[1] $note_inc1" "[2] $note_yd", span size($notesize)) 
	graph save "$gdFig\inc_dtr", replace 
	graph close

/** Indirect Taxes // NB: does not run because variable "inc_itx_fuel_totl_pc" not found
	graph bar inc_itx_vatx_pc inc_itx_excs_pc inc_itx_fuel_totl_pc inc_itx_cust_pc inc_itx_moto_pc inc_itx_elec_pc inc_itx_wsub_pc, ///
	graph bar inc_itx_vatx_pc inc_itx_excs_pc inc_itx_cust_pc inc_itx_moto_pc inc_itx_elec_pc inc_itx_wsub_pc, ///
	title({bf: Incidence: Indirect Taxes}, size($titlesize)) over(dec_yd) stack asyvars ///
	legend(label(1 "VAT") label(2 "Excise") label(3 "Fuel taxes") label(4 "Customs") label(5 "MVR") label(6 "Elec. tax") label(7 "Water infra. tax") ///
	pos(3)) b1title({bf: Decile of Disposible Income},  size($titlesize)) ytitle({bf: Incidence (% of Disposable income)}, size($titlesize))
	//note({break} "Notes:" "[1] $note_inc1" "[2] $note_yd", span size($notesize))
	graph save "$gdFig\inc_itx", replace 
	graph close
*/

//MG: please split into direct and indirect effects where these exist  
	
** Subsidies
	graph bar inc_sub_watr_pc, over(dec_yd) title({bf: Incidence: Water Tariff Subsidy}, size($titlesize)) ///
	b1title({bf: Decile of Disposible Income},  size($titlesize)) ytitle({bf: Incidence (% of Disposable income)}, size($titlesize)) ///
	//note({break} "Notes:" "[1] $note_inc1" "[2] $note_yd", span size($notesize))
	graph save "$gdFig\inc_sub", replace 
	graph close


	br inc_itx_pc
	
** In-kind transfers and user-fees (All in one)
	graph bar inc_edu_prim_pc inc_edu_seco_pc inc_edu_tert_pc inc_hlt_prim_pc inc_hlt_hosp_pc inc_oth_econ_pc inc_fee_educ_pc inc_fee_hlth_pc, ///
	title({bf: Incidence: In-Kind Transfers & User-fees}, size($titlesize)) over(dec_yd) stack asyvars ///
	legend(label(1 "Primary educ.") label(2 "Secondary educ.") label(3 "Tertiary educ.") label(4 "Primary healthc.") label(5 "Hospital healthc.") label(6 "PSSN economic inclusion") ///
	label(7 "Health fees") label(8 "Educ. fees") pos(3)) b1title({bf: Decile of Disposible Income},  size($titlesize))  ytitle({bf: Incidence (% of Disposable income)}, size($titlesize)) yline(0, lstyle(foreground)) 
	//note({break} "Notes:" "[1] $note_inc1" "[2] $note_inc2" "[3] $note_yd", span size($notesize))
	graph save "$gdFig\inc_ink_&_fee", replace
	graph close
	
**************************************************************************************************************************************************************************************************************************************************************************************	
* New concentration graphs format 
**************************************************************************************************************************************************************************************************************************************************************************************
use "$gdOut\inci_conc_yd.dta", clear
global barw2 0.8
global barw3 0.4
gen area = dec_yd - 0.4

*Direct Taxes + Contributions concentration graphs
	twoway bar conc_dtx_pc area, barw($barw3) || bar conc_dtr_pc dec_yd, barw($barw3) ///
	|| connected conc_yp_pc dec_yd, name(concsh`x', replace) lpattern(dash) /// 
	legend(label (1 "Direct Taxes") label (2 "Contributions") label (3 "Pre-fiscal income") pos(6) row(1)) ///
	title({bf:Concentration Shares: Direct Taxes & Contributions}, size($titlesize)) ytit({bf: Concentration Shares (%)}) /// 
	xlabel(1(1)10) xtit({bf: Decile of Disposible Income}) ///
	yline(0, lstyle(foreground)) 
	graph save "$gdFig\/cs_dtx_&_con.gph", replace  
	graph close
		
*In-Kind Transfers and User-fees
	twoway bar conc_ink_pc area, barw($barw3) || bar conc_fee_pc dec_yd, barw($barw3) ///
	|| connected conc_yp_pc dec_yd, name(concsh`x', replace) lpattern(dash) /// 
	legend(label (1 "In-Kind Transfers") label (2 "User-Fees") label (3 "Pre-fiscal income") pos(6) row(1)) ///
	title({bf: Concentration Shares: In-Kind Transfers & User-fees}, size($titlesize)) ytit({bf: Concentration Shares (%)}) xlabel(1(1)10) ///
	xtit({bf: Decile of Disposible Income}) yline(0, lstyle(foreground)) 
	graph save "$gdFig\/cs_ink_&_fee.gph", replace  
	graph close
	
*Indirect Taxes 
	twoway bar conc_itx_pc dec_yd, barw($barw3) ///
	|| connected conc_yp_pc dec_yd, lpattern(dash) /// 
	legend(label (1 "Indirect Taxes") label (2 "Pre-fiscal income") pos(6) row(1)) ///
	title({bf: Concentration Shares: Indirect Taxes}, size($titlesize)) ytit({bf: Concentration Shares (%)}) xlabel(1(1)10) ///
	xtit({bf: Decile of Disposible Income}) yline(0, lstyle(foreground)) 
	graph save "$gdFig\/cs_itx.gph", replace  
	graph close

*Direct Transfer
	twoway bar conc_dtr_pc dec_yd, barw($barw3) ///
	|| connected conc_yp_pc dec_yd, lpattern(dash) /// 
	legend(label (1 "Direct Transfers") label (2 "Pre-fiscal income") pos(6) row(1)) ///
	title({bf: Concentration Shares: Direct Transfers}, size($titlesize)) ytit({bf: Concentration Shares (%)}) xlabel(1(1)10) /// 
	xtit({bf: Decile of Disposible Income}) yline(0, lstyle(foreground)) 
	graph save "$gdFig\/cs_dtr.gph", replace  
	graph close

*Subsidies 
	twoway bar conc_sub_pc dec_yd, barw($barw3) ///
	|| connected conc_yp_pc dec_yd, lpattern(dash) /// 
	legend(label (1 "Indirect Subsidies") label (2 "Pre-fiscal income") pos(6) row(1)) ///
	title({bf: Concentration Shares: Indirect Subsidies}, size($titlesize)) ytit({bf: Concentration Shares (%)}) xlabel(1(1)10) ///
	xtit({bf: Decile of Disposible Income}) yline(0, lstyle(foreground)) 
	graph save "$gdFig\/cs_sub.gph", replace  
	graph close
	
*****************************************************************************************************************************************************************
* Combining Incidence and Concentration graphs
*************************************************************************************************************************************************************************

/** Direct taxes and Contributions
	graph combine "$gdFig\inc_dtx_&_con" "$gdFig\cs_dtx_&_con.gph", ///
	note({break} "Notes:" "[1] $note_inc1" "[2] $note_cc1" "[3] $note_yd", span size($notesize))
	graph save "$gdFig\comb_dtx_&_con_inc_conc", replace
	graph close
*/	

** Direct Transfers
	graph combine "$gdFig\inc_dtr.gph" "$gdFig\cs_dtr.gph", ///
	note({break} "Notes:" "[1] $note_inc1" "[2] $note_cc1" "[3] $note_yd", span size($notesize))
	graph save "$gdFig\comb_dtr_inc_conc", replace
	graph close

/** Indirect Taxes
	graph combine "$gdFig\inc_itx" "$gdFig\cs_itx.gph"
	graph save "$gdFig\comb_itx_inc_conc", replace
	graph close
*/

** Subdies: Simple bar graph
	graph combine "$gdFig\inc_sub" "$gdFig\cs_sub"
	graph save "$gdFig\comb_sub_inc_conc", replace
	graph close

**In-Kind Transfers and Fees
	graph combine "$gdFig\inc_ink_&_fee.gph" "$gdFig\cs_ink_&_fee.gph"
	graph save "$gdFig\ink_&_feeinc_conc_comb", replace
	graph close

	

*****************************************************************************************************************************************************************
/* Comparison graphs 
*****************************************************************************************************************************************************************
	use "${raw}../SI_10May2022_pov_inq.dta", clear
	g africa = .
	replace africa = 1 in 6
	replace africa = 1 in 9
	replace africa = 1 in 11
	replace africa = 1 in 15
	replace africa = 1 in 18
	replace africa = 1 in 21
	replace africa = 1 in 26
	replace africa = 1 in 27
	replace africa = 1 in 35
	replace africa = 1 in 36
	replace africa = 1 in 40
	replace africa = 1 in 41
	replace africa = 1 in 50
	replace africa = 1 in 51
	replace africa = 1 in 55
	replace africa = 1 in 56
	replace africa = 1 in 57
	replace africa = 1 in 59
	replace africa = 1 in 60
	replace africa = 1 in 66
	replace africa = 1 in 67
	replace africa = 1 in 68


	lab var logofgdppercapitax "Log of GDP per capita (2017 constant $US)"
	lab var povertyreductiony "Poverty headcount reduction (percentage points)"
	replace redistributiveeffecty = 4.329482 if countryyear == "Côte d'Ivoire (2018)"
	replace povertyreductiony = -3.24149 if countryyear == "Côte d'Ivoire (2018)"
	replace logofgdppercapitax = 3.68 in 68 //Source: https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD?locations=CI
	g waemu = inlist(country,"Benin", "Côte d'Ivoire", "Togo")

	drop if inlist(country,"United States","South Africa","Spain")
	drop if inlist(countryyear,"Uganda (2012)", "Peru (2009", "Namibia (2010)", "Mexico (2010)", "Mexico (2012)")
	drop if inlist(countryyear,"Guatemala (2011)", "El Salvador (2011)", "El Salvador (2013)", "El Salvador (2015)","Colombia (2010)", "Bolivia (2009)", "Argentina (2012)")

	graph bar povertyreductiony if africa == 1, over(country, sort(povertyreductiony) label(angle(45))) title("Poverty headcount reduction", size(small)) ///
		ytitle("Percentage points") blabel(bar, size($barlblsize)) 
			//I can't get the labels to show properly.. 

	graph twoway ///
	(scatter povertyreductiony logofgdppercapitax if incomecategory == "Low income", mlabel(country) mcolor(green)) ///
	(scatter povertyreductiony logofgdppercapitax if incomecategory == "Lower middle income", mlabel(country) mcolor(red)) ///
	(scatter povertyreductiony logofgdppercapitax if incomecategory == "Upper middle income", mlabel(country) mcolor(blue)) ///
	(scatter povertyreductiony logofgdppercapitax if incomecategory == "High income", mlabel(country) mcolor(lightblue)), ///
	legend(label(1 "LICs") label(2 "LMICs") label(3 "UMICs") label(4 "HICs") pos(6) row(1)) ytitle("Poverty headcount reduction at $3.20 line (percentage points)")
	graph save "$gdFig\comp_all_pov", replace 
	graph close

	graph twoway ///
	(scatter redistributiveeffecty logofgdppercapitax if incomecategory == "Low income", mlabel(country) mcolor(green)) ///
	(scatter redistributiveeffecty logofgdppercapitax if incomecategory == "Lower middle income", mlabel(country) mcolor(red)) ///
	(scatter redistributiveeffecty logofgdppercapitax if incomecategory == "Upper middle income", mlabel(country) mcolor(blue)) ///
	(scatter redistributiveeffecty logofgdppercapitax if incomecategory == "High income", mlabel(country) mcolor(lightblue)), ///
	legend(label(1 "LICs") label(2 "LMICs") label(3 "UMICs") label(4 "HICs") pos(6) row(1)) 
	graph save "$gdFig\comp_all_inq", replace 
	graph close

	//Venezuela - GDP is missing. 
	// Cote d'Ivoire (2015) - do I need to include it? Might just leave it out.. 

*/   
*****************************************************************************************************************************************************************
* End
*****************************************************************************************************************************************************************

