* analysis_test.do


set more off

global loc =  "/Volumes/GoogleDrive/My Drive/disc_data/"


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

drop if WEEKDAY==9

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

save "${loc}temp/temp_weekday.dta", replace


***** PREP POLICY DATA *****

use "${loc}input/dc_cold.dta", clear
	replace state =  "District Of Columbia" if state== "District of Columbia"
	ren state STATE
	ren year YEAR
save "${loc}temp/dc_cold_to_merge.dta", replace

use "${loc}input/wonder.dta", clear

	merge 1:1 STATE YEAR WEEKDAY MONTH using "${loc}temp/temp_weekday.dta"
	keep if _merge==3  // LOST A COUPLE STATES HERE IN THE TEMPERATURE DATA
	drop _merge

	merge m:1 STATE YEAR using "${loc}temp/dc_cold_to_merge.dta"
	drop if _merge==2
	drop _merge

save "${loc}temp/full_data_test.dta", replace







