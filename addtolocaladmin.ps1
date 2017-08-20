# use one line to add a user to a local group
$Computer = 'BLUELTSPARE79'
$Group = 'Administrators'
$Domain = 'b-i.ch'
$User = 'admin_aleresche'
([ADSI]"WinNT://$computer/$Group,group").psbase.Invoke("Add",([ADSI]"WinNT://$domain/$user").path)