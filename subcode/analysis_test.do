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

* first, just time trends of deaths and temperature
preserve
collapse (sum) deaths (mean) MIN_tmin_med MEAN_tmin_med, by(YEAR MONTH)
tostring YEAR, g(y)
tostring MONTH, g(m)
egen d=concat(y m), punct(-)
g date=monthly(d, "YM")
format date %tmMonCCYY
replace deaths=deaths/1000
tw (line deaths date, lw(thick)) (line MIN_tmin_med date, yaxis(2)) (line MEAN_tmin_med date, yaxis(2)), xti("") yti("Deaths, 1000s", axis(1)) yti("Temperature", axis(2)) legend(order(1 "Deaths" 2 "Min" 3 "Mean") r(1)) xlab(492 528 564 600 636 672)
graph export  "${discfile}${temp}trends_temp_deaths.pdf", as(pdf) replace
restore

* a few graphical explorations of the raw relationship between temperature and deaths:

	preserve
	g mytemp=round(MIN_tmin_med)
	g counter=1
	collapse (sum) deaths counter, by(mytemp)
	replace deaths=deaths/1000
	tw (scatter deaths mytemp) (scatter counter mytemp, msize(vsmall)), xli(32, lc(gs8) lp(dash)) xlab(-50 0 32 "32ºF" 50 100) xti("Minimum temperature") yti("") legend(order(1 "Deaths, 1000s" 2 "Frequency"))	
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

	g MIN_tmin_med_2=MIN_tmin_med*MIN_tmin_med
	areg deaths MIN_tmin_med MIN_tmin_med_2 i.YM, a(S) // pos and neg for square term 

	
	
	areg deaths MIN_tmin_med i.YEAR i.WEEKDAY i.MONTH, a(S)




**** FIRST IDEA :  TEMPERATURE GRADIENT FOR TREATED AND UNTREATED STATES (focus on 32 degrees)

use "${loc}temp/full_data_test.dta", clear

* a really simple version here: states with and without disconnection policies
preserve
	g policy=temp!=.
	bysort STATE: egen check=sd(policy) 
	tab STATE if check!=0
	g mytemp=round(MIN_tmin_med)
	collapse (sum) deaths if check==0, by(mytemp policy)
	replace deaths=deaths/1000
	reshape wide deaths, i(mytemp) j(policy)
	g diff=deaths1-deaths0
	tw (scatter deaths1 mytemp) (scatter deaths0 mytemp) (line diff mytemp) (lfit diff mytemp if mytemp<32, lc(gs8) lp(dash)) (lfit diff mytemp if mytemp>32, lc(gs8) lp(dash)) if mytemp>=0 & mytemp<=50, xli(32, lc(gs8) lp(dash)) xlab(0 32 "32ºF" 50) xti("Minimum temperature") yti("Deaths, 1000s") legend(order(1 "With disconnection policy" 2 "Without" 3 "Difference") r(1)) 
	graph export  "${discfile}${temp}raw_mintemp_deaths_bypolicy.pdf", as(pdf) replace
	** this looks odd... not quite what I would've expected 
restore


* now do something similar to what will did
use "${loc}temp/full_data_test.dta", clear

merge m:1 STATE YEAR using "${loc}input/state_pop.dta"
keep if _merge==3
drop _merge


g policy=temp!=.
bysort STATE: egen check=sd(policy) 
keep if check==0

drop policy check
g dc32=1 if temp==32
replace dc32=0 if temp==.
drop if dc32==.


egen S = group(STATE)


egen YM=group(YEAR MONTH)
egen full_date = group(YEAR MONTH WEEKDAY)


g T = round(MIN_tmin_min)

global M = 30

replace T=T-32
replace T=`=${M}' if T>=`=${M}'
replace T=`=-${M}' if T<=`=-${M}'

qui tab T, g(T_)
foreach var of varlist T_* {
			g `var'_no = `var'==1 & dc32==0
			g `var'_yes = `var'==1 & dc32==1
			drop `var'
}

ren T_31_no omit_no
ren T_31_yes omit_yes

gen ldeaths=log(deaths)
gen rdeaths=100000*deaths/pop

qui areg deaths T_* omit_* i.YM i.WEEKDAY, a(STATE) cluster(STATE) r 

preserve

	parmest, fast  
	save "${loc}temp/temp_est.dta", replace

	use "${loc}temp/temp_est.dta", clear
		keep if regexm(parm,"_no")==1
		g F=_n+1
		replace F=F+1 if F>31
		replace F=32 if F==63
		ren estimate est_no
		ren min95 min95_no
		ren max95 max95_no
		keep F est min max
	save "${loc}temp/temp_est_no.dta", replace
	
	use "${loc}temp/temp_est.dta", clear
		keep if regexm(parm,"_yes")==1
		g F=_n+1
		replace F=F+1 if F>31
		replace F=32 if F==63
		ren estimate est_yes
		ren min95 min95_yes
		ren max95 max95_yes
		keep F est min max
	save "${loc}temp/temp_est_yes.dta", replace
	
	use "${loc}temp/temp_est_no.dta", clear
	merge 1:1 F using "${loc}temp/temp_est_yes.dta"
	drop _merge

	tw (line est_no F, lc(cranberry) lw(thick)) (line est_yes F, lc(navy) lw(thick)) (line min95_no F if F<32, lp(dash) lc(red)) (line min95_no F if F>32, lp(dash) lc(red)) (line max95_no F if F<32, lp(dash) lc(red)) (line max95_no F if F>32, lp(dash) lc(red)) (line min95_yes F if F<32, lp(dash) lc(midblue)) (line min95_yes F if F>32, lp(dash) lc(midblue)) (line max95_yes F if F<32, lp(dash) lc(midblue)) (line max95_yes F if F>32, lp(dash) lc(midblue)), legend(order(2 "States with policies" 1 "States without")) xti("Degrees Fahrenheit") xlab(2 "{&le} 2" 12 "12" 22 "22" 32 "32" 42 "42" 52 "52" 62 "{&ge} 62")
	graph export  "${loc}temp/first_regs.pdf", as(pdf) replace
	
	erase "${loc}temp/temp_est.dta"
	erase "${loc}temp/temp_est_no.dta"
	erase "${loc}temp/temp_est_yes.dta"
	
restore


*** will's code 
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










