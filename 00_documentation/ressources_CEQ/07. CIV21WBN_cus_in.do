*******************************************************************************************************
* Cote d'Ivoire 2021
* Ian Houts
* 3 Dec 2023

* Purpose: Calculate the customs tariffs on purchases
*******************************************************************************************************

clear all
set more off 
set type double 

global CUSIO1    = 0.36     //Customs tariff rate for FOOD AGRICULTURE PRODUCTS_35
global CUSIO2    = 0.21     //Customs tariff rate for FOOD AGRICULTURE PRODUCTS_20
global CUSIO3    = 0.11     //Customs tariff rate for FOOD AGRICULTURE PRODUCTS_10
global CUSIO4    = 0.06     //Customs tariff rate for FOOD AGRICULTURE PRODUCTS_5
global CUSIO5    = 0.00     //Customs tariff rate for FOOD AGRICULTURE PRODUCTS_0
global CUSIO6    = 0.21     //Customs tariff rate for AGRICULTURAL PRODUCTS INTENDED PRIMARILY FOR
global CUSIO7    = 0.06     //Customs tariff rate for LIVESTOCK AND HUNTING PRODUCTS
global CUSIO8    = 0.21     //Customs tariff rate for AGRICULTURE AND EL SUPPORT SERVICES
global CUSIO9    = 0.21     //Customs tariff rate for FORESTRY AND logging PRODUCTS
global CUSIO10   = 0.21     //Customs tariff rate for FISHING, PISCULTURE AND AQUACULT PRODUCTS_20
global CUSIO11   = 0.11     //Customs tariff rate for FISHING, PISCULTURE AND AQUACULT PRODUCTS_10
global CUSIO12   = 0.06     //Customs tariff rate for PRODUCTS FROM THE EXTRACTIVE INDUSTRIES
global CUSIO13   = 0.36     //Customs tariff rate for MEAT, MEAT PRODUCTS AND PRODUCTS_35
global CUSIO14   = 0.21     //Customs tariff rate for MEAT, MEAT PRODUCTS AND PRODUCTS_20
global CUSIO15   = 0.36     //Customs tariff rate for Fats and oils_35
global CUSIO16   = 0.21     //Customs tariff rate for Fats and oils_20
global CUSIO17   = 0.11     //Customs tariff rate for Fats and oils_10
global CUSIO18   = 0.21     //Customs tariff rate for PRODUCT OF GRAIN WORK AND AMY PRODUCTS_20
global CUSIO19   = 0.00     //Customs tariff rate for PRODUCT OF GRAIN WORK AND AMY PRODUCTS_0
global CUSIO20   = 0.21     //Customs tariff rate for BREAD, PASTRY AND PASTA
global CUSIO21   = 0.36     //Customs tariff rate for COCOA, COFFEE AND PROCESSING PRODUCTS_35
global CUSIO22   = 0.11     //Customs tariff rate for COCOA, COFFEE AND PROCESSING PRODUCTS_10
global CUSIO23   = 0.36     //Customs tariff rate for OTHER FOOD PRODUCTS_35
global CUSIO24   = 0.21     //Customs tariff rate for OTHER FOOD PRODUCTS_20
global CUSIO25   = 0.11     //Customs tariff rate for OTHER FOOD PRODUCTS_10
global CUSIO26   = 0.06     //Customs tariff rate for OTHER FOOD PRODUCTS_5
global CUSIO27   = 0.36     //Customs tariff rate for DRINKS_35
global CUSIO28   = 0.21     //Customs tariff rate for DRINKS_20
global CUSIO29   = 0.11     //Customs tariff rate for DRINKS_10
global CUSIO30   = 0.21     //Customs tariff rate for CIGARETTES AND OTHER TOBACCO PRODUCTS
global CUSIO31   = 0.21     //Customs tariff rate for TEXTILE AND APPAREL INDUSTRIES
global CUSIO32   = 0.21     //Customs tariff rate for WORKED LEATHER; TRAVEL ITEMS; SHOE
global CUSIO33   = 0.06     //Customs tariff rate for WOOD, WOODEN OR BASKETWARE ARTICLES
global CUSIO34   = 0.21     //Customs tariff rate for PAPER AND CARDBOARD INDUSTRY PRODUCTS_20
global CUSIO35   = 0.11     //Customs tariff rate for PAPER AND CARDBOARD INDUSTRY PRODUCTS_10
global CUSIO36   = 0.00     //Customs tariff rate for REFINING PRODUCTS_20
global CUSIO37   = 0.00     //Customs tariff rate for REFINING PRODUCTS_5
global CUSIO38   = 0.21     //Customs tariff rate for CHEMICALS AND PHARMACEUTICALS_20
global CUSIO39   = 0.11     //Customs tariff rate for CHEMICALS AND PHARMACEUTICALS_10
global CUSIO40   = 0.06     //Customs tariff rate for CHEMICALS AND PHARMACEUTICALS_5
global CUSIO41   = 0.21     //Customs tariff rate for RUBBER OR PLASTIC PRODUCTS
global CUSIO42   = 0.21     //Customs tariff rate for NON-METALLIC MINERAL PRODUCTS
global CUSIO43   = 0.21     //Customs tariff rate for METALLURGICAL PRODUCTS; METAL WORKS
global CUSIO44   = 0.21     //Customs tariff rate for ELECTRONIC AND COMPUTER PRODUCTS
global CUSIO45   = 0.21     //Customs tariff rate for ELECTRICAL EQUIPMENT AND MATERIALS
global CUSIO46   = 0.21     //Customs tariff rate for MACHINERY AND EQUIPMENT N.E.C.
global CUSIO47   = 0.21     //Customs tariff rate for TRANSPORT EQUIPMENT_20
global CUSIO48   = 0.11     //Customs tariff rate for TRANSPORT EQUIPMENT_10
global CUSIO49   = 0.21     //Customs tariff rate for FURNITURE, MISCELLANEOUS PRODUCTS
global CUSIO50   = 0.00     //Customs tariff rate for REPAIR AND INSTALLATION OF MACHINERY AND
global CUSIO51   = 0.00     //Customs tariff rate for ELECTRICITY PRODUCTION, DISTRIBUTION AND
global CUSIO52   = 0.00     //Customs tariff rate for PRODUCTION AND DISTRIBUTION OF WATER, SANITATION
global CUSIO53   = 0.21     //Customs tariff rate for CONSTRUCTION WORKS_20
global CUSIO54   = 0.00     //Customs tariff rate for CONSTRUCTION WORKS_0
global CUSIO55   = 0.21     //Customs tariff rate for TRADE_20
global CUSIO56   = 0.11     //Customs tariff rate for TRADE_10
global CUSIO57   = 0.06     //Customs tariff rate for TRADE_5
global CUSIO58   = 0.00     //Customs tariff rate for TRANSPORTATION AND WAREHOUSE SERVICES
global CUSIO59   = 0.00     //Customs tariff rate for ACCOMMODATION AND FOOD SERVICES
global CUSIO60   = 0.00     //Customs tariff rate for INFORMATION AND COMMUNICATION SERVICES
global CUSIO61   = 0.00     //Customs tariff rate for FINANCIAL AND INSURANCE SERVICES
global CUSIO62   = 0.00     //Customs tariff rate for REAL ESTATE SERVICES
global CUSIO63   = 0.00     //Customs tariff rate for SPECIALIZED, SCIENTIFIC AND TECH ACTIVITIES
global CUSIO64   = 0.00     //Customs tariff rate for SUPPORT AND OFFICE SERVICES ACTIVITIES
global CUSIO65   = 0.00     //Customs tariff rate for PUBLIC ADMINISTRATION SERVICES
global CUSIO66   = 0.00     //Customs tariff rate for EDUCATION
global CUSIO67   = 0.21     //Customs tariff rate for HUMAN HEALTH AND SOCIAL ACTION SERVICES_20
global CUSIO68   = 0.00     //Customs tariff rate for HUMAN HEALTH AND SOCIAL ACTION SERVICES_0
global CUSIO69   = 0.00     //Customs tariff rate for COLLECTIVE, SOCIAL AND PERSONAL SERVICES
global CUSIO70   = 0.21     //Customs tariff rate for OTHER SERVICE ACTIVITIES N.E.C._20
global CUSIO71   = 0.00     //Customs tariff rate for OTHER SERVICE ACTIVITIES N.E.C._0
global CUSIO72   = 0.00     //Customs tariff rate for ACTIVITY OF HOUSEHOLDS AS EMPLOYERS OF
global CUSIO73   = 0.00     //Customs tariff rate for TERRITORIAL CORRECTION


