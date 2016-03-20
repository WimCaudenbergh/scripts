#variables
##list with missing items based on previous check
$fdmissing = "C:\scripts\fd-removedfiles.txt"
##list with current files
$fdcurrent = "C:\scripts\fd-list.txt"
##folder to check recursively
$fdfolder = "C:\test"
##send mails to 
$mailto = "wim.caudenbergh@userfull.be"



#compare files from previous check with current files
$exists = @{}
ForEach ($file in (Get-Content $fdcurrent))
{
	$existsResult = Test-Path $file
	$exists.add($file, $existsResult)
}

#uncomment to see the compared files
# $exists.GetEnumerator() | Sort-Object Value

#write all missing items to file
Clear-Content $fdmissing
$missing = $exists.GetEnumerator() |  where-object {$_.Value -in "False" } 
$missing >> $fdmissing

#create a list of current files and put them in list.txt
Clear-Content $fdcurrent
Get-ChildItem $fdfolder -recurse | foreach{$_.Fullname >> $fdcurrent}


#Send mail with missing items if there are any
If ((Get-Content $fdmissing) -ne $Null) {
	
	#Via office365 - not working yet
	#$pass = cat C:\scripts\pw.txt | convertto-securestring                                                            
	#$mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist "automator@uf365.be",$pass  
	#send-mailmessage -to "wim.caudenbergh@userfull.be" -from "automator@uf365.be" -subject "Test mail" -smtpServer "smtp.office365.com" -Credential $mycred -UseSsl
	
	send-mailmessage -to $mailto -from "filechecker@fiskodata.be" -subject "Filecheck - There were files missing." -smtpServer "relay.skynet.be" -body  $($missing | Out-String) 

}else
{
	write-host "no files missing"
}



 
