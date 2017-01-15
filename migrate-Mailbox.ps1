<#
.SYNOPSIS
   	Connect through Exchange web services read mailbox content
.DESCRIPTION
   	Connect OWA, and retrieve mailbox content
    First version view content only
.EXAMPLE
	./migrate-mailbox.ps1
.NOTES
    author      :   arnaud leresche
    version     :   0.1
#>

<#
.INIT
#>
write-host "======================= Mailbox Tool =============================" -ForegroundColor Yellow
#Load Exchange web service DLL
Add-Type -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

<#
.Test Call back URL for Autodiscover redirect
#>
$TestUrlCallback = {
 param ([string] $url)
 if ($url -eq "https://autodiscover-s.outlook.com/autodiscover/autodiscover.xml") {$true} else {$false}
}

<#
.MAIN CODE
#>
#set up EWS Source connector
write-host "Source Endpoint setup" -ForegroundColor Yellow
$ewsSrc = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService -ArgumentList "Exchange2007_SP1"
#set up credential
$credSrc = (Get-Credential).GetNetworkCredential()
$ewsSrc.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $credSrc.UserName, $credSrc.Password, $credSrc.Domain
#Specify Mailbox (auto discover will configure the correct exchange infos)
$ewsSrc.AutodiscoverUrl( ( Read-Host "Enter mailbox (email address)" ) )

#set up EWS Destination connector
write-host "Destination Endpoint setup" -ForegroundColor Yellow
$ewsDest = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService -ArgumentList "Exchange2007_SP1"
#set up credential
$credDest = (Get-Credential).GetNetworkCredential()
$ewsDest.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $credDest.UserName, $credDest.Password, $credDest.Domain
$ewsDest.AutodiscoverUrl( ( Read-Host "Enter mailbox (email address)" ),$TestUrlCallback)

write-host "EWS endpoint configured`nReading Source Endpoint..." -ForegroundColor Yellow
#finding 10 first items in Inbox
$results = $ewsSrc.FindItems(
	"Inbox",
	( New-Object Microsoft.Exchange.WebServices.Data.ItemView -ArgumentList 10 )
)
#Display Result
$results.Items | ForEach-Object { $_.Subject }

#Migrate them
write-host "Adding items in destination endpoint" -ForegroundColor Yellow
#import loop
$results.Items | ForEach-Object {
    
    $ewsDest.createitems($_)
}