<#
.SYNOPSIS
Get-DAGHealth.ps1 - Exchange Server 2010/2013 Database Availability Group Health Check Script.

.DESCRIPTION 
Performs a series of health checks on the Database Availability Groups
and outputs the results to screen or HTML email.

.OUTPUTS
Results are output to screen or HTML email

.PARAMETER Detailed
When this parameter is used a more detailed report is shown in the output.

.PARAMETER HTMLFileName
When this parameter is used the HTML report is written to the file name you specify.

.PARAMETER SendEmail
Sends the HTML report via email using the SMTP configuration within the script.

.EXAMPLE
.\Get-DAGHealth.ps1
Checks all DAGs in the organization and outputs a health summary to the PowerShell window.

.EXAMPLE
.\Get-DAGHealth.ps1 -Detailed
Checks all DAGs in the organization and outputs a detailed health report to the PowerShell
window. Due to the amount of detail the full report may get cut off in your window. I recommend
detailed reports be output to HTML file or email instead.

.EXAMPLE
.\Get-DAGHealth.ps1 -Detailed -SendEmail
Checks all DAGs in the organization and outputs a detailed health report via email using
the SMTP settings you configure in the script.

.LINK
http://exchangeserverpro.com/get-daghealth-ps1-database-availability-group-health-check-script/

.NOTES
Written By: Paul Cunningham
Website:	http://exchangeserverpro.com
Twitter:	http://twitter.com/exchservpro

Change Log
V1.00, 14/02/2013 - Initial version
V1.01, 24/04/2013 - Bug fixes, Exchange 2013 testing
#>

[CmdletBinding()]
param(
	[Parameter( Mandatory=$false)]
	[switch]$SendEmail,
	
	[Parameter( Mandatory=$false)]
	[string]$HTMLFileName,
	
	[Parameter( Mandatory=$false)]
	[switch]$Detailed
	)

#...................................
# Variables
#...................................

$now = Get-Date -Format F

$dags = @()
[int]$replqueuewarning = 8
$reportbody = $null

#...................................
# Modify these SMTP settings to
# suit your environment
#...................................

$smtpsettings = @{
	To =  "administrator@exchangeserverpro.net"
	From = "exchangeserver@exchangeserverpro.net"
	Subject = "Exchange DAG Health Report - $now"
	SmtpServer = "smtp.exchangeserverpro.net"
	}


#...................................
# Functions
#...................................


#...................................
# Script
#...................................

