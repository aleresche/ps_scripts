$tenant1Cred = Get-Credential


#Connecting to Azure AD & Exchange Online
write-host "Loading Online Session 1...." -ForegroundColor Yellow
$Session1 = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $tenant1Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session1 -AllowClobber |  out-null
write-host "Online session 2 established !" -ForegroundColor Yellow

$tenant2Cred = Get-Credential

#Connecting to Azure AD & Exchange Online
write-host "Loading Online Session 2...." -ForegroundColor Yellow
$Session2 = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $tenant2Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session2 -AllowClobber |  out-null
write-host "Online session 2 established !" -ForegroundColor Yellow