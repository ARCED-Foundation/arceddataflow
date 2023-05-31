*! version 1.0.0 Mehrab Ali 31may2023

cap prog drop arceddataflow
program  arceddataflow
	version 12
		

	**# Define syntax                                                            
	*-------------------------------------------------------------------------------
		
		syntax, DOfiles(string) 
	
	* Copy do files
		
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/00_master.do" ///
			 "`dofiles'/00_master.do"
		
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/00_master.do" ///
			 "`dofiles'/01_setup.do"
			 
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/00_master.do" ///
			 "`dofiles'/02_import.do"
			 
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/00_master.do" ///
			 "`dofiles'/03_prep.do"
			 
		copy "https://github.com/ARCED-Foundation/arceddataflow/raw/master/dos/00_master.do" ///
			 "`dofiles'/04_checks.do"

			 
end