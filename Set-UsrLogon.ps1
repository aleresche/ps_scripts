<# 
.Synopsis
   	Retrieve and Modify SMTP/UPN/ALIAS/SIP mail address from an office 365 tenant, 
.EXAMPLE
	./Set-Usrlogon.ps1 -Username admin@xxx.onmicrosoft.com -Password mypass123 -currentdomain xxx.onmicrosoft.com -newdomain xxx.com -filter <StringToAddorRemove>
    
    ./Set-UsrLogon.ps1 -CurrentDomain xxx.onmicrosoft.com -Newdomain xxx.com
    
    ./Set-UsrLogon.ps1 -CurrentDomain xxx.onmicrosoft.com -Newdomain xxx.com -filter <StringToAddorRemove>
.NOTES
   	Version 1.6
    Features :
        Rename - UPN/EMAILS/SIP/ALIAS
        Extract result in log file
        Smart Renaming - Filter Option that allow to insert or remove string from username 
        Credential Rework 
        UI rework
   	Written by Arnaud Leresche
#>
<#
.PARAMETERS
#>
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Username,  
    [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]  
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
#Introduction
write-host "Preparing Tool...`nLooking for login cache..." -ForegroundColor Cyan
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
#Connecting to Azure AD & Exchange Online
write-host "Connecting using User : " $AdmUsr -ForegroundColor Cyan
connect-msolservice -credential $UsrCredential
$Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UsrCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber |  out-null
write-host "Connected !" -ForegroundColor Cyan


# Menu multiple choice to guide the user
function Show-Menu {
     Write-Host "================ Userlogon Renaming ================" -ForegroundColor Cyan
     Write-host "Connected on Tenant : $($Domain[1])" -ForegroundColor Cyan
     Write-Host "1: Press '1' to Migrate from $CurrentDomain to $NewDomain" -ForegroundColor Cyan
     Write-Host "2: Press '2' to Rollback from $CurrentDomain to $Newdomain"  -ForegroundColor Cyan
     Write-Host "Q: Press 'Q' to quit." -ForegroundColor Cyan
}
do {
     Show-Menu
     write-host "Please make a selection" -ForegroundColor Cyan
     $input = Read-Host
     switch ($input)
     {
           '1' {write-host 'You chose option #1' -ForegroundColor Cyan} 
           '2' {write-host 'You chose option #2' -ForegroundColor Cyan}
           'q' {
                #Cleaning sessions
                write-host "Closing sessions...`nOperation aborted" -ForegroundColor Cyan
                Get-PSSession | Remove-PSSession
                exit
               }
     }
}
until ($input -eq 'q' -or $input -eq '1'-or $input -eq '2' )

#>
<#
.Main Code - Migrate EMail/UPN/ALIAS/SIP domain + suppress Filter Entry
#>
$date = Get-Date -Format ddMMyyyy-HHmmss

if ($input -eq '1'){  # Migrating switch
    #Renaming SMTP Primary 
    $Mailboxes = get-mailbox -ResultSize Unlimited
    write-host "Renaming Emails/Alias/SIP...." -ForegroundColor Cyan
    foreach ($Mailbox in $Mailboxes){
        if ($Mailbox.PrimarySmtpAddress -like "*$CurrentDomain" -and $Mailbox.PrimarySmtpAddress.ToString() -match $Filter){
            $Smtp = $Mailbox.PrimarySmtpAddress
            $NewEmail = $Smtp -replace $CurrentDomain.Tostring(),$NewDomain.ToString() #Changing domain
            $NewEmail = $NewEmail -replace $Filter,""
            $NewAlias = $Mailbox.Alias -replace $Filter,""
            $NewEmailsaddresses = @() #array to store new email address
            $NewEmailsaddresses = $Mailbox.EmailAddresses -replace ("SMTP:$($Mailbox.PrimarySmtpAddress)","SMTP:$NewEmail")
            $NewEmailsaddresses = $NewEmailsaddresses -replace ("SIP:$($Mailbox.PrimarySmtpAddress)","SIP:$NewEmail")
            $NewEmailsaddresses = $NewEmailsaddresses -replace ("smtp:$($Mailbox.PrimarySmtpAddress)","")
            $OutSMTP =  "Updating User Email : "+$Mailbox.identity+" `nFrom : "+$Mailbox.Emailaddresses+" `nto : "+$NewEmailsaddresses+"`nUpdating User Alias From : "+$Mailbox.Alias+" to : "+$NewAlias  
            write-host $OutSMTP  -ForegroundColor Magenta
            #set-mailbox $Mailbox.identity -Emailaddresses $NewEmail -Alias $NewAlias -confirm:$false
            $OutSMTP -split "`n" | out-file -FilePath $pwd\Migr_SMTP_renaming_report_$date.log -append -Encoding Default
            $CountSMTP++
        }
    }
    $TotalSMTP = "Total Users Renamed : " + $CountSMTP
    $TotalSMTP | out-file -FilePath $pwd\Migr_SMTP_renaming_report_$date.log -append -Encoding Default
    write-host "=====================`n"$TotalSMTP -ForegroundColor Magenta
    write-host "Done!" -ForegroundColor Cyan

    #Renaming UPN
    write-host "Renaming UPNs...." -ForegroundColor Cyan
    Get-MsolUser -All | Where {$_.UserPrincipalName.ToLower().EndsWith($CurrentDomain.ToString()) -and $_.UserPrincipalName.ToString() -match $filter} | ForEach {
        $upnVal = $_.UserPrincipalName.Split("@")[0] + "@"+$NewDomain.ToString()
        $upnVal = $upnVal -replace $filter,""
        $OutUPN = "Changing UPN value from: "+ $_.UserPrincipalName+" to: "+ $upnVal
        Write-Host $OutUPN -ForegroundColor Magenta
        $OutUPN | out-file -FilePath $pwd\Migr_UPN_renaming_report_$date.log -append -Encoding Default
        #Set-MsolUserPrincipalName -ObjectId $_.ObjectId -NewUserPrincipalName ($upnVal)
        $count++
    }           
    $TotalUPN = "Total Users Renamed : " + $count 
    $TotalUPN | out-file -FilePath $pwd\Migr_UPN_renaming_report_$date.log -append -Encoding Default
    write-host "=====================`n"$TotalUPN -ForegroundColor Magenta
    write-host "Done!" -ForegroundColor Cyan
    
}

