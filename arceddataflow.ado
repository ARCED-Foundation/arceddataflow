*! version 1.0.1 Mehrab Ali 17jun2023

cap prog drop arceddataflow
program  arceddataflow
	version 12
		

	**# Define syntax                                                            
	*-------------------------------------------------------------------------------
		
		syntax, DOfiles(string) CORRection(string)
	
	* Copy do files
		
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/00_master.do" ///
			 "`dofiles'/00_master.do"
		
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/01_setup.do" ///
			 "`dofiles'/01_setup.do"
			 
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/02_import.do" ///
			 "`dofiles'/02_import.do"
			 
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/03_prep.do" ///
			 "`dofiles'/03_prep.do"
			 
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/04_checks.do" ///
			 "`dofiles'/04_checks.do"
			
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/assets/Correction_sheet.xlsx" ///
			 "`correction'/Correction_sheet.xlsx"

			 
end