<#
.Synopsis
   	Powershell Tools that monitor specific urls configured in the app for 24/48 hours with graphical interface
.DESCRIPTION
       powershell script embedded in a xaml GUI to monitor different urls, 
       logs are stored by url name in the same folder as this script 
.EXAMPLE
	./monitoringtool.ps1
.NOTES
    Version 2.0
    adding multithreading for UI and script interaction 
    Written by Arnaud Leresche
#>
#=====================================================================================================================================================================================
# Init Runspace + XAML GUI
#=====================================================================================================================================================================================
Add-Type -AssemblyName PresentationCore, PresentationFramework
# Create synced RunSpace
$Global:syncHash = [hashtable]::Synchronized(@{})
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
Title="Cloud Solutions -  PS Monitoring Tools" Height="507.115" Width="592.898">
<Grid>
<ListView Name="WPFUrlsList" HorizontalAlignment="Left" Height="138" Margin="10,42,0,0" VerticalAlignment="Top" Width="463">
    <ListView.View>
        <GridView>
            <GridViewColumn/>
        </GridView>
    </ListView.View>
</ListView>
<Label Name="WPFtxtUrls" Content="Website Urls to check :" HorizontalAlignment="Left" Margin="10,11,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.417,-0.248"/>
<Button Name="WPFbtnCheck" Content="Start check" HorizontalAlignment="Left" Margin="488,131,0,0" VerticalAlignment="Top" Width="75"/>
<Button Name="WPFbtnStop" Content="Stop" HorizontalAlignment="Left" Margin="488,156,0,0" VerticalAlignment="Top" Width="75"/>
<ListView Name="WPFConsole" HorizontalAlignment="Left" Height="223" Margin="10,223,0,0" VerticalAlignment="Top" Width="553">
    <ListView.View>
        <GridView>
            <GridViewColumn/>
        </GridView>
    </ListView.View>
</ListView>
<Label Name="WPFtxtConsole" Content="Console Output :" HorizontalAlignment="Left" Margin="10,201,0,0" VerticalAlignment="Top"/>
<Button Name="WPFbtnAddUrl" Content="Add Url" HorizontalAlignment="Left" Margin="488,42,0,0" VerticalAlignment="Top" Width="75"/>
<ComboBox Name="TimerBox" HorizontalAlignment="Left" Margin="515,75,0,0" VerticalAlignment="Top" Width="48" RenderTransformOrigin="0.458,-0.607" SelectedIndex="0">
    <ComboBoxItem Content="24H" HorizontalAlignment="Left" Width="92"/>
    <ComboBoxItem Content="48H" HorizontalAlignment="Left" Width="92"/>
</ComboBox>
<Label Name="LabelTTL" Content="TTL:" HorizontalAlignment="Left" Margin="483,71,0,0" VerticalAlignment="Top" Width="49" Height="26"/>

</Grid>
</Window>
"@
#=====================================================================================================================================================================================
# XAML objects mapping synchash
#=====================================================================================================================================================================================
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash.Add($_.Name,$synchash.Window.FindName($_.Name))}
#=====================================================================================================================================================================================

