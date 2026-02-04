version 17
set more off
*ssc install confirmdir

global suser = lower(c(username))

// nb: Check your paths next time you run these do-files

* Arthur	
if ("${suser}"=="wb388526") {
	global gdDo 		= "C:\Users\WB388526\Documents\GitHub\CIV-CEQ"
	local ldAnalysis 	= "C:\Users\WB388526\WBG\EAWPV Pov Data Files - EAWPV Pov Data Documents\CMU_CIV\analytics\CEQCIV"
} 


* Anne
else if ("${suser}"=="wb542101") {
	global gdDo 		= "C:\Users\wb542101\OneDrive - WBG\GitHub\CIV-CEQ"
	local ldAnalysis 	= "C:\Users\wb542101\WBG\EAWPV Pov Data Files - CEQCIV"
} 


* Bernardo
else if ("${suser}"=="wb384997") {
	global ppath = "C:\Users\wb384997\OneDrive - WBG\Documents\"
	global gdDo 		= "$ppath\CEQ\Shared folders\CEQCIV\CEQCIV repo\"
	local ldAnalysis 	= "$ppath\CEQ\Shared folders\CEQCIV\EAWPV Pov Data Files - CEQCIV\"
} 


else {
	di as error "Configure work environment for user in 01-init.do before running the code."
	error 1
}


global gdData 	= "`ldAnalysis'\data\"
global gdOut 	= "`ldAnalysis'\\${suser}\"
global gdTemp 	= "${gdOut}\Temp\"
global gdLog	= "${gdOut}\Log\"
global gdFig	= "${gdOut}\Figure\"
global io 		= "`ldAnalysis'\Data\000-io\"

global date = string(date(c(current_date), "DMY"), "%td")

foreach d in "`ldAnalysis'" "${gdOut}" "${gdTemp}" "${gdLog}" {
	confirmdir "`d'" 
	if _rc!=0 mkdir "`d'" 
}

/*
stop
*Install packages
* update all
ssc install ceq, replace
ssc install povdeco, replace
ssc install ineqdeco, replace
ssc install quantiles, replace
ssc install ceqppp, replace 
ssc install schemepack, replace
ssc install glcurve, replace 
net install spnorm.pkg , replace // nb: Arthur needed to go online and manually save the ado and sthlp file @: https://ideas.repec.org/c/boc/bocode/s458835.html
ssc install sp_groupfunction  // nb: Arthur needed to go online and manually save the ado and sthlp file @: https://github.com/pcorralrodas/sp_groupfunction/tree/master/s
ssc install listsome 
* ssc install concindexi: need to first search: search concindexi
net install groupfunction.pkg , replace 
net install gr0001_3, replace
net install github, from("https://haghish.github.io/github/")
github install pcorralrodas/sp_groupfunction   // Attention. This package requires pathon installed on the PC.
// Python or anaconda has to be installed. For example from: https://www.anaconda.com/
// This command has to be run in Stata after installing anaconda.
python search       // Users must search and find a valid path to the python executable.
net install sgini, from(http://medim.ceps.lu/stata) // AD needed to go online and manually save the ado and sthlp file @ https://ideas.repec.org/c/boc/bocode/s458778.html
*/
