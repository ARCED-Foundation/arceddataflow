                                                                                                                                                                                                      /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          03_prep.do                                                 ║
║    PROJECT:        						                                    ║
║    PURPOSE:        Prepare data                                               ║
║-------------------------------------------------------------------------------║
║    AUTHOR:                                                                    ║
║    CONTACT:                                                                   ║
║-------------------------------------------------------------------------------║
║    CREATED:                                                                   ║
║    MODIFIED:                                                                  ║
╚═══════════════════════════════════════════════════════════════════════════════╝


                                                                                                                                                                                                       */
                                                                                                                                                                                                                                                                                                                                                                                         	
	                                                                                                                                                                                                                                                                                                                                                                                         	
                                                                                                                                                                                                                                                                                                                                                                                         																																																																																																	qui {
**# Initiate deidentified dataset
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	n di as input _n "Initiating datataset..."
	cap confirm file "${deidentified}"
	if !_rc n u "${deidentified}", clear
	if  _rc n u "${rawdatadta}", clear
	
	n di as input "Data preparation initiated.."
	
**# generate date variabls
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	gen startdate 	= dofc(starttime)
	gen enddate		= dofc(endtime)
	gen subdate 	= dofc(submissiondate)
	
	format %td startdate enddate subdate
	
	n di as result _n "Date variables generated"

**# check date variables
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	loc datelist "${starttime} ${endtime} submissiondate"
	qui {
		foreach var of loc datelist {
			count if mi(`var')
			if `r(N)' > 0 {
				n di as err "Variable `var' has `r(N)' missing values"
				exit 416
			}
		}
	}	
	
	n di as result _n "Date variables checked"
		
**# destring numeric variables and tostring enumid
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	destring _all, replace

	tostring ${enumid}, replace
	replace ${enumid} = subinstr(${enumid}, " ", "", .)
	
**# drop unwanted variables
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	#d;
	/* drop deviceid 
		 subscriberid 
		 simid 
		 devicephonenum 
		 username */
		 ;
	#d cr
	
	n di as result _n "Dropped unnecessary variables"
	
**# Manual corrections
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	qui if ${data_correction} {
		n di as input _n "Data corrections processing..."
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/assets/Correction_log_template.xlsx" "${correction_log}", replace
		
		tempfile c_maindata 
		save 	`c_maindata'
		
		* Corrections
		import excel "${correctionsheet}", first clear sh(corrections)
		drop if mi(key)
		
		if _N>0  {
			count if mi(remarks)
			
			if `=r(N)'>0 n {
				gen __serialcorr = _n 
				levelsof __serialcorr if mi(remarks), clean loc(remmissing)
				drop __serialcorr
				di as err _n "Remarks missing in corrections sheet. Rows: `remmissing'."
				u `c_maindata', clear
				exit 459
			}
			
			duplicates tag key variable, gen(__dup)
			count if __dup>0 
			if r(N) > 0 {
				n di as err _n "There are duplicate entries in the correction sheet"
				n list key variable correction if __dup>0, sepby(key variable) divider fast abbreviate(15)
				u `c_maindata', clear
				exit 459
			}
			

			loc corrcount = _N
			matrix CORR = J(`corrcount', 1, .)
			
			forval var =1/`corrcount' {	
				loc _`var'_name 	= "`=variable[`var']'"
				loc `var'_cmd_num 	= "qui replace `=variable[`var']'=" + "`=correction[`var']'" + `" if key==""' + key[`var'] + `"""'
				loc `var'_cmd_str 	= "qui replace `=variable[`var']'=" + `"""'+ "`=correction[`var']'" + `"""' + `" if key==""' + key[`var'] + `"""'
				loc _`var'_value 	= "`=correction[`var']'"
				loc _`var'_key 		= "`=key[`var']'"
			}

			
			tempfile allcorrections
			save 	`allcorrections'
			
			* Apply corrections		
			u `c_maindata', clear

			loc i=0
			forval var =1/`corrcount' {
				
				cap conf var `_`var'_name'
				if _rc {
					n di "`_`var'_name' not found"
					exit 111
				}
				else {
					if inlist("`: type `_`var'_name''", "byte", "double", "float", "int", "long") {
						count if key == "`_`var'_key'" & `_`var'_name' != `_`var'_value'
						if `=r(N)' > 0 {
							n ``var'_cmd_num'
							mat CORR [`var', 1] = 1
							loc ++i						
						}
						if `=r(N)' == 0 mat CORR [`var', 1] = 0
					}
					
					if !inlist("`: type `_`var'_name''", "byte", "double", "float", "int", "long") {
						count if key == "`_`var'_key'" & `_`var'_name' != "`_`var'_value'" 
						if `=r(N)' > 0 {
							``var'_cmd_str'
							mat CORR [`var', 1] = 1
							loc ++i
						}
						if `=r(N)' == 0 mat CORR [`var', 1] = 0
					}		
				}		
			}
			
			preserve 
				u `allcorrections', clear
				svmat CORR, names(col)
				mat drop CORR
				g Result = cond(c1==1, "Value successfully changed", "Value could not be changed")
				drop c1 __dup

				
				export excel using "${correction_log}", ///
								sh(Corrections)			///
								sheetmodify 			///
								cell(A2) 				///
								keepcellfmt
			restore 
			
			n di as result "`i' correction(s) made successfully" _n
			sleep 5000
		}
		
		if _N==0  u 	`c_maindata', clear	
		save 	`c_maindata', replace

		* Drop list
		import excel "${correctionsheet}", first clear sh(droplist)
		drop if mi(key)
		
		count if mi(reason)
		if `=r(N)'>0 n {
			gen __serialreas = _n 
			levelsof __serialreas if mi(reason), clean loc(resmissing)
			drop __serialreas
			di as err "Reasons missing in droplist sheet. Rows: `resmissing'."
			exit 459
		}
		loc totaldrops = `=_N'
		
		tempfile droplist 
		save	`droplist'
		
		
		* Apply drops 
		if `totaldrops'>0 {
			duplicates tag key, gen(__dup)
			count if __dup>0 

			if r(N) > 0 {
				n di as err _n  "There are duplicate keys in the droplist sheet" 
				n list key if __dup>0, sepby(key) divider fast abbreviate(15) 
				u `c_maindata', clear
				exit 459
			}
			
			merge m:1 key using `droplist', gen(merge_drop) keepusing(key reason) noreport
			
			levelsof key if merge_drop==2, clean loc(_keynotfound) s(,)
			
			preserve 
				keep if merge_drop!=1
				g result = cond(merge_drop==3, "Successfully dropped", "Drop unsucessfull")
				loc dropped = _N
				export excel 	key reason	result			///
								using "${correction_log}", 	///
								sh(Dropped)					///
								sheetmodify 				///
								cell(A2) 					///
								keepcellfmt
			restore 
			
			drop reason
			keep if merge_drop==1
			
			if `dropped'>0 n di as result "`dropped' submissions dropped successfully" _n
			drop merge_drop
			u `c_maindata', clear
			
			if `=wordcount("`_keynotfound'")'>0 {
				n di as err "These keys do not exist in data: " "`_keynotfound'" _n
				sleep 2000
			}		
		}	
	}
	

	

