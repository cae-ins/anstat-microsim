cap program drop globalvarlabels
program define globalvarlabels 

* Label all variables 


		global con_pc  		"Contributions (non-pension)"	
		global con_fama_pc "Contributions to family allowance"
		global con_indu_pc "Contributions to Industrial Accident Fund"
		global dtx_stax_pc "Tax on salaries"
		global dtx_pc  		"Direct taxes"
		global dtx_pitx_pc  	"PIT"
		global dtx_igrx_pc  	"PIT: IGR"
		global dtx_ibic_pc  	"PIT: BIC"
		global dtx_rent_pc  	"PIT: rent"
		global dtx_capt_pc  	"PIT: capital gains"
		global dtx_pyrl_pc  	"Payroll"
		global con_fama_pc  	"Cont: Family allowance"
		global con_indu_pc  	"Cont: Industrial accident"
		global dtx_prop_pc  	"Property Tax"
		global dtr_pc			"Direct transfers"
		global dtr_pssn_pc		"PSSNP"
		global dtr_fama_pc		"Ben: Family Allowance"
		global dtr_indu_pc		"Ben: Industrial Accidents"
		global dtr_schl_pc		"Scholarships"
		global dtx_natn_pc  	"National contributions tax"
		global dtx_stax_pc  	"Tax on salaries"
		global con_hins_pc  	"Contributions to National Health Insurance: pilot program, pc"
		global itx_pc  		"Indirect taxes"
		
		global sub_pc           "Indirect subsidies"
		global sub_watr_pc      "Water tariff subsidies"
		global itx_wsub_pc  	"Water infra tax"
		global sub_elec_pc      "Electricity tariff subsidies"
		global itx_elec_pc  	"Electricity infra tax"
		global sub_fuel_pc      "Fuel subsidies (total)"
		global sub_dfuel_pc      "Fuel subsidies (direct effects)"
		global sub_ifuel_pc      "Fuel subsidies (indirect effects)"
		
		global itx_dvat_pc  	"VAT (direct)"
		global itx_ivat_pc  	"VAT (indirect)"
		global itx_vatx_pc  	"VAT"
		
		global itx_excs_pc  	"Excise"
		global itx_exca_pc  	"Excise: alcohol"
		global itx_exct_pc  	"Excise: tobacco"
		global itx_exco_pc  	"Excise: other"

		global itx_dfuel_pc 	"Fuel Excise (direct)"
		global itx_ifuel_pc 	"Fuel Excise Tax: (indirect)"
		global itx_fuel_pc 		"Fuel Excise"
		
		global itx_fuel_totl_pc "Fuel taxes (total)"
		global itx_fuel_dtotl_pc "Fuel tax (direct)"
		global itx_fuel_itotl_pc "Fuel tax (indirect)"
		global itx_excs_fuel_pc  	"Fuel: excise"
		global itx_cust_fuel_pc  	"Fuel: customs"
		
		global itx_cust_pc  	"Customs"
		global itx_dcus_pc  	"Customs (direct)"
		global itx_icus_pc  	"Customs (indirect)"
		
		global itx_moto_pc		"Motor Vehicle Registration Tax"
		global ink_pc  			"In-kind benefits"
		global hlt_pc  			"In-kind health benefits"
		global edu_pc  			"In-kind education benefits"
		global hlt_prim_pc  	"Healthcare: primary"
		global hlt_hosp_pc  	"Healthcare: hospital"
		global hlt_insu_pc		"NHI"
		global edu_prim_pc  	"Educ: primary"
		global edu_seco_pc  	"Educ: secondary"
		global edu_tert_pc  	"Educ: tertiary"
		global oth_econ_pc		"PSSNP Economic Inclusion training"
		global fee_hlth_pc  	"User fees: healthcare"
		global fee_educ_pc  	"User fees: education"
		global fee_pc			"User fees"


		global net_cash_pc 		"Net cash position"
		global net_totl_pc 		"Net total position"
		global itx_vatx_fuel_pc "Fuel tax: VAT"
		global itx_cust_fuel_pc "Fuel tax: customs"
		global itx_excs_fuel_pc "Fuel tax: excises"
		global itx_exca_pc 		"Excises: alcohol"
		global itx_exct_pc 		"Excises: tobacco"
		global itx_exco_pc 		"Excises: other"
		
	forval i = 1/3{
		global sim_dtx_pitx`i'_pc	"Direct taxes: PIT reform (`i')"
		global sim_dtx_igrx`i'_pc 	"Direct taxes: IGR reform (`i')"
		global sim_pitx`i'_pc 		"PIT reform (`i')"
		global sim_igrx`i'_pc 		"IGR reform (`i')"

		global sim_dtx`i'_yp_pc 	"Market income plus pensions (`s',PDI), pc"
		global sim_dtx`i'_yn_pc 	"Net market income (`s',PDI), pc"
		global sim_dtx`i'_yd_pc 	"Disposable income  (`s',PDI), pc"
		global sim_dtx`i'_yc_pc 	"Consumable income (`s',PDI), pc"
		global sim_dtx`i'_yf_pc	 	"Final income (`s',PDI), pc"
	}

end 
