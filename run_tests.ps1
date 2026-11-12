# Assembles tests\test_program.s and runs every testbench.
# Easiest way to start it: double-click run_tests.bat
Set-Location $PSScriptRoot
. .\find_iverilog.ps1

try {
    $iv     = Find-Iverilog
    $python = Find-Python
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
$vvp = Join-Path (Split-Path $iv) 'vvp.exe'

& $python -I tools\rvasm.py tests\test_program.s program.hex | Select-Object -First 1

$rtl   = 'alu.v','alu_dec.v','control_unit.v','imm_gen.v','inst_mem.v','reg_file.v','data_mem.v','branch_unit.v','riscv_top.v'
$tests = 'tb_alu','tb_alu_dec','tb_control','tb_imm_gen','tb_branch_unit','tb_reg_file','tb_data_mem','tb_inst_mem','tb_top'
$failed = 0
New-Item -ItemType Directory -Force build | Out-Null

foreach ($t in $tests) {
    & $iv -g2005 -o "build\$t.vvp" "$t.v" @rtl
    if ($LASTEXITCODE -ne 0) { Write-Host "COMPILE ERROR in $t" -ForegroundColor Red; $failed++; continue }
    $out = & $vvp "build\$t.vvp"
    $out | Where-Object { $_ -notmatch 'WARNING|\$finish' } | ForEach-Object { Write-Host $_ }
    if (-not ($out -match 'ALL TESTS PASSED')) { $failed++ }
}

if ($failed) { Write-Host "`n$failed testbench(es) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll $($tests.Count) testbenches passed" -ForegroundColor Green
