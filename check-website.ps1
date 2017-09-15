<#
.Synopsis
   	Powershell Script that checks URL availbility
.DESCRIPTION
   	script to Monitor URL availabilty over the web and in local web app
.EXAMPLE
	./check-website.ps1
.NOTES
   	Version 0.1 
   	Written by Arnaud Leresche
#>

## Parameters 
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $url 
)

## Main check
for ($i=0;$i -le 1000;$i++){
    $httpCode = Invoke-WebRequest -uri $url | Select-Object StatusCode
    if ($httpCode = 200){
        write-host "$url is responding correctly (HTTP:$httpcode)" -ForegroundColor Magenta | out-file -filepath ./$url.log -Encoding default
    }
    else{
        write-host "WARNING $url not responding :: ERROR HTTP $httpcode" -ForegroundColor Cyan | out-file -filepath ./$url.log -Encoding default
    }
    start-sleep -s 60
}



