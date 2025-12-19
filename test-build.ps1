# Test Build Script
Write-Host "🔨 Building Taskify Client..." -ForegroundColor Cyan

Set-Location client
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Client dependencies installation failed!" -ForegroundColor Red
    exit 1
}

npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Client build failed!" -ForegroundColor Red
    exit 1
}

Set-Location ..
Write-Host "✅ Build successful! Check client/dist folder" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Build output is in: client/dist" -ForegroundColor Yellow
Write-Host "🚀 Ready for deployment!" -ForegroundColor Green
