# --- Ensure Admin Privileges ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Add Key to GitHub via API ---
# Prompt for GitHub token (don't store in script)
$githubToken = Read-Host -AsSecureString "Enter your GitHub Personal Access Token"
$tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken))

$headers = @{
    Authorization = "token $tokenPlain"
    Accept = "application/vnd.github+json"
    "User-Agent" = "PowerShell"
}

$body = @{
    title = "$env:COMPUTERNAME SSH Key"
    key   = $publicKey
} | ConvertTo-Json

$response = Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/keys" -Headers $headers -Body $body

if ($response.id) {
    Write-Host "✅ SSH key added to GitHub as: $($response.title)" -ForegroundColor Green
} else {
    Write-Warning "Failed to upload SSH key to GitHub"
}
