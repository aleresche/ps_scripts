$Runspace = [runspacefactory]::CreateRunspace()

$PowerShell = ::Create(void)

$PowerShell.runspace = $Runspace

$Runspace.Open()

[void]$PowerShell.AddScript({

    Get-Date

})

$PowerShell.Invoke()