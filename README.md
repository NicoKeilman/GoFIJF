# GoFIJF
PEP files and Stata code to reproduce results in International Journal of Forecasting paper entitled "Assessing the accuracy of probabilistic
population forecasts" by Juha Alho and Nico Keilman.

Stata code files for computing results and drawing graphs: 

- computeRbarMig2.do : Stata code for computing Rbar and Rtilde for net-migration

- computeRbarbirths2.do: Stata code for computing Rbar and Rtilde for births

- computeRbarDeaths.do:  Stata code for computing Rbar and Rtilde for deaths


PEPNorway2003.7z is a zip file containing 1000 input files from PEP, one for each sample: 

- Px_d1.S1 with x = 1(1)1000.

- Columns M0, M1, M2, ... F0, F1, F2, ... represent numbers of men (women) aged 0, 1, 2, ...

- Rows 1, 2, 3 represent calendar years 2004, 2005, 2006 etc.

obs2003.dta is a Stata file with data for 2003