<#
.Main Code - Rollback EMail & UPN domain + add Filter Entry
#>

if ($input -eq '2'){
    #Renaming SMTP/ALIAS/SIP Primary 
    $Mailboxes = get-mailbox -ResultSize Unlimited
    write-host "Renaming Emails...." -ForegroundColor Cyan
    foreach ($Mailbox in $Mailboxes){
        if ($Mailbox.PrimarySmtpAddress -like "*$CurrentDomain"){
            $Smtp = $Mailbox.PrimarySmtpAddress
            $NewEmail = $Smtp -replace $CurrentDomain.Tostring(),$NewDomain.ToString()
            $Usr = $smtp.Split("@")[0] + $filter
            $NewEmail = $Usr +"@"+$NewDomain
            $NewAlias = $Mailbox.Alias.ToString() + $Filter
            $NewEmailsaddresses = $Mailbox.EmailAddresses -replace ("SMTP:$($Mailbox.PrimarySmtpAddress)","SMTP:$NewEmail")
            $NewEmailsaddresses = $NewEmailsaddresses -replace ("SIP:$($Mailbox.PrimarySmtpAddress)","SIP:$NewEmail")
            $NewEmailsaddresses = $NewEmailsaddresses -replace ("smtp:$($Mailbox.PrimarySmtpAddress)","")
            $OutSMTP =  "Updating User Email : "+$Mailbox.identity+" From : "+$Mailbox.Emailaddresses+" to : "+$NewEmailsaddresses+"`nUpdating User Alias From : "+$Mailbox.Alias+" to : "+$NewAlias
            write-host $OutSMTP  -ForegroundColor Magenta
            #set-mailbox $Mailbox.identity -Emailaddresses $NewEmailsaddresses -Alias $NewAlias -confirm:$false
            $OutSMTP -split "`n" | out-file -FilePath $pwd\Rollback_SMTP_renaming_report_$date.log -append -Encoding Default
            $CountSMTP++
        }
    }
    $TotalSMTP = "Total Emails Renamed : "+$CountSMTP
    $TotalSMTP | out-file -FilePath $pwd\Rollback_SMTP_renaming_report_$date.log -append -Encoding Default
    write-host "=====================`n"$TotalSMTP -ForegroundColor Magenta
    write-host "Done!" -ForegroundColor Cyan

    #Renaming UPN
    write-host "Renaming UPNs...." -ForegroundColor Cyan
    Get-MsolUser -All | Where {$_.UserPrincipalName.ToLower() -like "*$CurrentDomain"} | ForEach {
        $upnVal = $_.UserPrincipalName.Split("@")[0]+ $filter + "@"+$NewDomain.ToString()
        $OutUPN = "Changing UPN value from: "+ $_.UserPrincipalName+" to: "+ $upnVal
        Write-Host $OutUPN -ForegroundColor Magenta
        $OutUPN | out-file -FilePath $pwd\Rollback_UPN_renaming_report_$date.log -append -Encoding Default
        if ((get-mailbox $_.UserPrincipalName) -eq $true){
           # Set-MsolUserPrincipalName -ObjectId $_.ObjectId -NewUserPrincipalName ($upnVal)
        }
        $count++
    }         
    $TotalUPN = "Total UPNs Renamed : "+$count 
    $TotalUPN | out-file -FilePath $pwd\Rollback_UPN_renaming_report_$date.log -append -Encoding Default
    write-host "=====================`n"$TotalUPN -ForegroundColor Magenta
    write-host "Done!" -ForegroundColor Cyan 
}



#Cleaning sessions
write-host "Closing sessions...`nOperation completed" -ForegroundColor Cyan
Get-PSSession | Remove-PSSession
