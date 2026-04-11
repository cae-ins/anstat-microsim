*******************************************************************************
* Enquete harmonisee sur les conditions de vie des menages-UEMOA - Episode 2  *
*                           Analyse de la pauvreté                            *
*         Creation du fichier des caractéristiques sociodemographiques        *
*  Programme régional adapté pour la CIV(version Mars 2023))                  *
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
log using "$prog\ehcvm_${pays}_pgm01.log", replace text   

***********
********************* Lecture des fichiers au niveau individuel **************************
***********

use "$datain_men\s01_me_${pays}.dta", clear 
merge 1:1 grappe menage individu using "$datain_men\s02_me_${pays}.dta", nogen
merge 1:1 grappe menage individu  using "$datain_men\s03_me_${pays}.dta", nogen
merge 1:1 grappe menage individu using "$datain_men\s04_me_${pays}.dta",nogen
merge 1:1 grappe menage individu using "$datain_men\s06_me_${pays}.dta", nogen 

*drop if s01q00a==2 //* ôter de la base les individus ayant quitté le ménage (à adapter pour la CIV à partir de la section panel) */  

merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(s00q00 s00q01 s00q02 s00q03 s00q04 s00q08 s00q23a s00q27 panel)
drop _merge
desc s00*

rename s00q01 region
rename s00q02 departement
rename s00q03 sp_commune
rename s00q04 milieu

label var region "Region de residence"
label var departement  "Département  de residence"
label var sp_commune "Sous préfecture ou commune de résidence"
label var milieu "Milieu residence"		

tab s00q08 s01q01, m 
tab s00q08 s01q02, m 

drop if s00q08!=1 & s00q08!=2  /* Conserver les ménages avec un questionnaire valide : pas b'observations non valides */

***********
********************* Informations générales
***********

gen str country= "CIV"
gen year=2021																
destring grappe, replace
gen hhid=grappe*100+menage 

rename individu numind

////////////////*Creation de zae pour la CIV
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


label var country "Pays" 
label var year "Annee enquete"
label var hhid "Idenfiant menage"
label var grappe "Numero de grappe"
label var menage "Numero du menage"
label var numind "Numero individu"
label var zae "Zone agroecologique"
lab var region "Region residence"
label var departement  "Département  de residence"
label var sp_commune "Sous préfecture ou commune de résidence"	
lab var milieu "Milieu residence"
lab var milieu2 "Milieu residence avec Abidjan"

tab zae, m
tab zaemil, m

sort grappe menage numind

******
****** Caractéristiques sociodemographiques de base ****************************
******

/* Examiner les ménages avec un grand nombre de variables avec ND au niveau individuel.  
   Si de tels ménages existent dans les bases de données, il faudrait les supprimer */

* 
tab1 s01q01 s01q02 region departement milieu, m 

drop if numind==.  /* individus créés artificiellement: il n'y en a pas */

preserve 
gen resid=0
replace resid=1 if (s01q12==1) | (s01q12==2 & s01q13==1)
keep if resid==1

  collapse (count) hhsize=numind (first) vague milieu, by(grappe menage)
  tab vague milieu
  sum hhsize
  save "$dataout_temp\hhsize.dta",  replace 
restore  

/*** On dénombre 19 969 ménages. Pour la vague 1: 6 479 (dont 2 724 urbain et 3 755 ruraux); 
         Pour la vague 2: 6 490 (dont 2 519 urbain et 3 971 ruraux) ***/
		 
tab1 s01q01 s01q02 region   milieu, m /* 64 496 individus */
rename s01q01 sexe
rename s01q02 lien
tab lien, m  /* chaque ménage a un chef unique */
tab numind, m /* il n'y a que 12 969 numeros 1*/
replace numind=1 if lien==1 & numind!=1 //0 cas

replace s01q12=1 if (s01q12==2 & s01q13==2) & lien==1  /* Aucun CM visiteur, good */
replace s01q13=. if s01q12==1 & s01q13!=. // aucun cas

*** Situation de residence, les visiteurs seront exclus de l'analyse
tab1 s01q11 s01q12 s01q13, m
gen resid=0
replace resid=1 if (s01q12==1) | (s01q12==2 & s01q13==1)
tab resid s01q11, m
tab resid s01q12, m
lab def ouinon 1"Oui" 0"Non"
lab val resid ouinon
tab lien resid 

*** Reverification sur le nombre de CM dans le menage
gen cm=lien==1
egen ncm=total(cm), by(grappe menage)
gen flag=ncm!=1
list grappe menage numind ncm lien if flag==1 
drop flag

*** Verification sur les menages sans individu avec le numero 1
gen pm=numind==1
egen npm=total(pm), by(grappe menage)
gen flag=npm!=1
list grappe menage numind npm lien if flag==1  
drop flag
gen flag=lien==1 & resid!=1
list grappe menage numind lien resid if flag==1 
drop flag

