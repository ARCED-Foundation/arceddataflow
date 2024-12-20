cls                                                                                                                                                                                                   /*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                 __  __  ___ __     _____          __    ___ __                ║
║             /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |           ║
║            /~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|           ║
║           www.arced.foundation;  https://github.com/ARCED-Foundation          ║
║                                                                               ║
║-------------------------------------------------------------------------------║
║    TITLE:          00_master.do                                               ║
║    PROJECT:        						                                    ║
║    PURPOSE:        Master do file for dataflow                                ║
║-------------------------------------------------------------------------------║
║    AUTHOR:                                                                    ║
║    CONTACT:                                                                   ║
║-------------------------------------------------------------------------------║
║    CREATED:                                                                   ║
║    MODIFIED:                                                                  ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                                                                                                                                                                                                                                                                                                                                                                                               

                                                                                                                                                                                                       */
                                                                                                                                                                                                                                                                                                                                                                                         	
	                                                                                                                                                                                                                                                                                                                                                                                         	
                                                                                                                                                                                                                                                                                                                                                                                         																																																																																																	
**# Run do files
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	
	**# 01_setup.do
	/*---------------------------------------------------	
	
		01_setup.do congiures the Stata environment
		and set necessary globals for the data flow.	
	
	----------------------------------------------------*/
	
	do "01_setup.do"
	
	
	**# 02_import.do
	/*---------------------------------------------------	
	
		02_import.do does data download, encryption,
		PII splitting, data labeling.
	
	----------------------------------------------------*/

	do "02_import.do"
	
		
	**# 03_prep.do
	/*---------------------------------------------------	
	
		03_prep.do includes all the preparatory works
		for data, data labeling, variable renaming, 
        manual data corrections and basic cleaning.
	
	----------------------------------------------------*/

	do "03_prep.do"
	
		
	**# 04_checks.do
	/*---------------------------------------------------	
	
		04_checks.do includes all the logical checks
		and data quality checks.
	
	----------------------------------------------------*/
	
	do "04_checks.do"

	
	
**# End
