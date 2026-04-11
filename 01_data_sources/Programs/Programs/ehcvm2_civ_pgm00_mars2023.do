*******************************************************************************
* Enquete harmonisee sur les conditions de vie des menages-UEMOA - Episode 2  *
*                           Analyse de la pauvreté                            *
*         Creation fichiers de travail NSU et valeurs unitaires               *
*            Programme régional adapté pour la Côte d'Ivoire                  * 
*                      version Mars 2023                                      *
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
log using "$prog\ehcvm_${pays}_pgm00.log", replace text   

*********************
********************* Creation de fichiers NSU a differents niveaux geographiques
*********************

use "$datain_aux\ehcvm_nsu_${pays}.dta", clear
rename s00q01 region
rename s00q02 departement 
*rename s00q03 sous_prefecture
rename s00q04 milieu


//////////////
/*Creation de zae pour la CIV */
recode region (4 7 11 21 29 33=1 "CENTRE") ///
			  (2 6 12 18 27=2 "CENTRE-OUEST")  ///
              (3 8 10 14 19 20 22 23 24 28 32=3 "NORD") ///
			  (1 5 13 16 26 30=4 "SUD-EST") ///
			  (9 15 17 25 31=5 "SUD-OUEST") ///
			  (0=6 "ABIDJAN"), gen(zae)
replace zae=6 if region==1 & milieu==1 

label var zae "Zone agroecologique"


*Creation de zaemil
egen zaemil = group(zae milieu)
tab zaemil zae
label def zaemil 1 "CENTRE (urbain)" 2 "CENTRE (rural)" ///
				 3 "CENTRE-OUEST (urbain)" 4 "CENTRE-OUEST (rural)" ///
				 5 "NORD (urbain)" 6 "NORD (rural)" ///
				 7 "SUD-EST (urbain)" 8 "SUD-EST (rural)" ///
				 9 "SUD-OUEST (urbain)" 10 "SUD-OUEST (rural)" ///
				 11 "ABIDJAN", replace
label val zaemil zaemil

* Creation de milieu2
gen     milieu2 = (region==1 & milieu==1)
replace milieu2 = 2 if milieu==1 & milieu2 ==0
replace milieu2 = 3 if milieu==2 & milieu2 ==0
label define milieu2 1 "Abidjan urbain" 2 "Autre urbain" 3 "Rural" 
label values milieu2 milieu2


rename produitID codpr													
rename uniteID unite
rename tailleID taille

replace unite = unite*10+taille													
keep region zae milieu milieu2 zaemil codpr unite poids
compress
order region zae milieu milieu2 zaemil codpr unite poids
sort region zae milieu zaemil codpr unite
save "$dataout_nsu\ehcvm_nsu_brut_${pays}.dta", replace


preserve
  collapse (median) poids, by(region milieu codpr unite)
  sort region milieu codpr unite
  save "$dataout_nsu\ehcvm_nsu_regmil_${pays}.dta", replace /* niveau region milieu */
restore



preserve
  collapse (median) poids, by(zae milieu codpr unite)
  sort zae milieu codpr unite
  save "$dataout_nsu\ehcvm_nsu_zaemil_${pays}.dta", replace /* niveau zae milieu */
restore



preserve
  collapse (median) poids, by(milieu codpr unite)
  sort milieu codpr unite
  save "$dataout_nsu\ehcvm_nsu_milieu_${pays}.dta", replace /* niveau milieu */
restore



preserve
  collapse (median) poids, by(milieu2 codpr unite)
  sort milieu2 codpr unite
  save "$dataout_nsu\ehcvm_nsu_milieu2_${pays}.dta", replace /* niveau milieu2 */
restore


preserve
  collapse (median) poids, by(region codpr unite)
  sort region codpr unite
  save "$dataout_nsu\ehcvm_nsu_region_${pays}.dta", replace /* niveau region */
restore


