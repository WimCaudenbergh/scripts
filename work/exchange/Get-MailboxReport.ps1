﻿<#
.SYNOPSIS
Get-MailboxReport.ps1 - Mailbox report generation script.

.DESCRIPTION 
Generates a report of useful information for
the specified server, database, mailbox or list of mailboxes.
Use only one parameter at a time depending on the scope of
your mailbox report.

.OUTPUTS
Single mailbox reports are output to the console, while all other
reports are output to a CSV file.

.PARAMETER all
Generates a report for all mailboxes in the organization.

.PARAMETER server
Generates a report for all mailboxes on the specified server.

.PARAMETER database
Generates a report for all mailboxes on the specified database.

.PARAMETER file
Generates a report for mailbox names listed in the specified text file.

.PARAMETER mailbox
Generates a report only for the specified mailbox.

.PARAMETER filename
(Optional) Specifies the CSV file name to be used for the report.
If no file name specificed then a unique file name is generated by the script.

.EXAMPLE
.\Get-MailboxReport.ps1 -database HO-MB-01
Returns a report with the mailbox statistics for all mailbox users in
database HO-MB-01

.EXAMPLE
.\Get-MailboxReport.ps1 -file .\users.txt
Returns a report with the mailbox statistics for all mailbox users in
the file users.txt. Text file should contain names in a format that
will work for Get-Mailbox, such as the display name, alias, or primary
SMTP address.

.EXAMPLE
.\Get-MailboxReport.ps1 -server ex2010-mb1
Generates a report with the mailbox statisitcs for all mailbox users
on ex2010-mb1

.EXAMPLE
.\Get-MailboxReport.ps1 -server ex2010-mb1 -filename ex2010-mb1.csv
Generates a report with the mailbox statisitcs for all mailbox users
on ex2010-mb1, and uses the custom file name of ex2010-mb1.csv

.LINK
http://exchangeserverpro.com/powershell-script-create-mailbox-size-report-exchange-server-2010

.NOTES
Written By: Paul Cunningham
Website:	http://exchangeserverpro.com
Twitter:	http://twitter.com/exchservpro

Additional Credits:
Chris Brown, http://www.flamingkeys.com
Boe Prox, http://learn-powershell.net/

Change Log
V1.00, 2/2/2012 - Initial version
V1.01, 27/2/2012 - Improved recipient scope settings, exception handling, and custom file name parameter.
V1.02, 16/10/2012 - Reordered report fields, added OU, primary SMTP, some specific folder stats,
                    archive mailbox info, and updated to show DAG name for databases when applicable.

#>

#requires -version 2

param(
	[Parameter(ParameterSetName='database')] [string]$database,
	[Parameter(ParameterSetName='file')] [string]$file,
	[Parameter(ParameterSetName='server')] [string]$server,
	[Parameter(ParameterSetName='mailbox')] [string]$mailbox,
	[Parameter(ParameterSetName='all')] [switch]$all,
	[string]$filename
)

#...................................
# Variables
#...................................

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
$report = @()


#...................................
# Initialize
#...................................

#Set recipient scope
$2007snapin = Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.Admin
if ($2007snapin)
{
	$AdminSessionADSettings.ViewEntireForest = 1
}
else
{
	$2010snapin = Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010
	if ($2010snapin)
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
}


#If no filename specified, generate report file name with random strings for uniqueness
#Thanks to @proxb and @chrisbrownie for the help with random string generation

if ($filename)
{
	$reportfile = $filename
}
else
{
	$timestamp = Get-Date -UFormat %Y%m%d-%H%M
	$random = -join(48..57+65..90+97..122 | ForEach-Object {[char]$_} | Get-Random -Count 6)
	$reportfile = "MailboxReport-$timestamp-$random.csv"
}


#...................................
# Script
#...................................

#Add dependencies
Import-Module ActiveDirectory

#Get the mailbox list

Write-Host -ForegroundColor White "Collecting mailbox list"

if($all) { $mailboxes = @(Get-Mailbox -resultsize unlimited -IgnoreDefaultScope) }

if($server) { $mailboxes = @(Get-Mailbox -server $server -resultsize unlimited -IgnoreDefaultScope) }

if($database){ $mailboxes = @(Get-Mailbox -database $database -resultsize unlimited -IgnoreDefaultScope) }

if($file) {	$mailboxes = @(Get-Content $file | Get-Mailbox -resultsize unlimited) }

if($mailbox) { $mailboxes = @(Get-Mailbox $mailbox) }

#Get the report

Write-Host -ForegroundColor White "Collecting report data"

$mailboxcount = $mailboxes.count
$i = 0

$mailboxdatabases = @(Get-MailboxDatabase)

