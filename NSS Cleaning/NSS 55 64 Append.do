

use "$Data\India\NSS\Built\NSS 55_10 Person Level.dta", clear

append using "$Data\India\NSS\Built\NSS 64_10.2 Person Level.dta"


********************************************************************************
// DUMMIES for OCCUPATION DIVISIONS (NCO 1698 and 2004)
gen OCAdminManager = UsualactivityNCO2004>100 & UsualactivityNCO2004<200 
gen OCProfessionals = UsualactivityNCO2004>200 & UsualactivityNCO2004<400
gen OCClreks = UsualactivityNCO2004>400 & UsualactivityNCO2004<500
gen OCSalesService = UsualactivityNCO2004>500 & UsualactivityNCO2004<600
gen OCAgricultureFishery = UsualactivityNCO2004>600 & UsualactivityNCO2004<700
gen OCCraftsmenMachineOp = UsualactivityNCO2004>700 & UsualactivityNCO2004<900
gen OCLabourerUnskilled = UsualactivityNCO2004>900 & UsualactivityNCO2004<1000

*Use NCO 1968 to 2004 conversion
replace OCAdminManager=1 if UsualactivityNCO68>=200 & UsualactivityNCO68<=299 ///
	| UsualactivityNCO68>=601 & UsualactivityNCO68<=609
	
replace OCProfessionals=1 if UsualactivityNCO68>=0 & UsualactivityNCO68<=198 ///
	& UsualactivityNCO68!=134 & UsualactivityNCO68!=136 & UsualactivityNCO68!=137 ///
	& UsualactivityNCO68!=169 & UsualactivityNCO68!=183 & UsualactivityNCO68!=192 ///
	| UsualactivityNCO68>=300 & UsualactivityNCO68<=309 ///
	| UsualactivityNCO68==391 | UsualactivityNCO68==411 ///
	| UsualactivityNCO68>=420 & UsualactivityNCO68<=429 ///
	| UsualactivityNCO68>=440 & UsualactivityNCO68<=449 ///
	| UsualactivityNCO68==571 ///
	| UsualactivityNCO68>=860 & UsualactivityNCO68<=869
	
replace OCClreks=1 if UsualactivityNCO68>=310 & UsualactivityNCO68<=359 ///
	& UsualactivityNCO68!=353 & UsualactivityNCO68!=357 & UsualactivityNCO68!=358 ///
	| UsualactivityNCO68>=370 & UsualactivityNCO68<=399 ///
	& UsualactivityNCO68!=370 & UsualactivityNCO68!=371 ///
	& UsualactivityNCO68!=381 & UsualactivityNCO68!=389 ///
	& UsualactivityNCO68!=391 & UsualactivityNCO68!=399 ///
	| UsualactivityNCO68>=450 & UsualactivityNCO68<=459
	
replace OCSalesService=1 if UsualactivityNCO68>=400 & UsualactivityNCO68<=419 ///
	& UsualactivityNCO68!=410 & UsualactivityNCO68!=411 ///
	| UsualactivityNCO68>=430 & UsualactivityNCO68<=439 ///
	& UsualactivityNCO68!=431 ///
	| UsualactivityNCO68>=490 & UsualactivityNCO68<=539 ///
	& UsualactivityNCO68!=531 & UsualactivityNCO68!=539 ///
	| UsualactivityNCO68>=552 & UsualactivityNCO68<=598 ///
	& UsualactivityNCO68!=559 & UsualactivityNCO68!=570 ///
	& UsualactivityNCO68!=571 & UsualactivityNCO68!=572 ///
	& UsualactivityNCO68!=574 ///
	| UsualactivityNCO68==357 | UsualactivityNCO68==370 | UsualactivityNCO68==371
	
replace OCAgricultureFishery=1 if UsualactivityNCO68>=610 & UsualactivityNCO68<=629 ///
	| UsualactivityNCO68>=641 & UsualactivityNCO68<=689 ///
	& UsualactivityNCO68!=649 & UsualactivityNCO68!=650
	
replace OCCraftsmenMachineOp=1 if UsualactivityNCO68>=710 & UsualactivityNCO68<=858 ///
	& UsualactivityNCO68!=716 & UsualactivityNCO68!=759 ///
	& UsualactivityNCO68!=819 ///
	| UsualactivityNCO68>=870 & UsualactivityNCO68<=986 ///
	& UsualactivityNCO68!=943 & UsualactivityNCO68!=959 ///
	& UsualactivityNCO68!=971 & UsualactivityNCO68!=975 ///
	& UsualactivityNCO68!=976 & UsualactivityNCO68!=980 ///
	| UsualactivityNCO68==650
	
