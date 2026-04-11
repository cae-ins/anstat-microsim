*******************************************************************************
* Enquete harmonisee sur les conditions de vie des menages-UEMOA - Episode 2  *
*                           Analyse de la pauvreté                            *
*Creation fichier consommation: menage/produits/mode acquisition/valeur ann.  *
*                 Programme régional adapté pour la CIV (version mars 2023)                 *
*******************************************************************************

clear
set more off

*Dossiers
global chemin "E:\ATELIER TOUBAB MARS 2023"

global datain "$chemin\Datain"
global datain_men "$chemin\Datain\Menage"
global datain_com "$chemin\Datain\Commune"
global datain_aux "$chemin\Datain\Auxiliaire"

global dataout "$chemin\Dataout"
global dataout_p "$chemin\Dataout\Prix"
global dataout_nsu "$chemin\Dataout\NSU"
global dataout_temp "$chemin\Dataout\temp"

global prog "$chemin\Programs"	

** Noms de fichiers
global pays "CIV2021"														   

capture log close
log using "$prog\ehcvm_${pays}_pgm02.log", replace text   

***********
*********** Partie 1: Consommation alimentaire - Sections 7B, 7A et 9C *********
***********

/* Ne conserver que les menages valides en cohérence avec le pgm01 */

use "$dataout\ehcvm_individu_${pays}.dta", clear
keep if resid==1
collapse (count) hhsize=numind (first) grappe menage  region milieu zae, by(hhid) 
sort hhid 
compress
save "$dataout_temp\ehcvm_men_temp.dta", replace
*
*
**** Section 7B : consommation alimentaire des 7 derniers jours - valorisation par les VU
use "$datain_men\s07b_me_${pays}.dta", clear 
keep if s07bq02==1
drop if missing(s07bq03a) | s07bq03a==0

merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", gen(ka)
keep if ka==3
drop ka

/* La consommation alimentaire est déclarée en quantité, et comprend les achats,
  l'autoconsommation et les cadeaux. On traite separement chacune de ces 
  composantes. Comme on dispose de quantites, on valorise en utilisant la valeur 
  unitaire quand il y a eu achat dans le menage. S'il n'y a pas eu achat, on 
  calcule la mediane des valeurs unitaires declarees dans la grappe, ou 
  dans le milieu de residence, ou la region ou au niveau national. 
  Si les valeurs unitaires n'existent pas pour le produit, on utilise 
  les medianes des prix collectées parrallèlement au volet ménage, pour le moment
  ces prix ne sont pas totalement prêts */
*
rename s07bq01 codpr
gen unite1=s07bq03b*10+s07bq03c  
gen unite2=s07bq07b*10+s07bq07c  

gen sit=1 if (unite1>0 & unite1<.) & (unite2>0 & unite2<.) & (unite1==unite2)  
replace sit=2 if (unite1>0 & unite1<.) & (unite2>0 & unite2<.) & (unite1!=unite2)  
replace sit=3 if (unite1>0 & unite1<.) & (unite2==.) 

tab sit, m

drop if sit==.  /* 0 observations supprimées */

recode s07bq08 (99 999 9999 99999 =.)
gen p0=s07bq08/s07bq07a if sit==1

*Pour les valeurs aberrantes

egen p0_low=pctile(p0), p(25) by(region codpr unite2)
egen p0_upp=pctile(p0), p(75) by(region codpr unite2)
egen piqr=iqr(p0), by(region codpr unite2)
gen p0min=p0_low-(1.5*piqr)							
gen p0max=p0_upp+(1.5*piqr)

gen flag1=p0<p0min
gen flag2=p0>p0max & p0<.   
tab codpr flag1 
tab codpr flag2 

tab codpr if flag1==1,sort 
tab codpr if flag2==1,sort

replace p0=p0min if flag1==1 //0.3% des observations concernées 
replace p0=p0max if flag2==1

drop p0_low p0_upp piqr p0min p0max flag1 flag2

* probablement des missing
recode s07bq03a s07bq04 s07bq05 (99 999 9999 99999 .=0)

** Nbr observations attendu  
sum s07bq03a if s07bq03a>0 & s07bq03a<.
sum s07bq04 if s07bq04>0 & s07bq04<.
sum s07bq05 if s07bq05>0 & s07bq05<.

recode s07bq04 (.=0)
recode s07bq05 (.=0)

gen conso1=s07bq03a-s07bq04-s07bq05 
gen conso2=s07bq04 
gen conso3=s07bq05 

sum conso*

** Nbr observations à traiter - différence du absence variable poids (NSU)  
sum conso1 if conso1>0 & conso1<.
sum conso2 if conso2>0 & conso2<.
sum conso3 if conso3>0 & conso3<.

preserve
  keep if conso1==. & conso2==. & conso3==.
  count /* 0 cas */
restore  

// Ajout de la variable s00q23a afin de conserver le mois d'enquête //
merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague s00q23a s00q08)  gen(merge)
  drop if s00q08==3
drop merge

// Ajout de 5 commandes pour conserver le mois d'enquête //
gen annee=substr(s00q23,1,4)
gen mois=substr(s00q23,6,2)
destring annee mois, force replace
replace annee=2022 if vague==2 & inlist(mois,6,7) & annee==2021
replace mois=7 if vague==2 & mois==8 & annee==2022

clonevar unite=unite1 
sort vague zae milieu codpr unite
merge m:1 zae milieu vague codpr unite using "$dataout_p\ehcvm_pu_merge_${pays}_unit.dta",gen(l)
drop if l==2
drop l
drop if codpr==.  /* peut-être des enregs vides*/

drop interview__key interview__id s07bq02_autre
save "$dataout_temp\s07b_temp1.dta", replace 
*
* Valorisation par les valeurs unitaires
forvalues x=1/3 {
  gen depan`x'=conso`x'*p0*365/7 if sit==1
  replace depan`x'=conso`x'*vu_mean*365/7 if sit!=1 
  disp "résidu non valorisé"
  count if missing(depan`x') /* 405 observations non valorisées satisfaisant */
}

keep vague zae zaemil region milieu grappe menage codpr depan1 depan2 depan3

collapse (sum) depan1 depan2 depan3 (first) vague zae zaemil region milieu, by(grappe menage codpr) 

reshape long depan, i(vague zae zaemil region milieu grappe menage codpr) j(modep)

lab def modepl 1"Achat" 2"Autoconso" 3"Don" 4"Valeur usage BD" 5"Loyer imputee" 
lab val modep modepl

drop if depan==0 | depan==.
sum depan
egen maxi=pctile(depan), p(99)
tab modep 
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim1.dta", replace  
erase "$dataout_temp\s07b_temp1.dta"
*
**
*
**** Section 7A : repas pris hors ménage au cours des 7 derniers jours
use "$datain_men\s07a_1_me_${pays}.dta", clear 

rename s07aq*b s07aq*
gen s01q00a=98
gen s01q00b=" "

append using "$datain_men\s07a_2_me_${pays}.dta"

recode s07aq02 s07aq05 s07aq08 s07aq11 s07aq14 s07aq17 s07aq20 ///
       s07aq03 s07aq06 s07aq09 s07aq12 s07aq15 s07aq18 s07aq21 (. .a=0)

rename (s07aq02 s07aq05 s07aq08 s07aq11 s07aq14 s07aq17 s07aq20) ///
       (depan191 depan192 depan193 depan194 depan195 depan196 depan197)   /* repas acheté à l'extérieur */

rename (s07aq03 s07aq06 s07aq09 s07aq12 s07aq15 s07aq18 s07aq21) ///
       (depam191 depam192 depam193 depam194 depam195 depam196 depam197)   /* repas reçu en cadeau */
*
forval x=191/197 {
    replace depan`x' = depan`x'*365/7
    replace depam`x' = depam`x'*365/7	
    }
*
*
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(zae region milieu grappe menage )
keep if _merge==3    
drop _merge
	   
preserve
   collapse (sum) depan191 depan192 depan193 depan194 depan195 depan196 depan197, ///
                  by(vague grappe menage zae region milieu)
   reshape long depan, i(vague grappe menage  zae region milieu) j(codpr)
   gen modep=1
   save "$dataout_temp\Dep_Alim2a.dta", replace
restore
*
preserve
   collapse (sum) depam191 depam192 depam193 depam194 depam195 depam196 depam197, ///
                  by(vague grappe menage zae region milieu)
   reshape long depam, i(vague grappe menage zae region milieu) j(codpr)
   rename depam depan
   gen modep=3
   save "$dataout_temp\Dep_Alim2b.dta", replace
restore   
*	   
use "$dataout_temp\Dep_Alim2a.dta", clear
append using "$dataout_temp\Dep_Alim2b.dta"

drop if depan==0 | depan==.
sum depan   
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim2.dta", replace
* 
erase "$dataout_temp\Dep_Alim2a.dta"
erase "$dataout_temp\Dep_Alim2b.dta"

*
**** Section 9C : vins modernes et liqueurs
use "$datain_men\s09c_me_${pays}.dta", clear 
keep if s09cq02==1
rename s09cq01 codpr
keep if codpr==301 | codpr==302
sum s09cq03
gen depan=s09cq03*12
gen modep=1
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(zae region milieu grappe menage)
keep if _merge==3   
drop _merge
keep if depan>0 & depan<.
sum depan

merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague s00q08)
    drop if s00q08==3

