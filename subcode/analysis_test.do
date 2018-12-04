* analysis_test.do



set more off

global dataloc =  "/Volumes/GoogleDrive/My Drive/disc_data/"
global loc = "/Users/williamviolette/disc/"
global temp = "output/"


use "${dataloc}temp/full_data_test.dta", clear

egen f = max(temp), by(STATE)

egen m_s_max=max(m_start), by(STATE)
egen m_e_max=max(m_end), by(STATE)

egen S = group(STATE)

areg deaths MIN_tmin_med i.YEAR i.WEEKDAY i.MONTH, a(S)




**** FIRST IDEA :  TEMPERATURE GRADIENT FOR TREATED AND UNTREATED STATES (focus on 32 degrees)

use "${dataloc}temp/full_data_test.dta", clear

egen f = max(temp), by(STATE)

egen m_s_max=max(m_start), by(STATE)
egen m_e_max=max(m_end), by(STATE)

egen S = group(STATE)

drop if f!=32 & f!=.

g treat = f==32


g T = round(MIN_tmin_min,1) - 32



	global M = 12

cap program drop graph_trend2
program define graph_trend2
	

	preserve

		replace T=. if T<`=-${M}' | T>`=${M}'
		qui sum T, detail
		local time_min `=r(min)'
		local time `=r(max)-r(min)'
		replace T=99 if T==.
		qui tab T, g(T_)

		foreach var of varlist T_* {
			g `var'_no = `var'==1 & treat==0
			g `var'_yes = `var'==1 & treat==1
			drop `var'
		}

		xi: qui areg deaths *_no *_yes i.YEAR*i.MONTH i.WEEKDAY, absorb(STATE) cluster(STATE) r 
	   	parmest, fast
	   		save "${loc}${temp}temp_est.dta", replace

	   		use "${loc}${temp}temp_est.dta", clear
				g time = _n
	   			keep if time<=`=`time''	   		
	   			replace time = time + `=`time_min''
	   			keep estimate time max95 min95
	   			ren estimate estimate_no
	   			ren max95 max95_no 
	   			ren min95 min95_no
	   		save "${loc}${temp}temp_est_no.dta", replace

	   		use "${loc}${temp}temp_est.dta", clear
				g time = _n
	   			drop if time<=`=`time''
	   			drop time
	   			g time = _n
	   			keep if time<=`=`time''   		
	   			replace time = time + `=`time_min''
	   			keep estimate time max95 min95
	   			ren estimate estimate_yes
	   			ren max95 max95_yes 
	   			ren min95 min95_yes
	   		
	   			merge 1:1 time using "${loc}${temp}temp_est_no.dta"
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
    	 graph export  "${loc}${temp}trend2.pdf", as(pdf) replace
    	 erase "${loc}${temp}temp_est.dta"
    	 erase "${loc}${temp}temp_est_no.dta"
    restore
end


*** TEST FOR LEAKS

graph_trend2






