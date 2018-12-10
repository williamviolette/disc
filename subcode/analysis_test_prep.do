* analysis_test.do


set more off

* global loc =  "/Volumes/GoogleDrive/My Drive/disc_data/"


***** PREP HEALTH DATA *******

foreach v in wonder_1999_2004 wonder_2005_2016 {
import delimited using "${loc}raw/health/`v'.txt", delimiter(tab) clear
replace state = "District Of Columbia" if state=="District of Columbia"

ren state STATE

keep if STATE!=""

g MONTH = substr(monthcode,6,2)
destring MONTH, replace force

ren weekdaycode WEEKDAY
ren year YEAR 

keep STATE MONTH YEAR WEEKDAY deaths

save "${loc}input/`v'.dta", replace
}

use "${loc}input/wonder_1999_2004.dta", clear

append using "${loc}input/wonder_2005_2016.dta"

drop if WEEKDAY==9  // just 39 obs

* note: data has 50 states plus DC, from 1999-2016 
* 18 years * 12 months * 7 days a week * 51 states = 77,112 obs for balanced panel 

save  "${loc}input/wonder.dta", replace
erase "${loc}input/wonder_1999_2004.dta"
erase "${loc}input/wonder_2005_2016.dta"



****** PREP TEMP DATA ******

use "${loc}input/min_temp.dta", clear

gen WEEKDAY = dow( mdy( MONTH, DAY, YEAR) ) + 1

drop DAY

foreach var of varlist tmin_* {
	egen MIN_`var' =min(`var'), by(STATE YEAR MONTH WEEKDAY)
	egen MEAN_`var' =mean(`var'), by(STATE YEAR MONTH WEEKDAY)
}

drop tmin_*
duplicates drop STATE YEAR MONTH WEEKDAY, force

drop if YEAR>2016 // we don't have deaths data after 2016
*  note: data has 48 states in continental us (no DC)
* 16 years * 12 months * 7 days a week * 48 states = 64,512 obs for balanced panel

save "${loc}temp/temp_weekday.dta", replace


***** PREP POLICY DATA *****

use "${loc}input/dc_cold.dta", clear
	replace state =  "District Of Columbia" if state== "District of Columbia"
	ren state STATE
	ren year YEAR
	drop if strlen(STATE)>25  // get rid of obs that are not state names 
	* generate 2010 observations by duplicating 2009 values:
	g exp=1
	replace exp=2 if YEAR==2009
	expand exp
	bysort STATE YEAR: g n=_n
	replace YEAR=2010 if n==2
	drop exp n
	* generate 2001, 2002 and 2003 obs by duplicating 2004 values:
	g exp=1
	replace exp=4 if YEAR==2004
	expand exp
	bysort STATE YEAR: g n=_n
	replace YEAR=2001 if n==2
	replace YEAR=2002 if n==3
	replace YEAR=2003 if n==4
	drop exp n
save "${loc}temp/dc_cold_to_merge.dta", replace

use "${loc}input/wonder.dta", clear

	merge 1:1 STATE YEAR WEEKDAY MONTH using "${loc}temp/temp_weekday.dta"
	keep if _merge==3  // lost Alaska, Hawaii, DC, and all states for years 1999-2000 (missing in temp data)
	drop _merge

	merge m:1 STATE YEAR using "${loc}temp/dc_cold_to_merge.dta"
	drop if _merge==2  // these are data for 2018 for all 51 states, and data for AK, HI, DC
	drop _merge

save "${loc}temp/full_data_test.dta", replace  // balanced panel of 48 states, 16 years (2001-2016), 12 months, 7 weekdays







