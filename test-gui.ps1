[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MainWindow" Height="496.539" Width="950.087">
    <Grid RenderTransformOrigin="0.497,0.418">
        <GroupBox Name="groupBoxConsole" Header="Console Output" HorizontalAlignment="Left" Margin="10,167,0,0" VerticalAlignment="Top" Height="289" Width="922">
            <ListBox Name="listBox" HorizontalAlignment="Left" Height="90" Margin="3,-122,0,0" VerticalAlignment="Top" Width="377"/>
        </GroupBox>
        <GroupBox Name="groupBoxConnecct" Header="Connection Status" HorizontalAlignment="Left" Margin="10,26,0,0" VerticalAlignment="Top" Height="136" Width="922">
            <Label Name="label" Content="Logins" HorizontalAlignment="Left" Margin="10,0,0,0" VerticalAlignment="Top"/>
        </GroupBox>
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
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null