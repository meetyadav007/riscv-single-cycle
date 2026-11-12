`timescale 1ns / 1ps
// Instruction memory (read-only, word aligned, combinational read).
//
// Contents come from INIT_FILE (hex, one 32-bit word per line).
//  * Icarus / ModelSim : run the simulator from the folder holding program.hex,
//                        or override INIT_FILE with an absolute path.
//  * Vivado            : add program.hex to the project (Add Sources -> Add or
//                        create simulation/design sources, file type "Memory
//                        File") or override INIT_FILE with an absolute path
//                        using forward slashes.
// Unused words are filled with NOP (ADDI x0,x0,0) so running past the end of
// the program is harmless.
module inst_mem #(
    parameter INIT_FILE = "program.hex",
    parameter AW        = 8                // address bits: 2^AW words
) (
    input  [31:0] address,                 // byte address (PC)
    output [31:0] instruction
);

    localparam WORDS = 1 << AW;

    reg [31:0] memory [0:WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            memory[i] = 32'h00000013;      // NOP
        $readmemh(INIT_FILE, memory);
    end

    assign instruction = memory[address[AW+1:2]];

endmodule
