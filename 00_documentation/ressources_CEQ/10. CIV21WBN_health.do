* Cote d'Ivoire 2021
* Healthcare
* 26 Aug 2023
* Ian Houts

*Section 3 of survey data
clear all
set more off
set type double


*Step 1: set simulation parameters

		global primhlthexp = 166900000000 		//Total operational expenditure in public healthcare for primary care facilities (CFCA)
		global hosphlthexp =  52700000000		//Total operational expenditure in public healthcare for hospitals (CFCA)
		global othrhlthexp = 245800000000		//Total operational expenditure in public healthcare not otherwise defined (CFCA)
		
		global hospvisits =    864691 			//Total annual inpatient visits to public hospitals (individual visits)
		global primvisits =  42067028			//Total annual outpatient visits to public primary care facilities (individual visits)
		global totvisits = $hospvisits + $primvisits


use "$gdOut\health_use_base.dta", clear

* Step 2: calculate the subsidy amounts 				
		// Using budgetary information (CCM 2021) to determine total inpatient (hospital) and outpatient(primary) care. No scaling; we allocate the entirety of the budget, and will add general administrative costs as an average as well. 
		loc svy_hospexp =  $primhlthexp
		loc svy_primexp =  $hosphlthexp
		loc svy_othrexp =  $othrhlthexp


		
/*	//Use healthcare data on visits from administrative accounts to calculate benefit for each institution type. (We decided against using this method, as the results did not fit a consistent pattern with other comparable countries in terms of averages per capita, i.e. the subsidies for hospital care were smaller than the primary care subsidies on average, which is the opposite of what we would expect.)
		loc hospvisits =  792995
		loc primvisits =  2004190 

		loc hospben = `svy_hospexp'/`hospvisits'
		loc primben = `svy_primexp'/`primvisits'			

		disp `hospben'   //    per visit
		disp `primben'  //     per visit
*/
		
	//Use visits from survey responses to calculate alternative benefit for each institution type
		loc hospvisits = $hospvisits
		loc primvisits = $primvisits
		loc totvisits =  $totvisits
		
		loc hospben = `svy_hospexp'/`hospvisits'	//60,946.6
		loc primben = `svy_primexp'/`primvisits'	// 3,967.5
		

* Step 3: allocate the average subsidy amounts to individuals per visit
 
		*g hlt_hosp_in = `hospben' if hlt_hosp_ri==1							// subsidy per patient
		g hlt_hosp_in = `hospben' * hlt_hosp_visits if hlt_hosp_ri==1			// subsidy per visit
		
		*g hlt_prim_in = `primben' if hlt_prim_ri==1			 
		g hlt_prim_in = `primben' * hlt_prim_visits if hlt_prim_ri==1
		
		
*Now create benefit shares and allocate the other administrative expenditure
		egen hbentot = rowtotal(hlt_hosp_in hlt_prim_in)
		qui sum hbentot [w=hhweight]
		loc hbentot = r(sum)
		
		gen hben_sh = (hbentot*hhweight)/ `hbentot'			//total healthcare benefit share
		gen hlt_othr_in = (`svy_othrexp' * hben_sh) /hhweight
		
*visits by decile for user fee averaging
		foreach dec of numlist 1/10 {
			qui sum hlt_hosp_visits [w=hhweight] if dec_yd_pc==`dec'
			loc hospvisits_svy_`dec' = r(sum)
			qui sum hlt_prim_visits [w=hhweight] if dec_yd_pc==`dec'
			loc primvisits_svy_`dec' = r(sum)
		}
		
* Step 4: Userfees *******		

	foreach dec of numlist 1/10{	
		qui sum fee_hosp_in_yr [w=hhweight] if dec_yd_pc==`dec'
		loc hosp_fees_`dec' = r(sum)
		g fee_hosp_`dec' = `hosp_fees_`dec'' / `hospvisits_svy_`dec'' if dec_yd_pc==`dec'	//Average fee for inpatient care
		replace fee_hosp_`dec' = fee_hosp_`dec' *hlt_hosp_visits if hlt_hosp_ri==1 & hlt_hosp_ri!=. & dec_yd_pc==`dec'
		replace fee_hosp_`dec' =0 if hlt_hosp_ri <=0 //| fee_hosp_in_yr<=0
		}
		egen fee_hosp_in = rowtotal(fee_hosp_1-fee_hosp_10)
		drop fee_hosp_1-fee_hosp_10

	foreach dec of numlist 1/10{
		qui sum fee_phlt_in_yr [w=hhweight] if dec_yd_pc==`dec'
		loc prim_fees_`dec' = r(sum)
		g fee_phlt_`dec' = `prim_fees_`dec'' / `primvisits_svy_`dec''	if dec_yd_pc==`dec'			//Average fee for outpatient care
		replace fee_phlt_`dec' = fee_phlt_`dec' *hlt_prim_visits if hlt_prim_ri==1 & hlt_prim_ri !=. & dec_yd_pc==`dec'
		replace fee_phlt_`dec' =0 if hlt_prim_ri <=0 // | fee_phlt_in_yr<=0
		}
		egen fee_phlt_in = rowtotal(fee_phlt_1-fee_phlt_10)
		drop fee_phlt_1-fee_phlt_10		
		
		
		/*Because we impute average benefits (not the individual benefit), 
		    average copayments and user-fees should be subtracted (not the individual fees or copayment). 
		    If not, we will find negative numbers.*/
			
		g hlt_prim_net_in = hlt_prim_in - fee_phlt_in
		g hlt_hosp_net_in = hlt_hosp_in - fee_hosp_in

		
* Step 5: Collapse, change to 0 if negative (we don't want to tax people)   
		collapse (sum) hlt_hosp_in hlt_hosp_net_in hlt_prim_in hlt_othr_in hlt_prim_net_in fee_hosp_in fee_phlt_in (max) hlt_prim_ri hlt_hosp_ri, by(hhid hhweight dec_yd_pc)
		ren *ri *rh 
		ren *in *hh
		ren hhweight weight
		
*Now reabsorb the "other" expenditure into the household share of hospital and primary benefit.
egen hlt_total_hh = rowtotal(hlt_hosp_hh hlt_prim_hh)
g hh_hosp_sh = hlt_hosp_hh/hlt_total_hh
g hh_prim_sh = 1- hh_hosp_sh
replace hlt_hosp_hh = hlt_hosp_hh + (hlt_othr_hh* hh_hosp_sh )
replace hlt_prim_hh = hlt_prim_hh + (hlt_othr_hh* hh_prim_sh )
		
		egen fee_hlth_hh = rowtotal(fee_hosp_hh fee_phlt_hh)
		egen hlt_hh = rowtotal(hlt_prim_hh hlt_hosp_hh)
		egen hlt_net_hh = rowtotal(hlt_prim_net_hh hlt_hosp_net_hh)

		lab var hlt_prim_hh "In-kind subsidy: primary healthcare"
		lab var hlt_hosp_hh "In-kind subsidy: hospital healthcare"
		lab var hlt_prim_net_hh "In-kind subsidy: primary healthcare (net of userfees)"
		lab var hlt_hosp_net_hh "In-kind subsidy: hospital healthcare (net of userfees)"
		lab var hlt_hh 			"In-kind subsidy: healthcare"
		lab var hlt_net_hh 		"In-kind subsidy: healthcare (net of userfees)"
		lab var fee_hosp_hh "User fees: hospital healthcare"
		lab var fee_phlt_hh "User fees: primary healthcare"
		lab var fee_hlth_hh  "User fees: healthcare"
		
	
save "$gdTemp\health_use_final.dta", replace

