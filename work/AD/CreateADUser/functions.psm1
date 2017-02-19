########################################################
#load dependencies
########################################################

#import-module ActiveDirectory


########################################################
#functions
#
#TODO:
#   set default calendar permissions
#   more checks 
#   manpages
#   reusablity (provide variable instead of using global variable)
#   Misc tasks (unlock user, disable user,...)
#   add user to distr_<customername> groups (PRTG & ckure)
#   different options based on internal, external and intern user
#   create Teamviewer account
#   CRM configuration if possible?
########################################################

#TODO: generate password if left empty
##WORKS##
function checkPassword{
    if ($global:Password -ne $global:Password2) {
        Write-Host "`n ---------Retype the password---------"
        $global:Password = Read-Host ' Password:'
        $global:Password2 = Read-Host ' Retype Password:'
        checkpassword
    }else{
        $global:Password = $global:Password2 | ConvertTo-SecureString -AsPlainText -Force
        Write-Host "`n Password set"
    }    
}

##WORKS##
function checkIfUsernameExists($username){
    #keep asking until not exists
    $userexists=$null
    Try { 
        $userexists = Get-ADUser -Identity $username 
    } Catch {}
    
    if ($userexists) {
        $global:username = Read-Host "`n Username $username exists, fill in a new username (without @uf.be)"
        checkIfUsernameExists($global:username)
    }
}

##WORKS##
function generateUsername($first, $last){
    $first = $first.Substring(0,1)
    $last = $last.Substring(0,1)
    $global:username = "$first$last"

    checkIfUsernameExists $global:username

    $title = " "
    $message = " The username $global:username@uf.be will be used. Continue?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Use $global:username@uf.be as the username."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Choose a new username."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {" Username set to $global:username@uf.be"}
            1 {$global:username = Read-Host " Fill in a new username (without @uf.be)"}
        }
}

#TODO using wrong variables? 
##WORKS##
function generateAddresses($first, $last){

    $last = $last -replace '\s',''
    $global:primarymail = $firstname+"."+$lastname+"@Userfull.be"
    $global:proxyaddress = $global:username+"@uf.be"
}

##WORKS##
function fillInMailAttributes{
    Get-ADUser -Identity $global:username| Set-ADUser -EmailAddress $global:primarymail
    Get-ADUser -Identity $global:username| Set-ADUser -Add @{proxyAddresses = "SMTP:"+$global:primarymail}
    Get-ADUser -Identity $global:username| Set-ADUser -Add @{proxyAddresses = "smtp:"+$global:proxyaddress}
}

##WORKS##
function checkMobile($nr){

    if ($nr -NotMatch '^\+\d{2}\s\d{3}\s\d{2}\s\d{2}\s\d{2}$') {
        $global:Mobile = Read-Host "`n incorrect format (example: +32 123 45 67 89)"
        checkMobile $global:Mobile
    }
}

##WORKS##
function askRole{
    $title = " "
    $message = " What is the user role?"

    $answApp = New-Object System.Management.Automation.Host.ChoiceDescription "&APP", `
        "Applications"

    $answHR = New-Object System.Management.Automation.Host.ChoiceDescription "&HR", `
        "Human Resources"

    $answMgmt = New-Object System.Management.Automation.Host.ChoiceDescription "&MGMT", `
        "Management"

    $answMsp = New-Object System.Management.Automation.Host.ChoiceDescription "M&SP", `
        "Marketing/Sales"

    $answOi = New-Object System.Management.Automation.Host.ChoiceDescription "&OI", `
        "Order Intake"

    $answPlt = New-Object System.Management.Automation.Host.ChoiceDescription "&PLT", `
        "Platform"

    $answSol = New-Object System.Management.Automation.Host.ChoiceDescription "SO&L", `
        "Solutions"

    $answInt = New-Object System.Management.Automation.Host.ChoiceDescription "&INT", `
        "Interns"

    $answExt = New-Object System.Management.Automation.Host.ChoiceDescription "&EXT", `
        "External"


    $options = [System.Management.Automation.Host.ChoiceDescription[]]($answApp, $answHR, $answMgmt, $answMsp, $answOi, $answPlt, $answSol, $answInt, $answExt)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {$global:userOU = "OU=APP,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Applications"}
            1 {$global:userOU = "OU=HR,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Human Resources"}
            2 {$global:userOU = "OU=Management,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Management"}
            3 {$global:userOU = "OU=MSP,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Marketing and Sales"}
            4 {$global:userOU = "OU=OI,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Order Intake and Finance"}
            5 {$global:userOU = "OU=PLT,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Platform"}
            6 {$global:userOU = "OU=SOL,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Solutions"}
            7 {$global:userOU = "OU=Interns,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "Intern"}
            8 {$global:userOU = "OU=External,OU=Users,OU=Userfull,DC=UF,DC=be"; $global:userTitle = "External"}

        }
}

##WORKS##
function setDeveloper {
    $title = " Developer?"
    $message = " Add the user to the developer group??"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Add user to the group."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't add user to the group."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {$global:devgroup = $True}
            1 {$global:devgroup = $False}
        }
}

##WORKS##
function setTechsupport {
    $title = " Techsupport?"
    $message = " Add the user to the UF Techsupport group?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Add user to the group."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't add user to the group."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {$global:uftechgroup = $True}
            1 {$global:uftechgroup = $False}
        }
}

##WORKS##
function setFAP {
    $title = " FAP?"
    $message = " Add the user to the FAP group?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Add user to the group."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't add user to the group."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {$global:fapgroup = $True}
            1 {$global:fapgroup = $False}
        }
}

##WORKS##
function syncWithO365 {
    $title = " ------------------ `n O365 Sync"
    $message = " Sync the on premise Active Directory with Office 365?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Sync now"

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't sync"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {Start-Process "C:\Program Files\Microsoft Azure AD Sync\Bin\DirectorySyncClientCmd.exe" -Wait}
            1 {"Skipping sync with O365"}
        }
    Write-Host "`n ------------------"
}

