# Reusable Windows Setup Script
# Save as: installWindows.ps1

# --- Ensure Admin Privileges ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Define App List ---
$apps = @(
    "Zen-Team.Zen-Browser",
    "Zen-Team.Zen-Browser.Twilight",          
    "Whatsapp.Whatsapp",
    "Telegram.TelegramDesktop",
    "Discord.Discord",
    "Notion.Notion",
    "Spotify.Spotify",
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Logitech.GHUB",
    "Corsair.iCUE",
    "Valve.Steam",
    "NordVPN.NordVPN",
    "AgileBits.1Password",
    "OpenAI.ChatGPT",
    "GitHub.GitHubDesktop",
    "GeekCorner.threema",
    "OpenWhisperSystems.Signal",
    "Mozilla.Thunderbird",
    "Google.GoogleDrive"
)

# --- Install Apps via Winget ---
foreach ($app in $apps) {
    Write-Host "`n➡ Installing: $app" -ForegroundColor Cyan
    $result = winget install --id "$app" --silent --accept-package-agreements --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "⚠ Could not install: $app. It may not exist in the winget repository."
    }
}

# --- Reminder for Manual Installs ---
# Write-Host "`n⚠ Manual Installation Needed:" -ForegroundColor Yellow



# --- Keyboard Layout: US International Only ---
Write-Host "`n🧩 Setting keyboard layout to US International..." -ForegroundColor Cyan

Set-WinUserLanguageList -LanguageList en-US -Force
Set-WinUILanguageOverride -Language en-US
Set-WinSystemLocale -SystemLocale en-US
Set-WinHomeLocation -GeoId 223    # Switzerland

# Registry tweak to enforce US International keyboard only
$intlKey = 'HKCU:\Keyboard Layout\Preload'
Remove-Item -Path $intlKey -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $intlKey -Force | Out-Null
New-ItemProperty -Path $intlKey -Name "1" -Value "00020409" -PropertyType String -Force

# --- Date/Time Format: Swiss Style, 24h ---
Write-Host "🕓 Setting date/time format to Swiss (dd.MM.yyyy, 24h)..." -ForegroundColor Cyan

Set-Culture de-CH
Set-WinHomeLocation -GeoId 223  # Switzerland
Set-TimeZone -Id "W. Europe Standard Time"

# Customize short/long date and time formats
$intl = 'HKCU:\Control Panel\International'
Set-ItemProperty -Path $intl -Name "sShortDate" -Value "dd.MM.yyyy"
Set-ItemProperty -Path $intl -Name "sLongDate"  -Value "dddd, d. MMMM yyyy"
Set-ItemProperty -Path $intl -Name "sTimeFormat" -Value "HH:mm:ss"
Set-ItemProperty -Path $intl -Name "iTime" -Value "1"
Set-ItemProperty -Path $intl -Name "iTimePrefix" -Value "0"

# --- Force English as Only Display Language ---
Write-Host "🌐 Setting English as the only display language..." -ForegroundColor Cyan

$LangList = New-WinUserLanguageList en-US
$LangList[0].Handwriting = $false
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add("0409:00020409") # US International

Set-WinUserLanguageList $LangList -Force

# --- Variables ---
$sshKeyName = "id_ed25519"
$sshKeyPath = "$env:USERPROFILE\.ssh\$sshKeyName"

# --- Generate SSH Key ---
if (-Not (Test-Path $sshKeyPath)) {
    Write-Host "🔐 Generating new SSH key..." -ForegroundColor Cyan
    ssh-keygen -t ed25519 -C "security@leandrokuster.com" -f $sshKeyPath -N ""
} else {
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
    Write-Warning "❌ Failed to upload SSH key to GitHub"
}