keep vague grappe menage codpr modep depan zae region milieu
order grappe menage vague codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim3.dta", replace  
*
*
********* Depenses alimentaires et habit, lors des fêtes, section 9a 

use "$datain_men\s09a_me_${pays}.dta", clear
destring grappe, replace

merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(grappe menage zae region milieu)
keep if _merge==3
drop _merge

keep if s09aq02==1

rename s09aq01 codpr

*drop if codpr>=9    //* On élargit à toutes les fêtes pour les autres besoins, mais on ne retiendra que les fêtes religieuses  /
*drop s09aq06 s09aq07   //* On élargit à toutes les rubriques, mais ne retiendra  l'habillement des fêtes religieuses */

sum s09aq03 s09aq04 s09aq05 s09aq06 s09aq07
recode s09aq03 s09aq04 s09aq05 s09aq06 s09aq07 (99 999 9999 99999 . .a =0)

gen depan1=s09aq03 if codpr<=8
gen depan2=s09aq03 if codpr>=9 & codpr<=11
gen depan3=s09aq03 if codpr==12 | codpr==13
*
gen depan4=s09aq04 if codpr<=8
gen depan5=s09aq04 if codpr>=9 & codpr<=11
gen depan6=s09aq04 if codpr==12 | codpr==13
*
gen depan7=s09aq05 if codpr<=8
gen depan8=s09aq05 if codpr>=9 & codpr<=11
gen depan9=s09aq05 if codpr==12 | codpr==13
*
gen depan10=s09aq06+s09aq07 if codpr<=8
gen depan11=s09aq06+s09aq07 if codpr>=9 & codpr<=11
gen depan12=s09aq06+s09aq07 if codpr==12 | codpr==13
*
*
merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague s00q08)
  drop if s00q08==3
  drop _merge

collapse (sum) depan1 depan2 depan3 depan4 depan5 depan6 depan7 depan8 ///
           depan9 depan10 depan11 depan12, by(vague grappe menage zae region milieu) 

reshape long depan, i(vague grappe menage zae region milieu) j(codpr)

// Changement code "Repas de fêtes"
recode codpr (1=901) (2=902) (3=903) (4=904) (5=905) (6=906) (7=521) ///
             (8=908) (9=909) (10=910) (11=911) (12=912)   
drop if (depan==0 | depan==.)

gen modep=1
sum depan  
keep if depan>0 & depan<.
keep vague grappe menage codpr modep depan zae region milieu
order grappe menage codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Fetes.dta", replace  
*
*
use "$dataout_temp\Dep_Fetes.dta", clear

*keep if codpr==901 /* le seul produit alimentaire des fêtes */
keep if codpr>=901 & codpr<=906

append using "$dataout_temp\Dep_Alim1.dta" ///
             "$dataout_temp\Dep_Alim2.dta" ///
             "$dataout_temp\Dep_Alim3.dta" 
sum depan   /* */
sort grappe menage codpr modep
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(region milieu zae hhsize )
keep if _merge==3    /* tous les ménages y sont  */
drop _merge  
		 
drop if depan==0 | depan==.
sum depan  /*  Examin manuel valeurs anormalement élevées avant corrections auto */
gsort -depan
lis grappe menage codpr modep depan if depan>=1000000, sep(200)

**************** Correction automatique valeurs anormalement élevées ************

preserve
  collapse (sum) depant=depan (first) hhsize vague region zae milieu, by(grappe menage codpr)
  gen const=depant/hhsize
  gen lconst=ln(const)
  egen dom1=group(vague zae)
  egen dom2=group(dom1 milieu)
  egen domcod=group(dom2 codpr) 
  egen lconstmd=median(lconst), by(domcod)
  egen liqr=iqr(lconst), by(domcod)
  gen lconstmax=lconstmd+(2.5*liqr)
  gen flag=lconst>lconstmax & lconst<. /* log conso par tête > log median+2.5*iqr */  
  tab region flag 
  gen depant_e=exp(lconstmax)*hhsize if flag==1  /* imputation par le max, trimming */
  keep grappe menage codpr flag depant depant_e
  sort grappe menage codpr
  save "$dataout_temp\Cor_Dep_Alim.dta", replace
restore
******************************************************************** 

sort grappe menage codpr
merge m:1 grappe menage codpr using "$dataout_temp\Cor_Dep_Alim.dta"
drop _merge

lab var codpr"Code produit"
lab var depan"Depense annuelle"
lab var modep"Mode d'acquisition"

*lab def modepl 1"Achat" 2"Autoconso" 3"Don" 4"Valeur usage BD" 5"Loyer imputee" 
lab val modep modepl

preserve
  keep vague grappe menage region milieu zae codpr modep depan 
  order grappe menage region milieu zae codpr modep
  sort grappe menage codpr modep
  save "$dataout_temp\Dep_Alim_Sans_Cor.dta", replace 
restore

replace depan=(depan/depant)*depant_e if flag==1 /* Impute, reallocate total consumption by  original share */
drop hhsize flag depant depant_e 

sum depan  
compress
order grappe menage region milieu zae codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim.dta", replace 

erase "$dataout_temp\Dep_Alim1.dta"
erase "$dataout_temp\Dep_Alim2.dta" 
erase "$dataout_temp\Dep_Alim3.dta"
erase "$dataout_temp\Cor_Dep_Alim.dta"
*
***********
*********** Partie 2: Conso non-alim. monétaire - Sections 9b à 9f, 2, 3 et 11 *****
***********

//* Ajustements pour garder les dépenses exceptionnelles et d'investissement, exclure lors de l'analyse // 
****** Dépenses non alimentaires de la section 9
*
foreach x in b c d e f {
  use "$datain_men\s09`x'_me_${pays}.dta", clear
  keep if s09`x'q02==1
  rename s09`x'q01 codpr
  rename s09`x'q03 s09q03
  drop s09`x'q02
  save "$dataout_temp\s09`x'.dta", replace
}
*	
use "$dataout_temp\s09b.dta", clear
append using "$dataout_temp\s09c.dta" ///
             "$dataout_temp\s09d.dta" ///
             "$dataout_temp\s09e.dta" ///
             "$dataout_temp\s09f.dta"
		
