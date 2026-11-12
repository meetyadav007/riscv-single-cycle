# Runs the demo program with a readable trace. Add -Wave to open GTKWave.
# Easiest way to start it: double-click run_demo.bat (or run_demo_wave.bat)
param([switch]$Wave)
Set-Location $PSScriptRoot
. .\find_iverilog.ps1

try {
    $iv     = Find-Iverilog
    $python = Find-Python
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
$bin = Split-Path $iv

& $python -I tools\rvasm.py tests\demo.s demo.hex | Select-Object -First 1
New-Item -ItemType Directory -Force build | Out-Null
$rtl = 'alu.v','alu_dec.v','control_unit.v','imm_gen.v','inst_mem.v','reg_file.v','data_mem.v','branch_unit.v','riscv_top.v'
& $iv -g2005 -DDUMP_VCD -o build\tb_demo.vvp tb_demo.v @rtl
if ($LASTEXITCODE -ne 0) { Write-Host 'Compile failed' -ForegroundColor Red; exit 1 }
& "$bin\vvp.exe" build\tb_demo.vvp | Where-Object { $_ -notmatch 'WARNING|\$finish' }

if ($Wave) {
    $gtk = Join-Path (Split-Path $bin) 'gtkwave\bin\gtkwave.exe'
    if (-not (Test-Path $gtk)) { Write-Host 'gtkwave.exe not found next to Icarus' -ForegroundColor Red; exit 1 }
    Get-Process gtkwave -ErrorAction SilentlyContinue | Stop-Process -Force
    # relative names + working directory avoid trouble with the space in the folder name
    Start-Process $gtk -WorkingDirectory $PSScriptRoot -ArgumentList 'demo.vcd','--script','demo_wave.tcl'
}
