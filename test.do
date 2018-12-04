






import delimited using "/Volumes/GoogleDrive/My Drive/utility_health/data/raw/health/wonder_2005_2016.txt", delimiter(tab) clear







import delimited using "/Users/williamviolette/Downloads/test_dc.txt", delimiter(tab) clear


import delimited using "/Users/williamviolette/Downloads/test_dc.txt", delimiter(tab) clear




keep if notes==""
drop notes


import delimited using "/Users/williamviolette/Downloads/test (1).txt", delimiter(tab) clear
keep if notes==""
drop notes

g mn = substr(monthcode,-2,2)

destring mn, replace force

egen did = group(year mn weekdaycode)


g key = .
replace key=did if weekday=="Thursday" & mn==12 & year==2005
replace key=did if weekday=="Friday" & mn==12 & year==2006
replace key=did if weekday=="Saturday" & mn==12 & year==2007
replace key=did if weekday=="Monday" & mn==12 & year==2008
replace key=did if weekday=="Tuesday" & mn==12 & year==2009
replace key=did if weekday=="Wednesday" & mn==12 & year==2010
replace key=did if weekday=="Thursday" & mn==12 & year==2011
replace key=did if weekday=="Saturday" & mn==12 & year==2012
replace key=did if weekday=="Sunday" & mn==12 & year==2013
replace key=did if weekday=="Monday" & mn==12 & year==2014
replace key=did if weekday=="Tuesday" & mn==12 & year==2015
replace key=did if weekday=="Thursday" & mn==12 & year==2016


*replace key=. if  state=="Indiana"



global M = 48


sort state did
g T = .
replace T = 0 if key!=.
forvalues v=1/$M {
by state: replace T=-`v' if key[_n+`v']!=.
}

forvalues v=1/$M {
by state: replace T=`v' if key[_n-`v']!=.
}

g T_alt = T
replace T=. if state!="Indiana"


cap program drop graph_trend
program define graph_trend
	local fe_var "`2'"
	local outcome "`1'"
	local T_high "${M}"
	local T_low "-${M}"
	preserve

		 replace T=. if T<`=`T_low'' | T>`=`T_high''
		 qui sum T, detail
		 local time_min `=r(min)'
		 local time `=r(max)-r(min)'
		 replace T=99 if T==.
		 qui tab T, g(TI_)
		 qui tab T_alt, g(T_alt_)
		 
		areg `outcome' TI_* T_alt_* i.year i.mn i.weekdaycode, absorb(`fe_var') cluster(`fe_var') r 
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
    	 graph export  "trend.pdf", as(pdf) replace
   	restore
end

*** TEST FOR LEAKS

graph_trend deaths state





*twoway scatter 



* indiana : December 1 (thursday) - March 15 (tuesday)

* maine : November 15-April 15

* mass : 	November 15-March 15

* michigan : November 1-March 31

* ohio : October 20-April 15

* penn : December 1-March 31