preserve
  collapse (median) poids, by(zae codpr unite)
  sort zae codpr unite
  save "$dataout_nsu\ehcvm_nsu_zae_${pays}.dta", replace /* niveau Zone agroecologique */
restore

 
preserve
  collapse (median) poids, by(codpr unite)
  sort codpr unite
  save "$dataout_nsu\ehcvm_nsu_nat_${pays}.dta", replace /* niveau national */
restore

*******
******* Creation de fichiers de valeurs unitaires, à différents niveaux géographiques
******* L'objectif est d'avoir un ensemble de valeurs unitaires pour toutes les  ...
******* combinaisons produit/unité. Les valeurs moyennes et medianes sont ...
******  théoriquement calculees pour un minimum de 30 observations
******

use "$datain_men/s00_me_${pays}.dta",  clear 
drop if s00q08==3
keep vague grappe menage s00q01 s00q02 s00q03 s00q04
merge 1:m grappe menage using "$datain_men/s07b_me_${pays}.dta"
keep if _merge  == 3
drop _merge

tab1 s07bq07* if s07bq06>=4 

/* il faut s'assurer que les sauts ont bien marché pour les produits dont les achats n'ont pas été faits dans les 30 derniers jours : c'est ok */

keep if s07bq06 <=3

gen region=s00q01
gen milieu=s00q04
rename s07bq01 codpr

*** Define agroecological zones (definition 1)

///////////////*Creation de zae pour la CIV
recode region (4 7 11 21 29 33=1 "CENTRE") ///
			  (2 6 12 18 27=2 "CENTRE-OUEST")  ///
              (3 8 10 14 19 20 22 23 24 28 32=3 "NORD") ///
			  (1 5 13 16 26 30=4 "SUD-EST") ///
			  (9 15 17 25 31=5 "SUD-OUEST") ///
			  (0=6 "ABIDJAN"), gen(zae)
replace zae=6 if region==1 & milieu==1 
label var zae "Zone agroecologique"
lab var zae "Zones Agro-Ecologiques"
tab zae, m 
tab region zae, m

*creation de zaemil
egen zaemil = group(zae milieu)
tab zaemil zae
label def zaemil 1 "CENTRE (urbain)" 2 "CENTRE (rural)" ///
				 3 "CENTRE-OUEST (urbain)" 4 "CENTRE-OUEST (rural)" ///
				 5 "NORD (urbain)" 6 "NORD (rural)" ///
				 7 "SUD-EST (urbain)" 8 "SUD-EST (rural)" ///
				 9 "SUD-OUEST (urbain)" 10 "SUD-OUEST (rural)" ///
				 11 "ABIDJAN", replace
label val zaemil zaemil

* Creation de milieu2
gen     milieu2 = (region==1 & milieu==1)
replace milieu2 = 2 if milieu==1 & milieu2 ==0
replace milieu2 = 3 if milieu==2 & milieu2 ==0
label define milieu2 1 "Abidjan urbain" 2 "Autre urbain" 3 "Rural" 
label values milieu2 milieu2

*Creation de unité 
gen unite=s07bq07b*10+s07bq07c  
label var unite "s07bq07b*10 + s07bq07c"

do "$prog\codpr2_label_civ.do"
label val codpr codprl
do "$prog\format_unite_civ_fev2023.do"
label val unite unitel

*Unit value
recode s07bq08 (99 999 9999 99999 =.)
gen vu = s07bq08/s07bq07a
label var vu "Valeurs unité"

*Pour les valeurs aberrantes

egen vu_low=pctile(vu), p(25) by(region codpr unite)
egen vu_upp=pctile(vu), p(75) by(region codpr unite)
egen piqr=iqr(vu), by(region codpr unite)
gen vumin=vu_low-(1.5*piqr)							
gen vumax=vu_upp+(1.5*piqr)

gen flag1=vu<vumin
gen flag2=vu>vumax & vu<.   // Modification sur le ND /

tab codpr flag1 


tab codpr flag2 

