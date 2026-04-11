*Direct Taxes
*Nov 15 2021
*Ian Houts
*Part 3: remove CN and IS taxes and reductions to gross income 

clear all
set more off
set type double

global igr_1	 75000		//General Income Tax bracket 1, upper bound (taxable base, monthly XOF)
global igr_2     240000		//General Income Tax bracket 2, upper bound (taxable base, monthly XOF)
global igr_3     800000     //General Income Tax bracket 3, upper bound (taxable base, monthly XOF)
global igr_4     2400000  	//General Income Tax bracket 4, upper bound (taxable base, monthly XOF)
global igr_5     8000000  	//General Income Tax bracket 5, upper bound (taxable base, monthly XOF)

global igrrate_1  0			//General Income Tax bracket 1, rate (percentage)
global igrrate_2  .16		//General Income Tax bracket 2, rate (percentage)
global igrrate_3  .21		//General Income Tax bracket 3, rate (percentage)
global igrrate_4  .24		//General Income Tax bracket 4, rate (percentage)
global igrrate_5  .28		//General Income Tax bracket 5, rate (percentage)
global igrrate_6  .32		//General Income Tax bracket 6, rate (percentage)

global part	5500			//General Income Tax deduction per 0.5 family quotient (monthly XOF)

global ibic1	500000000	//Business Income Tax normal tax regime lower threshold (turnover, annual XOF)
global ibic2	200000000	//Business Income Tax simplified tax regime lower threshold (turnover, annual XOF)
global ibic3	5000000		//Business Income Tax synthetic tax regime lower threshold (turnover, annual XOF)
global ibicrate1  .25		//Business Income Tax: ordinary tax rate for normal regoime (percentage)
global ibicrate2  .25		//Business Income Tax: ordinary tax rate for simplified regime (percentage)
global ibicrate3  .06		//Business Income Tax: ordinary tax rate for synthetic regime (percentage)
global ibicrate4  .05		//Business Income Tax: ordinary tax rate for entrepreneur regime (percentage)
global ibicmin	  .05		//Business Income Tax: minimum tax rate (percentage)

global proptax1 = 0.09		//Property Tax: tax rate on rental value of income-earning properties owned by individuals (%)
global proptax2 = 0.03		//Property Tax: tax rate on rental value of properties owned by indivuduals, primary residence or first secondary (%)

global natconB   .015		//National Contribution -employer- rate (percentage)
global pyrl_app  .005		//Apprenticeship tax (percentage)
global pyrl_prof .015 		//Professional training tax (percentage)
global pyrl_nr   .115		//Salary tax on expatriate employees (percentage)

global famallowance .0575	//Rate of salary contribution to social security: Family Allowance (percentage)
global industaccid  .035	//Rate of salary contribution to social security: Industrial Accident Fund (percentage)
global cnpspension  .14		//Rate of salary contribution to social security: CNPS retirement pension (percentage)
global minwage		60000	//Minimum wage for mandatory contributions to social security (annual XOF)
global maxconfam	70000	//Maximum monthly contribution to social security: Family Allowance (monthly XOF)
global maxconind 	70000	//Maximum monthly contribution to social security: Industrial Accident Fund (monthly XOF)
global maxconpen  3375000	//Maximum monthly contribution to social security: CNPS retirement pension (monthly XOF)

global renttax		.03		//Tax rate on annual rental income for individuals (percentage)
global captax		.15		//Tax rate on annual capital income for individuals (percentage)

use "$gdOut\dtx_base.dta", clear

*OPTION 2: Assignment of statutory rates
*General Income Tax (IGR)

g TI = GI

/*
NEW REFORM PROPOSAL:
							
From 			To			Net Tax		-   (Reduction*N)
        0	   75,000			0		-	5,500*N
   75,001	  240,000			16%		-	5,500*N		(max annual:  2,880,000 - 900,000 = 1,980,000*.16 = 316,800)
  240,001	  800,000 			21%		-	5,500*N		(max:  1,411,200)
  800,001	2,400,000			24%		-	5,500*N		(max:  4,608,000)
2,400,001	8,000,000			28%		-	5,500*N		(max: 18,816,000)
8,000,001					    32%		-	5,500*N

Parts	Month	Annual
1         0         0
1,5   5 500    66 000
2    11 000   132 000
2,5  16 500   198 000
3    22 000   264 000
3,5  27 500   330 000
4    33 000   396 000
4,5  38 500   462 000
5    44 000   528 000

*/

