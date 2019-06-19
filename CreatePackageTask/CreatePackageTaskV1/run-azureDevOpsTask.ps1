Write-Verbose "Entering script run-azureDevOpsTask.ps1"

$sourceDirectory = Get-VstsInput -Name SourceDirectory
$roles = Get-VstsInput -Name Roles
$single = Get-VstsInput -Name Single -AsBool
$cd = Get-VstsInput -Name CD -AsBool
$cm = Get-VstsInput -Name CM -AsBool
$rep = Get-VstsInput -Name PRC -AsBool
$prc = Get-VstsInput -Name REP -AsBool
$exm = Get-VstsInput -Name EXM -AsBool
$previousBuildArtifactLocation = Get-VstsInput -Name PreviousBuildArtifactLocation
$outputDirectory = Get-VstsInput -Name OutputDirectory 

$roles = @()
if($single) { $roles += "Single" }
if($cd) { $roles += "CD" }
if($cm) { $roles += "CM" }
if($rep) { $roles += "PRC" }
if($prc) { $roles += "REP" }
if($exm) { $roles += "EXM" }

.\run-createPackage.ps1 -sourceDirectory $sourceDirectory -roles $roles -previousBuildArtifactLocation $previousBuildArtifactLocation -outputDirectory $outputDirectory