replace vu=vumin if flag1==1 // Les valeurs unitaires anormalement faibles ou anormalement elevées ont été corrigées
replace vu=vumax if flag2==1

********************************************************************************

scalar min_obs=30

*Au niveau zae milieu vague
egen n_zmv=count(vu), by(zaemil vague codpr unite)
bysort vague zaemil codpr unite: egen vuam_med = median(vu) if n_zmv >= min_obs
bysort vague zaemil codpr unite: egen vuam_mean = mean(vu) if n_zmv >= min_obs

preserve
  collapse (mean) vuam_med vuam_mean n_zmv, by(zaemil zae milieu vague codpr unite)
  save "$dataout_p\ehcvm_pu_zaemil_${pays}_unit.dta", replace
restore

*Au niveau zae vague
egen n_zv =count(vu), by(zae vague codpr unite)
bysort zae vague codpr unite: egen vua_med = median(vu) if n_zv >= min_obs
bysort zae vague codpr unite: egen vua_mean = mean(vu) if n_zv >= min_obs

preserve
  collapse (mean) vua_med vua_mean n_zv, by(zae vague codpr unite)
  save "$dataout_p\ehcvm_pu_zae_${pays}_unit.dta", replace
restore

*Au niveau milieu vague
egen n_mv =count(vu), by(milieu vague codpr unite)
bysort zae milieu vague codpr unite: egen vunm_med = median(vu) if n_mv >= min_obs
bysort zae milieu codpr unite: egen vunm_mean = mean(vu) if n_mv >= min_obs

preserve
  collapse (mean) vunm_med vunm_mean n_mv, by(milieu vague codpr unite)
  save "$dataout_p\ehcvm_pu_milieu_${pays}_unit.dta", replace
restore


*Au niveau milieu2 vague
egen n_mv2 =count(vu), by(milieu2 vague codpr unite)
bysort zae vague codpr unite: egen vunm2_med = median(vu) if n_mv2 >= min_obs
bysort zae vague codpr unite: egen vunm2_mean = mean(vu) if n_mv2 >= min_obs

preserve
  collapse (mean) vunm_med vunm_mean n_mv, by(milieu2 vague codpr unite)
  save "$dataout_p\ehcvm_pu_milieu2_${pays}_unit.dta", replace
restore
*/


*Au niveau vague
egen n_vag =count(vu), by(vague codpr unite)
bysort vague codpr unite: egen vun_med = median(vu) if n_vag >= min_obs
bysort vague codpr unite: egen vun_mean = mean(vu) if n_vag >= min_obs
// activate code below to get values even with few obs.

preserve
  collapse (mean) vun_med vun_mean n_vag, by(vague codpr unite)
  save "$dataout_p\ehcvm_pu_nat_${pays}_unit.dta", replace
restore

*Au niveau national
egen n_nat =count(vu), by(codpr unite)
bysort codpr unite: egen vunag_med = median(vu) if n_nat >= min_obs //* correction nat au lieu de vag */
bysort codpr unite: egen vunag_mean = mean(vu) if n_nat >= min_obs  //* idem */
bysort codpr unite: egen vunag_med_any = median(vu)
bysort codpr unite: egen vunag_mean_any = mean(vu)
replace vunag_med = vunag_med_any if vunag_med==. 
replace vunag_mean = vunag_mean_any if vunag_mean==. 

preserve
  collapse (mean) vunag_med vunag_mean n_nat, by(codpr unite)
  save "$dataout_p\ehcvm_pu_nat_ag_${pays}_unit.dta", replace
restore

********************************************************************************
** Mode 
** Produire les valeurs unitaires pour l'unité modale pour chaque produit 
** en se focalisant sur les produits du panier pour le seuil de pauvreté (*_mode)  

numlabel, add
bysort codpr: egen unit_nat = mode(unite), maxmode
label val unit_nat unite
keep if unite==unit_nat
drop unite
rename unit_nat unite
gen one=1
collapse one, by(codpr unite) 
drop one
tempfile tf_mode
sort codpr unit
save `tf_mode'

*************************************************************
// Considérer une liste unique de zaemil 
use "$dataout_p\ehcvm_pu_zaemil_${pays}_unit.dta", clear
keep zaemil zae milieu

levelsof zaemil
local rlevels "`r(levels)'"
di "`rlevels'"

