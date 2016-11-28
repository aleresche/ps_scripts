<#
.Synopsis
   	Connect To MS Online Cloud Services (O365,MsOnline,SkypeOnline)
.DESCRIPTION
   	Connect to MS Online Cloud Services including the following subservice :
    - Exchange Online (Office 365)
    - Azure AD (MS Online)
    - Skype for Business (SkypeforbusinessOnline)
.EXAMPLE
	./Connect-ExchangeOnline.ps1
.NOTES
   	Version 1.5 new feat.
    - Login management rework
    - UI rework
    - Test for MS cloud module  
   	Written by Arnaud Leresche
#>
#Parameters
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Username,  
    [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Password,
    [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Domain  
)
#Remove all existing Powershell sessions  
Get-PSSession | Remove-PSSession

#Did they provide creds?  If not, ask them for it. 
if (([string]::IsNullOrEmpty($Username) -eq $false) -and ([string]::IsNullOrEmpty($Password) -eq $false)) 
{ 
    $SecurePassword = ConvertTo-SecureString -AsPlainText $Password -Force
    #Build credentials object  
    $UserCredential  = New-Object System.Management.Automation.PSCredential $Username, $SecurePassword
} 
else 
{ 
    #Build credentials object
    write-host "Requesting credential..."  -ForegroundColor Yellow
    $UserCredential  = Get-Credential
}

#Establishing Session
write-host "Loading Online Session...." -ForegroundColor Yellow
$Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber | Out-Null
write-host "Online session established !" -ForegroundColor Yellow

