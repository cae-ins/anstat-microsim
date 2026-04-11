*******************************************************************************
* Enquete harmonisee sur les conditions de vie des menages-UEMOA - Episode 2  *
*                           Analyse de la pauvreté                            *
*       Calculs déflateurs temporels et spatiaux à utiliser dans la suite     *
*         Programme régional adapté pour la CIV en Fevrier 2023               *
*******************************************************************************

clear
set more off

//Definition du chemin d'accès au dessier contenant les bases de données et programmes
global chemin "E:\ATELIER TOUBAB MARS 2023"

global datain "$chemin\Datain"  //les bases de données en entrée
global datain_men "$chemin\Datain\Menage"  //les bases ménages S00-S20
global datain_com "$chemin\Datain\Commune"  //les bases communautaires s00-s04
global datain_aux "$chemin\Datain\Auxiliaire" // bases prix, NSU, ponderation, calories

global dataout "$chemin\Dataout"  // les fichiers de travail (individi, menage, conso, welfare
global dataout_p "$chemin\Dataout\Prix"  // les fichiers de travail sur les prix  (valeurs unitaires, section 7b)
global dataout_nsu "$chemin\Dataout\NSU"  // les fichiers de travail sur les données NSU
global dataout_temp "$chemin\Dataout\temp" // les fichiers transitoire

global prog "$chemin\Programs"	//Les fichiers programmes

***parametre 2018 de calcul des seuil***
local d_min=3 //3em decile
local d_max=7 //7em decile
local pas=0.05 // l'intervalle a partir du quel on calcul le seuil non alimentaire
local Nkcal=2300 //Seuil en Kca

** Macro pour generer le nom du pays et l'année de l'enquête  
global pays "CIV2021"														   
												   

capture log close
log using "$prog\ehcvm_${pays}_pgm03_00_revise.log", replace text   
*
use "$dataout\ehcvm_individu_${pays}.dta", clear 
/* Ne conserver que les menages valides en cohérence avec le pgm01 */
keep if resid==1
gen eqadu1=0.255 if age<1
replace eqadu1=0.450 if age>=1 & age<=3
replace eqadu1=0.620 if age>=4 & age<=6
replace eqadu1=0.690 if age>=7 & age<=10
replace eqadu1=0.860 if age>=11 & age<=14 & sexe==1
replace eqadu1=1.030 if age>=15 & age<=18 & sexe==1
replace eqadu1=1.000 if age>=19 & age<=50 & sexe==1
replace eqadu1=0.790 if age>=51 & sexe==1
replace eqadu1=0.760 if age>=11 & age<=50 & sexe==2
replace eqadu1=0.660 if age>=51 & sexe==2
gen adlt=age>=18
gen enft=age<=17
collapse (count) hhsize=numind (sum) eqadu1 adlt enft ///
         (first) country year grappe menage zae zaemil region milieu hhweight, by(hhid) 
gen flag=adlt==0		 
replace adlt=1 if flag==1
replace enft=enft-1 if flag==1
gen eqadu2=(1+(0.7*(adlt-1))+(0.5*enft))^0.9
sum
*
merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", keepusing(vague s00q23a)
keep if _merge==3
drop _merge
** Convert date of survey
gen annee=substr(s00q23,1,4)
gen mois=substr(s00q23,6,2)
destring annee mois, force replace
replace annee=2022 if vague==2 & inlist(mois,6,7) & annee==2021
replace mois=7 if vague==2 & mois==8 & annee==2022

keep hhid country year grappe menage vague region zae zaemil milieu hhweight annee mois hhsize eqadu1 eqadu2 
sort hhid 
compress
save "$dataout_temp\ehcvm_men_work.dta", replace
*
*
use "$dataout\ehcvm_conso_${pays}.dta", clear

drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
        (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
		(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
        (codpr>=774 & codpr<=777) | (codpr>=901) /* Exclure les produits ne faisant pas partie de l'agrégat */
*
**
*** Déflateurs temporels calculés par les prix, calcul par zae/mois, comparer avec l'IHPC
*
*
* Détermination du panier devant servir au calcul des déflateurs, on construit un panier ... 
* au niveau national, mais on utilise les poids des produits retenus dans les ZAE 
*
preserve
  collapse (sum) dtot=depan, by(hhid)
  merge 1:1 hhid using "$dataout_temp\ehcvm_men_work.dta"
  drop _merge
  gen dtet=dtot/hhsize
  sum dtot dtet
  xtile ndtet=dtet [pw=hhweight*hhsize], nq(10)
  save "$dataout_temp\ehcvm_men_temp.dta", replace
restore

merge m:1 hhid using "$dataout_temp\ehcvm_men_temp.dta"
drop _merge

preserve
  keep if (ndtet>=`d_min' & ndtet<=`d_max')    /* exclusion des extremes pour le panier */
  collapse (sum) depant=depan [pw=hhweight], by(codpr)
  egen depan_tot=sum(depant)
  gsort -depant
  gen cobu=depant*100/depan_tot
  gen cobuc=cobu if _n==1
  replace cobuc=cobuc[_n-1]+cobu if _n>1
  keep if cobuc<95  /* On garde les items faisant 95% de la conso totale */
  keep codpr depant depan_tot cobu  /* On ne garde que les produits et variétés ehaustives */
  merge 1:m codpr using "$dataout_temp\produit_exhaustif_${pays}.dta"
  /* _merge==1; 36 cas (produits/variétés) du panier sans info sur les prix, que représentent-ils? */
  drop if _merge==2
  sort _merge
  numlabel,add
  list codpr cobu if _merge==1 
  egen cobu_all=sum(cobu) 
  egen cobu_np=sum(cobu) if _merge==1
  gen cobu_rejet=cobu_np/cobu_all
  dis cobu_rejet   /* les produits sans info prix représente 7% du panier, important */
  keep if _merge==3
  drop _merge mois cobu_all cobu_np cobu_rejet 
  save "$dataout_temp\ehcvm_panier_nat_temp.dta", replace
restore
  
merge m:1 codpr using "$dataout_temp\ehcvm_panier_nat_temp.dta"
keep if _merge==3
drop _merge

collapse (sum) depan (first) cobu_nat=cobu [pw=hhweight], by(zae milieu codpr)
save "$dataout_temp\ehcvm_panier_ponder_temporel_prov.dta", replace /* Panier et pondérations déflateur temporels provisoires, il faudra les ajuster avec seulemnt les biens communs au panier et aux prix*/
*
*
*
use "$dataout_temp\ehcvm_prix_exhaustif_${pays}_cor.dta", clear

*drop if annee==2022 & mois==8
merge m:1 codpr using "$dataout_temp\ehcvm_panier_nat_temp.dta"
keep if _merge==3
drop _merge

keep if select==1  // Ne garder que les variétés présentes tous les mois dans toutes les ZAE

preserve
  collapse (count) m=mois, by(zae milieu zaemil codpr)
  merge m:1 zae milieu codpr using "$dataout_temp\ehcvm_panier_ponder_temporel_prov.dta"
  keep if _merge==3
  drop _merge
  drop m
  egen depant=sum(depan), by(zae milieu)
  gen cobu_zmi=depan*10000/depant  // Ajout
  egen cobu_zmi_t=sum(cobu_zmi), by(zaemil)  // Ajout
  replace cobu_zmi=cobu_zmi*10000/cobu_zmi_t // Ajout
*
  egen cobu_nat_t=sum(cobu_nat)  // Ajout
  replace cobu_nat=cobu_nat*10000/cobu_nat_t  // Ajout
*
  drop cobu_zmi_t cobu_nat_t  // Ajout
  sort zae milieu codpr
  order zae milieu zaemil codpr cobu_nat cobu_zmi
  save "$dataout_temp\ehcvm_panier_ponder_temporel.dta", replace /* Panier et pondérations déflateur temporels */
restore

merge m:1 zae milieu codpr using "$dataout_temp\ehcvm_panier_ponder_temporel.dta"
keep if _merge==3
drop _merge

** Prix en UNS, calcul les indices élémentaires par variété

sort zae milieu annee mois codpr variete

// Calculs des prix de base, moyenne par variété
egen prix_m_v=mean(prix), by(zae milieu codpr variete)

// Indice élementaire par variété
gen Ivar=prix/prix_m_v

*** Agrégation niveau produit par la moyenne géométrique des indices élémentaires non-pondérés
gen LnIvar=ln(Ivar)
order zae milieu annee mois codpr
collapse (mean) Ipr=LnIvar (first) cobu_nat cobu_zmi, by(zae milieu annee mois codpr)
sort zae milieu annee mois codpr


** On continue avec des moyennes arithmétriques, et des pondérations alternatives
** pour 3 cas différents 
** Pour chacun des 3 cas, on calcule aussi un indice national, à comparer avec l'IHPC 
** pour validation 

preserve  // Pondérations à affecter pour l'agrégation niveau national
  use "$dataout_temp\ehcvm_panier_ponder_temporel.dta", replace
  keep zae milieu codpr depan
  collapse (sum) depan_str=depan, by(zae milieu)
  save "$dataout_temp\depan_str.dta", replace  
restore

*** Calculs des indices

replace Ipr=exp(Ipr)

preserve // Indice par zae/milieu pondérations nationales 
  collapse (mean) def_temp1=Ipr [pw=cobu_nat], by(zae milieu annee mois) // Déflateur temp. par strate, hyp1
  save "$dataout_temp\deftem_1.dta", replace
  merge m:1 zae milieu using "$dataout_temp\depan_str.dta"
  drop _merge
  collapse (mean) ipc1=def_temp1 [pw=depan_str], by(annee mois) // Déf. temp. niveau nat. pour test avec IHPC
  merge 1:m annee mois using "$dataout_temp\deftem_1.dta"
  drop _merge
  order zae milieu annee mois def_temp1 ipc1
  sort zae milieu annee mois
  save "$dataout_temp\deftem_1.dta", replace 	
restore  

preserve // Indice par zae/milieu pondérations de la strate
  collapse (mean) def_temp2=Ipr [pw=cobu_zmi], by(zae milieu annee mois) // Déflateur temp. par strate, hyp2
  save "$dataout_temp\deftem_2.dta", replace
  merge m:1 zae milieu using "$dataout_temp\depan_str.dta"
  drop _merge
  collapse (mean) ipc2=def_temp2 [pw=depan_str], by(annee mois) // Déf. temp. niveau nat. pour test avec IHPC
  merge 1:m annee mois using "$dataout_temp\deftem_2.dta"
  drop _merge
  order zae milieu annee mois def_temp2 ipc2
  sort zae milieu annee mois
  save "$dataout_temp\deftem_2.dta", replace 	
restore  

preserve // Indice par zae/milieu pondérations moyennes national/milieu
  gen cobu_moy=(cobu_zmi+cobu_nat)/2
  collapse (mean) def_temp3=Ipr [pw=cobu_moy], by(zae milieu annee mois) // Déf. temp. strate, hyp3
  save "$dataout_temp\deftem_3.dta", replace
  merge m:1 zae milieu using "$dataout_temp\depan_str.dta"
  drop _merge
  collapse (mean) ipc3=def_temp3 [pw=depan_str], by(annee mois) // Déf. temp. niveau nat. pour test avec IHPC
  merge 1:m annee mois using "$dataout_temp\deftem_3.dta"
  drop _merge
  order zae milieu annee mois def_temp3 ipc3
  sort zae milieu annee mois
  save "$dataout_temp\deftem_3.dta", replace 	  
restore  
*
*
use "$dataout_temp\deftem_1.dta", clear
  merge 1:1 zae milieu annee mois using "$dataout_temp\deftem_2.dta"
  drop _merge
  merge 1:1 zae milieu annee mois using "$dataout_temp\deftem_3.dta"
  drop _merge  

gen def_temp=def_temp2  

*table zae milieu, stat(mean def_temp1 def_temp2 def_temp3)

egen zaemil=group(zae milieu)
bys zaemil: tabstat def_temp1 def_temp2 def_temp3, by(mois)
drop zaemil
  
sort annee mois zae milieu 
save "$dataout\deflateur_temporel_2021.dta", replace
*
erase "$dataout_temp\ehcvm_panier_nat_temp.dta"
erase "$dataout_temp\ehcvm_panier_ponder_temporel.dta"
erase "$dataout_temp\deftem_1.dta"
erase "$dataout_temp\deftem_2.dta"
erase "$dataout_temp\deftem_3.dta"
*
**
*** Déflateurs spatiaux calculés par les prix EHCVM, calcul par zae, comparer avec les seuils
**
*
use "$dataout\ehcvm_conso_${pays}.dta", clear

drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
        (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
		(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
        (codpr>=774 & codpr<=777) | (codpr>=901)  /* Exclure les produits ne faisant pas partie de l'agrégat */
*
*
merge m:1 hhid using "$dataout_temp\ehcvm_men_temp.dta", keepusing(zae milieu annee mois hhweight hhsize)
drop _merge
*
merge m:1 zae milieu annee mois using "$dataout\deflateur_temporel_2021.dta"
keep if _merge==3
drop _merge
*
replace depan=depan/def_temp
*
preserve
  collapse (sum) dtot=depan (first) zae milieu hhweight hhsize, by(hhid)
  gen dtet=dtot/hhsize
  sum dtot dtet
  xtile ndtet=dtet [pw=hhweight*hhsize], nq(10)
  save "$dataout_temp\ehcvm_men_temp.dta", replace
restore

merge m:1 hhid using "$dataout_temp\ehcvm_men_temp.dta"
drop _merge

preserve
  keep if (ndtet>=`d_min' & ndtet<=`d_max')    /* exclusion des extremes pour le panier */
  collapse (sum) depant=depan [pw=hhweight], by(codpr)
  egen depan_tot=sum(depant)
  gsort -depant
  gen cobu=depant*100/depan_tot
  gen cobuc=cobu if _n==1
  replace cobuc=cobuc[_n-1]+cobu if _n>1
  keep if cobuc<96 /* On garde les items faisant 95% de la conso totale */
  keep codpr depant depan_tot cobu  /* On ne garde que les produits et variétés ehaustives */
  merge 1:m codpr using "$dataout_temp\produit_exhaustif_${pays}.dta"
  /* _merge==1; 36 cas (produits/variétés) du panier sans info sur les prix, que représentent-ils? */
  drop if _merge==2
  sort _merge
  list codpr cobu if _merge==1 
  egen cobu_all=sum(cobu) 
  egen cobu_np=sum(cobu) if _merge==1
  gen cobu_rejet=cobu_np/cobu_all
  dis cobu_rejet   /* les produits sans info prix représente un quart du panier, important */
  keep if _merge==3
  drop _merge mois cobu_all cobu_np cobu_rejet 
  sort codpr
  save "$dataout_temp\ehcvm_panier_nat_spa.dta", replace
restore

// Se limiter aux produits du panier  
merge m:1 codpr using "$dataout_temp\ehcvm_panier_nat_spa.dta"
keep if _merge==3
drop _merge

// Se restrindre aux produits exhaustifs
preserve
  merge m:1 codpr using "$dataout_temp\produit_exhaustif_${pays}.dta"
  tab _merge
  keep if _merge==3
  drop _merge
  collapse (count) nc=mois, by(codpr)
  save "$dataout_temp\ehcvm_panier_prod.dta", replace
restore

// Ajustement des pondérations aux produits du panier et étant exhaustifs

merge m:1 codpr using "$dataout_temp\ehcvm_panier_prod.dta"
keep if _merge==3
drop _merge nc
*
collapse (sum) depan (first) cobu_nat=cobu [pw=hhweight], by(zae milieu codpr)
egen depant=sum(depan), by(zae milieu)
gen cobu_zmi=depan*10000/depant
egen zaemil=group(zae milieu)
egen cobu_zmi_t=sum(cobu_zmi), by(zaemil)
replace cobu_zmi=cobu_zmi*10000/cobu_zmi_t
*
egen cobu_nat_t=sum(cobu_nat)
replace cobu_nat=cobu_nat*10000/cobu_nat_t
*
drop cobu_zmi_t cobu_nat_t
sort zae milieu codpr
order zae milieu codpr
save "$dataout_temp\ehcvm_panier_ponder_spatial.dta", replace /* Panier et pondérations déflateur spatiaux */
*
*
**
use "$dataout_temp\ehcvm_prix_exhaustif_${pays}_cor.dta", clear

keep if select==1
*drop if annee==2022 & mois==8

** Après la déflation temporelle, on annule les effets mois
** Si plusieurs relevés le même mois, calculer d'abord la moyenne arithmétique simple du mois
collapse (mean) prix, by(zae milieu codpr variete)

merge m:1 codpr using "$dataout_temp\ehcvm_panier_nat_spa.dta"
keep if _merge==3
drop _merge

// Calculs des prix de base
egen prix_m_v=mean(prix), by(codpr variete)
gen Ivar=prix/prix_m_v 

gen Ivar_paasche=prix_m_v/prix //ajout pour l'approche de pasche/

gen LnIvar=ln(Ivar)  // Indice élémentaire au niveau des variétés, moyennes géométriques

gen LnIvar_paasche=ln(Ivar_paasche)  //ajout/

order zae milieu codpr
collapse (mean) Ipr=LnIvar Ipr_paasche=LnIvar_paasche , by(zae milieu codpr)/*ajout et modifié paasche*/
sort zae milieu codpr

merge m:1 zae milieu codpr using "$dataout_temp\ehcvm_panier_ponder_spatial.dta"
keep if _merge==3
drop _merge
sort zae milieu codpr

// Agrégation au niveau des produits, moyennes arithmétiques
replace Ipr=exp(Ipr)
gen def_spa=Ipr

replace Ipr_paasche=exp(Ipr_paasche) //ajout
gen def_spa_paasche=Ipr_paasche  //ajout/

preserve
  collapse (mean) def_spa1=def_spa [pw=cobu_nat], by(zae milieu)
  save "$dataout_temp\defspa_1.dta", replace
restore




// preserve
//  egen cobu_nat2=mean(cobu_zmi), by(codpr)
//   collapse (mean) def_spa2=def_spa [pw=cobu_nat2], by(zae milieu)
//   save "$dataout_temp\defspa_2.dta", replace
// restore


preserve //ajout
 // egen cobu_nat2=mean(cobu_zmi), by(codpr)
  collapse (mean) def_spa2=def_spa_paasche [pw=cobu_zmi], by(zae milieu)
  replace def_spa2=1/def_spa2
  save "$dataout_temp\defspa_2.dta", replace
restore



*
use "$dataout_temp\defspa_1.dta", clear
  merge 1:1 zae milieu using "$dataout_temp\defspa_2.dta"
  drop _merge  
//ajout
  
  
drop if zae==.
gen def_spa=sqrt(def_spa1*def_spa2)

egen zaemil=group(zae milieu)
tabstat def_spa1 def_spa2 def_spa , by(zaemil)
drop zaemil
save "$dataout\deflateur_spatial_2021.dta", replace
erase "$dataout_temp\defspa_1.dta"
erase "$dataout_temp\defspa_2.dta"
*
*
*** Déflateurs temporels calculés par l'IHPC, calcul par mois niveau national
*
use "$datain_aux\ehcvm_ihpc_${pays}.dta", clear
keep if (annee==2021 & mois==12) | (annee==2021 & mois==11) | (annee==2022 & mois<=7)
egen ipc_moyen=mean(ipc)
gen def_temp=ipc/ipc_moyen
save "$dataout\ihpc_temp.dta", replace

