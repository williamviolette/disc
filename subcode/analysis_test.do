* analysis_test.do



set more off
set matsize 10000


global discfile = "../../"
global temp = "output/"


use "${loc}temp/full_data_test.dta", clear

egen f = max(temp), by(STATE)

egen m_s_max=max(m_start), by(STATE)
egen m_e_max=max(m_end), by(STATE)

egen S = group(STATE)

* a few graphical explorations of the raw relationship between temperature and deaths:

	preserve
	g mytemp=round(MIN_tmin_med)
	collapse (sum) deaths, by(mytemp)
	replace deaths=deaths/1000
	tw (scatter deaths mytemp), xli(32, lc(gs8) lp(dash)) xlab(-50 0 32 "32ºF" 50 100) legend(off) xti("Minimum temperature") yti("Deaths, 1000s")
	graph export  "${discfile}${temp}raw_mintemp_deaths.pdf", as(pdf) replace
	restore

	preserve
	g mytemp=round(MEAN_tmin_mean)
	collapse (sum) deaths, by(mytemp)
	replace deaths=deaths/1000
	tw (scatter deaths mytemp), xli(32, lc(gs8) lp(dash)) xlab(-50 0 32 "32ºF" 50 100) legend(off) xti("Mean temperature") yti("Deaths, 1000s")
	graph export  "${discfile}${temp}raw_mintemp_deaths2.pdf", as(pdf) replace
	restore

	preserve
	drop if MONTH>4 & MONTH<11
	g mytemp=round(MIN_tmin_med)
	collapse (sum) deaths, by(mytemp)
	replace deaths=deaths/1000
	tw (scatter deaths mytemp), xli(32, lc(gs8) lp(dash)) xlab(-50 0 32 "32ºF" 50 100) legend(off) xti("Minimum temperature") yti("Deaths, 1000s") note("Note: Restricting to data from Nov-Apr.")
	graph export  "${discfile}${temp}raw_mintemp_deaths3.pdf", as(pdf) replace
	restore
	
	preserve
	drop if MONTH>4 & MONTH<11
	g mytemp=round(MIN_tmin_med)
	collapse (sum) deaths, by(mytemp STATE)
	replace deaths=deaths/1000
	sort STATE
	egen s=group(STATE)
	scatter deaths mytemp if s<25, by(STATE) xli(32, lc(gs8) lp(dash)) xlab(-50 0 32 "32ºF" 50 100) ylab(0 100 200) legend(off) xti("Minimum temperature") yti("Deaths, 1000s") note("Note: Restricting to data from Nov-Apr.")
	graph export  "${discfile}${temp}raw_mintemp_deaths4.pdf", as(pdf) replace
	scatter deaths mytemp if s>=25, by(STATE) xli(32, lc(gs8) lp(dash)) xlab(-50 0 32 "32ºF" 50 100) ylab(0 100 200) legend(off) xti("Minimum temperature") yti("Deaths, 1000s") note("Note: Restricting to data from Nov-Apr.")
	graph export  "${discfile}${temp}raw_mintemp_deaths5.pdf", as(pdf) replace
	restore 
	
	
* initial explorations of relationship between temperature and deaths in regression form:

	egen YM=group(YEAR MONTH)

	reg deaths MIN_tmin_med // positive relationship: opposite of what we expect!
	reg deaths MIN_tmin_med i.MONTH i.YEAR // positive relationship
	reg deaths MIN_tmin_med i.YM // positive relationship
	areg deaths MIN_tmin_med, a(STATE) // with state FE it becomes negative!
	areg deaths MIN_tmin_med i.YEAR i.MONTH, a(S) // smaller magnitude but still neg
	areg deaths MIN_tmin_med i.YM, a(S) // smaller magnitude but still neg
	areg deaths MIN_tmin_med i.YM if MONTH<5 | MONTH>10, a(S) // restrict to Nov-Apr (coldest 6 months), same results larger coef

	areg deaths MIN_tmin_med i.YEAR i.WEEKDAY i.MONTH, a(S)




**** FIRST IDEA :  TEMPERATURE GRADIENT FOR TREATED AND UNTREATED STATES (focus on 32 degrees)

use "${loc}temp/full_data_test.dta", clear

egen f = max(temp), by(STATE)

egen m_s_max=max(m_start), by(STATE)
egen m_e_max=max(m_end), by(STATE)

egen S = group(STATE)

drop if f!=32 & f!=.

g treat = f==32

egen full_date = group(YEAR MONTH WEEKDAY)


