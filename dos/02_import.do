                                                                                                                                                                                                      /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          02_import.do                                               ║
║    PROJECT:        Test Project                                               ║
║    PURPOSE:        Prepare data                                               ║
║-------------------------------------------------------------------------------║
║    AUTHOR:         [YOUR NAME], ARCED Foundation                              ║
║    CONTACT:        [YOUR.EMAIL]@arced.foundation                              ║
║-------------------------------------------------------------------------------║
║    CREATED:        03 December 2022                                           ║
║    MODIFIED:       28 April 2023                                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝

                                                                                                                                                                                                       */

qui {																																																	   
**# Encryption
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	n di as result "Data import initiated..."
	n arced_mount_file using "${container}", drive(X:)
	


**# Download data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	* Manual data download 
	qui if ${manualdownload} {
		cap confirm file "${sctodesktoploc}"
		
		if _rc {
			n di as err `"Check if {browse "https://docs.surveycto.com/05-exporting-and-publishing-data/02-exporting-data-with-surveycto-desktop/01.using-desktop.html":SurveyCTO Desktop} is downloaded and the 01_setup.do has the correct location."'
			exit 601
		}
		
		if ${warning}	window stopbox note "Now SurveyCTO Desktop will be open for data download." ///
						"Close the SurveyCTO Desktop application after downloading data to resume DataFlow."
		
		else n di as result "Close the SurveyCTO Desktop application after downloading data to resume DataFlow." _n
		
		! "${sctodesktoploc}"		
		
		n di as result "Data download done." _n
	}
	
	
	* SurveyCTO API data download	
	qui if ${sctodownload} {		
		n di as input "SurveyCTO username:" _r(suser)
		n di as input "SurveyCTO password:" _r(spass)
		sctoapi ${formid}, server(arced) username("${suser}") password("${spass}") ///
				date(1546344000) output("${sctodataloc}") media("${media}") 
		
		copy "${sctodataloc}/${formid}_WIDE.csv" "${rawdata}", replace
		n di as result "Data download done." _n
	}
	
	
**# Data labeling
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	qui {
		insheet using "${rawdata}", clear names
		
		tempfile 	rawdata
		save		`rawdata'
		
		* Label dataset using XLSForm
		qui odksplit, 	data(`rawdata') survey("${xlsform}") ///
						single multiple varlabel ///
						label(English) clear
		
		* Fix date variables 
			** Find date and datetime variables from the form
			preserve 
				import excel using "${xlsform}", sheet(survey) clear firstrow
				
				cap confirm var name 
				
				if _rc {
					loc name = "value"
				}
				
				else {
					loc name = "name"
				}
				
				replace type = trim(type)
				glevelsof `name' if inlist(type, "date"), loc(dates) clean
				glevelsof `name' if inlist(type, "datetime", "start", "end"), loc(datetimes) clean
			restore
		
			** Change the formats of date and datetime variables
			if !mi(`dates') {
				foreach date of loc dates {
					cap confirm var `date'
					
					if !_rc {
						tempvar 	`date'_t
						gen double 	``date'_t' = date(`date', "MDY"), after(`date')
						drop 		`date'
						gen 		`date' = ``date'_t', after(``date'_t')
						format 		`date' %td
						drop  		``date'_t'
					}			
				}
			}
		
			loc datetimes =  `"`datetimes' submissiondate"'

			foreach datetime of loc datetimes {
				cap confirm var `datetime'
				
				if !_rc {
					tempvar 	`datetime'_t
					gen double 	``datetime'_t' = Clock(`datetime', "MDYhms"), after(`datetime')
					drop 		`datetime'
					gen 		`datetime' = ``datetime'_t', after(``datetime'_t')
					format 		`datetime' %tC	
					drop  		``datetime'_t'
				}
			}
		
		
		* Fix media variables

			if !mi("${media}") {
				foreach var of global media {
					local delim = strpos(`var', " ")
					replace `var' = word(`var', `=wordcount(`var')')
				}
			}
			
			
			
		
		* Save dta file
		compress
		label data "Updated by `=c(username)' on `=c(current_date)' `=c(current_time)'. NOTE: This dataset contains PII."
		save `"`=regexr("${rawdata}", ".csv", ".dta")'"', replace 	
		
		n di as result "Data labelling done." _n
	}
	
	

	
**# PII cleaning
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	qui if ${pii_correction} {
		
		tempfile c_maindata 
		save 	`c_maindata'
		
		import excel "${pii_correction_file}", first clear
		drop if mi(key)
		tostring _all, replace

		if _N>0  {
			glevelsof variable, clean loc(variables)
			foreach var of loc variables {
				loc `var'_cmd_num = "replace `var'=" + correction + `" if key==""' + key + `"""'
				loc `var'_cmd_str = "replace `var'=" + `"""'+ correction + `"""' + `" if key==""' + key + `"""'
			}			
	
			
			u `c_maindata', clear
			
			loc i=0
			foreach var of loc variables {
				if _rc {
					n di "`var' not found"
					exit 111
				}
				else {
					if inlist("`: type `var''", "byte", "double", "float", "int", "long") ``var'_cmd_num'
					else ``var'_cmd_str'
					loc ++i
				}
				n di as result "`i' correction(s) made successfully" _n
			}
		}
		
		else u `c_maindata', clear	
	}
	
	
	
**# PII splitting
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	qui if !mi(`PIIs') {
		* Save the PII varibles separately
		preserve
			keep 	${PIIs} ${uid}
			label data "This dataset contains only PIIs."
			save `"`=regexr("${rawdata}", ".csv", "_PII.dta")'"', replace 	
		restore
		
		* Save the deidentified dataset
		preserve
			drop 	${PIIs}
			
			ds *name* *phone* *gps*
			loc varnamelist = "`r(varlist)'"
			
			ds, has(varl *name* *phone*)
			loc varlablist = "`r(varlist)'"
			
			
			if (!mi("`varnamelist'") | !mi("`varlablist'")) & ${warning} {
				cap window stopbox rusure "Are these variables PIIs:" " " "`=r(varlist)'" 
				
				if _rc == 1  { 
					label data "Deidentified dateset. Updated by `=c(username)' on `=c(current_date)' `=c(current_time)'."
					save "${deidentified}", replace 
				}
				
				if _rc == 0  { 
					n di as err "Add `=r(varlist)' in the PIIs global in 01_setup.do file" _n
					exit 459
				}
			}
		restore
		
		n di as result "PII Splitting done." _n
	}
	
	
	
**# Dismount
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	veracrypt, dismount drive(X:) 
	
	

n di as result _col(15) "---------------------"
n di as result _col(15) "|  Data import done |"
n di as result _col(15) "---------------------"

	
**# End
}
