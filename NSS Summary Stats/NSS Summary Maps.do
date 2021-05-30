/*
--------------------------------------------------------------------------------
Map the summary stats
--------------------------------------------------------------------------------
*/

*ssc install spmap
*ssc install shp2dta

clear 

********************************************************************************
// ----------------- CONSTRUCT DATA FILES FOR MAPS -----------------
cd "$Data\India\Map"

shp2dta using "$Data\India\Map\Shape File\StatesClean.shp", database(IndiaSTATE) coordi(IndiaSTATECoor) replace
shp2dta using "$Data\India\Map\Shape File\DistrictsClean.shp", database(IndiaDISTRICT) coordi(IndiaDISTRICTCoor) replace

*use correct DISTRICT_ID
use IndiaDISTRICT.dta, clear
drop DISTRICT_I TOT* M* F* R* U* T*
gen STATE_ID = real(substr(C_CODE01,1,2))
gen DISTRICT_ID = real(substr(C_CODE01,1,4))
save IndiaDISTRICT.dta, replace

merge 1:m _ID using IndiaDISTRICTCoor.dta
drop _m
replace _ID = DISTRICT_ID //if DISTRICT_ID !=.
drop if STATE_ID==35
drop NAME STATE_UT C_CODE01 STATE_ID DISTRICT_ID
sort _ID, stable
save IndiaDISTRICTCoor.dta, replace

use IndiaDISTRICT.dta, clear
list STATE_ID DISTRICT_ID NAME		


*use correct STATE_ID
use IndiaSTATE.dta, clear
drop TOT* M* F* R* U* T*
list STATE_ID NAME
save IndiaSTATE.dta, replace

merge 1:m _ID using IndiaSTATECoor.dta
drop _m
drop if STATE_ID==35
replace _ID = STATE_ID
sort _ID, stable
save IndiaSTATECoor.dta, replace

	
********************************************************************************


********************************************************************************
use "$Data\India\NSS\Built\NSS 55 64 Person Level Summary.dta", clear
rename StateCode64 STATE_ID
gen DISTRICT_ID = STATE_ID*100 + DistrictCode64

*Level
local level "STATE"	// "STATE-DISTRICT"
*Round
local rnd "64"		//"55-64"
********************************************************************************

********************************************************************************
////////////////////////////////////////////////////////////////////////////////
preserve 

// ------------------- HH LEVEL STATISTICS ----------------------
*Formermembermigratedoutanytime MaleMemberInternalOutmigrant (64 only)
*HHMigratedInlast365days ShareMaleInternalRemitCons ShareMaleInternalRemitConsAll (64 only)
*Sector(Urbanization)

*Urbanization
gen Urban = 1-Sector

*Variables of interest
local stat1 Formermembermigratedoutanytime ShareMaleInternalRemitCons Urban
local stat2 MaleMemberInternalOutmigrant
local stat3 HHMigratedInlast365days ShareMaleInternalRemitConsAll


