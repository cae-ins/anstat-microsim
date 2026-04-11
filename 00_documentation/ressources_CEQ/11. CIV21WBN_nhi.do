* Cote d'Ivoire 2021
* Health Insurance Scheme
* 27 Aug 2023
* Ian Houts

clear all
set more off
set type double


global nhi_pelig_pop = 75000				//Number of participating noncontributory members in CMU scheme (Total)
global nhi_npelig_pop = 1425000				//Number of participating contributory members in CMU scheme (Total)
global nhi_cont		= 1000					//Monthly contribution to NHI insurance program (CFA)


use "$gdOut\nhi_base.dta", clear

g hlt_pelig = (nhi_p_elig==1 & pelig<= $nhi_pelig_pop )
g hlt_npelig = (nhi_np_elig==1 	& npelig<= $nhi_npelig_pop )		//These two categories now cover 1,484,649 people, enough for the 2018/2019 enrolled population
g con_hins_in = $nhi_cont * 12 if hlt_npelig==1 & age >=18

*I'm going to assume that we don't directly see any respondent who was actually in the pilot, so I will treat the fees as non-subsidized.
g hlt_insu_in = hlth_fees*(percentcov/100) if hlt_pelig==1 | hlt_npelig==1
g hlt_insu_ri = (hlt_insu_in>0 & hlt_insu!=.)

collapse (sum) hlt_insu_hh=hlt_insu_in con_hins_hh=con_hins_in, by(hhid hhweight)

save "$gdTemp\nhi_insu_final.dta", replace


