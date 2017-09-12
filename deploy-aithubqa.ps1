<#
.Synopsis
   	AIT Hub Deploy
.DESCRIPTION
   	pshell script that will deploy a new AIT HUB Release
.EXAMPLE
	./deploy-aithubqa.ps1 -releasepath c:\temp\hub.1.7.0\
.NOTES
   	Version 0.1
       
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
# Init  
#=========================================================================================================================================================================
# Remove all existing Powershell sessions  
Get-PSSession | Remove-PSSession

# Variables
$dbServer = "10.7.12.62"
$webServer = "10.7.12.168"

# Test if SQL pshell module is present, install it if not the case
if ((Get-Command "Invoke-Sqlcmd") -eq $null) {
	Write-host "Module MS SQL is missing..." -ForegroundColor Red
	Install-Module -Name SqlServer
}

# Test if Release file exists
if(![System.IO.File]::Exists($releasefile)){
	write-host "No Release Found !`n`nmake sure a release zip file is present and named HUB.x.x.x" -ForegroundColor Red
	Exit;
}

#No cache found asking for Credential
if(![System.IO.File]::Exists($inputCred)){
	write-host "No Credential Found, creating cache..." -ForegroundColor Red
	write-host "Please provide Credential :" -ForegroundColor Yellow
    $inputCred = Join-Path $PWD.ToString()".\Cache_login.xml"  
    Get-Credential | Export-Clixml $inputCred
}
# loading XML credential file
$UsrCredential = Import-Clixml $inputCred

# Uncompress Zip file for release
$deployedrelease = $releasefile -replace ".zip",""
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory($releasefile, $deployedrelease)
#=========================================================================================================================================================================
#=========================================================================================================================================================================
# Menu Deploy 
#=========================================================================================================================================================================
# 
function Show-MenuConnect {
	Write-Host "================ AIT Hub PsDeploy ================" -ForegroundColor Yellow
	Write-host "AIT HUB version to Deploy : $deployedrelease" -ForegroundColor Yellow
	write-host "Production ENV Script" -ForegroundColor Yellow
	Write-Host "=================== Options ======================" -ForegroundColor Yellow
	Write-Host "1: Press '1' Deploy Databases" -ForegroundColor Yellow
	Write-Host "2: Press '2' Deploy Web Services"  -ForegroundColor Yellow
	Write-host "3: Press '3' Change Web Contents" -ForegroundColor Yellow
	Write-Host "Q: Press 'Q' to quit." -ForegroundColor Yellow
}
do {
	Show-MenuConnect
	write-host "Please make a selection" -ForegroundColor Yellow
	$input = Read-Host
	switch ($input)
	{
		  '1' {write-host 'You chose option #1' -ForegroundColor Yellow} 
		  '2' {write-host 'You chose option #2' -ForegroundColor Yellow}
		  '3' {write-host 'You chose option #3' -ForegroundColor Yellow}
		  'q' {
			   #Cleaning sessions
			   write-host "Closing sessions...`nOperation aborted" -ForegroundColor Yellow
			   Get-PSSession | Remove-PSSession
			   exit
			  }
	}
}
until ($input -eq 'q' -or $input -eq '1'-or $input -eq '2'-or $input -eq '3')
#=========================================================================================================================================================================


#=========================================================================================================================================================================
# Database Modification
#=========================================================================================================================================================================
# Loop through all SQL script in Configuration repo
if ($input -eq "2"){
	Get-ChildItem -Path $deployedrelease"\01 - Database\Configuration\" | ForEach-Object {
		$queryname = $_.Name
		# Invoke query on Hub PRD
		Invoke-Sqlcmd -InputFile $deployedrelease"\01 - Database\Configuration\"$queryname`
		-ServerInstance $dbServer -Username $UsrCredential.Username -Password $UsrCredential.GetNetworkCredential().password | Out-File -filePath $PWD.Path"\result_$queryname.rpt" 
	}
	write-host "SQL script deployed, you can check results in the rpt files"
	Show-MenuConnect
}

#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Services Modification
#=========================================================================================================================================================================
#
$WebServerSession = New-PSSession -Name "WebAIT" -ComputerName $webServer -Credential $UsrCredential
Get-ChildItem -Path $deployedrelease"\02 - Web services\" | ForEach-Object {
	Copy-Item -FromSession $WebServerSession -Path $deployedrelease"\02 - Web services\"$_.Name -Destination "D:\Blue Infinity\Web Services\"$_.Name
}
#=========================================================================================================================================================================

#=========================================================================================================================================================================
# Web Content Modification
#=========================================================================================================================================================================
#
$WebServerSession = New-PSSession -Name "WebAIT" -ComputerName $webServer -Credential $UsrCredential
Get-ChildItem -Path $deployedrelease"\03 - Web Content\" | ForEach-Object {
	Copy-Item -FromSession $WebServerSession -Path $deployedrelease"\01 - Web services\"$_.Name -Destination "D:\inetpub\wwwroot\"$_.Name
}

#=========================================================================================================================================================================