*** calcul de l'age utilisant les dates de naissance et celle debut enquete
tab1 s01q03a s01q03b s01q03c, m
replace s01q03a=15 if (s01q03a==9999) & (s01q03c!=. & s01q03c!=9999) /* impute day=15 if NR, but year valid */
replace s01q03b=6 if (s01q03b==9999) & (s01q03c!=. & s01q03c!=9999) /* impute month=6, if NR but year valid */ 
replace s01q03a=30 if s01q03a==31 & s01q03b==6 /* deux individus nés le 31 juin, on corrige le 30 juin */
** Convert date of birth in string
recode s01q03a (9999 .a . =.)
recode s01q03b (9999 .a . =.)
recode s01q03c (9999 .a . =.)
tostring s01q03a, gen(nj) 
tostring s01q03b, gen(nm) 
tostring s01q03c, gen(na) 
egen dob=concat(nm nj na), punc(" ")
gen ddn=date(dob, "MDY") 
format ddn %tdMon_DD_CCYY 
lis ddn in 1/30
list s00q23 in 1/30
** Convert date of survey
gen ea=substr(s00q23,1,4)
gen em=substr(s00q23,6,2)
gen ej=substr(s00q23,9,2)
egen dd1=concat(em ej ea)
gen dde=date(dd1, "MDY") 
format dde %tdMon_DD_CCYY 
lis dde in 1/30
** compute age
gen age=int((dde-ddn)/365) /* 3 919 individus (sur 64 505) ne connaissent par leur ddn, pas mal */
replace age=s01q04a if age==. 
sum age 
tab age, m  /* il y a 10 individus de plus de 100 ans, même un à 122 ans */

* Traitement de la variable etat matrimonial  
tab s01q07 if age>10, m
clonevar mstat=s01q07
replace mstat=1 if age<10  /* les moins de 10 ans sont classés célibataire */
tab mstat, m    /* 12 individus avec mstat en NR */
list lien age sexe if mstat==. /* les 12 individus sont des enfants de 10 ans, on impute */
recode mstat (.a=.)
replace mstat=1 if mstat==. & age <16

* Variables religion, ethnie, nationalité
tab1 s01q14 s01q15 s01q16, m
clonevar religion=s01q14
clonevar nation=s01q15
clonevar ethnie=s01q16
tab religion resid, m
tab nation resid, m
tab ethnie resid, m
tab ethnie if nation==15, m 
egen ethm=mode(ethnie), by(grappe menage) missing minmode
replace ethnie=ethm if ethnie==. & resid==1 & nation==15 
gen agemar=s01q10 
*
lab var sexe "Genre"
lab var age "Age en annees"
lab var lien "Lien de parente"
lab var mstat "Situation de famille"
lab var resid "Resident"
lab var religion "Religion"
lab var nation "Nationalité"
lab var ethnie "Ethnie"
lab var agemar "Age premier marriage"  

tab1 sexe lien mstat resid religion nation ethnie, m
sum age agemar

******
******  Caracteristiques de l'education  **************************************
****** 

*** Alphabétisation  
tab1 s02q01__1 s02q01__2 s02q01__3 s02q02__1 s02q02__2 s02q02__3, m
tab1 s02q02a__1 s02q02a__2 s02q02a__3, m
gen alfa=(s02q01__1==1 & s02q02__1==1) | ///
         (s02q01__2==1 & s02q02__2==1) | ///
         (s02q01__3==1 & s02q02__3==1) 
gen alfa2=((alfa==1) & (s02q02a__1==1 | s02q02a__2==1 | s02q02a__3==1)) 
lab var alfa "Alphabet. lire/ecrire"
lab var alfa2 "Alphabet. lire/ecrire/comprend."

lab val alfa alfa2 ouinon
tab alfa resid, m
tab alfa if resid==1 & age>=3, m
tab alfa2 resid, m
tab alfa2 if resid==1 & age>=3, m

*** Education/Scolarisation    
** Fréquentation scolaire en 2020/21 
gen scol=(s02q12==1)
lab var scol "Freq. ecole 2020/21"
lab val scol ouinon 

** Niveau scolaire actuel, ind. scolarisés en 2020/21  
clonevar educ_scol=s02q14
tab educ_scol scol, m
lab var educ_scol "Niv. educ. actuel"  
tab educ_scol scol if age>=3 & s02q03==1 & s02q12==1, m 
tab s02q29 if age>=3 & s02q03==1 & s02q12==2, m 

/** Niveau d'études le plus élevé: ind. qui n'ont pas fréquenté l'école 
   2020/21 ou qui n'ont jamais été à l'école */                                               
