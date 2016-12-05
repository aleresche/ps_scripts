<#
.Synopsis
   	Connect To MS Online Cloud Services (O365,MsOnline,SkypeOnline)
.DESCRIPTION
   	Connect to MS Online Cloud Services including the following subservice :
    - Exchange Online (Office 365)
    - Azure AD (MS Online)
    - Skype for Business (SkypeforbusinessOnline)
.EXAMPLE
	./Access-MSCloud.ps1
.NOTES
   	Version 2.0
    Graphical Version

   	Written by Arnaud Leresche
#>
#===========================================================================
# XAML WINDOWS FORM CODE
#===========================================================================
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="O365 Connect Tool" Height="496.539" Width="621.587">
    <Grid RenderTransformOrigin="0.497,0.418">
        <Button Name="buttonConnect" Content="Connect" HorizontalAlignment="Left" Margin="10,160,0,0" VerticalAlignment="Top" Width="96" Height="56" IsEnabled="False"/>
        <Label Name="labelConnectStatus" Content="Connection Status :" HorizontalAlignment="Left" Margin="10,40,0,0" VerticalAlignment="Top"/>
        <Label Name="labelStatus" Content="N/A" HorizontalAlignment="Left" Margin="122,40,0,0" VerticalAlignment="Top"/>
        <Label Name="labelCurrentDomain" Content="Current Domain :" HorizontalAlignment="Left" Margin="10,102,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.368,-0.788"/>
        <Label Name="labelStatusDomain" Content="N/A" HorizontalAlignment="Left" Margin="122,102,0,0" VerticalAlignment="Top"/>
        <Border BorderBrush="Black" BorderThickness="1" HorizontalAlignment="Left" Height="100" Margin="10,40,0,0" VerticalAlignment="Top" Width="277"/>
        <Border BorderBrush="Black" BorderThickness="1" HorizontalAlignment="Left" Height="100" Margin="292,40,0,0" VerticalAlignment="Top" Width="306">
            <ListBox Name="listLogin" Margin="9"/>
        </Border>
        <ListView Name="listViewConsole" HorizontalAlignment="Left" Height="222" Margin="10,234,0,0" VerticalAlignment="Top" Width="588">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Name="LabelCInfos" Content="ConnectionI Infos" HorizontalAlignment="Left" Margin="10,9,0,0" VerticalAlignment="Top"/>
        <Label Name="LabelLogins" Content="Logins&#xD;&#xA;" HorizontalAlignment="Left" Margin="292,9,0,0" VerticalAlignment="Top" Height="26"/>
        <Button Name="buttonSetlogin" Content="Set Login" HorizontalAlignment="Left" Margin="502,160,0,0" VerticalAlignment="Top" Width="96" Height="56" IsEnabled="True" RenderTransformOrigin="0.5,0.5"/>
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

$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#===========================================================================
# Function to Check Login Cache
#===========================================================================
function get-cache {
    $Admins = get-childitem -Path .\ | where {$_ -like "Cache_*"} | foreach{get-content $_ | Select-String "UserName"}
    $Admins = $Admins -replace '<S N="UserName">', '' -replace '</S>', '' -replace '(^\s+|\s+$)','' -replace '\s+',' '
    return $Admins
}

#===========================================================================
# Display logins in cache 
#===========================================================================
#Cache checking 
$AdmUsr = get-cache
if($AdmUsr -eq $null){
    $ListLogin.item.Add("No Login found in cache..")
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
$buttonSetlogin.Add_Click({
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
        $cacheXMLpath = get-childitem -Path .\ | where {$_ -like "Cache_*"}
        foreach ($xml in $cacheXMLpath.Name ){
                if (get-content .\$xml | select-string $CurrentUsr){
                    $inputCred = Join-Path ".\"$xml 
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
        $listViewConsole.Items.Add("ERROR : XML file cache not found, please select another login or recreate cache")
        break
    }
    # Set this variable to the location of the file where credentials are cached
    $UsrCredential = Import-Clixml $inputCred
    #Creating PS Session
    $labelStatus.Content = "Connecting.."
    $Session = New-PSSession -Name "ExchangeOnline" -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UsrCredential -Authentication Basic -AllowRedirection
    Start-Process powershell {
        Import-PSSession $Session -AllowClobber |  out-null
    }
    
    $listViewConsole.Items.Add("SUCCESS : Connected to O365 Service")
    $listViewConsole.Items.Add("DOMAIN  : $($LabelStatusDomain.Content)")
    $labelStatus.Content = "Connected"
})

#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null
