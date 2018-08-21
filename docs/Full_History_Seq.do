
* With this do file we want to create the data to be used as an imput for the
* GGP Data Visualisation of full histories (partnerships and fertility).

cd "C:\Users\temer\Desktop\Full History"

set matsize 10000

use combinedfile_BiCh.dta, clear

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

generate group = 0
replace group = 1 if (birth_y == 1950)
replace group = 2 if (birth_y == 1970)

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
		howend_par1-howend_par10 ///
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
local max_num_of_par = 10
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

export delimited using "/Users/Eugenio/Stata/NIDI_Stata/Data_Viz/FH_real.csv", novarnames replace
















