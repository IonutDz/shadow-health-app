# Shadow Health - Build APK Script
$ErrorActionPreference = "Stop"
$projectDir = "C:\Users\shado\Desktop\shadow-health-app"
$flutterBin = "C:\Users\shado\flutter\bin\flutter.bat"

Set-Location $projectDir

if (-Not (Test-Path "$projectDir\android")) {
    Write-Host "Android platform not found. Creating..." -ForegroundColor Yellow
    & $flutterBin create --platforms android,ios,web .
    if ($LASTEXITCODE -ne 0) { Write-Host "flutter create failed" -ForegroundColor Red; exit 1 }
}

Write-Host "Getting dependencies..." -ForegroundColor Yellow
& $flutterBin pub get
if ($LASTEXITCODE -ne 0) { Write-Host "pub get failed" -ForegroundColor Red; exit 1 }

Write-Host "Building release APK..." -ForegroundColor Yellow
& $flutterBin build apk --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

$apkPath = "$projectDir\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $size = (Get-Item $apkPath).Length / 1MB
    Write-Host "APK built OK - $([Math]::Round($size, 1)) MB - $apkPath" -ForegroundColor Green
} else {
    Write-Host "APK not found at: $apkPath" -ForegroundColor Yellow
}
