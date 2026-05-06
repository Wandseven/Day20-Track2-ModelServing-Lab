# Launch llama-server (via llama-cpp-python) reading models/active.json.
# Windows PowerShell 7+.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$python_cmd = if ($env:PYTHON) { $env:PYTHON } else { "python" }
$model   = (Get-Content "models/active.json" | ConvertFrom-Json).primary_model
$hw      = Get-Content "hardware.json" | ConvertFrom-Json
$threads = if ($hw.cpu.cores_physical) { $hw.cpu.cores_physical } else { 4 }
$gpu     = if ($env:LAB_N_GPU_LAYERS) { $env:LAB_N_GPU_LAYERS } else { '99' }
$ctx     = if ($env:LAB_N_CTX) { $env:LAB_N_CTX } else { '2048' }

Write-Host "==> Starting llama-server" -ForegroundColor Cyan
Write-Host "    model     : $model"
Write-Host "    threads   : $threads"
Write-Host "    gpu_layers: $gpu"
Write-Host "    ctx       : $ctx"
Write-Host "    listening : http://0.0.0.0:8080"
Write-Host ""

& $python_cmd 02-llama-cpp-server/server_with_metrics.py
