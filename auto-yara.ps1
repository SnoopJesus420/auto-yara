# Set the path to the YARA executable and the rules folder
$yaraExePath = "C:\your-path\protections-artifacts\yara64.exe"
$rulesFolderPath = "C:\-your-path\protections-artifacts\yara\rules"
$exportPath = "YaraScanResults.csv"

# Set the FilePath and ProcessID (these can be set to $null if you want to skip them)
$FilePath = "C:\path\to\your\file.exe"  # Set this to $null if scanning a ProcessID
$ProcessID = $null  # Set this to a valid PID if you want to scan a process, or $null to scan a file

# Check if YARA executable exists
if (-Not (Test-Path $yaraExePath)) {
    Write-Host "ERROR: YARA executable not found at $yaraExePath" -ForegroundColor Red
    Exit
}

# Check if rules folder exists
if (-Not (Test-Path $rulesFolderPath)) {
    Write-Host "ERROR: YARA rules folder not found at $rulesFolderPath" -ForegroundColor Red
    Exit
}

# Get all rule files in the folder (only .yar files)
$ruleFiles = Get-ChildItem -Path $rulesFolderPath -Filter *.yar

# Log which YARA files were found (useful for debugging)
if ($ruleFiles.Count -eq 0) {
    Write-Host "ERROR: No YARA rule files found in $rulesFolderPath" -ForegroundColor Yellow
    Exit
} else {
    Write-Host "INFO: Found $($ruleFiles.Count) YARA rule files in $rulesFolderPath" -ForegroundColor Green
    $ruleFiles | ForEach-Object { Write-Host "  -> $($_.FullName)" }
}

# Validate FilePath or ProcessID
if (-not $FilePath -and -not $ProcessID) {
    Write-Host "ERROR: Both FilePath and ProcessID are null. Provide at least one to scan." -ForegroundColor Red
    Exit
}

# Create a variable to store all results
$results = @()

# Determine scan target (file or process)
$scanTarget = if ($ProcessID) { "--pid=$ProcessID" } elseif ($FilePath) { $FilePath } else { $null }

# Loop through each rule file and execute YARA
foreach ($ruleFile in $ruleFiles) {
    Write-Host "Processing rule: $($ruleFile.Name)" -ForegroundColor Cyan
    
    # Run YARA for this rule file against the scan target (file or process)
    if ($scanTarget) {
        try {
            $command = & $yaraExePath -s $ruleFile.FullName $scanTarget 2>&1
        } catch {
            Write-Host "ERROR: Failed to run YARA on $($ruleFile.FullName) for target $scanTarget" -ForegroundColor Red
            continue
        }
    } else {
        Write-Host "ERROR: No file path or ProcessID specified for scanning." -ForegroundColor Red
        Exit
    }

    # Check if the YARA command succeeded
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Failed to execute YARA for $($ruleFile.Name) on $scanTarget" -ForegroundColor Yellow
        continue
    }

    # Parse and collect the results
    $commandOutput = $command | Out-String
    if ($commandOutput) {
        $parsedResults = $commandOutput | ForEach-Object {
            if ($_ -match '(\S+)\s+(\S+)\s+(.+)') {
                [PSCustomObject]@{
                    RuleFile = $ruleFile.Name
                    RuleName = $matches[1]
                    MatchedTarget = $scanTarget
                    StringContent = $matches[3].Trim()
                }
            }
        }

        if ($parsedResults) {
            $results += $parsedResults
        }
    } else {
        Write-Host "INFO: No matches found for $($ruleFile.Name) on $scanTarget" -ForegroundColor Yellow
    }
}

# Check if there are any results
if ($results.Count -eq 0) {
    Write-Host "No YARA matches found for the file or process." -ForegroundColor Green
    Exit
}

# Display the results in a formatted table
Write-Host "`n==== YARA Scan Results ====" -ForegroundColor Green
$results | Format-Table -AutoSize

# Export the results to a CSV file for later review
$results | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "`nResults have been saved to $exportPath" -ForegroundColor Green
