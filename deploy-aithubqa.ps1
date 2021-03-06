<#
.Synopsis
   	   AIT Hub Deploy Script
.DESCRIPTION
	   pshell script that will deploy a new AIT HUB Release, 
	   credential are managed within the script and will be prompted when needed
	   DB script are loaded with pshell SQLServer module
	   the file will be managed through remote ps session and copy item
	   a compare will be made between file in the release to file in destination and update if needed
	   if conflict of version prompt will be made to ask admin for manual input about which version keep
	   
.EXAMPLE
	   ./deploy-aithubqa.ps1 -releasefile hub.1.7.3.v3.zip
.NOTES
   	   Version 0.5
       
   	   Written by Arnaud Leresche
#>
#=========================================================================================================================================================================
# Parameters 
#=========================================================================================================================================================================
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $releasefile 
)
#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Main Variables
#=========================================================================================================================================================================
# Servers Infos
$dbServer = "172.18.223.191"
$webServer = "10.1.1.1"
# Path for release zip file
$fullpath = "$PWD\$releasefile"
$releaseVersion = $releasefile -replace ".zip",""
$deployedrelease = $fullpath -replace ".zip",""
# Credential 
$inputCred = Join-Path $PWD.ToString()".\Cache_login.xml"
#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Init and Pre check tests  
#=========================================================================================================================================================================
# Remove all existing Powershell sessions  
Get-PSSession | Remove-PSSession

# Test if SQL pshell module is present, install it if not the case
if ( $(Get-InstalledModule -Name "SqlServer" -ErrorAction SilentlyContinue) -eq $null ) {
	Write-host "Module MS SQL is missing...`n" -ForegroundColor Red
	Write-host "Installing SQL module..." -ForegroundColor Cyan
	Install-Module -Name SqlServer 
}

# Test if Release file exists
if(![System.IO.File]::Exists($fullpath)){
	write-host "No Release Found !`n`nmake sure a release zip file is present and named HUB.x.x.x" -ForegroundColor Red
	Exit
}

#No cache found asking for Credential
if(![System.IO.File]::Exists($inputCred)){
	write-host "No Credential Found, creating cache..." -ForegroundColor Red
	write-host "Please provide Credential :" -ForegroundColor Cyan  
    Get-Credential | Export-Clixml $inputCred
}
# loading XML credential file
$UsrCredential = Import-Clixml $inputCred

