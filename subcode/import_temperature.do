* import_temp.do

cd "/Users/williamviolette/Downloads/ghcnd_hcn/"

global fullimport = 0
global tminfull   = 0

if $fullimport == 1 {

local files : dir "/Users/williamviolette/Downloads/ghcnd_hcn/ghcnd_hcn/" files "*.dly"

local import ""
local import "`import' str ID            1-11 "
local import "`import' YEAR         12-15   "
local import "`import' MONTH        16-17   "
local import "`import' str ELEMENT      18-21   "

global z = 0
forvalues r = 22(8)262 { 
global z = $z + 1
local import "`import' VALUE${z}       `=`r''-`=`r'+4'   "
local import "`import' str MFLAG${z}       `=`r'+5'-`=`r'+5'    "
local import "`import' str QFLAG${z}       `=`r'+6'-`=`r'+6'    "
local import "`import' str SFLAG${z}        `=`r'+7'-`=`r'+7'    "
}

foreach file in `files' {

infix `import' using "ghcnd_hcn/`file'", clear
	keep if YEAR>1990
	keep if ELEMENT == "TMIN"
	keep ID YEAR MONTH ELEMENT VALUE*
	reshape long VALUE, i(ID YEAR MONTH ELEMENT) j(DAY)
drop ELEMENT
drop if VALUE==-9999
save "temp/`file'.dta", replace
}

}


if $tminfull == 1 {
global z = 1
local files : dir "/Users/williamviolette/Downloads/ghcnd_hcn/ghcnd_hcn/" files "*.dly"

foreach file in `files' {
	if $z == 1 {
		use "temp/`file'.dta", clear
		global z = $z + 1
	}
	else {
		append using "temp/`file'.dta"
	}
}
keep if YEAR>2000
save "temp/tmin_full.dta", replace

}


* 

infix str STATE 1-2 str NAME 4-25 using "ghcnd-states.txt", clear

replace NAME = lower(NAME)
replace NAME = proper(NAME)

foreach v in GU MP MH NB NL BC NT NS PE PR PI PW QC SK UM VI YT FM MB { 
	drop if STATE=="`v'"
}

save "state_key.dta", replace


local import ""
local import "`import' str ID            1-11 "
local import "`import' str STATE 39-40  "

infix `import' using "ghcnd-stations.txt", clear
drop if STATE==""
save "temp/id_state.dta", replace


use "temp/tmin_full.dta", clear

	merge m:1 ID using "temp/id_state.dta"
	keep if _merge==3
	drop _merge

	merge m:1 STATE using "state_key.dta"
	keep if _merge==3
	drop _merge

drop STATE ID
ren NAME STATE

egen tmin_med  = median(VALUE),  by(STATE YEAR MONTH DAY)
egen tmin_mean = mean(VALUE), by(STATE YEAR MONTH DAY)
egen tmin_min  = min(VALUE),  by(STATE YEAR MONTH DAY)

drop VALUE
duplicates drop STATE YEAR MONTH DAY, force

foreach var of varlist tmin_* {
	replace `var' = (`var'/10)*(9/5) + 32
}

save "/Volumes/GoogleDrive/My Drive/utility_health/data/input/min_temp.dta", replace





