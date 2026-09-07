<#
.SYNOPSIS
    TASK-060 File Audit Script
.DESCRIPTION
    Validates the existence and structure of all files created for TASK-060:
    Installer Architecture Design & Scope Definition
.NOTES
    Author: Team 295905
    Task: TASK-060
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$BasePath = "C:\dbug\workspace\bughub-installer"
)

$SuccessColor = "Green"
$WarningColor = "Yellow"
$ErrorColor = "Red"
$InfoColor = "Cyan"

Write-Host "============================================================" -ForegroundColor $InfoColor
Write-Host "  TASK-060: File Existence Audit" -ForegroundColor $InfoColor
Write-Host "  Base Path: $BasePath" -ForegroundColor $InfoColor
Write-Host "  Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $InfoColor
Write-Host "============================================================" -ForegroundColor $InfoColor
Write-Host ""

$ExpectedFiles = @(
    @{ Path = "config\install_manifest_schema.json"; Description = "Install Manifest JSON Schema Template"; Type = "JSON" },
    @{ Path = "docs\INSTALLER_ARCHITECTURE.md"; Description = "Installer Architecture Documentation"; Type = "Markdown" },
    @{ Path = "src\installer\Install-Manifest.psm1"; Description = "PowerShell Module - Manifest Management"; Type = "PowerShell Module" },
    @{ Path = "install.ps1"; Description = "Main Installer Script"; Type = "PowerShell Script" }
)

$TotalFiles = $ExpectedFiles.Count
$FilesFound = 0
$FilesMissing = 0
$ValidationResults = @()

foreach ($file in $ExpectedFiles) {
    $fullPath = Join-Path $BasePath $file.Path
    $exists = Test-Path $fullPath
    
    $result = [PSCustomObject]@{
        File = $file.Path
        Description = $file.Description
        Type = $file.Type
        Exists = $exists
        Size = $null
        LastModified = $null
    }
    
    if ($exists) {
        $FilesFound++
        $item = Get-Item $fullPath
        $result.Size = "{0:N0} bytes" -f $item.Length
        $result.LastModified = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        
        Write-Host "[✓] $($file.Path)" -ForegroundColor $SuccessColor
        Write-Host "    Description: $($file.Description)" -ForegroundColor Gray
        Write-Host "    Size: $($result.Size) | Modified: $($result.LastModified)" -ForegroundColor Gray
        
        if ($file.Type -eq "JSON") {
            try { Get-Content $fullPath -Raw | ConvertFrom-Json | Out-Null; Write-Host "    ✓ JSON syntax valid" -ForegroundColor $SuccessColor }
            catch { Write-Host "    ✗ JSON syntax error: $_" -ForegroundColor $ErrorColor }
        }
        if ($file.Type -match "PowerShell") {
            try { $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $fullPath -Raw), [ref]$null); Write-Host "    ✓ PowerShell syntax valid" -ForegroundColor $SuccessColor }
            catch { Write-Host "    ✗ PowerShell syntax error: $_" -ForegroundColor $ErrorColor }
        }
    } else {
        $FilesMissing++
        Write-Host "[✗] $($file.Path)" -ForegroundColor $ErrorColor
        Write-Host "    Status: FILE NOT FOUND" -ForegroundColor $WarningColor
    }
    $ValidationResults += $result
    Write-Host ""
}

Write-Host "============================================================" -ForegroundColor $InfoColor
Write-Host "  AUDIT SUMMARY" -ForegroundColor $InfoColor
Write-Host "============================================================" -ForegroundColor $InfoColor
Write-Host "Total Files Expected: $TotalFiles" -ForegroundColor $InfoColor
Write-Host "Files Found:          $FilesFound" -ForegroundColor $SuccessColor
Write-Host "Files Missing:        $FilesMissing" -ForegroundColor $(if ($FilesMissing -gt 0) { $ErrorColor } else { $SuccessColor })
Write-Host ""

if ($FilesMissing -eq 0) {
    Write-Host "✓ TASK-060 FILE AUDIT COMPLETE - ALL FILES PRESENT" -ForegroundColor $SuccessColor
} else {
    Write-Host "✗ TASK-060 FILE AUDIT INCOMPLETE - MISSING FILES DETECTED" -ForegroundColor $ErrorColor
}

# Export results to JSON
$ExportPath = Join-Path $BasePath "docs\task060_audit_results.json"
$AuditReport = [PSCustomObject]@{
    AuditTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    BasePath = $BasePath
    TotalFiles = $TotalFiles
    FilesFound = $FilesFound
    FilesMissing = $FilesMissing
    AuditPassed = ($FilesMissing -eq 0)
    Files = $ValidationResults
}
$AuditReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ExportPath -Encoding UTF8
Write-Host "Audit results exported to: $ExportPath" -ForegroundColor $InfoColor
