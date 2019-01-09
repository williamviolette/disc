* analysis_test.do

* cd /Users/williamviolette/disc/disc_code/subcode/

set more off
set matsize 10000


global discfile = "../../"
global temp = "output/"


use "${loc}input/min_temp_80.dta", clear

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
ren 
save "${loc}temp/min_temp_80_analysis.dta", replace





use "${loc}temp/input_82_temp_dates.dta", clear
g month_start =regexs(1) if regexm(date_low_pre,"^([0-9]+)")
g day_start =regexs(1) if regexm(date_low_pre,"([0-9]+)$")

g month_end =regexs(1) if regexm(date_low_post,"^([0-9]+)")
g day_end =regexs(1) if regexm(date_low_post,"([0-9]+)$")

keep stateoc month_start day_start month_end day_end

destring *, replace force
drop if month_start==.
save "${loc}temp/cold_date_80s.dta", replace









use "${mort}mort_age.dta", clear

// reshape wide deaths, i(stateoc month day year) j(A)
// drop if day==.
// replace deaths0=0 if deaths0==.
// replace deaths1=0 if deaths1==.
// replace deaths2=0 if deaths2==.

replace deaths=0 if deaths==.

merge m:1 stateoc using "${loc}temp/cold_date_80s.dta"
drop if _merge==2
drop _merge

g date=mdy(month,day,year)
drop if date==.
duplicates drop stateoc date, force

** do enter dc period
g start = month == month_start & day == day_start

global M = 30
global idvar ="start"
global groupvar = "stateoc"

sort stateoc date


*** population adjustment!! 

g treat=(A==1 | A==2)

egen dtotal=sum(deaths), by(stateoc date)
g ldt=log(dtotal+1)

*** IMPLEMENTED LATER!
*keep if year>=1982 

g ld=log(deaths+1)

global M = 30

cap program drop graph_trend
program define graph_trend

	local fe_var "`2'"
	local outcome "`1'"
	local T_high "${M}"
	local T_low "-${M}"
	preserve
		`4'
		`5'
		cap drop T
		g T = .
		replace T = 0 if ${idvar}==1
		forvalues v=1/$M {
		qui by ${groupvar}: replace T=-`v' if ${idvar}[_n+`v']==1 
		}
		forvalues v=1/$M {
		qui by ${groupvar}: replace T=`v' if ${idvar}[_n-`v']==1 
		}
		** FULL ***
		replace T=. if T<`=`T_low'' | T>`=`T_high''
		qui sum T, detail
		local time_min `=r(min)'
		local time `=r(max)-r(min)'
		replace T=99 if T==.
		qui tab T, g(T_)
// 		** NON-FULL ***
// 		keep if T>=`=`T_low'' & T<=`=`T_high''
// 		qui tab T, g(T_)
// 		qui sum T, detail
// 		local time_min `=r(min)'
// 		local time `=r(max)-r(min)'

		egen demean = mean(`outcome'), by(date A)
		replace `outcome'=`outcome'-demean
		areg `outcome' T_*, absorb(`fe_var') cluster(`fe_var') r 
		*reg `outcome' T_* , cluster(`fe_var') r 
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
    	 graph export  "${loc}temp/trend_age_`3'.pdf", as(pdf) replace
   	restore
end


graph_trend dt stateoc  test

graph_trend ldt stateoc  test 


* graph_trend ld stateoc  test "keep if A==0"


*graph_trend deaths stateoc  test "keep if A==1"






cap program drop graph_trend2
program define graph_trend2

	preserve
		cap drop T
		g T = .
		replace T = 0 if ${idvar}==1
		forvalues v=1/$M {
		qui by ${groupvar}: replace T=-`v' if ${idvar}[_n+`v']==1 
		}
		forvalues v=1/$M {
		qui by ${groupvar}: replace T=`v' if ${idvar}[_n-`v']==1 
		}
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
		egen demean = mean(deaths), by(date A)
		replace deaths=deaths-demean
		areg deaths *_no *_yes, absorb(stateoc) cluster(stateoc) r 
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
    	 ytitle("deaths")
    	 graph export  "${loc}temp/trend_age.pdf", as(pdf) replace
    	 erase "${loc}temp/temp_est.dta"
    	 erase "${loc}temp/temp_est_no.dta"
    restore
end


graph_trend2