#Loop through mailbox list and collect the mailbox statistics
foreach ($mb in $mailboxes)
{
	$i = $i + 1
	$pct = $i/$mailboxcount * 100
	Write-Progress -Activity "Collecting mailbox details" -Status "Processing mailbox $i of $mailboxcount - $mb" -PercentComplete $pct

	$stats = $mb | Get-MailboxStatistics | Select-Object TotalItemSize,TotalDeletedItemSize,ItemCount,LastLogonTime,LastLoggedOnUserAccount
    
    if ($mb.ArchiveDatabase)
    {
        $archivestats = $mb | Get-MailboxStatistics -Archive | Select-Object TotalItemSize,TotalDeletedItemSize,ItemCount
    }
    else
    {
        $archivestats = "n/a"
    }

    $inboxstats = Get-MailboxFolderStatistics $mb -FolderScope Inbox | Where {$_.FolderPath -eq "/Inbox"}
    $sentitemsstats = Get-MailboxFolderStatistics $mb -FolderScope SentItems | Where {$_.FolderPath -eq "/Sent Items"}
    $deleteditemsstats = Get-MailboxFolderStatistics $mb -FolderScope DeletedItems | Where {$_.FolderPath -eq "/Deleted Items"}
    #FolderandSubFolderSize.ToMB()

	$lastlogon = $stats.LastLogonTime

	$user = Get-User $mb
	$aduser = Get-ADUser $mb.samaccountname -Properties Enabled,AccountExpirationDate

	#Create a custom PS object to aggregate the data we're interested in
	
	$userObj = New-Object PSObject
	$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $mb.DisplayName
	$userObj | Add-Member NoteProperty -Name "Mailbox Type" -Value $mb.RecipientTypeDetails
	$userObj | Add-Member NoteProperty -Name "Title" -Value $user.Title
    $userObj | Add-Member NoteProperty -Name "Department" -Value $user.Department
    $userObj | Add-Member NoteProperty -Name "Office" -Value $user.Office

    $userObj | Add-Member NoteProperty -Name "Total Mailbox Size (Mb)" -Value ($stats.TotalItemSize.Value.ToMB() + $stats.TotalDeletedItemSize.Value.ToMB())
	$userObj | Add-Member NoteProperty -Name "Mailbox Size (Mb)" -Value $stats.TotalItemSize.Value.ToMB()
	$userObj | Add-Member NoteProperty -Name "Mailbox Recoverable Item Size (Mb)" -Value $stats.TotalDeletedItemSize.Value.ToMB()
	$userObj | Add-Member NoteProperty -Name "Mailbox Items" -Value $stats.ItemCount

    $userObj | Add-Member NoteProperty -Name "Inbox Folder Size (Mb)" -Value $inboxstats.FolderandSubFolderSize.ToMB()
    $userObj | Add-Member NoteProperty -Name "Sent Items Folder Size (Mb)" -Value $sentitemsstats.FolderandSubFolderSize.ToMB()
    $userObj | Add-Member NoteProperty -Name "Deleted Items Folder Size (Mb)" -Value $deleteditemsstats.FolderandSubFolderSize.ToMB()

    if ($archivestats -eq "n/a")
    {
        $userObj | Add-Member NoteProperty -Name "Total Archive Size (Mb)" -Value "n/a"
	    $userObj | Add-Member NoteProperty -Name "Archive Size (Mb)" -Value "n/a"
	    $userObj | Add-Member NoteProperty -Name "Archive Deleted Item Size (Mb)" -Value "n/a"
	    $userObj | Add-Member NoteProperty -Name "Archive Items" -Value "n/a"
    }
    else
    {
        $userObj | Add-Member NoteProperty -Name "Total Archive Size (Mb)" -Value ($archivestats.TotalItemSize.Value.ToMB() + $archivestats.TotalDeletedItemSize.Value.ToMB())
	    $userObj | Add-Member NoteProperty -Name "Archive Size (Mb)" -Value $archivestats.TotalItemSize.Value.ToMB()
	    $userObj | Add-Member NoteProperty -Name "Archive Deleted Item Size (Mb)" -Value $archivestats.TotalDeletedItemSize.Value.ToMB()
	    $userObj | Add-Member NoteProperty -Name "Archive Items" -Value $archivestats.ItemCount
    }

	$userObj | Add-Member NoteProperty -Name "Account Enabled" -Value $aduser.Enabled
	$userObj | Add-Member NoteProperty -Name "Account Expires" -Value $aduser.AccountExpirationDate
	$userObj | Add-Member NoteProperty -Name "Last Mailbox Logon" -Value $lastlogon
	$userObj | Add-Member NoteProperty -Name "Last Logon By" -Value $stats.LastLoggedOnUserAccount
    

    $db = $mailboxdatabases | where {$_.Name -eq $mb.Database.Name}
	$userObj | Add-Member NoteProperty -Name "Primary Mailbox Database" -Value $mb.Database
	$userObj | Add-Member NoteProperty -Name "Primary Server/DAG" -Value $db.MasterServerOrAvailabilityGroup

    $db = $mailboxdatabases | where {$_.Name -eq $mb.ArchiveDatabase.Name}
	$userObj | Add-Member NoteProperty -Name "Archive Mailbox Database" -Value $mb.ArchiveDatabase
	$userObj | Add-Member NoteProperty -Name "Archive Server/DAG" -Value $db.MasterServerOrAvailabilityGroup

    $userObj | Add-Member NoteProperty -Name "Primary Email Address" -Value $mb.PrimarySMTPAddress
    $userObj | Add-Member NoteProperty -Name "Organizational Unit" -Value $user.OrganizationalUnit

	
	#Add the object to the report
	$report = $report += $userObj
}

#Catch zero item results
$reportcount = $report.count

if ($reportcount -eq 0)
{
	Write-Host -ForegroundColor Yellow "No mailboxes were found matching that criteria."
}
else
{
	#Output single mailbox report to console, otherwise output to CSV file
	if ($mailbox) 
	{
		$report | Format-List
	}
	else
	{
		$report | Export-Csv -Path $reportfile -NoTypeInformation
		Write-Host -ForegroundColor White "Report written to $reportfile in current path."
		Get-Item $reportfile
	}
}
