

*use "$Data\India\NSS\Built\NSS 55 64 Person Level without District Matching.dta", clear
use "$Data\India\NSS\Built\NSS 55 64 Person Level.dta", clear


// Generate # of Adults and Children
gen AdultTag=1 if Age>=15 & Age!=.
gen PrimeTag=1 if Age>=15 & Age<=64
gen ChildTag=1 if Age<15

bys Round hhid: egen Adults = sum(AdultTag)
bys Round hhid: egen Children = sum(ChildTag)

recode Sex 2=0
recode Sector 2=0

//Wage
gen YearlyWageSalary = WeeklyWageSalary*52
bys Round hhid: egen HHWageIncome = sum(YearlyWageSalary)

//Remittances and Consumption
recode InternalRemit 0=.
recode InternationalRemit 0=.
recode MaleInternalRemit 0=.
gen YearlyConsumption = MonthlyHHconsumerexpenditureRs*12
gen ShareInternalRemitWage = InternalRemit/HHWageIncome
gen ShareInternalRemitCons = InternalRemit/YearlyConsumption
gen ShareMaleInternalRemitWage = MaleInternalRemit/HHWageIncome
gen ShareMaleInternalRemitCons = MaleInternalRemit/YearlyConsumption
gen ShareMaleInternalRemitConsAll = ShareMaleInternalRemitCons
recode ShareMaleInternalRemitConsAll .=0 if Round==64

//Former (male) member migrated out any time in the past and Receiving Internal Remittances
recode Formermembermigratedoutanytime 2=0
gen ReceivingInternalRemit = InternalRemit>0 & InternalRemit!=.
replace ReceivingInternalRemit=. if Round==55
gen ReceivingInternationalRemit = InternationalRemit>0 & InternationalRemit!=.
replace ReceivingInternationalRemit=. if Round==55
gen MaleMemberInternalOutmigrant= OutMigrationMaleInternal>0 & OutMigrationMaleInternal!=.
gen MaleReceivingInternalRemit = MaleInternalRemit>0 & MaleInternalRemit!=.
replace MaleMemberInternalOutmigrant=. if Round==55
replace MaleReceivingInternalRemit=. if Round==55

//HH migrated to current place during last 365days and coming from Rural origin
rename Migratedtoduringlast365days HHMigratedInlast365days
recode HHMigratedInlast365days 2=0
/*
gen HHMigratedfromRural = Locationoflast==1 | Locationoflast==3 | Locationoflast==5
replace HHMigratedfromRural=. if Round==55 | Locationoflast==7
*/

//Members migrated in 
rename Placeofenumerationdiffersfroml MigratedIn
recode MigratedIn 2=0	//This differs within a HH, bcs of marriage etc.
/* 
gen MigratedfromRural = Locationoflast==1 | Locationoflast==3 | Locationoflast==5
replace MigratedfromRural=. if Locationoflast==7
*/

//This migration was a return. Round 55 doesn't ask this question
recode Placeofenumerationwasupranytim 2=0
gen ExcludingReturn = MigratedIn
replace ExcludingReturn = 0 if Placeofenumerationwasupranytim==1

//Migrated out seasonally or temporarily for employment
*Round 55 
gen SeasonalMigrant55 = 0
replace SeasonalMigrant55 = 1 if Stayedinforlast6monthsormore==2 
replace SeasonalMigrant55 = 1 if Stayedawayforempl60daysormore==1
replace SeasonalMigrant55 = 0 if MigratedIn==1 & Periodsinceleavingthelastuprye==0
replace SeasonalMigrant55 = . if Round==64
*Round 64 
rename Whetherstayedawayfromvillageto SeasonalMigrant64
recode SeasonalMigrant64 2=0
*Exclude Children and Olds
recode SeasonalMigrant55 1=0 if PrimeTag!=1
recode SeasonalMigrant64 1=0 if PrimeTag!=1

*HHs with Seasonal Migrants
bys Round hhid: egen HHSeasonalMigrant55=max(SeasonalMigrant55)
bys Round hhid: egen HHSeasonalMigrant64=max(SeasonalMigrant64)

