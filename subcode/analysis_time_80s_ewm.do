set more off
set matsize 10000



cap program drop omit
program define omit
  local original ${`1'}
  local temp1 `0'
  local temp2 `1'
  local except: list temp1 - temp2
  local modified
  foreach e of local except{
   local modified = " `modified' o.`e'"
  }
  local new: list original - except
  local new " `modified' `new'"
  global `1' `new'
end



* use "${loc}temp/input_82_temp.dta", clear // determines which policy data to use
* use "${loc}temp/input_82_temp_dates.dta", clear





use "${loc}temp/input_82_temp.dta", clear

replace winter=lower(winter)

g w_policy = regexm(winter,"weather")==1 | ///
			 regexm(winter,"yes")==1 | ///
			 regexm(winter,"winter")==1 

g month_start =regexs(1) if regexm(date_low_pre,"^([0-9]+)")
g day_start =regexs(1) if regexm(date_low_pre,"([0-9]+)$")

g month_end =regexs(1) if regexm(date_low_post,"^([0-9]+)")
g day_end =regexs(1) if regexm(date_low_post,"([0-9]+)$")

destring month_start day_start month_end day_end, replace force


g day_start_policy =regexs(1) if regexm(winter_date,"^[0-9]+/([0-9]+)/[0-9]+")

g month_start_policy =regexs(1) if regexm(winter_date,"^([0-9]+)/[0-9]+/[0-9]+")
replace month_start_policy =regexs(1) if regexm(winter_date,"^([0-9]+)/[0-9]+") & month_start_policy==""

g year_start_policy =regexs(1) if regexm(winter_date,"^[0-9]+/[0-9]+/([0-9]+)")
replace year_start_policy =regexs(1) if regexm(winter_date,"^[0-9]+/([0-9]+)") & year_start_policy==""
replace year_start_policy="19"+year_start_policy
replace year_start_policy=winter_date if regexm(winter_date,"/")!=1
replace year_start_policy="1980" if regexm(year_start_policy,"80-81")==1

destring year_start_policy month_start_policy day_start_policy, replace force

ren temp_low temp



keep fipsst w_policy month_start day_start month_end day_end year_start_policy month_start_policy day_start_policy temp

foreach var of varlist w_policy month_start day_start month_end day_end year_start_policy month_start_policy day_start_policy temp {
	ren `var' `var'_all
}

drop if fipsst == .

save "${loc}temp/input_82_temp_all.dta", replace




use "${loc}temp/input_82_temp_dates.dta", clear
	g month_start =regexs(1) if regexm(date_low_pre,"^([0-9]+)")
	g day_start =regexs(1) if regexm(date_low_pre,"([0-9]+)$")

	g month_end =regexs(1) if regexm(date_low_post,"^([0-9]+)")
	g day_end =regexs(1) if regexm(date_low_post,"([0-9]+)$")

	g temp = substr(temp_low,1,2)
	destring temp, replace force
	keep state fipsst month_start day_start month_end day_end temp

destring fipsst month_start day_start month_end day_end temp, replace force
drop if fipsst == .

*drop if month_start==. // define treated states as having clear policy start date? (not for now...)
save "${loc}temp/cold_date_temp_80s.dta", replace




use "${loc}temp/cold_date_temp_80s.dta", clear

merge  1:1 fipsst using  "${loc}temp/input_82_temp_all.dta"
drop _merge

destring temp*, replace force
replace temp = temp_all if temp==. & temp_all!=.
drop temp_all

ren w_policy_all wpol

foreach var of varlist month_start day_start month_end day_end {
	replace `var'=`var'_all if `var'==. & `var'!=.
	drop `var'_all
}

ren *_all *

keep fipsst temp wpol month_start day_start month_end day_end day_start_policy month_start_policy year_start_policy

save "${loc}temp/cold_date_80s_analysis.dta",  replace





use "${loc}temp/mort_age_ewm.dta", clear

replace A = A+90 if ewm==1
drop ewm fipsst

reshape wide deaths, i(fipsco year month day) j(A)
 
foreach v of varlist deaths* {
replace `v'=0 if `v'==.
}

egen deaths_all = rowtotal(deaths*)

egen deaths_ewm = rowtotal(deaths9*)

ren deaths0 deaths_young_oth
ren deaths1 deaths_mid_oth
ren deaths2 deaths_old_oth

ren deaths90 deaths_young_ewm
ren deaths91 deaths_mid_ewm
ren deaths92 deaths_old_ewm

g date=mdy(month,day,year)
drop month day year

duplicates drop date fipsco, force
drop if date==.

save "${loc}temp/mort_age_ewm_to_merge.dta", replace




use "${loc}input/full_temp.dta", clear

ren VALUE f

replace f = round((f/10)*(9/5) + 32,1)

g fipsst=substr(string(geoid10),1,1) if length(string(geoid10))==4
replace fipsst= substr(string(geoid10),1,2) if length(string(geoid10))==5
destring fipsst, replace force

ren geoid10 fipsco

merge m:1 fipsst using "${loc}temp/cold_date_80s_analysis.dta"
	keep if _merge==3
	drop _merge

merge 1:1 fipsco date using "${loc}temp/mort_age_ewm_to_merge.dta"
	drop if _merge==2
	drop _merge

foreach var of varlist deaths* {
	replace `var'=0 if `var'==. 
}

save "${loc}input/full_ewm.dta", replace