tab zaemil
di "`r(r)'"
di r(r)

tempfile tf_pass
tempfile tf_out
use `tf_mode', clear
save `tf_out'

// Ajout de la liste complete de codpr à celle de zaemil
foreach j in `rlevels' {
                use `tf_mode', clear
                gen zaemil=`j'
                save `tf_pass', replace
                use `tf_out'
                append using `tf_pass'
                save `tf_out', replace
}
drop if zaemil==.
save `tf_out', replace

// Traitement par vague 
				gen vague=1               
				save `tf_pass', replace
                use `tf_out'
                gen vague=2       
				append using `tf_pass'
                save `tf_out', replace

********************************************************************************
// L'on merge dans unitvalues pour compléter la liste de zaemil et codpr (pour le mode useulement)

use "$dataout_p\ehcvm_pu_zaemil_${pays}_unit.dta", clear

drop if codpr == . /* vérifier l'appariement: c'est bon */
duplicates report codpr unite zaemil vague
bys codpr unite zaemil vague: gen rk=_N
drop if rk!=1 /* Examen le pourcentage de missing 0% de missing*/

sort codpr unite
merge 1:1 codpr unite zaemil vague using `tf_out'
tab _m
keep if _m==3 | _m==2
drop if codpr ==.
drop _merge
save "$dataout_p\ehcvm_pu_zaemil_${pays}_mode.dta", replace
***

foreach i in zae milieu nat nat_ag { 
                use "$dataout_p\ehcvm_pu_`i'_${pays}_unit.dta", clear
				sort codpr unite
				merge m:1 codpr unite using `tf_mode'
				tab _m
				keep if _m==3
				drop _m
                save "$dataout_p\ehcvm_pu_`i'_${pays}_mode.dta", replace
}				
                
** S'il y a un nombre élevé de missing pour zaemil vague, imputer à un niveau d'agrégation plus élevé 

use "$dataout_p\ehcvm_pu_zaemil_${pays}_mode.dta", clear
gen vu_med = vuam_med
gen vu_mean = vuam_mean
gen vu_source = 1 if vu_med != .
gen vu_nobs = n_zmv if vu_source==1

sort zae vague codpr unite
merge m:1 zae vague codpr unite using "$dataout_p\ehcvm_pu_zae_${pays}_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 2 if vu_med ==. & vua_med !=.
replace vu_nobs = n_zv if vu_source==2
replace vu_med = vua_med if vu_med ==. & vua_med != . 
replace vu_mean = vua_mean if vu_mean ==. & vua_mean != . 

sort vague codpr unite
merge m:1 vague codpr unite using "$dataout_p\ehcvm_pu_nat_${pays}_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 4 if vu_med ==. & vun_med !=.
replace vu_nobs = n_vag if vu_source==4
replace vu_med = vun_med if vu_med ==. & vun_med != . 
replace vu_mean = vun_mean if vu_mean ==. & vun_mean != .

sort codpr unite
merge m:1 codpr unite using "$dataout_p\ehcvm_pu_nat_ag_${pays}_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 5 if vu_med ==. & vunag_med !=.
replace vu_nobs = n_nat if vu_source==5
replace vu_med = vunag_med if vu_med ==. & vunag_med != . 
replace vu_mean = vunag_mean if vu_mean ==. & vunag_mean != .

label def vu_source 1 "zae milieu vague" ///
					2 "zae vague" ///
					3 "milieu vague" ///
					4 "vague" ///
					5 "national ag" , replace
label val vu_source vu_source

keep codpr unite vague zaemil zae milieu vu_mean vu_med vu_source vu_nobs
order codpr unite vague zaemil zae milieu vu_mean vu_med vu_source vu_nobs

