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



use "${loc}temp/mort_age.dta", clear

reshape wide deaths, i(stateoc year month day) j(A)
 
foreach v of varlist deaths* {
replace `v'=0 if `v'==.
}

egen deathstot = rowtotal(deaths*)


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

g ld=log(deathstot+1)

global M = 15 // temperature window around freezing



g start_date = mdy(month_start,day_start,year)




cap drop T  
g T = date - start_date 
*replace T = . if T<-20 | T>20

cap drop H
g H = 1 if tmin_min<25
replace H = 2 if tmin_min>20 & tmin_min<=32
replace H = 3 if tmin_min>32 & tmin_min<44

// cap drop H
// g H=1


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
	  areg `4' $coef `5' , absorb(stateoc) cluster(stateoc) r
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
	 `6'
	 
	  tw ///
	    (rcap max95 min95 T if H==1, lc(gs7) lw(medthick) ) ||  ///
	    (connected estimate T if H==1, ms(o) msiz(small) mlc(gs7) mfc(gs0) lc(gs0) lp(none) lw(medium)) || ///
	     (rcap max95 min95 T if H==2, lc(blue) lw(medthick) ) || ///
	    (connected estimate T if H==2, ms(o) msiz(small) mlc(blue) mfc(gs0) lc(blue) lp(none) lw(medium)) || ///
	     (rcap max95 min95 T if H==3, lc(red) lw(medthick) ) || ///
	    connected estimate T if H==3, ms(o) msiz(small) mlc(red) mfc(gs0) lc(red) lp(none) lw(medium) ///
	    note("Mean : ${mean} ", size(medium)) ///
	    legend(order(2 "less than 20" 4 "20 to 30" 6 "over 30") ///
	    symx(6) col(3) size(medium)) title("`3'") xtitle("time to policy", size(large)) ylabel(-10(5)10, labsize(large))
	  graph export "${loc}temp/`2'_clustlevel.pdf", as(pdf) replace

	restore
end


rgraph 1 time_graph "time to graph by temp" deathstot " i.day" "keep if T>=-20 & T<=20"






	
cap prog drop rgraph1
prog define rgraph1
	preserve

	if `1'==1 {
	  areg `4' $coef `5'  , absorb(stateoc) cluster(stateoc) r
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
	`6'
	global mean = "`=Mmean[1]'"
	  tw ///
	    (rcap max95 min95 T if H==1, lc(gs7) lw(medthick) ) ||  ///
	    connected estimate T if H==1, ms(o) msiz(small) mlc(gs7) mfc(gs0) lc(gs0) lp(none) lw(medium) ///
	    title("`3'") xtitle("time to policy", size(large)) ylabel(-10(5)10, labsize(large))
	  graph export "${loc}temp/`2'_clustlevel.pdf", as(pdf) replace

	restore
end


rgraph1 1 time_graph "time to graph by temp" deathstot   " i.day "   " keep if T>=-20 & T<=20 "



