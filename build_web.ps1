# Shadow Health - Build Web Script
$ErrorActionPreference = "Stop"
$projectDir = "C:\Users\shado\Desktop\shadow-health-app"
$flutterBin = "C:\Users\shado\flutter\bin\flutter.bat"

Set-Location $projectDir

Write-Host "Adding web platform..." -ForegroundColor Yellow
& $flutterBin create . --platforms web
if ($LASTEXITCODE -ne 0) { Write-Host "flutter create failed" -ForegroundColor Red; exit 1 }

Write-Host "Getting dependencies..." -ForegroundColor Yellow
& $flutterBin pub get

Write-Host "Building web..." -ForegroundColor Yellow
& $flutterBin build web --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Web build OK - build/web/" -ForegroundColor Green
