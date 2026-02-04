if ("$gdDo" == "") {
	di as error "Configure work environment in 01-init.do before running the code."
	error 1
}

* pre-simulation
do "$gdDo\01. CIV21WBN_presimulation_setup.do"

* simulation
* parameters:
global consratio = 0.64884479		//16,204,529,688,442 (yd_hh)  /  24,974,431,335,000 (Final HH + NPISH) 2020		//0.567678803 was 2018
do "$gdDo\02. CIV21WBN_dtx.do"
do "$gdDo\03. CIV21WBN_dtr.do"
do "$gdDo\04. CIV21WBN_vat_in.do"
do "$gdDo\05. CIV21WBN_excise.do"
*do "$gdDo\06. CIV21WBN_fuel_excise.do"		//fuel taxes eliminated for 2021/2
do "$gdDo\07. CIV21WBN_cus_in.do"
do "$gdDo\08. CIV21WBN_subs.do"
do "$gdDo\09. CIV21WBN_educ.do"
do "$gdDo\10. CIV21WBN_health.do"
do "$gdDo\11. CIV21WBN_nhi.do"
* Simulation compilation in one file.
do "$gdDo\12. CIV21WBN_ceqincome.do"

* post-simulation
do "$gdDo\13. ceq_stats.do"
do "$gdDo\99. programGlobalVarlabels.do"
do "$gdDo\100. CIV21WBN_indicators.do"
do "$gdDo\101. CIV21WBN_graphs_presentation.do"
do "$gdDo\etabs.do"