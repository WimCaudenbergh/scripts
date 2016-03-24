# Run script as admin
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
if ($myWindowsPrincipal.IsInRole($adminRole))

   {
   # Running as admin, change colours
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host

   }
else
   {
   #not running as admin, reopen powershell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   $newProcess.Verb = "runas";
   [System.Diagnostics.Process]::Start($newProcess);

   exit

   }

   
Write-Host "`n Start of script:" + (Get-Date).DateTime

#Get files from our ftp server and prepare them for install

$ftpSEP = "ftp://ftp.uf.be/Roll/SymantecExtractor.exe"  
$localSEP = "C:\TEMP\SymantecExtractor.exe"  

$ftpIntuneInstall = "ftp://ftp.uf.be/Roll/Microsoft_Intune_Setup.exe"  
$localIntuneInstall = "C:\TEMP\Microsoft_Intune_Setup.exe"  

$ftpIntuneCert = "ftp://ftp.uf.be/Roll/MicrosoftIntune.accountcert"  
$localIntuneCert = "C:\TEMP\MicrosoftIntune.accountcert"  

$user = "ufftp"  
$pass = "Pr!vat3FTPuf"  

$ftpclient = New-Object system.Net.WebClient
$ftpclient.Credentials = new-object System.Net.NetworkCredential($user, $pass)

$uriSEP = New-Object System.Uri($ftpSEP)
$uriIntuneInstall = New-Object System.Uri($ftpIntuneInstall)
$uriIntuneCert = New-Object System.Uri($ftpIntuneCert)


$destDir = "C:\TEMP"
 
If (!(Test-Path $destDir)) {
  New-Item -Path $destDir -ItemType Directory
}
else {
  Write-Host "Directory already exists!"
}


Write-Host "`ndownloading: $ftpSEP"
$ftpclient.DownloadFile($uriSEP,$localSEP)
Write-Host "Finished, saved at: $localSEP`n"

Write-Host "downloading: $ftpIntuneInstall"
$ftpclient.DownloadFile($uriIntuneInstall,$localIntuneInstall)
Write-Host "Finished, saved at: $localIntuneInstall`n"

Write-Host "downloading: $ftpIntuneCert"
$ftpclient.DownloadFile($uriIntuneCert,$localIntuneCert)
Write-Host "Finished, saved at: $localIntuneCert"


#execute installers

push-location "C:\TEMP";
$exe = "SymantecExtractor.exe"  
$proc = (Start-Process $exe -PassThru)
$proc | Wait-Process

Write-Host "`n Installed SEP Cloud at:" + (Get-Date).DateTime

push-location "C:\TEMP";
$exe = "Microsoft_Intune_Setup.exe"  
$proc = (Start-Process $exe -PassThru)
$proc | Wait-Process

Write-Host "`n Installed Intune at:" + (Get-Date).DateTime
Write-Host "Allow some time to let Intuen fully install."


PAUSE
