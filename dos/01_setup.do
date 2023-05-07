                                                                                                                                                                                                      /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          01_setup.do                                                ║
║    PROJECT:        Test Project                                               ║
║    PURPOSE:        All setup for the Data Flow                                ║
║-------------------------------------------------------------------------------║
║    AUTHOR:         [YOUR NAME], ARCED Foundation                              ║
║    CONTACT:        [YOUR.EMAIL]@arced.foundation                              ║
║-------------------------------------------------------------------------------║
║    CREATED:        03 December 2022                                           ║
║    MODIFIED:       28 April 2023                                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                                                                                                                                                                                       */


**# Setup Stata
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	discard
	clear           all
	macro drop      _all
	set min_memory  1g
	set more        off 
	set niceness    1
	set traced      1 
	pause           on
	set seed        87235
	set sortseed    87235
	version         11
	set maxvar      32767	
	
	
qui {	
**# Setup working directory
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	if "$cwd" ~= "" cd "$cwd"
	else global cwd "`c(pwd)'"
	sysdir set PLUS "01_Ado"
	
	
	
**# Installations
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
		
	** Install veracrypt 
	cap which 	veracrypt
	if _rc 		ssc install veracrypt, all replace 
	
	** Install sctoapi
	cap which 	sctoapi
	if _rc 		net install scto, all replace ///
				from("https://raw.githubusercontent.com/surveycto/scto/master/src")
	
	** Install odksplit 
	cap which 	odksplit
	if _rc 		net install odksplit, all replace ///
				from("https://raw.githubusercontent.com/ARCED-Foundation/odksplit/master")
	
	** Install parallel 
	cap which 	parallel
	if _rc 		net install parallel, ///
				from("https://raw.github.com/gvegayon/parallel/stable/") replace
	mata mata 	mlib index
	
	** Install gtools 
	cap which 	gtools
	if _rc 		ssc install gtools, all replace 


	
**# Switches
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	**# Data sources
	*---------------------------	
	
	gl 	sctodownload			0		// Download data from SurveyCTO		
		* Globals for SurveyCTO api download
		*-----------------------------------
		gl formid			"apwp_confirmation"
		gl sctodataloc		"X:"
		
	gl 	odkdownload				0		// Download data from ARCED ODK server	
		* Globals for ARCED ODK server api download
		*------------------------------------------
	
	gl	manualdownload			0		// Download data manually	
		* Globals for manual download
		*----------------------------
		gl 	sctodesktoploc	"C:\Users\\`=c(username)'\AppData\local\Programs\SurveyCTODesktop\SurveyCTO Desktop.exe"
	

	
	**# Actions
	*---------------------------
	gl 	data_correction			1
	gl 	pii_correction			1
	
	
	**# Preferences
	*---------------------------
	gl	warning 				0
	
	
	
	
**# File paths
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	/*--------------------------------------------------------------------------	
	
		container		The name and path of the encrypted container. 
						If the mentioned container does not exist, the 
						program will notify and automatically create the
						container using VeraCrypt. 
						
		rawdata 		The name of the raw csv data. The path is by default 
						X:/ because the encrypted container will be mounted
						on X:/ drive. Don't change that.
						
		deidentified	The name and path of the deidentified dataset. This
						dataset will not be encrypted.						
	
	--------------------------------------------------------------------------*/
	
	** Data files
	gl 	container			"${cwd}/../03_Data/02_Raw/rawdata"
	gl 	rawdata				"X:/APWP Confirmation Survey_WIDE.csv"
	gl 	deidentified		"${cwd}/../03_Data/04_Intermediate/APWP Confirmation Survey.dta"
// 	gl 	cleandata			"${cwd}/../03_Data/05_Clean/APWP Confirmation Survey_clean.dta"
	gl 	cleandata			"${cwd}/../03_Data/05_Clean/Father_baseline_prep.dta"
	
	** Correction files
	gl	correctionsheet		"${cwd}/../03_Data/03_Corrections/Correction_sheet.xlsx"
	gl	pii_correction_file	"X:/pii_correction.xlsx"
	
	** Outfile
	gl 	outfile_hfc			"${cwd}/../04_Output/02_Checks/Check_report.xlsx"


**# Data preparation
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	/*--------------------------------------------------------------------------	
	
		xlsform			The name and path of the XLSForm. This will be used
						to label the variables.
						
		media			Space separated list of variables of ODK/SurveyCTO 
						media, i.e., audio audit, text audit etc.
						
		PIIs 			List of PIIs those need to be split from the dataset.
						
		uid				The unique identification. This should be key variable.						
	
	--------------------------------------------------------------------------*/
	
	gl 	xlsform				"${cwd}/../01_Instruments/02_XLSForm/APWP Confirmation Survey.xlsx"	
	gl 	media				"text audio"																									
	gl 	uid					"key"
	gl 	sid					"hhid_final"
	
							#d ;	
	gl  PIIs				" 	enumname landmark ph
								upazila firm_name firmaddress 
								resp_que respondent_name	
							" ;	
							#d cr	
	
	
	
**# Survey information
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	/*--------------------------------------------------------------------------	
	
		surveystart		The date when surveys started. All data before this 
						will be dropped.
						
		starttime		Start time variable.
						
		uid				The unique identification. This should be key variable.						
	
	--------------------------------------------------------------------------*/
	
	gl 	surveystart			"01feb2023"
	gl 	targetsample		"2000"
	
	gl 	startdate			"startdate"
	gl 	starttime			"starttime"
	gl 	enddate				"enddate"
	gl 	endtime				"endtime"
	gl 	duration			"duration"
	
	gl  consent				"consent_final"
	gl 	enumid				"enumid"
	gl 	enumname 			""
	
	gl 	dk					"-99"
	gl 	ref					"-98"	
	
	
**# Check preferances
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	* Outliers
	gl	outkeepvars			""
	gl 	sd					3
	gl	comboutvars			"age_* dob_* gender_*"
								
							#d ;	
	gl  outexclude			" 	pct_conversation pct_moving pct_still pct_quiet
								mean_light_level mean_sound_level consent_1
								mean_sound_pitch backcheck_rand	
							" ;	
							#d cr	

	
	
	
n di as result _col(15) "---------------------"
n di as result _col(15) "|     Setup done    |"
n di as result _col(15) "---------------------"
	
	
**# End
}