Import-Module ".\changeDevices.psm1"

$xml = New-Object System.Xml.XmlDocument
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
         
        foreach( $device in $devicesXML.devices.device) 
        { 
            if ($device.ESP -eq "True") {
                Update-DeviceState $device.name
            }
        }  

        write-host $newline "-----    Next refresh in $NextRefresh loop(s)    -----" $newline

        Start-Sleep -s 5
    }
}


Function Update-DeviceState($name)
{

    $Script:deviceNode = $Script:devicesXML.devices.device | where {$_.name -eq $name}


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
              
        Write-Comment 1 $name $s $state

        $deviceNode.currentState = $state
       
        Update-LedState $deviceNode.ip $state
    }elseif($deviceNode.LEDupToDate -eq "False"){
        
        Write-Comment 2 $name

        Update-LedState $deviceNode.ip $state
    }else{

        Write-Comment 3 $name

    }

}

Function Update-LedState($ip, $state)
{

    $ESPurl = "http://$ip/state/$state"
    # $ESPurl = "http://google.be"

    Write-Comment 4 $ip $state $ESPurl

    #try invoking the ESP url that switches the LEDs. Do nothing if the page times out. 
    try {
        Invoke-WebRequest $ESPurl -TimeoutSec 3  > $null 

    }catch{
        write-host $newline "Timed out while requesting $ESPurl" $newline
        $timeout=$true
        
    }

    if (!$timeout) {
        write-host "Connected to webserver. LED should be up to date."
        $Script:deviceNode.LEDupToDate = "True"
        $timeout=$false
    }

}

Function Update-DeviceXML
{
    # update devices after a couple of loops

    if ($DevicesLoaded -ge $DeviceRefreshTime) {
        $Script:devicesXML = Get-DevicesXML   
        $Script:DevicesLoaded = 0 

        Write-host "Updating the device list. Resetting status of devices to " -nonewline;
        write-host "Unchecked" -foregroundcolor red

    }else {
        $Script:DevicesLoaded += 1
    }    
}


Function Write-Comment($case, $nameorip, $state1, $state2)
{
    switch ($case) 
    { 
        1 
        {
            write-host $newline"Change state of " -nonewline; 
            write-host "$nameorip " -nonewline -foregroundcolor yellow; 
            write-host "from " -nonewline;
            write-host "$state1 " -nonewline -foregroundcolor red;
            write-host "to " -nonewline;
            write-host "$state2" -foregroundcolor red   
        }

        2 
        {
            write-host $newline"State of " -nonewline; 
            write-host "$nameorip " -nonewline -foregroundcolor yellow; 
            write-host "not changed. But the LED is not up to date. Trying again."
        } 
        
        3 
        {
            write-host $newline"State of " -nonewline; 
            write-host "$nameorip " -nonewline -foregroundcolor yellow; 
            write-host "not changed. Skipping" 
        } 
        
        4 
        {
            write-host "Set LED-state to " -nonewline; 
            write-host "$state1 " -nonewline -foregroundcolor red; 
            write-host "on "  -nonewline; 
            write-host "$nameorip" -nonewline -foregroundcolor yellow; 
            write-host "       ==>  $state2" -foregroundcolor green
        } 
        5 {"The color is orange."} 
        default {"Write-Comment function error, wrong parameters given."}
    }

}


Start-Monitoring