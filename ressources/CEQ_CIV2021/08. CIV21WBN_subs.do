*Cote d'Ivoire 2021
*5 Dec 2023
*Ian Houts
*Indirect Subsidies

clear all
set more off
set type double

global prodcost = 59.67			//Production cost of one kWh (XOF)
global esocial   = 81131		//Maximum electricity cost for households in social tranche, postpayment - Abidjan (XOF)
global esocialb  = 79331		//Maximum electricity cost for households in social tranche, postpayment - Non-Abidjan (XOF)
global esociall	 = 23898		//Upper threshold of electricity expenditure in 1st billing range of social tranche (XOF)
global esociallb = 23178		//Upper threshold of electricity expenditure in 1st billing range of social tranche, postpayment (XOF)

global edomestic = 211652		//Upper threshold of electricity expenditure in 1st billing range of domestic tranche, postpayment - Abidjan (XOF)
global edomesticb = 210032		//Upper threshold of electricity expenditure in 1st billing range of domestic tranche, postpayment - non-Abidjan (XOF)

global esocialp   = 71940		//Maximum electiricity cost for households in social tranche, prepayment - Abidjan (XOF)
global esocialpb  = 70140		//Maximum electiricity cost for households in social tranche, prepayment - Non-Abidjan (XOF)

global wtranche0 = 235		//Unit price of one m3 of water for consumption under 9m3 (XOF) 2,115
global wtranche1 = 235		//Unit price of one m3 of water in tranche 1 (XOF) 2,115
global wtranche2 = 367.3	//Unit price of one m3 of water in tranche 2 (XOF) 30,675.6
global wtranche3 = 586.8	//Unit price of one m3 of water in tranche 3 (XOF)
global wtranche4 = 684.3	//Unit price of one m3 of water in tranche 4 (XOF)

global wupper0 = 9			//Upper threshold of water consumption in flat billing tranche (m3)
global wupper1 = 18			//Upper threshold of water consumption in tranche 1 (m3)		
global wupper2 = 90			//Upper threshold of water consumption in tranche 2 (m3)
global wupper3 = 300		//Upper threshold of water consumption in tranche 3 (m3)

global wprodcost = 299		//Production cost for one unit (m3) of public water

***UPDATE*** All fuel taxes were eliminated and a fuel subsidy was implemented
global sub_petr = 285		//Subsidy on gasoline fuel per liter (CFCA)
global sub_dies = 469		//Subsidy on diesel fuel per liter (CFCA)
global sub_fuel = ( $sub_petr + $sub_dies ) / 2		//Average of fuel subsidies, as the survey does not discriminate between petrol and diesel.


use "$gdOut\sub_elec_base.dta", clear

****POST_PAYMENT****
g tranche1= (elec_exp<= $esocial & elec_access==1 & takataka==1 & postpay==1)			//social abidjan
g tranche2= (elec_exp> $esocial & elec_access==1 & takataka==1  & postpay==1)			//general abidjan

g tranche1a = (elec_exp<= $esociall ) if tranche1==1 & takataka==1 & postpay==1			//social lower range abidjan
g tranche1b = (elec_exp> $esociall ) if tranche1==1 & takataka==1 & postpay==1			//social upper range abidjan

replace tranche1  = (elec_exp<= $esocialb ) if elec_access==1 & takataka==0 & postpay==1	//social elsewhere
replace tranche1a = (elec_exp<= $esociallb ) if tranche1==1 & takataka==0 & postpay==1		//social lower range elsewhere
replace tranche1b = (elec_exp> $esociallb ) if tranche1==1 & takataka==0 & postpay==1		//social upper range elsewhere

g tranche2a = (elec_exp<= $edomestic ) if tranche2==1 & takataka==1 & postpay==1			//general lower range abidjan
g tranche2b = (elec_exp> $edomestic )  if tranche2==1 & takataka==1 & postpay==1			//general upper range abidjan

replace tranche2  = (elec_exp> $esocialb )   if elec_access==1 & takataka==0 & postpay==1	//general elsewhere
replace tranche2a = (elec_exp<= $edomesticb ) if tranche2==1 & takataka==0 & postpay==1	//general lower range elsewhere
replace tranche2b = (elec_exp> $edomesticb )  if tranche2==1 & takataka==0 & postpay==1	//general upper range elsewhere

****PRE_PAYMENT**** 
g tranche3 = (elec_access==1 & prepay==1)										//social tranche 		can't be higher than 100kWh per month
g tranche3a = (elec_exp<= $esocialp ) if tranche3==1 & takataka==1 & prepay==1		//social abidjan 		
g tranche3b = (elec_exp<= $esocialpb ) if tranche3==1 & takataka==0 & prepay==1		//social elsewhere 		