recode s02q29 (.a=.)      
gen educ_hi=s02q29+1 if s02q29>=1 & s02q29<. 
replace educ_hi=1 if (s02q29==.) & ((s02q03!=1) | (s02q03==1 & scol==0))  /* 0 ind. restant en ND, revoir */
replace educ_hi=educ_scol+1 if educ_hi==. & s02q03==1 
lab var educ_hi "Niv. educ. acheve"
lab def educl 1"Aucun" 2"Maternelle" 3"Primaire" 4"Second. gl 1" 5"Second. tech. 1" 6"Second. gl 2" ///
              7"Second. tech. 2" 8"Postsecondaire" 9"Superieur"
lab val educ_hi educl

* Diplôme
clonevar diplome=s02q33
recode diplome (. .a=0)
lab var diplome "Diplome plus eleve"

***** Autres variables d'éducation
gen telpor=s01q36==1
gen internet=s01q39__1==1 | s01q39__2==1 | s01q39__3==1 | s01q39__4==1 | s01q39__5==1
lab var telpor "Individu a telephone portable"
lab var internet "Individu a acces internet"
lab val telpor internet ouinon
tab1 alfa alfa2 scol educ_scol educ_hi diplome telpor internet, m 

******
******  Caracteristiques sante *************************************************
****** 

* Maladie et consultation au cours des 30 derniers jours
gen mal30j=s03q01==1 
lab var mal30j "Prob. sante 30 dern. jours"
tab mal30j s03q05, m 
gen con30j=1 if mal30j==1 & s03q05==1 
replace con30j=0 if mal30j==1 & s03q05!=1
replace mal30j=0 if mal30j==1 & s03q05==.
lab var con30j "Consulte 30 dern. jours"

tab1 con30j if mal30j==1, m 

****************************************************************
clonevar aff30j=s03q02
tab aff30j mal30j, m
lab var aff30j "probleme sante"
gen arrmal=s03q03==1
lab var arrmal "Arret activite pour maladie"
clonevar durarr=s03q04
lab var durarr "Duree arret activite pour maladie"
gen moustiq=s03q39==1 | s03q39==2
lab var moustiq "Dormi moustiquire nuit dern."
lab val moustiq ouinon
gen couvmal=s03q32==1
lab var couvmal "Indivu couverture maladie"
lab val arrmal couvmal ouinon
tab1 arrmal couvmal moustiq durarr, m
*
recode s03q07 (1 2 3 7 8=1)(4 5 =2) (6 9 10 11 12 13=3), gen(serviceconsult)
replace serviceconsult=4 if mal30j==1 & serviceconsult==.
lab def serviceconsult 1 "Hôpital/Clinique" 2 "Dispensaire" 3 "Autres" 4 "Pas de consultation"
lab val serviceconsult serviceconsult
lab var serviceconsult "Service de santé consulté"
*
recode s03q08 (1 2 3=1)(4 =2) (5 6 7 8 9 10 11  =3), gen(persconsult)
replace persconsult=4 if mal30j==1 & persconsult==.
lab def persconsult 1 "Médecin" 2 "Infirmier" 3 "Autres" 4 "Pas de consultation"
lab val persconsult persconsult
lab var persconsult "Personnel de santé consulté"

* Hospitalisation au cours des 12 derniers mois
gen hos12m=s03q19==1
lab var hos12m "Hospitalisation 12 der. mois"

* Handicap 
tab1 s03q41 s03q42 s03q43 s03q44 s03q45 s03q46, m /* 3935 individus NC, vérifier si moins de 5 ans */
forval num = 41/46 {  /* recoder les moins de 5 ans en NC */
  replace s03q`num'=5 if s03q`num'==. & age<5
         }
* 
tab1 s03q41 s03q42 s03q43 s03q44 s03q45 s03q46, m 
/* Reste 33 individus (0.11%) avec valeurs manquantes, imputer au mode */         
forval num = 41/46 {  
  replace s03q`num'=1 if s03q`num'==. 
         }
*
gen handit=((s03q41>=2 & s03q41<=4) | (s03q42>=2 & s03q42<=4) |  ///
             (s03q43>=2 & s03q43<=4) | (s03q44>=2 & s03q44<=4) |  ///
             (s03q45>=2 & s03q45<=4) | (s03q46>=2 & s03q46<=4)) &  ///
			 (age >= 5) 
replace handit=. if age<5
tab handit, m 
gen handig=((s03q41>=3 & s03q41<=4) | (s03q42>=3 & s03q42<=4) |  ///
             (s03q43>=3 & s03q43<=4) | (s03q44>=3 & s03q44<=4) |  ///
             (s03q45>=3 & s03q45<=4) | (s03q46>=3 & s03q46<=4)) &  ///
			 (age >= 5) 
