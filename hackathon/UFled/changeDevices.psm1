function Get-ScriptDirectory {
    Split-Path -Parent $PSCommandPath
}

$DefaultPath = Get-ScriptDirectory
$DefaultPath += ".\connectedDevices.xml"

Function Get-DevicesXML($XMLpath = $DefaultPath){
    $DeviceXML = New-Object XML
    $DeviceXML.Load($XMLpath)
    $DeviceXML
}