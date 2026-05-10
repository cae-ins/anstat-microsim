********************************************************************************
* 02_mapping_tax_clean.do
*
* OBJECTIF :
* Construire un mapping TVA propre et auditable par code produit (codpr),
* a partir de :
*   (1) un mapping Excel officiel importe du tableau TVA CGI 2026
*
* SORTIE FINALE :
* Un fichier final de mapping TVA au niveau produit pret a etre fusionne avec les donnees de consommation.
*
* PRINCIPES FONDAMENTAUX :
* - codpr et "produit" sont les cles de fusion
*
* INTERPRETATION ECONOMIQUE :
* - r_vat_official : taux TVA final utilise dans l'analyse
* - hors_champ : produit hors champ TVA dans le mapping officiel original
*
* NOTES :
* - Les taux TVA sont stockes en proportions : 0, 0,09, 0,18
* - La TVA manuelleentee dans Excel est supposee être en points de pourcentage : 0, 9, 18
 ********************************************************************************

clear all
set more off

 ********************************************************************************
* ETAPE 1 — Importer le mapping Excel TVA officiel
 ********************************************************************************
* Le fichier Excel attendu contient au moins :
*  code, produit, mode d'acquisition, ...


import excel "$DATA\COPR_EHCVM_TVA_renseigne.xlsx", sheet("TVA_detail") firstrow clear

 ********************************************************************************
* ETAPE 2 — Gerer le "Hors champ"
 ********************************************************************************
* "Hors champ" signifie hors du champ TVA.
* On preserve cette information avec un indicateur, mais on definit le taux brut a 0
*以便可以转换为数字形式。

gen hors_champ = (trim(TVA_statutaire) == "Hors champ")

replace hors_champ = 1 if mode != "Achat"
replace TVA_statutaire = "9999" if trim(TVA_statutaire) == "Hors champ"

 ********************************************************************************
* ETAPE 3 — Nettoyer la chaine de taux TVA brute
 ********************************************************************************
* Supprimer %, *, espaces, puis convertir en numerique.

* Supprimer %, *, espaces, puis convertir en numerique.

replace TVA_statutaire = subinstr(TVA_statutaire, "%", "", .)
replace TVA_statutaire = subinstr(TVA_statutaire, "*", "", .)
replace TVA_statutaire = trim(TVA_statutaire)

destring TVA_statutaire, replace force
ta TVA_statutaire
* Convertir du pourcentage a la proportion
gen r_vat_official = TVA_statutaire / 100

drop TVA_statutaire

 ********************************************************************************
* ETAPE 4 — Valider les taux TVA officiels importes
 ********************************************************************************

di as text ">>> Resume des taux TVA officiels"
sum r_vat_official

di as text ">>> Distribution des taux TVA officiels"
tab r_vat_official

di as text ">>> Distribution de l'indicateur hors_champ"
tab hors_champ


 ********************************************************************************
* ETAPE 5 — Verifier l'unicite de codpr dans le mapping officiel
 ********************************************************************************
* Chaque codpr doit correspondre a un profil TVA officiel unique.

duplicates report code produit

 ********************************************************************************
* ETAPE 6 — Garder uniquement les variables pertinentes du mapping officiel
 ********************************************************************************

keep code produit hors_champ r_vat_official

* Ajouter la source explicite
gen source = "official"

sort code produit
save "$SILVER/02/mapping_fiscal_official.dta", replace

di as result ">>> Mapping TVA officiel nettoy et sauvegarde"


 ********************************************************************************
* ETAPE 7 — Fusionner le mapping final dans les donnees de consommation
 ********************************************************************************
* C'est la fusion operationnelle finale utilisee pour l'analyse d'incidence.

use "$SILVER/01/conso_clean.dta", clear
gen code = codpr
decode codpr, gen(produit)
drop codpr 
order code produit
sort code produit
merge m:1  code produit using "$SILVER/02/mapping_fiscal_official.dta"

di as text ">>> Resultats de la fusion finale"
tab _merge

tab hors_champ if _merge==2 // Par consequent, ceux qui n'ont pas trouve de correspondance sont hors champ.

* Forte expectation :
* - _merge==1 devrait etre 0
* - _merge==3 devrait couvrir toutes les observations de consommation
* - _merge==2 peut exister et est sans danger pour l'analyse finale


 ********************************************************************************
* ETAPE 8 — Diagnostics apres fusion
 ********************************************************************************

* Produits dans la consommation encore manquants du mapping (devrait etre nul)
count if _merge == 1
br code r_vat_official produit if _merge == 1

* Produits dans le mapping non observes dans conso (pas un probleme)
count if _merge == 2
br code r_vat_official produit if _merge == 2

list code produit if _merge == 2


 ********************************************************************************
* ETAPE 9 — Garder uniquement les observations pertinentes pour l'analyse
 ********************************************************************************
keep if _merge == 3
drop _merge
keep if  hors_champ ==0

 ********************************************************************************
* ETAPE 10 — ETIQUETAGE DU JEU DE DONNEES
 ********************************************************************************

*-------------------------------
* 1. ETIQUETER LES VARIABLES 
*-------------------------------

label variable country        "Code pays"
label variable year           "Annee d'enquete"
label variable hhid           "Identifiant unique du menage"
label variable vague          "Vague d'enquete"
label variable grappe         "Grappe d'echantillonnage"
label variable menage         "Numero du menage dans la grappe"

label variable region         "Region de residence"
label variable milieu         "Zone de residence (urbain/rural)"

label variable hhweight       "Ponderation d'echantillonnage du menage"

label variable code          "Code produit (nomenclature EHCVM)"
label variable produit        "Libelle produit / service"

label variable inclus         "Inclus dans l'aggregat de consommation finale"
label variable coicop         "Classification COICOP"
label variable modep          "Mode d'acquisition"

label variable depan          "Depense annuelle de consommation (CFA)"
label variable log_depan      "Log de la depense annuelle de consommation"
label variable depan_w        "Depense de consommation winsorisee"

* Variables TVA / fiscales
label variable hors_champ     "Hors champ TVA (1=oui, 0=non)"
label variable r_vat_official "Taux TVA officiel (CGI 2026)"
label variable source         "Source de l'assignation TVA (officiel)"

*-------------------------------
* 1. ETIQUETER LES VALEURS 
*-------------------------------
* Inclus
label define inclus_lbl 0 "Non" 1 "Oui"
label values inclus inclus_lbl


 /*
 * TVA final
gen vat_cat = round(r_vat_final*100)

replace vat_cat = 0  if vat_cat==0
replace vat_cat = 9  if vat_cat==9
replace vat_cat = 18 if vat_cat==18

label define vat_cat_lbl 0 "Exonere (0%)" 1"Reduit(9%)" 2"Standard (18%)"

label values vat_cat vat_cat_lbl
label variable vat_cat "Categorie TVA"
 */


 *format r_vat_official %9.2f
 *format depan %15.0fc
 *format depan_w %15.0fc


 ********************************************************************************
* ETAPE 11 — Sauvegarde
 ********************************************************************************


save "$SILVER/01/conso_clean", replace
di as result ">>> Jeu de donnees etiquete et pret pour l'analyse"


 ********************************************************************************
* FIN
 ********************************************************************************