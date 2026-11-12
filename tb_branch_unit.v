`timescale 1ns / 1ps
// Self-checking branch comparator testbench.
module tb_branch_unit;
    reg  [31:0] rs1, rs2;
    reg  [2:0]  funct3;
    wire        taken;
    integer errors;

    branch_unit uut (.rs1(rs1), .rs2(rs2), .funct3(funct3), .taken(taken));

    task check;
        input [2:0] f3;
        input [31:0] a, b;
        input expected;
        begin
            funct3 = f3; rs1 = a; rs2 = b; #5;
            if (taken !== expected) begin
                $display("FAIL: f3=%b rs1=%h rs2=%h taken=%b expected %b", f3, a, b, taken, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check(3'b000, 5, 5, 1);  check(3'b000, 5, 6, 0);                 // BEQ
        check(3'b001, 5, 6, 1);  check(3'b001, 5, 5, 0);                 // BNE
        check(3'b100, -1, 1, 1); check(3'b100, 1, -1, 0);                // BLT  (signed)
        check(3'b100, 5, 5, 0);
        check(3'b101, 1, -1, 1); check(3'b101, -1, 1, 0);                // BGE  (signed)
        check(3'b101, 5, 5, 1);
        check(3'b110, 1, -1, 1); check(3'b110, -1, 1, 0);                // BLTU (unsigned)
        check(3'b111, -1, 1, 1); check(3'b111, 1, -1, 0);                // BGEU (unsigned)
        check(3'b111, 7, 7, 1);
        check(3'b010, 5, 5, 0);                                          // invalid funct3
        if (errors == 0) $display("ALL TESTS PASSED (tb_branch_unit)");
        else             $display("TESTS FAILED: %0d error(s) (tb_branch_unit)", errors);
        $finish;
    end
endmodule
