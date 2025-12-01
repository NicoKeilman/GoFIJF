*****************************************************
* computes Rbar based on empirical deaths D(x,t)    *
* stores result in RbarMort.dta, graph in Rbar.gph*
*****************************************************

cd "M:\NICOK\Juha\Ri_results"
 quietly {

**** set # simulations  ****
forvalues s = 1/1000 {	
import delimited "M:\NICOK\Juha\PEPNorway2003\P`s'_d1.S1", delimiter(space, collapse) varnames(nonames) case(upper) clear	

* drop column names caused by spaces in PEP files' column names, and define forecast year (1 Jan)
drop in 1
ren V1 year
replace year = _n + 2003
drop if year > 2023

* drop excessive columns caused by spaces in names
foreach var of varlist V204-V406 {
 drop `var'
}

* change to numeric
foreach var of varlist V2-V203 {
 destring `var', replace
}

* drop columns for men in ages 0-59 
foreach var of varlist V2-V61 {
 drop `var'
}

* drop columns for men in ages 92-100 and women in ages 0-59 
foreach var of varlist V94-V162 {
 drop `var'
}

* drop columns for women in ages 92-100
foreach var of varlist V195-V203 {
 drop `var'
}

* add men and women
forvalues i = 60/91 {
local x =`i'
local y = `x'+2
local z = `x'+103
gen P`x' = V`y' + V`z'
}

*drop men and drop women
drop V*

save "M:\NICOK\Juha\Ri_results\diSim_`s'.dta", replace
* end loop s
}

* append data for 1 Jan 2003
**** set # simulations  ****
forvalues s = 1/1000 {	
use  "obs2003.dta", replace
foreach var of varlist P0-P59 {
 drop `var'
}
append using "diSim_`s'.dta"

* time series
tsset year

*compute deaths Di(x,t) in cohorts
forvalues i = 60/90 {
local x =`i'
local y = `x'+1
gen Di`x' = P`x' - F1.P`y'
}

* death probabilities di(x,t)
forvalues j = 60/90 {
local x =`j'
gen di`x' = Di`x'/P`x'
}

drop P* D*

save "diSim_`s'.dta", replace

*merge with observed data
merge 1:1 year using "M:\NICOK\Juha\Ri_results\observations.dta"
* note: age = age on 1 January here - as opposed to age (for deaths) in file bookkeeping.xls
foreach var of varlist P0-P59 {
 drop `var'
}
drop _merge

tsset year
*compute death probabilities for observations
forvalues j = 60(5)90 {
local x =`j'
* deaths D(x,t), probabilities d(x,t)
gen d`x' = D`x'/P`x'

*compute log-likelihoods for d(x,t) and di(x,t)
* scaled Rbar, P=1; ll2 denotes scaled log-likelihood
gen ll2d`x' = -d`x' + (d`x')*ln(d`x')
gen ll2di`x' = -di`x' + (d`x')*ln(di`x')
*compute log-likelihood ratio Ri(x,t)
gen Ri`x' = 2*(ll2d`x' - ll2di`x')
}

save "R_`s'.dta", replace
erase "diSim_`s'.dta"

** compute Rbar for ages 60(5)90 and years 2003 - 2022
keep year Ri60 Ri65 Ri70 Ri75 Ri80 Ri85 Ri90
forvalues j = 60(5)90 {
	rename Ri`j' R`s'_`j'
	save "R_`s'_`j'.dta", replace
	}
	erase "R_`s'.dta"
* end loop s
}

forvalues j = 60(5)90 {
	use "R_1_`j'.dta", clear
	rename R1_`j' oldsum
	save "RbarAge`j'.dta", replace
	erase "R_1_`j'.dta"
}

**** set # simulations  ****
forvalues s = 2/1000 {	
	forvalues j = 60(5)90 {
	use "RbarAge`j'.dta", clear
	merge 1:1 year using  "R_`s'_`j'.dta"
	drop _merge
	gen newsum = oldsum + R`s'_`j'
	drop oldsum
	rename newsum oldsum
	drop R*
	save "RbarAge`j'.dta", replace
	erase "R_`s'_`j'.dta"
	}
* end loop s 
}
* end quietly
}


use "RbarAge60.dta", clear
**NB divide by # simulations **
gen RbarAge60 = oldsum/1000
drop oldsum

forvalues j = 65(5)90 {
	merge 1:1 year using "RbarAge`j'.dta"
**NB divide by # simulations **
	gen RbarAge`j' = oldsum/1000
	drop oldsum
	drop _merge
}

*** remove extreme value in x=60, t=2022, caused by immigration from Ukraine
*replace RbarAge60 = . in 20
rename RbarAge* Age*
save "RbarMort.dta", replace
twoway (line Age70 Age75 Age80 Age85 Age90 year)
graph save "Graph" "M:\NICOK\Juha\Ri_results\Rbar.gph", replace