keep if Round==`rnd'
collapse (max) `stat1' `stat2' `stat3' `level'_ID Mult, by(hhid)
collapse (mean) `stat1' `stat2' `stat3' [aweight=Mult], by(`level')

save "$Data\India\Map\TEMPIndia`level'.dta", replace
use "$Data\India\Map\India`level'.dta", clear


merge 1:1 `level'_ID using "$Data\India\Map\TEMPIndia`level'.dta"

foreach var of varlist `stat1' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.1 0.2 0.3 0.4 0.5 0.6 0.8) ///
	legend(size(medium) pos(5) label(8 "60%-80%") label(7 "50%-60%") ///
	label(6 "40%-50%") label(5 "30%-40%") label(4 "20%-30%") label(3 "10%-20%") label(2 "0%-10%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

foreach var of varlist `stat2' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.05 0.10 0.15 0.20 0.30 0.40 0.50) ///
	legend(size(medium) pos(5) label(8 "40%-50%") label(7 "30%-40%") ///
	label(6 "20%-30%") label(5 "15%-20%") label(4 "10%-15%") label(3 "5%-10%") label(2 "0%-5%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

foreach var of varlist `stat3' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.01 0.02 0.03 0.04 0.05 0.06 0.08 0.1 0.15) ///
	legend(size(medium) pos(5) label(10 "10%-15%") label(9 "8%-10%") label(8 "6%-8%") label(7 "5%-6%") ///
	label(6 "4%-5%") label(5 "3%-4%") label(4 "2%-3%") label(3 "1%-2%") label(2 "0%-1%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

restore
////////////////////////////////////////////////////////////////////////////////
********************************************************************************

********************************************************************************
////////////////////////////////////////////////////////////////////////////////

// ------------------- PERSON LEVEL STATISTICS ----------------------
* Adult-Male
/*
use "$Data\India\NSS\Built\NSS 55 64 Person Level Summary.dta", clear
rename StateCode64 STATE_ID
gen DISTRICT_ID = STATE_ID*100 + DistrictCode64

*Level
local level "STATE"	// "STATE-DISTRICT"
*Round
local rnd "64"		//"55-64"
*/
*Variables of interest
local stat1 MigratedIn ExcludingReturn
local stat2 SeasonalMigrant`rnd'

keep if Round==`rnd'
keep if PrimeTag==1
keep if Sex==1

collapse (mean) `stat1' `stat2' [aweight=Mult_Person], by(`level')

save "$Data\India\Map\TEMPIndia`level'.dta", replace
use "$Data\India\Map\India`level'.dta", clear

merge 1:1 `level'_ID using "$Data\India\Map\TEMPIndia`level'.dta"


foreach var of varlist `stat1' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.05 0.1 0.15 0.2 0.25 0.3) ///
	legend(size(medium) pos(5) label(7 "25%-30%") label(6 "20%-25%") ///
	label(5 "15%-20%") label(4 "10%-15%") label(3 "5%-10%") label(2 "0%-5%"))
	
graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

foreach var of varlist `stat2' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.01 0.02 0.03 0.04 0.05 0.07 0.10) ///
	legend(size(medium) pos(5) label(8 "7%-10%") label(7 "5%-7%") label(6 "4%-5%") ///
	label(5 "3%-4%") label(4 "2%-3%") label(3 "1%-2%") label(2 "0%-1%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}
////////////////////////////////////////////////////////////////////////////////
********************************************************************************

erase "$Data\India\Map\TEMPIndia`level'.dta"

/*
********************************************************************************
********************************************************************************
*********************     DISTRICT LEVEL    ************************************
********************************************************************************

use "$Data\India\NSS\Built\NSS 55 64 Person Level Summary.dta", clear
rename StateCode64 STATE_ID
gen DISTRICT_ID = STATE_ID*100 + DistrictCode64

*Level
local level "DISTRICT"	// "STATE-DISTRICT"
*Round
local rnd "64"		//"55-64"
********************************************************************************

********************************************************************************
////////////////////////////////////////////////////////////////////////////////
preserve 

// ------------------- HH LEVEL STATISTICS ----------------------
*Formermembermigratedoutanytime MaleMemberInternalOutmigrant (64 only)
*HHMigratedInlast365days ShareMaleInternalRemitCons ShareMaleInternalRemitConsAll (64 only)
*Sector(Urbanization)

*Urbanization
gen Urban = 1-Sector

*Variables of interest
local stat1 Formermembermigratedoutanytime ShareMaleInternalRemitCons Urban
local stat2 MaleMemberInternalOutmigrant
local stat3 HHMigratedInlast365days ShareMaleInternalRemitConsAll


keep if Round==`rnd'
collapse (max) `stat1' `stat2' `stat3' `level'_ID Mult, by(hhid)
collapse (mean) `stat1' `stat2' `stat3' [aweight=Mult], by(`level')

save "$Data\India\Map\TEMPIndia`level'.dta", replace
use "$Data\India\Map\India`level'.dta", clear


merge 1:1 `level'_ID using "$Data\India\Map\TEMPIndia`level'.dta"

foreach var of varlist `stat1' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.1 0.2 0.3 0.4 0.5 0.6 0.8 1) ///
	legend(size(medium) pos(5) label(9 "80%-100%") label(8 "60%-80%") label(7 "50%-60%") ///
	label(6 "40%-50%") label(5 "30%-40%") label(4 "20%-30%") label(3 "10%-20%") label(2 "0%-10%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

foreach var of varlist `stat2' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.05 0.10 0.15 0.20 0.30 0.40 0.50 0.70 1) ///
	legend(size(medium) pos(5) label(10 "70%-100%") label(9 "50%-70%") label(8 "40%-50%") label(7 "30%-40%") ///
	label(6 "20%-30%") label(5 "15%-20%") label(4 "10%-15%") label(3 "5%-10%") label(2 "0%-5%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

foreach var of varlist `stat3' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.02 0.04 0.06 0.08 0.1 0.15 0.2 0.3) ///
	legend(size(medium) pos(5) label(9 "20%-30%") label(8 "15%-20%") label(7 "10%-15%") ///
	label(6 "8%-10%") label(5 "6%-8%") label(4 "4%-6%") label(3 "2%-4%") label(2 "0%-2%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

restore
////////////////////////////////////////////////////////////////////////////////
********************************************************************************

********************************************************************************
////////////////////////////////////////////////////////////////////////////////

// ------------------- PERSON LEVEL STATISTICS ----------------------
* Adult-Male
/*
use "$Data\India\NSS\Built\NSS 55 64 Person Level Summary.dta", clear
rename StateCode64 STATE_ID
gen DISTRICT_ID = STATE_ID*100 + DistrictCode64

*Level
local level "DISTRICT"	// "STATE-DISTRICT"
*Round
local rnd "64"		//"55-64"
*/
*Variables of interest
local stat1 MigratedIn ExcludingReturn
local stat2 SeasonalMigrant`rnd'

keep if Round==`rnd'
keep if PrimeTag==1
keep if Sex==1

collapse (mean) `stat1' `stat2' [aweight=Mult_Person], by(`level')

save "$Data\India\Map\TEMPIndia`level'.dta", replace
use "$Data\India\Map\India`level'.dta", clear

merge 1:1 `level'_ID using "$Data\India\Map\TEMPIndia`level'.dta"


foreach var of varlist `stat1' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5) ///
	legend(size(medium) pos(5) label(9 "40%-50%") label(8 "30%-40%") label(7 "25%-30%") ///
	label(6 "20%-25%") label(5 "15%-20%") label(4 "10%-15%") label(3 "5%-10%") label(2 "0%-5%"))
	
graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

foreach var of varlist `stat2' {

spmap `var' using "$Data\India\Map\India`level'Coor.dta", id(`level'_ID)  fcolor(Reds) ///
	ndfcolor(black) clmethod(custom) clbreaks(0 0.02 0.04 0.06 0.08 0.10 0.15 0.2 0.3) ///
	legend(size(medium) pos(5) label(9 "20%-30%") label(8 "15%-20%") label(7 "10%-15%") ///
	label(6 "8%-10%") label(5 "6%-8%") label(4 "4%-6%") label(3 "2%-4%") label(2 "0%-2%"))

graph export "$Maps\India\India-`level'-`var'-`rnd'.png", replace
}

////////////////////////////////////////////////////////////////////////////////
********************************************************************************


erase "$Data\India\Map\TEMPIndia`level'.dta"

