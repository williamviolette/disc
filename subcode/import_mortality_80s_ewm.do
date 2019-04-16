* import_mortality.do


global mort = "/Users/williamviolette/Downloads/mort/"


global mort_clean_temp = 1
global mort_age_temp = 1


if $mort_clean_temp == 1 {


*global yr = 1980

forvalues r=1980/1988 {
global yr = `r'

* global yr = 1980
use "${mort}mort${yr}.dta", clear

keep stateoc countyoc monthdth daydth racer3 ager12 stateoc ucr72 metro

replace countyoc=substr(countyoc,3,3)

merge m:1 stateoc countyoc using "${loc}input/nchs2fips_county1990.dta"
keep if _merge==3
drop _merge

g ewm =  ucr72 == 90 |   ///  				 /* septicimia */
			ucr72 == 510 |   ///  				 /* pneumonia */
			( ucr72 >=360 & ucr72<=390 ) |  ///  /* heart issues */
			( ucr72 >=430 & ucr72<=470 ) |  ///  /* cerebrovascular diseases */
			( ucr72 >=430 & ucr72<=470 )         /* tuburculosis */
			
g year = $yr
ren monthdth month
ren daydth day
destring fipsst fipsco month day ager12 racer3, replace force
g city = metro=="1"

global varset="fipsst fipsco year month day city ager12 racer3 ewm"
keep $varset
order $varset

bys  ${varset}: g deaths=_N
bys  ${varset}: g dn=_n
keep if dn==1
drop dn

save "${loc}temp/mort${yr}_temp_ewm.dta", replace

}

}



if $mort_age_temp == 1 {

*global yr=1980
forvalues r=1980/1988 {
global yr = `r'
use "${loc}temp/mort${yr}_temp_ewm.dta", clear

g A=0
replace A =2 if ager12>=10 & ager12<=11
replace A =1 if ager12<=2

global varset="fipsst fipsco year month day A ewm"
keep $varset deaths
order $varset deaths

ren deaths deaths1
egen deaths = sum(deaths1), by( $varset )
bys  ${varset}: g dn=_n
keep if dn==1
drop dn deaths1

save "${loc}temp/mort${yr}_age_temp_ewm.dta", replace
}


forvalues r=1980/1988 {
global yr = `r'
if `r' == 1980 {
use "${loc}temp/mort${yr}_age_temp_ewm.dta", clear
}
else {
append using "${loc}temp/mort${yr}_age_temp_ewm.dta"
}
erase "${loc}temp/mort${yr}_age_temp_ewm.dta"
}

save  "${loc}temp/mort_age_ewm.dta", replace


}


