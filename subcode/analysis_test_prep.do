* analysis_test.do


set more off

global run_local = 1

if ${run_local} == 1 {
	cd "/Volumes/GoogleDrive/My Drive/utility_health/"
}


***** PREP HEALTH DATA *******

foreach v in wonder_1999_2004 wonder_2005_2016 {
import delimited using "data/raw/health/`v'.txt", delimiter(tab) clear
replace state = "District Of Columbia" if state=="District of Columbia"

ren state STATE

keep if STATE!=""

g MONTH = substr(monthcode,6,2)
destring MONTH, replace force

ren weekdaycode WEEKDAY
ren year YEAR 

keep STATE MONTH YEAR WEEKDAY deaths

save "data/input/`v'.dta", replace
}

use "data/input/wonder_1999_2004.dta", clear

append using "data/input/wonder_2005_2016.dta"

drop if WEEKDAY==9

save  "data/input/wonder.dta", replace
erase "data/input/wonder_1999_2004.dta"
erase "data/input/wonder_2005_2016.dta"



****** PREP TEMP DATA ******

use "data/input/min_temp.dta", clear

gen WEEKDAY = dow( mdy( MONTH, DAY, YEAR) ) + 1

drop DAY

foreach var of varlist tmin_* {
	egen MIN_`var' =min(`var'), by(STATE YEAR MONTH WEEKDAY)
	egen MEAN_`var' =mean(`var'), by(STATE YEAR MONTH WEEKDAY)
}

drop tmin_*
duplicates drop STATE YEAR MONTH WEEKDAY, force

save "data/temp/temp_weekday.dta", replace


***** PREP POLICY DATA *****

use "data/input/dc_cold.dta", clear
	replace state =  "District Of Columbia" if state== "District of Columbia"
	ren state STATE
	ren year YEAR
save "data/temp/dc_cold_to_merge.dta", replace

use "data/input/wonder.dta", clear

	merge 1:1 STATE YEAR WEEKDAY MONTH using "data/temp/temp_weekday.dta"
	keep if _merge==3  // LOST A COUPLE STATES HERE IN THE TEMPERATURE DATA
	drop _merge

	merge m:1 STATE YEAR using "data/temp/dc_cold_to_merge.dta"
	drop if _merge==2
	drop _merge

save "data/temp/full_data_test.dta", replace







