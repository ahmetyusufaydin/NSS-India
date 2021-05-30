
********************************
******** Out-Migrants **********


use "$Data\India\NSS\Built\NSS 64_10.2 Out-Migrants Person Level.dta", clear

recode Sector 2=0

*ADULTS (Prime Age)
keep if Presentage>=15 & Presentage<=64

*MALE 
keep if Sex==1


tab Presentplaceofresidence

tabstat InternalMigration, stat(n mean)


keep if InternalMigration==1

// --------- All ---------
tabstat Presentage Sex Periodsinceleavingthehousehold Whetherengaged Whethersent, stat(n mean)
tabstat Amountofremittancessentinlast3, stat(n mean min max)

*Reason for Migration
gen RMSearchEmp = Reasonformigration==1 | Reasonformigration==2
gen RMBusiness = Reasonformigration==3
gen RMTakeEmp = Reasonformigration==4
gen RMTransfer = Reasonformigration==5
gen RMProximity = Reasonformigration==6
gen RMStudy = Reasonformigration==7
gen RMMarriage = Reasonformigration==16
gen RMFamily = Reasonformigration==17
gen RMOther = Reasonformigration>=8 & Reasonformigration<=15 | Reasonformigration==19
tabstat RM*, stat(n mean)

// --------- Coming from rural HH ---------
preserve
keep if Sector == 1

tabstat Presentage Sex Periodsinceleavingthehousehold Whetherengaged Whethersent, stat(n mean)
tabstat Amountofremittancessentinlast3, stat(n mean min max)
tabstat RM*, stat(n mean)

restore


// --------- Coming from urban HH ---------
preserve
keep if Sector == 0

tabstat Presentage Sex Periodsinceleavingthehousehold Whetherengaged Whethersent, stat(n mean)
tabstat Amountofremittancessentinlast3, stat(n mean min max)
tabstat RM*, stat(n mean)

restore