Function Semail([string]$bod, [string]$sub){
	$sub += " HOSTHV"
	Write-Host $sub
	$EmailFrom = "HostHV@kvkhv.be”
	$EmailTo = “monitor@userfull.be"
	$Subject = $sub
	$Body = @()
	$Body += $bod
	$SMTPServer = “relay.skynet.be”
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
}

Function SemailFailed(){
	$EmailFrom = "HostHV@kvkhv.be”
	$EmailTo = “monitor@userfull.be"
	$Subject = "'Microsoft Hyper-V VSS Writer' HOSTHV"
	$Body = "Status: Failed --- The hyperV service - on HostHV - stopped working! Restart the service."
	$Body += $bod
	$SMTPServer = “relay.skynet.be”
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
}

Function ProcessWriters([string]$c, [string]$Writer1, [string]$Writer2)
{
	$pos1 = $pos1 = $c.IndexOf($Writer1)
	$pos2 = $b.IndexOf($Writer2)
	$writer = $b.Substring($pos1, $pos2-$pos1)

	$Writer1 = $Writer1.Replace("Writer name: ","")

	Semail $writer $Writer1
}

$a = (vssadmin list writers)
$b = [string]$a
$b = $b.Replace("vssadmin 1.1 - Volume Shadow Copy Service administrative command-line tool (C) Copyright 2001-2005 Microsoft Corp. ","")


$WriterName1 = "Writer name: 'Task Scheduler Writer'"
$WriterName2 = "Writer name: 'VSS Metadata Store Writer'"
$WriterName3 = "Writer name: 'Performance Counters Writer'"
$WriterName8 = "Writer name: 'Microsoft Hyper-V VSS Writer'"
$WriterName4 = "Writer name: 'ASR Writer'"
$WriterName5 = "Writer name: 'Shadow Copy Optimization Writer'"
$WriterName6 = "Writer name: 'Registry Writer'"
$WriterName7 = "Writer name: 'COM+ REGDB Writer'"

if($b.Contains($WriterName8)){

ProcessWriters $b $WriterName8 $WriterName4


}else{

#if the hyperv service doensn't exist - use this code to check the status of the writers.
#ProcessWriters $b $WriterName1 $WriterName2
#ProcessWriters $b $WriterName2 $WriterName3
#ProcessWriters $b $WriterName3 $WriterName4
#ProcessWriters $b $WriterName4 $WriterName5
#ProcessWriters $b $WriterName5 $WriterName6
#ProcessWriters $b $WriterName6 $WriterName7

#$pos7 = $b.IndexOf($WriterName7)
#$writer7 = $b.Substring($pos7)
#$WriterName7 = $WriterName7.Replace("Writer name: ","")
#Semail $writer7 $WriterName7

SemailFailed

}



Start-Sleep -s 15