replace handig=. if age<5
tab handig, m 
lab var handit "Handicap tout niveau"
lab var handig "Handicap majeur seul"
lab define ab1 1 "Oui" 0 "Non", replace
lab val mal30j con30j hos12m handit handig ab1

tab1 mal30j con30j hos12m handit handig, m

******
******  Caracteristiques du marché du travail *********************************
****** 

/*
*** Reclasser les travailleurs familiaux non rémunérés comme sans emploi
replace s04q06=2 if s04q06==1 & s04q39==8
replace s04q07=2 if s04q07==1 & s04q39==8
replace s04q08=2 if s04q08==1 & s04q39==8
replace s04q09=2 if s04q09==1 & s04q39==8
*/

//* Activité du moment
gen activ7j=6 if age<5
replace activ7j=5 if age>=5
replace activ7j=1 if age>=5 & (s04q06==1 | s04q07==1 | s04q08==1 | s04q09==1) 
replace activ7j=1 if age>=5 & s04q11==1
replace activ7j=2 if age>=5 & s04q13==1 & s04q15==1
replace activ7j=3 if age>=5 & s04q13==1 & s04q15==2
replace activ7j=2 if age>=5 & activ7j==5 & s04q14==1 & s04q15==1
replace activ7j=3 if age>=5 & activ7j==5 & s04q14==1 & s04q15==2
replace activ7j=4 if age>=5 & activ7j==5 & s04q17==1 
lab var activ7j "Situation activite 7 derniers jours"
lab def activl 1"Occupe" 2"TF cherchant emploi" 3"TF cherchant pas" 4"Chomeur" 5"Inactif" 6"Moins de 5 ans"
lab val activ7j activl
tab lien activ7j, m

//* Activité habituelle
gen activ12m=4 if age<5
replace activ12m=3 if age>=5
replace activ12m=2 if activ7j==2 | activ7j==3
replace activ12m=1 if activ7j==1 
replace activ12m=1 if activ7j!=1 & s04q27==1
lab var activ12m "Situation activite 12 derniers mois
lab def activl2 1"Occupe" 2"Trav. fam." 3"Non occupe" 4"Moins de 5 ans"
lab val activ12m activl2
tab lien activ12m, m

* Branches d'Activité
tab s04q30d if s04q27!=2 & age>=5,m  /* 41 ind. sans branche, imputer avec info. aux. (SI, profession) */
tab s04q30d if s04q27!=2 & age>=5,m nolab 

gen branch=s04q30d  if inlist(activ12m,1,2) 
lab var branch "Branche activite"

recode branch (11/23=1) (31/53=2) (100/143=3) (151/362=4) (370/457=5) ///
              (501/527=6) (551/572=7) (601/633 641/643=8) (800/853=9) ///
			  (651/754 900/990=11) 
			  
lab def brl 1"Agriculture" 2"Elevage/syl./peche" 3"Indust. extr." 4"Autr. indust." 5"BTP" ///
            6"Commerce" 7"Restaurant/Hotel" 8"Trans./Comm." 9"Education/Sante" ///
			10"Services perso." 11"Aut. services" 
lab val branch brl
tab branch activ12m if s04q27!=2 , m 
            
* Secteur institutionnel                                           
clonevar sectins=s04q31
lab var sectins "Sect. institutionnel empl. prin."
tab sectins activ12m, m 
*replace sectins=3 if sectins==.a & activ12m==1 /* 2 cas peut-être affiner */
*tab sectins activ12m, m 

* Catégorie socioprofessionnelle 
clonevar csp=s04q39
lab var csp "CSP empl. prin."
tab csp activ12m, m 
replace csp=1 if csp==. & activ12m==1  /* 5 cas */
tab csp activ12m, m 
tab csp sectins if activ12m==1, m
tab csp sectins if activ12m==2, m

tab1 activ7j activ12m branch sectins csp, m 

// Modifications
*** Volume horaire de travail 
sum s04q32 s04q33 s04q34 s04q36 s04q37 if activ12m==1
recode s04q32 s04q34 (9999 .a .=.)
sum s04q32 s04q34
egen med_s04q32=median(s04q32), by(csp)
replace s04q32=0.5 if activ12m==1 & s04q32==0 
replace s04q32=med_s04q32 if activ12m==1 & (s04q32==.) /* 40 cas sur 9374 */
egen med_s04q37=median(s04q37), by(csp)
replace s04q37=med_s04q37 if activ12m==1 & (s04q37==0 | s04q37==.a) /* 18 cas sur 9374 */
tab s04q33 activ12m, m
gen conge=12*s04q34/365 if (s04q33==1) & (s04q34>0 & s04q34<.)
egen med_conge=median(conge), by(csp)
replace conge=med_conge if (s04q33==1) & (s04q34>0 & s04q34<.) & (conge==.)  
replace conge=0 if s04q33==2
sum conge
gen moistrav=s04q32-conge
sum moistrav
// Corrections valeurs extrêmes variables s04q36 et s04q37
tabstat s04q36 if activ12m==1, by(csp) stat(min p5 p25 p50 p75 p95 max)
gen j_mois=s04q36 if activ12m==1
replace j_mois=25 if (activ12m==1) & (j_mois>=25 & j_mois<.)
tabstat s04q37 if activ12m==1, by(csp) stat(min p5 p25 p50 p75 p95 max)
gen hor=s04q37 if activ12m==1
egen max_hor=pctile(hor), by(csp) p(95)
replace hor=max_hor if activ12m==1 & hor>max_hor & hor<.
gen volhor=moistrav*j_mois*hor if activ12m==1 
sum volhor 
lab var volhor "Horaire an. travail empl. prin."

