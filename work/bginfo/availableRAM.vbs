'<script language="vbscript">
OPTION EXPLICIT
On Error Resume Next

DIM strComputer, objWMIService, colItems, objItem 
strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_PerfRawData_PerfOS_Memory",,48)


DIM strReturn
For Each objItem in colItems
	strReturn = objItem.AvailableMBytes & " MB"
Next


On Error Resume Next
	wscript.Echo strReturn	'for cmd line
	Echo strReturn	'for BGInfo
on error goto 0