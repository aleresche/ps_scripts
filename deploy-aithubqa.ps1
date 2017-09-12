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
## Parameters 
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $releasePath 
)