*** Salaires
sum s04q43 s04q43_unite s04q44 s04q45 s04q45_unite s04q46 s04q47 s04q47_unite ///
    s04q48 s04q49 s04q49_unite if csp>=1 & csp<=6
*
recode s04q43 s04q45 s04q47 s04q49 (. .a=0)
local numb "43 45 47 49"
foreach x of local numb {
  gen unite`x'=52 if s04q`x'_unite==1
  replace unite`x'=12 if s04q`x'_unite==2
  replace unite`x'=4 if s04q`x'_unite==3
  replace unite`x'=1 if s04q`x'_unite==4
  gen sal`x'=s04q`x'*unite`x'
        }
*	
sum sal43 sal45 sal47 sal49 if csp>=1 & csp<=6	
recode sal43 sal45 sal47 sal49 (.=0)	
gen salaire=sal43+sal45+sal47+sal49 if csp>=1 & csp<=6
replace salaire=. if csp>=7
lab var salaire "Salaire an. empl. prin." 	
sum salaire if csp>=1 & csp<=6
gen flag=salaire==0 & csp>=1 & csp<=6
tab flag if csp>=1 & csp<=6  /*  1,445 cas de salaire ND sur 5304, imputation */
*
gen lsal=ln(salaire)
gen exper=age-7
gen exper2=exper^2

gen nivs=educ_scol+1 if scol==1
replace nivs=educ_hi if scol==0
gen class=s02q16 if scol==1
replace class=s02q31 if scol==0
*
gen aned=0 if nivs<=2
replace aned=min(class, 6) if nivs==3
replace aned=6+min(class, 4) if nivs==4 | nivs==5
replace aned=10+min(class, 3) if nivs==6 | nivs==7
replace aned=13+min(class, 2) if nivs==8
replace aned=13+min(class, 9) if nivs==9
*
tabulate csp, gen(csp_)
gen feminin=sexe==2
gen rural=milieu==2
local varsal "exper exper2 aned feminin csp_1 csp_2 csp_3 csp_4 csp_5 rural"
regress lsal `varsal'
predlog salaire `varsal' 
replace salaire=YHTSMEAR if (activ12m==1) & (salaire==0) & (csp>=1 & csp<=6)  
sum salaire
drop YH*


*** Caracteristiques emploi secondaire
gen emploi_sec=s04q50==1
lab var emploi_sec "A un emploi secondaire 12 mois"
lab val emploi_sec ouinon

clonevar sectins_sec=s04q53
lab var sectins_sec "Secteur instit. emploi sec."
tab sectins_sec emploi_sec, m  
clonevar csp_sec=s04q57
lab var csp_sec "CSP emploi sec."
tab csp_sec sectins_sec, m 

*** Volume horaire et salaire en emploi secondaire
sum s04q54 s04q55 s04q56 if emploi_sec==1
egen med_s04q54=median(s04q54), by(csp_sec)
replace s04q54=med_s04q54 if emploi_sec==1 & s04q54==0 /* aucun cas */
replace s04q55=30 if s04q55==31 /* aucun cas */
gen volhor_sec=s04q54*s04q55*s04q56 if emploi_sec==1 
sum volhor_sec 
lab var volhor_sec "Horaire an. travail emploi sec."
*
sum s04q58 s04q58_unite s04q59 s04q60 s04q60_unite s04q61 s04q62 s04q62_unite ///
    s04q63 s04q64 s04q64_unite if csp_sec>=1 & csp_sec<=6
*
recode s04q58 s04q60 s04q62 s04q64 (. .a=0)
local numb2 "58 60 62 64"
foreach x of local numb2 {
  gen unite`x'=52 if s04q`x'_unite==1
  replace unite`x'=12 if s04q`x'_unite==2
  replace unite`x'=4 if s04q`x'_unite==3
  replace unite`x'=1 if s04q`x'_unite==4
  gen sal`x'=s04q`x'*unite`x'
        }
		
