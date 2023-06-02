                                                                                                                                                                                                      /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          04_checks.do                                               ║
║    PROJECT:        TRK_followup_survey_2023                                   ║
║    PURPOSE:        Check data                                                 ║
║-------------------------------------------------------------------------------║
║    AUTHOR:                                                                    ║
║    CONTACT:                                                                   ║
║-------------------------------------------------------------------------------║
║    CREATED:                                                                   ║
║    MODIFIED:                                                                  ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                                                                                                                                                                                       */


qui {
include 01_setup.do 
	
**# Create output file
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	loc template 	= "https://github.com/ARCED-Foundation/arceddataflow/raw/master/assets/Check_report_template.xlsx"	
	gl outfile_hfc 			= subinstr("${outfile_hfc}", ".xlsx", "", .)
	gl outfile_hfc_fixed 	= "${outfile_hfc}.xlsx"
	gl outfile_hfc			= "`=subinstr("${outfile_hfc_fixed}", ".xlsx", "", .)'_`=c(current_date)'.xlsx"
	
	copy `template' "${outfile_hfc}", replace
    
	
**# Initiate data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	u "${cleandata}", clear
	
	tostring ${enumid}, replace 
	
	if mi("${enumname}") {
		cap g 	enumname = ${enumid}
		gl 	enumname = "enumname"
	}
	

**# Summary
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*	
	
	n di as input _n "Running summary..."
	
	preserve
		keep if ${consent} == 1
		g dur_min = duration / 60
		collapse (mean) dur_min
		
		
		export excel 		dur_min							///
								using "${outfile_hfc}", 	///
								sh("Summary")				///
								sheetmodify 				///
								cell(J13) 					///
								keepcellfmt 
	
	restore 
	
	preserve
		clear 
		set obs 1
		g today = "`=c(current_date)'"
		
		
		export excel 		today							///
								using "${outfile_hfc}", 	///
								sh("Summary")				///
								sheetmodify 				///
								cell(T7) 					///
								keepcellfmt 
	
	restore 
    
	n di as result  "Summary completed."
	
**# Enum Performance
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	n di as input _n "Running enumerators' performance..."
	preserve 
		keep if ${consent} == 1
		levelsof ${enumid}, clean loc(enumids)
		
		ds, has(type numeric)	
		loc numvars = "`r(varlist)'"
		
		matrix Enum = J(`: word count `enumids'', 4, .)
		
		loc i = 1
		qui foreach enum of loc enumids {
			loc enumdk 	= 0
			loc enumref = 0
			loc nomiss 	= 0
			
			foreach var of loc numvars {
				count if !mi(`var') & ${enumid}=="`enum'"
				loc nomiss = `nomiss' + r(N)
				
				count if `var'==.d & ${enumid}=="`enum'"
				loc enumdk = `enumdk' + r(N)
				
				count if `var'==.r & ${enumid}=="`enum'"
				loc enumref = `enumref' + r(N)			
			}
			
			sum duration if ${enumid}=="`enum'"
			loc enumdur =  r(mean)
			
			mat Enum [`i', 1] = `enumdk'
			mat Enum [`i', 2] = `enumref'
			mat Enum [`i', 3] = `nomiss'
			mat Enum [`i', 4] = `enumdur'
			loc ++i
		}

		mat colnames Enum = DK REF NOMISS DURATION
		mat list Enum
		
		clear
		svmat Enum, names(col)
		mat drop Enum
		g dk_per 	= DK  / (DK  + NOMISS)
		g ref_per 	= REF / (REF + NOMISS)
		
		export excel 		dk_per	ref_per DURATION	///
							using "${outfile_hfc}", 	///
							sh("EnumPerformance")		///
							sheetmodify 				///
							cell(S2) 					///
							keepcellfmt  		
	restore 
	n di as result "Enumerators performance completed."

**# Check 1: Summarize completed surveys by date
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	 
	n di as input _n "Running Check 1: Summarize completed surveys by date"
	preserve
		keep if ${consent} == 1
		format 	${startdate} %td	
		
		if real("`c(version)'")>11 version 11

		table 	${startdate}, replace
		rename 	table1 freq 
		
		gen 	cum_freq 		= sum(freq)
		gen 	perc_targ 		= 100 * (freq / ${targetsample})
		format 	perc_targ 		%9.2f 
		gen 	cum_perc_targ 	= sum(perc_targ) 
		format 	cum_perc_targ 	%9.2f 
		
		export excel 	using "${outfile_hfc}", ///
						sh("C1. Progress")  		///
						sheetmodify 			///
						cell(A4) 				///
						keepcellfmt 		
	restore
	n di as result "Check 1 completed"
	
**# Check 2: Summarize completed surveys by enumerator
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	n di as input _n "Running Check 2: Summarize completed surveys by enumerator"
	preserve
		keep if ${consent} == 1
		format 	${startdate} %td	
		
		if real("`c(version)'")>11 version 11

		table 	 ${enumid} ${enumname} ${startdate}, replace		
		ren table1 _d
		reshape  wide _d, 		///
				 i(${enumid}) 	///
				 j(${startdate})
		
		egen total = rowtotal(_d*)
		egen days  = rownonmiss(_d*)
		
		order  ${enumid} ${enumname} days total, first

		export excel 	using "${outfile_hfc}", ///
						sh("C2. Productivity") 	///
						sheetmodify 			///
						cell(A4) 				///
						keepcellfmt 
		
		set obs `=_N+1'		
		gsort ${enumname} ${enumid}, mfirst
		tostring _all, replace force
		
		foreach var of varlist _d* {
			loc newvar = subinstr("`var'", "_d", "", .)
			replace `var' = `"`=string(`newvar', "%td")'"' in 1
			replace `var' = "" if `var'=="."
		}
		
		replace days			= "Days worked"	in 1
		replace total			= "Surveyed"	in 1
		replace ${enumid} 		= "Enum ID"		in 1
		replace ${enumname} 	= "Name"		in 1
		
		keep if _n==1
		
		export excel 	using "${outfile_hfc}", ///
						sh("C2. Productivity")   ///
						sheetmodify 			///
						cell(A3) 				///
						keepcellfmt nolabel
	restore
	n di as result  "Check 2 completed"
	
**# Check 3: Duplicates list
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	n di as input _n "Running Check 3: Duplicates list"
	preserve
		keep if ${consent}==1
		format 	${starttime} %tc
		
		duplicates tag ${sid}, gen(dup)
		keep if dup>0
		sort ${sid} ${starttime}

		if _N>0 {
			export excel 	${sid} ${starttime} 	///
							${enumid} ${enumname} 	///
							${uid} 					///
							using "${outfile_hfc}", ///
							sh("C3. Duplicates") 	///
							sheetmodify 			///
							cell(A5) 				///
							keepcellfmt nolabel
		}
	restore
	n di as result  "Check 3 completed"
	

**# Check 3b: Duplicates list from other variables
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	n di as input _n "Running Check 3b: Duplicates list from other variables"
	if !mi("${otherdupvars}") {
		preserve
			keep if ${consent}==1
			format 	${starttime} %tc

			foreach var of global otherdupvars {
				duplicates tag `var' if !mi(`var'), gen(`var'_dup)
				sort `var' ${starttime}
				count if `var'_dup>0 & !mi(`var')
				if `=r(N)'>0 {
					g __`var' = "`var'"
					
					export excel 	${sid} ${starttime} 			///
									${enumid} ${enumname} 			///
									 __`var' `var' ${uid} 			///
									using "${outfile_hfc}"			///
									if `var'_dup>0 & !mi(`var'), 	///
									sh("C3b. OtherVarDups") 		///
									sheetmodify 					///
									cell(A5) 						///
									keepcellfmt nolabel
				}
			}
			
		restore	
	}
	n di as result "Check 3b completed"
	
**# Check 4: Formversion check
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	n di as input _n "Running Check 4: Formversion check"
	preserve 
		* Check formdef_version variable 
		cap assert !mi(formdef_version)
		if _rc == 9 {
			count if missing(formdef_version)
			disp as err `"variable formdef_version has `r(N)' missing values."', ///
						`"Version variable should not contain missing values"'
			exit 9
		}
		
		* Current form version
		sum formdef_version
		loc curr_version	`r(max)'
		
		* get first date of latest version	
		sum ${startdate} if formdef_version == `curr_version'
		loc curr_ver_fdate 	`r(min)'
		
		gen outdated  = formdef_version != `curr_version' & ${startdate} >= `curr_ver_fdate'
		gen submitted = submissiondate
		gen lastdate  = ${startdate}
		format lastdate %td
		
		snapshot save
		loc retpoint = r(snapshot)
		collapse 	(count) submitted 		///
					(sum) outdated 			///
					(first) ${startdate}	///
					(last) lastdate 		///
					, by(formdef_version)	///
					fast
		
		sort formdef_version
		
		export excel	using "${outfile_hfc}", ///
						sh("C4. FormVersion") 	///
						sheetmodify 			///
						cell(A5) 				///
						keepcellfmt 
		
		* List outdated submissions
		snapshot restore `retpoint'
		
		keep if outdated
		sort formdef_version
		
		if _N>0 {
			export excel	${enumid} ${enumname} 	///
						${formkeepvars} 		///
						formdef_version 		///
						${startdate}			///
						using "${outfile_hfc}", ///
						sh("C4. FormVersion") 	///
						sheetmodify 			///
						cell(G5) 				///
						keepcellfmt 
		}
		
	restore 
	n di as result  "Check 4 completed"
	
**# Check 5: Refusals
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	n di as input _n "Running Check 5: Refusals"
	preserve
		gen consented= (${consent}==1)
		gen surveyed = _n
		collapse 	(count) surveyed 	///
					(sum) consented		///
					(firstnm) ${enumname} ///
					, by(${enumid}) 	///
					fast		

		gen survey_gap= surveyed - consented
		gen survey_gap_percent= (survey_gap/surveyed)*100
		sort ${enumid}

		export excel 	${enumid}	${enumname} ///									
						surveyed 	consented 	///
						survey_gap 				///
						survey_gap_percent 		///
						using "${outfile_hfc}", ///
						sh("C5. Refusals") 		///
						sheetmodify 			///
						cell(A5) 	keepcellfmt								
	restore
	n di as result  "Check 5 completed"
	
**# Check 6: Start and end dates
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	n di as input _n "Running Check 6: Start and end dates"
	preserve 
		gen message 	= "Start date and end date is not the same; " ///
						if ${startdate} != ${enddate}
		replace message = message + 					///
						"Submission date is different" 	///
						if ${enddate}	!= subdate

		keep if ${startdate} != ${enddate} | ${enddate}	!= subdate	
		sort subdate
		
		replace message = 	substr(message, 1, length(message) - 2) ///
							if substr(message, -2, .) ==  "; "
		
		if _N>0 {		
			export excel 	${sid} 			${uid} 		///
							${enumid} 		${enumname} ///
							${startdate} 	${enddate}	///
							subdate 		message		///
							using "${outfile_hfc}",		///
							sh("C6. DateCheck") 		///
							sheetmodify 				///
							cell(A5) 		keepcellfmt
		}
	restore 
	n di as result  "Check 6 completed"

**# Check 7: Outliers
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	n di as input _n "Running Check 7: Outliers"
	if !mi("`=trim("${outexclude}")'")	drop ${outexclude} 
	
	* Find all numeric variables 
	ds, has(type numeric)
	loc outlier_list 	= "`r(varlist)'"
	
	* Drop catagorical variables if a numeric variable has label 
	ds, has(vallabel)
	loc catvars			= "`r(varlist)'"
	
	foreach var of global comboutvars {
		unab comblist 	: `var'
		loc  combvarlist =  "`combvarlist' " + "`comblist'"
	}
	
	#d ;
	loc exclude_list	= 	"
							${starttime} 	${startdate} 
							${startdate} 	${enddate}
							${enumid} 		${sid} 
							${consent}		${outexclude} 
							duration
							" ;
	#d cr
	
	loc new_outlier_list : list outlier_list 	 - exclude_list 
	loc new_outlier_list : list new_outlier_list - combvarlist 
	loc new_outlier_list : list new_outlier_list - catvars 
	
	
	* keep only relevant variables
	keep `new_outlier_list' ${enumid} ${enumname} ${sid} ${uid} ${outkeepvars} ${comboutvars} 
	lab drop _all
	
	* Start a tempfile 
	preserve 
		clear
		tempfile outlier_file 
		save 	`outlier_file', replace emptyok
	restore 
	
	
	* List of outliers for all variables except combined
	qui foreach var of loc new_outlier_list {
	
		preserve
			qui  sum `var'    
			
			g outlier 	= 	(`var' > (r(mean) + (${sd} * r(sd))) | 	///
							`var' < (r(mean) - (${sd} * r(sd))))	///
							& !mi(`var')
			
			keep if outlier	==	1
			g min 		= r(min)
			g max 		= r(max)
			g sd  		= r(sd)
			g mean 		= r(mean)
			
			keep `var' ${enumid} ${enumname} ${uid} ${sid} min max sd mean ${outkeepvars}
			gen  variable 	= "`var'"
			g varlabel 		= "`: var lab `var''"
			// ren  `var'		value
			
			g value  = `var'
			append using 	`outlier_file', nolabel nonotes
			save 			`outlier_file', replace
		restore
	}
	
	* List of outliers for combined variables
	qui foreach combvar of global comboutvars {
	
		preserve
			keep `combvar' ${enumid} ${enumname} ${uid} ${sid}
			destring `combvar', replace
			
			unab varlist : `combvar'
			loc varlab 	= `"`: var lab `=word("`varlist'", 1)''"'			
			loc var 	`=ustrregexra("`combvar'", "[\*]|[\?]|[\#]", "")'
			
			foreach singvar of local varlist {
				count if !mi(`singvar')
				if r(N) == 0 drop `singvar'
			}
					
			cap reshape long `var', ///
							i(${uid}) j(sl)
							
			if _rc reshape long	`var', ///
							i(${uid}) j(sl) string

			lab var `var' "`varlab'"
	
			qui sum `var'    
			
			g outlier 	= 	(`var' > (r(mean) + (${sd} * r(sd))) | 	///
							`var' < (r(mean) - (${sd} * r(sd))))	///
							& !mi(`var')
			
			keep if outlier	==	1
			g min 		= r(min)
			g max 		= r(max)
			g sd  		= r(sd)
			g mean 		= r(mean)
			tostring sl, replace
			g `var'_name= "`var'" + sl
			
			
			keep `var' `var'_name ${enumid} ${enumname} ${uid} ${sid} min max sd mean ${outkeepvars}
			gen  variable 	= "`var'_name"
			g varlabel 		= "`: var lab `var''"
			// ren  `var'		value
			
			g value = `var'
			append using 	`outlier_file', nolabel nonotes
			save 			`outlier_file', replace
			
		restore
	}
	
	
	* Export all
	u `outlier_file', clear 
	
	sort variable ${enumname} ${enumid}, stable
	
	if _N>0 {		
		export excel 	${sid} 			${uid} 		///
						${enumid} 		${enumname} ///
						variable varlabel value		///
						min 	max 	sd			///
						${outkeepvars}				///
						using "${outfile_hfc}",		///
						sh("C7. Outliers") 			///
						sheetmodify 				///
						cell(A5) 		keepcellfmt
	}

	n di as result  "Check 7 completed"
	use "${cleandata}", clear
    
	
**# Check 8: All comments
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	if !mi("${enumcomments}") {	
		n di as input _n "Running Check 8: All comments"
		gsort ${startdate}
		export 	excel ${sid} ${uid} ${enumid} 						///
				${enumname} ${startdate} ${enumcomments} 				///
				if !inlist(lower(trim(${enumcomments})), 			///
				"na","no","m/a","n/a","n\a","nai","nei",".na",".") 	///
				& !mi(${enumcomments}) 								///
				using "${outfile_hfc}", 							///
				sheetmodify 										///
				sh("C8. Comments")									///
				cell(A5) 		keepcellfmt
    
	n di as result  "Check 8 completed"
	}


    
**# Check 9: Prepare and export comments data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*	

	if !mi("${sctocomments}")  {
		n di as input _n "Running Check 9: Prepare and export comments data"

		* Export stats
		
		n u "${commentsdata}" if !inlist(comment, ".") & !mi(comment), clear
		
		* Variable stats
		g variable = reverse(substr(reverse(fieldname), 1, strpos(reverse(fieldname), "/") - 1))
		replace variable = fieldname if !regex(fieldname, "/")
		
		merge m:m ${uid} using "${cleandata}", nogen keep(3) keepusing(${enumid} ${enumname} ${startdate} ${sid})
		
						
			export 	excel 	${sid} ${uid} ${enumid} ///
							${enumname}  			///
							${startdate} variable comment	///
							using "${outfile_hfc}", ///
							sheetmodify 			///
							sh("C9. SCTOcomments")	///
							cell(A5) keepcellfmt	
		n di as result  "Check 9 completed"
	}
	
**# Check 10: Prepare and check text audit data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*	

	if !mi("${text_audit}")  {
		n di as input _n "Running Check 10: Prepare and check text audit data"
		
		* Export stats
		clear
		tempfile groupstats 
		save	`groupstats', emptyok replace
		
		n u "${textauditdata}", clear
		
		* Variable stats
		g variable = reverse(substr(reverse(fieldname), 1, strpos(reverse(fieldname), "/") - 1))
		replace variable = fieldname if !regex(fieldname, "/")
		
		preserve 
			collapse 	(count) Count	= totaldurationseconds	///
						(mean) 	Mean	= totaldurationseconds 	///
						(sd) 	SD		= totaldurationseconds	///
						(min)	Min		= totaldurationseconds	///
						(max)	Max		= totaldurationseconds	///
						, by(variable)
						
			export 	excel 	using "${outfile_hfc}", ///
							sheetmodify 			///
							sh("C10. TimeSpent")		///
							cell(H5) keepcellfmt
		
		restore 
		
		g groupnames = regexr(fieldname, variable + "$", "")
		split groupnames, p("/") gen(group_)
		
		* If groups exist
		cap confirm var group_1 
		if !_rc {
			foreach var of varlist group_* {
				replace `var' = regexr(`var', "\[(.)+\]", "")
			}
					
			keep totaldurationseconds group_* 
			
			replace group_1 = "No group" if mi(group_1)
			
			foreach var of varlist group_* {
				preserve 
					drop if mi(`var')
					collapse 	(count) Count	= totaldurationseconds	///
								(mean) 	Mean	= totaldurationseconds 	///
								(sd) 	SD		= totaldurationseconds	///
								(min)	Min		= totaldurationseconds	///
								(max)	Max		= totaldurationseconds	///
						, by(`var')
					ren `var' groupname
					append 	using `groupstats'
					save	`groupstats', replace
				restore
			}
			
			u `groupstats', clear
			g order = groupname!="No group"
			sort order groupname
			drop order
						
			export 	excel 	using "${outfile_hfc}", ///
							sheetmodify 			///
							sh("C10. TimeSpent")		///
							cell(A5) keepcellfmt
				
		}
		n di as result  "Check 10 completed"
	}
	
	
**# Check 11: Time use
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*	

	n di as input _n "Running Check 11: Time use"
	
	* Daily time use
	n u "${cleandata}", clear
	format ${starttime} %tc
	
	gen  __hour = hh(${starttime})
	gen  __min	= mm(${starttime})
	collapse (count)  total= __min, by(${startdate} __hour) fast
	
	sum total 
	loc min = r(min)
	loc max = r(max)
	
	reshape wide total, i(${startdate}) j(__hour)
	
	forval x=1/24 {
		cap g total`x' = .
	}
	
	order total*, seq
	order ${startdate}, first
	order total24, after(${startdate})
	
	
	g 		mintime = `min' in 1
	if _N<17 set obs 17
	replace mintime = `max' in 17
	
		export 	excel 	using "${outfile_hfc}", ///
						sheetmodify 			///
						sh("C11a. DailyTimeUse")	///
						cell(A5) keepcellfmt	
						
	
	* Enum time use
	n u "${cleandata}", clear
	format ${starttime} %tc
	
	gen  __hour = hh(${starttime})
	gen  __min	= mm(${starttime})
	collapse (count)  total= __min (first) ${enumname}, by(${enumid} __hour) fast
	
	sum total 
	loc min = r(min)
	loc max = r(max)
	
	reshape wide total, i(${enumid} ${enumname}) j(__hour)
	
	forval x=1/24 {
		cap g total`x' = .
	}
	
	order total*, seq
	order ${enumid} ${enumname}, first
	order total24, after(${enumname})
	
	
	g 		mintime = `min' in 1
	if _N<17 set obs 17
	replace mintime = `max' in 17
	
		export 	excel 	using "${outfile_hfc}", ///
						sheetmodify 			///
						sh("C11b. EnumTimeUse")	///
						cell(A5) keepcellfmt	
						
	n di as result  "Check 11 completed"	
	
	
	macro drop enumname			
	copy  "${outfile_hfc}" "${outfile_hfc_fixed}", replace
	n di _n  `"Check report is saved here: {browse "${outfile_hfc}":${outfile_hfc}}"'
	n di   `"Correction logs are saved here: {browse "${correction_log}":${correction_log}}"'
	!"${outfile_hfc_fixed}"
	
}	
** END OF DATA FLOW **	
	

			