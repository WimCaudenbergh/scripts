$prtghost="monitor.uf.be"
$username="ufadmin";
$passhash="2651545647"

$Sensors = ((Invoke-WebRequest -URI "https://$($prtghost)/api/table.json?content=sensors&output=json&columns=objid,device,sensor&filter_status=7&username=$($username)&passhash=$($passhash)").Content | ConvertFrom-Json)
$Devices = ((Invoke-WebRequest -URI "https://$($prtghost)/api/table.json?content=devices&output=json&columns=objid,device&filter_status=7&username=$($username)&passhash=$($passhash)").Content | ConvertFrom-Json)
$Groups = ((Invoke-WebRequest -URI "https://$($prtghost)/api/table.json?content=groups&output=json&columns=objid,device,group&filter_status=7&username=$($username)&passhash=$($passhash)").Content | ConvertFrom-Json)

Write-Host "[Unpausing groups]"
Foreach($Group in $Groups.groups){
    Write-Host "Resuming $($Group.group)..." -NoNewline
    Invoke-WebRequest -Uri "https://$($prtghost)/api/pause.htm?id=$($Group.objid)&action=1&username=$($username)&passhash=$($passhash)" | Out-Null
    Write-Host "done." -NoNewline -ForegroundColor Green
    Write-Host "`r"
}

Write-Host "[Unpausing devices]"
Foreach($Device in $Devices.devices){
    Write-Host "Resuming $($Device.device)..." -NoNewline
    Invoke-WebRequest -Uri "https://$($prtghost)/api/pause.htm?id=$($Device.objid)&action=1&username=$($username)&passhash=$($passhash)" | Out-Null
    Write-Host "done." -NoNewline -ForegroundColor Green
    Write-Host "`r"
}
Write-Host "[Unpausing sensors]"
Foreach($Sensor in $Sensors.sensors){
    Write-Host "Resuming $($Sensor.sensor) on $($Sensor.device)..." -NoNewline
    Invoke-WebRequest -Uri "https://$($prtghost)/api/pause.htm?id=$($Sensor.objid)&action=1&username=$($username)&passhash=$($passhash)" | Out-Null
    Write-Host "done." -NoNewline -ForegroundColor Green
    Write-Host "`r"
}