*
sum sal58 sal60 sal62 sal64 if csp_sec>=1 & csp_sec<=6
recode sal58 sal60 sal62 sal64 (.=0)	
gen salaire_sec=sal58+sal60+sal62+sal64 if csp_sec>=1 & csp_sec<=6
replace salaire_sec=. if csp_sec>=7
lab var salaire_sec "Salaire an. emploi sec." 	
sum salaire_sec

******
******  Autres caracteristiques ***********************************************
****** 
gen bank=s06q01__1==1 | s06q01__2==1  | s06q01__3==1 | s06q01__4==1    
lab var bank "compte banque ou autre"
lab val bank ouinon
tab bank, m
*


merge m:1 grappe menage using "$datain_aux\ehcvm_ponderations_${pays}.dta"
drop _merge

ren poids hhweight
lab var hhweight "Ponderation menage"


******
******   Sauvegarde fichier individuel ****************************************
****** 

keep country year vague hhid grappe menage panel numind zae zaemil region departement sp_commune milieu /// 
     hhweight resid sexe age lien mstat religion ethnie nation agemar ///
	 mal30j aff30j arrmal durarr con30j hos12m couvmal moustiq handit handig serviceconsult persconsult ///
	 alfa alfa2 scol educ_scol educ_hi diplome telpor internet ///
	 activ7j activ12m branch sectins csp volhor salaire ///
	 emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank 

order country year hhid grappe menage panel  numind vague zae zaemil region departement sp_commune milieu /// 
      hhweight resid sexe age lien mstat religion ethnie nation agemar ///
	  mal30j aff30j arrmal durarr con30j hos12m couvmal moustiq handit handig handig ///
	  alfa alfa2 scol educ_scol educ_hi diplome telpor internet ///
	  activ7j activ12m branch sectins csp volhor salaire ///
	  emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank 

sort hhid numind
compress
des

save "$dataout\ehcvm_individu_${pays}.dta", replace

*********************************** Chocs *************************************
use "$datain_men\s14b_me_${pays}.dta", clear 

sort grappe menage s14bq01
gen hhid=grappe*100+menage 
sort hhid s14bq01
gen sh_id_demo=(s14bq01>=101 & s14bq01<=103) & (s14bq02==1)
gen sh_co_natu=((s14bq01>=104 & s14bq01<=108) | (s14bq01>=120 & s14bq01<=121)) & (s14bq02==1)
gen sh_co_eco=(s14bq01>=109 & s14bq01<=111) & (s14bq02==1) 
gen sh_id_eco=(s14bq01>=112 & s14bq01<=117) & (s14bq02==1)
gen sh_co_vio=(s14bq01==118 | s14bq01==119) & (s14bq02==1) 
gen sh_co_oth=(s14bq01==122) & (s14bq02==1)    

collapse (sum) sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth, by(hhid) 
recode sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth (0=0) (1/9=1) 
lab var sh_id_demo "Choc idio démographique"
lab var sh_co_natu "Choc covariant naturel"
lab var sh_co_eco "Choc covariant économique"
lab var sh_id_eco "Choc idio économique"
lab var sh_co_vio "Choc covariant violence"
lab var sh_co_oth "Autres Chocs"     

lab val sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth ouinon  
tab1 sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth , m 
sort hhid 
save "$dataout_temp\ehcvm_menage0_${pays}.dta", replace 
*
*
****************************** Taille du cheptel *******************************
use "$datain_men\s17_me_${pays}.dta", clear 

sort grappe menage s17q01 
gen hhid=grappe*100+menage 

sum s17q05
recode s17q05 (.=0)
gen grosrum=s17q05 if s17q01==1 | s17q01==4 | s17q01==5 | s17q01==6 
gen petitrum=s17q05 if s17q01==2 | s17q01==3 
gen porc=s17q05 if s17q01==7 
gen lapin=s17q05 if s17q01==8 
gen volail=s17q05 if s17q01==9 | s17q01==10 | s17q01==11 

collapse (sum) grosrum petitrum porc lapin volail, by(hhid)
sum grosrum petitrum porc lapin volail
lab var grosrum "Nbr gros ruminants"
lab var petitrum "Nbr petits ruminants"
lab var porc "Nbr porcs"
lab var lapin "Nbr lapins"
lab var volail "Nbr volailles"

merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_${pays}.dta"
drop _merge
sort hhid 
save "$dataout_temp\ehcvm_menage0_${pays}.dta", replace 
*
*
****************************** Superficies agricoles **************************
use "$datain_men\s16a_me_${pays}.dta", clear 
sort grappe menage s16aq02 s16aq03
drop if s16aq02==. & s16aq03==. & s16aq04==.
gen hhid=grappe*100+menage 
recode s16aq09a s16aq47 (.=0)
replace s16aq47=s16aq47/10000 if s16aq47>=100 & s16aq47<. /* q47 est déclarée en m2 et en ha, nous tentons cette correction, mais il faut retravailler cette variable */ 
gen sup_dec=s16aq09a if s16aq09b==1
replace sup_dec=s16aq09a/10000 if s16aq09b==2
gen sup_mes=s16aq47
sum sup_dec if sup_dec>0 & sup_dec<.
sum sup_mes if sup_me>0 & sup_mes<.

gen fl0=(sup_dec>0 & sup_dec<.) & (sup_mes>0 & sup_mes<.)
gen fl1=(sup_dec>0 & sup_dec<.) & (sup_mes==0 | sup_mes==.)
gen fl2=(sup_dec==0 | sup_dec==.) & (sup_mes>0 & sup_mes<.)

tab1 fl0 fl1 fl2, m

clonevar numind=s16aq04
destring numind, replace
sort grappe menage numind 
merge m:1 grappe menage numind using "$dataout\ehcvm_individu_${pays}.dta", ///
          keepusing(region milieu sexe age alfa educ_hi) 
drop if _merge==2
drop _merge
gen age2=age^2          
regress sup_mes sup_dec i.sexe age age2 i.educ_hi i.region i.milieu if fl0==1
predict sup_mes_pred if fl1==1, xb
sum sup_mes_pred if fl1==1
replace sup_mes_pred=0.1 if sup_mes_pred<0 /* 20 cas avec prédiction négative */

gen superf=sup_mes if fl0==1 | fl2==1
replace superf=sup_mes_pred if fl1==1
sum superf

collapse (sum) superf, by(hhid)
sum superf
lab var superf "Superficie agricole"

merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_${pays}.dta"
drop _merge
sort hhid 
save "$dataout_temp\ehcvm_menage0_${pays}.dta", replace 
*
*
*************************** Elements de confort *******************************
use "$datain_men\s12_me_${pays}.dta", clear 
*rename menage menage 

gen hhid=grappe*100+menage 
sort hhid s12q01
gen tv=s12q01==20 & s12q02==1
gen fer=s12q01==7 & s12q02==1
gen frigo=(s12q01==16 | s12q01==17) & (s12q02==1)
gen cuisin=s12q01==9 & s12q02==1
gen ordin=s12q01==37 & s12q02==1
gen decod=s12q01==22 & s12q02==1
gen car=s12q01==28 & s12q02==1

collapse (sum) tv fer frigo cuisin ordin decod car, by(hhid)
merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_${pays}.dta"
drop _merge

recode tv fer frigo cuisin ordin decod car (0 .=0) (1/9=1) 

lab var tv "menage a TV"
lab var fer "menage a fer electrique"
lab var frigo "menage a frigo/congel"
lab var cuisin "menage a cuisiniere elec/gaz"
lab var ordin "menage a ordinateur"
lab var decod "menage a decodeur/antenne"
lab var car "menage a voiture"

lab val tv fer frigo cuisin ordin decod car ouinon
tab1 tv fer frigo cuisin ordin decod car, m

sort hhid 
drop if hhid ==.
save "$dataout_temp\ehcvm_menage0_${pays}.dta", replace 
*
*
*************************** Caractéristiques de logement ***********************
use "$datain_men\s11_me_${pays}.dta", clear 

gen hhid=grappe*100+menage 

tab s11q04, m  /* plus du quart de ménages logé gratuit, trop peut-être(?) */
tab1 s11q18 s11q19 s11q20, m 
recode s11q04 (1 3=1) (2 4=2) (5=3) (6/8=4), gen(logem)
lab def logeml 1"Proprietaire titre" 2"Proprietaire sans titre" 3"Locataire" 4"Autre"
lab var logem "Occupation logement"
lab val logem logeml
tab1 logem, m  
gen mur=s11q18>=1 & s11q18<=4
gen toit=s11q19>=1 & s11q19<=3
gen sol=s11q20>=1 & s11q20<=2
lab var mur "Mur en materiaux definitifs"
lab var toit "toit en materiaux definitifs"
lab var sol "Sol en materiaux definitifs"
lab val mur toit sol ouinon
tab1 mur toit sol, m
*
*
gen eauboi_ss=(s11q26a>=1 & s11q26a<=4) | (s11q26a>=9 & s11q26a<=10)
replace eauboi_ss=1 if (s11q26a==7 | s11q26a==8) & (s11q31==1)
tab eauboi_ss
gen eauboi_sp=(s11q26b>=1 & s11q26b<=4) | (s11q26b>=9 & s11q26b<=10) 
replace eauboi_sp=1 if (s11q26b==7 | s11q26b==8) & (s11q31==1)
lab var eauboi_ss "eau potable saison seche"
lab var eauboi_sp "eau potable saison pluie"
lab val eauboi_ss eauboi_sp ouinon
tab1 eauboi_ss eauboi_sp, m
*
gen elec_ac=s11q33==1
gen elec_ur=s11q37==1
gen elec_ua=s11q37==2 | s11q37==3
lab var elec_ac "Acces reseau electrique"
lab var elec_ur "Utilise elec. reseau"
lab var elec_ua "Utilise elec. solaire/groupe"
lab val elec_ac elec_ur elec_ua ouinon
tab1 elec_ac elec_ur elec_ua, m
*
gen ordure=s11q53>=1 & s11q53<=2
gen toilet=s11q54>=1 & s11q54<=6
gen eva_toi=s11q57>=1 & s11q57<=3
gen eva_eau=s11q59==1 | s11q59==2
lab var ordure "Déchets évacués sainement"
lab var toilet "Toilettes saines"
lab var eva_toi "Excréments évacués sainement"
lab var eva_eau "Eaux usées évacuées sainement"
lab val ordure toilet eva_toi eva_eau ouinon
tab1 ordure toilet eva_toi eva_eau, m 
lab var hhid "Identifiant menage"

