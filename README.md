# auto-yara
A PowerShell script to iterate through yara rules and spits out a CSV!

# How-to
Edit the following variables <br>
```powershell
# Set the path to the YARA executable and the rules folder
$yaraExePath = "C:\Tools\protections-artifacts\yara64.exe"
$rulesFolderPath = "C:\Tools\protections-artifacts\yara\rules"
$exportPath = "YaraScanResults.csv"

# Set the FilePath and ProcessID (these can be set to $null if you want to skip them)
$FilePath = "C:\path\to\your\file.exe"  # Set this to $null if scanning a ProcessID
$ProcessID = $null  # Set this to a valid PID if you want to scan a process, or $null to scan a file
```