* Exclure les rubriques déjà prises en compte 
drop if codpr==301 | codpr==302  /* vins et liqueurs, alimentaire */

* Garder depenses investissements et exceptionnelles, exclure pour analyse pauvreté

sum s09q03
recode s09q03 (99 999 9999 99999 999999 . .a =0)
gen depan=s09q03*365/7 if codpr>=201 & codpr<=217 /* Dépenses 7 jours */
replace depan=s09q03*12 if codpr>=301 & codpr<=324 /* Dépenses 30 jours */
replace depan=s09q03*4 if codpr>=401 & codpr<=421 /* Dépenses 3 mois */
replace depan=s09q03*2 if codpr>=501 & codpr<=512 /* Dépenses 6 mois */
replace depan=s09q03 if codpr>=601 & codpr<=657 /* Dépenses 12 mois */
gen modep=1

destring grappe, replace

merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague s00q08)
  drop if s00q08==3
  drop _merge


merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(grappe menage hhsize zae region milieu)
keep if _merge==3

drop _merge hhsize

sum depan   
keep if depan>0 & depan<.
keep vague grappe menage codpr modep depan vague zae region milieu
order grappe menage codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Nalim_S9.dta", replace  
*
erase "$dataout_temp\s09b.dta"
erase "$dataout_temp\s09c.dta" 
erase "$dataout_temp\s09d.dta" 
erase "$dataout_temp\s09e.dta" 
erase "$dataout_temp\s09f.dta"
*
*********************** Depenses de telephonie mobile, section 1

use "$datain_men\s01_me_${pays}.dta", clear
drop if s01q00_a==.  /* individus inexistant créés artificiellement */
*drop if s01q00a==2   //* ôter de la base les individus ayant quitté le ménage */

destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

sum s01q38
recode s01q38 (. =0)
gen depan=s01q38*365/7
collapse (sum) depan (first) vague zae region milieu, by(grappe menage )
drop if depan==0 | depan==.
gen codpr=338
gen modep=1
sum depan
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Tmob.dta", replace


*********************** Depenses education, section 2

use "$datain_men\s02_me_${pays}.dta", clear
*drop if s01q00_a==.  /* individus inexistant créés artificiellement */

destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

sum s02q20 s02q21 s02q22 s02q23 s02q24 s02q25 s02q26 s02q27
recode s02q20 s02q21 s02q22 s02q23 s02q24 s02q25 s02q26 s02q27 (99 999 9999 99999 . .a =0)

tab s02q14, m
drop if s02q14==.
recode s02q14 (1=1) (2=2) (3 4=3) (5 6=4) (7=5) (8=6), gen(niv)

forval num=1/6 {
  gen frais`num'=s02q20 if niv==`num'
  gen fcoti`num'=s02q21 if niv==`num'
  gen fourn`num'=s02q22 if niv==`num' 
  gen fautm`num'=s02q23 if niv==`num'
  gen funif`num'=s02q24 if niv==`num'
  gen fcant`num'=s02q25 if niv==`num'
  gen ftran`num'=s02q26 if niv==`num'
  gen fsout`num'=s02q27 if niv==`num'
     }
*
collapse (sum) frais1 fcoti1 fourn1 fautm1 funif1 fcant1 ftran1 fsout1 ///
        frais2 fcoti2 fourn2 fautm2 funif2 fcant2 ftran2 fsout2 ///
		frais3 fcoti3 fourn3 fautm3 funif3 fcant3 ftran3 fsout3 ///
		frais4 fcoti4 fourn4 fautm4 funif4 fcant4 ftran4 fsout4 ///
		frais5 fcoti5 fourn5 fautm5 funif5 fcant5 ftran5 fsout5 ///
		frais6 fcoti6 fourn6 fautm6 funif6 fcant6 ftran6 fsout6, ///
		by(grappe menage vague zae region milieu)

rename (frais1 fcoti1 fourn1 fautm1 funif1 fcant1 ftran1 fsout1 ///
        frais2 fcoti2 fourn2 fautm2 funif2 fcant2 ftran2 fsout2 ///
		frais3 fcoti3 fourn3 fautm3 funif3 fcant3 ftran3 fsout3 ///
		frais4 fcoti4 fourn4 fautm4 funif4 fcant4 ftran4 fsout4 ///
		frais5 fcoti5 fourn5 fautm5 funif5 fcant5 ftran5 fsout5 ///
		frais6 fcoti6 fourn6 fautm6 funif6 fcant6 ftran6 fsout6) ///
       (depan1 depan2 depan3 depan4 depan5 depan6 depan7 depan8 ///
	    depan9 depan10 depan11 depan12 depan13 depan14 depan15 depan16 ///
		depan17 depan18 depan19 depan20 depan21 depan22 depan23 depan24 ///
		depan25 depan26 depan27 depan28 depan29 depan30 depan31 depan32 ///
		depan33 depan34 depan35 depan36 depan37 depan38 depan39 depan40 ///
		depan41 depan42 depan43 depan44 depan45 depan46 depan47 depan48)
		
reshape long depan, i(grappe menage vague zae region milieu) j(codpr)

replace codpr=codpr+700
tab codpr, m
drop if depan==0 | depan==.
sum depan
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Educ.dta", replace
// Fin révision sur l'éducation //
*

*********************** Depenses de santé, section 3

use "$datain_men\s03_me_${pays}.dta", clear
*drop if s01q00_a==.  /* individus inexistant créés artificiellement */

destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

sum s03q13 s03q14 s03q15 s03q16 s03q17 s03q18a s03q18b s03q18c s03q24 s03q24b ///
    s03q26 s03q27 s03q29 s03q30 s03q31 s03q31b s03q48
recode s03q13 s03q14 s03q15 s03q16 s03q17 s03q18a s03q18b s03q18c s03q20 s03q24 ///
       s03q24b s03q26 s03q27 s03q29 s03q30 s03q31 s03q31b s03q48 (. .a =0)
recode s03q13 s03q14 s03q15 s03q16 s03q17 s03q18a s03q18b s03q18c s03q20 s03q24 ///
       s03q24b s03q26 s03q27 s03q29 s03q30 s03q31 s03q31b s03q48 (99 999 9999 99999 . .a=0)

tab1 s03q05 s03q12 s03q20 s03q25

gen depan1=s03q13*4
gen depan2=s03q14*4
gen depan3=s03q15*4
gen depan4=s03q16*4
gen depan5=s03q17*4
gen depan6=s03q18b*4
gen depan7=s03q18c*4
gen depan8=s03q18a*4
gen depan9=s03q29
gen depan10=s03q30
gen depan11=s03q31
gen depan12=s03q31b
gen depan13=s03q24b
gen depan14=s03q24*s03q20  /* Faire test de sensibilité sur la dépense d'hospitalisation */
gen depan15=s03q48         /* Faire test de sensibilité sur la dépense d'accouchement */
gen depan16=s03q26         /* Exclure pour la pauvreté, introduit pour les prix et la CN */ 
gen depan17=s03q27         /* Exclure pour la pauvreté, introduit pour les prix et la CN */

recode depan1 depan2 depan3 depan4 depan5 depan6 depan7 depan8 depan9 depan10 ///
       depan11 depan12 depan13 depan14 depan15 depan16 depan17 (.=0)

collapse (sum) depan1 depan2 depan3 depan4 depan5 depan6 depan7 depan8 depan9 depan10 ///
               depan11 depan12 depan13 depan14 depan15 depan16 depan17 /// 
         (first) vague zae region milieu, by(grappe menage)

reshape long depan, i(grappe menage vague zae region milieu) j(codpr)

replace codpr=codpr+760  
drop if depan==0 | depan==.
sum depan  
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Sante.dta", replace


*********************** Depenses de Logement, section 11

