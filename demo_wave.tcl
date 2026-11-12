# GTKWave setup: only the signals that matter, in a readable order.
set top tb_demo

proc add_fmt {names fmt} {
    gtkwave::addSignalsFromList $names
    gtkwave::highlightSignalsFromList $names
    if {$fmt eq "ascii"} { gtkwave::/Edit/Data_Format/ASCII }
    if {$fmt eq "hex"}   { gtkwave::/Edit/Data_Format/Hex }
    if {$fmt eq "dec"}   { gtkwave::/Edit/Data_Format/Decimal }
    gtkwave::/Edit/UnHighlight_All
}

add_fmt [list $top.clk] bin
add_fmt [list $top.asm] ascii
add_fmt [list $top.pc] hex
add_fmt [list $top.branch_taken] bin
foreach r {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16} {
    add_fmt [list $top.x$r] dec
}
gtkwave::/Time/Zoom/Zoom_Full
