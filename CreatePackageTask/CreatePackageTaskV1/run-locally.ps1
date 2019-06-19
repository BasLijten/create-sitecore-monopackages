$sourceDirectory ="c:\msdeploy\base" 
$outputDirectory = "c:\msdeploy\out"
$previousBuildArtifactLocation = ""

$roles = @();
$single = $False
$cd = $True
$cm = $True
$rep = $False
$prc = $False
$exm = $False

if($single) { $roles += "Single" }
if($cd) { $roles += "CD" }
if($cm) { $roles += "CM" }
if($rep) { $roles += "PRC" }
if($prc) { $roles += "REP" }
if($exm) { $roles += "EXM" }

.\run-createPackage.ps1 -sourceDirectory $sourceDirectory -roles $roles -previousBuildArtifactLocation $previousBuildArtifactLocation -output $outputDirectory 