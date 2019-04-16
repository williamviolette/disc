

global state_prep = 0


if $state_prep == 1 {

use "${loc}input/full_ewm.dta", clear

replace month_start_policy=1 if month_start_policy==.
replace day_start_policy=1 if day_start_policy==.
g policy_date = mdy(month_start_policy,day_start_policy,year_start_policy)
replace policy_date = 3653  if policy_date==.

g cold = f < 32

foreach var of varlist deaths* {
	g `var'_cold=`var'*cold
}
foreach var of varlist deaths* {
	egen `var'_sum = sum(`var'), by(fipsst date)
	replace `var'=`var'_sum
	drop `var'_sum
}
drop f fipsco cold
duplicates drop fipsst date, force

save "${loc}input/states_ewm.dta", replace

}




use "${loc}input/states_ewm.dta", clear

g year = yofd(date)
g month =  month(date)
g day = day(date)

	cap prog drop cut
	prog def cut
		sum `1', detail
		egen cut_temp = cut(`1'), at(`=r(min)'(`2')`=r(max)')
		drop `1'
		ren cut_temp `1'
	end


	cap prog drop dm
	prog def dm
		cap drop m_temp
		egen m_temp = mean(`1'), by(`2' `3' `4')
		replace `1'=`1'-m_temp
		drop m_temp
	end



cap prog drop splot
prog def splot

preserve 

	dm `2' date
	dm `2' fipsst month day
	dm `2' fipsst year

	`7'

	g start_date = mdy(month_`6',day_`6',year)

	g T=date-start_date

	cut T `5'
	keep if T>=`3' & T<=`4'

	g post_pol = (date>policy_date)

	egen o = mean(`2'), by(T post_pol)

	bys T post_pol: g t_n=_n

	scatter o T if t_n==1 & post_pol==1, color(edkblue)  || ///
	lpoly o T if t_n==1 & post_pol==1, color(edkblue)  ///
	legend(order(  1 "Pre Policy"  )) xtitle("Time to Event") ytitle("Deaths (demeaned)")  xlabel(${tl}(5)${tu})

	graph export "${fig}`1'.pdf", as(pdf) replace

restore 

end






cap prog drop splot_pre
prog def splot_pre

preserve 

	g post_pol = (date>policy_date)

	* dm `2' month day post_pol
	
	*dm `2' fipsst year month
	
	dm `2' fipsst year
	dm `2' date 

	*dm `2' post_pol
	

	egen min_post_pol=min(post_pol), by(fipsst)
	keep if min_post_pol==0

	`7'

	g start_date = mdy(month_`6',day_`6',year)

	g T=date-start_date

	cut T `5'
	keep if T>=`3' & T<=`4'

	egen o = mean(`2'), by(T post_pol)

	bys T post_pol: g t_n=_n

	global gtype = "lpoly"

	 twoway $gtype o T if t_n==1 & post_pol==0, color(sand) || $gtype o T if t_n==1 & post_pol==1, color(edkblue) ||  ///
	  scatter o T if t_n==1 & post_pol==0, color(sand) || scatter o T if t_n==1 & post_pol==1, color(edkblue)  ///
	 legend(order(  1 "Pre Policy" 2 "Post Policy" )) xtitle("Time to Event") ytitle("Deaths (demeaned)") 

	* scatter o T if t_n==1 & post_pol==1, color(edkblue)  || ///
	* lpoly o T if t_n==1 & post_pol==1, color(edkblue)  ///
	* legend(order(  1 "Pre Policy"  )) xtitle("Time to Event") ytitle("Deaths (demeaned)")  xlabel(${tl}(5)${tu})

	graph export "${fig}`1'.pdf", as(pdf) replace

restore 
end



global tl = -80
global tu =  80


splot_pre "te_deaths_old_ewm" "deaths_old_ewm" $tl $tu 5 "end"


splot_pre "te_deaths_old_ewm" "deaths_old_oth" $tl $tu 5 "end"



splot_pre "te_deaths_old_ewm" "deaths_all" $tl $tu 1 "end"




splot "te_deaths_old_ewm" "deaths_all" $tl $tu 1 "end"


splot "te_deaths_old_ewm" "deaths_young_oth" $tl $tu 1 "end"

splot "te_deaths_old_ewm" "deaths_old_ewm" $tl $tu 1 "end"


splot "te_deaths_old_ewm" "deaths_old_oth" $tl $tu 1 "end"



splot "te_deaths_old_ewm" "deaths_mid_oth" $tl $tu 4 "end"



splot "te_deaths_old_ewm" "deaths_old_ewm_cold" $tl $tu 4 "end"



splot "te_deaths_old_ewm" "deaths_ewm" $tl $tu 4 "end"






cap prog drop splot_cd
prog def splot_cd

preserve 

	dm `2' date
	dm `2' fipsst month day
	dm `2' fipsst year


	dm `2'_cold date
	dm `2'_cold fipsst month day
	dm `2'_cold fipsst year

	`6'

	g start_date = mdy(month_start,day_start,year)

	g T=date-start_date

	cut T `5'
	keep if T>=`3' & T<=`4'

	g post_pol = (date>policy_date)

	egen o = mean(`2'), by(T post_pol)
	egen o_cold = mean(`2'_cold), by(T post_pol)

	bys T post_pol: g t_n=_n

	g od = o_cold/o

	* scatter o T if t_n==1 & post_pol==0, color(sand) || scatter o T if t_n==1 & post_pol==1, color(edkblue)  ///
	* legend(order(  1 "Pre Policy" 2 "Post Policy" )) xtitle("Time to Event") ytitle("Deaths (demeaned)") 

	scatter od T if t_n==1 & post_pol==1, color(edkblue)  || ///
	lpoly od T if t_n==1 & post_pol==1, color(edkblue)  ///
	legend(order(  1 "Pre Policy"  )) xtitle("Time to Event") ytitle("Deaths (demeaned)") 

	graph export "${fig}`1'.pdf", as(pdf) replace

restore 

end



global tl = -20
global tu =  20


splot_cd "te_deaths_old_ewm" "deaths_ewm" $tl $tu 2






splot "te_deaths_old_ewm" "deaths_all" $tl $tu 4



splot "te_deaths_old_ewm" "deaths_old_ewm_cold" $tl $tu 2





splot "te_deaths_old_ewm" "deaths_all_cold" $tl $tu 1





splot "te_deaths_ewm" "deaths_ewm" $tl $tu 4


splot "te_deaths_ewm_cold" "deaths_ewm_cold" $tl $tu 4








splot "tgrad_deaths_all" "deaths_all" $c_l $c_u $step $tl $tu "keep if temp==32"





splot "tgrad_old_ewm" "deaths_old_ewm" $c_l $c_u $step $tl $tu




splot "tgrad_deaths_ewm" "deaths_ewm" $c_l $c_u $step $tl $tu





splot "tgrad_old_oth" "deaths_old_oth" $c_l $c_u $step $tl $tu

splot "tgrad_ewm" "deaths_ewm" $c_l $c_u $step $tl $tu

splot "tgrad_deaths_young_oth" "deaths_young_oth" $c_l $c_u $step $tl $tu
splot "tgrad_deaths_young_ewm" "deaths_young_ewm" $c_l $c_u $step $tl $tu

splot "tgrad_mid_oth" "deaths_mid_oth" $c_l $c_u $step $tl $tu
splot "tgrad_mid_ewm" "deaths_mid_ewm" $c_l $c_u $step $tl $tu




* global oc = "deaths92"








* global oc ="ewm"
*global oc = "deathstot"
* global oc = "deaths1"












/*




use "${loc}input/full_ewm.dta", clear

ren VALUE c

replace c = round((c/10)*(9/5) + 32,1)

*** temp graph

egen dt_mc=mean(deathstot), by(geoid10)
egen dt_date=mean(deathstot), by(date)
g dta = deathstot - dt_mc - dt_date

egen cta_mc=mean(c), by(geoid10)
egen cta_date=mean(c), by(date)

g cta = c - cta_mc - cta_date

replace cta=round(cta,1)

egen md=mean(dta), by(cta)

bys cta: g t_n=_n

twoway scatter md cta if t_n==1 & cta>-60 & cta<10








/*


sort stateoc date

g tr=round(tmin_mean,1) // running variable as temperature
g T=tr-32
g treat=temp==32 // treated states have 32 degree temperature threshold

g ld=log(deathstot+1)

global M = 15 // temperature window around freezing


g led=log(ewm+1)

	
g led2 = log(deaths92+1)

g dow = dow(date)

g start_date = mdy(month_start,day_start,year)

g end_date = mdy(month_end,day_end,year)





cap drop T  
g T = date - end_date 
replace T = . if T<-100 | T>100
sum T, detail
replace T=`=r(min)' if T==.

cap drop H
g H = 1 if tmin_min<25
replace H = 2 if tmin_min>20 & tmin_min<=32
replace H = 3 if tmin_min>32 


cap drop H
g H = 1 if tmin_min<=32
replace H = 2 if tmin_min>32


cap drop H
g H = 1
// cap drop H
// g H=1


global coef ""

global inc = 5

	sum H, detail
	
	forvalues r=`=r(min)'/`=r(max)' {
		sum T, detail
		forvalues z=`=`=r(min)'+${inc}'(${inc})`=r(max)' {
		if `z'<0 {
			local z1 "`=abs(`z')'"
			cap drop HH_`r'_MIN_`z1'
			g HH_`r'_MIN_`z1' = H==`r' & T>=`z'-${inc} & T<=`z'
			global coef " ${coef} HH_`r'_MIN_`z1' "
		}
		else {
			cap drop HH_`r'_PLU_`z' 
			g HH_`r'_PLU_`z' = H==`r' & T>=`z'-${inc} & T<=`z'
			global coef " ${coef} HH_`r'_PLU_`z' "
		}
		}
		*omit coef HH_`r'_MIN_1
	}
	


cap prog drop rgraph
prog define rgraph
	preserve

	if `1'==1 {
	  areg `4' $coef `5' , absorb(stateoc) cluster(stateoc) r /* state_oc_month_year */
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
	 
	 sum H, detail
	 global Hmax=`=r(max)'
	 global legend ""
	 global plots ""
	 
	 forvalues r=1/${Hmax} {
	 if `r'==1 {
		global color="gs7"
		disp "$color"
	 }
	 if `r'==2 {
		global color="blue"
	 }
	 if `r'==3 {
		global color="red"
	 }
	 if `r'==4 {
		global color="green"
	 }
	 	*global plots=" $plots rcap max95 min95 T if H==`r', lc(${color}) lw(med)  ||  connected estimate T if H==`r', ms(o) msiz(small) mlc(${color}) mfc(gs0) lc(gs0) lp(none) lw(medium) "
		global plots=" $plots connected estimate T if H==`r', ms(o) msiz(small) mlc(${color}) mfc(${color}) lc(${color}) lp(none) lw(medium) "
		disp "$plots"
		*global legend=" $legend `=2*`=r'' "group `=r'" "
		*disp "$legend"
		
	 if `r'!=${Hmax} {
		global plots=" $plots || " 
	 }
	 }
	  tw ///
		$plots ///
	    note("Mean : ${mean} ", size(medium)) ///
		legend(off) title("`3'") xtitle("time to policy", size(large)) ylabel(, labsize(large))
	  graph export "${loc}temp/`2'_clustlevel.pdf", as(pdf) replace

	restore
end



cap prog drop dm
prog define dm
	cap drop `1'_dm
	egen m_`1' = mean(`1'), by(`2' `3' `4')
	g `1'_dm = `1'-m_`1'
	drop m_`1'
end

dm led2 date 


cap drop tr2
g tr2 = tr*tr
cap drop tr3 
g tr3 = tr*tr*tr


rgraph 1 time_graph "time to graph by temp" led2_dm "  " "keep if T>=-80 & T<=80"





rgraph 1 time_graph "time to graph by temp" led2 "i.date " "keep if T>=-40 & T<=40"





rgraph 1 time_graph "time to graph by temp" led2 " i.day i.state_oc_month i.state_oc_year " "keep if T>=-40 & T<=40"








	
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


