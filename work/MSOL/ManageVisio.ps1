
#check if Msol connection still available, otherwise start a new one
try
{
    Get-MsolDomain -ErrorAction Stop > $null
}
catch 
{
    if ($cred -eq $null) {$cred = Get-Credential $O365Adminuser}
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}


#load up global info

$sku = "UF365:VISIOCLIENT"

$Visiolicenses = (Get-MsolAccountSku | where {$_.AccountSkuId -eq $sku})

$active = $Visiolicenses.ActiveUnits
$consumed = $Visiolicenses.ConsumedUnits
$available = $active - $consumed


#functions
function showMenu {
    $title = "Userfull Office365 Visio licensing"
    $message = "`n"

    $show = New-Object System.Management.Automation.Host.ChoiceDescription "&Show licenses", `
    "Show current licensing status."

    $user = New-Object System.Management.Automation.Host.ChoiceDescription "Licensed &Users", `
    "Show licensed users."

    $remove = New-Object System.Management.Automation.Host.ChoiceDescription "&Remove license from user", `
    "Remove license from a user."

    $add = New-Object System.Management.Automation.Host.ChoiceDescription "&Add license to a user", `
    "Add license to a user."

    $list = New-Object System.Management.Automation.Host.ChoiceDescription "&List user UPN", `
    "Add license to a user."

    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", `
    "Exit."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($show, $user, $remove, $add, $list, $exit)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
    {
        0 {showInfo}
        1 {showVisioUsers}
        2 {removeLicense}
        3 {addLicense}
        4 {listUsers}
        5 {exit}
    }

}

function backToMenu {
    Read-Host "`nPress ENTER to go back to the menu."
    Clear-Host
    showMenu
}

function showInfo {
    write-host "`nVisio licenses for UF365" 
    write-host "------------------------" 
    write-host Active `t`t $active
    write-host Consumed `t $consumed
    write-host Available `t $available -foregroundcolor "green"

    backToMenu
}

function showVisioUsers {
    write-host "`nUsers that have a Visio license" 
    write-host "---------------------------------" 

    $ALLUsers = Get-MsolUser -All | ?{ $_.isLicensed -eq "TRUE" }
    $ALLUsers | ?{ ($_.Licenses | ?{ $_.AccountSkuId -eq $sku}).Length -gt 0} | ft DisplayName, UserPrincipalName

    backToMenu
}

function removeLicense {
    $user = Read-Host "`nType in the UPN (initials@uf.be) of the user where the license will be removed"
    Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses $sku

    showVisioUsers
}

function addLicense {
    $user = Read-Host "`nType in the UPN (initials@uf.be) of the user that will get the license"
    Set-MsolUserLicense -UserPrincipalName $user -AddLicenses $sku

    showVisioUsers
}

function listUsers {
    $ALLUsers = Get-MsolUser -All | ?{ $_.isLicensed -eq "TRUE" }
    $ALLUsers = $ALLUsers | Sort-Object DisplayName, UserPrincipalName
    $ALLUsers | ft DisplayName, UserPrincipalName

    backToMenu
}



#start of flow
showMenu
