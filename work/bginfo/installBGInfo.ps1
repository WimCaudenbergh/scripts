New-Item -ItemType Directory -Force -Path C:\bginfo\
Copy-Item Eula.txt c:\bginfo\Eula.txt
Copy-Item availableRAM.vbs c:\bginfo\availableRAM.vbs
Copy-Item Bginfo.exe c:\bginfo\Bginfo.exe
Copy-Item UF.bgi c:\bginfo\UF.bgi

$objShell = New-Object -ComObject ("WScript.Shell")
$objShortCut = $objShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" + "\BGinfo.lnk")
$objShortCut.TargetPath = '"C:\bginfo\Bginfo.exe"' 
$objShortCut.Arguments = "UF.bgi /timer:0 /nolicprompt /silent"
$objShortCut.WorkingDirectory = "C:\bginfo\"
$objShortCut.Save()


Start-Process -FilePath "C:\bginfo\Bginfo.exe" -ArgumentList "UF.bgi /timer:0 /nolicprompt /silent"
