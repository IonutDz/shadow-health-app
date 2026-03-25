# Shadow Health - Build APK Script
# Run this in PowerShell from the project directory:
#   cd C:\Users\shado\Desktop\shadow-health-app
#   .\build_apk.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔨 Shadow Health - Building APK..." -ForegroundColor Cyan
Write-Host ""

$projectDir = "C:\Users\shado\Desktop\shadow-health-app"
Set-Location $projectDir

# Check if android platform exists
if (-Not (Test-Path "$projectDir\android")) {
    Write-Host "📱 Android platform not found. Creating..." -ForegroundColor Yellow
    flutter create --platforms android,ios,web .
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ flutter create failed" -ForegroundColor Red; exit 1 }
    Write-Host "✅ Platform files created" -ForegroundColor Green
}

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "❌ pub get failed" -ForegroundColor Red; exit 1 }

# Build release APK
Write-Host ""
Write-Host "🏗️  Building release APK (this takes 2-5 min first time)..." -ForegroundColor Yellow
flutter build apk --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Show output location
$apkPath = "$projectDir\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $size = (Get-Item $apkPath).Length / 1MB
    Write-Host ""
    Write-Host "✅ APK built successfully!" -ForegroundColor Green
    Write-Host "📱 Location: $apkPath" -ForegroundColor Cyan
    Write-Host "📏 Size: $([Math]::Round($size, 1)) MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps to enable APK download:" -ForegroundColor Yellow
    Write-Host "  1. Upload APK to GitHub Releases:" -ForegroundColor White
    Write-Host "     gh release create v1.0.0 build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Gray
    Write-Host "  2. Update kApkDownloadUrl in:" -ForegroundColor White
    Write-Host "     - lib/core/utils/platform_utils_stub.dart" -ForegroundColor Gray
    Write-Host "     - lib/core/utils/platform_utils_web.dart" -ForegroundColor Gray
    Write-Host "  3. Deploy web: .\build_web.ps1" -ForegroundColor White
} else {
    Write-Host "⚠️  APK not found at expected location: $apkPath" -ForegroundColor Yellow
}
