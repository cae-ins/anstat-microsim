*******************************************************************************
* Enquete harmonisee sur les conditions de vie des menages-UEMOA - Episode 2  *
*                           Analyse de la pauvreté                            *
*        Seuils de pauvreté et indicateurs - Approche 2, Variante a           *
*                 Programme régional adapté pour le Sénégal                   *
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

local d_min=3
local d_max=7
local pas=0.05
local Nkcal=2300

** Noms de fichiers
global pays "CIV2021"														   

capture log close
log using "$prog\ehcvm_${pays}_pgm032a.log", replace text   

***********
** On utilise trois approches pour le seuil 2021, et pour chaque approche deux variantes
** Ce do-file traite de la deuxième approche et de sa première variante
** Approche 2: Construction du seuil de 2021 avec un nouveau panier
** Variante a: les déflateurs temporels sont ceux calculés du volet prix de l'EHCVM
** Les déflateurs spatiaux: rapport seuils zae et seuil national  
***********
*
*
use "$dataout\ehcvm_conso_${pays}.dta", clear

drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
        (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
		(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
        (codpr>=774 & codpr<=777) | (codpr>=901)  /* Exclure les produits ne faisant pas partie de l'agrégat */
*
*
* Appliquer un déflateur temporel pour tenir compte de l'inflation pendant la période de collecte

merge m:1 hhid using "$dataout_temp\ehcvm_men_work.dta", keepusing(zae zaemil region milieu annee mois hhweight hhsize eqadu1 eqadu2) 
keep if _merge==3
drop _merge

merge m:1 zae milieu annee mois using "$dataout\deflateur_temporel_2021.dta"
keep if _merge==3 /* 150 observations ne matchent pas, pas de mois de collecte */
drop _merge

replace depan=depan/def_temp

gen i_ali=(codpr>=1 & codpr<=163) | (codpr>= 166 & codpr<=196) /* 164, 165: boissons alcool */
gen dtot=depan
gen dali=depan if i_ali==1
gen dnal=depan if i_ali==0

preserve
  recode dali dnal (.=0)
  collapse (sum) dali dnal (first) zae zaemil region milieu hhweight hhsize eqadu1 eqadu2 def_temp, by(hhid)
  gen dtot=dali+dnal
  gen dtet=dtot/hhsize
  gen dalit=dali/hhsize
  gen dnalt=dnal/hhsize
  sum dali dnal dtot dalit dnalt dtet
  xtile ndtet=dtet [pw=hhweight*hhsize], nq(10)
  save "$dataout_temp\ehcvm_men_temp.dta", replace
restore
*
*
***** Panier de consommation pour le seuil de pauvrete ************************* 
/* Exclure du panier les produits "autres" et repas hors ménages, pas de prix */
gen flag=(codpr==18 | codpr==19 | codpr==31 |codpr==39 | codpr==50 | codpr==59 | codpr==70 | codpr==75 | ///
          codpr==87 | codpr==106 | codpr==107 | codpr==129 | codpr==152 | codpr==154 | ///
		  codpr==171) | (codpr>=191 & codpr<=196)
keep if i_ali==1 & flag==0
merge m:1 hhid using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge
*
preserve /* panier au niveau national */
  keep if (ndtet>=`d_min' & ndtet<=`d_max') /* exclusion des extremes pour le panier */
  collapse (sum) depant=depan [pw=hhweight], by(codpr)
  egen depan_tot=sum(depant)
  gsort -depant
  gen cobu=depant*100/depan_tot
  gen cobuc=cobu if _n==1
  replace cobuc=cobuc[_n-1]+cobu if _n>1
  keep if cobuc<91  /* On garde les items faisant 90% de la conso totale */
  keep codpr depant depan_tot
  compress
  sort codpr
  save "$dataout_temp\ehcvm_panier_seuil_nat.dta", replace
restore

merge m:1 codpr using "$dataout_temp\ehcvm_panier_seuil_nat.dta"
gen ind_pan=_merge==3
drop _merge
*** Exercice: comparer le panier de 2021 et celui de 2018, déterminer 
** le poids des items de 2018 absents en 2021 
*
******************** Population de référence pour le seuil *********************

use "$dataout_temp\ehcvm_men_temp.dta", clear  /* Population decile 3 a 7 */
keep if ndtet>=`d_min' & ndtet<=`d_max'
gen all=1
collapse (sum) popul37=hhsize [pw=hhweight], by(all)
compress
save "$dataout_temp\ehcvm_popul_dec`d_min'`d_max'.dta", replace
*
*
******** Prix en kilogramme avec conversion des unités non standards ***********
*
use "$dataout_p\ehcvm_pu_merge_${pays}_mode.dta", clear 

sort zae milieu codpr unite
merge m:1 zae milieu codpr unite using "$dataout_nsu\ehcvm_nsu_zaemil_${pays}.dta", keepusing(poids)
drop if _merge==2
drop _merge
merge m:1 zae codpr unite using "$dataout_nsu\ehcvm_nsu_zae_${pays}.dta", keepusing(poids) update
drop if _merge==2
drop _merge
merge m:1 codpr unite using "$dataout_nsu\ehcvm_nsu_nat_${pays}.dta", keepusing(poids) update 
keep if _merge>=3
drop _merge

replace vu_med=(vu_med*1000)/poids if unite!=1000
replace vu_mean=(vu_mean*1000)/poids if unite!=1000 

collapse (mean) vuam_med=vu_med vuam_mean=vu_mean, by(zaemil codpr)

save "$dataout_p\ehcvm_vu_zaemil_${pays}.dta", replace /* Prix niveau ZAE/Milieu */

collapse (mean) vunag_med=vuam_med vunag_mean=vuam_mean, by(codpr)

save "$dataout_p\ehcvm_vu_nat_${pays}.dta", replace /* Prix niveau national */

*********************  Calcul de la conso en calories **************************
use "$dataout_temp\ehcvm_panier_seuil_nat.dta", clear  /* Partir du panier de conso */

gen all=1
merge m:1 all using "$dataout_temp\ehcvm_popul_dec`d_min'`d_max'.dta"
keep if _merge==3
drop _merge

sort codpr
merge 1:1 codpr using "$dataout_p\ehcvm_vu_nat_${pays}.dta"
keep if _merge==3
drop _merge

sort codpr
merge 1:1 codpr using "$datain_aux\calorie_conversion_WA_2021.dta"
keep if _merge==3
drop _merge 

gen pmn=vunag_med 
* Conso par tete, par bien et par jour 
gen conso_pc_val=depant/(popul37*365)
gen conso_pc_qte=conso_pc_val*10/pmn
gen conso_pc_ener=conso_pc_qte*(1-(refuse/100))*cal   

* Conso par tete, par jour, pour tous les biens, on scale-up pour avoir 2300 kcal  
egen conso_pc_ener_tot=sum(conso_pc_ener)
gen conso_pc_ener_up=conso_pc_ener*2300/conso_pc_ener_tot
gen conso_pc_qte_up=conso_pc_qte*2300/conso_pc_ener_tot

*** Comme infos a mettre dans un tableau, il faut retenir : 

tabstat cal conso_pc_qte conso_pc_ener conso_pc_qte_up conso_pc_ener_up, by(codpr) stat(sum)  

recode conso_pc_qte (.=0)
drop if conso_pc_qte==0

keep codpr cal conso_pc_qte conso_pc_ener conso_pc_qte_up conso_pc_ener_up 
order codpr cal conso_pc_qte conso_pc_ener conso_pc_qte_up conso_pc_ener_up 
sort codpr 
save "$dataout_temp\elt_seuil_alim.dta", replace //* Za2021=201161 vs Za2018=186869; 7,6% semble un peu bien *//
*
****************** Calcul Seuil alimentaire, national **************************
*
use "$dataout_p\ehcvm_vu_nat_${pays}.dta", clear 

clonevar pmn=vunag_med 

sort codpr
merge m:1 codpr using "$dataout_temp\elt_seuil_alim.dta"
keep if _merge==3
drop _merge

gen conso_pc_val_up=conso_pc_qte_up*pmn*365/10
gen all=1
collapse (sum) zali0=conso_pc_val_up, by(all)
save "$dataout_temp\seuil_nat.dta", replace
*
****************** Calcul Seuil alimentaire, zae/milieu ************************
*
forval i=1/11 {
   use "$dataout_temp\elt_seuil_alim.dta", clear
   gen zaemil=`i'
   save "$dataout_temp\elt_seuil_alim`i'.dta", replace
   }

use "$dataout_temp\elt_seuil_alim1.dta", clear 
forval i=2/11 {
  append using "$dataout_temp\elt_seuil_alim`i'.dta"
   }

sort zaemil codpr    
merge 1:1 zaemil codpr using "$dataout_p\ehcvm_vu_zaemil_${pays}.dta" 
drop if _merge==2 
clonevar pmam=vuam_med

gen conso_pc_val_up=conso_pc_qte_up*pmam*365/10
sort zaemil
collapse (sum) zali=conso_pc_val_up, by(zaemil)
sort zaemil
save "$dataout_temp\seuil_zaemil.dta", replace  

***********
*********** Partie 2: Seuil de pauvrete non-alimentaire ************************
***********

*** verifier population de reference meme chose, deciles 3 à 8 pour seuil non-alimentaire 

*********** Seuil au niveau national 
use "$dataout_temp\ehcvm_men_temp.dta", clear 

drop ndtet
gen all=1
merge m:1 all using "$dataout_temp\seuil_nat.dta"
drop _merge

gen dmin=0.95*zali0
gen dmax=1.05*zali0

tab all if dtet>=dmin & dtet<=dmax
tab all if dalit>=dmin & dalit<=dmax

gen alpha=dalit/dtet

// Stats supplémentaires pour nbre d'observations calcul seuils //
gen hhw=round(hhweight*dtet)
tabstat alpha [fw=hhw], stat(min median mean max)
tabstat alpha if (dtet>=dmin & dtet<=dmax) [fw=hhw], stat(min median mean max) 
tabstat alpha if (dalit>=dmin & dalit<=dmax) [fw=hhw], stat(min median mean max)

//* Les stats montrent parts conso alimentaire instable, influencent les seuils, apurement *//

preserve
  collapse (mean) alpha0_min=alpha if (dtet>=dmin & dtet<=dmax) [pw=hhweight*dtet], by(all)
  save "$dataout_temp\zmin0.dta", replace  
restore

preserve 
  collapse (mean) alpha0_max=alpha if (dalit>=dmin & dalit<=dmax) [pw=hhweight*dtet], by(all)
  save "$dataout_temp\zmax0.dta", replace  
restore

use "$dataout_temp\seuil_nat.dta", clear
merge 1:1 all using "$dataout_temp\zmin0.dta"
drop _merge
merge 1:1 all using "$dataout_temp\zmax0.dta"
drop _merge
save "$dataout_temp\seuil_nat.dta", replace

*********** Seuil au niveau des zae/milieu 
use "$dataout_temp\ehcvm_men_temp.dta", clear 

drop ndtet
sort zaemil
merge m:1 zaemil using "$dataout_temp\seuil_zaemil.dta"
drop _merge

gen dmin=0.95*zali
gen dmax=1.05*zali

tab zaemil if dtet>=dmin & dtet<=dmax /* Excepté zaemil=6 et 8, tous les autres - de 20 obs., peut-être autre regroupement */
tab zaemil if dalit>=dmin & dalit<=dmax /* Le nbre d'observations est bon */

gen alpha=dalit/dtet

gen hhw=round(hhweight*dtet)
tabstat alpha [fw=hhw], by(zaemil) stat(min median mean max)
tabstat alpha if (dtet>=dmin & dtet<=dmax) [fw=hhw], by(zaemil) stat(min median mean max) 
tabstat alpha if (dalit>=dmin & dalit<=dmax) [fw=hhw], by(zaemil) stat(min median mean max)
/* Les résults. indiquent que faible nbre d'obs., mais aussi données non finalisées posent pb. */ 
/* Pour cela les Zna ne sont pas cohérents avec 2018 */
preserve
  collapse (mean) alpha_min=alpha if dtet>=dmin & dtet<=dmax [pw=hhw], by(zaemil)
  save "$dataout_temp\zmin1.dta", replace  
restore

preserve 
  collapse (mean) alpha_max=alpha if dalit>=dmin & dalit<=dmax [pw=hhw], by(zaemil)
  save "$dataout_temp\zmax1.dta", replace  
restore
*
*
use "$dataout_temp\seuil_zaemil.dta", clear

merge m:1 zaemil using "$dataout_temp\zmin1.dta"
drop _merge
merge m:1 zaemil using "$dataout_temp\zmax1.dta"
drop _merge
gen all=1
merge m:1 all using "$dataout_temp\seuil_nat.dta"
drop _merge
save "$dataout_temp\seuil_all.dta", replace

***********
*********** Partie 3: Fichier pour travaux analyses pauvrete *******************
***********

use "$dataout\ehcvm_individu_${pays}.dta", clear

keep if lien==1
keep sexe age mstat religion nation ethnie alfa alfa2 educ_hi diplome handig activ7j /// 
     activ12m branch sectins csp country year hhid grappe menage zae region milieu vague 

rename (sexe age mstat religion nation ethnie alfa alfa2 educ_hi diplome handig ///
        activ7j activ12m branch sectins csp) ///
	   (hgender hage hmstat hreligion hnation hethnie halfa halfa2 heduc hdiploma hhandig ///
	    hactiv7j hactiv12m hbranch hsectins hcsp)
	   
merge 1:1 hhid using "$dataout_temp\ehcvm_men_temp.dta"
drop _merge

merge m:1 zaemil using "$dataout_temp\seuil_all.dta"
drop _merge

*gen zref=((zali0*(2-alpha0_min))+(zali0/alpha0_max))/2
*gen zzae=((zali*(2-alpha_min))+(zali/alpha_max))/2
*gen def_spa=zzae/zref


gen zref=zali0*(2-alpha0_min)
*gen zref=((zali0*(2-alpha0_min))+(zali0/alpha0_max))/2
gen zzae=zali*(2-alpha_min)
*gen zzae=((zali*(2-alpha_min))+(zali/alpha_max))/2
gen def_spa=zzae/zref

/*  Le résultat ci-dessous montre un pb pour les seuils non-alimentaires et donc les déflateurs spatiaux
	2021	2018	Evolution
Za	201161	186869	1.076481385
Zna	132431	146572	0.903521819
Z	333592	333441	1.000452854
*/

gen pcexp=dtet/def_spa

keep country year hhid grappe menage vague zae region milieu hhweight hhsize eqadu1 eqadu2 ///
     hgender hage hmstat hreligion hnation hethnie halfa halfa2 heduc hdiploma hhandig ///
	 hactiv7j hactiv12m hbranch hsectins hcsp dali dnal dtot pcexp zzae zref def_spa def_temp

order country year hhid grappe menage vague zae region milieu hhweight hhsize eqadu1 eqadu2 ///
     hgender hage hmstat hreligion hnation hethnie halfa halfa2 heduc hdiploma hhandig ///
	 hactiv7j hactiv12m hbranch hsectins hcsp dali dnal dtot pcexp zzae zref def_spa def_temp

lab var grappe "Numero grappe"
lab var menage "Numero menage"
lab var zae "Zone agroecologique"
lab var region "Region residence"
lab var milieu "Milieu residence"
lab var hhweight "Ponderation menage"
lab var hhsize "Taille menage"
lab var eqadu1 "Nbr adultes-equiv. FAO"
lab var eqadu2 "Nbr adultes-equiv. alt."
lab var hgender "Genre du CM"
lab var hage "Age du CM"
lab var hmstat "Situation famille du CM"
lab var hreligion "Religion du CM"
lab var hnation "Nationalite du CM"
lab var hethnie "Ethnie du CM"
lab var halfa "Alpha. lire/ecr. CM"
lab var halfa2 "Alpha. lire/ecr./comp. CM"
lab var heduc "Education du CM"
lab var hdiploma "Diplome du CM"
lab var hhandig "Handicap majeur CM"
lab var hactiv7j "Activite 7 jours du CM"
lab var hactiv12m "Activite 12 mois du CM"
lab var hbranch "Branche activite du CM"
lab var hsectins "Secteur instit. du CM"
lab var hcsp "CSP du CM"
lab var dali "Conso annuelle alim. menage"
lab var dnal "Conso annuelle non alim. menage"
lab var dtot "Conso annuelle totale menage"
lab var zref "Seuil pauvrete national"
lab var pcexp "Indicateur de bien-être"
lab var def_spa "Deflateur spatial"
lab var def_temp "Deflateur temporel"

compress
sort hhid 
save "$dataout\ehcvm_welfare_2a_${pays}.dta", replace

/********* Effacer les fichiers de travail */
erase "$dataout_temp\ehcvm_panier_seuil_nat.dta"
erase "$dataout_temp\ehcvm_popul_dec`d_min'`d_max'.dta" 
erase "$dataout_temp\elt_seuil_alim.dta"
erase "$dataout_temp\zmin0.dta"
erase "$dataout_temp\zmax0.dta"
erase "$dataout_temp\zmin1.dta"
erase "$dataout_temp\zmax1.dta"
erase "$dataout_temp\seuil_zaemil.dta"
erase "$dataout_temp\seuil_nat.dta"
erase "$dataout_temp\seuil_all.dta"


************* Calcul des indicateurs de pauvrete
gen dif=zref-pcexp
gen p0=100*(dif>0)
gen p1=(dif/zref)*p0
gen p2=((dif/zref)^2)*p0

replace hhweight=round(hhweight)

tabstat p0 p1 p2 pcexp [fw=hhweight*hhsize], by(milieu)
tabstat p0 p1 p2 pcexp [fw=hhweight*hhsize], by(region)

gen pauv=p0/100
tabstat pauv [fw=hhweight*hhsize], s(sum) by(milieu) format(%12.0g)
