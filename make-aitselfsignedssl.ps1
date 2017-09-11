<#
.Synopsis
   	Powershell script that create Self sign cert
.DESCRIPTION
   	Create Self sign using powershell module
.EXAMPLE
	./set-aitprdquery.ps1
.NOTES
    Version 0.1
    Written by Arnaud Leresche
#>
$certname
$certpath = 'cert:\localmachine\my\'

$cert = New-SelfSignedCertificate 
$password = ConvertTo-SecureString -String 'Passw0rd!' -Force -AsPlainText
$certpath = $path + $cert.Thumbprint

Export-PfxCertificate -Cert $certpath -FilePath "$PWD.Path\$certname.pfx" -Password $password 