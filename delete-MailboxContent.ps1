<#
.SYNOPSIS
   	Connect through EWS and delete Inbox folder content of a mailbox
.DESCRIPTION
   	Connect OWA, and retrieve content from a specific folder inside mailbox and hard delete them
.EXAMPLE
	./delete-MailboxContent
    
    this will execute the script, you will be prompted for admin account and the email address of the mailbox you want to Access
    ----------------------------------------------------------------------------------------------------------------------------

    ./delete-MailboxContent -MailboxToImpersonate jon.poulet@xxx.onmicrosoft.com -TargetFolder Inbox

    this will execute the script to delete content of inbox for Jon Poulet user
    ----------------------------------------------------------------------------------------------------------------------------
.NOTES
    author      :   arnaud leresche
    version     :   1.0
#>
######################################################################################################################################################################################################
#Parameters
######################################################################################################################################################################################################
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $MailboxToImpersonate,
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Targetfolder  
)
#######################################################################################################################################################################################################
#Variables
#######################################################################################################################################################################################################
## Define UPN of the Account that has impersonation rights
$AccountWithImpersonationRights = "arnaud.leresche@alvean.onmicrosoft.com"
## Define DLL for exchange webservices
$dllpath = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
## Define Path for login cache file
$inputCred = Join-Path $PWD.ToString()".\Cache_DMC.xml" 
#######################################################################################################################################################################################################
#INIT
#######################################################################################################################################################################################################
## test Parameters
if ($MailboxToImpersonate -eq $null) {
    ## prompt for Email address of mailbox to access
    write-host "no mailbox to check was defined..." -ForegroundColor Yellow
    $MailboxToImpersonate = (read-host "Enter Email address of mailbox to check : ")
}

if ($Targetfolder -eq $null ){
    ## Define default folder to look if none was specified in params
    $FoldertoClean = "Inbox"
}
else {
    $FoldertoClean = $Targetfolder
}
## Import EWS DLL
Import-Module $dllpath
## Set Exchange Version
$ExchangeVersion = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013
## Create Exchange Service Object
$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion)


write-host "============= Mailbox Deleting content Tool ==================`n==============================================================" -ForegroundColor Yellow 
write-host "Preparing connection to EWS Endpoint...." -ForegroundColor Yellow            

## test if Cache for credential exists
if(![System.IO.File]::Exists($inputCred)){
    write-host "No Credential Found, creating cache..." -ForegroundColor Yellow
    Get-Credential | Export-Clixml $inputCred
}

## Get valid Credentials using UPN for the ID that is used to impersonate mailbox
#$psCred = Get-Credential
$psCred = Import-Clixml $inputCred
$creds = New-Object System.Net.NetworkCredential($psCred.UserName.ToString(),$psCred.GetNetworkCredential().password.ToString())
$service.Credentials = $creds

## Set the URL of the CAS (Client Access Server)
$service.AutodiscoverUrl($AccountWithImpersonationRights ,{$true})


#######################################################################################################################################################################################################
#MAIN
#######################################################################################################################################################################################################
## Login to Mailbox with Impersonation
Write-Host 'Using ' $AccountWithImpersonationRights ' to Impersonate ' $MailboxToImpersonate -ForegroundColor Yellow
$service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress,$MailboxToImpersonate );

## Connect to the Inbox and display basic statistics
$InboxFolder= new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox,$ImpersonatedMailboxName)
$Inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,$InboxFolder)

## List number of items in inbox
Write-Host 'Total Item count for Inbox:' $Inbox.TotalCount -ForegroundColor Yellow

if ($Inbox.TotalCount > 10000 ){
    write-host "WARNING  :  Items count for Inbox is more than 10k items, aborting...."
    exit
}

$results = $Inbox.FindItems(
	$FoldertoClean,
	( New-Object Microsoft.Exchange.WebServices.Data.ItemView -ArgumentList 10000 )
)
$results.Items | ForEach-Object {
        write-host "Moving..." $_.subject -ForegroundColor Magenta         
		#[void]$_.Delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::HardDelete)
}