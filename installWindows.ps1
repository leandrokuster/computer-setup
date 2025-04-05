# Reusable Windows Setup Script
# Save as: install.ps1

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
    "OpenAI.ChatGPT"
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
