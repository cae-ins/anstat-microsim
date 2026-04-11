	use "D:\Profil de pauvreté 2018_analysis job\Finalisation\input\ehcvm_conso_CIV2018.dta" ,clear
	
drop if (codpr>=603 & codpr<=607) | (codpr>=610 & codpr<=613) |  ///
        (codpr==616) | (codpr>=623 & codpr<=624) |  /// 
		(codpr>=633 & codpr<=635) | (codpr==641) | /// 
        (codpr==691) | (codpr==152)  
		
		
		
  gen dep_cat = .
  ** Alimentaire
  replace dep_cat = 1 if (codpr>=1 & codpr<=136) | (codpr== 151) | (codpr>=161 & codpr<=164) 
  ** Loyer
  replace dep_cat = 2 if codpr == 331
  * Education
  replace dep_cat = 3 if inrange(codpr, 661, 672)
  
  * Sante
  replace dep_cat = 4 if inrange(codpr, 681, 686)
  
    * communication
  replace dep_cat = 5 if inlist(codpr, 313, 335,336,337,338)
  
  ** Autre - non-alim
  replace dep_cat = 6 if dep_cat == . & !missing(depan)
  
 lab def dep_cat  1 "Code depenses alim." 2 "Loyer" 3 "Education" 4 "Sante" 5" Communication" 6 "Autre non-Alimentaire"
  lab val dep_cat dep_cat 
  
  label var dep_cat "Category de consommation- alim, loyer, edu, sante, autre"
  
  gen dalim=depan if dep_cat ==1
  gen dloyer=depan if dep_cat ==2
   gen deduc=depan if dep_cat ==3
    gen dsante=depan if dep_cat ==4
	 gen dcom=depan if dep_cat ==5
	  gen dautr=depan if dep_cat ==6
	  
	  
	  collapse (sum) depan dalim dloyer deduc dsante dcom dautr ///
         (first) grappe menage hhweight, by(hhid)
		 gen dt=dalim+dloyer+deduc+dsante+dcom+dautr
		 
		 gen palim=dalim/depan
		 gen ployer=dloyer/depan
		 gen peduc=deduc/depan
		 gen psante=dsante/depan
		 gen pcom=dcom/depan
		 gen pautr=dautr/depan
		 
		 
		 gen hhw1=round(hhweight*depan)
		 
		 
		 tabstat palim ployer peduc psante pcom pautr [fw=hhw1]