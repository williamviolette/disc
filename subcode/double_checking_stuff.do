set more off
set matsize 10000


global discfile = "../../"
global temp = "output/"


use "${loc}temp/full_data_test.dta", clear


egen mt=mean(MIN_tmin_min), by(MONTH)
egen md=mean(deaths), by(MONTH)
bys MONTH: g mn=_n



scatter mt MONTH if mn==1 || scatter md MONTH if mn==1, yaxis(2)

* TEMP AND DEATHS SEEM TO LINE UP

g TR = round(MEAN_tmin_mean,1)

egen dtr=mean(deaths), by(TR)
bys TR: g trn=_n


scatter dtr TR if trn==1


