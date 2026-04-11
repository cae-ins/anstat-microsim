*******************************************************************************
* Enquete harmonisee sur les conditions de vie des menages-UEMOA - Episode 2  *
*                           Analyse de la pauvreté                            *
*        Seuils de pauvreté et indicateurs - Approche 1, Variante b           *
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
log using "$prog\ehcvm_${pays}_pgm031b.log", replace text   

***********
** On utilise trois approches pour le seuil 2021, et pour chaque approche deux variantes
** Ce do-file traite de la première approche et de sa seconde variante
** Approche 1: Seuil 2021 égal seuil 2018 multiplié par l'augmentation des prix en 2018-21
** Variante b: on utilise comme déflateurs temporels ceux calculés du volet prix de l'EHCVM 
** Les déflateurs spatiaux ceux calculés par les prix du volet prix de l'ehcvm 
***********
*
use "$dataout\ehcvm_conso_${pays}.dta", clear

drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
        (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
		(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
        (codpr>=774 & codpr<=777) | (codpr>=901) /* Exclure les produits ne faisant pas partie de l'agrégat */
*
*

* Appliquer un déflateur temporel pour tenir compte de l'inflation pendant la période de collecte

merge m:1 hhid using "$dataout_temp\ehcvm_men_work.dta", keepusing(zae milieu annee mois) 
keep if _merge==3
drop _merge

merge m:1 zae milieu annee mois using "$dataout\deflateur_temporel_2021.dta"
keep if _merge==3
drop _merge

replace depan=depan/def_temp

gen i_ali=(codpr>=1 & codpr<=163) | (codpr>= 166 & codpr<=196) /* 164, 165: boissons alcool */
gen dtot=depan
gen dali=depan if i_ali==1
gen dnal=depan if i_ali==0

collapse (sum) dtot dnal dali (first) grappe menage def_temp, by(hhid)

save "$dataout_temp\agregat_temp.dta", replace

***** Variables niveau menage, pour la suite des travaux *********************** 
*
*
use "$dataout\ehcvm_individu_${pays}.dta", clear

keep if lien==1
keep sexe age mstat religion nation ethnie alfa alfa2 educ_hi diplome handig activ7j /// 
     activ12m branch sectins csp country year hhid grappe menage zae region milieu vague 

rename (sexe age mstat religion nation ethnie alfa alfa2 educ_hi diplome handig ///
        activ7j activ12m branch sectins csp) ///
	   (hgender hage hmstat hreligion hnation hethnie halfa halfa2 heduc hdiploma hhandig ///
	    hactiv7j hactiv12m hbranch hsectins hcsp)

merge m:1 hhid using "$dataout_temp\ehcvm_men_work.dta", keepusing(hhweight hhsize eqadu1 eqadu2) 
keep if _merge==3
drop _merge		
		
merge 1:1 hhid using "$dataout_temp\agregat_temp.dta"
drop _merge

gen un=1
merge m:1 un using "$dataout\inflation_2018_2021.dta"
drop _merge

gen inflation_18_21=ipc_moyen_cour/ipc_moyen_base 
tab inflation_18_21

scalar zref2018=345520.3

gen zref=zref2018*inflation_18_21
tab zref

merge m:1 zae milieu using "$dataout\deflateur_spatial_2021.dta"
drop _merge

gen pcexp=dtot/(hhsize*def_spa)

keep country year hhid grappe menage vague zae region milieu hhweight hhsize eqadu1 eqadu2 ///
     hgender hage hmstat hreligion hnation hethnie halfa halfa2 heduc hdiploma hhandig ///
	 hactiv7j hactiv12m hbranch hsectins hcsp dali dnal dtot pcexp zref def_spa def_temp

order country year hhid grappe menage vague zae region milieu hhweight hhsize eqadu1 eqadu2 ///
     hgender hage hmstat hreligion hnation hethnie halfa halfa2 heduc hdiploma hhandig ///
	 hactiv7j hactiv12m hbranch hsectins hcsp dali dnal dtot pcexp zref def_spa def_temp

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
save "$dataout\ehcvm_welfare_1b_${pays}.dta", replace

/********* Effacer les fichiers de travail */
erase "$dataout_temp\agregat_temp.dta"

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