g depchild = (age<18 & mstat==1)
bysort hhid: egen children = sum(depchild)
replace part = 1 if age>=18 & (mstat==1 | mstat==4 | mstat==7) & children==0 & TI>0		//single or free union or separated with no dependents
replace part = 1.5 if age>18 & (mstat==5 | mstat==6) & children==0 & TI>0				//widowed or divorced with no dependents
replace part = 2 if age>18 & (mstat==2 | mstat==3) & children==0 & TI>0					//married no dependents
replace part = 2 if age>=18 & (mstat==1 | mstat==6) & children==1 & TI>0				//single or divorced 1 dependent
replace part = 2.5 if age>18 & (mstat==2 | mstat==3 | mstat==5) & children==1 & TI>0	//married or widowed 1 dependent
replace part = 2.5 if age>=18 & (mstat==1 | mstat==6) & children==2 & TI>0				//single or divorced 2 dependents
replace part = 3 if age>18 & (mstat==2 | mstat==3 | mstat==5) & children==2 & TI>0		//married or widowed 2 dependents
replace part = 3 if age>=18 & (mstat==1 | mstat==6) & children==3 & TI>0				//single or divorced 3 dependents
replace part = 3.5 if age>18 & (mstat==2 | mstat==3 | mstat==5) & children==3 & TI>0	//married or widowed 3 dependents
replace part = 3.5 if age>=18 & (mstat==1 | mstat==6) & children==4 & TI>0				//single or divorced 4 dependents
replace part = 4 if age>18 & (mstat==2 | mstat==3 | mstat==5) & children==4 & TI>0		//married or widowed 4 dependents
replace part = 4 if age>=18 & (mstat==1 | mstat==6) & children==5 & TI>0				//single or divorced 5 dependents
replace part = 4.5 if age>18 & (mstat==2 | mstat==3 | mstat==5) & children==5 & TI>0	//married or widowed 5 dependents
replace part = 4.5 if age>=18 & (mstat==1 | mstat==6) & children==6 & TI>0				//single or divorced 6 dependents
replace part = 5 if age>18 & (mstat==2 | mstat==3 | mstat==5) & children>=6 & TI>0		//married or widowed 6+ dependents
replace part = 5 if age>=18 & (mstat==1 | mstat==6) & children>=7 & TI>0				//single or divorced 7+ dependents
bysort hhid: egen Npart = max(part)

