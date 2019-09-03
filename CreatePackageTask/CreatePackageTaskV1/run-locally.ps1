$sourceDirectory ="${PSScriptRoot}\..\..\msdeploy\base" 
$outputDirectory = "${PSScriptRoot}\..\..\msdeploy\out"
$previousBuildArtifactLocation = ""

$roles = @();
$standalone = $True
$cd = $True
$cm = $True
$rep = $False
$prc = $False
$exm = $False

if($standalone) { $roles += "Standalone" }
if($cd) { $roles += "CD" }
if($cm) { $roles += "CM" }
if($rep) { $roles += "PRC" }
if($prc) { $roles += "REP" }
if($exm) { $roles += "EXM" }

$ps = "$PSScriptRoot\run-createPackage.ps1"
.$ps -sourceDirectory $sourceDirectory -roles $roles -previousBuildArtifactLocation $previousBuildArtifactLocation -output $outputDirectory