replace OCLabourerUnskilled=1 if UsualactivityNCO68==389 | UsualactivityNCO68==531 ///
	| UsualactivityNCO68>=540 & UsualactivityNCO68<=549 ///
	| UsualactivityNCO68==559 | UsualactivityNCO68==574 ///
	| UsualactivityNCO68>=630 & UsualactivityNCO68<=639 ///
	| UsualactivityNCO68==649 | UsualactivityNCO68==971 | UsualactivityNCO68==975 ///
	| UsualactivityNCO68==976 | UsualactivityNCO68==987| UsualactivityNCO68==988 ///
	| UsualactivityNCO68>=990 & UsualactivityNCO68<=999
	
foreach var of varlist OC* {
	replace `var' = . if missing(UsualactivityNCO68) & Round==55
	replace `var' = . if missing(UsualactivityNCO2004) & Round==64
}

save "$Data\India\NSS\Built\NSS 55 64 Person Level without District Matching.dta", replace
********************************************************************************


// !!! Observations for Round 55 is increasing from 596,686 to 778,445 due to duplication, see Imbert and Papp (2019)
********************************************************************************
// ----------------- DISTRICT MATCHING -----------------

use "$Data/India/District Matching/Census_2001_district_level", clear
rename state_code StateCensusCode2001
rename district_code DistrictCensusCode2001
collapse (sum) PCA_tot_p, by(StateCensusCode2001 DistrictCensusCode2001)
tempfile population
save `population'

insheet using "$Data/India/District Matching/District Matching.csv", comma case names clear
merge m:1 StateCensusCode2001 DistrictCensusCode2001 using `population', nogen
replace DistrictCode64=1 if StateCode64==7 
gen Split5564=regexm(upper(Notes5564),"SPLIT")==1 & regexm(Notes5564,"THREE WAY JOINT SPLIT")==0
gen JointSplit5564=regexm(Notes5564,"THREE WAY JOINT SPLIT")==1 
keep  DistrictCode64 StateCode64  DistrictCode55 StateCode55 State64 District64	Split5564 JointSplit5564 PCA_tot_p	 			
duplicates	drop	
duplicates tag  DistrictCode55	StateCode55, gen(Duplicates55)
bys DistrictCode55	StateCode55: egen SumPop=sum(PCA_tot_p)
gen Weight=PCA_tot_p/SumPop 
replace Weight=0.5 if JointSplit5564==1
drop  Split5564 JointSplit5564
tempfile match55
save `match55'

insheet using "$Data/India/District Matching/District Matching.csv", comma case names clear
replace DistrictCode64=1 if StateCode64==7 
replace District64="Delhi" if StateCode64==7 
keep  District64 State64 DistrictCode64 StateCode64						
drop if missing(StateCode64) | missing(DistrictCode64)
duplicates drop
* One joint-split in Karnataka
duplicates report  DistrictCode64 StateCode64 
tempfile match64
save `match64'


use "$Data\India\NSS\Built\NSS 55 64 Person Level without District Matching.dta", clear
gen State = floor(StateRegion/10)
replace District=1 if State==7 & Round==64
gen StateCode64 = State if Round==64
gen DistrictCode64 = District if Round==64
gen StateCode55 = State if Round==55
gen DistrictCode55 = District if Round==55
drop State District

merge m:1 DistrictCode64 StateCode64 using `match64', gen(merge) 
joinby DistrictCode55 StateCode55 using `match55', unmatched(master) _merge(join55) update
*!!!!Observations for Round 55 is increasing from 596,686 to 778,445 due to duplication, see Imbert and Papp (2019)

replace Mult=Mult*Weight if Round==55

tab Round join55
tab Round merge
* Three districts not surveyed in Jammu Kashmir *
drop if merge==2


drop join55 merge Duplicates55
drop PCA_tot_p SumPop Weight
quie compress


*erase "$Data\India\NSS\Built\NSS 55 64 Person Level without District Matching.dta"
********************************************************************************

	
save "$Data\India\NSS\Built\NSS 55 64 Person Level.dta", replace