preserve
	collapse (sum) TI (max)Npart hsize, by(hhid weight)

	g 		tax_IGR= 0
	*		Are the family quotient deductions which take the place of the predetermined variable meant to function the same way as the baseline variables? As in, will a household pay tax at a predetermined rate for their entire income?
	replace tax_IGR= ( $igrrate_2  * (TI - ($igr_1 *12 ))) if TI >= (($igr_1 *12) + 1) & TI < ($igr_2 *12)   
	replace tax_IGR= ( $igrrate_3  * (TI - ($igr_2 *12 ))) + (( ($igr_2 *12) - ( $igr_1 *12) )* $igrrate_2 )  if TI >= (($igr_2 *12) + 1) & TI < ($igr_3 *12)   
	replace tax_IGR= ( $igrrate_4  * (TI - ($igr_3 *12 ))) + (( ($igr_3 *12) - ( $igr_2 *12) )* $igrrate_3 ) + (( ($igr_2 *12) - ( $igr_1 *12) )* $igrrate_2 )  if TI >= (($igr_3 *12) + 1) & TI < ($igr_4 *12)   
	replace tax_IGR= ( $igrrate_5  * (TI - ($igr_4 *12 ))) + (( ($igr_4 *12) - ( $igr_3 *12) )* $igrrate_4 ) + (( ($igr_3 *12) - ( $igr_2 *12) )* $igrrate_3 ) + (( ($igr_2 *12) - ( $igr_1 *12) )* $igrrate_2 )  if TI >= (($igr_4 *12) + 1) & TI < ($igr_5 *12)   
	replace tax_IGR= ( $igrrate_6  * (TI - ($igr_5 *12 ))) + (( ($igr_5 *12) - ( $igr_4 *12) )* $igrrate_5 ) + (( ($igr_4 *12) - ( $igr_3 *12) )* $igrrate_4 ) + (( ($igr_3 *12) - ( $igr_2 *12) )* $igrrate_3 ) + (( ($igr_2 *12) - ( $igr_1 *12) )* $igrrate_2 )  if TI >= ($igr_5 *12) 


	g 		tax_bracket= 0
	*		Are the family quotient deductions which take the place of the predetermined variable meant to function the same way as the baseline variables? As in, will a household pay tax at a predetermined rate for their entire income?
	replace tax_bracket= 1 if TI <= ($igr_1 *12)
	replace tax_bracket= 2 if TI >= (($igr_1 *12) + 1) & TI <= ($igr_2 *12)   
	replace tax_bracket= 3 if TI >= (($igr_2 *12) + 1) & TI <= ($igr_3 *12)   
	replace tax_bracket= 4 if TI >= (($igr_3 *12) + 1) & TI <= ($igr_4 *12)   
	replace tax_bracket= 5 if TI >= (($igr_4 *12) + 1) & TI <= ($igr_5 *12)   
	replace tax_bracket= 6 if TI >= ($igr_5 *12) 

	count if tax_bracket==0
	count if tax_IGR<0
	replace tax_IGR=0 if tax_IGR<0
	replace tax_bracket = 1 if tax_bracket==0


	*IGR reductions
	replace tax_IGR = tax_IGR - ( $part * 1 * 12) if Npart==1.5 & tax_IGR>0
	replace tax_IGR = tax_IGR - ( $part * 2 * 12) if Npart==2   & tax_IGR>0
	replace tax_IGR = tax_IGR - ( $part * 3 * 12) if Npart==2.5 & tax_IGR>0
	replace tax_IGR = tax_IGR - ( $part * 4 * 12) if Npart==3   & tax_IGR>0
	replace tax_IGR = tax_IGR - ( $part * 5 * 12) if Npart==3.5 & tax_IGR>0
	replace tax_IGR = tax_IGR - ( $part * 6 * 12) if Npart==4   & tax_IGR>0
	replace tax_IGR = tax_IGR - ( $part * 7 * 12) if Npart==4.5 & tax_IGR>0
	replace tax_IGR = tax_IGR - ( $part * 8 * 12) if Npart==5   & tax_IGR>0

	rename tax_IGR dtx_igrx_hh
	replace dtx_igrx_hh=0 if dtx_igrx_hh<0

	tempfile IGR
	save `IGR', replace
restore

*******************************************************************************************************************
*Payroll Tax
/*
11.5% on salaries of expatriate staff
1.5% national contribution for all staff
0.5% apprenticeship tax on all staff
1.5% professional training tax for all staff
*/
replace dtx_pyrl_pc = GI*( $pyrl_app + $pyrl_prof ) if resid==1
replace dtx_pyrl_pc = GI*( $pyrl_nr + $pyrl_app + $pyrl_prof ) if resid==0
g con_natn_pc  = GI*( $natconB )
replace con_natn_pc  = 0 if con_natn_pc ==.
g dtx_pyrl_ri = (dtx_pyrl_pc>0 & dtx_pyrl_pc!=.)


save "$gdTemp\02.test03.dta", replace

*************************************************************************************
/*Business income
*	normal tax regime: 		  above F.CFA 500 million (all taxes included);
*	simplified tax regime: 	  between F.CFA 200 million and F.CFA 500 million (all taxes included);
*	synthetic tax regime: 	  between F.CFA 5 million and F.CFA 200 million (all taxes included) (see section 3.2.).
*	entrepreneur regime		  under 50 million
*inc_30d = turnover
*inc_self = profit
*/

g regime_1 = (inc_30d> $ibic1 & inc_30d!=.)
g regime_2 = (inc_30d>= $ibic2 & inc_30d<= $ibic1 & inc_30d!=.)
g regime_3 = (inc_30d>= $ibic3 & inc_30d< $ibic2 & inc_30d!=.)
g regime_4 = (inc_30d< $ibic3 & inc_30d!=.)

replace dtx_ibic_pc = inc_30d* $ibicrate1 if regime_1==1 
replace dtx_ibic_pc = inc_30d* $ibicrate2 if regime_2==1	
replace dtx_ibic_pc = inc_30d* $ibicrate3 if regime_3==1				//micro-enterprise and SMEs fall under the synthetic tax?
replace dtx_ibic_pc = inc_30d* $ibicrate4 if regime_4==1
replace dtx_ibic_pc = inc_30d* $ibicmin if dtx_ibic_pc< (inc_30d* $ibicmin ) & (regime_1==1 | regime_2==1 | regime_3==1 | regime_4==1)		//minimum tax

replace dtx_ibic_pc = 0 if dtx_ibic_pc> inc_self  //Assume that if the tax on turnover ends up higher than the profits a business makes, they are avoiding these taxes. 


*Rental Income
replace dtx_rent_pc = inc_rent* $renttax if inc_rent>0		//rental income is taxed at 3% for individual rental income

*Movable Capital Income
replace dtx_capt_pc = inc_capt* $captax if inc_capt>0 		//movable capital income is taxed at a flat 15% on shares, dividends and bonds


**********************
*National Contribution
replace con_fama_pc = GI* $famallowance  if GI> $minwage
replace con_fama_pc = $maxconfam *12 if con_fama_pc > ($maxconfam *12)		//Family allowance contribution is capped at 70k per month
replace con_inda_pc = GI* $industaccid   if GI> $minwage	
replace con_inda_pc = $maxconind *12 if con_inda_pc > ($maxconind *12)
replace cpn_cnps_pc = GI* $cnpspension   if GI> $minwage
replace cpn_cnps_pc = $maxconpen *12 if cpn_cnps_pc > ($maxconpen *12)	//Pension contributions capped at 2.7m per month


***********************************************
*Property Tax
replace dtx_prop_pc1 = inc_rent* $proptax1 if propown_lord==1
replace dtx_prop_pc2 = imprent*  $proptax2
replace dtx_prop_pc2 = dtx_prop_pc2*0.5 if s11q04==3 | s11q04==4		//assume any joint ownership of properties shares tax burden. 

egen dtx_prop_pc = rowtotal(dtx_prop_pc1 dtx_prop_pc2)
drop if weight==.
save "$gdTemp\dtx_ind.dta", replace


****************************************************************************************************

collapse (sum) dtx_pyrl_hh=dtx_pyrl_pc dtx_ibic_hh=dtx_ibic_pc dtx_rent_hh=dtx_rent_pc dtx_prop_hh=dtx_prop_pc dtx_capt_hh=dtx_capt_pc con_natn_hh=con_natn_pc con_fama_hh=con_fama_pc con_inda_hh=con_inda_pc cpn_cnps_hh=cpn_cnps_pc (max) dtx_pyrl_rh = dtx_pyrl_ri (max)hsize, by(hhid weight)

merge 1:1 hhid using `IGR', keepusing(dtx_igrx_hh)
drop _merge

