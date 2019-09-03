param(
    [Parameter(Mandatory=$True)]
    [string]$sourceDirectory,
    [Parameter(Mandatory=$False)]
    $roles = "",
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
Add-Type -Path "${PSScriptRoot}\..\..\buildAndReleaseTask\Microsoft.Web.XmlTransform.dll"

$regkey = "\SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3\"
$item = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE$regkey" -Name "InstallPath"
$msdeployExecutableName = "msdeploy.exe"
$fullMsdeployPath = $item.InstallPath + $msdeployExecutableName

Write-Host "Using $sourceDirectory as source location"
if($roles -eq "")
{
    Write-Host "roles are empty. Trying to determine what roles to build"
}
else
{
    Write-Host "$roles"
}

if($previousBuildArtifactLocation -eq "")
{
    Write-Host "no previous artifact specified. This will slow down deployments becvause of the use of a fresh build package"
}
else
{
    Write-Host "using $previousBuildArtifactLocation as archive which will be updated for fast deployments"
}

Write-Host "results can be found at $outputDirectory"

$msdeploy = $fullMsdeployPath

if(!(Test-Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory
    Write-Host "Created $outputDirectory"
}

Function Merge-XML
{
    param(
        [string]$sourceFile,
        [string]$destinationFile
    )
        if (!(Test-Path -Path $destinationFile))
        {
            New-Item $destinationFile -ItemType file -Value "<parameters/>"
        }

        Write-Output "Merging $($sourceFile)"

        $finalXml = "<parameters>"
    
        [xml]$xml = Get-Content $sourceFile    
        $finalXml += $xml.parameters.InnerXml    

        [xml]$xml = Get-Content $destinationFile
        $finalXml += $xml.parameters.InnerXml
        $finalXml += "</parameters>"
    ([xml]$finalXml).Save($destinationFile)
}

Function TransForm-Xml
{
    param(
        [string]$sourceFile,
        [string]$transformFile,
        [string]$outputFile
    )

    if (!(Test-Path $sourceFile))
    {
        Write-Error "File '${sourceFile}' not found."
        
        return
    }

    if (!(Test-Path $transformFile))
    {
        Write-Error "File '${transformFile}' not found."
        
        return
    }

    Write-Host "Applying transformations '${transformFile}' on '${sourceFile}' to '${outputFile}'..."
    
    $source = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
    $source.PreserveWhitespace = $true
    $source.Load($sourceFile)

    $transform = [System.IO.File]::ReadAllText($transformFile)
    $transformation = New-Object Microsoft.Web.XmlTransform.XmlTransformation $transform, $false, $null
    if (!$transformation.Apply($source))
    {
        Write-Error "Error while applying transformations '${transformFile}'."

        return
    }

    # save output
    $outputParent = Split-Path $OutputFile -Parent
    if (!(Test-Path $outputParent))
    {
        Write-Verbose "Creating folder '${outputParent}'."

        New-Item -Path $outputParent -ItemType Directory -Force > $null
    }

    $source.Save($outputFile)
}

Function Create-WDP
{
    param (
        [string]$role
    )

    Copy-Item "$outputDirectory\web.$role.config" -Destination $sourceDirectory\web.config
    
    $PackageDestinationPath = "$outputDirectory\webdeploy.$role.zip"
    
    # create web deploy package
    $verb = "-verb:sync"

    $match = $sourceDirectory.Replace("\", "\\")
    $sourceParameter = "-source:contentPath=`"$sourceDirectory`""


    $declareParamFilePath = "$outputDirectory\parameters.$role.xml"
    $declareParamFileParameter = "-declareparamfile=`"$($declareParamFilePath)`""
    
    ## the matchable parameter has to be injected over here, in order to be matched by the replace rule
    $declareParam = "-declareparam:name=`"IIS Web Application Name`",kind=ProviderPath,scope=contentpath,match=$match"
    $replace="-replace:match=`"$match`",replace=`"website`""


    $destination = "-dest:package=`"$($PackageDestinationPath)`""

    $skipDbFullSQL = "-skip:objectName=dbFullSql"
    $skipDbDacFx = "-skip:objectName=dbDacFx"

    Invoke-Expression "& '$msdeploy' --% $verb $sourceParameter $destination $declareParamFileParameter $declareParam $skipDbFullSQL $skipDbDacFx $replace -useChecksum"

    #Copy-Item "C:\msdeploy\output\webdeploy.$role.zip" 
}

Function Create-WDPS
{    
    foreach($role in $roles)
    {
        Write-Output ""
        Write-Output "Merging files for role $($role) to $($destinationFile)"
        ## Gather all 'deep' parameters files to merge for the specific role
        $roleFiles = Get-ChildItem -Path "$sourceDirectory\parameters.*$role.xml" -Recurse -Force
        $destinationFile = "$outputDirectory\parameters.$role.xml"

        Write-Output "$($roleFiles.Length) files found for role $($role)"
        
        foreach ($roleFile in $roleFiles) {
            Merge-XML -sourceFile "$roleFile" -destinationFile "$destinationFile"
        }
        
        # TransForm-Xml -sourceFile "$sourceDirectory\web.base.config" -transformFile "$sourceDirectory\web.helix.$role.config" -outputFile "$outputDirectory\web.$role.config"

        # $stopwatch =  [system.diagnostics.stopwatch]::StartNew() 

        # if(Test-Path "$outputDirectory\webdeploy.$role.zip") {
        #     Write-Host "webdeploy.$role.zip is already there. Building package should be really fast"
        # }
        # else
        # {
        #     Write-Host "no package yet. Looking in archive folder"
        # }
        
        # $archive = "previousBuildArtifactLocation\webdeploy.$role.zip"
        # if(Test-Path $archive)
        # {
        #     Copy-Item -Path $archive -Destination "$outputDirectory\webdeploy.$role.zip"
        #     Write-Host "$role package copied from archive"           
        # }
        # else
        # {
        #     Write-Host "no $role package available. Slow package time"
        # }

        
        # Create-WDP -role $role

        # $stopwatch.Stop();
        # $elapsedTime = $stopwatch.Elapsed.TotalSeconds

        # Write-Host "Created WDP for $role in: $elapsedTime"cls

        Write-Output ""
    }
}


Create-WDPS