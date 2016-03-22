$objShell = New-Object -ComObject ("WScript.Shell")
$objShortCut = $objShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" + "\UFSharepointShortcuts.lnk")
$objShortCut.TargetPath = "C:\Program Files (x86)\Userfull\UF SharePoint Shortcuts\UF.exe"
$objShortCut.Save()
