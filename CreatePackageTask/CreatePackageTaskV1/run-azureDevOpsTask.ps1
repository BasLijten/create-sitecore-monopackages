Write-Verbose "Entering script run-azureDevOpsTask.ps1"

$sourceDirectory = Get-VstsInput -Name SourceDirectory
$roles = Get-VstsInput -Name Roles
$previousBuildArtifactLocation = Get-VstsInput -Name PreviousBuildArtifactLocation
$outputDirectory = Get-VstsInput -Name OutputDirectory 

.\run-createPackage.ps1 -sourceDirectory $sourceDirectory -roles $roles -previousBuildArtifactLocation $previousBuildArtifactLocation -outputDirectory $outputDirectory

