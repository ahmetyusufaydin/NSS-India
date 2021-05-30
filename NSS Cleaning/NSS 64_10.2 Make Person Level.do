
*-----------------------------------------------------------------------------
// Level 07 - HH Consumption (HH Level)
*-----------------------------------------------------------------------------
// Monthly HH consumer expenditure is already copied into block 3

use "$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level07.dta", clear

replace ValueofconsumptionRslast365day = ValueofconsumptionRslast30days/30*365 ///
	if missing(ValueofconsumptionRslast365day)
gen ConFood = ValueofconsumptionRslast365day if Srlno<=8
gen ConPanTobaccoIntoxicants = ValueofconsumptionRslast365day if Srlno==9
gen ConFuelLight = ValueofconsumptionRslast365day if Srlno==10
gen ConEntertainment = ValueofconsumptionRslast365day if Srlno==11
gen ConPersonalCare = ValueofconsumptionRslast365day if Srlno==12
gen ConServices = ValueofconsumptionRslast365day if Srlno==13
gen ConRentTax = ValueofconsumptionRslast365day if Srlno==14
gen ConMedical = ValueofconsumptionRslast365day if Srlno==15 | Srlno==17
gen ConEducation = ValueofconsumptionRslast365day if Srlno==18
gen ConClothBedFoot = ValueofconsumptionRslast365day if Srlno==19
gen ConDurable = ValueofconsumptionRslast365day if Srlno==20

drop if Srlno==16 | Srlno==21 | Srlno==22 | Srlno==23

collapse (sum) Con*, by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)

tempfile consumption
save `consumption'

/* To check the consistency btw Block 7 and Block 3
keep if Srlno==23
drop ValueofconsumptionRslast365day Srlno
*/


*-----------------------------------------------------------------------------
// Level 05 - Weekly Activity of HH Members
*-----------------------------------------------------------------------------
use "$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level05.dta", clear

*Collapse to make it person level and retain weekly wage/salary earnings
collapse (sum) WageSalaryEarningsTotal, ///
	by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo PersonSerialno Age)

tempfile wage
save `wage'

*-----------------------------------------------------------------------------
// Level 04 - HH Members (Person Level)
*-----------------------------------------------------------------------------
use "$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level04.dta", clear

*-----------------------------------------------------------------------------
// Level 06 - Migration Particulars of HH Members (Person Level)
*-----------------------------------------------------------------------------
merge 1:1 FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo PersonSerialno ///
	Age using "$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level06.dta"
drop _merge

*-----------------------------------------------------------------------------
// Level 01 - HH Identification, etc. (HH Level)
*-----------------------------------------------------------------------------
merge m:1 FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo using ///
	"$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level01.dta"

drop 	InformantSlNo	///
		ResponseCode	///
		SurveyCode		///
		SubstitutionCode ///
		DateofSurvey	///
		DateofDespatch  ///
		Timetocanvass*	///
		SpecialcharactersforOKstamp ///
		Blank
drop _merge

*-----------------------------------------------------------------------------
// Level 02 - HH characteristics (HH Level)
*-----------------------------------------------------------------------------
merge m:1 FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo using ///
	"$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level02.dta"
drop _merge

*-----------------------------------------------------------------------------
// Level 07 - HH Consumption (HH Level)
*-----------------------------------------------------------------------------

merge m:1 FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo using ///
	`consumption'
drop _merge

*-----------------------------------------------------------------------------
// Level 05 - Weekly Activity of HH Members 
*-----------------------------------------------------------------------------
merge 1:1 FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo PersonSerialno ///
	Age using `wage'
drop _merge

*-----------------------------------------------------------------------------
// Level 03 - Out-Migrants (HH Level)
*-----------------------------------------------------------------------------
merge m:1 FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo using ///
	"$Data\India\NSS\Built\NSS 64_10.2 Out-Migrants HH Level.dta"
drop _merge



*UNIQUE IDENTIFIERS
egen hhid = group(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)
egen personid = group(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo PersonSerialno)


*MULTIPLIERS
gen Mult = mult_MLT/200 if mult_NSS != mult_NSC
replace Mult = mult_MLT/100 if mult_NSS == mult_NSC
gen Mult_Person = Mult*HHSize


*DROP UN-NEED VARIABLES
drop CentrecodeRoundandShift Level mult_* Specialcharactersfor* ///
	ScheduleNumber Sample Stratum SubStratum FODSubRegion
	

*RENAME VARIABLES
rename hgsbno  HamletgroupSubblockno
rename Subsample SubSample
rename Generaleducation  GeneralEducation
rename HHtype  HHType
rename Landpossessedcode  LandPossessed

*Block 4 - Activity of HH Members
rename Usualprincipalactivitystatus  UsualPrincipalStatus
rename UsualprincipalactivityNIC2004c  UsualactivityNIC2004
rename UsualprincipalactivityNCO2004c  UsualactivityNCO2004
rename Whetherengagedinsubsidiarycapa  Engagedinsubsidiary
recode Engagedinsubsidiary 2=0
rename Usualsubsidiaryeconomicactivit  SubsidiaryStatus
rename UsualsubsidiaryactivityNIC2004  SubsidiaryNIC2004
rename UsualsubsidiaryactivityNCO2004  SubsidiaryNCO2004

*Block 5 - Weekly Activity of HH Members
rename WageSalaryEarningsTotal WeeklyWageSalary

*Block 6 - Migration
rename Usualactivitypsstatuscode  UsualactivityMigStatuscode
rename Usualactivitypsforcodes1151NIC  UsualactivityMigNIC2004


*GENERATE VARIABLES
gen MPCE = MonthlyHHconsumerexpenditureRs/HHSize


*DUMMIES for EDUCATION
gen EdIlliterate=GeneralEducation==1
gen EdBelowPrimary=GeneralEducation>=2 & GeneralEducation<=6
gen EdPrimary=GeneralEducation==7
gen EdMiddle=GeneralEducation==8
gen EdSecondary=GeneralEducation==10
gen EdHigherSecondary=GeneralEducation==11
gen EdGraduate=GeneralEducation>=12 & GeneralEducation<=14
foreach var of varlist Ed* {
	replace `var' = . if missing(GeneralEducation)
}


*duplicates drop			// no duplicates
compress
destring NCO2004Code3digit, replace force


save "$Data\India\NSS\Built\NSS 64_10.2 Person Level.dta", replace
