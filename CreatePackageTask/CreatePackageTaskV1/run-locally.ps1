$sourceDirectory = (Get-Item "${PSScriptRoot}\..\..\testinput\base").FullName
$outputDirectory = (Get-Item "${PSScriptRoot}\..\..\msdeploy\out").FullName

$previousBuildArtifactLocation = ""
if (Test-Path -Path "${PSScriptRoot}\..\..\testinput\PreviouslyBuiltArtifacts") {
    $previousBuildArtifactLocation = (Get-Item "${PSScriptRoot}\..\..\testinput\PreviouslyBuiltArtifacts").FullName
}
$previousBuildArtifactLocation = ""

$roles = @();
$standalone = $True
$cd = $False
$cm = $False
$rep = $False
$prc = $False
$exm = $False

if($standalone) { $roles += "Standalone" }
if($cd) { $roles += "CD" }
if($cm) { $roles += "CM" }
if($rep) { $roles += "PRC" }
if($prc) { $roles += "REP" }
if($exm) { $roles += "DDS" }

$ps = "$PSScriptRoot\run-createPackage.ps1"
.$ps -sourceDirectory $sourceDirectory -roles $roles -previousBuildArtifactLocation $previousBuildArtifactLocation -output $outputDirectory