replace zae=1 if inlist(zaemil,1,2) & zae ==.
replace zae=2 if inlist(zaemil,3,4)  & zae ==.
replace zae=3 if inlist(zaemil,5,6)  & zae ==.
replace zae=4 if inlist(zaemil,7,8)  & zae ==.
replace zae=5 if inlist(zaemil,9,10)  & zae ==.
replace zae=6 if zaemil==11 & zae ==.

** Continuer de vérifier le pourcentage de missing 

replace milieu =1 if inlist(zaemil,1,3,5,7,9,11) & milieu ==.
replace milieu =2 if inlist(zaemil,2,4,6,8,10) & milieu ==.


save "$dataout_p\ehcvm_pu_merge_${pays}_mode.dta", replace
********************************************************************************
********************************************************************************

use "$datain_men\s07b_me_${pays}.dta", clear
drop if s07bq03a==.
merge m:1 vague grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(s00q00 s00q01 s00q02 s00q03 s00q04 s00q08 s00q23a s00q27) nogen
drop if s00q08==3

rename s00q01 region
rename s00q02 departement
rename s00q04 milieu
rename s07bq01 codpr

*Creation de unité 
gen unite=s07bq03b*10+s07bq03c  
label var unite "s07bq03b*10 + s07bq03c"

///////////////*Creation de zae pour la CIV
recode region (4 7 11 21 29 33=1 "CENTRE") ///
			  (2 6 12 18 27=2 "CENTRE-OUEST")  ///
              (3 8 10 14 19 20 22 23 24 28 32=3 "NORD") ///
			  (1 5 13 16 26 30=4 "SUD-EST") ///
			  (9 15 17 25 31=5 "SUD-OUEST") ///
			  (0=6 "ABIDJAN"), gen(zae)
replace zae=6 if region==1 & milieu==1 
label var zae "Zone agroecologique"

*Creation de zaemil
egen zaemil = group(zae milieu)
tab zaemil zae
label def zaemil 1 "CENTRE (urbain)" 2 "CENTRE (rural)" ///
				 3 "CENTRE-OUEST (urbain)" 4 "CENTRE-OUEST (rural)" ///
				 5 "NORD (urbain)" 6 "NORD (rural)" ///
				 7 "SUD-EST (urbain)" 8 "SUD-EST (rural)" ///
				 9 "SUD-OUEST (urbain)" 10 "SUD-OUEST (rural)" ///
				 11 "ABIDJAN", replace
label val zaemil zaemil

* Creation de milieu2
gen     milieu2 = (region==1 & milieu==1)
replace milieu2 = 2 if milieu==1 & milieu2 ==0
replace milieu2 = 3 if milieu==2 & milieu2 ==0
label define milieu2 1 "Abidjan urbain" 2 "Autre urbain" 3 "Rural" 
label values milieu2 milieu2