/*
gen SeasonalRural=1 if Destination==1 | Destination==3 | Destination==5
replace SeasonalRural=0 if Destination==2 | Destination==4 | Destination==6
*Whether worked for those among seasonal migrants
gen SeasonalWorked = Ifworked>0 & Ifworked!=.
replace SeasonalWorked=. if SeasonalMigrant64!=1
*/

save "$Data\India\NSS\Built\NSS 55 64 Person Level Summary.dta", replace



********************************************************************************
// ADULTS (Prime Age)

use "$Data\India\NSS\Built\NSS 55 64 Person Level Summary.dta", clear

keep if PrimeTag==1

tabstat Age Sex Sector if Round==55 [aweight=Mult_Person], stat(n mean min max)
tabstat Age Sex Sector if Round==64 [aweight=Mult_Person], stat(n mean min max)

tabstat Ed* if Round==55 [aweight=Mult_Person], stat(n mean)
tabstat Ed* if Round==64 [aweight=Mult_Person], stat(n mean)

tabstat OC* if Round==55 [aweight=Mult_Person], stat(n mean)
tabstat OC* if Round==64 [aweight=Mult_Person], stat(n mean)

tabstat MigratedIn if Round==55 [aweight=Mult_Person], stat(n mean)
tabstat MigratedIn ExcludingReturn if Round==64 [aweight=Mult_Person], stat(n mean)

tabstat SeasonalMigrant55 SeasonalMigrant64 [aweight=Mult_Person], stat(n mean)

// Seasonal Migrants
keep if SeasonalMigrant55==1 | SeasonalMigrant64==1

tabstat Age Sex Sector if Round==55 [aweight=Mult_Person], stat(n mean min max)
tabstat Age Sex Sector if Round==64 [aweight=Mult_Person], stat(n mean min max)

tabstat Ed* if Round==55 [aweight=Mult_Person], stat(n mean)
tabstat Ed* if Round==64 [aweight=Mult_Person], stat(n mean)

tabstat OC* if Round==55 [aweight=Mult_Person], stat(n mean)
tabstat OC* if Round==64 [aweight=Mult_Person], stat(n mean)

tabstat MigratedIn if Round==55 [aweight=Mult_Person], stat(n mean)
tabstat MigratedIn ExcludingReturn if Round==64 [aweight=Mult_Person], stat(n mean)
********************************************************************************


********************************************************************************
// HOUSEHOLD and HH HEAD CHARACTERISTICS

use "$Data\India\NSS\Built\NSS 55 64 Person Level Summary.dta", clear

keep if Relationtohead == 1			//more than 1 person stated as head for some HHs in round 55
									//some heads are not adult

duplicates tag Round hhid, gen(dup)
drop if dup>0 & PersonSerialno!=1	//pick the person on top of the list as head of HH
drop dup

********************************************************************************
*All HHs
tabstat HHSize Adults Children Age Sex Sector if Round==55 [aweight=Mult], stat(n mean min max)
tabstat HHSize Adults Children Age Sex Sector if Round==64 [aweight=Mult], stat(n mean min max)

tabstat Ed* if Round==55 [aweight=Mult], stat(n mean)
tabstat Ed* if Round==64 [aweight=Mult], stat(n mean)

tabstat OC* if Round==55 [aweight=Mult], stat(n mean)
tabstat OC* if Round==64 [aweight=Mult], stat(n mean)

tabstat Formermembermigratedoutanytime MaleMemberInternalOutmigrant ///
		HHSeasonalMigrant55 HHSeasonalMigrant64 HHMigratedInlast365days [aweight=Mult], stat(n mean)
	
tabstat MigratedIn if Round==55 [aweight=Mult], stat(n mean)
tabstat MigratedIn ExcludingReturn if Round==64 [aweight=Mult], stat(n mean)

*HHs with and without Out-Migrants
tabstat HHSize Adults Children Age Sex Sector if Formermembermigratedoutanytime==1 [aweight=Mult], stat(n mean min max)
tabstat HHSize Adults Children Age Sex Sector if Formermembermigratedoutanytime==0 [aweight=Mult], stat(n mean min max)

