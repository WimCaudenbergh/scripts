#Target MailboxID's
$MailboxNames =  "wca@uf.be" 

#Any Exchange Admin ID with appropriate permissions
$AdminID = "ufadmin@uf365.be"

#Fetch password as secure string
$AdminPwd = Read-Host "Enter Password" -AsSecureString

#Load the Exchange Web Service DLL
$dllpath = "C:\Program Files\Microsoft\Exchange\Web Services\2.0\Microsoft.Exchange.WebServices.dll"
[Reflection.Assembly]::LoadFile($dllpath)

#Create a Exchange Web Service
$Service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1)

#Credentials to impersonate the mail box
$Service.Credentials = New-Object System.Net.NetworkCredential($AdminID , $AdminPwd)
foreach($MailboxName in $MailboxNames)
{
#Impersonate using Exchange WebService Class
$Service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $MailboxName)
$Service.AutodiscoverUrl($MailboxName,{$true})

#Assing EWS URL
$service.Url = 'https://outlook.office365.com/EWS/Exchange.asmx'
Write-Host "Processing Mailbox: $MailboxName" -ForegroundColor Green

#Fetch Root Folder ID
$RootFolderID = New-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Root, $MailboxName)
$RootFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($Service,$RootFolderID)

#Create a Folder View
$FolderView = New-Object Microsoft.Exchange.WebServices.Data.FolderView(1000)
$FolderView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Deep

#Retrieve Folders from view
$response = $RootFolder.FindFolders($FolderView)

#Query Folder which has display name like Lync Contacts
$Folder =  $response | ? {$_.FolderClass -eq 'IPF.Contact.MOC.QuickContacts'}
$Folder | Select DisplayName , TotalCount

#Purge the items

$Folder.Empty([Microsoft.Exchange.WebServices.Data.DeleteMode]::SoftDelete, $false)
$Folder.Load()

#Perform Delete
$Folder.Delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::SoftDelete)
Write-Host "Removed Lync Contacts Folder on: $MailboxName mailbox" -ForegroundColor Green

}