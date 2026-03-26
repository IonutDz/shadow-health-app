# Shadow Health - Build Web Script
$ErrorActionPreference = "Stop"
$projectDir = "C:\Users\shado\Desktop\shadow-health-app"
$flutterBin = "C:\Users\shado\flutter\bin\flutter.bat"
Set-Location $projectDir
& $flutterBin pub get
& $flutterBin build web --release --no-tree-shake-icons --no-wasm-dry-run
Write-Host "Done"
