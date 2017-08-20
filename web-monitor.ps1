<#
.Synopsis
   	Powershell Tools that monitor specific urls configured in the app
.DESCRIPTION
   	powershell script embedded in a xaml GUI to monitor different urls 
.EXAMPLE
	./monitoringtool.ps1
.NOTES
    Version 1.1
    adding multithreading for UI and script interaction 
    Written by Arnaud Leresche
#>
#=====================================================================================================================================================================================
# Init Runspace + GUI
#=====================================================================================================================================================================================
# Create synced RunSpace
$syncHash = [hashtable]::Synchronized(@{})
$newRunspace =[runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"         
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
# Create GUI          
$psCmd = [PowerShell]::Create().AddScript({   
[xml]$xaml = @"
<Window
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
Title="Cloud Solutions -  PS Monitoring Tools" Height="507.115" Width="919.128">
<Grid>
<ListView Name="WPFUrlsList" HorizontalAlignment="Left" Height="138" Margin="10,42,0,0" VerticalAlignment="Top" Width="463">
    <ListView.View>
        <GridView>
            <GridViewColumn/>
        </GridView>
    </ListView.View>
</ListView>
<Label Name="WPFtxtUrls" Content="Website Urls to check :" HorizontalAlignment="Left" Margin="10,11,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.417,-0.248"/>
<TextBox Name="WPFLogPath" HorizontalAlignment="Left" Height="23" Margin="776,157,0,0" TextWrapping="Wrap" Text="c:\temp\url.log" VerticalAlignment="Top" Width="120"/>
<Label Name="WPFtxtPath" Content="Path for log file :" HorizontalAlignment="Left" Margin="677,156,0,0" VerticalAlignment="Top"/>
<Button Name="WPFbtnCheck" Content="Start check" HorizontalAlignment="Left" Margin="488,131,0,0" VerticalAlignment="Top" Width="75"/>
<Button Name="WPFbtnStop" Content="Stop" HorizontalAlignment="Left" Margin="488,156,0,0" VerticalAlignment="Top" Width="75"/>
<ListView Name="WPFConsole" HorizontalAlignment="Left" Height="223" Margin="10,223,0,0" VerticalAlignment="Top" Width="886">
    <ListView.View>
        <GridView>
            <GridViewColumn/>
        </GridView>
    </ListView.View>
</ListView>
<Label Name="WPFtxtConsole" Content="Console Output :" HorizontalAlignment="Left" Margin="10,201,0,0" VerticalAlignment="Top"/>
<Button Name="WPFbtnAddUrl" Content="Add Url" HorizontalAlignment="Left" Margin="488,42,0,0" VerticalAlignment="Top" Width="75"/>

</Grid>
</Window>
"@

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $syncHash.Window.FindName($_.Name)}
$syncHash.Window.ShowDialog() | Out-Null
$syncHash.Error = $Error
})
# start runspace and invoke GUI
$psCmd.Runspace = $newRunspace
$data = $psCmd.BeginInvoke()

#=====================================================================================================================================================================================
# Function to test websites availablility
#=====================================================================================================================================================================================


#=====================================================================================================================================================================================
# Function to add Url into form
#=====================================================================================================================================================================================


function add-url ($url) {
    if ($url -ne $null) {
       $syncHash.WPFbtnAddUrl.Dispatcher.invoke([action]{$syncHash.WPFbtnAddUrl.Content='TEST!'},"Normal")
    } 
}



add-url("test")


