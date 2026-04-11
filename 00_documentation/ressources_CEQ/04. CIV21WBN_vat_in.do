*******************************************************************************************************
* Cote d'Ivoire 2021
* Ian Houts
* VAT simulation
clear all
set more off 
set type double 

global VATIO1    =  0.09    //VAT charge on expenditures including FOOD AGRICULTURE PRODUCTS
global VATIO2    =  0.00    //VAT charge on expenditures including exempt food
global VATIO3    =  0.18    //VAT charge on expenditures including AGRICULTURAL PRODUCTS INTENDED PRIMARILY FOR
global VATIO4    =  0.00    //VAT charge on expenditures including LIVESTOCK AND HUNTING PRODUCTS
global VATIO5    =  0.18    //VAT charge on expenditures including AGRICULTURE AND EL SUPPORT SERVICES
global VATIO6    =  0.18    //VAT charge on expenditures including FORESTRY AND logging PRODUCTS
global VATIO7    =  0.00    //VAT charge on expenditures including FISHING, PISCULTURE AND AQUACULT PRODUCTS
global VATIO8    =  0.18    //VAT charge on expenditures including PRODUCTS FROM THE EXTRACTIVE INDUSTRIES
global VATIO9    =  0.00    //VAT charge on expenditures including MEAT, MEAT PRODUCTS AND PRODUCTS
global VATIO10   =  0.00    //VAT charge on expenditures including Fats and oils
global VATIO11   =  0.00    //VAT charge on expenditures including PRODUCT OF GRAIN WORK AND AMY PRODUCTS
global VATIO12   =  0.00    //VAT charge on expenditures including BREAD, PASTRY AND PASTA
global VATIO13   =  0.18    //VAT charge on expenditures including COCOA, COFFEE AND PROCESSING PRODUCTS
global VATIO14   =  0.09    //VAT charge on expenditures including OTHER FOOD PRODUCTS
global VATIO15   =  0.00    //VAT charge on expenditures including exempt other food
global VATIO16   =  0.18    //VAT charge on expenditures including DRINKS
global VATIO17   =  0.18    //VAT charge on expenditures including CIGARETTES AND OTHER TOBACCO PRODUCTS
global VATIO18   =  0.18    //VAT charge on expenditures including TEXTILE AND APPAREL INDUSTRIES
global VATIO19   =  0.18    //VAT charge on expenditures including WORKED LEATHER; TRAVEL ITEMS; SHOE
global VATIO20   =  0.18    //VAT charge on expenditures including WOOD, WOODEN OR BASKETWARE ARTICLES
global VATIO21   =  0.18    //VAT charge on expenditures including PAPER AND CARDBOARD INDUSTRY PRODUCTS
global VATIO22   =  0.00    //VAT charge on expenditures including exempt PAPER PRODUCTS
global VATIO23   =  0.00    //VAT charge on expenditures including REFINING PRODUCTS
global VATIO24   =  0.18    //VAT charge on expenditures including CHEMICALS AND PHARMACEUTICALS
global VATIO25   =  0.00    //VAT charge on expenditures including exempt pharmaceuticals
global VATIO26   =  0.18    //VAT charge on expenditures including RUBBER OR PLASTIC PRODUCTS
global VATIO27   =  0.18    //VAT charge on expenditures including NON-METALLIC MINERAL PRODUCTS
global VATIO28   =  0.18    //VAT charge on expenditures including METALLURGICAL PRODUCTS; METAL WORKS
global VATIO29   =  0.18    //VAT charge on expenditures including ELECTRONIC AND COMPUTER PRODUCTS
global VATIO30   =  0.09    //VAT charge on expenditures including ELECTRICAL EQUIPMENT AND MATERIALS
global VATIO31   =  0.18    //VAT charge on expenditures including MACHINERY AND EQUIPMENT N.E.C.
global VATIO32   =  0.18    //VAT charge on expenditures including TRANSPORT EQUIPMENT
global VATIO33   =  0.18    //VAT charge on expenditures including FURNITURE, MISCELLANEOUS PRODUCTS
global VATIO34   =  0.18    //VAT charge on expenditures including REPAIR AND INSTALLATION OF MACHINERY AND
global VATIO35   =  0.18    //VAT charge on expenditures including ELECTRICITY PRODUCTION, DISTRIBUTION AND
global VATIO36   =  0.18    //VAT charge on expenditures including PRODUCTION AND DISTRIBUTION OF WATER, SANITATION
global VATIO37   =  0.18    //VAT charge on expenditures including CONSTRUCTION WORKS
global VATIO38   =  0.18    //VAT charge on expenditures including TRADE
global VATIO39   =  0.18    //VAT charge on expenditures including TRANSPORTATION AND WAREHOUSE SERVICES
global VATIO40   =  0.18    //VAT charge on expenditures including ACCOMMODATION AND FOOD SERVICES
global VATIO41   =  0.18    //VAT charge on expenditures including INFORMATION AND COMMUNICATION SERVICES
global VATIO42   =  0.00    //VAT charge on expenditures including FINANCIAL AND INSURANCE SERVICES
global VATIO43   =  0.18    //VAT charge on expenditures including REAL ESTATE SERVICES
global VATIO44   =  0.18    //VAT charge on expenditures including SPECIALIZED, SCIENTIFIC AND TECH ACTIVITIES
global VATIO45   =  0.18    //VAT charge on expenditures including SUPPORT AND OFFICE SERVICES ACTIVITIES
global VATIO46   =  0.18    //VAT charge on expenditures including PUBLIC ADMINISTRATION SERVICES
global VATIO47   =  0.00    //VAT charge on expenditures including EDUCATION
global VATIO48   =  0.00    //VAT charge on expenditures including HUMAN HEALTH AND SOCIAL ACTION SERVICES
global VATIO49   =  0.18    //VAT charge on expenditures including COLLECTIVE, SOCIAL AND PERSONAL SERVICES
global VATIO50   =  0.18    //VAT charge on expenditures including OTHER SERVICE ACTIVITIES N.E.C.
global VATIO51   =  0.18    //VAT charge on expenditures including ACTIVITY OF HOUSEHOLDS AS EMPLOYERS OF
global VATIO52   =  0.18    //VAT charge on expenditures including TERRITORIAL CORRECTION

