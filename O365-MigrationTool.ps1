<#
.SYNOPSIS
   	PShell application to provide a small GUI to help you transfer Mailboxes from tenant to tenant
.DESCRIPTION
   	Connect using EWS API, and Migrate Mailbox content, both mailboxes must exist, as this will use CLIent SIDE access to migrate content
    GUI in XAML to seperate tasks and make it mor easy to use
.EXAMPLE
	./O365-MigrationTool
.NOTES
    author      :   arnaud leresche
    version     :   1.0
#>
#######################################################################################################################################################################################################
#Variables
#######################################################################################################################################################################################################
## Define UPN of the Account that has impersonation rights
$AccountWithImpersonationRights = "arnaud.leresche@bi4bilab1.onmicrosoft.com"
## Define DLL for exchange webservices
$dllpath = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
## Define Path for login cache file
$inputCred = Join-Path $PWD.ToString()".\Cache_Login.xml" 