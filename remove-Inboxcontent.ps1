$mailbox = Get-Mailbox arnaud.leresche@alvean.onmicrosoft.com
$mailAddress = $mailbox.PrimarySmtpAddress.ToString();

$TestUrlCallback = {
 param ([string] $url)
 if ($url -eq "https://autodiscover-s.outlook.com/autodiscover/autodiscover.xml") {$true} else {$false}
}


[Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll") | Out-Null
#$s = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2010)
$s = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService -ArgumentList "Exchange2007_SP1"
$s.AutodiscoverUrl($mailAddress,$TestUrlCallback);
 
$ItemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView(10000)
$MailboxRootid = new-object  Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$mailAddress)
$MailboxRoot = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($s,$MailboxRootid)
 
# Get Folder ID from Path
Function GetFolder()
{
	# Return a reference to a folder specified by path
 
	$RootFolder, $FolderPath = $args[0];
 
	$Folder = $RootFolder;
	if ($FolderPath -ne '\')
	{
		$PathElements = $FolderPath -split '\\';
		For ($i=0; $i -lt $PathElements.Count; $i++)
		{
			if ($PathElements[$i])
			{
				$View = New-Object  Microsoft.Exchange.WebServices.Data.FolderView(2,0);
				$View.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Deep;
				$View.PropertySet = [Microsoft.Exchange.WebServices.Data.BasePropertySet]::IdOnly;
 
				$SearchFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName, $PathElements[$i]);
 
				$FolderResults = $Folder.FindFolders($SearchFilter, $View);
				if ($FolderResults.TotalCount -ne 1)
				{
					# We have either none or more than one folder returned... Either way, we can't continue
					$Folder = $null;
					Write-Host "Failed to find " $PathElements[$i];
					Write-Host "Requested folder path: " $FolderPath;
					break;
				}
 
				$Folder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($s, $FolderResults.Folders[0].Id)
			}
		}
	}
 
	$Folder;
}
 
 
try {
 
	$FolderObject = GetFolder($MailboxRoot, "Inbox");
#Date from and To
    $findItemResults = $FolderObject.FindItems("System.Message.DateReceived:01/01/2014..01/31/2017",$ItemView)
 
        foreach ($item in $findItemResults.Items) {
 
                try {
#Comment Below out to not delete
                    [void]$item.Delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::HardDelete)
                    $Deleted ++
#Uncomment below to list before deleting
					Write-host $item.DateTimeReceived 
                } catch {
                    Write-warning "Unable to delete item, $($item.subject).  $($Error[0].Exception.Message)"
                }
            }        
 
 
    if ($Deleted -gt 0) { Write-host "$Deleted mail items deleted from the Inbox." }
} catch {
    Write-warning "Could not connect to Inbox.  $( $_.exception.message )"
}