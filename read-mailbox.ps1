<#
.SYNOPSIS
   	Connect through EWS to read mailbox
.DESCRIPTION
   	Connect OWA, and retrieve content from a specific folder inside mailbox
.EXAMPLE
	./read-mailbox.ps1 -mailaddress john.doe@microsoft.com

.NOTES
    author      :   arnaud leresche
    version     :   1.0
#>
######################################################################################################################################################################################################
#Parameters
######################################################################################################################################################################################################
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $emailaddress,
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [int] $MailNbrs
)
# Load Exchange DLL for EWS Service
Add-Type -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
## Define Path for login cache file
$inputCred = Join-Path $PWD.ToString()"Cache_login.xml"

## test if Cache for credential exists
if((get-childitem "cache_login.xml") -eq $null ){
    write-host "No Credential Found, creating cache..." -ForegroundColor Cyan
    Get-Credential | Export-Clixml $inputCred
}
# Load Credential
$psCred = Import-Clixml $inputCred
$cred = New-Object System.Net.NetworkCredential($psCred.UserName.ToString(),$psCred.GetNetworkCredential().password.ToString())

#######################################################################################################################################################################################################
#MAIN
#######################################################################################################################################################################################################
$Email = $emailaddress

$EWS = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService -ArgumentList "Exchange2010"
#$cred = (Get-Credential).GetNetworkCredential()
$EWS.Credentials = $cred
#Use Autodiscover to find the right URL endpoint
$EWS.AutodiscoverUrl($Email,{$true})


#Search the inbox
$results = $EWS.FindItems("Inbox",( New-Object Microsoft.Exchange.WebServices.Data.ItemView -ArgumentList 20 ))
$results.Items | ForEach-Object { $_.Subject }

# Create Email
for ($i=0;$i -le $MailNbrs;$i++){
$eMail = New-Object -TypeName Microsoft.Exchange.WebServices.Data.EmailMessage -ArgumentList $EWS
$eMail.Subject = 'EWS Mail sender test '+$i
$eMail.Body = 'This message is being sent through EWS with PowerShell, please discard'
$eMail.ToRecipients.Add($emailaddress) | Out-Null
# Sending email
$eMail.SendAndSaveCopy()
}