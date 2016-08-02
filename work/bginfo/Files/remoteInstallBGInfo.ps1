$objShell = New-Object -ComObject ("WScript.Shell")
$objShortCut = $objShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" + "\BGinfo.lnk")
$objShortCut.TargetPath = '"C:\bginfo\Bginfo.exe"' 
$objShortCut.Arguments = "UF.bgi /timer:0 /nolicprompt /silent"
$objShortCut.WorkingDirectory = "C:\bginfo\"
$objShortCut.Save()


Start-Process -FilePath "C:\bginfo\Bginfo.exe" -ArgumentList "UF.bgi /timer:0 /nolicprompt /silent"