#=====================================================================================================================================================================================
# region Background runspace to clean up jobs
#=====================================================================================================================================================================================
$Script:JobCleanup = [hashtable]::Synchronized(@{})
$Script:Jobs = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
$jobCleanup.Flag = $True
$newRunspace =[runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"          
$newRunspace.Open()        
$newRunspace.SessionStateProxy.SetVariable("jobCleanup",$jobCleanup)     
$newRunspace.SessionStateProxy.SetVariable("jobs",$jobs) 
$jobCleanup.PowerShell = [PowerShell]::Create().AddScript({
    #Routine to handle completed runspaces
    Do {    
        Foreach($runspace in $jobs) {            
            If ($runspace.Runspace.isCompleted) {
                [void]$runspace.powershell.EndInvoke($runspace.Runspace)
                $runspace.powershell.dispose()
                $runspace.Runspace = $null
                $runspace.powershell = $null               
            } 
        }
        #Clean out unused runspace jobs
        $temphash = $jobs.clone()
        $temphash | Where-Object {
            $_.runspace -eq $Null
        } | ForEach-Object {
            $jobs.remove($_)
        }        
        Start-Sleep -Seconds 1     
    } while ($jobCleanup.Flag)
})
$jobCleanup.PowerShell.Runspace = $newRunspace
$jobCleanup.Thread = $jobCleanup.PowerShell.BeginInvoke()  
#endregion Background runspace to clean up jobs
#=====================================================================================================================================================================================

#=====================================================================================================================================================================================
# Click Event Add Url
#=====================================================================================================================================================================================
$syncHash.WPFbtnAddUrl.Add_click({
    #Thread Creation
    $newRunspace =[runspacefactory]::CreateRunspace()
    $newRunspace.ApartmentState = "STA"
    $newRunspace.ThreadOptions = "ReuseThread"          
    $newRunspace.Open()
    $newRunspace.SessionStateProxy.SetVariable("SyncHash",$SyncHash) 
    $PowerShell = [PowerShell]::Create().AddScript({
        Add-Type -AssemblyName Microsoft.VisualBasic
        $url = [Microsoft.VisualBasic.Interaction]::InputBox('Enter a website url to monitor', 'url',"")
        if ($url -ne $null) {
            $syncHash.WPFUrlsList.Dispatcher.invoke([action]{$syncHash.WPFUrlsList.items.add($url)},"Normal")
        }
    })
    $PowerShell.Runspace = $newRunspace
    [void]$Jobs.Add((
        [pscustomobject]@{
            PowerShell = $PowerShell
            Runspace = $PowerShell.BeginInvoke()
        }
    ))
})
#=====================================================================================================================================================================================
#=====================================================================================================================================================================================
# Click Event check Url
#=====================================================================================================================================================================================
$syncHash.WPFbtnCheck.Add_click({
    #Thread Creation
    $Script:checkRunspace =[runspacefactory]::CreateRunspace()
    $checkRunspace.ApartmentState = "STA"
    $checkRunspace.ThreadOptions = "ReuseThread"         
    $checkRunspace.Open()
    $checkRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    $PowerShellcheck = [PowerShell]::Create().AddScript({
        if ($syncHash.TimerBox.SelectedItem -eq "24H"){
            $timer = 1440
        }
        elseif ($syncHash.TimerBox.SelectedItem -eq "48H") {
            $timer = 2880
        }
        for ($i=0;$i -le $timer;$i++){
            foreach ($url in $syncHash.WPFUrlsList.items) {
                if ($url -ne $null){
                    $Time = Measure-Command { $httpReq = Invoke-WebRequest -uri $url -ErrorAction SilentlyContinue } 
                    $date=Get-Date
                    if ($httpReq.StatusCode -eq "200"){
                        $outputOK = "$date :: $url is responding correctly :: OK HTTP "+$httpReq.StatusCode+" in "+$Time.TotalSeconds+" second response time"
                        $syncHash.WPFConsole.Dispatcher.invoke([action]{$syncHash.WPFConsole.items.add($outputOK)},"Normal")
                        $outputOK | out-file -filepath "$url.log"  -Encoding default -Append
                    }
                    if ($httpReq.StatusCode -eq $null){
                        $outputNOK =  "$date ::  $url not responding WARNING :: ERROR HTTP "+$httpReq.StatusCode+" in"+$Time.TotalSeconds+" second response time"
                        $syncHash.WPFConsole.Dispatcher.invoke([action]{$syncHash.WPFConsole.items.add($outputNOK)},"Normal")
                        $outputNOK | out-file -filepath "$url.log"  -Encoding default -Append
                    }
                }
            }
            start-sleep -s 59 # wait in seconds before looping aagain 
        }
    })
    $PowerShellcheck.Runspace = $checkRunspace
    $PowerShellcheck.Thread = $PowerShellcheck.BeginInvoke()  
})
#=====================================================================================================================================================================================

#=====================================================================================================================================================================================
# Click Event Stop Checks
#=====================================================================================================================================================================================
$syncHash.WPFbtnStop.Add_click({
    #kill urls checks
    $checkRunspace.Close()
})

#=====================================================================================================================================================================================

#=====================================================================================================================================================================================
# Region Window Close 
#=====================================================================================================================================================================================
$syncHash.Window.Add_Closed({
    $jobCleanup.Flag = $False
    #Stop all runspaces
    $jobCleanup.PowerShell.Dispose() 
})
#=====================================================================================================================================================================================

$syncHash.Window.ShowDialog() | Out-Null
$syncHash.Error = $Error
})

#=====================================================================================================================================================================================
# Start AppScript
#=====================================================================================================================================================================================
$psCmd.Runspace = $newRunspace
$data = $psCmd.BeginInvoke()
#=====================================================================================================================================================================================