** Read in for Cote d'Ivoire, the:
* 1. Leontief import (gammaF) matrix 
* 2. Leontief domestic (gammaD) matrix, 
* 3. Imported share of inputs
* 4. Domestic share of inputs 
**************************************************
*1. Matrix of domestic Leontief coefficients
**************************************************
  * 1a. import the spreadsheet as a list of variables 
  
  import excel using "$io\CIV21_AugIO.xlsx", sheet("CusL") cellrange(B156:BW229) firstrow clear	
  
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
  
import excel using "$io\CIV21_AugIO.xlsx", sheet("CusL") cellrange(B79:BW152) firstrow clear		

  * 2b. turn the variables into one big matrix stored in Stata's memory with the name gammaF
  mkmat `sectors', matrix(gammaF)	

*********************************************************
*3. Share of imported components in each good / service
*********************************************************
  * 3a. import the imported share column as a variable
  * [Adapt the name of the Excel spreadsheet, the Excel sheet, and the cellrange]
  import excel using "$io\CIV21_AugIO.xlsx", sheet("CusL") cellrange(BY2:BY75) firstrow clear   
  
  * 3b. turn the variable into a column vector stored in Stata's memory with the name IMP for imported
  mkmat impsh, matrix(IMP)	

  * 3c. turn the column vector into a row vector for conformability reasons in the do_iovat.do file
  matrix IMP = IMP'         

*********************************************************
*4. Share of domestic components in each good / services
*********************************************************
  * 4a. import the domestic share column as a variable
  * [Adapt the name of the Excel spreadsheet, the Excel sheet, and the cellrange]
  import excel using "$io\CIV21_AugIO.xlsx", sheet("CusL") cellrange(BZ2:BZ75) firstrow clear	

  * 4b. turn the variable into a column vector stored in Stata's memory with the name DOM for domestic
  mkmat domsh, matrix(DOM)	

  * 3c. turn the column vector into a row vector for conformability reasons in the do_iovat.do file
  matrix DOM = DOM'         
	
	
	
*************************************************************************************************************
*PARAMETERS
*************************************************************************************************************
*******************************************************************************************************

*** Number of IO sectors in the Augmented IO table:
scalar NUMGOODS = 73


**************************************************************************************************
*** BASELINE
**************************************************************************************************

**** IO sectors that are exempt: //calling all sectors exempt because there is no refundable mechanism for customs tariffs, and all tariffs are assumed to pass on as price increases for consumers. 

 *global exemptions_1 ""
					  						
local z = NUMGOODS

	
* The user should edit these Custom Duty rates so that they represent the reform system to be simulated.
*****************************************************************************************************

* Cote d'Ivoire Augmented IO sectors				// We are using statutory rates:
* Vector 1 will be used for direct effects on imports, where custom tariff rates have been mapped to each good (source: TARIF EXTERIEUR COMMUN de l’Union Economique et Monétaire Ouest Africaine)
* Vector 2 will be used for indirect effects on domestic inputs, where each rate corresponds with the input or intermediate good tariff category
* Vector 3 is a check to see if the indirect effects on domestic inputs should be direct effects on domestic inputs , as a 10% direct tax on final domestic goods

*Vector 1: Statutory rates + statistical fees (1%)
scalar CUS1  =  $CUSIO1 
scalar CUS2  =  $CUSIO2  
scalar CUS3  =  $CUSIO3  
scalar CUS4  =  $CUSIO4  
scalar CUS5  =  $CUSIO5  
scalar CUS6  =  $CUSIO6  
scalar CUS7  =  $CUSIO7  
scalar CUS8  =  $CUSIO8  
scalar CUS9  =  $CUSIO9 
scalar CUS10 =  $CUSIO10
scalar CUS11 =  $CUSIO11 
scalar CUS12 =  $CUSIO12 
scalar CUS13 =  $CUSIO13 
scalar CUS14 =  $CUSIO14 
scalar CUS15 =  $CUSIO15 
scalar CUS16 =  $CUSIO16 
scalar CUS17 =  $CUSIO17 
scalar CUS18 =  $CUSIO18 
scalar CUS19 =  $CUSIO19 
scalar CUS20 =  $CUSIO20 
scalar CUS21 =  $CUSIO21
scalar CUS22 =  $CUSIO22 
scalar CUS23 =  $CUSIO23
scalar CUS24 =  $CUSIO24 
scalar CUS25 =  $CUSIO25
scalar CUS26 =  $CUSIO26
scalar CUS27 =  $CUSIO27
scalar CUS28 =  $CUSIO28
scalar CUS29 =  $CUSIO29
scalar CUS30 =  $CUSIO30
scalar CUS31 =  $CUSIO31
scalar CUS32 =  $CUSIO32
scalar CUS33 =  $CUSIO33
scalar CUS34 =  $CUSIO34
scalar CUS35 =  $CUSIO35
scalar CUS36 =  $CUSIO36
scalar CUS37 =  $CUSIO37
scalar CUS38 =  $CUSIO38
scalar CUS39 =  $CUSIO39
scalar CUS40 =  $CUSIO40
scalar CUS41 =  $CUSIO41
scalar CUS42 =  $CUSIO42
scalar CUS43 =  $CUSIO43
scalar CUS44 =  $CUSIO44
scalar CUS45 =  $CUSIO45
scalar CUS46 =  $CUSIO46
scalar CUS47 =  $CUSIO47
scalar CUS48 =  $CUSIO48
scalar CUS49 =  $CUSIO49
scalar CUS50 =  $CUSIO50
scalar CUS51 =  $CUSIO51
scalar CUS52 =  $CUSIO52
scalar CUS53 =  $CUSIO53
scalar CUS54 =  $CUSIO54
scalar CUS55 =  $CUSIO55
scalar CUS56 =  $CUSIO56
scalar CUS57 =  $CUSIO57
scalar CUS58 =  $CUSIO58
scalar CUS59 =  $CUSIO59
scalar CUS60 =  $CUSIO60
scalar CUS61 =  $CUSIO61
scalar CUS62 =  $CUSIO62
scalar CUS63 =  $CUSIO63
scalar CUS64 =  $CUSIO64
scalar CUS65 =  $CUSIO65
scalar CUS66 =  $CUSIO66
scalar CUS67 =  $CUSIO67
scalar CUS68 =  $CUSIO68
scalar CUS69 =  $CUSIO69
scalar CUS70 =  $CUSIO70
scalar CUS71 =  $CUSIO71
scalar CUS72 =  $CUSIO72
scalar CUS73 =  $CUSIO73


*****************************************************************************************************
*"do_iocus.do"
*****************************************************************************************************

*-----------------------------------------------------------------------------------------------------                    
** Step 1. Set up the tax rates to be used in the I-O analysis
*-----------------------------------------------------------------------------------------------------
	* Specify dimensions of Leontief
	local Nsectors = rowsof(gammaD)	
	disp `Nsectors'

	* Create matrices of CUS rates and exemptions, where ordering aligns with SAM

	matrix t = (CUS1)
	foreach i of numlist 2/`Nsectors' {
		matrix t = (t,CUS`i')
	}