use "$datain_men\s11_me_${pays}.dta", clear

*drop if s11q01==. | s11q01==.a /* conserver les questionnaires valides */
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

****Rappel contenu des variables
* s11q04 (statut d'occupation) 
*s11q05 (loyer potentiel propriétaire) *s11q06 (loyer mensuel locataire)
* s11q23a s11q23b (facture eau et périodicité); s11q25 (eau revendeur) 
* s11q36a s11q36b (facture elec. et périod.) 
* s11q44a s11q44b (telephone fixe et périod.)
* s1147a et s1147b (internet et period.) 
* s11q51a s11q51b (cable et périod.) 

sum s11q05 s11q06 s11q23a s11q25 s11q36a s11q44a  /// 
s11q47a s11q51a 
recode s11q05 s11q06 s11q23a s11q25 s11q36a s11q44a s11q47a s11q51a (99 999 9999 99999 999999 . .a=0)

clonevar s11q5a=s11q05
clonevar s11q6a=s11q06
clonevar s11q25a=s11q25

gen s11q5b=5
gen s11q6b=2
gen s11q25b=2


*****loyer annuel pour les propriétaires
gen depan5=s11q05*12

*****loyer annuel pour les locataires
gen depan6=s11q06*12

****dépenses annuelles auprès des revendeurs
gen depan25=s11q25*365/30

****dépenses annuelles de facture éau (s11q23a); facture électricité (s11q36a); fcature telephone (s11q44a), facture abonnement internet (s11q47a); facture abonnement cable(s11q51a)

foreach x in 23 36 44 47 51 {
 tab1 s11q`x'b 
 gen depan`x'=s11q`x'a*52 if s11q`x'b==1
 replace depan`x'=s11q`x'a*12 if s11q`x'b==2
 replace depan`x'=s11q`x'a*6 if s11q`x'b==3
 replace depan`x'=s11q`x'a*4 if s11q`x'b==4
   }
 
 
merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague s00q08)
  drop if s00q08==3
  drop _merge
*
keep grappe menage depan5 depan6 depan23 depan25 depan36 depan44 depan47 depan51 vague zae region milieu
reshape long depan, i(grappe menage vague zae region milieu) j(codpr)

recode codpr (5=330) (6=331) (23=332) (25=333) (36=334) (44=335) (47=336) (51=337)
drop if depan==0 | depan==.
sum depan  
sum depan if codpr!=330 
lis grappe menage codpr depan if depan>=100000000 & codpr!=330 //aucun cas
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Logement.dta", replace

********* Ensemble consommation monétaire non alimentaire 

use "$dataout_temp\Dep_Fetes.dta", clear

*keep if codpr==521 /* Le seul item non-alimentaire de ce fichier */
keep if (codpr==521) | (codpr>=908 & codpr<=912)

append using "$dataout_temp\Dep_Nalim_S9.dta" ///
			 "$dataout_temp\Dep_Tmob.dta" ///
             "$dataout_temp\Dep_Educ.dta" ///
			 "$dataout_temp\Dep_Sante.dta" ///
             "$dataout_temp\Dep_Logement.dta" 
*
lab var codpr "Code produit"
lab var depan "Depense annuelle"
lab var modep "Mode d'acquisition"

lab val modep modepl

/*
// Ajout de lignes de codes pour examen minitieux des dépenses de conso //
preserve 
  drop if (codpr==330) | (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
          (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
	    	(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
           (codpr>=774 & codpr<=777) | (codpr>=901) 
  egen maxd=pctile(depan), p(99)	/*  Examen manuel valeurs trop élevées et corrections avant imputation auto */
  lis grappe menage codpr depan if depan>maxd
  /* l'une ou l'autre ou les deux */
  sum depan  
  lis grappe menage codpr depan if depan>5000000
  *lis grappe menage depan if depan>30000000 & codpr==330
  /* par exemple, on a 3 dépenses supérieures à 5 millions: 215 (transp. traction animale), 601 (rép. logement) et 644 (papiers, enveloppes) */
  /* 201: peut-être achat de l'animal, plutôt investissements en section 17 */
  /* 601: grosses réparations, plutôt investissements */
  /* 644: peut-être dépenses de l'entreprise du ménage */  
restore
*/

sum depan  
lis grappe menage codpr depan if depan>10000000 
sort grappe menage codpr modep
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(zae region milieu hhsize)
keep if _merge==3
drop _merge  

drop if depan==0 | depan==.
tab codpr, m

preserve
  keep grappe menage zae region milieu codpr modep depan
  order grappe menage region milieu codpr modep depan
  compress
  sort grappe menage codpr modep depan
  save "$dataout_temp\Dep_Nalim_Sans_Cor.dta", replace
restore

********************** Correction valeurs aberrantes ********************************

gen ldepan=ln(depan)
egen dom1=group(vague zae)
egen dom2=group(dom1 milieu)
egen domcod=group(dom2 codpr) 
egen ldepanmn=median(ldepan), by(domcod)
egen liqr=iqr(ldepan), by(domcod)
gen ldepanmax=ldepanmn+(2.5*liqr) 
gen flag=ldepan>ldepanmax & ldepan<.  /* anormale si log conso > log median+2.5*iqr */ 
tab region flag
replace depan=exp(ldepanmax) if flag==1    /* imputation par valeur max, trimming */

sum depan
keep vague grappe menage region milieu codpr modep depan
order grappe menage vague region milieu codpr modep
compress
sort grappe menage codpr modep
save "$dataout_temp\Dep_Nalim.dta", replace
*
erase "$dataout_temp\Dep_Fetes.dta"
erase "$dataout_temp\Dep_Nalim_S9.dta" 
erase "$dataout_temp\Dep_Tmob.dta" 
erase "$dataout_temp\Dep_Educ.dta" 
erase "$dataout_temp\Dep_Sante.dta" 
erase "$dataout_temp\Dep_Logement.dta"
*
***********
*********** Partie 3: Valeur d’usage des biens durables - Section 12 *********
***********
*
use "$datain_men\s12_me_${pays}.dta", clear

keep if s12q02==1
rename s12q01 codpr
sort grappe menage codpr
tab codpr, m  
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(grappe menage zae region milieu)
keep if _merge==3  
drop _merge  

drop if codpr==40 | codpr==41 | codpr==44 | codpr==45 /* Biens de production, Immobilier */


sum s12q03 s12q07 s12q08 s12q09  // Examiner les valeurs déclarés par type de bien, corriger si nécessaire //
recode s12q03 (0 .=.)
recode s12q08 s12q09 (99 999 9999 99999 999999 9999999 99999999 . .a=.)
drop if s12q03==. & s12q08==. & s12q09==. // Absence de toutes les variables importantes, supprimer */

*gen flag=codpr!=32 & codpr!=39 & codpr!=43  // Ajout
gen flag=codpr!=26 & codpr!=32 & codpr!=39 & codpr!=43

recode codpr (24 26=24) (31 32 39=31) (42 43 = 42),gen(codpr2)  /* grouper pour nbre faible d'obs. */
replace codpr=800+codpr 


**************************************
gen age=s12q07 
replace age=0.5 if s12q07==0 
replace age=20 if age>=20 & age<.

gen vacqui=s12q08 if s12q08!=. & s12q08!=0
gen vrempla=s12q09 if s12q09!=. & s12q09!=0 
replace vacqui=. if s12q08<=s12q09
replace vrempla=. if s12q08<=s12q09

gen depret=1-(vrempla/vacqui)^(1/age) if (s12q09>0 & s12q09<.) & (s12q08>0 & s12q08<.) & flag==1 //
drop flag

// 7 lignes de codes ajoutées
preserve
  collapse (median) mdpret=depret, by(codpr2)
  save "$dataout_temp\mdpret.dta", replace
restore

merge m:1 codpr2 using "$dataout_temp\mdpret.dta"
drop _merge

tabstat mdpret, by(codpr)  


*egen mdpret=median(depret), by(codpr) 
*tabstat mdpret, by(codpr)

/* Avant de calculer la valeur d'usage, on impute la quantite (dg3) 
   et la valeur d'acquisition (dg8) quand elles sont ND. De plus, 
   on corrige les valeurs aberrantes de ces 2 variables */

tab codpr s12q03, m 
egen Ms12q03 = mode(s12q03), by (codpr)
replace s12q03=Ms12q03 if s12q03==. // 380 cas concerné

egen Mes12q03=median(s12q03), by(codpr)
egen Ets12q03=iqr(s12q03), by(codpr)
gen Maxs12q03=Mes12q03+(3*Ets12q03)
gen Cor=s12q03>Maxs12q03
tab codpr Cor        // 3,4 pour cent d'observations concernées
 
replace s12q03=Maxs12q03 if Cor==1
drop Cor   
*   
gen ls12q08=ln(s12q08)
sum s12q08 ls12q08
egen mdg8=median(ls12q08), by(codpr)
egen idg8=iqr(ls12q08), by(codpr)
sum s12q08
replace s12q08=exp(mdg8) if s12q08==. | s12q08==0
sum s12q08
gen mdg8max=mdg8+(2.5*idg8)
gen didi=ls12q08>mdg8max 
tab codpr didi
replace s12q08=exp(mdg8max) if didi==1
sum s12q08
drop didi

gen depan=s12q03*s12q08*((1.01)^age)*(mdpret+0.02)   
gen modep=4
tab codpr, m
			 
drop if depan==0 | depan==.
tabstat depan, by(codpr) stat(min median mean max)
sum depan

preserve 
  keep vague grappe menage zae region milieu codpr modep depan 
  order grappe menage region milieu codpr modep depan
  compress
  sort grappe menage codpr modep
  save "$dataout_temp\Dep_Bdur_Sans_Cor.dta", replace
restore


gen ldepan=ln(depan)
egen ldepanmn=median(ldepan), by(codpr)
egen liqr=iqr(ldepan), by(codpr)
gen ldepanmax=ldepanmn+(2.5*liqr) 
gen flag=ldepan>ldepanmax & ldepan<.   
tab codpr flag
replace depan=exp(ldepanmax) if flag==1    /* imputation par la valeur max, trimming */
drop flag ldepanmn ldepanmax liqr

sum depan



keep vague grappe menage zae region milieu codpr modep depan 
order grappe menage region milieu codpr modep depan
compress
sort grappe menage codpr modep
save "$dataout_temp\Dep_Bdur.dta", replace

***********
*********** Partie 4: loyer impute (propro et gratuit) - Section 11 ************
***********

use "$datain_com\s01_comm_${pays}.dta", clear
duplicates report grappe                        
keep grappe s01q05 s01q06 s01q08__1 s01q08__2 s01q08__3 s01q08__4 s01q11 ///
     s01q12 s01q13a__1 s01q13a__2 s01q13a__3 s01q13a__6 s01q13b__1 s01q13b__2 s01q13b__3 s01q13b__6 s01q13b__7

tab1 s01q06 s01q08__1 s01q08__2 s01q08__3 s01q08__4 s01q11 ///
     s01q12 s01q13a__1 s01q13a__2 s01q13a__3 s01q13a__6 s01q13b__1 s01q13b__2 s01q13b__3 s01q13b__6 s01q13b__7, m	 
gen route_goud=s01q06==1	
gen route_late=s01q06==2

gen dist_vill=s01q05
gen ldist_vill=ln(dist_vill) if dist_vill>0
gen route_autre=inlist(s01q06,3,4,5,6) //ajout
gen trans_moto=s01q08__1==1	
gen trans_voit=s01q08__2==1
gen trans_autre=s01q08__3==1 | s01q08__4==1 //ajout
gen reseau_elec=s01q11==1
gen reseau_eau=s01q12==1
gen reseau_tel=s01q13a__1==1| s01q13a__2==1| s01q13a__3==1| s01q13a__6==1  

keep grappe dist_vill ldist_vill route_goud route_late route_autre trans_moto trans_voit trans_autre reseau_elec ///
     reseau_eau reseau_tel
	 
sort grappe
duplicates drop grappe, force
save  "$dataout_temp\Infra_com.dta", replace

*	 
use "$datain_men\s11_me_${pays}.dta", clear

drop if s11q01==. | s11q01==.a /* conserver les questionnaires valides */
destring grappe, replace
merge 1:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing (zae region milieu hhsize )
keep if _merge==3
drop _merge  

preserve
  use "$dataout_temp\Dep_Nalim.dta", clear
  keep if codpr==330 | codpr==331  /* On récupère le loyer payé et le loyer fictif autodéclaré */
  recode depan (.=0)
  gen loyer=depan if codpr==331
  gen loyer_auto=depan if codpr==330
  collapse (sum) loyer=loyer loyer_auto=loyer_auto, by(grappe menage)
  lab var loyer "loyer locataire"
  lab var loyer_auto "loyer auto-declaré"
  sort grappe menage
  save "$dataout_temp\Loyer.dta", replace
restore

merge 1:1 grappe menage using "$dataout_temp\Loyer.dta" /* 10 ménages dans le fichier ménage absent de la base temporaire loyer, car ils sont logés gratuitement*/
drop _merge
erase "$dataout_temp\Loyer.dta"

merge 1:1 grappe menage using "$datain_aux\ehcvm_ponderations_${pays}.dta", keepusing (poids)
tab _m
drop _m
rename poids hhweight

merge 1:1 grappe menage using "$datain_men\s00_me_${pays}.dta", keepusing (s00q03 s00q02 s00q05 s00q04 s00q08)
drop if s00q08==3
tab _m
drop _m

*ren s00q03 commune   // Variables s00q02, s00q03, s00q05 non renseignées, voir
ren s00q05 quartier 
ren s00q02 departement
ren s00q03 sous_prefecture

tab quartier,gen(quartier)

*tab quartier if region==1 & milieu==1, gen(quartier)   
*tab sous_prefecture if region==1 & milieu==1, gen(sous_prefecture)
*tab quartier if region==1
tab departement,gen(departement)

gen abj=.
replace abj=1 if inlist(quartier,201005,201006,201009,201007) //Abidjan sud

replace abj=2 if inlist(quartier,201002,201003) //Adjame et Attecoube
replace abj=3 if inlist(quartier,201004,203997) //Cocody et Bingerville

replace abj=4 if inlist(quartier,201001,202997) //Abobo et Anyama

replace abj=5 if inlist(quartier,201010,205012,202005) //Yopougon,Songon,Akoupe Zeudji

replace abj=6 if quartier==201008 //Port Bouet

label define abj 1"Abj sud" 2"Adj attec" 3"cocody binge" 4"abobo anyama" 5"yop songon" 6"port bouet"
label val abj abj 

recode loyer (.=0)
tabulate region, gen(region)
tabulate zae, gen(zae)
*gen urbain=(milieu==1)

tab1 s11q01 s11q04 s11q03__1 s11q03__2 s11q03__3 s11q18 s11q19 s11q20 ///
     s11q21 s11q33 s11q53 s11q54 s11q55 s11q57 s11q58 s11q59, m 
sum s11q02 

gen locat=(inlist(s11q04,5,9))
gen flag=(locat==1 & loyer==0)  /* Identification de locataires sans loyer */
tab flag     /* aucun cas dans cette situation */
drop flag
gen flag=(locat!=1 & loyer>0 & loyer<.) /* Identification de non locataires avec loyer */
tab flag   /* aucun cas dans cette situation */
list grappe menage locat loyer if flag==1
replace locat=0 if locat==1 & loyer==0
drop flag /*ajout*/


gen lnloyer=ln(loyer) if locat==1


//on recode les types de logement
recode s11q01 (1 2 6=1) (3 4=2) (5=3) (7 8=4) (9=5), gen(typlog)
label define typlog 1 "Maison moderne" 2 "Bande de maison" 3 "Cour commune" 4 "Maison isolée" 5 "Autre"
label val typlog typlog
tab typlog, m

*/

sum s11q02 /* Vérifier la distribution du nombre de pièces */
lis grappe menage s11q02 if s11q02>25 
gen npiece=s11q02
egen mnpiece=median(npiece), by(milieu)
replace npiece=mnpiece if s11q02>25 & s11q02<. 
gen lnpiece=ln(npiece)

// Pour les 3 variables, on a remplacé la commande clonevar par gen, créer une variable 0/1 

gen clim=s11q03__1
gen chauffe=s11q03__2
gen ventilo=s11q03__3

gen eau=(s11q21==1)
gen elec_direct=(s11q33==1)
gen elec_paral=(inlist(s11q33,2,3))

recode s11q18 (1 2 3 4=1) (5 6 7 8=2), gen(mur) 
label define mur 1 "Moderne" 2 "Non moderne"
label val mur mur

recode s11q19 (1 2 3=1) (4 5 6 7 8 9=2), gen(toit) 
label define toit 1 "Moderne" 2 "Non moderne"
label val toit toit

recode s11q20 (1=1) (2=2) (3/5=3), gen(sol) 
label define sol 1"marbre" 2"ciment" 3"non moderne"
label val sol sol

recode s11q53 (1=1) (2=2) (3 4 5 6=3), gen(ordures)
label define ordures 1 "Dépotoir public" 2 "Ramassage" 3 "Non moderne"
label val ordures ordures

recode s11q54 (1 3=1) (2 4=2) (5 6 7=3) (8 9 10 12=4) (11=5), gen(toilet) 
label define toilet 1"WC interne" 2"WC externe" 3"Latrines modernes" 4"Toilettes non modernes" 5"Pas de toilettes"
label val toilet toilet

recode s11q58 (1=1) (2 3 4 5 6 7=2), gen(excre) 
label define excre 1"moderne" 2"non moderne"
label val excre excre

recode s11q59 (1=1) (2 3 4 5=2), gen(eausee)
label define eausee 1"moderne" 2"non moderne"
label val eausee eausee 

tabulate typlog, gen(typlog)
tabulate toit, gen(toit)
tabulate mur, gen(mur)
tabulate sol, gen(sol)
tabulate toilet, gen(toilet)
tabulate ordures, gen(ordures)
tabulate excre, gen(excre)
tabulate eausee, gen(eausee)
tabulate abj, gen(abj)

merge m:1 grappe using "$dataout_temp\Infra_com.dta"
drop _merge

recode route_goud route_late trans_moto trans_voit reseau_elec reseau_eau reseau_tel (.=0)

gen zone=.
replace zone=1 if region==1
replace zone=2 if region!=1 & s00q04==1
replace zone=3 if region!=1 & s00q04==2


tab zone locat  /* Effectif locataires: 680 à Abidjan, 1 659 autre urbain et 368 rural; on essaye les régressions */

// Comparaison des caracteristiques du logement des proprietaires et locataires 

*** Abidjan


sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* abj* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==1 & locat==0   // Proprietaire à Abidjan

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* abj* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==1 & locat==1   // Locataire à Abidjan

reg lnpiece locat [w=hhweight*hhsize] if zone == 1  // p=0.000	 

*** Urban	

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==2 & locat==0   // Proprietaire dans le reste du milieu urbain
		
sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==2 & locat==1   // Locataire dans le reste du milieu urbain
	
reg lnpiece locat [w=hhweight*hhsize] if zone == 2 // p=0.000	
	
*** Rural 

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==3 & locat==0   // Proprietaire en milieu rural
		
sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==3 & locat==1   // Locataire en milieu rural 
	
reg lnpiece locat [w=hhweight*hhsize] if zone == 3 // p=0.000	
*	
*
******** Regression Abidjan


****zone 1


***abidjan global (r2=0.75 n=662 )
stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel abj1-abj5 if zone==1 
* Stocker la liste des variables de stepwise

mat list e(b)
mat A_Abidjan = e(b)  // 15 variables, y compris la constante _cons

local ncols = colsof(A_Abidjan)
local nvars = `ncols'-1
matselrc A_Abidjan A_vars_Abidjan, c(1/`nvars')  // sans la constante _cons 
local var1: colnames A_vars_Abidjan

reg 	lnloyer `var1' if zone==1 
predlog loyer `var1' if zone==1 

rename YHTSMEAR Abidjan_YHTSMEAR_new1   
drop YH*	

// Comparer les techniques d'imputation - Abidjan
gen loyer_imp=Abidjan_YHTSMEAR_new1 if locat==0 & zone==1 
gen loyer_eff=loyer if locat==1 & zone==1  

tabstat loyer_eff loyer_imp loyer_auto if zone==1 , stat(count min p25 mean median p75 max)  

twoway (kdensity Abidjan_YHTSMEAR_new1 if locat==0 & zone==1 , title(Abidjan) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 , legend(label (2 "actual rent"))) 

graph export "$prog\rent_Abidjan_1.tif", replace

twoway (kdensity Abidjan_YHTSMEAR_new1 if locat==0 & zone==1 , title(Abidjan) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 , legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==1, legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_Abidjan_2.tif", replace	


/*
*****abidjan 1 (koumassi,plateau,marcory,treichville n=75 r2=0.75)
				stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog1-typlog3 typlog5  ///
				eau elec_direct mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel if zone==1 & abj1==1
				
* Stocker la liste des variables de stepwise
mat list e(b)
mat A_Abidjan_1 = e(b)  // 6 variables, y compris la constante _cons
matselrc A_Abidjan_1 A_vars_Abidjan_1, c(1/5)  // sans la constante _cons 
local var1: colnames A_vars_Abidjan_1

reg 	lnloyer `var1' if zone==1 & abj1==1 
predlog loyer `var1' if zone==1 & abj1==1 

rename YHTSMEAR Abidjan_YHTSMEAR_new1_1    
drop YH*	

		
	
// Comparer les techniques d'imputation - Abidjan

gen loyer_imp1=Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1 & abj1==1 
gen loyer_eff1=loyer if locat==1 & zone==1 & abj1==1 

tabstat loyer_eff1 loyer_imp1 loyer_auto if zone==1 & abj1==1 , stat(count min p25 mean median p75 max)  

twoway (kdensity Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1 & abj1==1 , title(Abidjan) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 & abj1==1 , legend(label (2 "actual rent"))) 

graph export "$prog\rent_Abidjan_1_1.tif", replace

twoway (kdensity Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1 & abj1==1 , title(Abidjan_1) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 & abj1==1 , legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==1 & abj1==1 , legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_Abidjan_2_1.tif", replace
				
*****abidjan 2 (adjame attecoube n=98 r2=0.63)
				stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog2-typlog3 typlog5  ///
				eau elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel if zone==1 & abj2==1	

								
* Stocker la liste des variables de stepwise
mat list e(b)
mat A_Abidjan_2 = e(b)  // 11 variables, y compris la constante _cons
matselrc A_Abidjan_2 A_vars_Abidjan_2, c(1/10)  // sans la constante _cons 
local var2: colnames A_vars_Abidjan_2

reg 	lnloyer `var2' if zone==1 & abj2==1 
predlog loyer `var2' if zone==1 & abj2==1

rename YHTSMEAR Abidjan_YHTSMEAR_new1_2    
drop YH*				
	
// Comparer les techniques d'imputation - Abidjan

replace loyer_imp1=Abidjan_YHTSMEAR_new1_2 if locat==0 & zone==1 & abj2==1
replace loyer_eff1=loyer if locat==1 & zone==1 & abj2==1 

tabstat loyer_eff1 loyer_imp1 loyer_auto if zone==1 & abj2==1 , stat(count min p25 mean median p75 max)  

twoway (kdensity Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1 & abj2==1 , title(Abidjan_2) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 & abj1==1 , legend(label (2 "actual rent"))) 

graph export "$prog\rent_Abidjan_1_2.tif", replace

twoway (kdensity Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1 & abj2==1 , title(Abidjan_2) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 & abj2==1 , legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==1 & abj2==1 , legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_Abidjan_2_2.tif", replace
				
*****abidjan 3 (cocody bingerville n=87 r2=0.86)
stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog1-typlog3 typlog5  ///
				eau elec_direct mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel if zone==1 & abj3==1

* Stocker la liste des variables de stepwise
mat list e(b)
mat A_Abidjan_3 = e(b)  // 11 variables, y compris la constante _cons
matselrc A_Abidjan_3 A_vars_Abidjan_3, c(1/8)  // sans la constante _cons 
local var3: colnames A_vars_Abidjan_3

reg 	lnloyer `var3' if zone==1 & abj3==1 
predlog loyer `var3' if zone==1 & abj3==1

rename YHTSMEAR Abidjan_YHTSMEAR_new1_3    
drop YH*	
				
				
*****abidjan 4 (abobo anyama n=60 r=0.60 )
stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog1-typlog2 typlog5 typlog4  ///
				eau elec_direct elec_paral mur1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud  ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel if zone==1 & abj4==1

***abidjan 5 (yopougon n=195 r2=0.73)

stepwise, pr(.10) pe(.09) forward : reg lnloyer  lnpiece clim chauffe ventilo typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel if zone==1 & abj5==1
				
***abidjan 6 (port bouet n=87 r2=0.85)

stepwise, pr(.10) pe(.09) forward : reg lnloyer  lnpiece clim chauffe ventilo typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel if zone==1 & abj6==1				

				
*tab zone, m
				 
* Stocker la liste des variables de stepwise
mat list e(b)
mat A_Abidjan = e(b)  // 17 variables, y compris la constante _cons
matselrc A_Abidjan A_vars_Abidjan, c(1/17)  // sans la constante _cons 
local var1: colnames A_vars_Abidjan

reg 	lnloyer `var1' if zone==1 
predlog loyer `var1' if zone==1 

rename YHTSMEAR Abidjan_YHTSMEAR_new1_1    
drop YH*

// Comparer les techniques d'imputation - Abidjan

gen loyer_imp1=Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1
gen loyer_eff1=loyer if locat==1 & zone==1

tabstat loyer_eff1 loyer_imp1 loyer_auto if zone==1, stat(count min p25 mean median p75 max)  

twoway (kdensity Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1, title(Abidjan) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1, legend(label (2 "actual rent"))) 

graph export "$prog\rent_Abidjan_1.tif", replace

twoway (kdensity Abidjan_YHTSMEAR_new1_1 if locat==0 & zone==1, title(Abidjan) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1, legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==1, legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_Abidjan_2.tif", replace
*/

***********************

******** Regresssion Intérieur du pays - URBAN (n=1556 r2=0.68)

// Rejet des variables non significatives au seuil de 10% (p>.1)

stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel region2-region32 departement3-departement6 departement8-departement12 departement14-departement15 departement17-departement22 departement25-departement26 departement28-departement31 departement34-departement36 departement38 departement41-departement42 departement44-departement48 departement50 departement53-departement55 departement58-departement62 departement64 departement68-departement76 departement78 departement80 departement82 departement85-departement86 departement88-departement101 departement105-departement107  if zone==2


* Stocker la liste des variables de stepwise
mat list e(b) 
mat A_urb = e(b)  // 40 variables, y compris la constante _cons

local ncols = colsof(A_urb)
local nvars = `ncols'-1
matselrc A_urb A_vars_urb, c(1/`nvars')  // sans la constante _cons 
local var_urb: colnames A_vars_urb

reg 	lnloyer `var_urb' if zone==2
predlog loyer `var_urb' if zone==2

rename YHTSMEAR URB_YHTSMEAR_new
drop YH*

// Comparer les techniques d'imputation - Autre urbain

replace loyer_imp=URB_YHTSMEAR_new if locat==0 & zone==2
replace loyer_eff=loyer if locat==1 & zone==2

tabstat loyer_eff loyer_imp loyer_auto if zone==2, stat(count min p25 mean median p75 max)  

twoway (kdensity URB_YHTSMEAR_new if locat==0 & zone==2, title(Urban) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==2, legend(label (2 "actual rent"))) 
graph export "$prog\rent_urb.tif", replace

twoway (kdensity URB_YHTSMEAR_new if locat==0 & zone==2, title(Urban) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==2, legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==2, legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_urb2.tif", replace
*
*
******** Regression Intérieur du pays - Rural

// Rejet des variables non significatives au seuil de 10% (p>.10)

stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog1-typlog3  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3 /// 
				ordures1 ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau region2-region32 if zone==3

****test
stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece ldist_vill clim chauffe typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel region3-region32 departement3-departement6 departement8 departement9 departement11 departement12 departement14-departement15 departement17-departement22 departement25-departement26 departement28-departement31 departement34-departement36 departement38 departement41-departement42 departement44 departement45 departement47-departement48 departement50 departement53-departement55 departement58-departement62 departement68-departement76 departement78 departement80 departement82 departement86 departement88 departement89 departement90 departement92-departement98  departement100 departement101 departement107  if zone==3

* Stocker la liste des variables de stepwise
mat list e(b) 
mat A_rur = e(b)  // 20 variables, including _cons
local ncols = colsof(A_rur)
local nvars = `ncols'-1

matselrc A_rur A_vars_rur, c(1/`nvars')  // sans la constante _cons term
local var_rur: colnames A_vars_rur


reg 	lnloyer `var_rur' if zone==3
predlog loyer `var_rur' if zone==3

rename YHTSMEAR RUR_YHTSMEAR_new
drop YH*

// Comparer les techniques d'imputation - Rural

replace loyer_imp=RUR_YHTSMEAR_new if locat==0 & zone==3
replace loyer_eff=loyer if locat==1 & zone==3

tabstat loyer_eff loyer_imp loyer_auto if zone==3, stat(count min p25 mean median p75 max)  

twoway (kdensity RUR_YHTSMEAR_new if locat==0 & zone==3, title(Rural) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==3, legend(label (2 "actual rent"))) 

graph export "$prog\rent_rur.tif", replace

twoway (kdensity RUR_YHTSMEAR_new if locat==0 & zone==3, title(Rural) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==3, legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==3, legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_rur2.tif", replace

bys zone: sum loyer 		if locat == 1, detail 
bys zone: sum loyer_imp 	if locat == 0, detail 
bys zone: sum loyer_auto 	if locat == 0, detail 

*** Conclusion: loyer auto-déclaré trop élevé, on retient le loyer imputé par régression

gen depan=loyer_imp if locat==0
gen codpr=331
gen modep=5
sum depan

drop if depan==.
tab codpr, m

lab var codpr "Code produit"
lab var depan "Depense annuelle"
lab var modep "Mode d'acquisition"

lab val modep modepl

merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague )
  drop _merge

keep if locat==0
keep vague grappe menage codpr modep depan zae region milieu locat
order grappe menage region milieu codpr modep depan locat
compress
sort grappe menage codpr modep
save "$dataout_temp\Dep_Loyer.dta", replace 

***********
*********** Partie 5: Agrégat de consommation et quelques tests ************
***********

use "$dataout_temp\Dep_Alim.dta", clear

append using "$dataout_temp\Dep_Nalim.dta" ///
             "$dataout_temp\Dep_Bdur.dta" ///
             "$dataout_temp\Dep_Loyer.dta"
*
drop if codpr==330 //* Exclure le loyer fictif autodéclaré, doublon loyer */
*
lab def mill 1"Urbain" 2"Rural"
lab val milieu mill
lab def regl  1"AUTONOME D'ABIDJAN" 2"HAUT-SASSANDRA" 3"PORO" 4"GBEKE" 5"INDENIE-DJUABLIN" 6"TONKPI" 7"YAMOUSSOUKRO" 8"GONTOUGO" 9"SAN-PEDRO" 10"KABADOUGOU" 11"N'ZI" 12"MARAHOUE" 13"SUD-COMOE" 14"WORODOUGOU" 15"LÔH-DJIBOUA" 16"AGNEBY-TIASSA" 17"GÔH" 18"CAVALLY" 19"BAFING" 20"BAGOUE" 21"BELIER" 22"BERE" 23"BOUNKANI" 24"FOLON" 25"GBÔKLE" 26"GRANDS-PONTS" 27"GUEMON" 28"HAMBOL" 30"LA ME" 31"NAWA" 32"TCHOLOGO" 33"MORONOU" 29"IFFOU"
lab val region regl
gen str country="CIV"
lab var country "Pays"

gen year=2021
gen hhid=grappe*100+menage
lab var year "Annee enquête"
lab var hhid "Identifiant unique menage"
lab var grappe "Numero grappe"
lab var menage "Numero menage"
lab var region "Region résidence"
lab var milieu "Milieu résidence"		 
lab var codpr  "Code produit"
lab var modep  "Mode d'acquisition"
lab var depan  "Depense annuelle"

lab val modep modepl
do "$prog\codpr2_label_civ.do"
lab val codpr codprl



merge m:1 grappe menage using "$datain_aux\ehcvm_ponderations_${pays}.dta", keepusing (grappe  poids)
tab _merge
drop _merge
rename poids hhweight

lab var hhweight "Ponderation"

keep country year hhid vague grappe menage  region milieu hhweight codpr modep depan
compress
order country year hhid vague grappe menage  region milieu hhweight codpr modep
sort hhid codpr modep
save "$dataout\ehcvm_conso_${pays}.dta", replace

******
***************************** Tests de robustesse *****************************************
******

*************   Premier test: dépenses hospitalisation et accouchement *********

preserve
/* Exclure momentanément les produits ne faisant pas partie de l'agrégat, 
   mais garder hospitalisation et accouchement */

drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
        (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
		(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
        (codpr>=776 & codpr<=777) | (codpr>=901)   /* Exclure les produits ne faisant pas partie de l'agrégat */
  gen dhosp=depan if codpr==774 
  gen dacco=depan if codpr==775 
  collapse (sum) dhosp=dhosp dacco=dacco dtot=depan (first) milieu hhweight, by(hhid)
  replace hhweight=round(hhweight)
  tabstat dhosp dacco dtot [fw=hhweight], by(milieu) stat(min p25 mean median p75 max) 
  twoway (kdensity dhosp, title(National) legend(label (1 "Hospitalisation"))) 
  graph export "$prog\hosp_tot.tif", replace  /* Dépense vraiment exceptionnelle, ôter de l'agrégat */
  twoway (kdensity dacco, title(National) legend(label (1 "Accouchement"))) 
  graph export "$prog\acco_tot.tif", replace  /* Dépense également exceptionnelle, ôter de l'agrégat */
restore
*/
*
***** Deuxième test: examen des ménages avec consommation nulle ****************
*
/*** Exclure définitivement les dép. exceptionnelles, investissement, biens durables, 
      hospitalisation et accouchement et exclus de analyse pauvreté */	
		
drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
        (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
		(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
        (codpr>=774 & codpr<=777) | (codpr>=901)   /* Exclure les produits ne faisant pas partie de l'agrégat */

gen i_ali1=(codpr>=1 & codpr<=163) | (codpr>= 166 & codpr<=190) /* 164, 165: boissons alcool */
gen i_ali2=(codpr>=191 & codpr<=196) 

// ajout
gen i_nal1=(codpr==331 & modep==5)
gen i_nal2=(codpr>=801 & codpr<=843)
gen i_nal3=(codpr>=164 & codpr<=165) | ((codpr>=197) & (i_nal1==0 & i_nal2==0))
//

gen dtot=depan
gen dali1=depan if i_ali1==1 
gen dali2=depan if i_ali2==1
gen dnal1=depan if i_nal3==1 // ajout
gen dnal=depan if i_nal1==1 | i_nal2==1 | i_nal3==1  // ajout
*
*
gen dach_ali=depan if (i_ali1==1 | i_ali2==1) & (modep==1)
gen daut_ali=depan if (i_ali1==1 | i_ali2==1) & (modep==2)
gen ddon_ali=depan if (i_ali1==1 | i_ali2==1) & (modep==3)
gen dacq_bdu=depan if modep==4
gen dacq_lim=depan if modep==5 
*
preserve
  use "$dataout\ehcvm_individu_${pays}.dta", clear
  keep if resid==1
  egen hhsize=count(numind), by(hhid)
  keep if lien==1
  save "$dataout_temp\hhsize.dta", replace
restore
*
*
*
recode dali1 dali2 dnal1 dnal (.=0)
collapse (sum) dali1 dali2 dnal1 dnal dach_ali daut_ali ddon_ali dacq_bdu dacq_lim ///
         (first) grappe menage hhweight, by(hhid)
merge m:1 grappe menage using "$dataout_temp\hhsize.dta"
keep if _m == 3
drop _m
gen dali=dali1+dali2
gen dtot=dali+dnal
gen flag1=dali==0
gen flag2=dnal1==0
list grappe menage dali dnal dnal1 if flag1==1 /* Identifier ménages à conso alim. nulle, vérifier si tous les produits sont valorisés */
list grappe menage dali dnal dnal1 if flag2==1 /* Identifier ménages à conso non-alim. nulle, supprimer pour questionnaire incomplet */

* Activer ces trois commandes après s'être assuré que c'est de vrais 0
drop if flag1==1
drop if flag2==1 
drop flag1 flag2 
*
*
********* Troisième test: part de la consommation alimentaire ******************
*
gen pdali1=dali1/dtot
gen pdali2=dali2/dtot
gen pdali=pdali1+pdali2

gen dtet=dtot/hhsize
xtile ndtet=dtet [pw=hhweight*hhsize], nq(10)

gen hhw1=round(hhweight*dtot)

** Part conso alimentaire dans conso totale
tabstat pdali1 pdali2 pdali [fw=hhw1], by(milieu)
tabstat pdali1 pdali2 pdali [fw=hhw1], by(ndtet) //* ??? alimentaire, comparer avec 2018 */


tabstat pdali [fw=hhw1], stat(min p1 p10 median mean p90 p99 max) /* Examen conso alimentaire anormale */
twoway (kdensity pdali, title(Part de consommation alimentaire) legend(label (1 "Part alimentaire"))) 
graph export "$prog\palim.tif", replace  
*
*
******* Quatrième test: part autoconso et non-monétaire en général ****************
*
gen paut=daut_ali/dali
gen pdon=ddon_ali/dali
   
gen pbdu=dacq_bdu/dtot
gen plim=dacq_lim/dtot

gen hhw2=round(hhweight*dali)

** Part autoconso et don dans conso alimentaire 
tabstat paut pdon [fw=hhw2], by(milieu)
tabstat paut pdon [fw=hhw2], by(ndtet)

** Part biens durables et loyer impute dans conso totale 
tabstat pbdu plim [fw=hhw1], by(milieu)
tabstat pbdu plim [fw=hhw1], by(ndtet)

