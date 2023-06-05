## :nazar_amulet: Overview

``arceddataflow`` is a Stata command that creates the do files for the data flow for a project.



## :card_file_box: Versions
#### Current version
:memo: V1.0.0: May 2023 - [GitHub repo](https://github.com/ARCED-Foundation/arceddataflow/)



## :gear: Installation
```stata
net install arceddataflow, all replace ///
	from("https://raw.githubusercontent.com/ARCED-Foundation/arceddataflow/master")
```

## :wrench: Syntax
``arceddataflow, dofiles(string) correction(string)``


## :screwdriver: Options

<b>dofiles</b> specifies the path where the do files should be created

## :paperclip: Example Syntax
```stata
arceddataflow, do("C:\Users\Mehrab Ali\Projects\New Project") correction(C:\Users\Mehrab Ali\Projects\New Project\Data\Corrections)
```

## :mage: Author
<a href="https://arced.foundation/mehrab-ali" target="_blank">Mehrab Ali</a>

<a href="https://arced.foundation" target="_blank">ARCED Foundation</a>

Please report all :lady_beetle:/feature request to the <a href="https://github.com/ARCED-Foundation/arceddataflow/issues" target="_blank"> github issues page</a>

