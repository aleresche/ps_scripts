<#
.Synopsis
   	Powershell script that create Self sign cert
.DESCRIPTION
   	Create Self sign using powershell module
.EXAMPLE
	./make-aitselfsignedssl.ps1 -certname -passwd -
.NOTES
    Version 0.1
    Written by Arnaud Leresche
#>
######################################################################################################################################################################################################
#Parameters
######################################################################################################################################################################################################
Param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $certname,
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]  
    [string] $passwd
)
# Creating CA Root
$caroot = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "AIT Local Certificate Authority" -KeyusageProperty All -KeyUsage CertSign, CRLSign, DigitalSiganture
# Creating Client Cert
$certpath = 'cert:\localmachine\my\'
$cert = New-SelfSignedCertificate -Subject "*.testing.local"  -DnsName "*.testing.local, testing.local" -CertStoreLocation $certpath  -Signer $caroot
# Export it to PFX file
$password = ConvertTo-SecureString -String $passwd -Force -AsPlainText
$certpath = $path + $cert.Thumbprint
Export-PfxCertificate -Cert $certpath -FilePath "$PWD.Path\$certname.pfx" -Password $password 