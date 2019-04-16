

* this program graphs mortality against temperature
* for states with policies versus ones without (using daily measures)
* from 1980 to 1988


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





g start_date = mdy(month_start,day_start,year)




cap drop T  
g T = date - start_date 
replace T = . if T<-30 | T>30

cap drop H
g H = 1 if tmin_min<20
replace H = 2 if tmin_min>20 & tmin_min<30
replace H = 3 if tmin_min>30



global coef ""

	sum H, detail
	
	forvalues r=`=r(min)'/`=r(max)' {
		sum T, detail
		forvalues z=`=r(min)'/`=r(max)' {
		if `z'<0 {
			local z1 "`=abs(`z')'"
			cap drop HH_`r'_MIN_`z1'
			g HH_`r'_MIN_`z1' = H==`r' & T==`z'
			global coef " ${coef} HH_`r'_MIN_`z1' "
		}
		else {
			cap drop HH_`r'_PLU_`z' 
			g HH_`r'_PLU_`z' = H==`r' & T==`z'
			global coef " ${coef} HH_`r'_PLU_`z' "
		}
		}
		omit coef HH_`r'_MIN_1
	}
	
	

cap prog drop rgraph
prog define rgraph
	preserve

	if `1'==1 {
	  areg `4' $coef `5' `6' , absorb(stateoc) cluster(stateoc) r
	  sum `4' if e(sample)==1, detail
	  global  mean = "`=string(round(`=r(mean)',.001),"%12.2fc")'"

	  parmest, fast
	  replace parm=substr(parm,3,.) if estimate==0
	  g T = substr(parm,10,.)
	  g H = substr(parm,4,1)
	  keep if  substr(parm,1,2)=="HH"

	  destring T H, replace force
	  replace T = T*-1 if substr(parm,6,1)=="M"
	  sort H T 
	  g Mmean = "${mean}"
	save "${loc}temp/`2'_clustlevel.dta", replace
	}

	use "${loc}temp/`2'_clustlevel.dta", clear
	global mean = "`=Mmean[1]'"
	  tw ///
	    (rcap max95 min95 T if H==1, lc(gs7) lw(medthick) ) ||  ///
	    (connected estimate T if H==1, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(gs0) lp(none) lw(medium)) || ///
	     (rcap max95 min95 T if H==2, lc(blue) lw(medthick) ) || ///
	    (connected estimate T if H==2, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(blue) lp(none) lw(medium)) || ///
	     (rcap max95 min95 T if H==3, lc(red) lw(medthick) ) || ///
	    connected estimate T if H==3, ms(o) msiz(small) mlc(gs0) mfc(gs0) lc(red) lp(none) lw(medium) ///
	    note("Mean : ${mean} ", size(medium)) ///
	    legend(order(2 "less than 20" 4 "20 to 30" 6 "over 30") ///
	    symx(6) col(3) size(medium)) title("`3'") xtitle("time to policy", size(large)) ylabel(-10(5)10, labsize(large))
	  graph export "${loc}temp/`2'_clustlevel.pdf", as(pdf) replace

	restore
end

rgraph 1 time_graph "time to graph by temp" deaths " i.day if A==2"