tabstat Ed* if Formermembermigratedoutanytime==1 [aweight=Mult], stat(n mean)
tabstat Ed* if Formermembermigratedoutanytime==0 [aweight=Mult], stat(n mean)

tabstat OC* if Formermembermigratedoutanytime==1 [aweight=Mult], stat(n mean)
tabstat OC* if Formermembermigratedoutanytime==0 [aweight=Mult], stat(n mean)

tabstat HHMigratedInlast365days if Formermembermigratedoutanytime==1 [aweight=Mult], stat(n mean)
tabstat HHMigratedInlast365days if Formermembermigratedoutanytime==0 [aweight=Mult], stat(n mean)

tabstat MigratedIn ExcludingReturn if Formermembermigratedoutanytime==1 [aweight=Mult], stat(n mean)
tabstat MigratedIn ExcludingReturn if Formermembermigratedoutanytime==0 [aweight=Mult], stat(n mean)

*HHs with Male Internal Out-Migrants
tabstat HHSize Adults Children Age Sex Sector if MaleMemberInternalOutmigrant==1 [aweight=Mult], stat(n mean min max)

tabstat Ed* if MaleMemberInternalOutmigrant==1 [aweight=Mult], stat(n mean)

tabstat OC* if MaleMemberInternalOutmigrant==1 [aweight=Mult], stat(n mean)

tabstat HHMigratedInlast365days if MaleMemberInternalOutmigrant==1 [aweight=Mult], stat(n mean)

tabstat MigratedIn ExcludingReturn if MaleMemberInternalOutmigrant==1 [aweight=Mult], stat(n mean)

*HHs with Seasonal Migrants
tabstat HHSize Adults Children Age Sex Sector if HHSeasonalMigrant55==1 [aweight=Mult], stat(n mean min max)
tabstat HHSize Adults Children Age Sex Sector if HHSeasonalMigrant64==1 [aweight=Mult], stat(n mean min max)

tabstat Ed* if HHSeasonalMigrant55==1 [aweight=Mult], stat(n mean)
tabstat Ed* if HHSeasonalMigrant64==1 [aweight=Mult], stat(n mean)

tabstat OC* if HHSeasonalMigrant55==1 [aweight=Mult], stat(n mean)
tabstat OC* if HHSeasonalMigrant64==1 [aweight=Mult], stat(n mean)

tabstat HHMigratedInlast365days if HHSeasonalMigrant64==1 [aweight=Mult], stat(n mean)

tabstat MigratedIn if HHSeasonalMigrant55==1 [aweight=Mult], stat(n mean)
tabstat MigratedIn ExcludingReturn if HHSeasonalMigrant64==1 [aweight=Mult], stat(n mean)

********************************************************************************
 
********************************************************************************
*Income
tabstat HHWageIncome if Round==55 [aweight=Mult], stat(n mean min max)
tabstat HHWageIncome if Round==64 [aweight=Mult], stat(n mean min max)

tabstat HHWageIncome if HHWageIncome>0 & Round==55 [aweight=Mult], stat(n mean min max)
tabstat HHWageIncome if HHWageIncome>0 & Round==64 [aweight=Mult], stat(n mean min max)

*Consumption and Remittances
tabstat Con* if Round==64 [aweight=Mult], stat(n mean)

tabstat MonthlyHHconsumerexpenditureRs MPCE if Round==55 [aweight=Mult], stat(n mean min max)
tabstat MonthlyHHconsumerexpenditureRs MPCE if Round==64 [aweight=Mult], stat(n mean min max)

tabstat Formermembermigratedoutanytime ReceivingInternalRemit ReceivingInternationalRemit ///
		MaleMemberInternalOutmigrant MaleReceivingInternalRemit [aweight=Mult], stat(n mean)

tabstat InternalRemit InternationalRemit MaleInternalRemit [aweight=Mult], stat(n mean min max)
tabstat ShareInternalRemitWage ShareInternalRemitCons ///
		ShareMaleInternalRemitWage ShareMaleInternalRemitCons ///
		ShareMaleInternalRemitConsAll [aweight=Mult], stat(n mean)

