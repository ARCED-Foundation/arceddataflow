*! version 1.0.0 SoTLab, ARCED Foundation 05mat2023 

cap pr drop arced_mount_file
pr arced_mount_file
	
	syntax using, [drive(str) progdir(str)]
	
	* Check if veracrypt command exists
		cap which 	veracrypt
		if _rc 		ssc install veracrypt, all replace 
	
	* Check if the container existis

		gettoken first 	0 : 0
		gettoken container 0 : 0

		cap confirm file `"`container'"'
		
		if mi("`drive'") 	{
			loc drive 	= "X:"
		}
		else {
			loc drive = subinstr("`drive'", "/", "", .)
			loc drive = subinstr("`drive'", "\", "", .)
		}
		
		if mi("`progdir'") 	loc progdir = "C:\Program Files\VeraCrypt"
		
		* IF does not exist
		if _rc {		
			mata : st_numscalar("Confirmed", direxists("`drive'"))
			
			* If not already mounted, that means the container does not exist. 
			if scalar(Confirmed) == 0 {
				cap window stopbox rusure "`container' does not exist." "Do you wish to create a new container?"
				
				if _rc == 0  {
					n di as input "Write desired password: (Make it a strong password)" _r(vpass) _n
					n di as input "What should be the size of the container? (Write in MB, i.e, 10):" _r(vsize) _n
				
					!"`progdir'\VeraCrypt Format.exe" /create "`container'" /password "${vpass}" /hash sha512 /encryption serpent /filesystem FAT /size ${vsize}M /force		
				}
				else {
					n di as err `"No encrypted container "`container'" found"' _n
					exit 601
				}
			}
		}
		
		* Check if already mounted
		mata : st_numscalar("Confirmed", direxists("`drive'"))
		
		if scalar(Confirmed) == 0 {
			veracrypt "`container'", mount drive("`drive'") progdir("`progdir'")
		}
		
		else {
			* Ask for dismount and mount again
			cap window stopbox rusure "`drive' already exists." "Do you wish to dismount?"
			
			if _rc == 0  {
				veracrypt, dismount drive(X:) 
				veracrypt "`container'", mount drive(X:)
			}			
		}
		
		
		* Check if mounting was successful
		mata : st_numscalar("Confirmed", direxists("`drive'"))
		
		if scalar(Confirmed) == 0 {
				n di as err "Mounting was not successful" _n
				exit 696
		}	
			
		else {
			n di as result "Successfully mounted on `drive' drive" _n
		}
		
end


