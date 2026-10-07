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

try {
    # Import users
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
        # Clear all MFA methods
        Remove-MgUserAuthenticationMethod -UserId $upn -AuthenticationMethodId "all"

        Write-Log "✅ Cleared MFA methods for user: $upn" Green
    }
    catch {
        Write-Log "❌ Failed to clear MFA for user: $upn. Error: $_" Red
    }
}

Write-Log "Script completed."