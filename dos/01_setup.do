                                                                                                                                                                                                      /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          02_setup.do                                                ║
║    PROJECT:        						                                    ║
║    PURPOSE:        All setup for the Data Flow                                ║
║-------------------------------------------------------------------------------║
║    AUTHOR:                                                                    ║
║    CONTACT:                                                                   ║
║-------------------------------------------------------------------------------║
║    CREATED:                                                                   ║
║    MODIFIED:                                                                  ║
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
				from("https://raw.githubusercontent.com/surveycto/stata-scto/master/src")
	
	** Install odksplit 
	cap which 	odksplit
	if _rc 		net install odksplit, all replace ///
				from("https://raw.githubusercontent.com/ARCED-Foundation/odksplit/master")
	adoupdate odksplit, update


	** Install arced_mount_file 
	cap which 	arced_mount_file
	if _rc 		net install arced_mount_file, all replace ///
				from("https://raw.githubusercontent.com/ARCED-Foundation/arceddataflow/master/ados")
	
	** Install graph scheme
	cap conf file 	"01_Ado/s/scheme-white_w3d.scheme"
	if _rc 		ssc install schemepack, replace
	
**# Switches
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	**# Data sources
	*---------------------------
	
	/*----------------------------------------------------------------
	
		The sctodownload and odkdownload prompts for the username
		and password. If you want not to type the username and 
		password on the command window, you can setup profile.do
		to set the username and password. Read more:
		https://www.stata.com/support/faqs/programming/profile-do-file
		https://www.techtips.surveydesign.com.au/post/the-profile-and-sysprofile-do-files-automating-your-stata-start-up
		
		In the profile.do set the following globals:
		
		* SurveyCTO credentials
		gl suser = "xxxxx" 
		gl spass = "yyyyy"
		
		* ODK credentials
		gl Ouser = "xxxxx"
		gl Opass = "yyyyy"
	
	-----------------------------------------------------------------*/
	
	gl 	sctodownload			0		// Download data from SurveyCTO		
		* Globals for SurveyCTO api download
		*-----------------------------------
		gl formid			"ssc_bd_23"
		gl sctodataloc		"X:"
		gl timeshift 		"6"  		/* 	When data downloaded through API, the time is UTC, 
											so for Bangladesh the default is UTC+6 to shift to local time */
		
	gl 	odkdownload				1		// Download data from ARCED ODK server	
		* Globals for ARCED ODK server api download
		*------------------------------------------
		gl OData 		"https://sotlab.eastus.cloudapp.azure.com/v1/projects/17/forms/skills_for_growth_listing.svc"
		gl odkapi 		`"`=regexr("$OData", ".svc", "/submissions.csv.zip")'"'
		
	
	gl	manualdownload			0		// Download data manually	
		* Globals for manual download
		*----------------------------
		gl 	sctodesktoploc	"C:\Users\\`=c(username)'\AppData\local\Programs\SurveyCTODesktop\SurveyCTO Desktop.exe"
	
		
	
	**# Actions
	*---------------------------
	gl 	data_correction			1
	gl 	pii_correction			0
	gl	odksplit 				1
		gl  language		"English"
		gl 	sctoimportdo 	"02b_datalabel.do"

	
	**# Preferences
	*---------------------------
	gl	warning 				1
	gl	encrypt 				1
	
	
	
	
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
	gl  rawpath				"${cwd}/../03_Data/02_Raw"
	gl 	container			"${cwd}/../03_Data/02_Raw/rawdata"
	gl 	rawdata				"X:/Social Contact Survey 2023_WIDE.csv"
	gl 	rawdatadta			`"`=regexr("${rawdata}", ".csv", ".dta")'"'
	gl	mediafolder			"X:/media"
	
	gl 	deidentified		"${cwd}/../03_Data/04_Intermediate/Social Contact Survey 2023.dta"
 	gl 	cleandata			"${cwd}/../03_Data/05_Clean/Social Contact Survey 2023_clean.dta"
	gl 	textauditdata		"${cwd}/../03_Data/02_Raw/Text_audit_data.dta"
	gl 	commentsdata		"${cwd}/../03_Data/02_Raw/Comments_data.dta"
	
	
	** Correction files
	gl	correctionsheet		"${cwd}/../03_Data/03_Corrections/Correction_sheet.xlsx"
	gl	pii_correction_file	"X:/pii_correction.xlsx"
	gl  correction_log		"${cwd}/../04_Output/01_Logs/Correction_log_`c(current_date)'.xlsx"
	
	** Outfile
	gl 	outpath			"${cwd}/../04_Output/02_Checks"
	gl 	outfile_hfc			"${cwd}/../04_Output/02_Checks/Check_report.xlsx"
	
	** 	audio_audit folder
	gl 	audit_folder		"../../../03_FieldWork/02_Phone_Call/05_Audio_audit"


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
	
	gl 	xlsform				"${cwd}/../01_Instruments/02_XLSForm/Social Contact Survey_23.xlsx"	
	gl 	media				"audio_audit text_audit"
	gl 	text_audit			"text_audit"
	gl	sctocomments		""
	gl 	uid					"key"
	gl 	sid					"id"
	
							#d ;	
	gl  PIIs				" 	upazilaname unionname villagename	gps* 
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
	
	gl 	surveystart			"14may2023"
	gl 	targetsample		"3000"
	
	gl 	startdate			"startdate"
	gl 	starttime			"starttime"
	gl 	enddate				"enddate"
	gl 	endtime				"endtime"
	gl 	duration			"duration"
	
	gl  consent				"availability"
	gl 	enumid				"enumid"
	gl 	enumname 			"enumname"
	
	gl 	dk					"-99"
	gl 	ref					"-98"
	gl 	skip				"-97"
	gl 	NA 					"-95"
	gl 	other				"-96"
	
	gl 	enumcomments		"comments"
	
	
**# Check preferances
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	* Duplicates from other variables 
	gl 	otherdupvars		"phonenumber_called "
	
	* Outliers
	gl	outkeepvars			""
	gl 	sd					3
	gl	comboutvars			"age_year_* "
								
							#d ;	
	gl  outexclude			" 	activity_*	addplace collect_phone_app contacts 
								eligible_*  totalrepeat rand* *_sl* select_mem_id_*
							" ;	
							#d cr	

	* Missing max % 
	gl	missper				"70"
	
	
n di as result _col(15) "---------------------"
n di as result _col(15) "|     Setup done    |"
n di as result _col(15) "---------------------"
	
	
**# End
}
