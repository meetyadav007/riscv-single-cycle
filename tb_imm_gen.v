`timescale 1ns / 1ps
// Self-checking immediate generator testbench (encodings from the RISC-V spec).
module tb_imm_gen;
    reg  [31:0] inst;
    wire [31:0] imm_out;
    integer errors;

    imm_gen uut (.inst(inst), .imm_out(imm_out));

    task check;
        input [31:0] i;
        input [31:0] expected;
        input [8*6-1:0] name;
        begin
            inst = i; #5;
            if (imm_out !== expected) begin
                $display("FAIL %0s: inst=%h imm=%h expected %h", name, i, imm_out, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check(32'h00A00093, 32'd10,        "ADDI+");   // addi x1,x0,10
        check(32'hFF000113, 32'hFFFFFFF0,  "ADDI-");   // addi x2,x0,-16
        check(32'h00812183, 32'd8,         "LW");      // lw x3,8(x2)
        check(32'h00112A23, 32'd20,        "SW+");     // sw x1,20(x2)
        check(32'hFE112E23, 32'hFFFFFFFC,  "SW-");     // sw x1,-4(x2)
        check(32'h00208663, 32'd12,        "BEQ+");    // beq x1,x2,+12
        check(32'hFE208EE3, 32'hFFFFFFFC,  "BEQ-");    // beq x1,x2,-4
        check(32'h123450B7, 32'h12345000,  "LUI");     // lui x1,0x12345
        check(32'hFFFFF0B7, 32'hFFFFF000,  "LUIneg");  // lui x1,0xFFFFF
        check(32'h010000EF, 32'd16,        "JAL+");    // jal x1,+16
        check(32'hFF1FF0EF, 32'hFFFFFFF0,  "JAL-");    // jal x1,-16
        if (errors == 0) $display("ALL TESTS PASSED (tb_imm_gen)");
        else             $display("TESTS FAILED: %0d error(s) (tb_imm_gen)", errors);
        $finish;
    end
endmodule
