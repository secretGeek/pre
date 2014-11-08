# dot this file (for example add this to your $profile: ". .\pre.ps1")
##                 _
##  ___  _ _  ___ | |
## | p \| r_>/ e_>!_/
## |  _/|_|  \___.<_>
## |_|
## 
## PRE! The friendly pre-processor.
## 
## MIT License. Leon Bambrick 2014
# ascii art, courtesy of http://patorjk.com/software/taag/#p=display&f=Dr%20Pepper&t=pre!%0Acodeblocks%0A%0A
## 
## Commands:
## pre $file        <-- process a file, replacing codeblocks with their result.
###                       write the result to the same file, with .pre removed from the name.
###                       e.g. pre 'person.cs.pre' will write to 'person.cs'
###                       while pre 'person.cs' will overwrite 'person.cs' (as there is no '.pre' to be replaced
## pre_help          <-- help on pre
## pre_help_detailed <-- verbose help on pre, with details about codeblocks.
###              _       _    _            _       
###  ___  ___  _| | ___ | |_ | | ___  ___ | |__ ___
### / | '/ . \/ . |/ ._>| . \| |/ . \/ | '| / /<_-<
### \_|_.\___/\___|\___.|___/|_|\___/\_|_.|_\_\/__/
###                                                
### 
### A codeblock is a {language:expression:} embedded in a text file that "pre" replaces with the result of their invokation.
### Currently there are two kinds of codeblocks that can be used: powershell, and sql.
### 
### powershell codeblocks look like this:
### 
###   {powershell:
###   dir c:\
###   :}
### 
### SQL codeblocks look like this, and are executed against the connection from $env:conn
### 
###   {sql:
###   select * from sysobjects
###   :}
### 
### 
### NimbleText codeblocks look like this, and are mixed with the data from file named $env:ntdata
### 
###   {nt:
###   Hello $0 how are you.
###   :}
###
### When pre is run, the codeblocks are replaced with the result of their execution.
### The start and end tags of a code block must be on their own line. So you can't do this:
### {sql:select * from sysobjects:} <-- this won't work. *yet* 
# TODO: make that work.
### 
### The start and end tags can be wrapped in whatever is the native multi-line comment for the platform, e.g.
### /* {powershell:
### dir c:\
### :} */
###
### ...this works because the start tag only has to be the last thing on the line, and the end tag only has to be 
### the first thing on the line. Any other text on tag start/end lines is assumed to be comments, and is discarded/replaced.
# No support for stripping platform-specific comment prefixes, e.g. "--" on sql, "//" on C-family. Yet!

function pre_help() {
    $x = (& { $myInvocation.ScriptName })
    type $x | ? { $_ -like "## *"}  | % { $_.TrimStart("#") }
}

function pre_help_detailed() {
    $x = (& { $myInvocation.ScriptName })
    type $x | ? { ($_ -like "## *") -or ($_ -like "### *")}  | % { $_.TrimStart("#") }
}
 
function pre([string]$file) {
	if ($file -eq "") { write-error "specify a file to process. for help: pre_help"; return; }
	$mode = "normal"
	$codeblock = "";
	$output = "";
	# if there is a .pre at the end of the filename, remove it!
	$outfile = $file -replace "\.pre$",""  
	type $file | 
	% { 
		if ($mode -ne "normal" ) {
			if ($_.StartsWith(":}")) {
				# finished a code block, now interpret the code...
				if ($mode -eq "sql") {
                    $codeblock = prepare-sql($codeblock);
				} elseif ($mode -eq "nimbleText") {
					# todo: don't hardcode the pattern 
                    $codeblock = prepare-nt($codeblock);
				}
                #write-host $codeblock;
				Invoke-expression $codeblock; 
				$mode = "normal";
				$codeblock = "";
			} else {
				# still in the codeblock, keep building up the code...
				$codeblock = $codeblock  + $_ + "`r`n";
			}
		} else {
			# mode is "normal"
			if ($_.EndsWith("{powershell:")) {
				#start of a powershell block... (skip this line)
				$mode = "powershell";
			} elseif ($_.EndsWith("{sql:")) {
				#start of a sql block... (skip this line)
				$mode = "sql";
			} elseif ($_.EndsWith("{nt:")) {
				$mode = "nimbleText";
			} else {
				# echo the current line to the output.
				$_;
			}
		}
	} | out-file $outfile -Encoding 'UTF8'; 

  if ($mode -ne "normal" ) {
    # we got to the end without completing our code block.
    write-host "final " + $mode + " codeblock not terminated (expected a ':}' but didn't find it), to wit:"  -foregroundcolor "red"
    write-host $codeblock
  } 
  
  $mode = "normal";
  $codeblock = "";

}

function Local:prepare-Sql($code) {
	# Note: provide connection string via $env:conn.
    # (we parse out the server, db, and either SSPI or username/password... fragile...)

    $sb = New-Object System.Data.Common.DbConnectionStringBuilder
    $sb.set_ConnectionString($env:conn)
    $server =  ($sb["Server"], $sb["Data Source"],'None' -ne $null)[0]
    $E = ($sb["Integrated Security"], $sb["Trusted_Connection"],'False' -ne $null)[0]
    if ($E -ne "False") 
    { $usr = " -E " } else 
    { 
        $user = ($sb["User Id"], $sb["Uid"] -ne $null)[0]
        $pass = ($sb["Password"], $sb["Pwd"] -ne $null)[0] 
        $usr = " -U '$user' -P '$pass' ";
    }
    $db =  ($sb["Database"], $sb["Initial Catalog"],'None' -ne $null)[0]
	$code = "sqlcmd " + $usr + " -S '" + $server + "' -d '" + $db + "' -W -Q '" + $code.trim() + "' | ? { `$_ -ne '' };"
    return $code;
}

function Local:prepare-nt($code) { 
  if ($env:ntdata -eq $null) {
    write-error "NimbleText patterns require the ntdata environment variable to specify the data file"
    return "`"Oops! pre cannot process your NimbleText pattern. You must specify ```$env:ntdata (the data source to run the pattern against).`r`n" + $code.replace('$','`$') + "`"" ;
  }
  $patternfile = [System.IO.Path]::GetTempFileName();
  $code | out-file $patternfile -Encoding 'UTF8';
  $code = "& nimbletext.com --inputdatafile='$env:ntdata' --patternfile='$patternFile' --rowdelim='\n' --coldelim=','";
  # todo: nimbleText.exe must be in the path
  # todo: nimbleText.com must be in the path (nobody knows about this)
  # todo: ensure "\r\n" and "\n" are respected on any platform.
  return $code;
}

