<#
.Synopsis
   	O365 User Account Renaming Tool
.DESCRIPTION
   	Renaming tool in XAML & Powershell for Office365 users, including :
    - set primary smtp address
    - set User principal name (UPN)
    - set SIP address 
    - retain existing emails as secondary

    msol-service module needed to access azure AD
.EXAMPLE
	./Rename-O365users.ps1
.NOTES
   	Version 0.1 
   	Written by Arnaud Leresche
#>
#>
#===========================================================================
# XAML WINDOWS FORM CODE
#===========================================================================
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="O365 Users Renaming tools v1.0" Height="789.62" Width="881.054">
    <Grid RenderTransformOrigin="0.491,0.553">
        <Button Name="buttonConnect" Content="Connect" HorizontalAlignment="Left" Margin="759,33,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
        <Button Name="button" Content="Clear Cache" HorizontalAlignment="Left" Margin="275,30,0,0" VerticalAlignment="Top" Width="75"/>
        <Label Name="labelConectionStatus" Content="Connection Status :" HorizontalAlignment="Left" Margin="389,30,0,0" VerticalAlignment="Top"/>
        <Separator HorizontalAlignment="Left" Height="56" Margin="10,95,0,0" VerticalAlignment="Top" Width="852"/>
        <Label Name="labelConnectStats" Content="N/A" HorizontalAlignment="Left" Margin="506,30,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.501,-0.098"/>
        <Label Name="labelloginInfo" Content="Login List :" HorizontalAlignment="Left" Margin="10,30,0,0" VerticalAlignment="Top" Height="27" Width="112"/>
        <ListView Name="listViewTenant" HorizontalAlignment="Left" Height="253" Margin="10,201,0,0" VerticalAlignment="Top" Width="852">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Name="labelTenantCurentInfo" Content="Tenant Infos" HorizontalAlignment="Left" Margin="10,175,0,0" VerticalAlignment="Top"/>
        <Button Name="buttonRefresh" Content="Refresh" HorizontalAlignment="Left" Margin="759,175,0,0" VerticalAlignment="Top" Width="75"/>
        <Button Name="buttonApplyModification" Content="Apply" HorizontalAlignment="Left" Margin="759,461,0,0" VerticalAlignment="Top" Width="75"/>
        <Button Name="buttonEditMode" Content="Edit Mode" HorizontalAlignment="Left" Margin="19,461,0,0" VerticalAlignment="Top" Width="75"/>
        <Button Name="buttonQuit" Content="Quit" HorizontalAlignment="Left" Margin="759,718,0,0" VerticalAlignment="Top" Width="75"/>
        <Label Name="labelWarning" Content="WARNING : EDIT MODE ENABLED" HorizontalAlignment="Left" Margin="111,458,0,0" VerticalAlignment="Top" Foreground="#FFDA3F3F" FontWeight="Bold" Visibility="Hidden"/>
        <Separator HorizontalAlignment="Left" Height="75" Margin="10,479,0,0" VerticalAlignment="Top" Width="852"/>
        <Label Name="labelConsoleOutput" Content="Console Ouput :" HorizontalAlignment="Left" Margin="10,512,0,0" VerticalAlignment="Top"/>
        <ListView Name="listViewConsole" HorizontalAlignment="Left" Height="170" Margin="10,543,0,0" VerticalAlignment="Top" Width="852">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <ProgressBar Name="ProgressBar" HorizontalAlignment="Left" Height="20" Margin="465,461,0,0" VerticalAlignment="Top" Width="224" Visibility="Hidden"/>
        <ListBox Name="listBoxLogin" HorizontalAlignment="Left" Height="58" Margin="10,57,0,0" VerticalAlignment="Top" Width="340"/>
    </Grid>
</Window>
'@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $XAML) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#===========================================================================
# Function to Check Login Cache
#===========================================================================
function get-cache {
    $Admins = get-childitem -Path .\ | Where-Object {$_ -like "Cache_*"} | ForEach-Object {get-content $_ | Select-String "UserName"}
    $Admins = $Admins -replace '<S N="UserName">', '' -replace '</S>', '' -replace '(^\s+|\s+$)','' -replace '\s+',' '
    return $Admins
}


#===========================================================================
# Display logins in cache 
#===========================================================================
#Cache checking 
$AdmUsr = get-cache
if($AdmUsr -eq $null){
    $ListLogin.items.Add("No Login found in cache..")
}
#if Cache found
else {
    $buttonConnect.isEnabled = $true
    foreach ($usr in $AdmUsr){
        if ($usr -ne ""){
            $ListLogin.items.Add($usr)
        }
    }
}

#===========================================================================
# Set Login Click
#===========================================================================
$buttonConnect.Add_Click({
    #create unique ID for cred cache file
    if ($AdmUsr -eq $null) {
        $guidSession = [guid]::NewGuid()
        $inputCred = Join-Path $PWD.ToString()".\Cache_$guidSession.xml"  
        Get-Credential | Export-Clixml $inputCred
        $newUsr = get-cache
        $ListLogin.items.Add($newUsr)
        $buttonConnect.isEnabled = $true
    }
    # otherwise cache exist, looping through them to find the one selected
    else {
        $CurrentUsr = $listLogin.SelectedItem.ToString()
        $cacheXMLpath = get-childitem -Path .\ | Where-Object {$_ -like "Cache_*"}
        foreach ($xml in $cacheXMLpath.Name ){
                if (get-cache $xml -eq $CurrentUsr){
                    $inputCred = $xml 
                } 
        }
        #Import Real XML login file
        Import-Clixml $inputCred
        #Display Domain Connection Status
        $Domain = $CurrentUsr -split "@"
        $labelStatusDomain.Content = $Domain[1]
    }

})

#===========================================================================
# Connect Button Click
#===========================================================================
$buttonConnect.Add_Click({
    #if XML file doesnt exist
    if(![System.IO.File]::Exists($inputCred)){
        $listViewLogin.Items.Add("ERROR : XML file cache not found, please select another login or recreate cache")
        break
    }
    # Set this variable to the location of the file where credentials are cached
    $UsrCredential = Import-Clixml $inputCred
    #Creating PS Session
    $labelStatus.Content = "Connecting.."
    $Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UsrCredential -Authentication Basic -AllowRedirection
    Import-PSSession $Session -AllowClobber |  out-null
    #Test if the session is available if yes display Connected + domain status
    if ( $(get-pssession).Name -eq "ExchangeOnline" -and $(get-pssession).Availability -eq "Available") {
        $labelStatus.Content = "Connected" 
    }
    $Form.Showintaskbar = $true
})

##############################################################################################################################################################
# Renaming different Emails (including SIP)
##############################################################################################################################################################
Function renameEmails {

}
##############################################################################################################################################################
# Renaming User Principal Name (UPN)
##############################################################################################################################################################
Function renameUPN {

}


#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null