global exemptions "2 4 7 9 10 11 12 15 22 25 42 47 48"	// IO sectors exempted from VAT
 
* Purpose: Calculate the vat on purchases
*******************************************************************************************************

* 1. Calculate the effective rates by running datasets 1, 2, and 3
	* Baseline

**************************************************
*1. Matrix of domestic Leontief coefficients
**************************************************
  * 1a. import the spreadsheet as a list of variables 
  
  import excel using "$io\CIV21_AugIO.xlsx", sheet("AugL") cellrange(C117:BC169) firstrow clear
  
  * 1b. create a local which contains the list of variable names in the dataset, excluding the first variable with all the IO sector names 
  * [change the phrase "Augmented sectors" to whatever the column heading is in the Excel spreadsheet for the row labels]
  foreach var of varlist * {              
  	if "`var'" != "Sectors"    {           
  			local sectors "`sectors' `var'"                         
  	}                                    
  }

  * 1c. turn the variables into one big matrix stored in Stata's memory with the name gammaD
  mkmat `sectors', matrix(gammaD)

**************************************************
*2. Matrix of foreign Leontief coefficients
**************************************************
  * 2a. import the spreadsheet as a list of variables 
  
import excel using "$io\CIV21_AugIO.xlsx", sheet("AugL") cellrange(C60:BC112) firstrow clear

  * 2b. turn the variables into one big matrix stored in Stata's memory with the name gammaF
  mkmat `sectors', matrix(gammaF)	

