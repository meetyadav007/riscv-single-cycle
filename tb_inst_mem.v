`timescale 1ns / 1ps
// Self-checking instruction memory testbench (uses program.hex).
module tb_inst_mem;
    reg  [31:0] address;
    wire [31:0] instruction;
    integer errors;

    inst_mem #(.INIT_FILE("program.hex")) uut (.address(address), .instruction(instruction));

    task check;
        input [31:0] a, expected;
        begin
            address = a; #5;
            if (instruction !== expected) begin
                $display("FAIL: PC=%0d -> %h, expected %h", a, instruction, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check(32'd0, 32'h00A00093);        // addi x1,x0,10
        check(32'd4, 32'h00300113);        // addi x2,x0,3
        check(32'd8, 32'h002081B3);        // add  x3,x1,x2
        check(32'd12, 32'h40208233);       // sub  x4,x1,x2
        check(32'd1000, 32'h00000013);     // beyond the program: NOP padding
        check(32'd5, 32'h00300113);        // byte offset inside a word -> same word
        if (errors == 0) $display("ALL TESTS PASSED (tb_inst_mem)");
        else             $display("TESTS FAILED: %0d error(s) (tb_inst_mem)", errors);
        $finish;
    end
endmodule