##WORKS##
function askValues{
    $global:FirstName = Read-Host "`n First name"
    $global:LastName = Read-Host "`n Last name"

    generateUsername $global:FirstName $global:LastName
    generateAddresses $global:FirstName $global:LastName

    askRole

    $global:Password = Read-Host "`n Password"
    $global:Password2 = Read-Host " Retype Password"

    checkPassword

    $global:Mobile = Read-Host "`n Mobile number (+32 123 45 67 89)"

    checkMobile $global:Mobile

    $defaultTwitter = 'https://twitter.com/Userfull_ICT'
    $Twitter = Read-Host "`n Twitter url (leave blank for $($defaultTwitter))"
    $global:Twitter = ($defaultTwitter,$Twitter)[[bool]$Twitter]



    $defaultLinkedIn = 'https://www.linkedin.com/company/userfull'
    $LinkedIn = Read-Host "`n LinkedIn url (leave blank for $($defaultLinkedIn))"
    $global:LinkedIn = ($defaultLinkedIn,$LinkedIn)[[bool]$LinkedIn]


    setDeveloper

    setTechsupport

    setFAP
}

##WORKS##
function showValues{

    Write-Host "`n `n -----------------------------------"

    Write-Host " First name:`t" $global:FirstName
    Write-Host " Last name:`t" $global:LastName
    Write-Host " username:`t" $global:username"@uf.be"
    Write-Host " User OU:`t" $global:userOU
    Write-Host " Password:`t" $global:Password
    Write-Host " Twitter:`t" $global:Twitter
    Write-Host " Mobile nr:`t" $global:Mobile
    Write-Host " LinkedIn:`t" $global:LinkedIn
    Write-Host " Developer:`t" $global:devgroup
    Write-Host " Techsupport:`t" $global:uftechgroup
    Write-Host " FAP:`t`t" $global:fapgroup
    Write-Host "`n emailaddr:`t" $global:primarymail
    Write-Host " ProxyAddr1:`t SMTP:$global:primarymail"
    Write-Host " ProxyAddr2:`t smtp:$global:proxyaddress"
    Write-Host "`n Adding to default groups: `n `t - distr_medewerkers" 

    Write-Host "----------------------------------- `n"
}

##WORKS##
function step1{
    askValues
    showvalues
    askForAccountCreation
    addUserToLocalGroups
}

##WORKS##
function askForAccountCreation{
    $title = " create user"
    $message = " An account with the listed attributes will be created. Continue?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Create user."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Start over"

    $stop = New-Object System.Management.Automation.Host.ChoiceDescription "&Stop", `
        " Stop the script"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $stop)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {createUser}
            1 {step1}
            2 {exit}
        }
}

##WORKS##
function enableDialIn{

    Get-ADUser $global:username| Set-ADUser -replace @{msnpallowdialin=$true} 
}

#TODO: create user
#TODO(values): fix telephonenr, email & UPN
function createUser{

    Write-Host "creating AD user"

    $fullname = $global:FirstName + " " + $global:LastName
    $upn = $global:username+"@uf.be"
    try{
        New-ADUser -Name $fullname -UserPrincipalName $upn -SamAccountName $global:username -GivenName $global:FirstName -Surname $global:LastName -DisplayName $fullname -Path $global:userOU -Description $global:userTitle -Title $global:userTitle -Department $global:userTitle -AccountPassword $global:Password -PasswordNeverExpires $true -Enabled $true -ErrorAction Stop
    }
    catch{
        Write-Output "Could not create user."
    }

    #correct dial-in settings
    enableDialIn
}

##WORKS##
function addUserToLocalGroups{
    # add to defaultgroups (medewerkers)
    Add-ADGroupMember -Identity "distr_medewerkers" -Members $global:username

    # add to groups with flags set
    if ($global:devgroup) {
        Add-ADGroupMember -Identity "sec_development" -Members $global:username
        Add-ADGroupMember -Identity "distr_development" -Members $global:username
    }

    if ($global:uftechgroup) {
        Add-ADGroupMember -Identity "distr_uftechsupport" -Members $global:username
    }

    if ($global:fapgroup) {
        Add-ADGroupMember -Identity "sec_FAP" -Members $global:username
        Add-ADGroupMember -Identity "sec_finance" -Members $global:username
        Add-ADGroupMember -Identity "sec_Facturatie" -Members $global:username
    }
}

##WORKS##
function connectToMsol{

    if (!$global:o365credential) { $global:o365credential = get-credential }
    Connect-MsolService -Credential $global:o365credential 
}

##WORKS##
function connectToExchangeOnline{

    if (!$global:o365credential) { $global:o365credential = get-credential }
    
    $global:EOSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/?proxymethod=rps -Credential $global:o365credential -Authentication Basic -AllowRedirection
    Import-PSSession $global:EOSession
}

##WORKS##
function disconnectFromExchangeOnline{

    Remove-PSSession $global:EOSession
}

##WORKS##
function askForO365Licenses{
    $title = " Office 365 licenses"
    $message = " Does the user need the default licenses? (Office 365 E3, Intune and CRM)"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Assign default licenses."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Assign specific licenses."

    $skip = New-Object System.Management.Automation.Host.ChoiceDescription "&Skip", `
        " skip this step"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $skip)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {assignOffice365licenses $True $True $True}
            1 {askForO365LicensesSpecific}
            2 {"Skipping license assignment"}
        }
}

