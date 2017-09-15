<#
.SYNOPSIS
   	Connect through EWS and delete Inbox folder content of a mailbox
.DESCRIPTION
   	Connect OWA, and retrieve mailbox content
    delete this content 
.EXAMPLE
	./migrate-mailbox.ps1
     this will execute the script, you will be prompted for admin account and the email address of the mailbox you want to access
.NOTES
    author      :   arnaud leresche
    version     :   0.1
#>

<#
.INIT - load Exchange DLL to access EWS API
#>
write-host "======================= Mailbox Cleaning Tool =============================" -ForegroundColor Cyan
#Load Exchange web service DLL
Add-Type -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
$FoldertoClean = "Inbox"
$AdminEmail = "arnaud.leresche@alvean.onmicrosoft.com"
$MailboxToImpersonate = "janine.wang@alvean.onmicrosoft.com"
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
write-host "Configuring EWS API access..." -ForegroundColor Cyan
$ews = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService -ArgumentList "Exchange2010"
#set up credential
write-host "Provide Admin credential" -ForegroundColor Cyan
$cred = (Get-Credential).GetNetworkCredential()
$ews.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $cred.UserName, $cred.Password, $cred.Domain
#Specify Email of admin account
$ews.AutodiscoverUrl($AdminEmail,$TestUrlCallback)
#select mailbox to clean
$ews.ImpersonateUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress,$MailboxToImpersonate);
#bind mailbox to clean to service
$InboxFolder= new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox,$ImpersonatedMailboxName)
$Inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($ews,$InboxFolder)
write-host "EWS endpoint configured`nPreparing to delete content..." -ForegroundColor Cyan
#Lopping to retrieve items inside Inbox folder
$results = $ews.FindItems(
	$FoldertoClean,
	( New-Object Microsoft.Exchange.WebServices.Data.ItemView -ArgumentList 10 )
)
#Looping to delete all content inside Inbox 
$results.Items | ForEach-Object {
        write-host "deleting.... " $_.subject -ForegroundColor Magenta         
		#[void]$_.Delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::HardDelete)
}