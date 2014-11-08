# run all the tests.

$testsRun = 0;
$testsFailed = 0;
$folder = "";
dir . *.pre -recurse | % {  
    if ($_.Directory.Name -ne $folder) {
        $folder = $_.Directory.Name;
        write-host $folder.replace("_", " ")... -foregroundcolor "white"
    }
    $testsRun = $testsRun + 1;
    $actualFile = $_.FullName.trimend(".pre"); 
    $expectedFile = $_.FullName.trimend(".pre") + ".expected"; 
    $actual = $_.Name.trimend(".pre"); 
    $expect = $_.Name.trimend(".pre") + ".expected"; 
    
    $actualContent = (gc $actualFile | out-string ) ;
    $expectedContent = (gc $expectedFile | out-string );
    if ($actualContent -ne $expectedContent) {
        $testsFailed = $testsFailed + 1;
        write-host "`t" $actual.trimend(".md").replace("_", " ") " FAIL." -foregroundcolor "red";
    } else {
        write-host "`t" $actual.trimend(".md").replace("_", " ") " Passed!" -foregroundcolor "green";
    }    
 }
 
 write-host "$testsRun tests run, $testsFailed failed";