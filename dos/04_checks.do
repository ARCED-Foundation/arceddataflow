                                                                                                                                                                                                      /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          04_checks.do                                               ║
║    PROJECT:        Test Project                                               ║
║    PURPOSE:        Check data                                                 ║
║-------------------------------------------------------------------------------║
║    AUTHOR:         [YOUR NAME], ARCED Foundation                              ║
║    CONTACT:        [YOUR.EMAIL]@arced.foundation                              ║
║-------------------------------------------------------------------------------║
║    CREATED:        03 December 2022                                           ║
║    MODIFIED:       28 April 2023                                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                                                                                                                                                                                       */



**# Create output file
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	loc template = "https://github.com/ARCED-Foundation/arceddataflow/raw/3943868e90af93e0735d0f4249006d4a15b4250a/assets/Check_report_template.xlsx"

	copy `template' "${outfile_hfc}", replace
	
**# Initiate data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	u "${cleandata}", clear
	
	drop if _n>1200
	if mi("${enumname}") {
		cap g 	enumname = ${enumid}
		gl 	enumname = "enumname"
	}
	

	
**# Enum Performance: Missing values
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	preserve 
		glevelsof ${enumid}, clean loc(enumids)
		
		ds, has(type numeric)	
		loc numvars = "`r(varlist)'"
		
		matrix Enum = J(`: word count `enumids'', 3, .)
		
		loc i = 1
		qui foreach enum of loc enumids {
			loc enumdk 	= 0
			loc enumref = 0
			loc nomiss 	= 0
			
			foreach var of loc numvars {
				count if !mi(`var') & enumid=="`enum'"
				loc nomiss = `nomiss' + r(N)
				
				count if `var'==.d & enumid=="`enum'"
				loc enumdk = `enumdk' + r(N)
				
				count if `var'==.r & enumid=="`enum'"
				loc enumref = `enumref' + r(N)			
			}
			
			mat Enum [`i', 1] = `enumdk'
			mat Enum [`i', 2] = `enumref'
			mat Enum [`i', 3] = `nomiss'
			loc ++i
		}

		mat colnames Enum = DK REF NOMISS
		mat list Enum
		
		clear
		svmat Enum, names(col)
		mat drop Enum
		g dk_per 	= DK  / (DK  + NOMISS)
		g ref_per 	= REF / (REF + NOMISS)
		
		export excel 		dk_per	ref_per ///
							using "${outfile_hfc}", ///
							sh("EnumPerformance")  		///
							sheetmodify 			///
							cell(S2) 				///
							keepcellfmt  		
	restore 
	
	
**# Check 1: Summarize completed surveys by date
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	  
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
	
	
**# Check 2: Summarize completed surveys by enumerator
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	preserve
		keep if ${consent} == 1
		format 	${startdate} %td	
		
		if real("`c(version)'")>11 version 11

		table 	 ${enumid} ${enumname} ${startdate}, replace		
		ren table1 d
		reshape  wide d, 		///
				 i(${enumid}) 	///
				 j(${startdate})
		
		egen total = rowtotal(d*)
		egen days  = rownonmiss(d*)
		
		order  ${enumid} ${enumname} days total, first

		export excel 	using "${outfile_hfc}", ///
						sh("C2. Productivity") 	///
						sheetmodify 			///
						cell(A4) 				///
						keepcellfmt 
		
		set obs `=_N+1'		
		gsort ${enumname} ${enumid}, mfirst
		tostring _all, replace force
		
		foreach var of varlist d* {
			loc newvar = subinstr("`var'", "d", "", .)
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
	
	
**# Check 3: Duplicates list
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
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
	

**# Check 4: Formversion check
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
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

	
	
**# Check 5: Refusals
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
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

	
	
	
**# Check 6: Start and end dates
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
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
	
	
	

	
	
**# Check 7: Outliers
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	* Find all numeric variables 
	ds, has(type numeric)
	loc outlier_list 	= "`r(varlist)'"
	
	* Drop catagorical variables if a numeric variable has label 
	ds, has(vallabel ?*)
	loc catvars			= "`r(varlist)'"
	
	foreach var of global comboutvars {
		unab comblist 	: `var'
		loc  combvarlist =  "`combvarlist' " + "`comblist'"
	}
	
	di as err "`combvarlist'"
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
	foreach var of loc new_outlier_list {
	
		preserve
			qui gstats sum `var'    
			
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
			ren  `var'		value

			append using 	`outlier_file', nolabel nonotes
			save 			`outlier_file', replace
		restore
	}
	
	* List of outliers for combined variables
	foreach combvar of global comboutvars {
	
		preserve
			keep `combvar' ${enumid} ${enumname} ${uid} ${sid}
			destring `combvar', replace
			
			unab varlist : `combvar'
			loc varlab 	= `"`: var lab `=word("`varlist'", 1)''"'			
			loc var 	`=ustrregexra("`combvar'", "[\*]|[\?]|[\#]", "")'
			
			reshape long 	`var', ///
							i(${uid}) j(sl)

			lab var `var' "`varlab'"
	
			qui gstats sum `var'    
			
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
			ren  `var'		value

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

	
	
	

	
	
macro drop enumname		
	
	
	
	
	
	
	
	
	
	
	
	