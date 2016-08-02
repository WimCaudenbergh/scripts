
#$script:username = ""

function checkPassword{
    if ($Password -ne $Password2) {
        Write-Host "`n ---------Retype the password---------"
        $script:Password = Read-Host ' Password:'
        $script:Password2 = Read-Host ' Retype Password:'
        checkpassword
    }else{
        Write-Host "`n ---------Password set---------"
    }
}

function generateUsername($first, $last){
    $first = $first.Substring(0,1)
    $last = $last.Substring(0,1)
    $script:username = "$first$last"

    #TODO check if username exists
    # $userexists=$null
    # Try { $userexists = Get-ADUser -Identity $script:username } Catch {}
    # if ($userexists) {
    #     $script:username = Read-Host "`n Username $script:username exists, fill in a new username (without @uf.be)"
    # }

    $script:correctun = Read-Host "`n the username $script:username@uf.be will be used. Continue?"
    while("y","n" -notcontains $script:correctun)
    {
        $script:correctun = Read-Host " Y or N"
    }

    if ($correctun -eq "n") {
        $script:username = Read-Host "`n Fill in a new username (without @uf.be)"
    }
}

function generateAddresses($first, $last){

    $last = $last -replace '\s',''
    $script:primarymail = $firstname+"."+$lastname+"@Userfull.be"
    $script:proxyaddress = $script:username+"@uf.be"

}

########################################################
#ask values
########################################################


#TODO ask role: APP, HR, Management, MSP, OI, PLT, SOL, intern, external


$FirstName = Read-Host "`n First name"
$LastName = Read-Host "`n Last name"

generateUsername $FirstName $LastName
generateAddresses $FirstName $LastName

$Password = Read-Host "`n Password"
$Password2 = Read-Host " Retype Password"

checkPassword

$defaultTwitter = 'https://twitter.com/Userfull_ICT'
$Twitter = Read-Host "`n Twitter url (leave blank for $($defaultTwitter))"
$Twitter = ($defaultTwitter,$Twitter)[[bool]$Twitter]



$defaultLinkedIn = 'https://www.linkedin.com/company/userfull'
$LinkedIn = Read-Host "`n LinkedIn url (leave blank for $($defaultLinkedIn))"
$LinkedIn = ($defaultLinkedIn,$LinkedIn)[[bool]$LinkedIn]


$devgroup = Read-Host "`n Developer: y or n"
while("y","n" -notcontains $devgroup)
{
    $devgroup = Read-Host " Y or N"
}

$uftechgroup = Read-Host "`n UFTechsupport: y or n"
while("y","n" -notcontains $uftechgroup)
{
    $uftechgroup = Read-Host " Y or N"
}

$fapgroup = Read-Host "`n FAP: y or n"
while("y","n" -notcontains $fapgroup)
{
    $fapgroup = Read-Host " Y or N"
}



########################################################
#generate variables
########################################################


Write-Host "`n `n -----------------------------------"

Write-Host " First name:`t" $FirstName
Write-Host " Last name:`t" $LastName
Write-Host " username:`t $username@uf.be"
Write-Host " Password:`t" $Password
Write-Host " Twitter:`t" $Twitter
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