

use "${loc}input/dc_total.dta", clear
format state %20s
duplicates drop state, force
keep state

g prior_notice=""
g special_notice=""
g rec_deposit=""
g installment=""
g rec_charge=""
g winter=""
g winter_date=""
g authority=""
g temp_low=""
g date_low_pre=""
g date_low_post=""
g temp_high=""
g date_high_pre=""
g date_high_post=""


cap prog drop write
prog def write
local ifc "if state=="`1'""

replace prior_notice="`2'"  `ifc'
replace special_notice="`3'"  `ifc'
replace rec_deposit="`4'"  `ifc'
replace installment="`5'"  `ifc'
replace rec_charge="`6'"  `ifc'
replace winter="`7'"  `ifc'
replace winter_date="`8'"  `ifc'
replace authority="`9'"  `ifc'

replace temp_low="`10'"  `ifc'
replace date_low_pre="`11'"  `ifc'
replace date_low_post="`12'"  `ifc'

replace temp_high="`13'"  `ifc'
replace date_high_pre="`14'"  `ifc'
replace date_high_post="`15'"  `ifc'
end


write "District of Columbia" "15 Days" "Third party (2 attempts, first class writing)" "100 dollars or estimated cost for 60-day period" "Yes" "15" "Forecasted to be below 32 for next 24 hrs" "5/79" "PSC" 32


write Alabama "10 Days" "Third party" "2 months bill" "Yes" "3-15" "Extreme weather" "80-81" "PSC"
write Alaska "One written" "Third party" "2 months bill" "Yes" "12-50" "No" "" ""
write Arizona "5 Days" "Third party" "2 months bill" "Yes" "Yes" "Weather" "3/2/82" "Statute"
write Arkansas "5 Days" "Third party" "2 months bill" "Yes" "Depends on reason" "Weather" "4/21/81" "PSC" 32 "11/1" "3/31" 95 "4/1" "10/31"
write California "15 Days" "Third party" "Varies" "Yes" "2.5-5" "No" "" ""
write Colorado "10 Days" "Third party" "2 months bill" "Yes" "15" "Health Reasons" "4/29/80" "PUC"
write Connecticut "13 Days" "Third party" "No" "Yes" "Varies" "Hardship" "10/7/80"  "PSC" "." "11/1" "4/15"
write Delaware "15 Days" "Mail and 2 calls in winter" "Only two dcs in last 12 hrs" "Yes" "15" "Yes" "10/30/79" "PSC"
write Florida "5 Days" "Third party" "2 months bill" "Yes" "Up to utility" "No" 
write Georgia "5 Days" "Utilities have special notice procedures" "2 months bill" "Yes" "25" "Weather forcasted to below (little different for gas)" "1/80" "PSC" 32 "11/15" "3/15"
write Hawaii "7 Days" "Report ot PUC 5 days before terminating" "2 months bill" "Yes" "10" "No" 
write Idaho "1 Days" "Third party (personal in winter)" "1/6 year bill" "Yes" "Varies (8-104)" "Date but not for minors elderly or infirm households" "12/1/80"  "PUC" "." "12/1" "2/28"
write Illinois "8 Days" "Third Party" "No" "Yes" "No" "Forecasts for following 24 hours" "1/6/79" "ICC" 32
write Indiana "14 Days" "Third Party" "1/3 annual billing" "Yes" "Varies" "Eligible for state assistance" "9/1/83" "Statute" "." "12/1" "3/15"
write Iowa "12 Days" "Third Party" "No" "Yes" "Varies" "Eligible for state winter assistance" "1/6/83" "CC" "." "11/1" "4/1"
*** nothing for kansas
write Kentucky "10 Days" "No" "No" "Yes" "Varies" "Not if customer pays 1/3 and agrees to repayment" "1982" "PSC" "." "11/1" "3/31"
write Louisiana "5 Days" "No" "2 months bill" "case-by-case" "Varies" "Health or able to pay installments" "11/3/80" "PSC"
write Maine "14 Days" "10 Days to tenants" "No" "Yes" "Varies" "Agency approval in winter" "12/1/82" "PSC" "." "12/1" "4/15"
write Maryland "14 Days" "Third party" "No" "Yes" "Varies" "Affadavit that no health risks to PSC" "10/12/83" "PSC" "." "12/1" "3/31"
write Massachusetts "3 Days" "Third party" "No" "Yes" "5-15" "Need approval for health and no poverty" "9/81" "Statute" "." "11/15" "3/15"
write Michigan "3 Days" "Third party" "Under 150" "Yes" "6-60" "Weather for qualified customers" "11/80" "PSC" "." "12/1" "3/31"
write Minnesota "10 Days" "Welfare agency notified if during winter" "2 months" "Yes" "5-20" "Dates" "1980" "Statute" "." "10/15" "4/15"
write Mississippi "5 Days" "Up to utility" "No" "Yes" "Varies" "Varies"
write Missouri "6 Days" "Third party" "2 months" "Varies" "Varies" "Only customers who do not make good-faithed effort between dates" "11/1/77" "PSC" "." "11/15" "3/31"
write Montana "20 Days" "Third party" "No" "Yes" "Varies (10-30)" "None without approval" "7/1/80" "Statute" "." "11/1" "4/1"
*** nothing for nebraska
write Nevada "10 Days" "Yes" "No" "Yes" "Varies (5-17.50)" "No"
write "New Hampshire" "14 Days" "Contact adult or leave sealed not with instructions" "2 months" "Depends" "Varies (10-30)" "None under 175 for non-heating and 300 for heating" "1980" "PUC"
write "New Jersey" "7 Days" "Third Party" "Yes" "Yes" "Varies" "Weather, Dates for welfare or public assistance" "11/24/82" "BPU" "." "12/1" "3/15"
write "New Mexico" "15 Days" "Third Party" "1.5 months" "Yes" "Varies" "No"
write "New York" "15 Days" "Third party" "No" "Yes" "Varies (5-10)" "Health concerns special notice" "10/19/81" "Statute" "." "11/1" "4/15"
write "North Carolina" "10 Days" "Third party" "Maybe" "Yes" "Varies" "Elterly or handicapped who qualify for low-income energy assistance" "11/80" "Statute" "." "11/1" "3/31"
write "North Dakota" "10 Days" "Third Party" "1.5 months" "Yes" "Varies" "No"
write Ohio "14 Days" "Third party" "less than 6 months" "Yes" "Varies" "Special moratorium 12/1/82 3/31/83" "10/6/82" "Statute" "." "weird, look again"
write Oklahoma "10 Days" "Third party" "Maybe" "Yes" "Varies" "Special notice" "11/7/80" "CC" "." "11/15" "4/15"
write Pennsylvania "10 Days" "Third party" "No" "Yes" "Varies" "Hazardous safety condition" "1980" "PUC"
write "Rhode Island" "10 Days" "No" "No" "Yes" "Varies" "Source of heat must be over 175 dollars" "1978" "PUC" "." "11/20" "4/1"
write "South Carolina" "10 Days" "Third party, medical cert, deffered payment" "2 months" "Yes" "Varies (5-15)" "Medical certicicate" "1970" "Statute" "." "12/1" "3/31"
write "South Dakota" "10 Days" "Notice to guarantor" "2 months" "No" "Varies" "Additional notice" "1976" "Statute" "." "11/1" "3/31"
write "Tennessee" "5 Days" "No" "2 months" "Yes" "Varies (5-15)" "No"
write Texas "7 Days" "Notice in English and Spanish" "2 months" "Yes" "Varies" "Health, statement of physician" "10/1/81" "PUC"
write Utah "10 Days" "Personal contact, third party notice, pamphlet" "2 months" "Yes" "Varies (5-25)" "PUC approval of afffidavit" "1/83" "PUC" "." "11/1" "4/30"
write Vermont "14 Days" "Oral notification" "Varies" "Yes" "Varies" "Special notice procedures" "12/81" "PSB" "." "12/1" "3/31"
write Virginia "10 Days" "No" "2 months" "Yes" "Varies" "Avoid extreme weather" "1977" "PCC"

write Washington "8 Days" "Yes" "No" "Yes" "Varies (5-40)" "No"

write "West Virginia" "" "" "2 months" "Yes" "Varies (5-8)" "No termination with min payment" "12/22/83" "PSC"

write Wisconsin "8 Days" "Notice to county welfare" "2 months" "Yes" "Varies (8-53)" "No disconnect if winter emergency" "11/24/78" "Statute"

write Wyoming "7 Days" "Third party" "1.5 months" "Yes" "At cost" "Utility needs to contact directly" "1979" "PSC" "." "11/1" "4/1"





ren state statename

merge 1:1 statename using "${loc}input/fips_state.dta"
** no DC merge
drop _merge
ren statename state

destring fipsst, replace force


save "${loc}temp/input_82_temp.dta", replace



















