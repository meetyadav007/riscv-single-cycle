# Helper used by run_tests.ps1 and run_demo.ps1.
# Returns the full path of a working Icarus Verilog (version 11 or newer),
# or throws with a helpful message.
function Find-Iverilog {
    $candidates = @()
    $onPath = Get-Command iverilog -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }
    $candidates += 'C:\iverilog12\bin\iverilog.exe',
                   'C:\iverilog\bin\iverilog.exe',
                   'C:\Program Files\iverilog\bin\iverilog.exe',
                   'C:\Program Files (x86)\iverilog\bin\iverilog.exe'

    foreach ($c in $candidates) {
        if (-not (Test-Path $c)) { continue }
        $v = (& $c -V 2>$null | Select-Object -First 1)
        if ($v -match 'version (\d+)\.' -and [int]$Matches[1] -ge 11) { return $c }
    }
    throw "No working Icarus Verilog (v11+) found. Install it from https://bleyer.org/icarus/ or edit find_iverilog.ps1."
}

function Find-Python {
    foreach ($name in 'python','py') {
        $p = Get-Command $name -ErrorAction SilentlyContinue
        if ($p) { return $p.Source }
    }
    throw "Python was not found. Install Python 3 and tick 'Add to PATH'."
}
