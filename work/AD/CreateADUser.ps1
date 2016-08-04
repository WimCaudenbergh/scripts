########################################################
#load dependencies
########################################################

#import-module ActiveDirectory


########################################################
#functions
########################################################

function checkPassword{
    if ($global:Password -ne $global:Password2) {
        Write-Host "`n ---------Retype the password---------"
        $global:Password = Read-Host ' Password:'
        $global:Password2 = Read-Host ' Retype Password:'
        checkpassword
    }else{

        Write-Host "`n Password set"
    }
}

function checkIfUsernameExists($username){
    $userexists=$null
    Try { 
        $userexists = Get-ADUser -Identity $global:username 
    } Catch {}
    
    if (userexists) {
        $global:username = Read-Host "`n Username $global:username exists, fill in a new username (without @uf.be)"
    }
}

#TODO: generate password if left empty
function generateUsername($first, $last){
    $first = $first.Substring(0,1)
    $last = $last.Substring(0,1)
    $global:username = "$first$last"

    #TODO check if username exists
    #checkIfUsernameExists $global:username

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

function generateAddresses($first, $last){

    $last = $last -replace '\s',''
    $global:primarymail = $firstname+"."+$lastname+"@Userfull.be"
    $global:proxyaddress = $global:username+"@uf.be"

}

function checkMobile($nr){

    if ($nr -NotMatch '^\+\d{2}\s\d{3}\s\d{2}\s\d{2}\s\d{2}$') {
        $global:Mobile = Read-Host "`n incorrect format (example: +32 123 45 67 89)"
        checkMobile $global:Mobile
    }

}

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
            0 {$global:userOU = "OU=APP,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            1 {$global:userOU = "OU=HR,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            2 {$global:userOU = "OU=Management,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            3 {$global:userOU = "OU=MSP,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            4 {$global:userOU = "OU=OI,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            5 {$global:userOU = "OU=PLT,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            6 {$global:userOU = "OU=SOL,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            7 {$global:userOU = "OU=Interns,OU=Users,OU=Userfull,DC=UF,DC=be"}
            8 {$global:userOU = "OU=External,OU=Users,OU=Userfull,DC=UF,DC=be"}

        }

}

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

function step1{
    askValues
    showvalues
    askForAccountCreation
}

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

#TODO: create user
function createUser{

    Write-Host "creating AD user"
    #correct dial-in settings
    #Get-ADUser username| Set-ADUser -replace @{msnpallowdialin=$true}

}
########################################################
#Step1: ask values, show them and create user
########################################################

step1



########################################################
#TODO: Step2: Sync with Office365
########################################################

#Azure AD sync
#syncWithO365

########################################################
#TODO: Step3: Office365 settings
########################################################

    ########################################################
    #TODO: Office365 settings (licenses, groups, ...)
    ########################################################

    ########################################################
    #TODO: Exchange online settings
    ########################################################

    ########################################################
    #TODO: SFB settings
    ########################################################

########################################################
#TODO: Logging
########################################################