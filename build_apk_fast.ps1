# Fast APK build (arm64 only, no minify). Run from project root.
# First time may take 5-10 min (Gradle download). Later builds ~1-2 min.
# If build hangs or fails on lint, close IDEs/editors and run again.
$ErrorActionPreference = "Continue"
Write-Host "Building APK (arm64 only)..." -ForegroundColor Cyan
flutter build apk --target-platform android-arm64
if ($LASTEXITCODE -eq 0) {
    Write-Host "Done. APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
} else {
    Write-Host "Build failed. Try: flutter clean; then run this script again." -ForegroundColor Yellow
}
