
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

if ($myWindowsPrincipal.IsInRole($adminRole)){

    Write-host "Adding the UF led updater as a service."

    New-Item -ItemType Directory -Force -Path C:\UFled
    Copy-Item .\UFled\* C:\UFled
    C:\UFled\installService.ps1
    net start UFled

}else{

    Write-host "Please open Powershell as Administrator."
}

