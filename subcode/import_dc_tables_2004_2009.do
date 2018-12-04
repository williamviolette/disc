
set more off

global run_local = 1

if ${run_local} == 1 {
	cd "/Volumes/GoogleDrive/My Drive/utility_health/"
}


foreach year in 2004 2005 2006 2007 2008 2009 {

import delimited using "data/raw/dc_policy/dc_table_`year'.txt", delimiter(tab) clear

drop v2

g S=0 // gets 2 for virginia
replace S=1 if regexm(v1,"Alabama")==1 
replace S=1 if regexm(v1,"Alaska")==1
replace S=1 if regexm(v1,"Arizona")==1
replace S=1 if regexm(v1,"Arkansas")==1
replace S=1 if regexm(v1,"California")==1
replace S=1 if regexm(v1,"Colorado")==1
replace S=1 if regexm(v1,"Connecticut")==1
replace S=1 if regexm(v1,"Delaware")==1
replace S=1 if regexm(v1,"Florida")==1
replace S=1 if regexm(v1,"Georgia")==1
replace S=1 if regexm(v1,"Hawaii")==1
replace S=1 if regexm(v1,"Idaho")==1
replace S=1 if regexm(v1,"Illinois")==1
replace S=1 if regexm(v1,"Indiana")==1
replace S=1 if regexm(v1,"Iowa")==1
replace S=1 if regexm(v1,"Kansas")==1
replace S=1 if regexm(v1,"Kentucky")==1
replace S=1 if regexm(v1,"Louisiana")==1
replace S=1 if regexm(v1,"Maine")==1
replace S=1 if regexm(v1,"Maryland")==1
replace S=1 if regexm(v1,"Massachusetts")==1
replace S=1 if regexm(v1,"Michigan")==1
replace S=1 if regexm(v1,"Minnesota")==1
replace S=1 if regexm(v1,"Mississippi")==1
replace S=1 if regexm(v1,"Missouri")==1
replace S=1 if regexm(v1,"Montana")==1
replace S=1 if regexm(v1,"Nebraska")==1
replace S=1 if regexm(v1,"Nevada")==1
replace S=1 if regexm(v1,"New Hampshire")==1
replace S=1 if regexm(v1,"New Jersey")==1
replace S=1 if regexm(v1,"New Mexico")==1
replace S=1 if regexm(v1,"New York")==1
replace S=1 if regexm(v1,"North Carolina")==1
replace S=1 if regexm(v1,"North Dakota")==1
replace S=1 if regexm(v1,"Ohio")==1
replace S=1 if regexm(v1,"Oklahoma")==1
replace S=1 if regexm(v1,"Oregon")==1
replace S=1 if regexm(v1,"Pennsylvania")==1
replace S=1 if regexm(v1,"Rhode Island")==1
replace S=1 if regexm(v1,"South Carolina")==1
replace S=1 if regexm(v1,"South Dakota")==1
replace S=1 if regexm(v1,"Tennessee")==1
replace S=1 if regexm(v1,"Texas")==1
replace S=1 if regexm(v1,"Utah")==1
replace S=1 if regexm(v1,"Vermont")==1
replace S=1 if regexm(v1,"West Virginia")==1
replace S=1 if regexm(v1,"Virginia")==1
replace S=1 if regexm(v1,"Washington")==1
replace S=1 if regexm(v1,"Wisconsin")==1
replace S=1 if regexm(v1,"Wyoming")==1
replace S=1 if regexm(v1,"District of Columbia")==1

g state = v1 if S==1
replace state=state[_n-1] if state==""
drop if state==""

g id=_n
sort state id
by state: g sn=_n
egen SN=max(sn), by(state)


*** TEMP THRESHOLD
g temp_id = v1=="yes" & sn==4
egen temp=max(temp_id), by(state)

g temp_t = v1 if regexm(v1,"<")==1 | regexm(v1,">")==1 | regexm(v1,"°")==1 | regexm(v1,"below")==1
	g sn_temp_t=sn if temp_t!=""  // get rid of last phrase if there is already a temp
	egen sn_temp_min=min(sn_temp_t), by(state)
	replace temp_t="" if sn_temp_t!=sn_temp_min

forvalues r=1/8 {
by state: replace temp_t=temp_t[_n-`r'] if temp_t==""
by state: replace temp_t=temp_t[_n+`r'] if temp_t==""
}

*** DATE THRESHOLD
g date_id = v1=="yes" & sn==2
egen date=max(date_id), by(state)

g date_t = v1 if regexm(v1,"/")==1 
	g sn_date_t=sn if date_t!=""  // get rid of last phrase if there is already a date
	egen sn_date_min=min(sn_date_t), by(state)
	replace date_t="" if sn_date_t!=sn_date_min

forvalues r=1/8 {
by state: replace date_t=date_t[_n-`r'] if date_t==""
by state: replace date_t=date_t[_n+`r'] if date_t==""
}

*** EXTRA
g extra=v1 if SN==sn
forvalues r=1/8 {
by state: replace extra=extra[_n-`r'] if extra==""
by state: replace extra=extra[_n+`r'] if extra==""
}

format temp_t %30s
format date_t %30s

keep state temp temp_t date date_t extra
duplicates drop state, force


*** extra fixes
replace temp_t = "< 32" if state=="Wisconsin" & temp==1

if `year' == 2009 | `year'==2008 {
	replace date_t = "10/20 - 4/15" if state=="Ohio"
}

replace temp_t = "<32° (daytime), <20° F (night) or >103° F" if state=="Oklahoma"

g year = `year'

save "data/input/dc_`year'.dta", replace

}
