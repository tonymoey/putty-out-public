# Check if MSOnline module is installed
if (-not (Get-Module -ListAvailable -Name MSOnline)) {
    Write-Host "Installing MSOnline module..." -ForegroundColor Yellow
    Install-Module -Name MSOnline -Scope CurrentUser -Force
}

# Import module
Import-Module MSOnline

# Connect to Microsoft 365
Write-Host "🔗 Connecting to Microsoft 365..." -ForegroundColor Cyan
$cred = Get-Credential
Connect-MsolService -Credential $cred

# Path to CSV file
$csvPath = "C:\putty-out\email-trainees.csv"

# Output log file
$logFile = "C:\putty-out\logs1\MFA_Reset_$(Get-Date -Format 'yyyyMMdd-HHmm').log"

function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
    Add-Content -Path $logFile -Value "[$timestamp] $Message"
}

# Import users from CSV
try {
    $users = Import-Csv -Path $csvPath
    Write-Log "Successfully imported $($users.Count) users." Green
}
catch {
    Write-Log "Failed to import CSV file: $_" Red
    exit
}

# Loop through each user
foreach ($user in $users) {
    $upn = $user.UserPrincipalName

    if ([string]::IsNullOrWhiteSpace($upn) -or $upn -notmatch "@") {
        Write-Log "Invalid UPN format: '$upn'" Yellow
        continue
    }

    Write-Log "🔄 Processing user: $upn" Cyan

    try {
        # Clear existing MFA settings
        $authPrefs = Get-MsolUser -UserPrincipalName $upn | Select-Object -ExpandProperty StrongAuthenticationRequirements

        if ($authPrefs) {
            Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationRequirements @()
        }

        # Clear registered MFA methods
        Clear-MsolUserStrongAuthenticationData -UserPrincipalName $upn

        Write-Log "✅ Cleared MFA for user: $upn" Green
    }
    catch {
        Write-Log "❌ Failed to clear MFA for user: $upn. Error: $_" Red
    }
}

Write-Log "Script completed."