*********************************************************
*3. Share of imported components in each good / service
*********************************************************
  * 3a. import the imported share column as a variable
  * [Adapt the name of the Excel spreadsheet, the Excel sheet, and the cellrange]
  import excel using "$io\CIV21_AugIO.xlsx", sheet("AugL") cellrange(BE3:BE55) firstrow clear 
  
  * 3b. turn the variable into a column vector stored in Stata's memory with the name IMP for imported
  mkmat impsh, matrix(IMP)	

  * 3c. turn the column vector into a row vector for conformability reasons in the do_iovat.do file
  matrix IMP = IMP'         

*********************************************************
*4. Share of domestic components in each good / services
*********************************************************
  * 4a. import the domestic share column as a variable
  * [Adapt the name of the Excel spreadsheet, the Excel sheet, and the cellrange]
  import excel using "$io\CIV21_AugIO.xlsx", sheet("AugL") cellrange(BF3:BF55) firstrow clear

  * 4b. turn the variable into a column vector stored in Stata's memory with the name DOM for domestic
  mkmat domsh, matrix(DOM)	

  * 3c. turn the column vector into a row vector for conformability reasons in the do_iovat.do file
  matrix DOM = DOM'     
	
*******************************************************************************************************
* VAT PARAMETERS 
*******************************************************************************************************

*** Number of IO sectors in the Augmented IO table:
scalar NUMGOODS = 52

**** IO sectors that are exempt: 
local z = NUMGOODS

foreach i of numlist 1/`z' {

	scalar VATEXEMPT`i' = 0 
}