**# Drop observations with date before survey start date
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	count if startdate < date("${surveystart}", "DMY")
	loc beforetotal = `=r(N)'
	
	if `beforetotal'>0  {
		tostring startdate, gen(__startdate_str) format("%td") force
		levelsof __startdate_str if startdate < date("${surveystart}", "DMY"), clean loc(beforedate) sep(", ")
		drop __startdate_str
		if ${warning} cap window stopbox rusure "There are `beforetotal' submissions before ${surveystart}." "Dates: `beforedate'" " " "Are you sure you want to drop them?"		
	
		if !_rc | !${warning} {
			drop if startdate < date("${surveystart}", "DMY")
			n di as result "There are `beforetotal' submissions before ${surveystart}." 
			n di as result "Dates: `beforedate' are dropped." _n
		}	
	}
	
	
	n di as result _n "Dropped test data"
	
**# Recode extended missing values
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	qui {
		if "${dk}" 		!= "" loc dk_rec 	= "(`= trim(itrim(subinstr("${dk}", ",", " ", .)))' = .d)" 
		if "${ref}"		!= "" loc ref_rec 	= "(`= trim(itrim(subinstr("${ref}", ",", " ", .)))' = .r) "
		if "${skip}"	!= "" loc skip_rec 	= "(`= trim(itrim(subinstr("${skip}", ",", " ", .)))' = .s) "
		if "${NA}"		!= "" loc NA_rec 	= "(`= trim(itrim(subinstr("${NA}", ",", " ", .)))' = .n) "
		
		
		ds, has(type numeric)
		if 	!mi("${dk}") 		| !mi("${ref}") ///
			| !mi("${skip}")	| !mi("${NA}")	///
			recode `r(varlist)' ///
			`dk_rec' `ref_rec' 	///
			`skip_rec' `NA_rec'	
		
		n di as result "Recoding extended missing values completed." _n
	}

**# Remove single quotes from labels
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	foreach var of varlist _all {
		loc newvar = subinstr(`"`:var lab `var''"', `"`=char(34)'"', "", .)
		loc newvar = subinstr("`newvar'", "`=char(39)'", "", .)
		lab var `var' "`newvar'"
	}	

**# Additional preparation
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	
	
	
	
**# Saving prepped data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	
	qui {
		compress
		label data "Deidentified & cleaned dataset. Updated by `=c(username)' on `=c(current_date)' `=c(current_time)'."
		save "${cleandata}", replace 	

		n di as result "Cleaned data saved here ${cleandata}" _n
	}

	
	
n di as result _col(15) "----------------------"
n di as result _col(15) "|  Data cleaning done |"
n di as result _col(15) "----------------------"
	
	
**# End
}
