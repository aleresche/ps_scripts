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
# XAML WINDOWS FORM CODE
#=====================================================================================================================================================================================
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
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
'@
<#@'
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cloud Solutions -  PS Monitoring Tools" Height="507.115" Width="919.128">
    <Grid>
        <ListView Name="listView" HorizontalAlignment="Left" Height="138" Margin="10,42,0,0" VerticalAlignment="Top" Width="463">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Name="label" Content="Website Urls to check :" HorizontalAlignment="Left" Margin="10,11,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.417,-0.248"/>
        <TextBox Name="LogPath" HorizontalAlignment="Left" Height="23" Margin="776,157,0,0" TextWrapping="Wrap" Text="C:\share" VerticalAlignment="Top" Width="120"/>
        <Label Name="labelpath" Content="Path for log file :" HorizontalAlignment="Left" Margin="677,156,0,0" VerticalAlignment="Top"/>
        <Button Name="buttonUrl" Content="Add url" HorizontalAlignment="Left" Margin="488,42,0,0" VerticalAlignment="Top" Width="75"/>
        <Button Name="buttonCheck" Content="Start check" HorizontalAlignment="Left" Margin="488,132,0,0" VerticalAlignment="Top" Width="75"/>
        <Button Name="buttonStop" Content="Stop" HorizontalAlignment="Left" Margin="488,156,0,0" VerticalAlignment="Top" Width="75"/>
        <ListView Name="listViewConsole" HorizontalAlignment="Left" Height="223" Margin="10,223,0,0" VerticalAlignment="Top" Width="886">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Name="labelConsole" Content="Console Output :" HorizontalAlignment="Left" Margin="10,201,0,0" VerticalAlignment="Top"/>

    </Grid>
</Window>
'@#>



#Read XAML with try/catch to avoid XML errors
$reader=(New-Object System.Xml.XmlNodeReader $XAML) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

#=====================================================================================================================================================================================
# Store Form Objects In PowerShell
#=====================================================================================================================================================================================
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#=====================================================================================================================================================================================
# Functions
#=====================================================================================================================================================================================


#=====================================================================================================================================================================================
# Main Code
#=====================================================================================================================================================================================

#=====================================================================================================================================================================================
# buttonCheck - On Click 
#=====================================================================================================================================================================================
$buttonUrl.Add_Click({
    Add-Type -AssemblyName Microsoft.VisualBasic
    $url = [Microsoft.VisualBasic.Interaction]::InputBox('Enter a website url to monitor', 'url',"")
    if ($url -ne $null) {
        $listView.items.Add($url)
    }
})

#=====================================================================================================================================================================================
# buttonCheck - On Click Start to monitor website(s)
#=====================================================================================================================================================================================
$buttonCheck.Add_Click({
## 
$path = $LogPath.Text
for ($i=0;$i -le 2;$i++){
    foreach ($url in $ListView.items) {
        if ($url -ne $null){
            #try {
                    $Time = Measure-Command { $httpReq = Invoke-WebRequest -uri $url -ErrorAction SilentlyContinue } 
                    $date=Get-Date
                    if ($httpReq.StatusCode -eq "200"){
                        $outputOK = "$date :: $url is responding correctly :: OK HTTP "+$httpReq.StatusCode+" in "+$Time.TotalSeconds+" second response time"
                        $ListViewConsole.items.add($outputOK)
                        $outputOK | out-file -filepath $path\$url.log -Encoding default -Append
                    }
             #   }
             #   catch{
                 if ($httpReq.StatusCode -eq $null){
                    $outputNOK =  "$date ::  $url not responding WARNING :: ERROR HTTP "+$httpReq.StatusCode+" in"+$Time.TotalSeconds+" second response time"
                    $ListViewConsole.items.add($outputNOK) 
                    $outputNOK | out-file -filepath $path\$url.log -Encoding default -Append
                 }
             #   }
        }
    }
    start-sleep -s 59 # wait in seconds before looping again 
}

})

#=====================================================================================================================================================================================
# Shows the form
#=====================================================================================================================================================================================
$Form.ShowDialog() | out-null