foreach i of numlist $exemptions {

	scalar VATEXEMPT`i' = 1
	
}

*Cote d'Ivoire Augmented IO sectors		// We are using the 2018 tax rates to align with the 2018 survey.
										// Some sectors contain exempt goods that could not be identified exactly, so estimated reductions of effective VAT are assigned accordingly
scalar VAT1  =  $VATIO1  
scalar VAT2  =  $VATIO2  
scalar VAT3  =  $VATIO3  
scalar VAT4  =  $VATIO4  
scalar VAT5  =  $VATIO5  
scalar VAT6  =  $VATIO6  
scalar VAT7  =  $VATIO7  
scalar VAT8  =  $VATIO8  
scalar VAT9  =  $VATIO9  
scalar VAT10 =  $VATIO10 
scalar VAT11 =  $VATIO11 
scalar VAT12 =  $VATIO12 
scalar VAT13 =  $VATIO13 
scalar VAT14 =  $VATIO14 
scalar VAT15 =  $VATIO15 
scalar VAT16 =  $VATIO16 
scalar VAT17 =  $VATIO17 
scalar VAT18 =  $VATIO18 
scalar VAT19 =  $VATIO19 
scalar VAT20 =  $VATIO20 
scalar VAT21 =  $VATIO21 
scalar VAT22 =  $VATIO22 
scalar VAT23 =  $VATIO23 
scalar VAT24 =  $VATIO24 
scalar VAT25 =  $VATIO25 
scalar VAT26 =  $VATIO26 
scalar VAT27 =  $VATIO27 
scalar VAT28 =  $VATIO28 
scalar VAT29 =  $VATIO29 
scalar VAT30 =  $VATIO30 
scalar VAT31 =  $VATIO31 
scalar VAT32 =  $VATIO32 
scalar VAT33 =  $VATIO33 
scalar VAT34 =  $VATIO34 
scalar VAT35 =  $VATIO35 
scalar VAT36 =  $VATIO36 
scalar VAT37 =  $VATIO37 
scalar VAT38 =  $VATIO38 
scalar VAT39 =  $VATIO39 
scalar VAT40 =  $VATIO40 
scalar VAT41 =  $VATIO41 
scalar VAT42 =  $VATIO42 
scalar VAT43 =  $VATIO43 
scalar VAT44 =  $VATIO44 
scalar VAT45 =  $VATIO45 
scalar VAT46 =  $VATIO46 
scalar VAT47 =  $VATIO47 
scalar VAT48 =  $VATIO48 
scalar VAT49 =  $VATIO49 
scalar VAT50 =  $VATIO50 
scalar VAT51 =  $VATIO51 
scalar VAT52 =  $VATIO52 
		
*		do "${code}CIV21WBN_do_iovat_base.do"		//calculates an effective vat rate for each io sector, and stores them in a set of scalars
*-----------------------------------------------------------------------------------------------------                    
** Step 1. Set up the tax rates to be used in the I-O analysis
*-----------------------------------------------------------------------------------------------------

*rowsof(gammaD) 52x52

*rowsof(gammaF) 52x52


	* Specify rate of formality/compliance with the vat system, as defined in interface
	*local alpha = $effindex
	local alpha = 1
	disp `alpha'  //
	
	* Specify number of sectors, as defined in parameters file
	local z = NUMGOODS
	* Specify dimensions of Leontief
	local Nsectors = rowsof(gammaD)	
	disp `Nsectors'

	* Create matrices of VAT rates and exemptions, where ordering aligns with SAM

	foreach i of numlist 1/`z' {

		local a = VATEXEMPT`i'

		* Ensure that all sectors that are exempt have no VAT or NHIL being charged

		if `a' == 1 {
		scalar VAT`i' = 0			
		}

	}

	* This is a very manual step of realigning tax rates from the parameters file with the order of the SAM
	* We have aligned these already in the excel file, so they are all in order 

	* [adapt the number of VAT elements in the t matrix, and in the oldE matrix]
***************************************************************************************************************
	#delimit ;
	matrix t = (VAT1,VAT2,VAT3,VAT4,VAT5,VAT6,VAT7,VAT8,VAT9,VAT10,VAT11,VAT12,VAT13,VAT14,VAT15,
					VAT16,VAT17,VAT18,VAT19,VAT20,VAT21,VAT22,VAT23,VAT24,VAT25,VAT26,VAT27,VAT28,VAT29,VAT30,VAT31,VAT32,VAT33,
					VAT34,VAT35,VAT36,VAT37,VAT38,VAT39,VAT40,VAT41,VAT42,VAT43,VAT44,VAT45,VAT46,VAT47,VAT48,VAT49,VAT50,VAT51,
					VAT52);
	#delimit cr	

	#delimit ;
	matrix oldE = (VATEXEMPT1,VATEXEMPT2,VATEXEMPT3,VATEXEMPT4,VATEXEMPT5,VATEXEMPT6,VATEXEMPT7,VATEXEMPT8,VATEXEMPT9,
						VATEXEMPT10,VATEXEMPT11,VATEXEMPT12,VATEXEMPT13,VATEXEMPT14,VATEXEMPT15,VATEXEMPT16,VATEXEMPT17,
						VATEXEMPT18,VATEXEMPT19,VATEXEMPT20,VATEXEMPT21,VATEXEMPT22,VATEXEMPT23,VATEXEMPT24,VATEXEMPT25,
						VATEXEMPT26,VATEXEMPT27,VATEXEMPT28,VATEXEMPT29,VATEXEMPT30,VATEXEMPT31,VATEXEMPT32,
						VATEXEMPT33,VATEXEMPT34,VATEXEMPT35,VATEXEMPT36,VATEXEMPT37,VATEXEMPT38,VATEXEMPT39,
						VATEXEMPT40,VATEXEMPT41,VATEXEMPT42,VATEXEMPT43,VATEXEMPT44,VATEXEMPT45,VATEXEMPT46,VATEXEMPT47,
						VATEXEMPT48,VATEXEMPT49,VATEXEMPT50,VATEXEMPT51,VATEXEMPT52);
	#delimit cr	

	* Here define the vector of VAT exemption status needed for this analysis. We need the entry for the sector to be 0 if it is exempt.

	matrix list t
	matrix list oldE
	matrix I1 = J(1,`Nsectors',1)
	matrix list I1
	matrix E = I1 - oldE
	matrix list E

	//Maya: if we have to do this step, which I understand as just swapping the 0s and 1s around, why don't we just set it up this way in the vatparams file from the beginning? 

*-----------------------------------------------------------------------------------------------------                    
** Step 2. Execute the price-shifting model.
*-----------------------------------------------------------------------------------------------------

* Enter Mata where it is easy to do entry-by-entry multiplication which is required for the price shifting model

	matrix list gammaD
	matrix list gammaF
mata:

	E = st_matrix("E")		//vector of exempt scalars, where 1 = not exempt, and 0 = exempt
	t = st_matrix("t")		//vector of statutory rates, where exempt goods are 0
	
	gammaD = st_matrix("gammaD")
	gammaF = st_matrix("gammaF")
	
	tgammaD = t*gammaD
	tgammaF = t*gammaF
	
	EtgammaD = E :* tgammaD
	EtgammaF = E :* tgammaF

	st_matrix("EtgammaD", EtgammaD)
	st_matrix("EtgammaF", EtgammaF)

	st_matrix("tgammaD", tgammaD)
	st_matrix("tgammaF", tgammaF)

end

	matrix list EtgammaD
	matrix list EtgammaF
	* Combine vectors and matrices defined so far to execute price shifting model; the matrix VAT gives effective VAT rates for all sectors
	* The key difference in this model compared to the previous approach is that this only allows for embedded VAT to be present in domestically produced inputs.

	matrix T = (`alpha'*t - `alpha'*EtgammaD + t*gammaF - EtgammaF)*inv(I(`Nsectors') - gammaD)

	matrix list T
	matrix NEW = `alpha'*t				//Compliance rate * Statutory rates
	matrix list NEW
		
		* Calculate final price shock vector by weighting the vector T by the domestic share and the statutory rate vector t by the imported share

mata:

	t = st_matrix("t")
	T = st_matrix("T")
	IMP = st_matrix("IMP")
	DOM = st_matrix("DOM")
	NEW = st_matrix("NEW")

	A = T :* DOM + t :* IMP
	AA = A'
	st_matrix("BASEIO_VAT", AA)
	
	DIR = t:*IMP + NEW:* DOM 			//Direct effects is composed of the statutory rates*imports + statutory rates*alpha*domestic goods
		INDIR = A - DIR
		st_matrix("DIR", DIR)
		st_matrix("INDIR", INDIR)
		
end

	matrix VAT_TOTAL = BASEIO_VAT
	matrix list VAT_TOTAL
	matrix VAT_INDIR = INDIR'
	matrix list VAT_INDIR
	matrix VAT_DIR = DIR'
	matrix list VAT_DIR

matrix list VAT_TOTAL
* [adapt the Excel file name and sheet should you wish to change them]
putexcel set "$gdOut\Effective rates_2.xlsx", sheet("output") modify
putexcel d3 = mat(VAT_TOTAL)

matrix list VAT_INDIR
putexcel set "$gdOut\Effective rates_2.xlsx", sheet("output") modify
putexcel e3 = mat(VAT_INDIR)

matrix list VAT_DIR
putexcel set "$gdOut\Effective rates_2.xlsx", sheet("output") modify
putexcel f3 = mat(VAT_DIR)
	*mat BASEIO_VAT = T'

*-----------------------------------------------------------------------------------------------------                    
** Step 3. Extract final tax rates as scalars from this matrix, numbered according to Benin expenditure categories
*-----------------------------------------------------------------------------------------------------

*[adapt this to reflect the number of IO sectors]
***************************************************************************************************************

foreach num of numlist 1/52{
	scalar VAT_TOTAL`num' = VAT_TOTAL[`num',1]
	scalar VAT_INDIR`num' = VAT_INDIR[`num',1]
	scalar VAT_DIR`num' = VAT_DIR[`num',1]
}

