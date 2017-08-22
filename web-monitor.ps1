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
Add-Type -AssemblyName PresentationCore, PresentationFramework
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
#=====================================================================================================================================================================================
# XAML objects
#=====================================================================================================================================================================================
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash.Add($_.Name,$synchash.Window.FindName($_.Name))}
#=====================================================================================================================================================================================
$syncHash.WPFbtnAddUrl.Add_click({
    $count++
    if ($count -lt 3) {
        add-url
    }
})
$syncHash.Window.ShowDialog() | Out-Null
$syncHash.Error = $Error
})

#=====================================================================================================================================================================================
# Start AppScript
#=====================================================================================================================================================================================
$psCmd.Runspace = $newRunspace
$data = $psCmd.BeginInvoke()
#=====================================================================================================================================================================================


#=====================================================================================================================================================================================
# Buttons Add clicks Call
#=====================================================================================================================================================================================
$syncHash.WPFbtnAddUrl.Dispatcher.invoke([action]{$syncHash.WPFbtnAddUrl.Add_click({add-url})},"Normal")
$syncHash.WPFbtnAddUrl.Dispatcher.invoke([action]{$syncHash.WPFbtnAddUrl.Add_click({test-urls})},"Normal")

#=====================================================================================================================================================================================
# Function to add Url into form
#=====================================================================================================================================================================================
function add-url {
    
    Add-Type -AssemblyName Microsoft.VisualBasic
    $url = [Microsoft.VisualBasic.Interaction]::InputBox('Enter a website url to monitor', 'url',"")
    if ($url -ne $null) {
        #$syncHash.WPFUrlsList.items.add($url)
        $syncHash.WPFUrlsList.Dispatcher.invoke([action]{$syncHash.WPFUrlsList.items.add($url)},"Normal")
    }
}


#=====================================================================================================================================================================================
# Function to test urls
#=====================================================================================================================================================================================
function test-urls {
    $path = $syncHash.WPFLogPath.Text
    for ($i=0;$i -le 2;$i++){
        foreach ($url in $syncHash.WPFUrlsList.items) {
            if ($url -ne $null){
                $Time = Measure-Command { $httpReq = Invoke-WebRequest -uri $url -ErrorAction SilentlyContinue } 
                $date=Get-Date
                if ($httpReq.StatusCode -eq "200"){
                    $outputOK = "$date :: $url is responding correctly :: OK HTTP "+$httpReq.StatusCode+" in "+$Time.TotalSeconds+" second response time"
                    $syncHash.WPFConsole.items.add($outputOK)
                    $outputOK | out-file -filepath $path\$url.log -Encoding default -Append
                }
                if ($httpReq.StatusCode -eq $null){
                    $outputNOK =  "$date ::  $url not responding WARNING :: ERROR HTTP "+$httpReq.StatusCode+" in"+$Time.TotalSeconds+" second response time"
                    $syncHash.WPFConsole.items.add($outputNOK) 
                    $outputNOK | out-file -filepath $path\$url.log -Encoding default -Append
                }
            }
        }
        start-sleep -s 59 # wait in seconds before looping again 
    }
}


