$syncHash = [hashtable]::Synchronized(@{})
$newRunspace =[runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"         
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)          
$psCmd = [PowerShell]::Create().AddScript({   
    [xml]$xaml = @"
    <Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window" Title="Initial Window" WindowStartupLocation = "CenterScreen"
    Width = "600" Height = "800" ShowInTaskbar = "True">
    <TextBox x:Name = "textbox" Height = "400" Width = "600"/>
    </Window>
"@
  
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
    $syncHash.TextBox = $syncHash.window.FindName("textbox")
    $syncHash.Window.ShowDialog() | Out-Null
    $syncHash.Error = $Error
})
$psCmd.Runspace = $newRunspace
$data = $psCmd.BeginInvoke()


Function Update-Window {
    Param (
        $Title,
        $Content,
        [switch]$AppendContent
    )
    $syncHash.textbox.Dispatcher.invoke([action]{
        $syncHash.Window.Title = $title
        If ($PSBoundParameters['AppendContent']) {
            $syncHash.TextBox.AppendText($Content)
        } Else {
            $syncHash.TextBox.Text = $Content
        }
    },
    "Normal")
}



Update-Window -Title ("Services on {0}" -f $Env:Computername) -Content (Get-Service | Sort-Object Status -Desc| out-string)

