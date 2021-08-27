
* With this do file we want to create the data to be used as an imput for the
* GGP Data Visualisation of full histories (partnerships and fertility).

cd "/Users/temery/Documents/GitHub/FullHistory/docs/"

set matsize 10000

foreach COUNTRY in /*belgium czech_republic france georgia germany italy lituania netherlands norway poland romania sweden uk us uruguay*/ kazakhstan moldova {

use HARMONIZED-HISTORIES_ALL_GGSaccess.dta, clear

gen CNTRY = "NA"
replace CNTRY = "belgium" if COUNTRY == 561
replace CNTRY = "czech_republic" if COUNTRY == 2031
replace CNTRY = "france" if COUNTRY == 2501
replace CNTRY = "georgia" if COUNTRY == 2681
replace CNTRY = "germany" if COUNTRY == 2761
replace CNTRY = "italy" if COUNTRY == 3801
replace CNTRY = "lithuania" if COUNTRY == 4401
replace CNTRY = "netherlands" if COUNTRY == 5282
replace CNTRY = "norway" if COUNTRY == 5781
replace CNTRY = "poland" if COUNTRY == 6162
replace CNTRY = "romania" if COUNTRY == 6421
replace CNTRY = "sweden" if COUNTRY == 7521
replace CNTRY = "uk" if COUNTRY == 8261
replace CNTRY = "us" if COUNTRY == 8402
replace CNTRY = "uruguay" if COUNTRY == 8581
replace CNTRY = "kazkahstan" if COUNTRY == 8601
replace CNTRY = "moldova" if COUNTRY == 4981

keep if CNTRY == "`COUNTRY'"

* We start by constructing sequences of events for each respondent. Codes for
* event will we structured in this way:

*		xN: where x is a marital status code and N is the number of children

* For example, s1 will correspond to a single respondent with 1 child, m3 will
* indicate that the respondent is married and has three children. We only 
* consider 0, 1, 2, 3 and 4+ children and the following marital statuses:

*		- single (s)
*		- cohabiting (c)
*		- married (m)

* We generate a group variable (which may be country group, cohort or anything else).
* In this case we use it to create teo different cohorts

generate group = .
replace group = 1 if (BORN_Y == 1950)
replace group = 2 if (BORN_Y == 1970)

* We extract a random sample of 250 units from each cohort.

local num_of_groups = 2
local sample_size = 250

sort group
by group: sample `sample_size', count

* We set the start of our histories at 15 and the end at 40

local start_month = 15*12
local end_month = 40*12


* We generate a variable for each of the first four children with the age
* of the respondent at the birth of the child in months. To that we remove
* the start month so that we don't have a very long initial period with the
* same status (i.e. childless).

local i = 1

recode KID_M* BORN_M UNION_Y* SEP_Y* MARR_Y* DIV_Y* (21 = 1) (22 = 4) (23 = 7) (24 = 10) (25 = 12)

gen birth_cmc = (BORN_Y - 1900)*12 + BORN_M

forval x = 1(1)4 {
	gen birth_cmc_ch`x' = ((KID_Y`x' - 1900)*12) + KID_M`x'
}

foreach var of varlist birth_cmc_ch1-birth_cmc_ch4 {

	local new_var_name = "age_birth_ch" + "`i'"
	generate `new_var_name' = `var' - birth_cmc - `start_month'
	local i = `i' +1
	
	}
	
	
* We now generate a variable for each possible event in the partnership history
* with the respondent's age at that event in months. The possible events are:

*		- started a partnership
*		- married with partner
* 		- ended a partnership
* 		- divorced from partner

forval x = 1(1)10 {
	gen st_cmc_par`x' = ((UNION_Y`x' - 1900)*12) + UNION_M`x'
	gen mar_cmc_par`x' = ((MARR_Y`x' - 1900)*12) + MARR_M`x'
	gen end_cmc_par`x' = ((SEP_Y`x' - 1900)*12) + SEP_M`x'
	gen div_cmc_par`x' = ((DIV_Y`x' - 1900)*12) + DIV_M`x'
}


local events st mar end div

foreach event of local events {

	local i = 1
	local first_var = "`event'" + "_cmc_par1"
	local last_var = "`event'" + "_cmc_par10"

	foreach var of varlist `first_var'-`last_var' {
		
		local new_var_name = "age_" + "`event'" + "_par" + "`i'"
		generate `new_var_name' = `var' - birth_cmc - `start_month'
		local i = `i' + 1
		
		}

	}
	
* We keep only useful variables

keep 	age_birth_ch1-age_birth_ch4 ///
		age_st_par1-age_st_par10 ///
		age_mar_par1-age_mar_par10 ///
		age_end_par1-age_end_par10 ///
		age_div_par1-age_div_par10 ///
		/*howend_par1-howend_par10*/ ///
		group
	
* Our histories will start at age 15 and end at age 40 and each state will represent
* a month in the respondent's life. We will thus have a total of 300 states.

* We start by creating a variable for each state:

forvalues i = 1(1)300 {
	
	local state_var = "state" + "`i'"
	generate `state_var' = "."
	
	}
	
* Now we proceed to actually create the sequences

local max_num_of_ch = 4
local max_num_of_par = 9
local sample_size = `sample_size' * `num_of_groups'

