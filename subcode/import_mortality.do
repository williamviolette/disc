* import_mortality.do


global mort = "/Users/williamviolette/Downloads/mort/"
global sc = "/Users/williamviolette/disc/disc_code/subcode/"

*global mort_clean_temp = 0
*if $mort_clean_temp == 1 {


global yr = 1989

use "${mort}mort${yr}.dta", clear








/*

global yr = 2004
use "${mort}mort${yr}.dta", clear

drop if weekday==9

keep stateoc ucod metro ager12 educ89 educ racer5 year month weekday

destring metro, replace force
g city = metro == 1
* ager12 : 12 cat
* race5 : racer5
* educ : 9 cat

g edu = 0 if educ89 <=8 | educ<=1
replace edu = 1 if (educ89>8 & educ89<=12) | (educ>=2 & educ<=3 )
replace edu = 2 if (educ89>=13 & educ89<=14) | (educ>=4 & educ<=6)
replace edu = 3 if (educ89>=15 & educ89<=17) | (educ>=7 & educ<=8)
replace edu = 9 if (educ89==99 | educ==9)

g ic = substr(ucod,1,1)

g i10 = 0

global cv = 1
foreach v in `c(ALPHA)' {
replace i10=$cv if ic=="`v'"
global cv = $cv + 1
}

g state=stateoc

do "${sc}state_fix.do"


keep state i10 city ager12 edu racer5 city year month weekday

bys  state i10 city ager12 edu racer5 city year month weekday: g deaths=_N
bys  state i10 city ager12 edu racer5 city year month weekday: g dn=_n
keep if dn==1
drop dn

save "${mort}mort${yr}_temp.dta", replace


