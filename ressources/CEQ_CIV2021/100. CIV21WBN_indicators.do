	**************************************************************************************************************************************************************
	* Cote d'Ivoire 
	* Code to produce results for Powerpoint and report 
	* Ntuthuko Hlela, Maya Goldman, Ian Houts
	* 28 October 2022 

	/*Fuel taxes eliminated

	Payroll Tax: 11.5% on salaries of expatriate staff; 1.5% national contribution for all staff; 0.5% apprenticeship tax on all staff; 1.5% professional training tax for all staff

	*/

	use "$gdOut\CIV21WBN_ceqincome.dta", clear 
	drop *_hh

	***************************************************************************************************************************************************************
	** 0. Preparation
	***************************************************************************************************************************************************************



	* Calculate population
	***************************************************************************************************************************************************************
		qui sum pcweight  
		global pop_mil = r(sum)/1e6  
			//25.5 mil vs. 27.05 mil - looks good

	* Calculate totals for each category of instrument, and generate the net benefit variables 
		egen dtr_pc = rowtotal(dtr_pssn_pc dtr_schl_pc dtr_fama_pc dtr_indu_pc hlt_insu_pc)
		egen dtx_pc = rowtotal(dtx_pitx_pc dtx_pyrl_pc dtx_prop_pc dtx_natn_pc)
		egen con_pc = rowtotal(con_hins_pc con_fama_pc con_indu_pc)
		egen sub_pc = rowtotal(sub_watr_pc sub_elec_pc sub_fuel_pc)
		egen itx_pc = rowtotal(itx_vatx_pc itx_excs_pc itx_cust_pc itx_moto_pc itx_elec_pc itx_wsub_pc)		//itx_fuel_totl_pc
		egen fee_pc = rowtotal(fee_educ_pc fee_hlth_pc)
		egen hlt_pc = rowtotal(hlt_prim_pc hlt_hosp_pc hlt_insu_pc)
		egen edu_pc = rowtotal(edu_prim_pc edu_seco_pc edu_tert_pc oth_econ_pc)
		egen ink_pc = rowtotal(hlt_pc edu_pc)  

	* Set locals 
		loc inclist yp_pc yn_pc yd_pc yc_pc yf_pc 
		loc sublist 	sub_pc sub_watr_pc sub_fuel_pc
		loc itxlist 	itx_pc itx_vatx_pc itx_excs_pc itx_cust_pc itx_moto_pc itx_elec_pc itx_wsub_pc
		loc dtxlist 	dtx_pc dtx_pitx_pc dtx_pyrl_pc dtx_igrx_pc dtx_ibic_pc dtx_rent_pc dtx_capt_pc dtx_prop_pc dtx_natn_pc 
		loc conlist 	con_pc con_hins_pc con_fama_pc con_indu_pc 
		loc feelist 	fee_pc fee_hlth_pc fee_educ_pc		
		loc dtrlist dtr_pc dtr_pssn_pc dtr_schl_pc dtr_fama_pc dtr_indu_pc hlt_insu_pc
		loc inklist ink_pc hlt_pc hlt_prim_pc hlt_hosp_pc edu_pc edu_prim_pc edu_seco_pc edu_tert_pc oth_econ_pc
		loc paylist `itxlist' `dtxlist' `conlist' `feelist'
		loc benlist `dtrlist'  `sublist' `inklist'		
		loc ydlist `dtxlist' `conlist' `dtrlist'   //all variables included in consumable income 
		loc noydlist `itxlist' `sublist' `inklist' `feelist'													 //all variables NOT included in consumable income								 //all variables NOT included in consumable income

		loc yclist `dtxlist' `conlist' `dtrlist' `itxlist' `sublist'  //all variables included in consumable income 
		loc noyclist `inklist' `feelist'

		loc yflist `dtxlist' `conlist' `dtrlist' `itxlist' `sublist' `inklist' `feelist' //all variables included in consumable income 

														 //all variables NOT included in consumable income
		loc fisclist `dtxlist' `conlist' `dtrlist' `itxlist' `sublist' `inklist' `feelist'
		loc othrlist itx_exca_pc itx_exct_pc itx_exco_pc


		* Label variables 
		globalvarlabels  //run the program to define globals with variable lables for the graphs 
		foreach var of local fisclist{
			disp "$`var'"
			lab var `var' "$`var'"
		}

	* Generate the deciles 
		quantiles yp_pc [fw=int(pcweight)], nq(10) gencatvar(dec_yp)  //Creating the decile variable: Note yp_pc is the pre-fiscal income
		quantiles yd_pc [fw=int(pcweight)], nq(10) gencatvar(dec_yd)  //Creating the decile variable: Note yd_pc is the disposable income

	* Replace all the tax variables with negatives
		
		foreach t of local paylist{
			replace `t' = -`t' 
		}
		assert itx_pc <= 0 // & dtx_pc <= 0 & con_pc <= 0 & fee_pc <= 0
		
		egen net_cash_pc = rowtotal(dtx_pc con_pc itx_pc sub_pc dtr_pc)  
		egen net_totl_pc = rowtotal(net_cash_pc ink_pc) 
		loc netlist net_cash_pc net_totl_pc
		loc fiscinclist `fisclist' `inclist' `netlist' `othrlist'

	* Calculate baseline poverty and inequality for all income concepts 
		foreach i in `inclist'{ 
			qui ineqdeco `i' [w=pcweight]                        // creating base inequality
			gen gi_`i' = r(gini)*100

			qui povdeco `i' [w=pcweight], varpl(pl_nat)   // used different weights than you used. I could not find popweights. Also, I used national poverty lines, is this correct. - correct. popweights = pcweights. same thing. 
			g ph_`i' = r(fgt0)*100
			g pg_`i' = r(fgt1)*100
		}
		
		tempfile prep 
		save `prep'  
			//MG: I am saving the dataset here as a temporary file so that I don't need to create the deciles again down-below. 
				//We should always avoid doing the same thing twice as that is where errors can creep in if we come and edit the code later and we edit the code up-top but not down below - make sense? 	

	***************************************************************************************************************************************************************
	* Outputs
	***************************************************************************************************************************************************************
			* 1. Gini and Poverty 
			***************************************************************************************************************************************************************
				drop gi_* ph_* pg_* 

			// 1a) PDI
				
				ren (yp_pc yn_pc yd_pc yc_pc yf_pc) (pdi_1 pdi_2 pdi_3 pdi_4 pdi_5) 
				foreach i of numlist 1/5 {     
					qui ineqdeco pdi_`i' [w=pcweight]                                  //Calculating inequality
					gen gi_pdis_`i' = r(gini)*100                             // Generating inequality/Gini
				
					qui povdeco pdi_`i' [w=pcweight], varpl(pl_nat)                // Calculating poverty based on the national poverty line
					gen ph_natl_pdis_`i' = r(fgt0)*100                              // generating the headcount ratio
					gen pg_natl_pdis_`i' = r(fgt1)*100                              // generating the average normalised poverty gap 
				
					qui povdeco pdi_`i' [w=pcweight], varpl(pl_365)                // Calculating poverty based on the international poverty line
					gen ph_intl_pdis_`i' = r(fgt0)*100                              
					gen pg_intl_pdis_`i' = r(fgt1)*100
				} 

			// 1b) PGT
				
				*rename (ym_pc yk_pc pdi_3 pdi_4 pdi_5) (pgt_1 pgt_2 pgt_3 pgt_4 pgt_5)
				rename (yl_pc pdi_2 pdi_3 pdi_4 pdi_5) (pgt_1 pgt_2 pgt_3 pgt_4 pgt_5)	// (CIV does not have publically-subsidized contributory pensions, so yp and yl are equal)
				foreach i of numlist 1/5 {                     // (m= market income; k= net income; d = disposable income; c = consumable income; f = final income) 
					qui ineqdeco pgt_`i'[w=pcweight]                              // Calculating inequality  
					gen gi_pgts_`i' = r(gini)*100
				
				
					qui povdeco pgt_`i' [w=pcweight], varpl(pl_nat)              // Calculating poverty based on the national poverty line
					gen ph_natl_pgts_`i' = r(fgt0)*100                            // generating the headcount ratio
					gen pg_natl_pgts_`i' = r(fgt1)*100                            // generating the average normalised poverty gap
				}


			// 1c) Total impact 
				
				foreach sc in pdis pgts{
					g gi_`sc'_6 = gi_`sc'_1 - gi_`sc'_5	
				}

				foreach sc in natl_pdis intl_pdis natl_pgts{
					g ph_`sc'_6 = ph_`sc'_1 - ph_`sc'_4
					g pg_`sc'_6 = pg_`sc'_1 - pg_`sc'_4
				}

				collapse (mean) gi_* ph_* pg_*

				g id = _n 
				reshape long gi_pdis_ gi_pgts_ ph_natl_pdis_ pg_natl_pdis_ ph_intl_pdis_ pg_intl_pdis_ ph_natl_pgts_ pg_natl_pgts_ , i(id) j(y)
				ren (*_) (*)

				lab def y_lvl 1 "Pre-fiscal" 2 "Net market" 3 "Disposable" 4 "Consumable" 5 "Final" 6 "Total"
				lab val y y_lvl
				global y "Income type" 
				global gi_pdis "Gini (PDI)"
				global gi_pgts "Gini (PGT)"
				global ph_natl_pdis "Nat. pov. headc. (PDI)"
				global ph_intl_pdis "$3.65 pov. headc. (PDI)"
				global pg_natl_pdis "Nat. pov. gap (PDI)"
				global pg_intl_pdis "$3.65 pov. gap (PDI)"
				global ph_natl_pgts "Nat. pov. headc. (PGT)"
				global pg_natl_pgts "Nat. pov. gap (PGT)"


				foreach i of varlist gi* ph* pg*{
					g `i'_ch = `i'[_n-1] - `i'[_n]
					replace `i'_ch = `i' if inlist(y,1,6)
					*replace `i' = round(`i',.1)
					*replace `i'_ch = round(`i'_ch,.1)
				}

				global gi_pdis_ch "Gini (PDI): change"
				global gi_pgts_ch "Gini (PGT): change"
				global ph_natl_pdis_ch "Nat. pov. headc. (PDI): change"
				global ph_intl_pdis_ch "$3.65 pov. headc. (PDI): change"
				global pg_natl_pdis_ch "Nat. pov. gap (PDI): change"
				global pg_intl_pdis_ch "$3.65 pov. gap (PDI): change"
				global ph_natl_pgts_ch "Nat. pov. headc. (PGT): change"
				global pg_natl_pgts_ch "Nat. pov. gap (PGT): change"


				foreach i in ph_natl_pdis ph_intl_pdis ph_natl_pgts {
					g `i'_pop = `i'*($pop_mil/100)
				} 

				global ph_natl_pdis_pop "Nat. pov. headc. (PDI): pop (mil)"
				global ph_intl_pdis_pop "$3.65 pov. headc. (PDI): pop (mil)"
				global ph_natl_pgts_pop "Nat. pov. headc. (PGT): pop (mil)"

				export excel using "$gdOut\results_${date}.xlsx", sheet("gini_pov") firstrow(varlabel) sheetmodify
				save "$gdOut\gini_pov.dta", replace
				*use "$gdOut\gini_pov.dta", clear
				

	*************************************************************************************************************************************************************************
	** 2. Fiscal Impoverishment / Fiscal Gains to the Poor 
	*************************************************************************************************************************************************************************
			/* 
			a. Fiscal impoverishment: An individual who is poor at post-fiscal income is made poorer by the fiscal system or when an individual who is not poor at pre-fiscal income is 
				made poor at consumable income by the fiscal system. 
			b. Fiscal gains to the poor: An individual who is poor at pre-fiscal income experiences gains in income due to the fiscal system. 

			*/
		* BA: This sub-section was put as a comment (I guess because in CIV there is no PGT version) //*
			use `prep', clear 

			* PGT
					* BA: Remember that (CIV does not have publically-subsidized contributory pensions, so yp and yl are equal)
					gen ym_pc = yp_pc	
					gen yk_pc = yn_pc	
				
				g poor_0 = (ym_pc < pl_nat)
				g poor_1 = (yk_pc < pl_nat) 
				g poor_2 = (yd_pc < pl_nat) 
				g poor_3 = (yc_pc < pl_nat)

				g fi_0 = (poor_0 == 1 & ym_pc < ym_pc)
				g fi_1 = (poor_1 == 1 & yk_pc < ym_pc)
				g fi_2 = (poor_2 == 1 & yd_pc < ym_pc)
				g fi_3 = (poor_3 == 1 & yc_pc < ym_pc)

				g fg_0 = (poor_0 == 1 & ym_pc > ym_pc)
				g fg_1 = (poor_0 == 1 & yk_pc > ym_pc)
				g fg_2 = (poor_0 == 1 & yd_pc > ym_pc)
				g fg_3 = (poor_0 == 1 & yc_pc > ym_pc)

				assert fg_1 == 0  
				
				g n = 1 

				collapse (sum) n poor_* fi_* fg_* [fw=int(pcweight)]
				reshape long fi_ fg_ poor_, i(n) j(income) 
				ren (*_) (*)
				lab define income_lbl 0"Market" 1"Net market" 2"Disposable" 3"Consumable"
				lab val income income_lbl  

				g prepoor = poor[1]
				ren poor postpoor 

				g fi_poor = -(fi/postpoor)*100
				*replace fi_poor = round(fi_poor,.1)

				g fg_poor = (fg/prepoor)*100
				*replace fg_poor = round(fg_poor,.1)

				g fi_pop = -(fi/n)*100
				*replace fi_pop = round(fi_pop,.1)

				g fg_pop = (fg/n)*100
				*replace fg_pop = round(fg_pop,.1)

				global income "Income concept"
				global fi_poor "Fiscal impoverishment (% of poor pop.)"
				global fg_poor "Fiscal gains to the poor (% of poor pop.)"
				global fi_pop "Fiscal impoverishment (% of total pop.)"
				global fg_pop "Fiscal gains to the poor (% of total pop.)"
				global n "Total pop."
				global postpoor "Consumable income poor pop."
				global prepoor "Pre-fiscal poor pop."
				global fi "Fiscal impoverished (pop.)"
				global fg "Fiscal gains to the poor (pop.)"

				order income n prepoor postpoor fg* fi*

				export excel using "$gdOut\results_${date}.xlsx", sheet("fiscimp") firstrow(varlabel) sheetmodify
				save "$gdOut\fiscimp.dta", replace  
		*/		
		
	*************************************************************************************************************************************************************************
	** 2. Concentration coefficient
	*************************************************************************************************************************************************************************
	/* 	1. Concentration indices are frequently used to measure inequality in one variable over the distribution of another. 
		2. Negative no. for a transfer means, as a % of income, a proportional transfer will add more to a poor person's income than a rich person’s
		3. Positive no. as a % of income, a proportional transfer will add more to a poor person's income than a rich person’s */

		/* A concentration coefficient less than zero indicates that the variable in question is most concentrated at the bottom end of the income distribution (Poor)
		being used to rank households; a concentration coefficient equal to zero indicates that the variable in question is evenly spread across the 
			income distribution; and a concentration coefficient greater than zero indicates that the variable in question is concentrated at the top end of the 
				(ranking) income distribution (rich).*/

	use `prep', clear 
		
		foreach i of local fisclist{
			qui concindexi `i', welfarevar(yp_pc) clean
			matselrc r(CII) C, row(1) col(1)
			g cc_yp_`i' = C[1,1]*100
			matrix list C
		}

	************************************************************************************************************************************************************************
	** 3. Kakwani coefficient 
	*************************************************************************************************************************************************************************
	/*	A positive value indicates progressivity, a negative value indicates regressivity, and a value of 0 indicates a distributionally neutral tax or transfer. */
		** 5.a. Transfers (Gini Coefficient - Concentration coefficient)
	*loc benlist `dtrlist' `inklist' `sublist'
		foreach i of local benlist{
			g kk_yp_`i' = gi_yp_pc - cc_yp_`i'
		}

	** 5.b. Taxes (Concentration coefficient - Gini Coefficient)

		foreach i of local paylist{
			g kk_yp_`i' = cc_yp_`i' - gi_yp_pc
		}

		//No need to do anything different for the simulations because market income + pensions is the same in all scenarios. 

	***************************************************************************************************************************************************************************
	** 4. Marginal Contributions 
	***************************************************************************************************************************************************************************
	/*	The Marginal Contribution of a fiscal instrument is measured by the difference in an inequality or poverty measure (or any other distributional statistic)
			 at any Postfiscal Income and the Gini coefficient at the same Postfiscal Income concept excluding the instrument in question.  

		* Logic: Generate a Gini Final Income. Then, create a Gini of Final income (excluding the variable in question). After this, subtract the latter from the former.
		* Interpretation: - marginal contribution means decreases inequality; + means increases inequality (this seems more intuitive) */

		loc ydlist `dtxlist' `conlist' `dtrlist'   			//all variables for marg contr. at disposable income  
		loc yclist `itxlist' `sublist'  					//all variables for marg. contr. at consumable income 
		loc yflist `inklist' `feelist' 						//all variables for marg. contr. at final income

	// Calculate income with / without the variable of interest 
	*** Disposable 
	
		foreach i of local ydlist{
			g yd_`i' = yd_pc - `i' //sim_pitx`i'_pc 
		} 
		foreach i of local yclist{
			g yc_`i' = yc_pc - `i' //sim_pitx`i'_pc 
		} 
		foreach i of local yflist{
			g yf_`i' = yf_pc - `i' //sim_pitx`i'_pc 
		} 
	

	g chk_yc_itx_vatx_pc = yc_pc - itx_vatx_pc
	assert yc_itx_vatx_pc == chk_yc_itx_vatx_pc
	drop chk_yc_itx_vatx_pc
		

		
	// Calculate inequality for the extended disposable income concepts
	***********************************************************************
	foreach i in `ydlist'{
			qui ineqdeco yd_`i' [w=pcweight]
			g gi_yd_`i' = r(gini)*100

			qui povdeco yd_`i' [w=pcweight], varpl(pl_nat)   
			g ph_yd_`i' = r(fgt0)*100
			g pg_yd_`i' = r(fgt1)*100
	}

	foreach i in `yclist'{
			qui ineqdeco yc_`i' [w=pcweight]
			g gi_yc_`i' = r(gini)*100

			qui povdeco yc_`i' [w=pcweight], varpl(pl_nat)   
			g ph_yc_`i' = r(fgt0)*100
			g pg_yc_`i' = r(fgt1)*100
	}

	foreach i in `yflist'{
			qui ineqdeco yf_`i' [w=pcweight]
			g gi_yf_`i' = r(gini)*100

			qui povdeco yf_`i' [w=pcweight], varpl(pl_nat)   
			g ph_yf_`i' = r(fgt0)*100
			g pg_yf_`i' = r(fgt1)*100
	}	

		
	* Calculate marginal contributions as the value with the variable less the value without 
		//  For all instruments except education and health, the generated variable is w/o the instrument 

		* Without the variabel if poverty is higher then it should be positive so WITHOUT less WITH 

		foreach i in `ydlist'{
			g mc_gi_yd_`i' = gi_yd_`i' - gi_yd_pc
			g mc_ph_yd_`i' = ph_yd_`i' - ph_yd_pc
			g mc_pg_yd_`i' = pg_yd_`i' - pg_yd_pc
		}

		foreach i in `yclist'{
			g mc_gi_yc_`i' = gi_yc_`i' - gi_yc_pc
			g mc_ph_yc_`i' = ph_yc_`i' - ph_yc_pc
			g mc_pg_yc_`i' = pg_yc_`i' - pg_yc_pc
		}
		foreach i in `yflist'{
			g mc_gi_yf_`i' = gi_yf_`i' - gi_yf_pc
			g mc_ph_yf_`i' = ph_yf_`i' - ph_yf_pc
			g mc_pg_yf_`i' = pg_yf_`i' - pg_yf_pc
		}

	
		collapse (mean) cc* gi* kk* ph* pg* mc*
		ren (mc_*_yd_*) (mc_*_*) 
		ren (mc_*_yc_*) (mc_*_*)
		ren (mc_*_yf_*) (mc_*_*)
		drop gi_* ph_* pg_*

	//reshape long so that you have the variable on the rows, and the type of indicator on the columns 
		g id = _n 
		loc indlist mc_gi mc_ph mc_pg cc_yp kk_yp
		foreach ind of local indlist{
			loc n = 1
			foreach var of local fisclist{
				ren (`ind'_`var') (`ind'_`n')
				loc n = `n'+1
			}
		} 
		reshape long mc_gi_ mc_ph_ mc_pg_ cc_yp_ kk_yp_, i(id) j(instrument)
		ren (*_) (*)

		* Create labels for fiscal instrument dataset 
		disp "`fisclist'"

		lab def inst_lbl ///
				1"Direct taxes" 2"PIT" 3"Payroll" 4"PIT: IGR" 5"PIT: BIC" 6"PIT: Rent" 7"PIT: Capital" 8"Property tax" 9"Tax on salaries" 10"National contributions tax" ///
				11"Contributions" 12"Cont: NHI" 13"Cont: Family Allowance" 14"Cont: Industrial Accidents" ///
				15"Direct transfers" 16"PSSN cash transfers" 17"Scholarships" 18"Ben: Family Allowance" 19"Ben: Industrial Accidents" 20"NHI benefits" ///
				21"Indirect taxes" 22"VAT" 23"Excise" 24"Fuel tax" 25"Customs" 26"MVR" ///
				27"Electricity tax" 28"Water infra tax." 29"Indirect subs." 30"Water tariff subs." ///
				31"In-kind" 32"Health" 33"Primary healthc." 34"Hospital healthc." ///
				35"Educ." 36"Primary educ." 37"Secondary educ." 38"Tertiary educ." 39"PSSN economic inclusion" ///
				40"Userfees" 41"Hlth userfees" 42"Edu userfees" ///
				43"PIT: 2022 rates only" 44"PIT: 2022 rates, parts calc." 45"PIT: 2022 reform" ///
				46"IGR: 2022 rates only" 47"IGR: 2022 rates, parts calc." 48"IGR: 2022 reform", replace 
				
		lab val instrument inst_lbl
		global instrument "Fiscal instrument"
		global mc_gi "Marg. cont. to inequality reduction (Cons. inc.)"
		global mc_ph "Marg. cont. to pov. headc. reduction (Cons. inc.)"
		global mc_pg "Marg. cont. to pov. gap reduction (Cons. inc.)"
		global cc_yp "Concentration coefficient (yp)"
		global kk_yp "Kakwani Index (yp)"
		replace id = _n 
		export excel using "$gdOut\results_${date}.xlsx", sheet("cc_kk_mc") firstrow(varlabel) sheetmodify
		save "$gdOut\cc_kk_mc.dta", replace
	

	***************************************************************************************************************************************************************************** 
	** Part 2: Distributional analysis 
	*****************************************************************************************************************************************************************************
	** 1. Incidence 
	*****************************************************************************************************************************************************************************
		//a measure of distribution relative to income 
		foreach y in yd yp{
		use `prep', clear 

		foreach v of local fiscinclist {
	 		local l`v' : variable label `v'
	        if `"`l`v''"' == "" {
	 			local l`v' "`v'"
	  		}
	 	}

		collapse (sum) `fiscinclist' [fw=int(pcweight)], by(dec_`y') 

		foreach v of var * {
	 		label var `v' `"`l`v''"'
	 	}           

		foreach i of local fiscinclist {
			gen inc_`y'_`i' = (`i'/`y'_pc)*100
		} 
	           
	*****************************************************************************************************************************************************************************
	** 2. Concentration shares 
	*****************************************************************************************************************************************************************************
		//a measure of absolute distribution 
		foreach i of local fiscinclist{  
			qui sum `i'
			gen `i'_tt = r(sum)  
			gen conc_`i' = (`i'/`i'_tt)*100                             
		}

		foreach v of local fiscinclist {
			label var `v' `"`l`v''"'
	 		label var inc_`y'_`v' `"`l`v''"'
	 		label var conc_`v' `"`l`v''"'
	 	}

		save "$gdOut\inci_conc_`y'.dta", replace
		use "$gdOut\inci_conc_`y'.dta", clear 
		export excel dec_`y' inc_`y'_* using "$gdOut\results_${date}.xlsx", sheet("incidence_`y'") firstrow(varlabel) cell(A1) sheetmodify
		export excel dec_`y' conc_* using "$gdOut\results_${date}.xlsx", sheet("concentration_`y'") firstrow(varlabel) cell(A1) sheetmodify
}
		

	*****************************************************************************************************************************************************************************
	** Part 3: Totals
	*****************************************************************************************************************************************************************************
		use `prep', clear
		collapse (sum) `fiscinclist' [fw=int(pcweight)]
		
		foreach i of local fiscinclist{  
			replace `i' = -`i' if `i' < 0 
			g `i'_bn = `i'/1e9
			drop `i'
			*replace `i'_bn = round(`i'_bn,.1)
		}  

		foreach v of local fiscinclist {
	 		label var `v'_bn `"`l`v''"'
	 	}

		save "$gdOut\c1.dta", replace 
		export excel using "$gdOut\results_${date}.xlsx", sheet("totals") firstrow(varlabel) sheetmodify


	*****************************************************************************************************************************************************************************
	** End
	*****************************************************************************************************************************************************************************

