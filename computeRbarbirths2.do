**************************************************************
* computes Rbar for births based on empirical births B(t)    *
* stores results in Rbarbirths.dta, graph in R2barbirths.gph *
**************************************************************
 
cd "M:\NICOK\Juha\Ri_results"
quietly {

**** set # simulations  ****
forvalues s = 1/1000 {	
import delimited "M:\NICOK\Juha\PEPNorway2003\P`s'_d1.S1", delimiter(space, collapse) varnames(nonames) case(upper) clear	

* drop column names caused by spaces in PEP files' column names, and define forecast year (1 Jan)
drop in 1
ren V1 year
replace year = _n + 2003

* drop excessive columns caused by spaces in names
foreach var of varlist V204-V406 {
 drop `var'
}

* drop for years > 2023
drop if year > 2023

* change to numeric
foreach var of varlist V2-V203 {
destring `var', replace
}

* drop columns for men in ages 1-100 
foreach var of varlist V3-V102 {
 drop `var'
}

* drop columns for women in ages 1-14
foreach var of varlist V104-V117 {
 drop `var'
}

* drop columns for women in ages 50-100
foreach var of varlist V153-V203 {
 drop `var'
}

* add men and women age 0
gen P0 = V2 + V103

* add women ages 15-49
gen oldsum = V118
foreach var of varlist V119-V152 {
gen newsum = oldsum + `var'
drop oldsum
rename newsum oldsum
}
rename oldsum Vcb

*drop women 15-49
keep year P0 Vcb
save "M:\NICOK\Juha\Ri_results\biSim_`s'.dta", replace
}

* append data for 1 Jan 2003
cd "M:\NICOK\Juha\Ri_results"
**** set # simulations  ****
forvalues s = 1/1000 {	
use  "obs2003.dta", replace
keep year P0 Vcb
append using "biSim_`s'.dta"
rename P0 P0i
rename Vcb Vcbi
save "biSim_`s'.dta", replace

*merge with observed data
merge 1:1 year using "M:\NICOK\Juha\Ri_results\observations.dta", keepusing(B Vcb)
drop _merge

* birth rates for simulations bi(t)
gen bi = P0i/Vcbi

* observed birth rates b(t)
gen b = B/Vcb

*compute log-likelihoods for birth rates bi(t)
* unscaled R
* gen llbi = -Vcb*bi + P0*ln(Vcb*bi)
* scaled R, Vcb = 1
gen llbi2 = -bi + b*ln(bi)

*compute log-likelihoods for observed birth rates b(t)
* gen llb = -Vcb*b + P0*ln(Vcb*b)
gen llb2 = -b + b*ln(b)

*compute log-likelihood ratio Ri(x,t)
* gen Ri = 2*(llb - llbi)
gen Ri2 = 2*(llb2 - llbi2)

** compute Rbar for years 2003 - 2022
* rename Ri R`s'
rename Ri2 R2`s'
save "Rbirths_`s'.dta", replace
erase "biSim_`s'.dta"
use "Rbirths_`s'.dta", clear
* rename R`s' oldsum
rename R2`s' oldsum2
save "Rbarbirths.dta", replace
}

**** set # simulations  ****
forvalues s = 2/1000 {	
use "Rbarbirths.dta", clear
merge 1:1 year using  "Rbirths_`s'.dta"
drop _merge
* gen newsum = oldsum + R`s'
gen newsum2 = oldsum2 + R2`s'
* drop oldsum
drop oldsum2
* rename newsum oldsum
rename newsum2 oldsum2
drop R*
save "Rbarbirths.dta", replace
erase "Rbirths_`s'.dta"
}
erase "Rbirths_1.dta" 
*** end quietly
}

use "Rbarbirths.dta", clear
**NB divide by # simulations **
* gen Rbarbirths = oldsum/1000
gen R2barbirths = oldsum2/1000
* drop oldsum
drop  oldsum2
* Rbar is unscaled, R2bar is scaled with Vcb = 1
* keep Rbarbirths R2barbirths year
keep R2barbirths year
save "Rbarbirths.dta", replace
* twoway (line Rbarbirths year)
* graph save "Graph" "M:\NICOK\Juha\Ri_results\Rbarbirths.gph", replace
twoway (line R2barbirths year)
graph save "Graph" "M:\NICOK\Juha\Ri_results\R2barbirths.gph", replace