* 2. Generate a variable which contains the effective rate. The effective rate will depend on the IO sector which the good falls into. 
	* Baseline
	use "$gdOut\cons_vat.dta", clear
		
		g effrate = .
		foreach n of numlist 1/52{
		  replace effrate = VAT_TOTAL`n' if io==`n'
		}
		
		g effrate_dir = .
		foreach n of numlist 1/52{
		  replace effrate_dir = VAT_DIR`n' if io==`n'
		}
		
		g effrate_indir = .
		foreach n of numlist 1/52{
		  replace effrate_indir = VAT_INDIR`n' if io==`n'
		}
	
collapse (max)effrate effrate_dir effrate_indir, by(itemid)
save "$gdTemp\vat_item.dta", replace

*************************************************************************
*Adjust to informality rates by-decile and by-good
*Step 1: use the pre-calculated direct and indirect effective VAT rate by-good
use "$gdOut\cons_vat.dta", clear

merge m:1 itemid using "$gdTemp\vat_item.dta", keepusing(effrate effrate_dir effrate_indir)		//This is calculated as a base, with no evasion assumption, at the individual item level. 
drop _merge
merge m:1 hhid using "$gdTemp\yd.dta", keepusing(dec_yd_hh hsize weight)		//household welfare deciles
drop _merge

