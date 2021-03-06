﻿<# 
.Synopsis
   	Retrieve and Modify SMTP/UPN/ALIAS/SIP mail address
.EXAMPLE
	./Rename-SMTPAddr.ps1 -Username admin@xxx.onmicrosoft.com -Password mypass123 -currentdomain xxx.onmicrosoft.com -newdomain xxx.com -filter _domain.xx
.NOTES
   	Version 1.3
    - add UPN renaming
    - add Report option
    - add filter option
    - add Rollback function 
   	Written by Arnaud Leresche
#>
<#
.PARAMETERS
#>
Param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $Username,  
    [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $Password,
    [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $CurrentDomain,
    [Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $NewDomain,
    [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Filter
)
#>
<#
.INIT
#>
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
    write-host "Requesting credential..."  -ForegroundColor Cyan
    $UserCredential  = Get-Credential
}

#Connecting to Azure AD & Exchange Online
write-host "Loading Online Session...." -ForegroundColor Cyan
connect-msolservice -credential $UserCredential
$Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber |  out-null
write-host "Online session established !" -ForegroundColor Cyan

# Menu multiple choice to guide the user
function Show-Menu {
     Write-Host "================ Userlogon Rename ================" -ForegroundColor Cyan
     
     Write-Host "1: Press '1' to update from $CurrentDomain to $NewDomain" -ForegroundColor Cyan
     Write-Host "Q: Press 'Q' to quit." -ForegroundColor Cyan
}

do {
     Show-Menu
     write-host "Please make a selection" -ForegroundColor Cyan
     $input = Read-Host 
     switch ($input)
     {
           '1' {write-host 'Starting Update process'-ForegroundColor Cyan} 
           'q' {exit}
     }
}
until ($input -eq 'q' -or $input -eq '1')

#>
<#
.Main Code - Migrate EMail/UPN/ALIAS/SIP domain + suppress Filter Entry
#>
$date = Get-Date -Format ddMMyyyy-HHmmss

if ($input -eq '1'){  # Migrating switch
    #Renaming SMTP Primary 
    $Mailboxes = get-mailbox -ResultSize Unlimited
    write-host "Renaming Emails...." -ForegroundColor Cyan
    foreach ($Mailbox in $Mailboxes){
        if ($Mailbox.PrimarySmtpAddress -match $CurrentDomain <#-and $Mailbox.PrimarySmtpAddress.ToString() -match $Filter#>){
            $Smtp = $Mailbox.PrimarySmtpAddress
            $NewEmail = $Smtp -replace $CurrentDomain.Tostring(),$NewDomain.ToString()
            $NewEmail = $NewEmail -replace $Filter,""
            $OutSMTP = "Changing Email from " + $Mailbox.PrimarySmtpAddress.ToString()+ " to : "+ $NewEmail 
            write-host $OutSMTP  -ForegroundColor Magenta
            set-mailbox $Mailbox.Alias -Emailaddresses $NewEmail -confirm:$false
            $OutSMTP | out-file -FilePath $pwd\Migr_SMTP_renaming_report_$date.txt -append -Encoding Default
            $CountSMTP++
        }
    }
    $TotalSMTP = "Total Emails Renamed : " + $CountSMTP
    $TotalSMTP | out-file -FilePath $pwd\Migr_SMTP_renaming_report_$date.txt -append -Encoding Default
    write-host "=====================`n"+ $TotalSMTP -ForegroundColor Magenta
    write-host "Done!`n`n" -ForegroundColor Cyan


    #Renaming UPN
    write-host "Renaming UPNs...." -ForegroundColor Cyan
    Get-MsolUser -All | Where {$_.UserPrincipalName.ToLower().EndsWith($CurrentDomain.ToString()) <#-and $_.UserPrincipalName.ToString() -match $filter#>} | ForEach {
     #if($count -eq 1) #For Testing the first result
     # {
     $upnVal = $_.UserPrincipalName.Split("@")[0] + "@"+$NewDomain.ToString()
     $upnVal = $upnVal -replace $filter,""
     $OutUPN = "Changing UPN value from: "+ $_.UserPrincipalName+" to: "+ $upnVal
     Write-Host $OutUPN -ForegroundColor Magenta
     $OutUPN | out-file -FilePath $pwd\Migr_UPN_renaming_report_$date.txt -append -Encoding Default
     Set-MsolUserPrincipalName -ObjectId $_.ObjectId -NewUserPrincipalName ($upnVal)
     $count++
     # }
     }           
    $TotalUPN = "Total UPNs Renamed : " + $count 
    $TotalUPN | out-file -FilePath $pwd\Migr_UPN_renaming_report_$date.txt -append -Encoding Default
    write-host "=====================`n"+ $TotalUPN -ForegroundColor Magenta
    write-host "Done!`n`n" -ForegroundColor Cyan
}

#Cleaning sessions
 write-host "Closing sessions...`nOperation completed" -ForegroundColor Cyan
 Get-PSSession | Remove-PSSession
