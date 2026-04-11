*  2021
* Ian Houts 
* All results  
* Date: 3 Jan 2023

foreach zz in pc {					//pa
	foreach sc in pdi{				//pgt
		foreach yr in 2017 {		//2011 2005

cap log close
set more off
clear all

use "$gdOut\CIV21WBN_ceqincome.dta", clear

*egen itx_fuel_totl_`zz' = rowtotal(itx_vatx_fuel_`zz' itx_fuel_`zz' itx_cust_fuel_`zz')
*lab var itx_fuel_totl_`zz' "Total fuel tax, pc"

*ceqppp2017, country("civ") base(2017) survey(2021) locals	
		loc ppp = 	247.13443   //243.46086
		loc cpibase = 112.45198		//104.91243
		loc cpisurvey = 118.99111	//118.99111

loc ppplist2017 ppp(`ppp') cpibase(`cpibase') cpisurvey(`cpisurvey')
svyset psu [pw=weight]
loc surveylist hsize(hsize) psu(psu)
loc povlist2017 pl1(2.15) pl2(3.65) pl3(6.85) nationalextremepl(pl_215) nationalmoderatepl(pl_nat) 		//These aren't working and I don't know why... otherm(pl_320)	othere(pl_550)	
loc cutlist2017 cut1(2.15) cut2(3.65) cut3(6.85) cut4(10) cut5(50)

* Income concept options * 
loc inclistpdi market(yl_`zz') mpluspensions(yp_`zz') netmarket(yn_`zz') gross(yg_`zz') disposable(yd_`zz') consumable(yc_`zz') final(yf_`zz')
loc inclistpgt market(ym_`zz') mpluspensions(ye_`zz') netmarket(yk_`zz') gross(yr_`zz') disposable(yd_`zz') consumable(yc_`zz') final(yf_`zz')

loc conlist				con_fama_`zz' con_indu_`zz' con_hins_`zz'
loc dtxlist 			dtx_pitx_`zz' dtx_pyrl_`zz' dtx_prop_`zz' dtx_natn_`zz'
loc itxlist 			itx_vatx_`zz' itx_excs_`zz' itx_cust_`zz' itx_moto_`zz' itx_wsub_`zz' itx_elec_`zz'
loc sublist				sub_elec_`zz' sub_watr_`zz' sub_fuel_`zz'
loc hlthlist 			hlt_prim_`zz' hlt_hosp_`zz' 
loc educlist 			edu_prim_`zz' edu_seco_`zz' edu_tert_`zz'
loc hlthfeeslist 		fee_hlth_`zz'
loc educfeeslist 		fee_educ_`zz'
loc dtrlist				dtr_pssn_`zz' dtr_schl_`zz' dtr_fama_`zz' dtr_indu_`zz' hlt_insu_`zz'
loc othlist				oth_econ_`zz'

loc fisclist      dtransfers(`dtrlist') dtaxes(`dtxlist') contribs(`conlist') indtaxes(`itxlist') subsidies(`sublist') educ(`educlist') health(`hlthlist') other(`othlist') userfeeshealth(`hlthfeeslist') userfeeseduc(`educfeeslist')
loc titlelist1 country("Cote d'Ivoire") surveyyear(2021/22) authors("Ian Houts") scen("`sc', `zz', PPP-`yr'") group("WB, CEQ") project ("CIV21WBN")
loc titlelist country("Cote d'Ivoire") surveyyear(2021/22) authors("Ian Houts") baseyear(`yr') scen("`sc', `zz', PPP-`yr'") group("WB, CEQ") project ("CIV21WBN")

loc ceqdes    		= 1		// E1 - 
loc ceqpop    		= 0		// E2 - Population figures
loc ceqextpop 		= 0 	// E2b - Extended population figures
loc ceqlorenz 		= 1 	// E3 - overall poverty and inequality stats
loc ceqfi     		= 1 	// E5,E6 - fiscal impoverishment and gains to the poor for income concepts
loc ceqef			= 0		// E9  - Effectiveness indicators 	//not working properly
loc ceqconc   		= 0 	// E10 - concentration shares and incidence for income concepts
loc ceqfiscal 		= 1 	// E11 - concentration shares and incidence for fiscal instruments
loc ceqextend		= 0		// E12 - extended income concepts
loc ceqmarg			= 1		// E13 - marginal contributions, kakwani coefficients
*loc ceqefext		= 0		// E14 - effectiveness indicators, fiscal impoverishment and gains to the poor for fiscal instruments [not working]
loc ceqcoverage		= 0		// E18
loc ceqgraphprog	= 0		// E24  
loc ceqgraphconc	= 0		// E25 
loc ceqgraphcdf		= 0		// E26
loc ceqgraphfi		= 0		// E27

#delimit ;
		if `ceqdes'{;
			ceqdes using "$gdOut\MWBs\MWB E\MWB2018_E1_March29_2018.xlsx", ignorem 
					`inclist`sc'/'
					`fisclist'
					`surveylist'
					`titlelist1';
			};

		if `ceqpop'{;
			ceqpop using "$gdOut\MWBs\MWB E\MWB2018_E2_March29_2018.xlsx", ignorem
					`inclist`sc'/'
					`ppplist`yr'/'
					`surveylist'
					`cutlist`yr'/'
					`titlelist';
			};
			
			if `ceqextpop'{;
			ceqpop using "$gdOut\MWBs\MWB E\MWB2018_E2_March29_2018.xlsx", ignorem
					`inclist`sc'/'
					`ppplist`yr'/'
					`surveylist'
					`cutlist`yr'/'
					`titlelist';
			};
			

		if `ceqlorenz'{;
			ceqlorenz using "$gdOut\MWBs\MWB E\MWB2018_E3_March29_2018.xlsx", ignorem
					`inclist`sc'/'
					`ppplist`yr'/'
					`surveylist'
					`povlist`yr'/'	
					`cutlist`yr'/'
					`titlelist';
			};

		if `ceqfi'{;
			ceqfi using "$gdOut\MWBs\MWB E\MWB2018_E5E6_March29_2018.xlsx", ignorem
					`inclist`sc'/'
					`ppplist`yr'/'
					`surveylist'
					`povlist`yr'/'
					`titlelist';
			};
			
		if `ceqef'{;
			ceqef using "$gdOut\MWBs\MWB E\MWB2018_E9_March29_2018.xlsx", ignorem noc nob 
					`inclist`sc'/'
					`fisclist'
					`ppplist`yr'/'
					`surveylist'
					`cutlist`yr'/'
					`titlelist';
			};

		if `ceqconc'{;
			ceqconc using "$gdOut\MWBs\MWB E\MWB2018_E10_March29_2018.xlsx", ignorem noc nob 
					`inclist`sc'/'
					`ppplist`yr'/'
					`surveylist'
					`cutlist`yr'/'
					`titlelist';
			};

		if `ceqfiscal'{;
			ceqfiscal using "$gdOut\MWBs\MWB E\MWB2018_E11_March29_2018.xlsx", ignorem noc nob negatives
					`inclist`sc'/'
					`fisclist'
					`ppplist`yr'/'
					`surveylist'
					`cutlist`yr'/'
					`titlelist';
			};

		if `ceqextend'{;
			ceqextend using "$gdData\MWBs\MWB E\MWB2018_E12_March29_2018.xlsx", ignorem noc nob negatives
					`inclist`sc'/'
					`fisclist'
					`ppplist`yr'/'
					`surveylist'
					`povlist`yr'/'
					`cutlist`yr'/'
					`titlelist';
			};

		if `ceqmarg'{;
			ceqmarg using "$gdOut\MWBs\MWB E\MWB2018_E13_March29_2018.xlsx", ignorem negatives
					`inclist`sc'/'
					`fisclist'
					`ppplist`yr'/'
					`surveylist'
					`povlist`yr'/'
					`titlelist';
			};


		if `ceqcoverage'{;
			ceqmarg using "$gdOut\MWBs\MWB E\MWB2018_E18_March29_2018.xlsx", ignorem
					`inclist`sc'/'
					`fisclist'
					`ppplist`yr'/'
					`surveylist'
					`povlist`yr'/'
					`titlelist';
			};


#delimit cr	
}
}
}





