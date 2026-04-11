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

include "$prog\ehcvm2_civ_pgm00_mars2023.do"
include "$prog\ehcvm2_civ_pgm01_mars2023.do"
include "$prog\ehcvm2_civ_pgm02_mars2023.do"
include "$prog\ehcvm2_civ_pgm03_00_sept_2023.do"
*include "$prog\ehcvm2_civ_pgm03_00_mars2023_dernier.do"
*include "$prog\ehcvm2_civ_pgm03_1a_mars2023.do"
*include "$prog\ehcvm2_civ_pgm03_1b_mar2023.do"
*include "$prog\ehcvm2_civ_pgm03_2a_mars2023.do"
include "$prog\ehcvm2_civ_pgm03_2b_mars2023.do"
*include "$prog\ehcvm2_civ_pgm03_3a_mars2023.do"
*include "$prog\ehcvm2_civ_pgm03_3b_mars2023.do"
*include "$prog\ehcvm2_sn_pgm03_4a_mai2023.do"
*include "$prog\ehcvm2_sn_pgm03_4b_mai2023.do"
