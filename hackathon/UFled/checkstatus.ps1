Import-Module ".\changeDevices.psm1"

$xml = New-Object System.Xml.XmlDocument
# $web = New-Object Net.WebClient
$devicesXML = Get-DevicesXML 
$DevicesLoaded = 0
Set-Variable -name DevicesLoaded -scope Script
$DeviceRefreshTime = 5
$NextRefresh = $DeviceRefreshTime
$newline = [Environment]::NewLine
$deviceNode = $null
$state = "Unchecked"

Function Start-Monitoring
{
    While ($true)
    {
		
        Update-DeviceXML

        $NextRefresh = $DeviceRefreshTime - $DevicesLoaded
        
        # //TODO Loop all devices from XML file

        Update-DeviceState 'ESP Rack 1'
        # Update-DeviceState 'ESP Rack 2'
        # Update-DeviceState 'ESP Rack 3'
        write-host "-----"
        # foreach( $device in $devicesXML.devices.device) 
        # { 
        #     if ($device.ESP = "True") {
        #         $device
        #         Update-DeviceState 'ESP Rack 2'
        #     }
        # }  
        Start-Sleep -s 10
    }
}

Function Update-DeviceState($name)
{

    if ($deviceNode -eq $null) {
        $Script:deviceNode = $Script:devicesXML.devices.device | where {$_.name -eq $name}
    }
        
    $PRTGurl= "https://monitor.uf.be/api/getobjectstatus.htm?id=" + $deviceNode.PRTGidToCheck + "&name=status&show=text&username=ufadmin&passhash=560266657"
    $xml.Load($PRTGurl)
    $Script:state = $xml.prtg.result 

    #cut of the "(simulated error)" text if exists    
    if ($state -Match "simulated") 
    { 
        $state = $state.Substring(0, $state.IndexOf(' '))
    }    

    $state = $state.Trim()
    
    if ($deviceNode.currentState -ne $state) {
        $s = $deviceNode.currentState
        
        write-host $newline"Change state of " -nonewline; 
        write-host "$name " -nonewline -foregroundcolor yellow; 
        write-host "from " -nonewline;
        write-host "$s " -nonewline -foregroundcolor red;
        write-host "to " -nonewline;
        write-host "$state" -foregroundcolor red
        
        $deviceNode.currentState = $state
        $deviceNode
        Update-LedState $deviceNode.ip $state
    }

    # keep trying if timedout last time
    if ($deviceNode.LEDupToDate -eq "No") {
        Update-LedState $deviceNode.ip $state
    }


}

Function Update-LedState($ip, $state)
{

    $ESPurl = "http://$ip/state/$state"
    # $ESPurl = "http://google.be"
    write-host "Set LED-state to " -nonewline; 
    write-host "$state " -nonewline -foregroundcolor red; 
    write-host "on "  -nonewline; 
    write-host "$ip" -nonewline -foregroundcolor yellow; 
    write-host "       ==>  $ESPurl" -foregroundcolor green

    #try invoking the ESP url that switches the LEDs. Do nothing if the page times out. 
    try {
        Invoke-WebRequest $ESPurl -TimeoutSec 3  > $null 

    }catch{
        write-host $newline "Timed out while requesting $ESPurl" $newline
        $timeout=$true
        $deviceNode.name
    }

    if (!$timeout) {
        write-host "connected to webserver"
        $Script:deviceNode.LEDupToDate = "Yes"
        $timeout=$false
    }

}

Function Update-DeviceXML
{
    # update devices if not updated a minute ago

    if ($DevicesLoaded -ge $DeviceRefreshTime) {
        $Script:devicesXML = Get-DevicesXML   
      
        $Script:DevicesLoaded = 0 
    }else {
        $Script:DevicesLoaded += 1
    }    
}


Start-Monitoring