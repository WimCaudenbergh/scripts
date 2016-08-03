########################################################
#load dependencies
########################################################

#import-module ActiveDirectory


########################################################
#functions
########################################################

function checkPassword{
    if ($Password -ne $Password2) {
        Write-Host "`n ---------Retype the password---------"
        $script:Password = Read-Host ' Password:'
        $script:Password2 = Read-Host ' Retype Password:'
        checkpassword
    }else{
        Write-Host "`n Password set"
    }
}

function generateUsername($first, $last){
    $first = $first.Substring(0,1)
    $last = $last.Substring(0,1)
    $script:username = "$first$last"

    #TODO check if username exists
    # userexists=$null
    # Try { userexists = Get-ADUser -Identity $script:username } Catch {}
    # if (userexists) {
    #     $script:username = Read-Host "`n Username $script:username exists, fill in a new username (without @uf.be)"
    # }

    $title = " "
    $message = " The username $script:username@uf.be will be used. Continue?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        " Use $script:username@uf.be as the username."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        " Choose a new username."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 {" Username set to $script:username@uf.be"}
            1 {$script:username = Read-Host " Fill in a new username (without @uf.be)"}
        }

}

function generateAddresses($first, $last){

    $last = $last -replace '\s',''
    $script:primarymail = $firstname+"."+$lastname+"@Userfull.be"
    $script:proxyaddress = $script:username+"@uf.be"

}

function checkMobile($nr){

    if ($nr -NotMatch '^\+\d{2}\s\d{3}\s\d{2}\s\d{2}\s\d{2}$') {
        $script:Mobile = Read-Host "`n incorrect format (example: +32 123 45 67 89)"
        checkMobile $script:Mobile
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
            0 {$script:userOU = "OU=APP,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            1 {$script:userOU = "OU=HR,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            2 {$script:userOU = "OU=Management,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            3 {$script:userOU = "OU=MSP,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            4 {$script:userOU = "OU=OI,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            5 {$script:userOU = "OU=PLT,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            6 {$script:userOU = "OU=SOL,OU=Employees,OU=Users,OU=Userfull,DC=UF,DC=be"}
            7 {$script:userOU = "OU=Interns,OU=Users,OU=Userfull,DC=UF,DC=be"}
            8 {$script:userOU = "OU=External,OU=Users,OU=Userfull,DC=UF,DC=be"}

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
            0 {$script:devgroup = $True}
            1 {$script:devgroup = $False}
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
            0 {$script:uftechgroup = $True}
            1 {$script:uftechgroup = $False}
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
            0 {$script:fapgroup = $True}
            1 {$script:fapgroup = $False}
        }
}

########################################################
#ask values
########################################################


$FirstName = Read-Host "`n First name"
$LastName = Read-Host "`n Last name"

generateUsername $FirstName $LastName
generateAddresses $FirstName $LastName

askRole

$Password = Read-Host "`n Password"
$Password2 = Read-Host " Retype Password"

checkPassword

$Mobile = Read-Host "`n Mobile number (+32 123 45 67 89)"

checkMobile $Mobile

$defaultTwitter = 'https://twitter.com/Userfull_ICT'
$Twitter = Read-Host "`n Twitter url (leave blank for $($defaultTwitter))"
$Twitter = ($defaultTwitter,$Twitter)[[bool]$Twitter]



$defaultLinkedIn = 'https://www.linkedin.com/company/userfull'
$LinkedIn = Read-Host "`n LinkedIn url (leave blank for $($defaultLinkedIn))"
$LinkedIn = ($defaultLinkedIn,$LinkedIn)[[bool]$LinkedIn]


setDeveloper

setTechsupport

setFAP


########################################################
#output
########################################################


Write-Host "`n `n -----------------------------------"

Write-Host " First name:`t" $FirstName
Write-Host " Last name:`t" $LastName
Write-Host " username:`t username@uf.be"
Write-Host " User OU:`t" $userOU
Write-Host " Password:`t" $Password
Write-Host " Twitter:`t" $Twitter
Write-Host " Mobile nr:`t" $Mobile
Write-Host " LinkedIn:`t" $LinkedIn
Write-Host " Developer:`t" $devgroup
Write-Host " Techsupport:`t" $uftechgroup
Write-Host " FAP:`t`t" $fapgroup
Write-Host "`n emailaddr:`t" $primarymail
Write-Host " ProxyAddr1:`t SMTP:$primarymail"
Write-Host " ProxyAddr2:`t smtp:$proxyaddress"
Write-Host "`n Adding to default groups: `n `t - distr_medewerkers" 

Write-Host "----------------------------------- `n"

$correct = Read-Host "`n An account with the previous attributes will be created. Continue?"
while("y","n" -notcontains $correct)
{
    $correct = Read-Host " Y or N"
}

if ($correct -eq "y") {
    Write-Host 'continue'
}else{
    Write-Host "`n exiting"
    exit
}



########################################################
#TODO: Create the user
########################################################

#correct dial-in settings
#Get-ADUser username| Set-ADUser -replace @{msnpallowdialin=$true}


########################################################
#TODO: Sync with Office365
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