

********************************************************************************
// ----------------- INTERNAL CONSISTENCY OF BLOCK 7 -----------------
use "$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level07.dta", clear


egen monthly0=total(ValueofconsumptionRslast30days) if Srlno >= 1 & Srlno <= 15, ///
	by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)
	
egen yearlytot=total(ValueofconsumptionRslast365day) if Srlno >= 17 & Srlno <= 20, ///
	by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)
	
gen yearly0 = round(yearlytot*30/365)

egen monthly=mean(monthly0), ///
	by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)
egen yearly=mean(yearly0), ///
	by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)

gen hhexp = monthly + yearly


gen equal = (hhexp == ValueofconsumptionRslast30days) if Srlno==23
tab equal

*br if equal == 0


// Some of the inconsistencies stem from zero yearly-consumption, which is probable.
// Four of them are the HHs without any consumption in last 30 days. Weird but can be. 
// So, the total montly consumption on line 23 is reliable.
********************************************************************************

/*******************************************************************************
// --------- CHECK Monthly HH consumption, block 7 vs. block 3-17 -----------
use "$Data\India\NSS\Built\NSS 64_10.2 Person Level.dta", clear

collapse (max) MonthlyHHconsumerexpenditureRs ValueofconsumptionRslast30days, ///
	by(FSUSerialNo HamletgroupSubblockno Secondstagestratumno SamplehhldNo)

gen equal = (MonthlyHHconsumerexpenditureRs == ValueofconsumptionRslast30days)
tab equal		// All equal
drop equal	
// --------------------------------------------------------------------------
*/******************************************************************************

********************************************************************************
// ----------------- CHECK HH SIZE -----------------
use "$Data\India\NSS\Built\NSS 64_10.2 Person Level.dta", clear

*Construct HH Size
egen PersonTag=tag(personid)
bys hhid: egen HHSize2=sum(PersonTag)	

gen equal = (HHSize == HHSize2)
tab equal		// All eqaul
drop equal
********************************************************************************

********************************************************************************
********************************************************************************
// ---------- CHECK Out-Migration Questionnaire (Block3.1) --------------

use "$Data\India\NSS\Raw\Nss64_10.2\Schedule 10.2 level03.dta", clear

count if Serialno != 99		// 100,647 Out-migrants

egen hhid = group(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)	//53,961 HHs

// ---------------------- Consistency within block 3.1 ----------------------
bys hhid: egen RemitSum = sum(Amountofremittancessentinlast3) if Serialno != 99
bys hhid: egen TotalRemit=max(RemitSum)
count if TotalRemit!=Amountofremittancessentinlast3 & Serialno==99	//->24
count if TotalRemit!=Amountofremittancessentinlast3 & Serialno==99	& TotalRemit==0 //->24
	//-> All with 0 Remit -> Block 3.1 is internally consistent
drop RemitSum
// --------------------------------------------------------------------------


keep if Serialno == 99 		// remittance receiving HHs: 30,149

rename Amountofremittancessentinlast3 TotalRemit99		// 24 missing TotalRemit99

tempfile remittance
save `remittance'

use "$Data\India\NSS\Built\NSS 64_10.2 Person Level.dta"
rename HamletgroupSubblockno hgsbno
merge m:1 FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo ///
	using `remittance'
drop _merge

// collapse to HH level
collapse (max) OutMigration* InternalRemit InternationalRemit ///
	Noofmembersmigratedoutmale Noofmembersmigratedoutfemale ///
	Amntofremittancesduringlast365 TotalRemit TotalRemit99, ///
	by(FSUSerialNo hgsbno Secondstagestratumno SamplehhldNo)

	
gen TotalRemit2 = InternalRemit + InternationalRemit // 71,617 missing


drop if TotalRemit99==.		
drop if TotalRemit99==0

gen equal = (TotalRemit == TotalRemit99)
tab equal		// All equal -> Block 3.1 is intenally consistent
drop equal

gen equal = (TotalRemit2 == TotalRemit99)
tab equal		// 28 inconsistent observation due to uknown internal or international
drop equal


// ------- Check amounts of remit recieved, block 3-15 vs. block 3.1-10 -------
gen equal = (TotalRemit == Amntofremittancesduringlast365) 
tab equal		// All equal 
drop equal
// ----------------------------------------------------------------------------


// ----------- CHECK NUMBER OF OUT-MIGRANTS - MALE & FEMALE -----------
use "$Data\India\NSS\Built\NSS 64_10.2 Person Level.dta", clear

collapse (max) OutMigration* Noofmembersmigratedoutmale Noofmembersmigratedoutfemale, ///
	by(hhid)

gen Noofmembersmigratedout = Noofmembersmigratedoutmale + Noofmembersmigratedoutfemale
egen OutMigrant=sum(Noofmembersmigratedout)
di OutMigrant
	// -> 54,235 Out-migrants reported in block 3, but 100,647 Out-migrants reported in block 3.1

*-> Block 3, entry 13&14 might be problematic since entry 12 (number of HHs which sent migrants in the past) consistent with block 3.1
	
// Only HHs sent migrants
drop if OutMigrationMembers==.

//	Check Male out-migrants block 3-13 vs. block 3.1

gen equal = (Noofmembersmigratedoutmale == OutMigrationMale)
tab equal		// ?????
drop equal


//	Check Female out-migrants block 3-14 vs. block 3.1

gen equal = (Noofmembersmigratedoutfemale == OutMigrationMembers - OutMigrationMale)
tab equal		// ?????
drop equal


********************************************************************************
********************************************************************************