merge 1:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague s00q08)
  drop if s00q08==3
  drop if _merge==2
drop _merge
*
gen str country= "CIV"
gen year=2021			
*
keep country year hhid grappe menage vague logem mur toit sol eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
     ordure toilet eva_toi eva_eau
order country hhid grappe menage vague logem mur toit sol eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
      ordure toilet eva_toi eva_eau 	 
*
merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_${pays}.dta"
drop _merge
compress
des
sort hhid 
save "$dataout\ehcvm_menage_${pays}.dta", replace 


******
************** Indicateurs pour évaluer la qualité de l'enquête ****************
******
*
***** Indicateurs sociodémographiques 
use "$dataout\ehcvm_individu_${pays}.dta", clear

keep if resid==1
*
egen hhsize=count(numind), by(hhid)
* 
recode  age  (0/4=1) (5/14=2)  (15/64=3)  (65/max=4), gen(agecat)
lab var agecat "Age groups"
lab define agecat 1"0-4 ans" 2"5-14 ans"  3"15-64 ans"  4"65+ ans"
lab val agecat agecat
*
gen alfa100=100*alfa
*
gen scol6_11=100*cond(scol==1,1,0) if inrange(age,6,11)
label var scol6_11 "Taux net scolarisation 6-11 ans"
capture label define ouinon 1 "Oui" 0 "Non"
label val scol6_11 ouinon

*** Effectif ménages échantillon
tabout milieu if lien==1 using "$dataout\ehcvm2_indicators_${pays}.xls", cells (freq) f(0c) replace

***Effectif population échantillon
tabout milieu using "$dataout\ehcvm2_indicators_${pays}.xls", cells (freq) f(0c) append 

*** Effectif ménages par région et milieu de résidence
gen un=1
tabout region milieu if lien==1 [aw=hhweight] using "$dataout\ehcvm2_indicators_${pays}.xls", sum cells (sum un) f(0c) append

*** Effectif population par région et milieu de résidence
tabout region milieu [aw=hhweight] using "$dataout\ehcvm2_indicators_${pays}.xls", sum cells (sum un) f(0c)  append 

*** Taille moyenne des ménages par région et milieu de résidence
tabout region milieu [aw=hhweight] if lien==1 using "$dataout\ehcvm2_indicators_${pays}.xls", sum c(mean hhsize) f(1c) append 

*** Structure population par milieu de résidence
tabout region milieu [aw=hhweight] using "$dataout\ehcvm2_indicators_${pays}.xls", cells (row) f(1p)  append 

*** Structure population par sexe
tabout milieu sexe [aw=hhweight] using "$dataout\ehcvm2_indicators_${pays}.xls", cells (row) f(1p) append 

*** Structure population par âge
tabout milieu agecat  [aw=hhweight] using "$dataout\ehcvm2_indicators_${pays}.xls", cells (row) f(1p) append

*** Taux d'alphabétisation des 15 ans et plus
tabout milieu [aw=hhweight] if age>=15 using "$dataout\ehcvm2_indicators_${pays}.xls", sum c(mean alfa100) f(1c) append

*** Taux de fréquentation scolaire des 6-11 ans
tabout milieu [aw=hhweight] using "$dataout\ehcvm2_indicators_${pays}.xls", sum c(mean scol6_11) f(1c) append

*** Participation au marché du travail 15-64 ans
tabout activ7j milieu if age>=15 & age<=64 [aw=hhweight] using "$dataout\ehcvm2_indicators_${pays}.xls", cells (col) f(1p)    append


