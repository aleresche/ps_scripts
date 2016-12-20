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
cls
write-host "Connect to MS O365 Online services" -ForegroundColor Yellow
write-host "==================================" -ForegroundColor Yellow
write-host "Preparing data to setup connection...`nLooking for login cache..." -ForegroundColor Yellow

#Login Management
$Admins = @()
#Cache checking 
get-childitem -Path .\ | where {$_ -like "Cache_*"} | foreach{
    $AdmUsr = get-content $_ | select-string "UserName"
    $AdmUsr = $AdmUsr -replace '<S N="UserName">'; ''
    $AdmUsr = $AdmUsr -replace '</S>'; ''
    #Split username/domain
    $Adm = $AdmUsr -split '@'
    $admins.Add($Adm)
}
#No cache found asking for Credential
if(![System.IO.File]::Exists($inputCred) -and $Admins -eq $null){
    write-host "No Credential Found, creating cache..."
    #create unique ID for cred cache file
    $guidSession = [guid]::NewGuid()
    $inputCred = Join-Path $PWD.ToString()".\Cache_$guidSession.xml"  
    Get-Credential | Export-Clixml $inputCred
}


# Set this variable to the location of the file where credentials are cached
$UsrCredential = Import-Clixml $inputCred

# Menu multiple choice to guide the user
function Show-MenuConnect {
     Write-Host "================ Connecting ================" -ForegroundColor Yellow
     Write-host "Connecting on Tenant : $($Domain[1])" -ForegroundColor Yellow
     write-host "With User : $($Domain[0])" -ForegroundColor Yellow
     Write-Host "================= Options ==================" -ForegroundColor Yellow
     Write-Host "1: Press '1' Connect to O365 only" -ForegroundColor Yellow
     Write-Host "2: Press '2' Connect to O365 & MS Online"  -ForegroundColor Yellow
     Write-host "3: Press '3' Change admin login" -ForegroundColor Yellow
     Write-Host "Q: Press 'Q' to quit." -ForegroundColor Yellow
}
do {
     Show-MenuConnect
     write-host "Please make a selection" -ForegroundColor Yellow
     $input = Read-Host
     switch ($input)
     {
           '1' {write-host 'You chose option #1' -ForegroundColor Yellow} 
           '2' {write-host 'You chose option #2' -ForegroundColor Yellow}
           '3' {write-host 'You chose option #2' -ForegroundColor Yellow
                write-host "Changing admin login...`nPlease Input new Credential" -ForegroundColor Yellow
                Get-Credential | Export-Clixml $inputCred
                Show-MenuConnect
               }
           'q' {
                #Cleaning sessions
                write-host "Closing sessions...`nOperation aborted" -ForegroundColor Yellow
                Get-PSSession | Remove-PSSession
                exit
               }
     }
}
until ($input -eq 'q' -or $input -eq '1'-or $input -eq '2'-or $input -eq '3')


#Connecting to Azure AD & Exchange Online
write-host "Connecting using User : " $AdmUsr -ForegroundColor Yellow
$UsrCredential = Import-Clixml $inputCred
if ($input -eq '2'){
    connect-msolservice -credential $UsrCredential
}
$Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UsrCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber |  out-null
write-host "Connected !" -ForegroundColor Yellow


