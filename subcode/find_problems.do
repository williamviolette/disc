

use "/Users/williamviolette/Downloads/ghcnd_hcn/temp/id_state.dta", clear

merge 1:1 ID using "${loc}input/stations.dta"
