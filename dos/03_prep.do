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
**# Initiate deidentified dataset
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	n u "${deidentified}", clear
	

**# generate date variabls
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	gen startdate 	= dofc(starttime)
	gen enddate		= dofc(endtime)
	gen subdate 	= dofc(submissiondate)
	
	format %td startdate enddate subdate
	

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
	
**# Drop observations with date before survey start date
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	drop if startdate <= date("${surveystart}", "DMY")
	
	
	
		
**# destring numeric variables
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	destring _all, replace

	
	
**# drop unwanted variables
*------------------------------------------------------------------------------*

	#d;
	drop deviceid 
		 subscriberid 
		 simid 
		 devicephonenum 
		/* username */
		 ;
	#d cr
	

**# Manual corrections
*------------------------------------------------------------------------------*

	qui if ${data_correction} {
		
		tempfile c_maindata 
		save 	`c_maindata'
		
		import excel "${correctionsheet}", first clear
		drop if mi(key)
		tostring _all, replace

		if _N>0  {
			levelsof variable, clean loc(variables)
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
	

	
**# Recode extended missing values
*------------------------------------------------------------------------------*
	
	qui {
		if "${dk}" != "" loc dk_rec = "(`= trim(itrim(subinstr("${dk}", ",", " ", .)))' = .d)" 
		if "${ref}"!= "" loc ref_rec = "(`= trim(itrim(subinstr("${ref}", ",", " ", .)))' = .r) "
		
		ds, has(type numeric)
		if !mi("${dk}") & !mi("${ref}") recode `r(varlist)' `dk_rec' `ref_rec'
		
		n di as result "Recoding extended missing values done." _n
	}
	
	
**# Saving prepped data
*------------------------------------------------------------------------------*
	
	g factory_id = _n
	
	qui {
		compress
		label data "Deidentified & cleaned dataset. Updated by `=c(username)' on `=c(current_date)' `=c(current_time)'."
		save "${cleandata}", replace 	

		n di as result "Cleaned data saved here ${cleandata}" _n
	}

	
	
n di as result _col(15) "---------------------"
n di as result _col(15) "|  Data cleanig done |"
n di as result _col(15) "---------------------"
	
	
**# End
}