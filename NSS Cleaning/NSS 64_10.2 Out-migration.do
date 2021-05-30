
*------------------------------------------------
//Out-migration
*------------------------------------------------

use "$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level03.dta", clear

egen personid = group(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo Serialno)

drop CentrecodeRoundandShift ScheduleNumber Sample Stratum SubStratum ///
	FODSubRegion Level SpecialcharactersforOKstamp

drop if Serialno == 99

// Distinguish internal vs. international migration
gen 	InternalMigration = 1 if Presentplaceofresidence >= 1 & Presentplaceofresidence <= 3
replace InternalMigration = 0 if Presentplaceofresidence == 4

count if InternalMigration == .							// 161 unknown
count if missing(InternalMigration) & Whethersent==1	// 28 unknown who sent remit

recode Sex 2=0
recode Whetherengagedin 2=0 9=.
recode Whethersent 2=0 		


**** --> 100,647 Out-migrants
save "$Data\India\NSS\Built\NSS 64_10.2 Out-Migrants Person Level.dta", replace


gen InternalRemit = Amountofremittancessentinlast3 if InternalMigration == 1
gen InternationalRemit = Amountofremittancessentinlast3 if InternalMigration == 0
gen MaleInternalRemit = Amountofremittancessentinlast3 if InternalMigration == 1 & Sex==1

gen OutMigrationMembers=1
gen OutMigrationMale= Sex==1
gen OutMigrationInternal= InternalMigration==1
gen OutMigrationRemit= Whethersent==1
gen OutMigrationMaleInternal= Sex==1 & InternalMigration==1
gen OutMigrationInternalRemit= InternalMigration==1 & Whethersent==1
gen OutMigrationMaleRemit= Sex==1 & Whethersent==1
gen OutMigrationMaleInternalRemit= Sex==1 & InternalMigration==1 & Whethersent==1

collapse (sum) OutMigration* InternalRemit InternationalRemit MaleInternalRemit, /// 
	by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)	// --> 53,691 sending HHs
	
save "$Data\India\NSS\Built\NSS 64_10.2 Out-Migrants HH Level.dta", replace
