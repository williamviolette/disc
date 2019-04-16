* generate_station_link.do


 *  input_id is county
 *  target_id is station

clear
*odbc load, exec(" SELECT A.target_id, A.distance, B.geoid10 FROM distance_station_county AS A JOIN tl_2010_us_county10 AS B ON A.input_id = B.OGC_FID; ")  dsn("disc")

odbc load, exec(" SELECT * FROM int_stations_county; ")  dsn("disc")

	g ID1 = substr(ID,1,3)
	g ID2 = substr(ID,6,.)
	destring ID2, replace force

duplicates tag ID1 ID2, g(D)

drop if D>0
drop D

save "${loc}input/int_stations_county.dta", replace




clear
odbc load, exec("  SELECT C.ID, B.geoid10, A.distance FROM distance_station_county_1 AS A JOIN tl_2010_us_county10 AS B ON A.input_id = B.OGC_FID JOIN stations AS C ON C.OGC_FID = A.target_id; ")  dsn("disc")

	g ID1 = substr(ID,1,3)
	g ID2 = substr(ID,6,.)
	destring ID2, replace force

save "${loc}input/distance_station_county_1.dta", replace


clear
odbc load, exec("  SELECT C.ID, B.geoid10, A.distance FROM distance_station_county_5 AS A JOIN tl_2010_us_county10 AS B ON A.input_id = B.OGC_FID JOIN stations AS C ON C.OGC_FID = A.target_id; ")  dsn("disc")

	g ID1 = substr(ID,1,3)
	g ID2 = substr(ID,6,.)
	destring ID2, replace force

save "${loc}input/distance_station_county_5.dta", replace



use "${loc}input/distance_station_county_1.dta", clear

sort ID

joinby ID using "/Users/williamviolette/Downloads/ghcnd_hcn/temp/tmin_full_80.dta"

sort geoid10 YEAR MONTH DAY

by geoid10: g NN=_N

keep if NN<=3280

keep geoid10

duplicates drop geoid10, force

save "${loc}temp/counties_that_need_interpolation.dta", replace



use "${loc}temp/counties_that_need_interpolation.dta", replace

merge 1:m geoid10 using "${loc}input/distance_station_county_5.dta"
keep if _merge==3
keep geoid10 ID

sort ID geoid10

joinby ID using "/Users/williamviolette/Downloads/ghcnd_hcn/temp/tmin_full_80.dta"

egen m_value = mean(VALUE), by(geoid10 YEAR MONTH DAY)

drop VALUE
ren m_value VALUE

keep geoid10 YEAR MONTH DAY VALUE

duplicates drop geoid10 YEAR MONTH DAY, force

g date = myd
sort geoid10 YEAR MONTH DAY

g date=mdy(MONTH,DAY,YEAR)
drop MONTH DAY YEAR

save "${loc}temp/temp_station_5.dta", replace




use "${loc}input/distance_station_county_1.dta", clear

sort ID

joinby ID using "/Users/williamviolette/Downloads/ghcnd_hcn/temp/tmin_full_80.dta"

merge m:1 geoid10 using "${loc}temp/counties_that_need_interpolation.dta"
drop if _merge==3
drop _merge

g date=mdy(MONTH,DAY,YEAR)
drop MONTH DAY YEAR

keep geoid10 date VALUE
g s5=0

append using "${loc}temp/temp_station_5.dta"
replace s5=1 if s5==.

destring geoid10, replace force

save "${loc}input/full_temp.dta", replace

erase "${loc}temp/temp_station_5.dta"

