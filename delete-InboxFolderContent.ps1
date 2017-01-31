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


#set up EWS  connector
write-host "Endpoint setup" -ForegroundColor Yellow
$ews = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService -ArgumentList "Exchange2007_SP1"
#set up credential
$cred = (Get-Credential).GetNetworkCredential()
$ews.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $credDest.UserName, $credDest.Password, $credDest.Domain
$ews.AutodiscoverUrl( ( Read-Host "Enter mailbox (email address)" ),$TestUrlCallback)

write-host "EWS endpoint configured`nReading Source Endpoint..." -ForegroundColor Yellow
#finding 10 first items in Inbox
$results = $ews.FindItems(
	"Inbox",
	( New-Object Microsoft.Exchange.WebServices.Data.ItemView -ArgumentList 10 )
)
#Display Result
$results.Items | ForEach-Object { $_.Subject }

		#[void]$_.Delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::HardDelete)