*Use of Remittances
tab Useofremittancesfirstcode [aweight=Mult]
tab Useofremittancessecondcode [aweight=Mult]
tab Useofremittancesthirdcode [aweight=Mult]
********************************************************************************

// ------------------------------ Rural HH ------------------------------
preserve
keep if Sector == 1

tabstat HHSize Adults Children Age Sex if Round==55 [aweight=Mult], stat(n mean min max)
tabstat HHSize Adults Children Age Sex if Round==64 [aweight=Mult], stat(n mean min max)

tabstat Ed* if Round==55 [aweight=Mult], stat(n mean)
tabstat Ed* if Round==64 [aweight=Mult], stat(n mean)

tabstat OC* if Round==55 [aweight=Mult], stat(n mean)
tabstat OC* if Round==64 [aweight=Mult], stat(n mean)

tabstat Con* if Round==64 [aweight=Mult], stat(n mean)

tabstat HHSeasonalMigrant55 HHSeasonalMigrant64 [aweight=Mult], stat(n mean)

tabstat MonthlyHHconsumerexpenditureRs MPCE if Round==55 [aweight=Mult], stat(n mean min max)
tabstat MonthlyHHconsumerexpenditureRs MPCE if Round==64 [aweight=Mult], stat(n mean min max)

tabstat HHWageIncome if HHWageIncome>0 & Round==55 [aweight=Mult], stat(n mean min max)
tabstat HHWageIncome if HHWageIncome>0 & Round==64 [aweight=Mult], stat(n mean min max)

tabstat Formermembermigratedoutanytime ReceivingInternalRemit ///
		MaleMemberInternalOutmigrant MaleReceivingInternalRemit [aweight=Mult], stat(n mean)

tabstat InternalRemit InternationalRemit MaleInternalRemit [aweight=Mult], stat(n mean min max)
tabstat ShareInternalRemitWage ShareInternalRemitCons ///
		ShareMaleInternalRemitWage ShareMaleInternalRemitCons ///
		ShareMaleInternalRemitConsAll [aweight=Mult], stat(n mean)
restore


// ------------------------------ Urban HH ------------------------------
preserve
keep if Sector == 0

tabstat HHSize Adults Children Age Sex if Round==55 [aweight=Mult], stat(n mean min max)
tabstat HHSize Adults Children Age Sex if Round==64 [aweight=Mult], stat(n mean min max)

tabstat Ed* if Round==55 [aweight=Mult], stat(n mean)
tabstat Ed* if Round==64 [aweight=Mult], stat(n mean)

tabstat OC* if Round==55 [aweight=Mult], stat(n mean)
tabstat OC* if Round==64 [aweight=Mult], stat(n mean)

tabstat Con* if Round==64 [aweight=Mult], stat(n mean)

tabstat HHSeasonalMigrant55 HHSeasonalMigrant64 [aweight=Mult], stat(n mean)

tabstat MonthlyHHconsumerexpenditureRs MPCE if Round==55 [aweight=Mult], stat(n mean min max)
tabstat MonthlyHHconsumerexpenditureRs MPCE if Round==64 [aweight=Mult], stat(n mean min max)

tabstat HHWageIncome if HHWageIncome>0 & Round==55 [aweight=Mult], stat(n mean min max)
tabstat HHWageIncome if HHWageIncome>0 & Round==64 [aweight=Mult], stat(n mean min max)

tabstat Formermembermigratedoutanytime ReceivingInternalRemit ///
		MaleMemberInternalOutmigrant MaleReceivingInternalRemit [aweight=Mult], stat(n mean)

tabstat InternalRemit InternationalRemit MaleInternalRemit [aweight=Mult], stat(n mean min max)
tabstat ShareInternalRemitWage ShareInternalRemitCons ///
		ShareMaleInternalRemitWage ShareMaleInternalRemitCons ///
		ShareMaleInternalRemitConsAll [aweight=Mult], stat(n mean)

restore



