                                                                                                                                                                                                      /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          02_import.do                                               ║
║    PROJECT:         						                                    ║
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
**# Encryption
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	n di as text "Data import initiated..."
	if ${encrypt} n arced_mount_file using "${container}", drive(X:)
	


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
		n di as text "Data download initiated..."
		! "${sctodesktoploc}"		
		
		n di as result "Data download done." _n
	}
	
	
	* SurveyCTO API data download	
	qui if ${sctodownload} {		
		n di as input "SurveyCTO username:" _r(suser)
		n di as input "SurveyCTO password:" _r(spass)
		n di as text "Data download initiated..."
		cls
		sctoapi ${formid}, server(arced) username("${suser}") password("${spass}") ///
				date(1546344000) output("${sctodataloc}") media("${media}") 
		
		cap copy "${sctodataloc}/${formid}_WIDE.csv" "${rawdata}", replace
		n di as result "Data download done." _n
	}
	
	
**# Data labeling
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	 {		
		n di as text "Data labeling initiated..."
		if !${odksplit} do ${sctoimportdo}
		
		if ${odksplit} {
			
			if !mi("${language}") loc label = "label(${language})"
			insheet using "${rawdata}", clear names
		
			tempfile 	rawdata
			save		`rawdata'
			
			* Label dataset using XLSForm
			qui odksplit, 	data(`rawdata') survey("${xlsform}") ///
							clear dateformat(MDY) `label'
			
			
			* Fix for time shift
			if !mi("${shifttime}") & ${sctodownload} {
				ds _all, has(format %tc* %tC*)
				loc dtvars = r(varlist)
				foreach var of loc dtvars {
					replace `var' = `var' + ${timeshift}*60*60*1000
				}				
			}
			
			* Save dta file
			compress
			label data "Updated by `=c(username)' on `=c(current_date)' `=c(current_time)'. NOTE: This dataset contains PII."
			save `"`=regexr("${rawdata}", ".csv", ".dta")'"', replace 
		}
		
		
		
		n di as result "Data labelling done." _n
	}
	
	

	
**# PII cleaning
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	qui if ${pii_correction} {
		n di as text "PII cleaning initiated..."
		tempfile c_maindata 
		save 	`c_maindata'
		
		import excel "${pii_correction_file}", first clear
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
	
	
	
**# PII splitting
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	qui if !mi(trim("${PIIs}")) {
		n di as text "PII splitting initiated..."
		
		* Save the PII varibles separately
		preserve
			keep 	${PIIs} ${uid}
			label data "This dataset contains only PIIs."
			save `"`=regexr("${rawdata}", ".csv", "_PII.dta")'"', replace 	
		restore
		
		* Save the deidentified dataset
		preserve
			drop 	${PIIs}
			
			ds *name* *phone* 
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
	
**# Prepare Text Audit data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	if !mi("${text_audit}") qui {
		n di as text "Text audit data preparation initiated..."
		
		clear 
		tempfile textauditdata 
		save 	`textauditdata', emptyok replace 
		
		u "${rawdatadta}" if ${consent}==1 & !mi(${text_audit}), clear
		
		cap confirm file "${textauditdata}"
		if !_rc merge m:m ${uid} using "${textauditdata}", keep(1) nogen
		
		if `=_N' > 0 {
					
			if regexm(${text_audit}, "^https") {
			    * Browser or API 
				g __key = subinstr(key, "uuid:", "",.)
				replace ${text_audit} = "TA_" + __key 
				drop __key
			}
			
			else if regexm(${text_audit}, "^media") {
			    * Surveycto desktop
			    replace ${text_audit} = substr(${text_audit}, strpos(${text_audit}, "media\") + 6, ///
										strpos(${text_audit}, ".csv") - strpos(${text_audit}, "media\") - 6)
			}
			
			* Append all the files
			levelsof ${text_audit}, clean loc(alltexts)
			
			loc i = 1
			loc x = 0
			n _dots 0, title(Appending text audit files) reps(`=wordcount("`alltexts'")')
			foreach text of loc alltexts {
				cap confirm file "${mediafolder}/`text'.csv"
				if _rc loc ++x
				
				if !_rc {
					insheet using "${mediafolder}/`text'.csv", names clear
					
					* Generate uid
					g ${uid} = `"uuid:`=subinstr("`text'", "TA_", "",.)'"'
					
					append using `textauditdata'
					save `textauditdata', replace
					n _dots `i' 0 
					loc ++i
				}
			}
			if `x'>0 n di as err _n "`x' text audit files do not exist" _n
			
			
			if  `=_N'>0 {
				compress
				n di "" _n
				n di as result "Found `=`i'-1' new text audit files." _n
				cap append using "${textauditdata}"
				save "${textauditdata}", replace
			}	
			
		}
	}
		
**# Prepare Comment data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
		
	if !mi("${sctocomments}") qui {
		n di as text "Comments data preparation initiated..."
		
		clear 
		tempfile commentdata 
		save 	`commentdata', emptyok replace 
		
		u "${rawdatadta}" if ${consent}==1 & !mi(${sctocomments}), clear
		
		cap confirm file "${commentsdata}"
		if !_rc merge m:m ${uid} using "${commentsdata}", keep(1) nogen
		
		if `=_N' > 0 {
					
			if regexm(${sctocomments}, "^https") {
			    * Browser or API 
				g __key = subinstr(key, "uuid:", "",.)
				replace ${sctocomments} = "Comments-" + __key 
				drop __key
			}
			
			else if regexm(${sctocomments}, "^media") {
			    * Surveycto desktop
			    replace ${sctocomments} = substr(${sctocomments}, strpos(${sctocomments}, "media\") + 6, ///
										strpos(${sctocomments}, ".csv") - strpos(${sctocomments}, "media\") - 6)
			}
			
			* Append all the files
			levelsof ${sctocomments}, clean loc(allcomments)
			
			loc i = 1
			loc x = 1
			n _dots 0, title(Appending comments files)  reps(`=wordcount("`allcomments'")')
			foreach text of loc allcomments {
				cap confirm file "${mediafolder}/`text'.csv"
				if _rc loc ++x
				
				if !_rc {
					insheet using "${mediafolder}/`text'.csv", names clear
					tostring _all, replace
					* Generate uid
					g ${uid} = `"uuid:`=subinstr("`text'", "Comments-", "",.)'"'
					
					append using `commentdata'
					save `commentdata', replace
					n _dots `i' 0
					loc ++i
				}				
			}
			
			if `x'>0 n di as err _n "`x' comment files do not exist" _n
			
								
			if  `=_N'>0 {
				compress
				n di "" _n 
				n di as result "Found `=`i'-1' new Comment files." _n
				cap append using "${commentsdata}"
				save "${commentsdata}", replace
			}	
		}
	}
	
**# Dismount
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	if ${encrypt} veracrypt, dismount drive(X:) 
	
	

n di as result _col(15) "---------------------"
n di as result _col(15) "|  Data import done |"
n di as result _col(15) "---------------------"

	
**# End
}

