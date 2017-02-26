<#
.Synopsis
   	O365 User Account Renaming Tool
.DESCRIPTION
   	Renaming tool for Office365 users, including :
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
        Title="O365 Users Renaming tools v1.0" Height="778.72" Width="881.054">
    <Grid RenderTransformOrigin="0.491,0.553">
        <Button Name="buttonConnect" Content="Connect" HorizontalAlignment="Left" Margin="759,37,0,0" VerticalAlignment="Top" Width="75"/>
        <Button Name="button" Content="Clear Cache" HorizontalAlignment="Left" Margin="759,75,0,0" VerticalAlignment="Top" Width="75"/>
        <Label Name="labelConectionStatus" Content="Connection Status :" HorizontalAlignment="Left" Margin="10,37,0,0" VerticalAlignment="Top"/>
        <Separator HorizontalAlignment="Left" Height="56" Margin="10,95,0,0" VerticalAlignment="Top" Width="852"/>
        <Label Name="labelConnectStats" Content="N/A" HorizontalAlignment="Left" Margin="140,37,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.501,-0.098"/>
        <Label Name="labelloginInfo" Content="Login Info              :" HorizontalAlignment="Left" Margin="10,68,0,0" VerticalAlignment="Top" Height="27" Width="112"/>
        <Label Name="labelLogin" Content="N/A" HorizontalAlignment="Left" Margin="140,72,0,0" VerticalAlignment="Top"/>
        <ListView Name="listViewTenant" HorizontalAlignment="Left" Height="253" Margin="10,201,0,0" VerticalAlignment="Top" Width="852">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Name="labelTenantCurentInfo" Content="Tenant Infos" HorizontalAlignment="Left" Margin="10,175,0,0" VerticalAlignment="Top"/>
        <Button Name="buttonRefresh" Content="Refresh" HorizontalAlignment="Left" Margin="759,156,0,0" VerticalAlignment="Top" Width="75"/>
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
