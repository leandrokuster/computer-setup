# --- Ensure Admin Privileges ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Variables ---
$sshKeyName = "id_ed25519"
$sshKeyPath = "$env:USERPROFILE\.ssh\$sshKeyName"

# --- Generate SSH Key ---
if (-Not (Test-Path $sshKeyPath)) {
    Write-Host "🔐 Generating new SSH key..." -ForegroundColor Cyan
    ssh-keygen -t ed25519 -C "security@leandrokuster.com" -f $sshKeyPath -N "" 
    } 
else {
    Write-Host "✅ SSH key already exists: $sshKeyPath"
}

# --- Start SSH Agent and Add Key ---
Write-Host "🚀 Starting ssh-agent..." -ForegroundColor Cyan
Start-Service ssh-agent
ssh-add $sshKeyPath

# --- Copy Public Key ---
$publicKey = Get-Content "$sshKeyPath.pub" -Raw
Write-Host "`n📋 Public Key:"
Write-Host $publicKey
