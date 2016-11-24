$Runspace = [runspacefactory]::CreateRunspace()

$PowerShell = ::Create()

$PowerShell.runspace = $Runspace

$Runspace.Open()

[void]$PowerShell.AddScript({

    Get-Date

})

$PowerShell.Invoke()