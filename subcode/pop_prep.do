* pop_prep.do


set more off

* global loc =  "/Volumes/GoogleDrive/My Drive/disc_data/"


import excel "${loc}raw/population/pop_by_state.xlsx", firstrow clear

ren State STATE

*imputations

g d=pop2015-pop2010
replace d=d/5
foreach k in 11 12 13 14 {
	local j=`k'-1
	g pop20`k'=pop20`j'+d
}
g pop2016=pop2015+d
drop d

g d=pop2010-pop2000
replace d=d/10
foreach k in 1 2 3 4 5 6 7 8 9 {
	local j=`k'-1
	g pop200`k'=pop200`j'+d
}
drop d

drop pop1990

reshape long pop, i(STATE) j(YEAR)

save "${loc}input/state_pop.dta", replace