egen infid = concat(dec_yd_hh io), punct(" ")
sort infid
*Step 2: merge in the matrix of evasion factors by good and by I/O
preserve
import excel using "$io\informality_shares_matrix_CIV21.xlsx", sheet("Evasion_by_good") cellrange(AB1:AL53) firstrow clear	 

rename IOSectors io
rename AC informal1
rename AD informal2
rename AE informal3
rename AF informal4
rename AG informal5
rename AH informal6
rename AI informal7
rename AJ informal8
rename AK informal9
rename AL informal10
reshape long informal, i(io) j(decile)
egen infid = concat(decile io), punct(" ")
sort infid
tempfile informal
save `informal'
restore

merge m:1 infid using `informal', keepusing(informal)
drop _merge
drop if itemid==.
*replace effrate_dir = .18 if effrate_dir!=0 & effrate_dir!=.18			//for some reason there were standard rated goods that had values of .18 but were not counted as such. 


*Step 3: generate formal and informal shares of expenditure
g formal_exp = cons_val * informal		//the "informal" variable is the evasion factor, so .13 means 87% of expenditure is informal
g inform_exp = cons_val * (1-informal)

*Step 4: estimate VAT charge on each type of good in each decile
g vat_form_dir = effrate_dir*formal_exp/(1+effrate_dir)
g vat_form_indir = effrate_indir*formal_exp/(1+effrate_indir)

g vat_infor_dir = informal*0					//has no VAT charge because it is all informal purchases
g vat_infor_indir = effrate_indir*inform_exp	//carries embedded VAT of formally-purchased inputs

egen itx_vatx_hh = rowtotal(vat_form_dir vat_form_indir vat_infor_dir vat_infor_indir)
egen itx_dvat_hh = rowtotal(vat_form_dir vat_infor_dir)
egen itx_ivat_hh = rowtotal(vat_form_indir vat_infor_indir)

egen vat_elec = rowtotal(vat_form_dir vat_form_indir vat_infor_dir vat_infor_indir) if itemid==334		//For use in electricity subsidy calculation

	collapse (sum) cons_val itx_vatx_hh itx_dvat_hh itx_ivat_hh vat_elec (max)hsize, by(hhid weight)    			 
	lab var itx_vatx_hh "vat, hh"
	lab var itx_dvat_hh "vat, hh (direct effects)"
	lab var itx_ivat_hh "vat, hh (indirect effects)"
	
	g itx_vatx_rh = 0
	replace itx_vatx_rh= 1 if itx_vatx_hh>0 | itx_vatx_hh!=.
	lab var itx_vatx_rh "vat-paying household"

save "$gdTemp\vat_final.dta", replace

