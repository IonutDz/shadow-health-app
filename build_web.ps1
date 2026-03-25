# Shadow Health - Build Web Script
# Run from project dir:  .\build_web.ps1

$ErrorActionPreference = "Stop"
Write-Host "🌐 Shadow Health - Building Web..." -ForegroundColor Cyan

Set-Location "C:\Users\shado\Desktop\shadow-health-app"

flutter pub get
flutter build web --release --no-tree-shake-icons --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Web build ready at: build\web\" -ForegroundColor Green
    Write-Host "   Deploy to Firebase Hosting, Netlify, Vercel, etc." -ForegroundColor Cyan
} else {
    Write-Host "❌ Web build failed!" -ForegroundColor Red
}
