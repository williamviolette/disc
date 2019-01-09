
** set location: ( also can run setlocation.do )
global loc =  "/Volumes/GoogleDrive/My Drive/disc_data/" // for will
* global loc =  "/Users/adrian/Google Drive/disc_data/" // for adrian

global code =  "/Users/williamviolette/disc/disc_code/" // for will
* global code =  "" // for adrian


** control panel 

global import_dc_1_   		= 0
global import_temp_2_ 		= 0
global import_mortality_3_ 	= 0
global analysis_4_a    		= 0
global analysis_4_b    		= 0


** (1) import disconnection policy tables
if $import_dc_1_ == 1 {

	do "${code}subcode/import_dc_tables_2004_2009.do"
	do "${code}subcode/import_dc_tables_2011_2016.do"
	do "${code}subcode/combine_dc_tables.do"

	* clean data to look at cold temperature mortality 
	do "${code}subcode/cold_prep.do"
	
	* 80s policies hand coded
	* from bottom table
	do "${code}subcode/import_table_1982_manual.do"
	* from each policy list
	do "${code}subcode/import_table_1982_manual_extra_dates.do"
}


** (2) import temperature 
if $import_temp_2_ == 1 {
		* weekdays, 2000-2018
	do "${code}subcode/import_temperature.do"
		* daily, 1980-1988
	do "${code}subcode/import_temperature_80s.do"
		* raw data are on my computer because its really big
}

** (3) import mortality (80s)
if $import_mortality_3_ == 1 {
	do "${code}subcode/import_mortality_80s.do"
	* key output: "${loc}temp/mort_age.dta"
		* counts state/day deaths in three age bins (variable: A)
			* A = 1 : 0 - 4 yrs
			* A = 2 : over 75 yrs
			* A = 0 : all else
		* raw data are on my pc since its really big
}


** (4a) quick test analysis
if $analysis_4_a == 1 {
	do "${code}subcode/analysis_test_prep.do"
		* prepares the data for the analysis
			* cleans the WONDER health data here,
				* which just has deaths from 1999 to 2016 
				* by (state year month weekday)

	do "${code}subcode/analysis_test.do"
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

** (4b) quick test analysis 1980-1988 !  
if $analysis_4_b == 1 {
	* makes our standard temperature gradient graphs 
	* but with daily measures instead of weekday temps; and for different age groups
	* the graph for old people (over 75) looks pretty dec!
	do "${code}subcode/analysis_test_temp_80s.do"

	* tries to do an event study using the day that the policy kicks in each fall 
	* focuses on Nov. 15th start date since they are the most common
	* doesn't seem like a lot going on here; but definitely more to do 
	* (other start dates, end dates, ages, etc.)
	do "${code}subcode/analysis_test_temp_80s.do"

}


*** Next steps 1/9/19 :
	* 1) start messing around with cause of death measures? (Its available in the mortality data!)
	* 2) other ideas with the preliminary specifications for 1980s?
	* 3) try to find some publicly available/downloadable data on utility disconnections (it looks like california has it, but it might be a little tricky to get)



*** Next steps 12/1/18 : 
	* 1) get daily data!
	* 2) expand time period a lot: go back to the 1980's (temp and mortality data definitely go that far)
	* 3) get more specific with policies for particular utilities
	* 4) look at demographic heterogeneity... of course...
	* 5) find other daily health data (hospital discharge data?)
	* 6) google trends, first stage stuff