# Uncompress Zip file for release
if (![System.IO.Directory]::Exists($deployedrelease)){
	write-host "Extracting release zip file....`nPlease wait" -ForegroundColor Magenta
	Add-Type -assembly "system.io.compression.filesystem"
	[io.compression.zipfile]::ExtractToDirectory($fullpath, $deployedrelease)
}
#=========================================================================================================================================================================
#=========================================================================================================================================================================
# Function Database Deploy 
#=========================================================================================================================================================================
function set-aitDB{
	Get-ChildItem -Path $deployedrelease"\01 - Database\Configuration\" | ForEach-Object {
		$inputfilepath = $deployedrelease+"\01 - Database\Configuration\"+$_.Name
		$queryname = $_.Name
		# Invoke query on Hub DB
		try {
			Invoke-Sqlcmd -InputFile $inputfilepath -ServerInstance $dbServer -Username $UsrCredential.Username -Password $UsrCredential.GetNetworkCredential().password`
			| Out-File -filePath $PWD.Path"\result_$queryname.rpt" 
		}
		catch {
			write-host "There was an error in the sql file $queryname, please correct and try again" -ForegroundColor Red
		}
	}
	write-host "SQL script deployed, you can check results in the rpt files" -ForegroundColor Magenta
}

#=========================================================================================================================================================================
# Function Web Service deploy
#=========================================================================================================================================================================
function set-aitWebSrv {
	$WebServerSession = New-PSSession -Name "WebAIT" -ComputerName $webServer -Credential $UsrCredential
	# Retrieve files and directories on Remote and from zipped content
	$refRelease = Invoke-Command -session $WebServerSession -ScriptBlock {Get-ChildItem-Path "D:\inetpub\wwwroot\" -Recurse}
	$Ziprelease = Get-ChildItem -Path $deployedrelease"\02 - Windows Services\" -Recurse
	# Compare files and copy it if name and size are different
 	compare-object $refRelease $ZipRelease -Property Name,Length | Where-Object {$_.SideIndicator -eq "<="} | foreach-object {
		Copy-Item -ToSession $WebServerSession -Path $deployedrelease"\02 - Windows Services\"$_.Name -Destination "D:\inetpub\wwwroot\"
	}
	write-host "Web Content deployed" -ForegroundColor Magenta
	Get-PSSession | Remove-PSSession
}
#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Function Web Content deploy
#=========================================================================================================================================================================
function set-aitWebContent {
	$WebServerSession = New-PSSession -Name "WebAIT" -ComputerName $webServer -Credential $UsrCredential
	# Retrieve files and directories on Remote and from zipped content
	$refRelease = Invoke-Command -session $WebServerSession -ScriptBlock {Get-ChildItem-Path "D:\inetpub\wwwroot\" -Recurse}
	$Ziprelease = Get-ChildItem -Path $deployedrelease"\03 - Web Applications\" -Recurse
	# Compare files and copy it if name and size are different
 	compare-object $refRelease $ZipRelease -Property Name,Length | Where-Object {$_.SideIndicator -eq "<="} | foreach-object {
		Copy-Item -ToSession $WebServerSession -Path $deployedrelease"\03 - Web Applications\"$_.Name -Destination "D:\inetpub\wwwroot\"
	}
	write-host "Web Content deployed" -ForegroundColor Magenta
	Get-PSSession | Remove-PSSession
}
#=========================================================================================================================================================================
# Cleaning sessions
#=========================================================================================================================================================================
function close-deploy {
	write-host "Deployment Completed" -ForegroundColor Cyan
	Get-PSSession | Remove-PSSession
	exit
}
#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Menu Deploy 
#=========================================================================================================================================================================
# 
function Show-MenuConnect {
	Write-Host "================ AIT Hub PsDeploy ================" -ForegroundColor Cyan
	Write-Host "==================================================" -ForegroundColor Cyan
	Write-host "AIT HUB Deploying : $releaseVersion" -ForegroundColor Cyan
	write-host "QA ENV Script" -ForegroundColor Cyan
	Write-Host "=================== Options ======================" -ForegroundColor Cyan
	Write-Host "==================================================" -ForegroundColor Cyan
	Write-Host "1: Press '1' Deploy Databases" -ForegroundColor Cyan
	Write-Host "2: Press '2' Deploy Web Services"  -ForegroundColor Cyan
	Write-host "3: Press '3' Change Web Contents" -ForegroundColor Cyan
	Write-Host "Q: Press 'Q' to quit." -ForegroundColor Cyan
}
do {
	Show-MenuConnect
	write-host "`nPlease make a selection" -ForegroundColor Cyan
	$input = Read-Host
	switch ($input)
	{
		  '1' {write-host 'You chose option #1' -ForegroundColor Cyan} 
		  '2' {write-host 'You chose option #2' -ForegroundColor Cyan}
		  '3' {write-host 'You chose option #3' -ForegroundColor Cyan}
		  'q' {
			   #Cleaning sessions
			   write-host "aborting..." -ForegroundColor Cyan
			   close-deploy
			  }
	}
}
until ($input -eq 'q' -or $input -eq '1'-or $input -eq '2'-or $input -eq '3')
#=========================================================================================================================================================================


#=========================================================================================================================================================================
# Database Modification
#=========================================================================================================================================================================
# Loop through all SQL script in Configuration repo
if ($input -eq "1"){
	# Deploy function for DB
	set-aitDB
	# Test to leave or return to menu
	do {
		write-host "Return to Menu ? yes (y) or no (n) : " -ForegroundColor Magenta
		$read = read-host
	} 
	until ($read -eq 'y' -or $read -eq 'n')
	if ($read -eq 'y'){
		Show-MenuConnect
	}
	elseif ($read -eq 'n'){
		close-deploy
	}
}

#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Services Modification
#=========================================================================================================================================================================
#
if ($input -eq "2"){
	# Deploy function for Web Service
	set-aitWebSrv
	# Test to leave or return to menu
	do {
		write-host "Return to Menu ? yes (y) or no (n) : " -ForegroundColor Magenta
		$read = read-host
	} 
	until ($read -eq 'y' -or $read -eq 'n')
	if ($read -eq 'y'){
		Show-MenuConnect
	}
	elseif ($read -eq 'n'){
		close-deploy
	}
}
#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Web Content Modification
#=========================================================================================================================================================================
#
if ($input -eq "3"){
	# Deploy function for Web Content
	set-aitWebContent
	# Test to leave or return to menu
	do {
		write-host "Return to Menu ? yes (y) or no (n) : " -ForegroundColor Magenta
		$read = read-host
	} 
	until ($read -eq 'y' -or $read -eq 'n')
	if ($read -eq 'y'){
		Show-MenuConnect
	}
	elseif ($read -eq 'n'){
		close-deploy
	}
}
#=========================================================================================================================================================================