tempfile tf_7b
save `tf_7b'
keep codpr unite zaemil zae milieu vague
duplicates drop
count

merge 1:1 codpr unite zaemil zae milieu vague using "$dataout_p\ehcvm_pu_zaemil_${pays}_unit.dta"
rename _merge _merge_zaemil
gen vu_med = vuam_med
gen vu_mean = vuam_mean
gen vu_source = 1 if vu_med != .
gen vu_nobs = n_zmv if vu_source==1

merge m:1 codpr unite zae vague using "$dataout_p\ehcvm_pu_zae_${pays}_unit.dta"
rename _merge _merge_zae
replace vu_source = 2 if vu_med ==. & vua_med !=.
replace vu_nobs = n_zv if vu_source==2
replace vu_med = vua_med if vu_med ==. & vua_med != . 
replace vu_mean = vua_mean if vu_mean ==. & vua_mean != . 

merge m:1 codpr unite vague using "$dataout_p\ehcvm_pu_nat_${pays}_unit.dta"
rename _merge _merge_nat
replace vu_source = 4 if vu_med ==. & vun_med !=.
replace vu_nobs = n_vag if vu_source==4
replace vu_med = vun_med if vu_med ==. & vun_med != . 
replace vu_mean = vun_mean if vu_mean ==. & vun_mean != .

merge m:1 codpr unite using "$dataout_p\ehcvm_pu_nat_ag_${pays}_unit.dta"
rename _merge _merge_nat_ag
replace vu_source = 5 if vu_med ==. & vunag_med !=.
replace vu_nobs = n_nat if vu_source==5
replace vu_med = vunag_med if vu_med ==. & vunag_med != . 
replace vu_mean = vunag_mean if vu_mean ==. & vunag_mean != .

label def vu_source 1 "zae milieu vague" ///
					2 "zae vague" ///
					3 "milieu vague" ///
					4 "vague" ///
					5 "national ag" , replace
label val vu_source vu_source


keep codpr unite vague zaemil zae milieu vu_mean vu_med vu_source vu_nobs
order codpr unite vague zaemil zae milieu vu_mean vu_med vu_source vu_nobs
sort vague zae milieu codpr unite  
save "$dataout_p\ehcvm_pu_merge_${pays}_unit.dta", replace

// Identifier le nombre d'observations ne pouvant être valorisé
use `tf_7b', clear
merge m:1 codpr unite zaemil zae milieu vague using "$dataout_p\ehcvm_pu_merge_${pays}_unit.dta",gen(latif)

count if vu_mean ==.
count
*483 non valorisées combinaisons sur 310 807 soit 0.15% ce résultat est satisfaisant

***********
*********** Traitement des données prix. Il s'agit de créer un fichier similaire ...
*********** en corrigeant les valeurs anormales. Mais il faut évaluer l'exhaustivité ...
*********** du fichier brut. Un produit/variété n'est utile pour le calcul de 
*********** déflateurs, s'il est présent pour chaque mois, dans chaque strate (région/milieu)
***********
*

use "$datain_aux\ehcvm_prix_${pays}.dta", clear

** Dans le fichier de départ, on peut avoir pour un produit et une variété donnée, 
* plusieurs relevés dans le même mois et la même strate, les relevés se distinguent
* par un numéro 
capture drop obs_valid
capture drop poids
rename quantite poids

sort annee mois region milieu codpr variete
*** Examen du nombre d'observations valides par item et par mois 
gen obs_valid=prix!=.
tab obs_valid, m  /* 1 205 observations sur 1 541 626 avec prix ND, (0.078%) sont inutiles */


preserve
  collapse (sum) n_obs_valid_var=obs_valid, by(region milieu annee mois codpr variete)
  tab n_obs_valid_var  /* On agrège niveau variété, 606 obs. sur 344 674 sans info */ 
*
   collapse (sum) n_obs_valid_pro=n_obs_valid_var, by(region milieu annee mois codpr)
   tab n_obs_valid_pro  /* On agrège niveau produit, 8 obs. sur 135 684 sans info */
   tab mois if n_obs_valid_pro==0, m
restore
drop obs_valid

drop if prix==.     /* Suppression enregs non valides */
drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  ///
        (codpr>=617 & codpr<=619) | (codpr>=626 & codpr<=627) |  /// 
		(codpr>=637 & codpr<=639) | (codpr==645 | codpr==656) | /// 
        (codpr>=774 & codpr<=777) | (codpr>=901)     
*
gen prix_nor=prix                /*estimation des prix non standart en standart**/
replace prix_nor=1000*prix/poids if  type_produit==2 | type_produit==3
drop prix
rename prix_nor prix

*
* Avant toute opération, on détecte les valeurs anormales et on corrige
*
egen prix_low=pctile(prix), p(25) by(annee mois codpr variete)
egen prix_upp=pctile(prix), p(75) by(annee mois codpr variete)
egen piqr=iqr(prix), by(annee mois codpr variete)
gen prmin=prix_low-(2.5*piqr)							
gen prmax=prix_upp+(2.5*piqr)

