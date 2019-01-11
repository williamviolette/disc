


* this program graphs an event study looking at days around the
* time when the policies take effect (each year) and mortality for
* treated states (with date-specific policies) and untreated states (without)


set more off
set matsize 10000


global discfile = "../../"
global temp = "output/"


use "${loc}temp/input_82_temp_dates.dta", clear
g month_start =regexs(1) if regexm(date_low_pre,"^([0-9]+)")
g day_start =regexs(1) if regexm(date_low_pre,"([0-9]+)$")

g month_end =regexs(1) if regexm(date_low_post,"^([0-9]+)")
g day_end =regexs(1) if regexm(date_low_post,"([0-9]+)$")

keep stateoc month_start day_start month_end day_end

destring *, replace force
drop if month_start==.
save "${loc}temp/cold_date_80s.dta", replace



use "${loc}temp/mort_age.dta", clear

replace deaths=0 if deaths==.

merge m:1 stateoc using "${loc}temp/cold_date_80s.dta"
drop if _merge==2
drop _merge

g date=mdy(month,day,year)
drop if date==.
duplicates drop stateoc date, force

*drop if month_start!=11 & month_start!=. // get rid of states who have policies with different starting times? (keep them in control for now...)
*drop if day_start!=15 & day_start!=.

** do enter dc period
g start = month ==11 & day ==15 // focus only on the most common start date (november 15th)
g treat = month_start==11 & day_start==15

global M = 30 // days around starting event
global idvar ="start"
global groupvar = "stateoc"

sort stateoc date

egen deathst=sum(deaths), by(date stateoc) // sum deaths for all age groups together (for some specifications)
bys stateoc date: g dn=_n
g ld=log(deathst+1)


cap program drop graph_trend2
program define graph_trend2

	preserve
		`2'
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
		egen demean = mean(`1'), by(`3')
		replace `1'=`1'-demean
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
		ytitle("deaths for `4' people") legend(order(1 "untreated" 4 "treated")) ///
		 xtitle("day relative to start date") title("policy start date and deaths for `4' people")
    	 graph export  "${loc}temp/trend_age_`4'.pdf", as(pdf) replace
    	 erase "${loc}temp/temp_est.dta"
    	 erase "${loc}temp/temp_est_no.dta"
    restore
end


graph_trend2 "deaths" "keep if A==1" "date" young

graph_trend2 "deaths" "keep if A==2" "date" old

graph_trend2 "deaths" "keep if A==0" "date" other

graph_trend2 "deathst" "keep if dn==1" "date" all