*Estimate kWh
replace elec_kwh = (elec_exp*.015) /6/2.5  if tranche1a==1 & takataka==1		//Estimate by elec fee in 1st billing range of social tranche -- Abidjan
replace elec_kwh = (elec_exp*.020) /6/1    if tranche1a==1 & takataka==0		//by elec fee in 1st range -- Other regions
replace elec_kwh = (elec_exp*.015) /6/2.5  if tranche1b==1 & takataka==1		//by elec fee in 2nd range -- Abidjan
replace elec_kwh = (elec_exp*.021) /6/1    if tranche1b==1 & takataka==0		//by elec fee in 2nd range -- Other regions

replace elec_kwh = (elec_exp*.010)  /6/2.5  if tranche2a==1 & takataka==1		//Estimate by elec fee in 1st billing range of domestic tranche -- Abidjan
replace elec_kwh = (elec_exp*.011)  /6/1    if tranche2a==1 & takataka==0		//by elec fee in 1st range -- Other regions
replace elec_kwh = (elec_exp*.011)  /6/2.5  if tranche2b==1 & takataka==1		//by elec fee in 2nd range -- Abidjan
replace elec_kwh = (elec_exp*.012)  /6/1    if tranche2b==1 & takataka==0		//by elec fee in 2nd range -- Other regions

replace elec_kwh = elec_exp / 59.95 / 12 if tranche3a==1		//Electricity in social prepaid is variable only by region and kVA, but we use 5kVA for each household. 
replace elec_kwh = elec_exp / 58.45 / 12 if tranche3b==2

******************
*Estimate Subsidy
******************
*Subsidy = Cost of production - cost per kWh w/o VAT levies.    Want to see if there is cross-subsidization

g prodcost = $prodcost * elec_kwh

*Estimate the electricity bill without VAT: 
*				  fixed premium + billing range + Royality rural fee + Royal electrification fee + RTI fee + garbage collection
replace elecost = (3354 + (36.05*elec_kwh*6) + 600 + (elec_kwh*6) + (elec_kwh*2*6) + (2.5*elec_kwh*6)) if tranche1a==1 & takataka==1
replace elecost = (3354 + (36.05*elec_kwh*6) + 600 + (elec_kwh*6) + (elec_kwh*2*6) + (1*elec_kwh*6))   if tranche1a==1 & takataka==0
replace elecost = (3354 + (36.05*80*6) + (62.70*(elec_kwh-80)*6) + 600 + (elec_kwh*6) + (elec_kwh*2*6) + (2.5*elec_kwh*6)) if tranche1b==1 & takataka==1
replace elecost = (3354 + (36.05*80*6) + (62.70*(elec_kwh-80)*6) + 600 + (elec_kwh*6) + (elec_kwh*2*6) + (1*elec_kwh*6))   if tranche1b==1 & takataka==0


replace elecost = (7479 + (66.96*elec_kwh*6) + 600 + (1.06*elec_kwh*6) + (2000*6) + (2.5*elec_kwh*6)) if tranche2a==1 & takataka==1
replace elecost = (7479 + (66.96*elec_kwh*6) + 600 + (1.06*elec_kwh*6) + (2000*6) + (1*elec_kwh*6))   if tranche2a==1 & takataka==0
replace elecost = (7479 + (66.96*180*6) + (58.04*(elec_kwh-180)*6) + 600 + (1.06*elec_kwh*6) + (2000*6) + (2.5*elec_kwh*6)) if tranche2b==1 & takataka==1
replace elecost = (7479 + (66.96*180*6) + (58.04*(elec_kwh-180)*6) + 600 + (1.06*elec_kwh*6) + (2000*6) + (1*elec_kwh*6))   if tranche2b==1 & takataka==0

replace elecost = elec_kwh * 56.25 * 12 if tranche3a==1
replace elecost = elec_kwh * 54.75 * 12 if tranche3b==1


replace sub_elec_in = prodcost - elecost if prodcost!=. & elecost!=. & elecost>0		//(elecost-vat_elec)

g sub_elec_ri = (sub_elec_in>0 & sub_elec_in!=.)

*Collapse, estimate, and save
collapse (sum) sub_elec_hh = sub_elec_in elec_exp (max)sub_elec_rh = sub_elec_ri, by(hhid weight)

g itx_elec_hh = sub_elec_hh
replace itx_elec_hh = 0 if itx_elec_hh>0
replace sub_elec_hh = 0 if sub_elec_hh<0
replace itx_elec_hh = itx_elec_hh*-1

save "$gdTemp\sub_elec_final.dta", replace



****************WATER***************************************************************
use "$gdOut\sub_watr_base.dta", clear


