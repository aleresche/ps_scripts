$Runspace = [runspacefactory]::CreateRunspace()

$PowerShell =  [System.Management.Automation.PowerShell]::Create()

$PowerShell.runspace = $Runspace

$Runspace.Open()

[void]$PowerShell.AddScript({

    Get-Date

})

$PowerShell.Invoke()