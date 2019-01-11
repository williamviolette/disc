

* this program graphs mortality against temperature
* for states with policies versus ones without (using daily measures)
* from 1980 to 1988

set more off
set matsize 10000


global discfile = "../../"
global temp = "output/"


use "${loc}input/min_temp_80.dta", clear

* create state index that matches temp to mortality data
sort STATE YEAR MONTH DAY
by STATE: g sn=_n
sort sn STATE
g id = _n if _n<=48

order STATE id

* Alaska	2 // HERE
replace id = id+1 if id>=2
* District of Columbia	9 // HERE
replace id = id+1 if id>=9
* Hawaii	12 // HERE 
replace id = id+1 if id>=12

egen stateoc=max(id), by(STATE)
drop id sn
ren YEAR year
ren MONTH month
ren DAY day
g date=mdy(month,day,year)

duplicates drop date STATE, force
save "${loc}temp/min_temp_80_analysis.dta", replace



* use "${loc}temp/input_82_temp.dta", clear // determines which policy data to use
use "${loc}temp/input_82_temp_dates.dta", clear
g month_start =regexs(1) if regexm(date_low_pre,"^([0-9]+)")
g day_start =regexs(1) if regexm(date_low_pre,"([0-9]+)$")

g month_end =regexs(1) if regexm(date_low_post,"^([0-9]+)")
g day_end =regexs(1) if regexm(date_low_post,"([0-9]+)$")

g temp = substr(temp_low,1,2)
destring temp, replace force
keep stateoc month_start day_start month_end day_end temp

destring *, replace force
*drop if month_start==. // define treated states as having clear policy start date? (not for now...)
save "${loc}temp/cold_date_temp_80s.dta", replace


use "${loc}temp/mort_age.dta", clear

replace deaths=0 if deaths==. 

merge m:1 stateoc using "${loc}temp/cold_date_temp_80s.dta"
drop if _merge==2
drop _merge

g date=mdy(month,day,year)
drop if date==.
duplicates drop stateoc date, force

merge m:1 stateoc date using "${loc}temp/min_temp_80_analysis.dta"
** lose alaska hawaii and DC (DC is too bad..) 
keep if _merge==3
drop _merge

sort stateoc date

g tr=round(tmin_mean,1) // running variable as temperature
g T=tr-32
g treat=temp==32 // treated states have 32 degree temperature threshold

g ld=log(deaths+1)
egen dtotal=sum(deaths), by(stateoc date) // add all ages together for alternative specification
g ldt=log(dtotal+1)

global M = 15 // temperature window around freezing



** note: this specification takes a short-cut, demeaning by date X age to save the number of fixed effects
cap program drop graph_trend2
program define graph_trend2

	preserve
		`3'
		replace T=. if T<`=-${M}' | T>`=${M}'
		qui sum T, detail
		local time_min `=r(min)'
		local time `=r(max)-r(min)'

		replace T=99 if T==.
		qui tab T, g(T_)
		drop T_`=2*${M}+2'
		foreach var of varlist T_* {
			g `var'_no = `var'==1 & treat==0
			g `var'_yes = `var'==1 & treat==1
			drop `var'
		}
		* demean the outcome by date X age to save fixed effects!
		egen demean = mean(`1'), by(date A)
		replace `1'=`1'-demean
		* SPECIFICATION
		areg `1' *_no *_yes, absorb(stateoc) cluster(stateoc) r 

	   	parmest, fast
	   		save "${loc}temp/temp_est.dta", replace

	   		use "${loc}temp/temp_est.dta", clear
				keep if regexm(parm,"_no")==1
				g time = _n
	   			keep if time<=`=`time''	   		
	   			replace time = time + `=`time_min''
	   			keep estimate time max95 min95
	   			ren estimate estimate_no
	   			ren max95 max95_no 
	   			ren min95 min95_no
	   		save "${loc}temp/temp_est_no.dta", replace

	   		use "${loc}temp/temp_est.dta", clear
				keep if regexm(parm,"_yes")==1
	   			g time = _n
	   			keep if time<=`=`time''   		
	   			replace time = time + `=`time_min''
	   			keep estimate time max95 min95
	   			ren estimate estimate_yes
	   			ren max95 max95_yes 
	   			ren min95 min95_yes
	   		
	   			merge 1:1 time using "${loc}temp/temp_est_no.dta"
	   			drop _merge

	   	lab var time "Time"
    	*tw (scatter estimate time) || (rcap max95 min95 time)
    	tw (line estimate_no time, lcolor(black) lwidth(medthick)) ///
    	|| (line max95_no time, lcolor(blue) lpattern(dash) lwidth(med)) ///
    	|| (line min95_no time, lcolor(blue) lpattern(dash) lwidth(med)) ///
    	(line estimate_yes time, lcolor(red) lwidth(medthick)) ///
    	|| (line max95_yes time, lcolor(green) lpattern(dash) lwidth(med)) ///
    	|| (line min95_yes time, lcolor(green) lpattern(dash) lwidth(med)), ///
    	 graphregion(color(gs16)) plotregion(color(gs16)) xlabel(`=-${M}'(2)`=${M}') ///
    	 ytitle("deaths for `2' people") legend(order(1 "untreated" 4 "treated")) ///
		 xtitle("temperature relative to 32") title("temperature and deaths for `2' people")
    	 graph export  "${loc}temp/trend_temp_`2'.pdf", as(pdf) replace
    	 erase "${loc}temp/temp_est.dta"
    	 erase "${loc}temp/temp_est_no.dta"
    restore
end


graph_trend2 deaths young "keep if A==1"  // for young people!

graph_trend2 deaths old "keep if A==2"  // for old people!  * maybe something going on here!

graph_trend2 deaths other "keep if A==0"  // for other  people!










