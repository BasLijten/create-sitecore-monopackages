param(
    [Parameter(Mandatory=$True)]
    [string]$sourceDirectory,
    [Parameter(Mandatory=$False)]
    [string]$roles = "",
    [Parameter(Mandatory=$False)]
    [string]$previousBuildArtifactLocation,
    [Parameter(Mandatory=$True)]
    [string]$outputDirectory    
)

if(!$workingFolder)
{
    $workingFolder = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
}
#import assemblies
Add-Type -Path "${PSScriptRoot}\Microsoft.Web.XmlTransform.dll"