forvalues i = 1(1)`sample_size' {

	local marital_status = "s"
	local num_of_children = "0"
	local current_partner = 0
		
	* With this loop we fill the status at each state for
	* each respondent.
		
	forvalues state_num = 1(1)300 {

		* With this loop we change the number of children
		* the respondent has.
	
		forvalues num_ch = 1(1)`max_num_of_ch' {
		
			local child_var = "age_birth_ch" + "`num_ch'"
			
			if (`state_num' == `child_var'[`i']) {
				
				local num_of_children = "`num_ch'"
				
				}
			
			}
			
		* With this loop we change the marital status of 
		* the respondent.
			
		local next_partner = `current_partner' + 1
		
		local par_st_var = "age_st_par" + "`next_partner'"
		local par_end_var = "age_end_par" + "`next_partner'"
		local par_mar_var = "age_mar_par" + "`next_partner'"
		local par_div_var = "age_div_par" + "`next_partner'"
			
			
		if (`state_num'>=`par_st_var'[`i'] & `state_num'<`par_end_var'[`i']) {
			
			if (`state_num'>=`par_mar_var'[`i'] & `state_num'<`par_div_var'[`i']) {
					
				local marital_status = "m"
				local current_partner = `current_partner' +1
				
				}
			else if (`state_num'<`par_mar_var'[`i']) {
					
				local marital_status = "c"
				local current_partner = `current_partner' +1
					
				}
			else if (`state_num'>=`par_mar_var'[`i'] & `state_num'>=`par_div_var'[`i']) {
					
				local marital_status = "d"
					
				}
				
			}
		else if (`state_num'<`par_st_var'[`i'] & `par_st_var'[`i']!=. ) {
				
			local marital_status = "s"
				
			}
			
		local current_status = "`marital_status'" + "`num_of_children'"
		
		local state_var = "state" + "`state_num'"
		replace `state_var' = "`current_status'" in `i'
		
		}
		

	}
	
keep group state1-state300

forvalues i = 1(1)30 {

	local status_var = "status_var" + "`i'"
	local status_dur = "status_dur" + "`i'"
	
	generate `status_var' = "."
	replace `status_var'= "s0" if (`i'==1)
	generate `status_dur' = 0
		
	}

forvalues i = 1(1)`sample_size' {
	
	local status_num = 1
	local counter = 1
	
	forvalues state_num = 1(1)299 {
		
		local next_status_num = `status_num' +1
		local status_var = "status_var" + "`status_num'"
		local next_status_var = "status_var" + "`next_status_num'"
		local dur_var = "status_dur" + "`status_num'"
		local next_state_num = `state_num' +1
		local state_var = "state" + "`state_num'"
		local next_state_var = "state" + "`next_state_num'"
		
		if (`state_var'[`i']==`next_state_var'[`i']) {
		
			replace `dur_var' = `counter' in `i'
			local counter = `counter' + 1
			
			}
		else if (`state_var'[`i']!=`next_state_var'[`i']) {
			
			replace `dur_var' = `counter' in `i'
			replace `next_status_var' = `next_state_var'[`i'] in `i'
			local counter = 1
			local status_num = `status_num' +1
			
			}
	
		}
	
	}

keep group status_var1-status_dur30

ds, has(type string)
foreach x in `r(varlist)' {
	replace `x' = subinstr(`x', `"`=char(10)'"', "", .)
	replace `x' = subinstr(`x', ".", "", .)
}



forval x = 1(1)30 {
	rename status_dur`x' x_status_dur`x' 
	tostring x_status_dur`x', gen(status_dur`x') 
	drop x_status_dur`x'
	replace status_dur`x' = "" if status_dur`x' == "0"
	replace status_dur`x' = subinstr(status_dur`x', `"`=char(10)'"', "", .)
	replace status_dur`x' = subinstr(status_dur`x', ".", "", .)
}

export delimited using "`COUNTRY'_data.csv", novarnames replace

}













