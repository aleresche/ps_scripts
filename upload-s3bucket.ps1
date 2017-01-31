<#
.Synopsis
   	Copy content of a folder to an AWS S3 bucket storage
.DESCRIPTION
    retrieve files from a specific folder and upload them
.EXAMPLE
	./upload-s3bucket.ps1
.NOTES
   	Version 1.0
   	Written by Arnaud Leresche
#>
#############################################################################################################################
#Parameters
#############################################################################################################################
Param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $SelectedPath
)

#############################################################################################################################
#Main Code
#Loop through all the file and upload them, results should only have MS SQL Backup file 
#############################################################################################################################
#Retrieve all files inside specific folder
$results = Get-ChildItem $selectedPath -Recurse -Include "*.bak","*.trn"  
foreach ($path in $results) {
	Write-Host $path
	$filename = [System.IO.Path]::GetFileName($path)
	Write-S3Object -BucketName my-bucket -File $path -Key subfolder/$filename -CannedACLName Private -AccessKey accessKey -SecretKey secretKey
}