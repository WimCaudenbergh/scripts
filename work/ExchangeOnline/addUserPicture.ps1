#needs proxy method for high res photos
$ExSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/?proxymethod=rps -Credential $MSOLCred -Authentication Basic -AllowRedirection

$user = 'john.doe@contoso.com'

$userphoto = "C:\Temp\"+$user+".jpg"

Set-UserPhoto -Identity $user -PictureData ([System.IO.File]::ReadAllBytes($userphoto)) -Confirm:$false