*Subsidy brackets
g tranche0 =  (watr_exp<=( $wtranche0 * $wupper0 ) & watr_exp>0)
g tranche1 =  (watr_exp>( $wtranche0 * $wupper0 ) & watr_exp<= ((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 )))			
g tranche2 =  (watr_exp>((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 )) & watr_exp<= ((( $wupper2 - $wupper1 ) * $wtranche2 ) + (((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 )))))			
g tranche3 =  (watr_exp> (( $wupper2 - $wupper1 ) * $wtranche2 ) + (((( $wupper1 - $wupper0 ) * $wtranche1) + ($wtranche0 * $wupper0 ))) & watr_exp<= (($wupper3 - $wupper2) * $wtranche3 ) + (( $wupper2 - $wupper1 ) * $wtranche2 ) + (((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 ))))
g tranche4 =  (watr_exp> (($wupper3 - $wupper2) * $wtranche3 ) + (( $wupper2 - $wupper1 ) * $wtranche2 ) + (((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 ))))

*calculate quantity m3 with VAT included in price                   
replace wtr_qty = watr_exp/ ($wtranche0 * $wupper0 )  if tranche0==1
replace wtr_qty = ((watr_exp-($wtranche0 * $wupper0 )) / $wtranche1 ) + $wupper0  if tranche1==1		//expenditure - max expenditure on tranche0, plus max quantity in tranche0
replace wtr_qty = ((watr_exp-(((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 )))) / $wtranche2 ) + $wupper1 if tranche2==1		
replace wtr_qty = ((watr_exp-((( $wupper2 - $wupper1 ) * $wtranche2 ) + (((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 ))))) / $wtranche3 ) + $wupper2 if tranche3==1	
replace wtr_qty = ((watr_exp- ((($wupper3 - $wupper2) * $wtranche3 ) + ((( $wupper2 - $wupper1 ) * $wtranche2 ) + (((( $wupper1 - $wupper0 ) * $wtranche1 ) + ($wtranche0 * $wupper0 )))))) / $wtranche4 ) + $wupper3 if tranche4==1	
qui sum wtr_qty
disp %20.0f r(sum)

*Calculate subsidy paid to contractor and tax taken from funds with VAT price excluded
replace sub_watr_in = wtr_qty*71 
g itx_wsub_in = wtr_qty * 7 if (tranche0==1 | tranche1==1)	//126 max. These are billed at the same rate even though it's not in the table for tranche0
replace itx_wsub_in = ((wtr_qty-18) * 98.3) + 126 if tranche2==1		//7,077.6 max
replace itx_wsub_in = ((wtr_qty-90) * 317.8) + 7203.6 if tranche3==1	//66,738 max
replace itx_wsub_in = ((wtr_qty-300) * 415.3) + 73941.6 if tranche4==1	


replace sub_watr_in=0 if sub_watr_in<0

g sub_watr_ri = (sub_watr_in>0 & sub_watr_in!=.)

collapse (sum)itx_wsub_hh=itx_wsub_in sub_watr_hh=sub_watr_in (max) sub_watr_rh = sub_watr_ri, by(hhid weight)


save "$gdTemp\sub_watr_final.dta", replace


******************************************************
* Fuel subsidy
clear all 

use "$gdOut\fuel_subsidy_base", clear

replace sub_hh_fuel= hh_fuel_qty* $sub_fuel if itemid==208 | itemid==209 | itemid==304		//excise from fuel (avg of premium fuel, ordinary gasoline, and diesel excise, as no disaggregation exists in consumption data)

			*Calculate sum of consumption (d)
				qui sum hh_fuel_exp [w=weight]
				local hh_fuel = r(sum)
				display "`hh_fuel'"
			*Calculate sum of subsidy (d) 
				qui sum sub_hh_fuel [w=weight]
				local sub_hh_fuel = r(sum)
				disp %20.0f `sub_hh_fuel'
			* Calculate the decrease in the pre-subsidy value of fuel 
				loc pricechange_23 = `sub_hh_fuel'/(`hh_fuel'+`sub_hh_fuel')
				disp `pricechange_23'

********************************************************************************
*Step 3: Collapse and include Indirect effects

*Create a variable that includes all of the direct excise effects
gen sub_dfuel_hh = sub_hh_fuel
collapse (sum) sub_dfuel_hh, by(hhid weight)
lab var sub_dfuel_hh "Direct fuel subsidy"


