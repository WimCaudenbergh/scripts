function askRole{

    $title = "User role"
    $message = "What is the user role?"

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

    $result

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

askrole


write-host "--------------"
$result
$userOU