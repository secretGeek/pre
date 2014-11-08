# run all the tests.

$testsRun = 0;
$testsFailed = 0;
dir *.pre | % {  
    
    pre $_.Name;
    $testsRun = $testsRun + 1;
    $actual = $_.Name.trimend(".pre"); 
    $expected = $_.Name.trimend(".pre") + ".expected"; 
    
    $actualContent = (gc $actual | out-string ) ;
    $expectedContent = (gc $expected | out-string );
    if ($actualContent -ne $expectedContent) {
        $testsFailed = $testsFailed + 1;
        write-host "$actual FAIL." -foregroundcolor "red";
    } else {
        write-host "$actual Passed." -foregroundcolor "green";
    }    
 }
 
 write-host "$testsRun tests run, $testsFailed failed";