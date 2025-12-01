*****************************************************************************************
* computes Rbar ("R-tilde") for net-migration based on empirical net-migration N(x,t)   *
* stores results in RbarMig2.dta, graph in RbarMig3a.gph, RbarMig3b.gph, RbarMig3c.gph  *
*****************************************************************************************

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

* change to numeric
foreach var of varlist V2-V203 {
 destring `var', replace
}

*drop values for years after 2023
drop if year > 2023

** restrict analysis to ages 15-40
* drop columns for men in ages 0-14
foreach var of varlist V2-V16 {
 drop `var'
* end loop V2-V16
}

* drop columns for men in ages 42-100 and women in ages 0-14 
foreach var of varlist V44-V117 {
 drop `var'
* end loop V63-V117
}

* drop columns for women in ages 42-100
foreach var of varlist V145-V203 {
 drop `var'
* end loop V164-V203
}

* add men and women
forvalues i = 15/41 {
local x =`i'
local y = `x'+2
local z = `x'+103
gen P`x' = V`y' + V`z'
* end loop i
}

*drop men and drop women
drop V*
save "M:\NICOK\Juha\Ri_results\niSim_`s'.dta", replace
* end loop s
}

* append data for 1 Jan 2003
**** set # simulations  ****
forvalues s = 1/1000 {	
use  "obs2003.dta", replace
foreach var of varlist P0-P14 {
 drop `var'
}

foreach var of varlist P42-P91 {
 drop `var'
}

append using "niSim_`s'.dta"

* time series
tsset year

*compute net migration N(x,t) in cohorts
forvalues i = 15/40 {
local x =`i'
local y = `x'+1
gen Ni`x' = - P`x' + F1.P`y'
* end loop i
}

* migration probabilities ni(x,t)
forvalues j = 15/40 {
local x =`j'
gen ni`x' = Ni`x'/P`x'

* end loop j
}

drop P* Ni*

save "niSim_`s'.dta", replace

*merge with observed migration data
merge 1:1 year using "M:\NICOK\Juha\Ri_results\obsMig.dta", keepusing(P* N*)
drop _merge


* empirical migration probabilities n(x,t)
forvalues j = 15/40 {
local x =`j'
gen n`x' = N`x'/P`x'

* end loop j
}

*compute log-likelihoods for n(x,t)
forvalues j = 15/40 {
local x =`j'
* scaled Rbar ("R-tilde"), P=1
* ll2n(x) gets missing value for negative n(x) 
gen ll2n`x' = -n`x' + (n`x')*ln(n`x')

* end loop j
}


*compute log-likelihoods for ni(x,t)
forvalues j = 15/40 {
local x =`j'
* scaled Rbar ("R-tilde"), P=1
* ll2ni(x) gets missing value for negative ni(x) 
gen ll2ni`x' = -ni`x' + (n`x')*ln(ni`x')

* end loop j
}

*compute log-likelihood ratio Ri(x,t)
forvalues j = 15/40 {
local x =`j'
gen Ri`x' = 2*(ll2n`x' - ll2ni`x')

* end loop j
}

keep year Ri*  
save "Rmig_`s'.dta", replace
erase "niSim_`s'.dta"
* end loop s
}

*** set nr simulations
forvalues s = 1/1000 {	
	forvalues k = 2003/2022 {
	use "Rmig_`s'.dta", replace
	keep if year == `k'
	save "RmigS`s'Y`k'.dta", replace
	}
erase "Rmig_`s'.dta"
* end loop s
}

forvalues k = 2003/2022 {
	use "RmigS1Y`k'.dta", replace

**** set # simulations  ****
	forvalues s = 2/1000 {	
	append using "RmigS`s'Y`k'.dta"
	erase "RmigS`s'Y`k'.dta"
* end loop s
	}
save "RmigY`k'.dta", replace
erase "RmigS1Y`k'.dta"
}

use "RmigY2003.dta", replace
forvalues j = 15/40 {
	sum Ri`j'
	return list
	gen RbarMigA`j' = r(mean)
}
keep RbarMig*
drop if _n > 1
gen year = 2003
save "RbarMig.dta", replace
erase "RmigY2003.dta"

forvalues k = 2004/2022 {
	use "RmigY`k'.dta", replace
	forvalues j = 15/40 {
		sum Ri`j'
		return list
		gen RbarMigA`j' = r(mean)
** may check also r(p90) and r(p10) for 90th and 10th percentiles **
	}
	keep RbarMig*
	drop if _n > 1
	gen year = `k'
	append using "RbarMig.dta"
	save "RbarMig.dta", replace
	erase "RmigY`k'.dta"
}
sort year

rename RbarMigA* age*

*merge with observed migration data
merge 1:1 year using "M:\NICOK\Juha\Ri_results\obsMig.dta", keepusing(N*)
drop _merge

gen N20_30 = (N20 + N21 + N22 + N23 + N24 + N25 + N26 + N27 + N28 + N29 + N30)
save "RbarMig2.dta", replace

*end quietly
}

twoway (line age20 age25 age30 year) (line N20_30 year, yaxis(2))
graph save "Graph" "M:\NICOK\Juha\Ri_results\RbarMig3a.gph", replace
graph export "M:\NICOK\Juha\Ri_results\R3abarMig.pdf", as(pdf) name("Graph")

twoway (line age20 year) (line N20_30 year, yaxis(2))
graph save "Graph" "M:\NICOK\Juha\Ri_results\RbarMig3b.gph", replace
graph export "M:\NICOK\Juha\Ri_results\R3bbarMig.pdf", as(pdf) name("Graph")

twoway (line age30 year) (line N20_30 year, yaxis(2))
graph save "Graph" "M:\NICOK\Juha\Ri_results\RbarMig3c.gph", replace
graph export "M:\NICOK\Juha\Ri_results\R3cbarMig.pdf", as(pdf) name("Graph")

graph combine RbarMig3b.gph RbarMig3c.gph, cols(2)
graph save "Graph" "M:\NICOK\Juha\Ri_results\Combined.gph", replace
graph export "M:\NICOK\Juha\Ri_results\Combined.pdf", as(pdf) name("Combined")
