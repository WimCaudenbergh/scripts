New-Item -ItemType Directory -Force -Path C:\UFled
Copy-Item .\UFled\* C:\UFled
C:\UFled\installService.ps1
net start UFled