preserve
	*******************************************************************************************************
	* Step 1: INPUT
	*******************************************************************************************************

	* a. Read in the IO matrix, as a model of Cote d'Ivoire's economy
		import excel using "$io\CIV21_AugIO.xlsx", sheet("AugL") cellrange(C3:BC55) firstrow clear   	
		
		/* When read in STATA, the IO Aij coefficients matrix column names are treated by Stata as variables. In 
		this step a local macro called sectors is defined and assigned column names which is used as headings for
		displaying results */

		 foreach var of varlist * {         // collects all variables into local     
			if "`var'" != "Sectors"    {          // sectors except for sector name 
					loc sectors "`sectors' `var'"                         
			}                                    
		  }        
		   disp `sectors'

	* b. Declare matrix A as the Leontief coefficient matrix               
		mkmat `sectors', matrix(A)     
		

	* c. Count the number of sectors in the IO table
		loc Nsectors = rowsof(A) // number of I/O table sectors
		disp `Nsectors'   														// Cote d'Ivoire has 52 rows in the IO table										
		
	* d. Set up the simulation parameters	  
	* Fuel sector 23 = Petroleum products
		loc dpfuel23 = `pricechange_23'							//Excise tax as a percentage of the pre-excise value of fuel (sum of total fuel excise costs/(Sum of total fuel costs - sum of total fuel excise costs)) 


		matrix dp_fuel = J(1,`Nsectors',0) 
		matrix dp_fuel[1,23]=`dpfuel23'   										//23 = the IO sector number in which fuel is included
		mat list dp_fuel

	* e. Initialise a vector of sectors which have fixed prices that will not increase due to the electricity increase
		loc fixprice "23 35 36 46 47 48"    				 					// [Put in here the fuel sector, at a minimum, and then include any sectors that are gov administered, like water and electricity.]
		matrix dir

	*-----------------------------------------------------------------------------------------------------------------------------------------
	** Step 2. Compute indirect price effects of higher fuel prices on prices of other goods and services as listed in the IO table accounts.                                                             
	*-----------------------------------------------------------------------------------------------------------------------------------------
	  ** Define matrices                                                     
	     matrix gamma=J(`Nsectors',`Nsectors',0)  								// initializes fixed price matrix, with everything set to 0 
	   
	  ** Specify the row/column numbers of the commodities whose price will be fixed                                                           
	     foreach row of numlist `fixprice' {                       
	         matrix gamma[`row',`row']=1                  
	     }  																	//	replaces the matrix with fixed price sectors set to 1 on the diagonal

	    ** Calculating cost-push model pass-through for prices of all sectors
	    matrix alpha       = I(`Nsectors') - gamma          					//	1 on the diagonal for all sectors except for those with fixed prices 
	    matrix V           = inv(I(`Nsectors') - alpha * A) 					// 	scale everything back by 1-change in price                
		matrix deltaptilda = dp_fuel * A * V      								//	Indirect effect price increase                             
	    matrix deltap      =(dp_fuel*gamma) + (deltaptilda+dp_fuel) * alpha    	//	this is the second order effect, where you calculate 1) the direct change, 2) the change order change
	    matrix deltap = deltap'    

	*-----------------------------------------------------------------------------------------------------------------------                  
	** Step 3. OUTPUT: Extract final tax rates as scalars from this matrix, numbered according to Cote d'Ivoire's IO sectors
	*-----------------------------------------------------------------------------------------------------------------------

	    scalar drop _all
		foreach num of numlist 1/`Nsectors'{
			scalar fuelIO`num' = deltap[`num',1]
		}
		scalar dir

	* [adapt the Excel file name and sheet should you wish to change them]
		putexcel set "$gdTemp\Price changes_fuel.xlsx", sheet("Price changes") modify
		putexcel d3 = mat(deltap)


	use "$gdOut\cons_vat.dta", clear     //read in the consumption dataset
	
		loc Nsectors = 52

		g fuel_ind_gf = .
		lab var fuel_ind_gf "Imputed indirect price factor decreases due to subsidy on fuel"

		foreach num of numlist 1/`Nsectors'{
			replace fuel_ind_gf = fuelIO`num' if io == `num'
		}

		g sub_ifuel_hh = 0										
		replace sub_ifuel_hh = cons_val*fuel_ind_gf
		collapse (sum) sub_ifuel_hh, by(hhid weight)

		lab var  sub_ifuel_hh "Indirect fuel subsidy"   
		order hhid
	save "$gdTemp\fuel_ind.dta", replace
	
restore
	
	
merge 1:1 hhid using "$gdTemp\fuel_ind.dta"
drop _merge

*Scaling down indirect fuel to account for less-than-100% pass-through, as is almost certainly the case according to Rayner in Cameroon. Eliminating all indirect subsidy still doesn't get down to the target rate... 
replace sub_ifuel_hh = sub_ifuel_hh*0.2

egen sub_fuel_hh = rowtotal(sub_ifuel_hh sub_dfuel_hh)
lab var sub_fuel_hh "Fuel subsidy (dir and ind)"

merge 1:1 hhid using "$gdTemp\yd.dta", keepusing(dec_yd_hh dec_yd_pc)
drop _merge

g sub_fuel_rh = (sub_fuel_hh>0)

save "$gdTemp\sub_fuel_final.dta", replace 


