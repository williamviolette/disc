* cold_prep.do


* global loc =  "/Volumes/GoogleDrive/My Drive/disc_data/"


global fullimport = 0
global fullappend = 0


global stations = "${loc}raw/spatial/ghcnd-stations.txt"

local import ""
local import "`import' str ID            1-11   "
local import "`import' LATITUDE         13-20   "
local import "`import' LONGITUDE        22-30   "
local import "`import' str STATE        39-40   "

infix `import' using "${stations}", clear


keep if substr(ID,1,2)=="US"

g OGC_FID = _n

save "${loc}input/stations.dta", replace

odbc exec("DROP TABLE IF EXISTS stations ;"), dsn("disc")
odbc insert, table("stations") create
odbc exec("CREATE INDEX stations_id ON stations (ID);"), dsn("disc")






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

infix `import' using "/Users/williamviolette/Downloads/ghcnd_hcn/ghcnd_hcn/`file'", clear
	keep if YEAR>=1980 & YEAR<=1988
	keep if ELEMENT == "TMIN"
	keep ID YEAR MONTH ELEMENT VALUE*
	reshape long VALUE, i(ID YEAR MONTH ELEMENT) j(DAY)
drop ELEMENT
drop if VALUE==-9999
save "/Users/williamviolette/Downloads/ghcnd_hcn/temp/`file'_80.dta", replace
}

}


if $fullappend == 1 {
global z = 1
local files : dir "/Users/williamviolette/Downloads/ghcnd_hcn/ghcnd_hcn/" files "*.dly"

foreach file in `files' {
	if $z == 1 {
		use "/Users/williamviolette/Downloads/ghcnd_hcn/temp/`file'_80.dta", clear
		global z = $z + 1
	}
	else {
		append using "/Users/williamviolette/Downloads/ghcnd_hcn/temp/`file'_80.dta"
	}
	erase "/Users/williamviolette/Downloads/ghcnd_hcn/temp/`file'_80.dta"
}

save "/Users/williamviolette/Downloads/ghcnd_hcn/temp/tmin_full_80.dta", replace

}


if $unique_stations == 1 {

use "/Users/williamviolette/Downloads/ghcnd_hcn/temp/tmin_full_80.dta", clear

sort ID
bys ID: g NN=_N
keep if NN>3000

keep ID 
duplicates drop ID, force

odbc exec("DROP TABLE IF EXISTS stations_80 ;"), dsn("disc")
odbc insert, table("stations_80") create
odbc exec("CREATE INDEX stations_80_id ON stations_80 (ID);"), dsn("disc")

save "${loc}temp/stations_80.dta", replace

}



