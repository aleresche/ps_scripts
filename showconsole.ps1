[xml]$xaml= @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="HideWindow" Title="Initial Window" WindowStartupLocation = "CenterScreen" 
    Width = "335" Height = "208" ShowInTaskbar = "True" Background = "lightgray">
    <Grid Height="159" Name="grid1" Width="314">
        <TextBox Height="46" HorizontalAlignment="Left" Margin="44,30,0,0" Name="textBox" VerticalAlignment="Top" Width="199" />
        <CheckBox Content="Show PS Windpw" Height="52" HorizontalAlignment="Left" Margin="34,95,0,0" Name="checkBox" VerticalAlignment="Top" Width="226" FontSize="15" />
    </Grid>
</Window>
"@
Add-Type -AssemblyName PresentationFramework
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load( $reader )

Write-Host -ForegroundColor Cyan -Object "Welcome to the Hide/Show Console Demo"
Write-Host -ForegroundColor Green -Object "Demo by DexterPOSH"
#Tie the Controls
$CheckBox = $Window.FindName('checkBox')
$textbox = $Window.FindName('textBox')


#Function Definitions
# Credits to - http://powershell.cz/2013/04/04/hide-and-show-console-window-from-gui/
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

function Show-Console {
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 5)
}

function Hide-Console {
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)
}

Hide-Console # hide the console at start
#Events
Write-host -ForegroundColor Red "Warning : There is an issue"
$CheckBox.Add_Checked({$textbox.text = "Showing PS Window"; Show-Console})
$CheckBox.Add_UnChecked({$textbox.text = "Hiding PS Window"; Hide-Console})
$Window.ShowDialog() | Out-Null