gen flag1=prix<prmin
gen flag2=prix>prmax & prix<.   

tab codpr flag1 
tab codpr flag2

tab codpr region if flag1==1
tab codpr region if flag2==1

replace prix=prmin if flag1==1  /*  2274 cas sur 117795, soit 1,9% pour les produits alimentaires */
replace prix=prmax if flag2==1  /*  6706 cas sur 117795,  soit 5,7% pour les produits alimentaires */
** Il faut un retour aux données: i) variété différentes; ii) prix élevés
*
capture drop zae


//////////////
/*Creation de zae pour la CIV */
recode region (4 7 11 21 29 33=1 "CENTRE") ///
			  (2 6 12 18 27=2 "CENTRE-OUEST")  ///
              (3 8 10 14 19 20 22 23 24 28 32=3 "NORD") ///
			  (1 5 13 16 26 30=4 "SUD-EST") ///
			  (9 15 17 25 31=5 "SUD-OUEST") ///
			  (0=6 "ABIDJAN"), gen(zae)
replace zae=6 if region==1 & milieu==1 

label var zae "Zone agroecologique"


*Creation de zaemil
egen zaemil = group(zae milieu)
tab zaemil zae
label def zaemil 1 "CENTRE (urbain)" 2 "CENTRE (rural)" ///
				 3 "CENTRE-OUEST (urbain)" 4 "CENTRE-OUEST (rural)" ///
				 5 "NORD (urbain)" 6 "NORD (rural)" ///
				 7 "SUD-EST (urbain)" 8 "SUD-EST (rural)" ///
				 9 "SUD-OUEST (urbain)" 10 "SUD-OUEST (rural)" ///
				 11 "ABIDJAN", replace
label val zaemil zaemil


drop prmin flag1 prmax flag2 prix_low prix_upp piqr /*variete_desc2*/
sort annee mois region milieu codpr variete
save "$dataout_temp\ehcvm_prix_${pays}_cor.dta", replace
**pas d'ouverture de ehcvm_prix_pays a nouveau comme dans le prog ref**

*** Validité spatio-temporelle: test exhaustivité
* Procedé: détecter les variétés manquantes pour certains mois et certaines strates (région/milieu) 
* Cela suppose d'examiner pour chaque mois d'enquête, et pour chaque strate 
* si on dispose des mêmes variétés pour chaque produit manque
** Il faudrait alors déterminer comment traiter ces informations
** Pour la valorisation, on peut agréger à un niveau supérieur, mais vérifier le nbr de cas
** Pour les indices (temporel et spatial), il faut déterminer comment traiter ces cas
** Plus tard, il faut aussi détecter les produits absents dans certaines strates 
*
** On aggrège les données par mois en faisant la moyenne des relevés pour toutes les semaines  

collapse (mean) prix (first) unite poids, by(annee mois region milieu codpr variete) 

* On compte le nbr d'observations de variété pour chaque produit, chaque mois et chaque strate
bysort annee mois region milieu codpr: egen n_obs_v=count(prix)
tab codpr n_obs_v
bysort codpr: egen max_obs_v=max(n_obs_v)

* On détecte pour chaque produit, éventuellement les mois et les strates où le nbre de variétés
* est incomplet, c'est-à-dire les prix ne sont pas collectés pour toutes les variétés retenues
gen flag3=n_obs_v!=max_obs_v
tab codpr if flag3==1 
drop flag3

* Afin de détecter individuellement les observations manquantes, on crée le fichier virtuel exhaustif
* On devrait identifier et éliminer pour chaque produit, les variétés dont les prix ne
* sont pas collectés systématiquement 
preserve 
  gen un=1
  collapse (count) un, by(codpr variete)
  sort codpr variete
  gen region=1
  expandcl 33, cluster(region) generate(newcl)   /* 14 régions */
  replace region=newcl
  drop newcl
  sort region codpr variete
  gen milieu=1 
  expandcl 2, cluster(milieu) gen(newcl)
  replace milieu=newcl
  drop newcl
  sort region milieu codpr variete  
  gen mois=1
  expandcl 10, cluster(mois) gen(newcl)
  replace mois=newcl
  drop newcl  
  replace mois=11 if mois==9
  replace mois=12 if mois==10
  gen annee=2021 if mois>=11 & mois<=12
  
  replace annee=2022 if mois>=1 & mois<=8
  drop un
  order annee mois region milieu codpr variete
  sort annee mois region milieu codpr variete
  save "$dataout_temp\codpr_variete_prix.dta", replace
