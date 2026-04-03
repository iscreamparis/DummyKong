# DummyKong — run all three components
# Usage: .\run.ps1 [--clean]

param([switch]$Clean)

$Root = $PSScriptRoot
$ProjectName = Split-Path $Root -Leaf
# Environments live in the KONG install dir (same drive as store → hard links work)
$KongInstall = Split-Path (Get-Command kong).Source -Parent
$EnvDir = "$KongInstall\RULEZ\$ProjectName"

# ── 1. kong setup ───────────────────────────────────────────────────────────
if ($Clean) {
    Write-Host "[kong] Cleaning environments..." -ForegroundColor Cyan
    kong use "$Root\kong.rules" --clean
}

if (-not (Test-Path "$Root\kong.rules")) {
    Write-Host "[kong] Generating kong.rules..." -ForegroundColor Cyan
    Push-Location $Root; kong rules; Pop-Location
}

Write-Host "[kong] Setting up environments in $EnvDir ..." -ForegroundColor Cyan
kong use "$Root\kong.rules"

# ── 2. Activate Python venv ─────────────────────────────────────────────────
$Activate = "$EnvDir\.venv\Scripts\Activate.ps1"
if (Test-Path $Activate) { & $Activate }

# ── 3. Build Rust fractal binary ────────────────────────────────────────────
Write-Host "[fractal] Building Rust binary..." -ForegroundColor Cyan
Push-Location $Root
if (Test-Path "$EnvDir\.rust-toolchain\activate.ps1") {
    & "$EnvDir\.rust-toolchain\activate.ps1"
}
cargo build --release 2>&1 | Write-Host
Pop-Location

# ── 4. Start Flask backend (background) ─────────────────────────────────────
Write-Host "[backend] Starting Flask on http://localhost:5000 ..." -ForegroundColor Cyan
$PythonExe = if (Test-Path "$EnvDir\.venv\Scripts\python.exe") {
    "$EnvDir\.venv\Scripts\python.exe"
} else { "python" }
$BackendJob = Start-Job -ScriptBlock {
    param($root, $python)
    & $python "$root\src\backend\app.py"
} -ArgumentList $Root, $PythonExe

# ── 5. Start Vite frontend (background) ─────────────────────────────────────
Write-Host "[frontend] Starting Vite on http://localhost:5173 ..." -ForegroundColor Cyan
$NodeExe = "node"
$ViteJs = "$EnvDir\node_modules\vite\bin\vite.js"
$FrontendJob = Start-Job -ScriptBlock {
    param($root, $node, $vite)
    Set-Location $root
    & $node $vite
} -ArgumentList $Root, $NodeExe, $ViteJs

# ── 6. Show fractal demo ─────────────────────────────────────────────────────
Write-Host "[fractal] Running ASCII demo..." -ForegroundColor Cyan
& "$Root\target\release\fractal.exe"

Write-Host ""
Write-Host "Backend  → http://localhost:5000" -ForegroundColor Green
Write-Host "Frontend → http://localhost:5173" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop all services." -ForegroundColor Yellow

try {
    Wait-Job $BackendJob, $FrontendJob | Receive-Job
} finally {
    Stop-Job $BackendJob, $FrontendJob -ErrorAction SilentlyContinue
    Remove-Job $BackendJob, $FrontendJob -ErrorAction SilentlyContinue
}
