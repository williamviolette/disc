
*** HOLI WILLITO

** control panel 

global import_dc_1_   == 0
global import_temp_2_ == 0
global analysis_3_    == 0


** (1) import disconnection policy tables
if $import_dc_1_ == 1 {

	do "subcode/import_dc_tables_2004_2009.do"
	do "subcode/import_dc_tables_2011_2016.do"
	do "subcode/combine_dc_tables.do"

	* clean data to look at cold temperature mortality 
	do "subcode/cold_prep.do"
}


** (2) import temperature 
if $import_temp_2_ == 1 {
	do "subcode/import_temperature.do"
		* the data is on my computer because its really big
		* if we find that we want to keep cleaning it, then I can trim it and put it in the data folder
		* this file won't run on your PC because the data isn't there
}


** (3) quick test analysis
if $analysis_3_ == 1 {
	do "subcode/analysis_test_prep.do"
		* prepares the data for the analysis
			* cleans the WONDER health data here,
				* which just has deaths from 1999 to 2016 
				* by (state year month weekday)

	do "subcode/analysis_test.do"
		* does a quick preliminary analysis
		* temperature is measured as:
			* 1) min temp per day at a weather station
			* 2) min temp per day in a state
			* 3) min temp across weekdays in the same calendar month state
			* graphs the temperature mortality gradient (normalized where 0 is 32 degrees F)
				* 1) places with no threshold (black line)
				* 2) places with a 32 degree threshold (red line)
			* this graphs looks good : 
				* mortality is lower for no-disconnection states below 32 degrees
				* mortality converges above 32 degrees
		* next steps : leverage precise timing, policy changes, other temperature thresholds, etc.
}

*** Next steps : 
	* 1) get daily data!
	* 2) expand time period a lot: go back to the 1980's (temp and mortality data definitely go that far)
	* 3) get more specific with policies for particular utilities
	* 4) look at demographic heterogeneity... of course...
	* 5) find other daily health data (hospital discharge data?)