g T = round(MIN_tmin_min,1) - 32

	global M = 12

cap program drop graph_trend2
program define graph_trend2

	preserve

		replace T=. if T<`=-${M}' | T>`=${M}'
		qui sum T, detail
		local time_min `=r(min)'
		local time `=r(max)-r(min)'

		
		*drop if T==.
		replace T=99 if T==.
		qui tab T, g(T_)
		drop T_`=2*${M}+2'
		foreach var of varlist T_* {
			g `var'_no = `var'==1 & treat==0
			g `var'_yes = `var'==1 & treat==1
			drop `var'
		}
		* i.full_date
		areg deaths *_no *_yes i.YEAR i.MONTH i.WEEKDAY, absorb(STATE) cluster(STATE) r 
	   	parmest, fast
	   		save "${discfile}${temp}temp_est.dta", replace

	   		use "${discfile}${temp}temp_est.dta", clear
				keep if regexm(parm,"_no")==1
				g time = _n
	   			keep if time<=`=`time''	   		
	   			replace time = time + `=`time_min''
	   			keep estimate time max95 min95
	   			ren estimate estimate_no
	   			ren max95 max95_no 
	   			ren min95 min95_no
	   		save "${discfile}${temp}temp_est_no.dta", replace

	   		use "${discfile}${temp}temp_est.dta", clear
				keep if regexm(parm,"_yes")==1
	   			g time = _n
	   			keep if time<=`=`time''   		
	   			replace time = time + `=`time_min''
	   			keep estimate time max95 min95
	   			ren estimate estimate_yes
	   			ren max95 max95_yes 
	   			ren min95 min95_yes
	   		
	   			merge 1:1 time using "${discfile}${temp}temp_est_no.dta"
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
    	 ytitle("deaths")
    	 graph export  "${discfile}${temp}trend2.pdf", as(pdf) replace
    	 erase "${discfile}${temp}temp_est.dta"
    	 erase "${discfile}${temp}temp_est_no.dta"
    restore
end


*** TEST FOR LEAKS

graph_trend2





/*


**** SECOND IDEA :  GRADIENTS OVER TIME..

use "${loc}temp/full_data_test.dta", clear

egen f = max(temp), by(STATE)
egen m_s_max=max(m_start), by(STATE)
egen m_e_max=max(m_end), by(STATE)


drop if m_start==.

foreach var of varlist MIN_tmin_med MEAN_tmin_med MIN_tmin_mean MEAN_tmin_mean MIN_tmin_min MEAN_tmin_min {
	egen `var'_m = mean(`var'), by(STATE YEAR MONTH)
	drop `var'
	ren `var'_m `var'
}
duplicates drop STATE YEAR MONTH, force
egen S = group(STATE)

	global M = 3

replace MONTH = 13 if MONTH==1 
replace MONTH = 14 if MONTH==2 
replace MONTH = 15 if MONTH==3 
replace MONTH = 16 if MONTH==4 
replace MONTH = 17 if MONTH==5 
replace MONTH = 18 if MONTH==6 


g date= ym(YEAR,MONTH)

g T=MONTH - m_start

cap program drop graph_trend
program define graph_trend
	local outcome "`1'"
	local T_high "${M}"
	local T_low "-${M}"
	preserve

		 replace T=. if T<`=`T_low'' | T>`=`T_high''
		 qui sum T, detail
		 local time_min `=r(min)'
		 local time `=r(max)-r(min)'
		 replace T=99 if T==.
		 qui tab T, g(T_)
		 drop T_1
		xi: areg `outcome' T_* i.date, absorb(STATE) cluster(STATE) r 
	   	parmest, fast
	   	g time = _n
	   	keep if time<=`=`time''
	   	replace time = time + `=`time_min''
	   	lab var time "Time"
    	*tw (scatter estimate time) || (rcap max95 min95 time)
    	tw (line estimate time, lcolor(black) lwidth(medthick)) ///
    	|| (line max95 time, lcolor(blue) lpattern(dash) lwidth(med)) ///
    	|| (line min95 time, lcolor(blue) lpattern(dash) lwidth(med)), ///
    	 graphregion(color(gs16)) plotregion(color(gs16)) xlabel(`=`T_low''(2)`=`T_high'') ///
    	 ytitle("`outcome'") xline(0)
    	 graph export  "${discfile}${temp}trend2_`2'.pdf", as(pdf) replace
   	restore
end

*** TEST FOR LEAKS

graph_trend deaths testing










