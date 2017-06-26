<# 
.Synopsis
   	Retrieve and Modify SMTP/UPN/ALIAS/SIP mail address from an office 365 tenant
    with Graphical interface
.EXAMPLE
	./Set-Usrlogon.ps1 -Username admin@xxx.onmicrosoft.com -Password mypass123 -currentdomain xxx.onmicrosoft.com -newdomain xxx.com 
.NOTES
   	Version 1.0
   	Written by Arnaud Leresche
#>
<#
.INIT
#>
<#
#Remove all existing Powershell sessions  
Get-PSSession | Remove-PSSession

#Did they provide creds?  If not, ask them for it. 
if (([string]::IsNullOrEmpty($Username) -eq $false) -and ([string]::IsNullOrEmpty($Password) -eq $false)) { 
    $SecurePassword = ConvertTo-SecureString -AsPlainText $Password -Force
    #Build credentials object  
    $UserCredential  = New-Object System.Management.Automation.PSCredential $Username, $SecurePassword
} 
else { 
    #Build credentials object
    write-host "Requesting credential..."  -ForegroundColor Yellow
    $UserCredential  = Get-Credential
}
#>
<#
.FUNCTION CODE
#>
function Connect-Exch{
    $inputCred = Join-Path $PWD.ToString()"\..\Cred.xml"  
    if(![System.IO.File]::Exists($inputCred)){
        # Connection to tenant - use this only 1st time to collect credentials
        Get-Credential | Export-Clixml $inputCred
    } 
    #Write-Host "Credentials file located for user $msolAccount on tenant $msolTenantName ! Loading from cache..."
    # Set this variable to the location of the file where credentials are cached
    $UsrCredential = Import-Clixml $inputCred
    #Connecting to Azure AD & Exchange Online
    write-host "Connecting..." -ForegroundColor Yellow
    #connect-msolservice -credential $UserCredential
    $Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UsrCredential  -Authentication Basic -AllowRedirection
    Import-PSSession $Session -AllowClobber |  out-null
    write-host "Connected !" -ForegroundColor Yellow
}
<#
.INIT FROM
#>

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#Form Creation
$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "User Renaming Tool"
$objForm.Size = New-Object System.Drawing.Size(500,550) 
$objForm.StartPosition = "CenterScreen"

#O365 Connection Status Group
$objO365Status = New-Object System.Windows.Forms.GroupBox
$objO365Status.Location = New-object System.Drawing.Size(10,10)
$objO365Status.Size = New-Object System.Drawing.Size(460,100)
$objO365Status.Text = "O365 PS connection Status"
$objform.Controls.Add($objO365Status)

#O365 Connection Status labelExch
$objLabelXchConnect = New-Object System.Windows.Forms.Label
$objLabelXchConnect.Location = New-Object System.Drawing.Size(15,20) 
$objLabelXchConnect.Size = New-Object System.Drawing.Size(200,20) 
$objLabelXchConnect.Text = "Connection to Exchange : "
$objO365Status.Controls.Add($objLabelXchConnect) 

#O365 Connection Status labelCred
$objLabelCredential = New-Object System.Windows.Forms.Label
$objLabelCredential.Location = New-Object System.Drawing.Size(15,60) 
$objLabelCredential.Size = New-Object System.Drawing.Size(200,20) 
$objLabelCredential.Text = "Current Credential          : "
$objO365Status.Controls.Add($objLabelCredential) 


#O365 Connection Status
$objLabelConnect = New-Object System.Windows.Forms.Label
$objLabelConnect.Location = New-Object System.Drawing.Size(260,20) 
$objLabelConnect.Size = New-Object System.Drawing.Size(25,20) 
$objLabelConnect.Text = "N/A"
$objO365Status.Controls.Add($objLabelConnect) 

#O365 Connection Status
$objLabelCred = New-Object System.Windows.Forms.Label
$objLabelCred.Location = New-Object System.Drawing.Size(260,60) 
$objLabelCred.Size = New-Object System.Drawing.Size(25,20) 
$objLabelCred.Text = "N/A"
$objO365Status.Controls.Add($objLabelCred) 

$ConnectButton = New-Object System.Windows.Forms.Button
$ConnectButton.Location = New-Object System.Drawing.Size(360,25)
$ConnectButton.Size = New-Object System.Drawing.Size(75,50)
$ConnectButton.FlatStyle = "flat"
$ConnectButton.FlatAppearance.BorderSize = 1
$ConnectButton.Text = "Connect"
$ConnectButton.Add_Click({
    Connect-Exch
})
$objO365Status.Controls.Add($ConnectButton)

#O365 Connection Console Group
$objOutputGrp = New-Object System.Windows.Forms.GroupBox
$objOutputGrp.Location = New-object System.Drawing.Size(10,130)
$objOutputGrp.Size = New-Object System.Drawing.Size(460,235)
$objOutputGrp.Text = "Console"
$objform.Controls.Add($objOutputGrp)

#Console Output
$objviewOutput = New-Object System.Windows.Forms.Listbox
$objviewOutput.Location = New-Object System.Drawing.Size(10,15)
$objviewOutput.Size = New-Object System.Drawing.Size(440,220)
$objOutputGrp.Controls.Add($objviewOutput)


#display form
$objForm.Topmost = $True
$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()


