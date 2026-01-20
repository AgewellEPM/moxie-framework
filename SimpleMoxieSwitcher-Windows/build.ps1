# SimpleMoxieSwitcher Windows Build Script
param(
    [ValidateSet('Debug','Release')]
    [string]$Configuration = 'Release',
    [ValidateSet('x64','x86','arm64')]
    [string]$Platform = 'x64',
    [switch]$Package,
    [switch]$Clean
)

Write-Host "🚀 SimpleMoxieSwitcher Windows Build" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration | Platform: $Platform" -ForegroundColor Yellow

if ($Clean) {
    Write-Host "🧹 Cleaning..." -ForegroundColor Yellow
    dotnet clean SimpleMoxieSwitcher/SimpleMoxieSwitcher.csproj -c $Configuration
}

Write-Host "📦 Restoring packages..." -ForegroundColor Yellow
dotnet restore SimpleMoxieSwitcher/SimpleMoxieSwitcher.csproj

Write-Host "🔨 Building..." -ForegroundColor Yellow
dotnet build SimpleMoxieSwitcher/SimpleMoxieSwitcher.csproj -c $Configuration -p:Platform=$Platform

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    
    if ($Package) {
        Write-Host "📦 Creating package..." -ForegroundColor Yellow
        dotnet publish SimpleMoxieSwitcher/SimpleMoxieSwitcher.csproj -c $Configuration -p:Platform=$Platform --self-contained
        Write-Host "✅ Package created!" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
