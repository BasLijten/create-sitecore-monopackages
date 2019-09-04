$sourceDirectory = (Get-Item "${PSScriptRoot}\..\..\testinput\base").FullName
$outputDirectory = (Get-Item "${PSScriptRoot}\..\..\msdeploy\out").FullName

$previousBuiltArtifactLocation = ""
if (Test-Path -Path "${PSScriptRoot}\..\..\testinput\PreviouslyBuiltArtifacts") {
    $previousBuiltArtifactLocation = (Get-Item "${PSScriptRoot}\..\..\testinput\PreviouslyBuiltArtifacts").FullName
}

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
if($exm) { $roles += "DDS" }

$ps = "$PSScriptRoot\run-createPackage.ps1"
.$ps -sourceDirectory $sourceDirectory -roles $roles -previousBuiltArtifactLocation $previousBuiltArtifactLocation -output $outputDirectory