Import-Module ".\changeDevices.psm1"

$xml = New-Object System.Xml.XmlDocument
$web = New-Object Net.WebClient
$devicesXML = Get-DevicesXML 
$DevicesLoaded = 0
Set-Variable -name DevicesLoaded -scope Script
$DeviceRefreshTime = 5
$NextRefresh = $DeviceRefreshTime

Function Start-Monitoring
{
    While ($true)
    {
		
        Update-DeviceXML
    
        $xml.Load("https://monitor.uf.be/api/getobjectstatus.htm?id=25272&name=status&show=text&username=ufadmin&passhash=560266657")
		
		$status = $xml.prtg.result 
    
        $NextRefresh = $DeviceRefreshTime - $DevicesLoaded
		write-host "Sensor status: $status             Next device refresh in: $NextRefresh"

		# if ($status -like '*up*') { 
		# 	$web.DownloadString("http://192.168.76.105/state/green")
		# }elseif($status -like '*down*'){
		# 	$web.DownloadString("http://192.168.76.105/state/red")
		# }else{
		# 	$web.DownloadString("http://192.168.76.105/state/blue")
		# }

		
        Start-Sleep -s 1
    }
}

Function Update-DeviceXML
{
    # update devices if not updated a minute ago

    if ($DevicesLoaded -ge $DeviceRefreshTime) {
        $devicesXML = Get-DevicesXML   
        write-host "current devices loaded:"
        $devicesXML.devices.device
        
        $Script:DevicesLoaded = 0 
    }else {
        $Script:DevicesLoaded += 1
    }    
}

Start-Monitoring