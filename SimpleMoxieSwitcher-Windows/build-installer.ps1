# Build SimpleMoxieSwitcher Windows Installer
# Requires: .NET 8.0 SDK, Inno Setup

param(
    [string]$Configuration = "Release",
    [string]$Platform = "x64"
)

Write-Host "🚀 Building SimpleMoxieSwitcher for Windows distribution..." -ForegroundColor Green

# Step 1: Build the app
Write-Host "`n📦 Step 1: Building $Configuration version..." -ForegroundColor Cyan
dotnet publish SimpleMoxieSwitcher/SimpleMoxieSwitcher.csproj `
    -c $Configuration `
    -r win-$Platform `
    --self-contained true `
    -p:PublishSingleFile=false `
    -p:PublishReadyToRun=true `
    -p:IncludeNativeLibrariesForSelfExtract=true

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build complete!" -ForegroundColor Green

# Step 2: Create installer with Inno Setup
Write-Host "`n💿 Step 2: Creating installer..." -ForegroundColor Cyan

$innoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if (-not (Test-Path $innoSetupPath)) {
    Write-Host "⚠️  Inno Setup not found!" -ForegroundColor Yellow
    Write-Host "Download from: https://jrsoftware.org/isinfo.php" -ForegroundColor Yellow
    Write-Host "After installing, run this script again." -ForegroundColor Yellow
    exit 1
}

& $innoSetupPath "installer.iss"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Installer creation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Installer created: Output\SimpleMoxieSwitcher-Setup.exe" -ForegroundColor Green

# Step 3: Calculate hash for download verification
Write-Host "`n📊 Step 3: Generating checksum..." -ForegroundColor Cyan
$hash = Get-FileHash -Path "Output\SimpleMoxieSwitcher-Setup.exe" -Algorithm SHA256
Write-Host "SHA256: $($hash.Hash)" -ForegroundColor White

# Save hash to file
$hash.Hash | Out-File -FilePath "Output\SimpleMoxieSwitcher-Setup.exe.sha256" -NoNewline

Write-Host "`n🎉 Done!" -ForegroundColor Green
Write-Host "`nFiles ready for upload:" -ForegroundColor Cyan
Write-Host "  • Output\SimpleMoxieSwitcher-Setup.exe" -ForegroundColor White
Write-Host "  • Output\SimpleMoxieSwitcher-Setup.exe.sha256" -ForegroundColor White

Write-Host "`n⚠️  OPTIONAL: Code Signing" -ForegroundColor Yellow
Write-Host "To sign the installer (recommended):" -ForegroundColor Yellow
Write-Host "  signtool sign /f YourCertificate.pfx /p PASSWORD /t http://timestamp.digicert.com Output\SimpleMoxieSwitcher-Setup.exe" -ForegroundColor Gray

Write-Host "`nUpload to openmoxie.org/downloads/" -ForegroundColor Green
