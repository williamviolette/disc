* import_mortality.do


global mort = "/Users/williamviolette/Downloads/mort/"
global sc = "/Users/williamviolette/disc/disc_code/subcode/"

global mort_clean_temp = 0
global mort_age_temp = 1

if $mort_clean_temp == 1 {

*global yr = 1980

forvalues r=1980/1988 {
global yr = `r'
use "${mort}mort${yr}.dta", clear

keep stateoc monthdth daydth racer3 ager12 stateoc ucod metro

g ic = substr(ucod,1,1)

g year = $yr
ren monthdth month
ren daydth day
destring stateoc month day ager12 racer3, replace force
g city = metro=="1"

global varset="stateoc year month day city ager12 racer3 ic"
keep $varset
order $varset

bys  ${varset}: g deaths=_N
bys  ${varset}: g dn=_n
keep if dn==1
drop dn

save "${mort}mort${yr}_temp.dta", replace

}

}


if $mort_age_temp == 1 {

*global yr=1980

forvalues r=1980/1988 {
global yr = `r'
use "${mort}mort${yr}_temp.dta", clear
drop ic

g A=0
replace A =2 if ager12>=10 & ager12<=11
replace A =1 if ager12<=2

global varset="stateoc year month day A"
keep $varset deaths
order $varset deaths

ren deaths deaths1
egen deaths = sum(deaths1), by( $varset )
bys  ${varset}: g dn=_n
keep if dn==1
drop dn deaths1

save "${mort}mort${yr}_age_temp.dta", replace
}


forvalues r=1980/1988 {
global yr = `r'
if `r' == 1980 {
use "${mort}mort${yr}_age_temp.dta", clear
}
else {
append using "${mort}mort${yr}_age_temp.dta"
}
erase "${mort}mort${yr}_age_temp.dta"
}


save  "${mort}mort_age.dta", replace


}