* Create an identify matrix of 1s 
	matrix I1 = I(`Nsectors')
	

*-----------------------------------------------------------------------------------------------------                    
** Step 2. Execute the price-shifting model.
*-----------------------------------------------------------------------------------------------------


/* Combine vectors and matrices defined so far to execute price shifting model; the matrix CUS gives effective CUS rates 
	for all sectors. 
		* The key difference in this model compared to the previous approach is that this only allows 
				for embedded CUS to be present in domestically produced inputs. */
	mat tgammaF = t*gammaF
	mat I1gammaD = I(`Nsectors') - gammaD
	mat list tgammaF
	mat list I1gammaD


	matrix T = tgammaF*inv(I(`Nsectors') - gammaD)


* Calculate final price shock vector my weighting the vector T by the domestic share and the statutory rate vector t by the imported share
	* Enter Mata where it is easy to do entry-by-entry multiplication which is required for the price shifting model

mata:

	t = st_matrix("t")
	T = st_matrix("T")
	IMP = st_matrix("IMP")
	DOM = st_matrix("DOM")

	A = T :* DOM + t :* IMP
	AA = A'

	DIR = t :* IMP
	DIR = DIR'
	IND = T :* DOM   
	IND = IND'

	st_matrix("IO_CUS", AA)
    st_matrix("DIR_CUS", DIR)
    st_matrix("IND_CUS", IND)

end
//Direct effects is composed of the statutory rates * imports + statutory rates * alpha * domestic goods

matrix list IO_CUS
matrix list DIR_CUS
matrix list IND_CUS


putexcel set "$gdOut\cus_effrates.xlsx", sheet("effrates") modify
putexcel d2 = mat(IO_CUS)
putexcel e2 = mat(DIR_CUS)
putexcel f2 = mat(IND_CUS)


*-----------------------------------------------------------------------------------------------------                    
** Step 3. Extract final tax rates as scalars from this matrix, numbered according to ZAFTAX expenditure categories
* Note: we have matched the CIV IO with the Cote d'Ivoire tax expenditure categories, so these are the same for us
*-----------------------------------------------------------------------------------------------------
	
	foreach s of numlist 1/`Nsectors'{
		scalar IO_CUS`s'  = IO_CUS[`s',1]
		scalar DIR_CUS`s' = DIR_CUS[`s',1]
		scalar IND_CUS`s' = IND_CUS[`s',1]
	}
	
* Generate a variable which contains the effective rate. The effective rate will depend on the IO sector which the good falls into. 
	* Baseline
use "$gdOut\cons_cus.dta", clear


g effrate = .
		foreach n of numlist 1/73{
		  replace effrate = IO_CUS`n' if cusio==`n'
		}
		
		g effrate_dir = .
		foreach n of numlist 1/73{
		  replace effrate_dir = DIR_CUS`n' if cusio==`n'
		}
		
		g effrate_indir = .
		foreach n of numlist 1/73{
		  replace effrate_indir = IND_CUS`n' if cusio==`n'
		}
	
* 3. Calculate customs tariffs
	* Baseline
	
		g double customs = 0
		replace customs = cons_val/(1+effrate)*effrate   
		
	*Direct & indirect (estimate)
		g double cus_dir = 0
		replace cus_dir = cons_val/ (1+effrate_dir)*effrate_dir
		
		g double cus_indir = 0
		replace cus_indir = cons_val/ (1+effrate_indir)*effrate_indir

	
* 4. Calculate totals for direct and indirect effects

	rename customs itx_cust_hh
	rename cus_dir itx_dcus_hh
	rename cus_indir itx_icus_hh
		
* 5. Collapse the dataset and merge the weights, and official consumption in
	collapse (sum) cons_val itx_cust_hh itx_dcus_hh itx_icus_hh, by(hhid weight)  
	
g itx_cust_rh = (itx_cust_hh>0 & itx_cust_hh!=.)
	
	
		save "$gdTemp\customs_final.dta", replace
