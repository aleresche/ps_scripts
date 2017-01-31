<#
.Synopsis
   	Copy Printer config to another computer
.DESCRIPTION
    Get local printer install them on a remote machine
.EXAMPLE
	./copy-printer.ps1
.NOTES
   	Version 1.0
   	Written by Arnaud Leresche
#>

#Retrieve Printers 
$printers = get-printer


invoke-command -ComputerName $CompClient -ScriptBlock {
    foreach ($prt in $printers){
        if ($_.ComputerName -eq "bluesvprinter") {
            set-printer -InputObject $_ 
        }
    } 
}