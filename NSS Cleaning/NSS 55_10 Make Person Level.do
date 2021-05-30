

*-----------------------------------------------------------------------------
// HH Consumption (HH Level) --> missing in the data file
*-----------------------------------------------------------------------------


*-----------------------------------------------------------------------------
// WORK FILE 3 (ALL03N) - Time Disposition During the Week
*-----------------------------------------------------------------------------

use "$Data\India\NSS\Raw\Nss55_10\Schedule 55 10 Work File ALL03N.dta", clear


*Collapse to make it person level and retain weekly wage/salary earnings
collapse (sum) totwagereced, ///
	by(fsuno segno Secondstgstrm samphhno personsrl subrnd subsamp age)

tempfile wage
save `wage'

*-----------------------------------------------------------------------------
// WORK FILE 5 (ALL05) - HH Members(Person Level)
*-----------------------------------------------------------------------------

use "$Data\India\NSS\Raw\Nss55_10\Schedule 55 10 Work File ALL05.dta", clear

* Two odd duplicates
duplicates drop fsuno segno Secondstgstrm samphhno personsrl subrnd visitno, force	

merge 1:1 fsuno segno Secondstgstrm samphhno personsrl subsamp age ///
	using `wage'
drop if _merge==2		// 176 of lost observation have positive wage
drop _merge


* REMOVE REVISITS
drop if subsamp==9


*UNIQUE IDENTIFIERS
egen hhid = group(fsuno segno Secondstgstrm samphhno subrnd)
egen personid = group(fsuno segno Secondstgstrm samphhno personsrl subrnd)

*Construct HH Size
egen PersonTag=tag(personid)
bys hhid: egen HHSize=sum(PersonTag)	

*MULTIPLIERS
gen Mult = mult/800 if ssreplicate>1
replace Mult = mult/400 if ssreplicate==1
gen Mult_Person=Mult*HHSize


*RENAME and DROP VARIABLES
drop workfileid PersonTag mult

*-Block 1: Identification of Sample HH
rename roundsch  Round           
replace Round=55
rename sector  Sector
rename stateregion StateRegion 
rename district  District     
rename subrnd  SubRound  
rename subsamp SubSample

rename fsuno  FSUSerialNo  
rename segno HamletgroupSubblockno
rename Secondstgstrm  Secondstagestratumno
rename samphhno  SamplehhldNo  

drop stratum visitno svc reasubs Nss ssreplicate
  

*-Block 3: HH Characteristics
rename socialgrp  SocialGroup
rename religion  Religion 
rename hhdtype  HHType
rename mpce  MonthlyHHconsumerexpenditureRs
gen MPCE = MonthlyHHconsumerexpenditureRs/HHSize
rename landposs  LandPossessed  

drop landowned landcultivated


*-Block 4: Demographic and Migration Particulars of HH Members
rename personsrl  PersonSerialno 

rename relationtohead  Relationtohead
rename sex  Sex    
rename age  Age   
rename marstatus  Maritalstatus
rename geneducation  GeneralEducation
rename techeducation  TechnicalEducation

drop attenineduInstt emploexchange

rename stayinvill  Stayedinforlast6monthsormore  
rename stayaway  Stayedawayforempl60daysormore          
rename diffplaceenumeration  Placeofenumerationdiffersfroml
rename periodleaving  Periodsinceleavingthelastuprye 
rename location  Particularsoflastuprlocation  
rename statecode  ParticularsoflastuprStateutcou  
rename statusmigration  UsualactivityMigStatuscode
rename nicmigration  UsualactivityMigNIC98		//2 digit NIC 98
rename reasonmigration  Reasonforleavingthelastuprcode


*-Block 5.1 & 5.2: Usual Principal and Subsidiary Activity of HH Members
rename prnsts  UsualPrincipalStatus  
rename prnnic  UsualactivityNIC98
rename prnnco  UsualactivityNCO68      
rename engagedinsubwrk Engagedinsubsidiary  
recode Engagedinsubsidiary 2=0
rename substs1  SubsidiaryStatus
rename subnic1  SubsidiaryNIC98
rename subnco1  SubsidiaryNCO68

*-Block 5.3: Time Disposition During the Week
rename totwagereced WeeklyWageSalary

drop substs2 subnic2 subnco2 ///
	wksts wknic wknco nosubact skillpossed ///
	periodseekingwrk totworkingdays nominalwrkday ///
	uslsts uslnic uslnco engagedfullparttime morelessregx8Ax97xC8ly ///
	nomonthwithoutwrk soughtwrk madeeffort ///
	soughtaddlnwrk reasonaddlnwrk soughtalterwrk reasonalterwrk ///
	anyunionasso memberunionasso natureemployment coveredprovifund ///
	changests lastactstatus changeindustry lastindustry changeoccupation ///
	lastoccupation changeestablishment reasonforchange sexhead


*DUMMIES for EDUCATION
gen EdIlliterate=GeneralEducation==1
gen EdBelowPrimary=GeneralEducation>=2 & GeneralEducation<=5
gen EdPrimary=GeneralEducation==6
gen EdMiddle=GeneralEducation==7
gen EdSecondary=GeneralEducation==8
gen EdHigherSecondary=GeneralEducation==9
gen EdGraduate=GeneralEducation>=10 & GeneralEducation<=13
foreach var of varlist Ed* {
	replace `var' = . if missing(GeneralEducation)
}

*duplicates drop			// no duplicates
compress
destring UsualactivityNCO68 SubsidiaryNCO68, replace force


save "$Data\India\NSS\Built\NSS 55_10 Person Level.dta", replace
 