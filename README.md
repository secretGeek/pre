                     _
      ___  _ _  ___ | |
     | p \| r_>/ e_>!_/
     |  _/|_|  \___.<_>
     |_|
     
#PRE! The friendly pre-processor.
 
**MIT License. Leon Bambrick 2014**
 
*Commands:*

    pre $file        
...process a file, replacing codeblocks with their result.
write the result to the same file, with .pre removed from the name. e.g. `pre 'person.cs.pre' will write to 'person.cs'
while pre 'person.cs' will overwrite 'person.cs' (as there is no '.pre' to be replaced

    pre_help
...help on pre

    pre_help_detailed
...verbose help on pre, with details about codeblocks.
 
                   _       _    _            _       
       ___  ___  _| | ___ | |_ | | ___  ___ | |__ ___
      / | '/ . \/ . |/ ._>| . \| |/ . \/ | '| / /<_-<
      \_|_.\___/\___|\___.|___/|_|\___/\_|_.|_\_\/__/
                                                 
 
 A codeblock is a {language:expression:} embedded in a text file that "pre" replaces with the result of their invokation.
 Currently there are two kinds of codeblocks that can be used: powershell, and sql.
 
 powershell codeblocks look like this:
 
    {powershell:
    dir c:\
    :}
 
 SQL codeblocks look like this, and are executed against the connection from $env:conn
 
    {sql:
    select * from sysobjects
    :}
 
 
 NimbleText codeblocks look like this, and are mixed with the data from file named $env:ntdata
 
    {nt:
    Hello $0 how are you.
    :}
    
 When pre is run, the codeblocks are replaced with the result of their execution.
 The start and end tags of a code block must be on their own line. So you can't do this:
 {sql:select * from sysobjects:} <-- this won't work. *yet* 
 
 The start and end tags can be wrapped in whatever is the native multi-line comment for the platform, e.g.
 
     /* {powershell:
     dir c:\
     :} */
 ...this works because the start tag only has to be the last thing on the line, and the end tag only has to be 
 the first thing on the line. Any other text on tag start/end lines is assumed to be comments, and is discarded/replaced.
