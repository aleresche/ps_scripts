<#
.Synopsis
    Test UDP REMOTE Access Port
.DESCRIPTION
   	This script use Net Socket UDP client to set up a connection to a specific Machine & port, to test if the connection is open or closed
.EXAMPLE
	./test-portUDP.ps1 -RemoteComputer 80.80.230.75 -RemotePort 1194
.NOTES
   	Version 1.0
   	Written by Arnaud Leresche
#>
<#
.PARAMETERS
#>
Param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $RemoteComputer,  
    [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]  
    [int] $RemotePort
)
# Remote Computer & Port info
$Computername = $RemoteComputer
$Port = $RemotePort
# Create UDP client Object
$udpobject = new-Object system.Net.Sockets.Udpclient
$udpobject.Connect($Computername,$Port)
$udpobject.Client.ReceiveTimeout = 1000
# Create fake Data transmission
$a = new-object system.text.asciiencoding
$byte = $a.GetBytes("\x38\x01\x00\x00\x00\x00\x00\x00\x00")
[void]$udpobject.Send($byte,$byte.length)
# Try to send & receive
$remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)
Try {
    $receivebytes = $udpobject.Receive([ref]$remoteendpoint)
} Catch {
    Write-Warning "$($Error[0])"
}
If ($receivebytes) {
    [string]$returndata = $a.GetString($receivebytes)
    $returndata
} Else {
    "No data received from {0} on port {1}" -f $Computername,$Port
}
$udpobject.Close()
 

