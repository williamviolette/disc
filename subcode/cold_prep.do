* cold_prep.do


set more off

global run_local = 1

if ${run_local} == 1 {
	cd "/Volumes/GoogleDrive/My Drive/utility_health/"
}



use "data/input/dc_total.dta", clear

*** CLEAN COLD 

drop temp

g temp = regexs(1) if regexm(temp_t,"([0-9][0-9])")
order state year temp

replace temp = "" if state=="Utah" | state=="Rhode Island" | state=="Ohio" | state=="Minnesota" | state=="Michigan" | state=="Massachusetts" | state=="Maine"  | state=="Kentucky" | state=="Connecticut" | state=="Washington"

destring temp, replace force
replace temp = . if temp>40
replace temp = 32 if state=="Maryland" & year>=2015
replace temp = 20 if state=="Iowa"

g m_start = substr(date_t,1,2)
g d_start = substr(date_t,4,2) 
destring m_start d_start, ignore(-) replace force

g m_end = regexs(1) if regexm(date_t,"[0-9][ ]*-[ ]*([0-9]+)")
g d_end = regexs(1) if regexm(date_t,"[0-9][ ]*-[ ]*[0-9]+/([0-9]+)")
destring m_end d_end, replace force

* order m_end, before(date_t)
* order d_end, before(date_t)

order state year temp m_start d_start m_end d_end
keep state year temp m_start d_start m_end d_end

save "data/input/dc_cold.dta", replace  




