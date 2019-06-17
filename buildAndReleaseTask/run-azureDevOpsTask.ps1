Write-Verbose "Entering script run-azureDevOpsTask.ps1"

$sourceDirectory = Get-VstsInput -Name SourceDirectory
$roles = Get-VstsInput -Name Roles
$previousBuildArtifactLocation = Get-VstsInput -Name PreviousBuildArtifactLocation
$outputDirectory = Get-VstsInput -Name Output 

.\run-createPackage.ps1 -rootUrl $sourceDirectory -roles $roles -previousBuildArtifactLocation $previousBuildArtifactLocation -output $outputDirectory 