#Add Exchange snapin if not already loaded
if (!(Get-PSSnapin | where {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"}))
{
	Write-Verbose "Loading the Exchange snapin"
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue
	. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
	Connect-ExchangeServer -auto -AllowClobber
}

Write-Verbose "Retrieving Database Availability Groups"
$dags = @(Get-DatabaseAvailabilityGroup -Status)
Write-Verbose "$($dags.count) DAGs found"

foreach ($dag in $dags)
{

	#Strings for use in the HTML report/email
	$summaryintro = "<p>Database Availability Group <strong>$($dag.Name)</strong> Health Summary:</p>"
	$detailintro = "<p>Database Availability Group <strong>$($dag.Name)</strong> Health Details:</p>"
	$memberintro = "<p>Database Availability Group <strong>$($dag.Name)</strong> Member Health:</p>"

	$dbcopyReport = @()		#Database copy health report
	$ciReport = @()			#Content Index health report
	$memberReport = @()		#DAG member server health report
	$databaseSummary = @()	#Database health summary report
	
	Write-Verbose "---- Processing DAG $($dag.Name)"
	
	$dagmembers = @($dag | Select-Object -ExpandProperty Servers | Sort-Object Name)
	Write-Verbose "$($dagmembers.count) DAG members found"
	
	$dagdatabases = @(Get-MailboxDatabase -Status | Where-Object {$_.MasterServerOrAvailabilityGroup -eq $dag.Name} | Sort-Object Name)
	Write-Verbose "$($dagdatabases.count) DAG databases found"
	
	foreach ($database in $dagdatabases)
	{
		Write-Verbose "---- Processing database $database"

		#Custom object for Database
		$objectHash = @{
			"Database" = $database.Identity
			"Mounted on" = "Unknown"
			"Preference" = $null
			"Total Copies" = $null
			"Healthy Copies" = $null
			"Unhealthy Copies" = $null
			"Healthy Queues" = $null
			"Unhealthy Queues" = $null
			"Lagged Queues" = $null
			"Healthy Indexes" = $null
			"Unhealthy Indexes" = $null
			}
		$databaseObj = New-Object PSObject -Property $objectHash

		$dbcopystatus = @($database | Get-MailboxDatabaseCopyStatus)
		Write-Verbose "$database has $($dbcopystatus.Count) copies"
		foreach ($dbcopy in $dbcopystatus)
		{
			#Custom object for DB copy
			$objectHash = @{
				"Database Copy" = $dbcopy.Identity
				"Database Name" = $dbcopy.DatabaseName
				"Mailbox Server" = $null
				"Activation Preference" = $null
				"Status" = $null
				"Copy Queue" = $null
				"Replay Queue" = $null
				"Replay Lagged" = $null
				"Truncation Lagged" = $null
				"Content Index" = $null
				}
			$dbcopyObj = New-Object PSObject -Property $objectHash
			
			Write-Verbose "Database Copy: $($dbcopy.Identity)"
			
			$mailboxserver = $dbcopy.MailboxServer
			Write-Verbose "Server: $mailboxserver"

			$pref = ($database | Select-Object -ExpandProperty ActivationPreference | Where-Object {$_.Key -eq $mailboxserver}).Value
			Write-Verbose "Activation Preference: $pref"

			$copystatus = $dbcopy.Status
			Write-Verbose "Status: $copystatus"
			
			[int]$copyqueuelength = $dbcopy.CopyQueueLength
			Write-Verbose "Copy Queue: $copyqueuelength"
			
			[int]$replayqueuelength = $dbcopy.ReplayQueueLength
			Write-Verbose "Replay Queue: $replayqueuelength"
			
			$contentindexstate = $dbcopy.ContentIndexState
			Write-Verbose "Content Index: $contentindexstate"

			#Checking whether this is a replay lagged copy
			$replaylagcopies = @($database | Select -ExpandProperty ReplayLagTimes | Where-Object {$_.Value -gt 0})
			if ($($replaylagcopies.count) -gt 0)
            {
                [bool]$replaylag = $false
                foreach ($replaylagcopy in $replaylagcopies)
			    {
				    if ($replaylagcopy.Key -eq $mailboxserver)
				    {
					    Write-Verbose "$database is replay lagged on $mailboxserver"
					    [bool]$replaylag = $true
				    }
			    }
            }
            else
			{
			   [bool]$replaylag = $false
			}
            Write-Verbose "Replay lag is $replaylag"
					
			#Checking for truncation lagged copies
			$truncationlagcopies = @($database | Select -ExpandProperty TruncationLagTimes | Where-Object {$_.Value -gt 0})
			if ($($truncationlagcopies.count) -gt 0)
            {
                [bool]$truncatelag = $false
                foreach ($truncationlagcopy in $truncationlagcopies)
			    {
				    if ($truncationlagcopy.Key -eq $mailboxserver)
				    {
					    [bool]$truncatelag = $true
				    }
			    }
            }
            else
			{
			   [bool]$truncatelag = $false
			}
            Write-Verbose "Truncation lag is $truncatelag"
			
			$dbcopyObj | Add-Member NoteProperty -Name "Mailbox Server" -Value $mailboxserver -Force
			$dbcopyObj | Add-Member NoteProperty -Name "Activation Preference" -Value $pref -Force
			$dbcopyObj | Add-Member NoteProperty -Name "Status" -Value $copystatus -Force
			$dbcopyObj | Add-Member NoteProperty -Name "Copy Queue" -Value $copyqueuelength -Force
			$dbcopyObj | Add-Member NoteProperty -Name "Replay Queue" -Value $replayqueuelength -Force
			$dbcopyObj | Add-Member NoteProperty -Name "Replay Lagged" -Value $replaylag -Force
			$dbcopyObj | Add-Member NoteProperty -Name "Truncation Lagged" -Value $truncatelag -Force
			$dbcopyObj | Add-Member NoteProperty -Name "Content Index" -Value $contentindexstate -Force
			
			$dbcopyReport += $dbcopyObj
		}
	
		$copies = @($dbcopyReport | Where-Object { ($_."Database Name" -eq $database) })
	
		$mountedOn = ($copies | Where-Object { ($_.Status -eq "Mounted") })."Mailbox Server"
		if ($mountedOn)
		{
			$databaseObj | Add-Member NoteProperty -Name "Mounted on" -Value $mountedOn -Force
		}
	
		$activationPref = ($copies | Where-Object { ($_.Status -eq "Mounted") })."Activation Preference"
		$databaseObj | Add-Member NoteProperty -Name "Preference" -Value $activationPref -Force

		$totalcopies = $copies.count
		$databaseObj | Add-Member NoteProperty -Name "Total Copies" -Value $totalcopies -Force
	
		$healthycopies = @($copies | Where-Object { (($_.Status -eq "Mounted") -or ($_.Status -eq "Healthy")) }).Count
		$databaseObj | Add-Member NoteProperty -Name "Healthy Copies" -Value $healthycopies -Force
		
		$unhealthycopies = @($copies | Where-Object { (($_.Status -ne "Mounted") -and ($_.Status -ne "Healthy")) }).Count
		$databaseObj | Add-Member NoteProperty -Name "Unhealthy Copies" -Value $unhealthycopies -Force

		$healthyqueues  = @($copies | Where-Object { (($_."Copy Queue" -lt $replqueuewarning) -and (($_."Replay Queue" -lt $replqueuewarning)) -and ($_."Replay Lagged" -eq $false)) }).Count
        $databaseObj | Add-Member NoteProperty -Name "Healthy Queues" -Value $healthyqueues -Force

		$unhealthyqueues = @($copies | Where-Object { (($_."Copy Queue" -ge $replqueuewarning) -or (($_."Replay Queue" -ge $replqueuewarning) -and ($_."Replay Lagged" -eq $false))) }).Count
		$databaseObj | Add-Member NoteProperty -Name "Unhealthy Queues" -Value $unhealthyqueues -Force

		$laggedqueues = @($copies | Where-Object { ($_."Replay Lagged" -eq $true) -or ($_."Truncation Lagged" -eq $true) }).Count
		$databaseObj | Add-Member NoteProperty -Name "Lagged Queues" -Value $laggedqueues -Force

		$healthyindexes = @($copies | Where-Object { ($_."Content Index" -eq "Healthy") }).Count
		$databaseObj | Add-Member NoteProperty -Name "Healthy Indexes" -Value $healthyindexes -Force
		
		$unhealthyindexes = @($copies | Where-Object { ($_."Content Index" -ne "Healthy") }).Count
		$databaseObj | Add-Member NoteProperty -Name "Unhealthy Indexes" -Value $unhealthyindexes -Force
		
		$databaseSummary += $databaseObj
	
	}
	
	if ($Detailed)
	{
		#Get Test-Replication Health results for each DAG member
		foreach ($dagmember in $dagmembers)
		{
			$memberObj = New-Object PSObject
			$memberObj | Add-Member NoteProperty -Name "Server" -Value $($dagmember.Name)
		
			Write-Verbose "---- Checking replication health for $($dagmember.Name)"
			$replicationhealth = $dagmember | Invoke-Command {Test-ReplicationHealth}
			foreach ($healthitem in $replicationhealth)
			{
				Write-Verbose "$($healthitem.Check) $($healthitem.Result)"
				$memberObj | Add-Member NoteProperty -Name $($healthitem.Check) -Value $($healthitem.Result)
			}
			$memberReport += $memberObj
		}
	}
	
	#Roll the HTML
	if ($SendEmail -or $HTMLFileName)
	{
	
		####Begin Summary Table HTML
		$databasesummaryHtml = $null
		#Begin Summary table HTML header
		$htmltableheader = "<p>
						<table>
						<tr>
						<th>Database</th>
						<th>Mounted on</th>
						<th>Preference</th>
						<th>Total Copies</th>
						<th>Healthy Copies</th>
						<th>Unhealthy Copies</th>
						<th>Healthy Queues</th>
						<th>Unhealthy Queues</th>
						<th>Lagged Queues</th>
						<th>Healthy Indexes</th>
						<th>Unhealthy Indexes</th>
						</tr>"

		$databasesummaryHtml += $htmltableheader
		#End Summary table HTML header
		
		#Begin Summary table HTML rows
		foreach ($line in $databaseSummary)
		{
			$htmltablerow = "<tr>"
			$htmltablerow = $htmltablerow + "<td><strong>$($line.Database)</strong></td>"
			
			#Warn if mounted server is still unknown
			switch ($($line."Mounted on"))
			{
				"Unknown" { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Mounted on")</td>" }
				default { $htmltablerow = $htmltablerow + "<td>$($line."Mounted on")</td>" }
			}
			
			#Warn if DB is mounted on a server that is not Activation Preference 1
			if ($($line.Preference) -gt 1)
			{
				$htmltablerow = $htmltablerow + "<td class=""warn"">$($line.Preference)</td>"		
			}
			else
			{
				$htmltablerow = $htmltablerow + "<td class=""pass"">$($line.Preference)</td>"
			}
			
			$htmltablerow = $htmltablerow + "<td>$($line."Total Copies")</td>"
			
			#Show as info if health copies is 1 but total copies also 1,
            #Warn if healthy copies is 1, Fail if 0
			switch ($($line."Healthy Copies"))
			{	
				0 {$htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Healthy Copies")</td>"}
				1 {
					if ($($line."Total Copies") -eq $($line."Healthy Copies"))
					{
						$htmltablerow = $htmltablerow + "<td class=""info"">$($line."Healthy Copies")</td>"
					}
					else
					{
						$htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Healthy Copies")</td>"
					}
				  }
				default {$htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Healthy Copies")</td>"}
			}

			#Warn if unhealthy copies is 1, fail if more than 1
			switch ($($line."Unhealthy Copies"))
			{
				0 {	$htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Unhealthy Copies")</td>" }
				1 {	$htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Unhealthy Copies")</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Unhealthy Copies")</td>" }
			}

			#Warn if healthy queues + lagged queues is less than total copies
			#Fail if no healthy queues
			if ($($line."Total Copies") -eq ($($line."Healthy Queues") + $($line."Lagged Queues")))
			{
				$htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Healthy Queues")</td>"
			}
			else
			{
				switch ($($line."Healthy Queues"))
				{
					0 { $htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Healthy Queues")</td>" }
					default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Healthy Queues")</td>" }
				}
			}
			
			#Fail if unhealthy queues = total queues
			#Warn if more than one unhealthy queue
			if ($($line."Total Queues") -eq $($line."Unhealthy Queues"))
			{
				$htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Unhealthy Queues")</td>"
			}
			else
			{
				switch ($($line."Unhealthy Queues"))
				{
					0 { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Unhealthy Queues")</td>" }
					default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Unhealthy Queues")</td>" }
				}
			}
			
			#Info for lagged queues
			switch ($($line."Lagged Queues"))
			{
				0 { $htmltablerow = $htmltablerow + "<td>$($line."Lagged Queues")</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""info"">$($line."Lagged Queues")</td>" }
			}
			
			#Pass if healthy indexes = total copies
			#Warn if healthy indexes less than total copies
			#Fail if healthy indexes = 0
			if ($($line."Total Copies") -eq $($line."Healthy Indexes"))
			{
				$htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Healthy Indexes")</td>"
			}
			else
			{
				switch ($($line."Healthy Indexes"))
				{
					0 { $htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Healthy Indexes")</td>" }
					default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Healthy Indexes")</td>" }
				}
			}
			
			#Fail if unhealthy indexes = total copies
			#Warn if unhealthy indexes 1 or more
			#Pass if unhealthy indexes = 0
			if ($($line."Total Copies") -eq $($line."Unhealthy Indexes"))
			{
				$htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Unhealthy Indexes")</td>"
			}
			else
			{
				switch ($($line."Unhealthy Indexes"))
				{
					0 { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Unhealthy Indexes")</td>" }
					default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Unhealthy Indexes")</td>" }
				}
			}
			
			$htmltablerow = $htmltablerow + "</tr>"
			$databasesummaryHtml += $htmltablerow
		}
		$databasesummaryHtml += "</table>
								</p>"
		#End Summary table HTML rows
		####End Summary Table HTML

		####Begin Detail Table HTML
		$databasedetailsHtml = $null
		#Begin Detail table HTML header
		$htmltableheader = "<p>
						<table>
						<tr>
						<th>Database Copy</th>
						<th>Database Name</th>
						<th>Mailbox Server</th>
						<th>Activation Preference</th>
						<th>Status</th>
						<th>Copy Queue</th>
						<th>Replay Queue</th>
						<th>Replay Lagged</th>
						<th>Truncation Lagged</th>
						<th>Content Index</th>
						</tr>"

		$databasedetailsHtml += $htmltableheader
		#End Detail table HTML header
		
		#Begin Detail table HTML rows
		foreach ($line in $dbcopyReport)
		{
			$htmltablerow = "<tr>"
			$htmltablerow = $htmltablerow + "<td><strong>$($line."Database Copy")</strong></td>"
			$htmltablerow = $htmltablerow + "<td>$($line."Database Name")</td>"
			$htmltablerow = $htmltablerow + "<td>$($line."Mailbox Server")</td>"
			$htmltablerow = $htmltablerow + "<td>$($line."Activation Preference")</td>"
			
			Switch ($($line."Status"))
			{
				"Healthy" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Status")</td>" }
				"Mounted" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Status")</td>" }
				"Failed" { $htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Status")</td>" }
				"FailedAndSuspended" { $htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Status")</td>" }
				"ServiceDown" { $htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Status")</td>" }
				"Dismounted" { $htmltablerow = $htmltablerow + "<td class=""fail"">$($line."Status")</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Status")</td>" }
			}
			
			if ($($line."Copy Queue") -lt $replqueuewarning)
			{
				$htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Copy Queue")</td>"
			}
			else
			{
				$htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Copy Queue")</td>"
			}
			
			if (($($line."Replay Queue") -lt $replqueuewarning) -or ($($line."Replay Lagged") -eq $true))
			{
				$htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Replay Queue")</td>"
			}
			else
			{
				$htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Replay Queue")</td>"
			}
			

			Switch ($($line."Replay Lagged"))
			{
				$true { $htmltablerow = $htmltablerow + "<td class=""info"">$($line."Replay Lagged")</td>" }
				default { $htmltablerow = $htmltablerow + "<td>$($line."Replay Lagged")</td>" }
			}

			Switch ($($line."Truncation Lagged"))
			{
				$true { $htmltablerow = $htmltablerow + "<td class=""info"">$($line."Truncation Lagged")</td>" }
				default { $htmltablerow = $htmltablerow + "<td>$($line."Truncation Lagged")</td>" }
			}
			
			Switch ($($line."Content Index"))
			{
				"Healthy" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line."Content Index")</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line."Content Index")</td>" }
			}
			
			$htmltablerow = $htmltablerow + "</tr>"
			$databasedetailsHtml += $htmltablerow
		}
		$databasedetailsHtml += "</table>
								</p>"
		#End Detail table HTML rows
		####End Detail Table HTML
		
		
		####Begin Member Table HTML
		$memberHtml = $null
		#Begin Member table HTML header
		$htmltableheader = "<p>
							<table>
							<tr>
							<th>Server</th>
							<th>Cluster Service</th>
							<th>Replay Service</th>
							<th>Active Manager</th>
							<th>Tasks RPC Listener</th>
							<th>TCP Listener</th>
							<th>DAG Members Up</th>
							<th>Cluster Network</th>
							<th>Quorum Group</th>
							<th>File Share Quorum</th>
							<th>DB Copy Suspended</th>
							<th>DB Initializing</th>
							<th>DB Disconnected</th>
							<th>DB Log Copy Keeping Up</th>
							<th>DB Log Replay Keeping Up</th>
							</tr>"
		
		$memberHtml += $htmltableheader
		#End Member table HTML header
		
		#Begin Member table HTML rows
		foreach ($line in $memberReport)
		{
			$htmltablerow = "<tr>"
			$htmltablerow = $htmltablerow + "<td><strong>$($line."Server")</strong></td>"

			Switch ($($line.ClusterService))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.ClusterService)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.ClusterService)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.ClusterService)</td>" }
			}
			
			Switch ($($line.ReplayService))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.ReplayService)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.ReplayService)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.ReplayService)</td>" }
			}

			Switch ($($line.ActiveManager))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.ActiveManager)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.ActiveManager)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.ActiveManager)</td>" }
			}
			
			Switch ($($line.TasksRPCListener))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.TasksRPCListener)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.TasksRPCListener)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.TasksRPCListener)</td>" }
			}			
			
			Switch ($($line.TCPListener))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.TCPListener)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.TCPListener)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.TCPListener)</td>" }
			}
			
			Switch ($($line.DAGMembersUp))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.DAGMembersUp)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.DAGMembersUp)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.DAGMembersUp)</td>" }
			}
			
			Switch ($($line.ClusterNetwork))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.ClusterNetwork)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.ClusterNetwork)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.ClusterNetwork)</td>" }
			}
			
			Switch ($($line.QuorumGroup))
			{
				$null { $htmltablerow = $htmltablerow + "<td>$($line.QuorumGroup)</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.QuorumGroup)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.QuorumGroup)</td>" }
			}
			
			Switch ($($line.FileShareQuorum))
			{
				$null { $htmltablerow = $htmltablerow + "<td>n/a</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.FileShareQuorum)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.FileShareQuorum)</td>" }
			}
			
			Switch ($($line.DBCopySuspended))
			{
				$null { $htmltablerow = $htmltablerow + "<td>n/a</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.DBCopySuspended)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.DBCopySuspended)</td>" }
			}
			
			Switch ($($line.DBInitializing))
			{
				$null { $htmltablerow = $htmltablerow + "<td>n/a</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.DBInitializing)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.DBInitializing)</td>" }
			}
			
			Switch ($($line.DBDisconnected))
			{
				$null { $htmltablerow = $htmltablerow + "<td>n/a</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.DBDisconnected)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.DBDisconnected)</td>" }
			}
			
			Switch ($($line.DBLogCopyKeepingUp))
			{
				$null { $htmltablerow = $htmltablerow + "<td>n/a</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.DBLogCopyKeepingUp)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.DBLogCopyKeepingUp)</td>" }
			}
			Switch ($($line.DBLogReplayKeepingUp))
			{
				$null { $htmltablerow = $htmltablerow + "<td>n/a</td>" }
				"Passed" { $htmltablerow = $htmltablerow + "<td class=""pass"">$($line.DBLogReplayKeepingUp)</td>" }
				default { $htmltablerow = $htmltablerow + "<td class=""warn"">$($line.DBLogReplayKeepingUp)</td>" }
			}
			$htmltablerow = $htmltablerow + "</tr>"
			$memberHtml += $htmltablerow
		}
		$memberHtml += "</table>
		</p>"
	}
	
	#Output the report objects to console, and optionally to email and HTML file
	#Forcing table format for console output due to issue with multiple output
	#objects that have different layouts
	if (!($Detailed))
	{

		Write-Host "---- Database Copy Health Summary ----"
		$databaseSummary | ft

		if ($SendEmail -or $HTMLFileName)
		{
			$dagreporthtml = $summaryintro + $databasesummaryHtml
			$reportbody += $dagreporthtml
		}
	}
	else
	{
		Write-Host "---- Database Copy Health Summary ----"
		$databaseSummary | ft
				
		Write-Host "---- Database Copy Health Details ----"
		$dbcopyReport | ft
		
		Write-Host "`r`n---- Server Test-Replication Report ----`r`n"
		$memberReport | ft
		
		if ($SendEmail -or $HTMLFileName)
		{
			$dagreporthtml = $summaryintro + $databasesummaryHtml + $detailintro + $databasedetailsHtml + $memberintro + $memberHtml
			$reportbody += $dagreporthtml
		}
	}
}


#Output/send the HTML report
if ($SendEmail -or $HTMLFileName)
{
	$htmlhead="<html>
			<style>
			BODY{font-family: Arial; font-size: 8pt;}
			H1{font-size: 16px;}
			H2{font-size: 14px;}
			H3{font-size: 12px;}
			TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
			TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
			TD{border: 1px solid black; padding: 5px; }
			td.pass{background: #7FFF00;}
			td.warn{background: #FFE600;}
			td.fail{background: #FF0000; color: #ffffff;}
			td.info{background: #85D4FF;}
			</style>
			<body>
			<h3 align=""center"">Exchange DAG Health Check Report</h3>
			<p>Exchange Server Database Availability Group health check results as of $now</p>"
		
	$htmltail = "</body></html>"	

	$htmlreport = $htmlhead + $reportbody + $htmltail

	if ($SendEmail)
	{
		Send-MailMessage @smtpsettings -Body $htmlreport -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)
	}
	
	if ($HTMLFileName)
	{
		$htmlreport | Out-File $HTMLFileName
	}
}