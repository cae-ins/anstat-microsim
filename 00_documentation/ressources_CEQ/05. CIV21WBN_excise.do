*Cote d'Ivoire 21 Excise
*12 October 2022
*Ian Houts

* Calculate the total excise tax collected in the survey
****************************************************************************
clear all
set more off 
set type double 

global non_alc	= 0.14		//Excise rate on non-alcoholic beverages (percentage)
global beer		= 0.17		//Excise rate on beer and traditional wines (percentage)
global wine		= 0.35		//Excise rate on modern wines (percentage)
global spirit 	= 0.45		//Excise rate on whiskey and spirits (percentage)
global tobacco	= 0.44		//Excise rate on tobacco products (percentage)
global cars 	= 0.10		//Excise rate on passenger vehicles (percentage)
global exc_alco = 38480000000	//Total annual excise revenue from alcohol (XOF)
global exc_toba = 35656000000	//Total annual excise revenue from tobacco (XOF)
global exc_othr =  1442000000	//Total annual excise revenue from other sources (excluding alcohol, tobacco, and fuel) (XOF)
global exc_totl = 75578000000	//Total annual excise revenue (excluding fuel) (XOF)


*1. Identify all of the excise items in the dataset by filling in the item codes for all the excise goods

	use "$gdOut\excise_base.dta", clear
	
* 	itemid  		Juice								14%
	replace itx_exco_hh = cons_val/(1+ $non_alc) * $non_alc if itemid==160 | itemid==177
* 	itemid  162		Soft drinks							14%
	replace itx_exco_hh = cons_val/(1+ $non_alc) * $non_alc if itemid==162
* 	itemid  163		Powdered juice						14%
	replace itx_exco_hh = cons_val/(1+ $non_alc) * $non_alc if itemid==163
* 	itemid  164		Traditional beers and wines			17%
	replace itx_exca_hh = cons_val/(1+ $beer) * $beer if itemid==164
* 	itemid  165		Industrial beers					17%
	replace itx_exca_hh = cons_val/(1+ $beer) * $beer if itemid==165	
* 	itemid  201		Cigarettes, Tobacco					36.5%	//average of 2018 and 2019 rates of 36 and 37 percent
	replace itx_exct_hh = cons_val/(1+ $tobacco) * $tobacco if itemid==201
* 	itemid  301		Whiskey and other liqueurs			45%
	replace itx_exca_hh = cons_val/(1+ $spirit) * $spirit if itemid==301
* 	itemid  302		Modern wines						35%
	replace itx_exca_hh = cons_val/(1+ $wine) * $wine if itemid==302 
* 	itemid  626		Personal car						10%
	replace itx_exco_hh = cons_val/(1+ $cars) * $cars if itemid==626 

egen itx_excs_hh = rowtotal(itx_exca_hh itx_exct_hh itx_exco_hh)
count if itx_excs_hh >0 & itx_excs_hh !=.		//

gen itx_excs_ri = (itx_excs_hh>0)

*3. Collapse the file to hh level
	collapse (sum) itx_excs_hh itx_exca_hh itx_exct_hh itx_exco_hh itx_excs_rh=itx_excs_ri, by(hhid weight)
	label var itx_excs_hh "Excise tax"
	label var itx_excs_rh "Household pays excise tax"	
			
save "$gdTemp\excise_final.dta", replace
	

