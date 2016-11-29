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
    [string] $Password
)
#Remove all existing Powershell sessions  
Get-PSSession | Remove-PSSession
#Introduction
write-host "Preparing Info to setup connection...`nLooking for login cache..." -ForegroundColor Yellow
#Login Management
$inputCred = Join-Path $PWD.ToString()"\..\Cred.xml"  
if(![System.IO.File]::Exists($inputCred)){
    # Connection to tenant - use this only 1st time to collect credentials
    write-host "No Credential Found, creating cache..."
    if (([string]::IsNullOrEmpty($Username) -eq $false) -and ([string]::IsNullOrEmpty($Password) -eq $false)) {
        $SecurePassword = ConvertTo-SecureString -AsPlainText $Password -Force
        #Build credentials object  
        $inputCred  = New-Object System.Management.Automation.PSCredential $Username, $SecurePassword
    }
    else {
         Get-Credential | Export-Clixml $inputCred
    }
}
#load User Admin for display
$AdmUsr = get-content ..\Cred.xml | select-string "UserName"
$AdmUsr = $AdmUsr -replace '<S N="UserName">'; ''
$AdmUsr = $AdmUsr -replace '</S>'; ''
$Domain = $AdmUsr -split '@'
# Set this variable to the location of the file where credentials are cached
$UsrCredential = Import-Clixml $inputCred

# Menu multiple choice to guide the user
function Show-Menu {
     Write-Host "================ Connecting ================" -ForegroundColor Yellow
     Write-host "Connecting on Tenant : $($Domain[1])" -ForegroundColor Yellow
     Write-Host "1: Press '1' Connect to O365 only" -ForegroundColor Yellow
     Write-Host "2: Press '2' Connect to O365 & MS Online"  -ForegroundColor Yellow
     Write-host "3: Press '3' Change admin login"
     Write-Host "Q: Press 'Q' to quit." -ForegroundColor Yellow
}
do {
     Show-Menu
     write-host "Please make a selection" -ForegroundColor Yellow
     $input = Read-Host
     switch ($input)
     {
           '1' {write-host 'You chose option #1' -ForegroundColor Yellow} 
           '2' {write-host 'You chose option #2' -ForegroundColor Yellow}
           '3' {write-host 'You chose option #2' -ForegroundColor Yellow}
           'q' {
                #Cleaning sessions
                write-host "Closing sessions...`nOperation aborted" -ForegroundColor Yellow
                Get-PSSession | Remove-PSSession
                exit
               }
     }
}
until ($input -eq 'q' -or $input -eq '1'-or $input -eq '2'-or $input -eq '3')

if ($input -eq '2'){}

#Connecting to Azure AD & Exchange Online
write-host "Connecting using User : " $AdmUsr -ForegroundColor Yellow
if ($input -eq '2'){
    connect-msolservice -credential $UsrCredential
}
$Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UsrCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber |  out-null
write-host "Connected !" -ForegroundColor Yellow