g dtx_igrx_pc = dtx_igrx_hh/hsize
g dtx_pyrl_pc = dtx_pyrl_hh/hsize
g dtx_ibic_pc = dtx_ibic_hh/hsize
g dtx_rent_pc = dtx_rent_hh/hsize
g dtx_capt_pc = dtx_capt_hh/hsize
g dtx_prop_pc = dtx_prop_hh/hsize

g con_natn_pc = con_natn_hh/hsize
g con_fama_pc = con_fama_hh/hsize
g con_inda_pc = con_inda_hh/hsize
g cpn_cnps_pc = cpn_cnps_hh/hsize

*drop outlier
replace dtx_ibic_pc = 0 if dtx_ibic_pc>15000000		//just taking one observation off the top
replace dtx_ibic_hh = 0 if dtx_ibic_hh==1050000000

egen con_totl_pc = rowtotal(con_natn_pc cpn_cnps_pc)
egen con_totl_hh = rowtotal(con_natn_hh cpn_cnps_hh)
egen dtx_pitx_pc = rowtotal(dtx_igrx_pc dtx_ibic_pc dtx_rent_pc dtx_capt_pc)
egen dtx_pitx_hh = rowtotal(dtx_igrx_hh dtx_ibic_hh dtx_rent_hh dtx_capt_hh)

rename con_fama_* dtx_fama_*		//calling these taxes now, and their benefits direct transfers
rename con_inda_* dtx_indu_*



save "$gdTemp\dtx_final.dta", replace

