*! version 1.0.1 Mehrab Ali 17jun2023

cap prog drop arceddataflow
program  arceddataflow
	version 12
		

	**# Define syntax                                                            
	*-------------------------------------------------------------------------------
		
		syntax, DOfiles(string) CORRection(string) [author(string) email(string) project(string)]
	
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

			 
			 
	**# Edit headers
	*-------------------------------------------------------------------------------
	
	* 00_master.do 
	
	file open setup using "`dofiles'/00_master.do", read write
	file seek setup 4
	file write  setup ///
		_col(200) "/*" _n ///                                                                                                                                                                                 /*
		_col(1) "╔═══════════════════════════════════════════════════════════════════════════════╗"  _n 	///
		_col(1) "║" _col(19) "__" _col(23) "__" _col(27) "___" _col(31) "__" _col(38) "_____" _col(53) "__" _col(59) "___" _col(63) "__"   _col(83) "║" _n  ///
		_col(1) "║" _col(15) "/\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |"  _col(83) "║"  	_n 	///
		_col(1) "║" _col(14) "/~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|" _col(83) "║" 	_n 	///
		_col(1) "║" _col(13) "www.arced.foundation;  https://github.com/ARCED-Foundation" _col(83) "║"	_n 	///
		_col(1) "║"                                                                       _col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "TITLE:"  	_col(22) "00_master.do" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PROJECT:" 	_col(22) "`project'" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PURPOSE:" 	_col(22) "Master do file for dataflow  " 	_col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "AUTHOR:" 	_col(22) "`author'" 	_col(83) "║" _n 	///
		_col(1) "║"    _col(6) "CONTACT:" 	_col(22) "`email'"	 	_col(83) "║" _n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		 _n 	///
		_col(1) "║"    _col(6) "CREATED:" 	_col(22) "`c(current_date)'" 	_col(83) "║"				 _n 	///
		_col(1) "║"    _col(6) "MODIFIED:" 	_col(22) "`c(current_date)'"	 	_col(83) "║"			 _n 	///	
		_col(1) "╚═══════════════════════════════════════════════════════════════════════════════╝"		 _n 	///
		_col(200) "*/" _n

	file close setup
	
	
	* 01_Setup.do 
	
	file open setup using "`dofiles'/01_setup.do", read write
	file seek setup 1
	file write  setup ///
		_col(200) "/*" _n ///                                                                                                                                                                                 /*
		_col(1) "╔═══════════════════════════════════════════════════════════════════════════════╗"  _n 	///
		_col(1) "║" _col(19) "__" _col(23) "__" _col(27) "___" _col(31) "__" _col(38) "_____" _col(53) "__" _col(59) "___" _col(63) "__"   _col(83) "║" _n  ///
		_col(1) "║" _col(15) "/\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |"  _col(83) "║"  	_n 	///
		_col(1) "║" _col(14) "/~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|" _col(83) "║" 	_n 	///
		_col(1) "║" _col(13) "www.arced.foundation;  https://github.com/ARCED-Foundation" _col(83) "║"	_n 	///
		_col(1) "║"                                                                       _col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "TITLE:"  	_col(22) "01_setup.do" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PROJECT:" 	_col(22) "`project'" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PURPOSE:" 	_col(22) "All setup for the Data Flow  " 	_col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "AUTHOR:" 	_col(22) "`author'" 	_col(83) "║" _n 	///
		_col(1) "║"    _col(6) "CONTACT:" 	_col(22) "`email'"	 	_col(83) "║" _n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		 _n 	///
		_col(1) "║"    _col(6) "CREATED:" 	_col(22) "`c(current_date)'" 	_col(83) "║"				 _n 	///
		_col(1) "║"    _col(6) "MODIFIED:" 	_col(22) "`c(current_date)'"	 	_col(83) "║"			 _n 	///	
		_col(1) "╚═══════════════════════════════════════════════════════════════════════════════╝"		 _n 	///
		_col(200) "*/" _n

	file close setup	
		
		
	* 02_import.do 
	
	file open setup using "`dofiles'/02_import.do", read write
	file seek setup 1
	file write  setup ///
		_col(200) "/*" _n ///                                                                                                                                                                                 /*
		_col(1) "╔═══════════════════════════════════════════════════════════════════════════════╗"  _n 	///
		_col(1) "║" _col(19) "__" _col(23) "__" _col(27) "___" _col(31) "__" _col(38) "_____" _col(53) "__" _col(59) "___" _col(63) "__"   _col(83) "║" _n  ///
		_col(1) "║" _col(15) "/\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |"  _col(83) "║"  	_n 	///
		_col(1) "║" _col(14) "/~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|" _col(83) "║" 	_n 	///
		_col(1) "║" _col(13) "www.arced.foundation;  https://github.com/ARCED-Foundation" _col(83) "║"	_n 	///
		_col(1) "║"                                                                       _col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "TITLE:"  	_col(22) "02_import.do" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PROJECT:" 	_col(22) "`project'" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PURPOSE:" 	_col(22) "Import, label and deidentify data  " 	_col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "AUTHOR:" 	_col(22) "`author'" 	_col(83) "║" _n 	///
		_col(1) "║"    _col(6) "CONTACT:" 	_col(22) "`email'"	 	_col(83) "║" _n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		 _n 	///
		_col(1) "║"    _col(6) "CREATED:" 	_col(22) "`c(current_date)'" 	_col(83) "║"				 _n 	///
		_col(1) "║"    _col(6) "MODIFIED:" 	_col(22) "`c(current_date)'"	 	_col(83) "║"			 _n 	///	
		_col(1) "╚═══════════════════════════════════════════════════════════════════════════════╝"		 _n 	///
		_col(200) "*/" _n

	file close setup	
	
	
	* 03_prep.do 
	
	file open setup using "`dofiles'/03_prep.do", read write
	file seek setup 1
	file write  setup ///
		_col(200) "/*" _n ///                                                                                                                                                                                 /*
		_col(1) "╔═══════════════════════════════════════════════════════════════════════════════╗"  _n 	///
		_col(1) "║" _col(19) "__" _col(23) "__" _col(27) "___" _col(31) "__" _col(38) "_____" _col(53) "__" _col(59) "___" _col(63) "__"   _col(83) "║" _n  ///
		_col(1) "║" _col(15) "/\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |"  _col(83) "║"  	_n 	///
		_col(1) "║" _col(14) "/~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|" _col(83) "║" 	_n 	///
		_col(1) "║" _col(13) "www.arced.foundation;  https://github.com/ARCED-Foundation" _col(83) "║"	_n 	///
		_col(1) "║"                                                                       _col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "TITLE:"  	_col(22) "03_prep.do" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PROJECT:" 	_col(22) "`project'" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PURPOSE:" 	_col(22) "Prepare and clean data  " 	_col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "AUTHOR:" 	_col(22) "`author'" 	_col(83) "║" _n 	///
		_col(1) "║"    _col(6) "CONTACT:" 	_col(22) "`email'"	 	_col(83) "║" _n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		 _n 	///
		_col(1) "║"    _col(6) "CREATED:" 	_col(22) "`c(current_date)'" 	_col(83) "║"				 _n 	///
		_col(1) "║"    _col(6) "MODIFIED:" 	_col(22) "`c(current_date)'"	 	_col(83) "║"			 _n 	///	
		_col(1) "╚═══════════════════════════════════════════════════════════════════════════════╝"		 _n 	///
		_col(200) "*/" _n

	file close setup	
	
	
	* 04_checks.do 
	
	file open setup using "`dofiles'/04_checks.do", read write
	file seek setup 1
	file write  setup ///
		_col(200) "/*" _n ///                                                                                                                                                                                 /*
		_col(1) "╔═══════════════════════════════════════════════════════════════════════════════╗"  _n 	///
		_col(1) "║" _col(19) "__" _col(23) "__" _col(27) "___" _col(31) "__" _col(38) "_____" _col(53) "__" _col(59) "___" _col(63) "__"   _col(83) "║" _n  ///
		_col(1) "║" _col(15) "/\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ |"  _col(83) "║"  	_n 	///
		_col(1) "║" _col(14) "/~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|" _col(83) "║" 	_n 	///
		_col(1) "║" _col(13) "www.arced.foundation;  https://github.com/ARCED-Foundation" _col(83) "║"	_n 	///
		_col(1) "║"                                                                       _col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "TITLE:"  	_col(22) "04_checks.do" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PROJECT:" 	_col(22) "`project'" 						_col(83) "║"	_n 	///
		_col(1) "║"    _col(6) "PURPOSE:" 	_col(22) "Data check  " 	_col(83) "║"	_n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		_n 	///
		_col(1) "║"    _col(6) "AUTHOR:" 	_col(22) "`author'" 	_col(83) "║" _n 	///
		_col(1) "║"    _col(6) "CONTACT:" 	_col(22) "`email'"	 	_col(83) "║" _n 	///
		_col(1) "║-------------------------------------------------------------------------------║"		 _n 	///
		_col(1) "║"    _col(6) "CREATED:" 	_col(22) "`c(current_date)'" 	_col(83) "║"				 _n 	///
		_col(1) "║"    _col(6) "MODIFIED:" 	_col(22) "`c(current_date)'"	 	_col(83) "║"			 _n 	///	
		_col(1) "╚═══════════════════════════════════════════════════════════════════════════════╝"		 _n 	///
		_col(200) "*/" _n

	file close setup
			 
end