restore  
*
** On merge le fichier exhaustif avec le fichier de travail
order annee mois region milieu codpr variete
merge 1:1 annee mois region milieu codpr variete using "$dataout_temp\codpr_variete_prix.dta"
tab _merge
gen match_obs=_merge==3
sort annee mois region milieu codpr variete
drop _merge

*** On détecte les mois et les régions, les variétés absentes afin d'arrêter le panier avec lequel travailler
* Si une variété d'un produit est absent au moins un mois, on supprime la variété de la base

egen select_sum=sum(match_obs), by(codpr variete) 
/* On a 10 mois, 33 régions, 2 milieux, les variétés complètent devraient avoir un total de 252 */
gen select=select_sum==660
tab select
*
** Le résultat montre que les produits, même les plus courants, ont systématiquement des valeurs manquantes,
* soit en terme de mois, soit en terme de strate. On essaye deux alternatives, regrouper les régions par ZAE 
* pour une solution région, si cela ne marche pas, on essaye de grouper les mois par trimestre  
*
*
use "$dataout_temp\ehcvm_prix_${pays}_cor.dta", clear

*** On reprend en procédant à un regroupement par zae, pour avoir plus d'observations
*
collapse (mean) prix (first) unite poids, by(annee mois zaemil zae milieu codpr variete) 

* Afin de détecter individuellement les observations manquantes, on crée de même le fichier virtuel exhaustif
* On devrait identifier et éliminer pour chaque produit, les varétés dont les prix ne
* sont pas collectés systématiquement 
preserve 
  gen un=1
  collapse (count) un, by(codpr variete)
  sort codpr variete
  gen zaemil=1
  expandcl 11, cluster(zaemil) generate(newcl)   /* 8 zae */
  replace zaemil=newcl
  drop newcl
  sort zaemil codpr variete
  gen mois=1
  expandcl 10, cluster(mois) gen(newcl)
  replace mois=newcl
  drop newcl 
  
  replace mois=11 if mois==9
  replace mois=12 if mois==10
  gen annee=2021 if mois==12 | mois==11
  replace annee=2022 if mois>=1 & mois<=8
  drop un
  order annee mois zaemil codpr variete
  sort annee mois zaemil codpr variete
  save "$dataout_temp\codpr_variete_prix.dta", replace
restore  

** On merge le fichier exhaustif avec le fichier de travail
order annee mois zaemil codpr variete
merge m:1 annee mois zaemil codpr variete using "$dataout_temp\codpr_variete_prix.dta"
tab _merge
gen match_obs=_merge==3
sort annee mois zaemil codpr variete
drop _merge

*** On détecte les mois et les régions, les variétés absentes afin d'arrêter le panier avec lequel travailler
* Si une variété d'un produit est absent au moins un mois, on supprime la variété de la base

egen select_sum=sum(match_obs), by(codpr variete) 
/* On a 10 mois, 11 zae/milieux, les variétés complètent devraient avoir un total de 110 */
gen select=select_sum==110
tab select

lab var select "Varieté exhaustive niveau zae/milieu"

drop match_obs select_sum
drop if prix==. //suppression des lignes vides
save "$dataout_temp\ehcvm_prix_exhaustif_${pays}_cor.dta", replace

*** Panier des produits/variétés ayant une information exhaustive

keep if select==1
collapse (count) mois, by (codpr)


save "$dataout_temp\produit_exhaustif_${pays}.dta", replace
