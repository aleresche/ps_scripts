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
$objLabelVMname = New-Object System.Windows.Forms.Label
$objLabelVMname.Location = New-Object System.Drawing.Size(15,20) 
$objLabelVMname.Size = New-Object System.Drawing.Size(200,20) 
$objLabelVMname.Text = "Connection to Exchange : "
$objO365Status.Controls.Add($objLabelVMname) 

#O365 Connection Status labelCred
$objLabelVMname = New-Object System.Windows.Forms.Label
$objLabelVMname.Location = New-Object System.Drawing.Size(15,60) 
$objLabelVMname.Size = New-Object System.Drawing.Size(200,20) 
$objLabelVMname.Text = "Current Credential          : "
$objO365Status.Controls.Add($objLabelVMname) 


#O365 Connection Status
$objLabelVMname = New-Object System.Windows.Forms.Label
$objLabelVMname.Location = New-Object System.Drawing.Size(260,20) 
$objLabelVMname.Size = New-Object System.Drawing.Size(25,20) 
$objLabelVMname.Text = "N/A"
$objO365Status.Controls.Add($objLabelVMname) 

#O365 Connection Status
$objLabelVMname = New-Object System.Windows.Forms.Label
$objLabelVMname.Location = New-Object System.Drawing.Size(260,60) 
$objLabelVMname.Size = New-Object System.Drawing.Size(25,20) 
$objLabelVMname.Text = "N/A"
$objO365Status.Controls.Add($objLabelVMname) 

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(360,25)
$OKButton.Size = New-Object System.Drawing.Size(75,50)
$OKButton.Text = "Connect"
$OKButton.Add_Click({
    Connect-Exch
 
})
$objO365Status.Controls.Add($OKButton)

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


function Connect-Exch()  {
    Write-Output "Credentials cache lookup path set to $PWD"
    if(![System.IO.File]::Exists($inputCred)){
        # Connection to tenant - use this only 1st time to collect credentials
        Get-Credential | Export-Clixml $inputCred
    } 

    #Write-Host "Credentials file located for user $msolAccount on tenant $msolTenantName ! Loading from cache..."
    # Set this variable to the location of the file where credentials are cached
    $UsrCredential = Import-Clixml $$inputCred
    
}
