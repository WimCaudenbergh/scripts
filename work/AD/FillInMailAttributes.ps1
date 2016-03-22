import-module ActiveDirectory

$UPN = $Args[0]

$firstname = (Get-ADUser -Identity $UPN -Properties *).givenname
$lastname = (Get-ADUser -Identity $UPN -Properties *).sn
echo "editing user $firstname $lastname"
echo "---------------"

$lastname = $lastname -replace '\s',''

$primarymail = $firstname+"."+$lastname+"@Userfull.be"


echo "Primary address"
echo "SMTP:$primarymail"


#aliassen aanmaken

echo "Aliasses"
$proxy1 = "smtp:"+$firstname+"."+$lastname+"@uf.be"

$proxy2 = "smtp:"+$firstname+"."+$lastname+"@userfull.com"

$proxy3 = "smtp:"+$UPN+"@uf.be"

$proxy4 = "smtp:"+$UPN+"@Userfull.com"

$proxy5 = "smtp:"+$UPN+"@Userfull.be"

echo $proxy1
echo $proxy2
echo $proxy3
echo $proxy4
echo $proxy5


Get-ADUser $UPN| Set-ADUser -EmailAddress "$primarymail"
Get-ADUser $UPN| Set-ADUser -Add @{proxyAddresses = "$proxy1"}
Get-ADUser $UPN| Set-ADUser -Add @{proxyAddresses = "$proxy2"}
Get-ADUser $UPN| Set-ADUser -Add @{proxyAddresses = "$proxy3"}
Get-ADUser $UPN| Set-ADUser -Add @{proxyAddresses = "$proxy4"}
Get-ADUser $UPN| Set-ADUser -Add @{proxyAddresses = "$proxy5"}

echo "---------------"
echo "checking AD object"

Get-ADUser -Identity $UPN -Properties mail,proxyaddresses | Select-Object name, proxyaddresses, mail