##WORKS##
function askForO365LicensesSpecific{
    $title = " Office 365 E3"
    $message = " Does the user need Office 365 E3?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Assign license."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't assing license."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {$e3 = $True}
            1 {$e3 = $False}
        }  



    $title = " Intune"
    $message = " Does the user need Intune?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Assign license."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't assing license."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {$intune = $True}
            1 {$intune = $False}
        }   

    $title = " CRM"
    $message = " Does the user need CRM?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Assign license."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't assing license."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {$CRM = $True}
            1 {$CRM = $False}
        } 

    assignOffice365licenses $e3 $intune $CRM
}

##WORKS##
function assignMsolLocation{

    $upn = $global:username+"@uf.be"    
    Set-MsolUser -UserPrincipalName $upn -UsageLocation BE
}

##WORKS##
function assignOffice365licenses($e3, $intune, $CRM){
    <#
    available licenses
    AccountSkuId                    ActiveUnits WarningUnits ConsumedUnits
    ------------                    ----------- ------------ -------------
    UF365:POWERAPPS_INDIVIDUAL_USER 10000       0            2
    UF365:AAD_BASIC                 100         0            0
    UF365:ENTERPRISEPACK            100         0            83             ----> Office365 E3
    UF365:CRMSTANDARD               1           0            0
    UF365:POWER_BI_STANDARD         1000003     0            3
    UF365:INTUNE_A                  100         0            39             ----> Intune
    UF365:CRMIUR                    60          0            50             ----> CRM
    #>       

    #TODO: finish function

    $upn = $global:username+"@uf.be"

    #set location
    assignMsolLocation

    if ($e3 -eq $True) {
        Write-Host "Setting E3 license"
        Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses "UF365:ENTERPRISEPACK" 
    }

    if ($intune -eq $True) {
        Write-Host "Setting Intune license"
        Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses "UF365:INTUNE_A" 
    }

    if ($CRM -eq $True) {
        Write-Host "setting CRM license"
        Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses "UF365:CRMIUR" 
    }
}

##WORKS##
function askForO365GroupMembership{
    $title = " Office 365 groups"
    $message = " Add the user to the default groups?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Add user to the default groups."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Don't add the user to any groups."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {addUserToMsolGroups}
            1 {"Skipping group assignment"}
        }
}

##WORKS##
function addUserToMsolGroups{
    $upn = $global:username+"@uf.be"
    $memberid = Get-MsolUser -UserPrincipalName $upn
    $groupid = Get-MsolGroup | Where-Object {$_.DisplayName -eq "Userfull for SPS"}
    Add-MsolGroupMember -GroupObjectId $groupid.ObjectId -GroupMemberObjectId $memberid.ObjectId -GroupMemberType Use
}

##WORKS##
function enableOnlineArchive{
    $upn = $global:username+"@uf.be"

    $title = " Exchange Online archive"
    $message = " Enabel the archive for the user mailbox?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Enables archiving."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " No change made."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {Enable-Mailbox -Identity $upn -Archive}
            1 {"Skipping Online Archive"}
        }
}

##WORKS##
function browseFile($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "Image Files (*.jpg)|*.jpg"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

##WORKS##
function uploadProfilePhoto{

    #source:  https://blogs.technet.microsoft.com/cloudtrek365/2014/12/31/uploading-high-resolution-photos-using-powershell-for-office-365/
    #preferred resolution:  648 pixels by 648 pixels

    $upn = $global:username+"@uf.be"
    $userphoto = browseFile
    Set-UserPhoto -Identity $upn -PictureData ([System.IO.File]::ReadAllBytes($userphoto)) -Confirm:$false
}

##WORKS##
function askForProfilePhoto{
    $title = " Office 365 Profile photo"
    $message = " Do you wish to select a photo to upload as a profile photo for the new user?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Select a photo."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Skip this step."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {uploadProfilePhoto}
            1 {"Skipping photo upload"}
        }
}