******************************************************
* Cote d'Ivoire 2021
* Ian Houts
* Dec 4 2023
* Fuel excise

set type double
set more off
clear all 

***UPDATE*** All fuel taxes were eliminated and a fuel subsidy was implemented
* these parameters can move to simulate fuel taxes (this in XFO/L):
global exc_fuel = 0		//Average excise charge on gasoline and diesel fuel per liter (CFCA)
global exc_kero = 0		//Excise charge on kerosene fuel per liter (CFCA)

use "$gdOut\fuel_excise_base", clear

replace exc_hh_fuel= hh_fuel_qty* $exc_fuel if itemid==208 | itemid==209 | itemid==304		//excise from fuel (avg of premium fuel, ordinary gasoline, and diesel excise, as no disaggregation exists in consumption data)
replace exc_hh_kero= hh_kero_qty* $exc_kero if itemid==202

			*Calculate sum of consumption (d)
				qui sum hh_fuel_exp [w=weight]
				local hh_fuel = r(sum)
				display "`hh_fuel'"
			*Calculate sum of excise (d) 
				qui sum exc_hh_fuel [w=weight]
				local exc_hh_fuel = r(sum)
				disp %20.0f `exc_hh_fuel'
			*Calculate sum of consumption (d)
				qui sum hh_kero_exp [w=weight]
				local hh_kero = r(sum)
				disp %20.0f `hh_kero'
			*Calculate sum of excise (d) 
				qui sum exc_hh_kero [w=weight]
				local exc_hh_kero = r(sum)
				disp %20.0f `exc_hh_kero'
			*Sum excises by fuel type				
				loc exc_hh_fuel_tot = `exc_hh_fuel'+`exc_hh_kero'
				disp %20.0f `exc_hh_fuel_tot'
				loc hh_fuel_tot = `hh_fuel'+`hh_kero'
			* Calculate the increase in the pre-excise value of fuel 
				loc pricechange_23 = `exc_hh_fuel_tot'/(`hh_fuel_tot'-`exc_hh_fuel_tot')
				disp `pricechange_23'

********************************************************************************
*Step 3: Collapse and include Indirect effects

*Create a variable that includes all of the direct excise effects
gen itx_dfuel_hh = exc_hh_fuel
collapse (sum) itx_dfuel_hh, by(hhid weight)
lab var itx_dfuel_hh "Direct fuel tax"


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
		lab var fuel_ind_gf "Imputed indirect price factor increases due to excise tax on fuel"

		foreach num of numlist 1/`Nsectors'{
			replace fuel_ind_gf = fuelIO`num' if io == `num'
		}

		g itx_ifuel_hh = 0										
		replace itx_ifuel_hh = cons_val*fuel_ind_gf
		collapse (sum) itx_ifuel_hh, by(hhid weight)

		lab var  itx_ifuel_hh "Indirect fuel tax"   
		order hhid
	save "$gdTemp\fuel_ind.dta", replace
	
restore
	
	
merge 1:1 hhid using "$gdTemp\fuel_ind.dta"
drop _merge
egen itx_excs_fuel_hh = rowtotal(itx_ifuel_hh itx_dfuel_hh)
lab var itx_excs_fuel_hh "Fuel tax (dir and ind)"

merge 1:1 hhid using "$gdTemp\yd.dta", keepusing(dec_yd_hh dec_yd_pc)
drop _merge

g itx_excs_fuel_rh = (itx_excs_fuel_hh>0)

save "$gdTemp\fuel_final.dta", replace 
