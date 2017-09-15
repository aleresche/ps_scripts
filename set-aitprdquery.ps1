<#
.Synopsis
   	Powershell script to remote exec query on AIT HUB
.DESCRIPTION
   	allow push of SQL query into HUB Production Database 
.EXAMPLE
	./set-aitprdquery.ps1
.NOTES
    Version 0.1
    Written by Arnaud Leresche
#>

#Parameters
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Username
)


if ((Get-Command "Invoke-Sqlcmd") -eq $null) {
	Write-host "Module MS SQL is missing..." -ForegroundColor Cyan
	Install-Module -Name SqlServer
}


# Invoke query on HuB PRD
Invoke-Sqlcmd -InputFile $QueryFilePath  -ServerInstance "10.7.12.168" | Out-File -filePath "$PWD\resultSQLCmd.rpt" 
