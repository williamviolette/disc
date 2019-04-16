

use "${loc}input/nchs2fips_county1990.dta", clear

keep statename fipsst
duplicates drop statename, force

save "${loc}input/fips_state.dta", replace
