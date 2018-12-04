* combine_dc_tables.do

set more off

global run_local = 1

if ${run_local} == 1 {
	cd "/Volumes/GoogleDrive/My Drive/utility_health/"
}

* dates change : kentucky , connecticut , michigan , nebraska , new hampshire , new york , ohio , rhode island
* temperatures don't seem to really change 

foreach year in 2004 2005 2006 2007 2008 2009 2011 2012 2013 2014 2015 2016 2018  {
	if `year'==2004 {
		use "data/input/dc_`year'.dta", clear
	}
	else {
		append using "data/input/dc_`year'.dta"
	}
}

format temp_t %30s
format date_t %30s
format state %10s

order state year
sort state year

save "data/input/dc_total.dta", replace




