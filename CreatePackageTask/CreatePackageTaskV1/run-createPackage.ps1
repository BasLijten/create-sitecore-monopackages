param(
    [Parameter(Mandatory=$True)]
    [string]$sourceDirectory,
    [Parameter(Mandatory=$False)]
    $roles = "",
    [Parameter(Mandatory=$False)]
    [string]$previousBuiltArtifactLocation,
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

if($previousBuiltArtifactLocation -eq "")
{
    Write-Host "no previous artifact specified. This will slow down deployments becvause of the use of a fresh build package"
}
else
{
    Write-Host "using $previousBuiltArtifactLocation as archive which will be updated for fast deployments"
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

    if (!(Test-Path "$outputDirectory\$role")) {
        New-Item -ItemType directory -Path "$outputDirectory\$role"
    }

    Copy-Item "$outputDirectory\web.$role.config" -Destination "$outputDirectory\$role\web.config"
    
    $PackageDestinationPath = "$outputDirectory\webdeploy.$role.zip"
    
    # create web deploy package
    $verb = "-verb:sync"

    $match = "$outputDirectory\$role".Replace("\", "\\")
    $sourceParameter = "-source:contentPath=`"$outputDirectory\$role`""
    
    $declareParamFilePath = "$outputDirectory\parameters.$role.xml"
    $declareParamFileParameter = "-declareparamfile=`"$($declareParamFilePath)`""
    
    ## the matchable parameter has to be injected over here, in order to be matched by the replace rule
    $declareParam = "-declareparam:name=`"IIS Web Application Name`",kind=ProviderPath,scope=contentpath,match=$match"
    $replace="-replace:match=`"$match`",replace=`"website`""

    $destination = "-dest:package=`"$($PackageDestinationPath)`""

    $skipDbFullSQL = "-skip:objectName=dbFullSql"
    $skipDbDacFx = "-skip:objectName=dbDacFx"

    $expression = "& '$msdeploy' --% $verb $sourceParameter $destination $declareParamFileParameter $declareParam $skipDbFullSQL $skipDbDacFx $replace -useChecksum"

    Invoke-Expression $expression
    Write-Output ""
}

Function Create-WDPS
{    
    foreach($role in $roles)
    {
        Write-Output ""
        ## Gather all 'deep' parameters files to merge for the specific role
        $roleParametersFiles = Get-ChildItem -Path "$sourceDirectory\parameters.*$role.xml" -Recurse -Force
        $destinationParametersFile = "$outputDirectory\parameters.$role.xml"

        Write-Output "Merging parameter files for role $($role) to $($destinationParametersFile)"
        Write-Output "$($roleParametersFiles.Length) files found for role $($role)"
        
        # Remove the old parameters file first
        if (Test-Path($destinationParametersFile)){
            Remove-Item -Path "$destinationParametersFile" -Force
        }

        foreach ($roleParameterFile in $roleParametersFiles) {
            Merge-XML -sourceFile "$roleParameterFile" -destinationFile "$destinationParametersFile"
        }

        Write-Output ""

        ## Gather all 'deep' web config files to merge for the specific role
        $roleWebConfigFiles = Get-ChildItem -Path "$sourceDirectory\web.*$role.config" -Recurse -Force
        $destinationWebConfigFile = "$outputDirectory\web.$role.config"

        Write-Output "Merging web.XXX.config files for role $($role) to $($destinationWebConfigFile)"
        Write-Output "$($roleWebConfigFiles.Length) files found for role $($role)"
        
        # Prepare the output configuration file
        Copy-Item "$sourceDirectory\web.config" "$outputDirectory\web.$role.config"

        foreach ($roleWebConfigFile in $roleWebConfigFiles) {
            TransForm-Xml -sourceFile "$outputDirectory\web.$role.config" -transformFile $roleWebConfigFile -outputFile "$outputDirectory\web.$role.config"
        }
        
        Write-Output ""

        $stopwatch =  [system.diagnostics.stopwatch]::StartNew() 

        if (Test-Path "$outputDirectory\webdeploy.$role.zip") {
            Write-Host "webdeploy.$role.zip is already there. Building package should be really fast"
        }
        else {
            Write-Host "no package yet. Looking in archive folder"
        }
        
        $archive = "$previousBuiltArtifactLocation\webdeploy.$role.zip"
        
        if(Test-Path $archive)
        {
            Copy-Item -Path $archive -Destination "$outputDirectory\webdeploy.$role.zip"
            Write-Host "$role package copied from archive"           
        }
        else
        {
            Write-Host "no $role package available. Slow package time"
        }
        
        Create-WDP -role $role

        $stopwatch.Stop();
        $elapsedTime = $stopwatch.Elapsed.TotalSeconds

        Write-Host "Created WDP for $role in: $elapsedTime"

        Write-Output ""
    }
}


Create-WDPS