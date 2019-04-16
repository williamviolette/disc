

use "${loc}input/dc_total.dta", clear
format state %20s
duplicates drop state, force
keep state

drop if regexm(state,"Several of")==1

g extra = ""
g temp_low=""
g date_low_pre=""
g date_low_post=""
g temp_high=""
g date_high_pre=""
g date_high_post=""


cap prog drop write
prog def write
local ifc "if state=="`1'""
replace extra="`2'"  `ifc'
replace temp_low="`3'"  `ifc'
replace date_low_pre="`4'"  `ifc'
replace date_low_post="`5'"  `ifc'
replace temp_high="`6'"  `ifc'
replace date_high_pre="`7'"  `ifc'
replace date_high_post="`8'"  `ifc'
end


* alabama
* alaska
write Arizona "ill; doc" "32"
write Arkansas "ill, old, dis; doc" "no low, 95" "11/1" "3/31"
write California "ill, old, dis"
write Colorado "ill; doc" 
** colorado reject uniform temp because of climate variation
write Connecticut "ill, old, dis, poor" "." "11/1" "4/15"
** require written verification of illnesses
write Delaware "ill; doc" "20; 50 miles"
** air tem within 50 miles is less than 20 degrees
write "District of Columbia" "med; doc" "32; 24 hr"
write Florida "no weekends"
write Georgia "ill; doc; pay plan"  "32; 8 am" "11/15" "3/15"
write Hawaii "old; dis"
write Idaho "ill, old, dis, child, pay plan" "." "12/1" "2/1"
** charitable interpretation, not in coldest parts of the year
write Illinois "1st pay plan" "." "12/1" "3/31"
write Indiana "poor" "." "12/1" "3/15"
write Iowa "poor; 6/29/84" "." "12/1" "4/1"
write Kansas "1st pay plan" "." "11/15" "3/31"
write Kentucky "1st pay plan; poor" "." "12/1" "3/31"
write Louisiana "health; poor"
write Maine "1st pay plan; poor" "." "12/1" "4/15"
write Maryland "1st pay plan; 10/1984"
write Massachusetts "ill, old, anyone in date range, doc; proposed" "." "11/15" "3/15"
write Michigan "1st pay plan; old" "." "12/1" "3/31" 
write Minnesota "1st pay plan; 9/84" "." "10/15" "4/15"
write Mississippi "no weekends"
write Missouri "1st pay plan; 1/84" "." "11/15" "3/31"
write Montana "gov" "32; 24 hr" "11/1" "4/1"
write Nebraska "no laws; unwritten norm"
** nevada has none
write "New Hampshire" "1st pay plan, old, big bill" "." "12/1" "4/1"
write "New Jersey" "1st pay plan; ill; doc" "." "12/1" "3/15"
write "New Mexico" "ill; doc"
write "New York" "hardship" "." "11/1" "4/15" 
** additional notice to all tenants
write "North Carolina" "poor, dis, 1st pay plan" "." "11/1" "3/31"
write "North Dakota" "notify gov; postpone if sick" "." "10/15" "4/15"
write "Ohio" "1st pay plan" "." "11/1" "4/15"
write "Oklahoma" "ill, old; 1st pay plan" "." "11/15" "4/15"
write Oregon "ill, doc"
write Pennsylvania "gov; strict" "." "12/1" "4/15"
write "Rhode Island" "old, dis, low bill" "." "11/1" "3/31"
write "South Carolina" "ill; doc" "."  "12/1" "3/31"
write "South Dakota" "only 30 days extra" "." "11/1" "3/31"
** not much for tennessee bc TVA
write Texas "ill, heat advisory"
write Utah "ill; doc"
write Vermont "1st pay plan" "." "12/1" "3/31"
write Virginia "severe weather; not law" "." "12/31" "3/1" 
write Washington "1st pay plan, poor" "." "11/15" "3/15"
write "West Virginia" "1st pay plan, ill" "." "12/1" "3/1"
write Wisconsin "no weekends; contact; 10/84"
write Wyoming "ill, old, 1st pay plan" "." "11/1" "4/30"


sort state
g stateoc = _n





ren state statename

merge 1:1 statename using "${loc}input/fips_state.dta"
** no DC merge
drop _merge
ren statename state

destring fipsst, replace force


save "${loc}temp/input_82_temp_dates.dta", replace



















