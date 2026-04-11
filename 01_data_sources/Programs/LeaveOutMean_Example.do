
** Leave-out mean personnes qui travaillent  1


egen SCON = sum(Working1 ) , by(PSU)
gen n=1 if Working1 ~=.
egen ntot = sum(n), by(PSU)
sort PSU

gen RCON_Working1 = (SCON - Working1 )/(ntot-1)
lab var RCON_Working1 "Leave out Mean working au niveau de la grappe"
drop n ntot SCON 
******************
