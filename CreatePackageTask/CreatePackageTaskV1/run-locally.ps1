$sourceDirectory ="c:\msdeploy\base" 
$roles = "CD" 
$outputDirectory = "c:\msdeploy\out"
$previousBuildArtifactLocation = ""

.\run-createPackage.ps1 -sourceDirectory $sourceDirectory -roles $roles -previousBuildArtifactLocation $previousBuildArtifactLocation -output $outputDirectory 