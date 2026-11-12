# Vivado batch simulation + synthesis check.
#   vivado -mode batch -source vivado/run_sim.tcl            (from the project root)
# Optional: set TB to another testbench, e.g.  -tclargs tb_alu
set root [file normalize [file join [file dirname [info script]] ..]]
set tb   [expr {[llength $argv] > 0 ? [lindex $argv 0] : "tb_top"}]

create_project -in_memory -part xc7a35tcpg236-1
set rtl {alu.v alu_dec.v control_unit.v imm_gen.v inst_mem.v reg_file.v
         data_mem.v branch_unit.v riscv_top.v}
foreach f $rtl { add_files [file join $root $f] }
foreach f [glob -directory $root tb_*.v] { add_files -fileset sim_1 $f }
add_files -fileset sim_1 [file join $root program.hex]   ;# found by $readmemh in the xsim run dir
set_property top riscv_top [current_fileset]
set_property top $tb [get_filesets sim_1]
update_compile_order -fileset sources_1

# --- behavioural simulation ---
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

# --- synthesis sanity check (instruction ROM is initialised from program.hex) ---
add_files [file join $root program.hex]
set_property file_type {Memory Initialization Files} [get_files program.hex]
synth_design -top riscv_top -part xc7a35tcpg236-1 -mode out_of_context
report_utilization
