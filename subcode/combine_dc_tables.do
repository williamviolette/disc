* combine_dc_tables.do

set more off

global loc =  "/Volumes/GoogleDrive/My Drive/disc_data/"

* dates change : kentucky , connecticut , michigan , nebraska , new hampshire , new york , ohio , rhode island
* temperatures don't seem to really change 

foreach year in 2004 2005 2006 2007 2008 2009 2011 2012 2013 2014 2015 2016 2018  {
	if `year'==2004 {
		use "${loc}input/dc_`year'.dta", clear
	}
	else {
		append using "${loc}input/dc_`year'.dta"
	}
}

format temp_t %30s
format date_t %30s
format state %10s

order state year
sort state year

save "${loc}input/dc_total.dta", replace




