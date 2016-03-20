Import-Module ".\changeDevices.psm1"

$devicesXML = Get-DevicesXML 

# $devicesXML.devices.device

foreach( $device in $devicesXML.devices.device) 
{ 
    Write-Host $device.name
} 