# --- Ensure Admin Privileges ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

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
Write-Host "🕓 Setting date/time format to Swiss (dd.MM.yyyy',' 24h)..." -ForegroundColor Cyan

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
