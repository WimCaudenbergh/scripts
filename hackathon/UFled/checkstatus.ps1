$xml = New-Object System.Xml.XmlDocument
$web = New-Object Net.WebClient

Clear-Content "c:\scripts\hackathon\UFled\out.txt"

Function Start-Monitoring
{
    While ($true)
    {
		$xml.Load("https://monitor.uf.be/api/getobjectstatus.htm?id=25272&name=status&show=text&username=ufadmin&passhash=560266657")
		# $xml.prtg.result | add-content -path "c:\scripts\hackathon\UFled\out.txt"
		$status = $xml.prtg.result 
		write-host $status
		if ($status -like '*up*') { 
			$web.DownloadString("http://192.168.76.105/state/green")
		}elseif($status -like '*down*'){
			$web.DownloadString("http://192.168.76.105/state/red")
		}else{
			$web.DownloadString("http://192.168.76.105/state/blue")
		}

		
        Start-Sleep -s 1
    }
}

Start-Monitoring