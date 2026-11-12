`timescale 1ns / 1ps
// Self-checking ALU testbench.
module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;
    integer errors;

    alu uut (.a(a), .b(b), .alu_control(alu_control), .result(result), .zero(zero));

    task check;
        input [3:0]  ctrl;
        input [31:0] ia, ib, expected;
        input [8*6-1:0] name;
        begin
            a = ia; b = ib; alu_control = ctrl;
            #10;
            if (result !== expected || zero !== (expected == 0)) begin
                $display("FAIL %0s: a=%h b=%h -> %h (zero=%b), expected %h", name, ia, ib, result, zero, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
`ifdef DUMP_VCD
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, tb_alu);
`endif
        errors = 0;
        check(4'b0010, 10, 5, 15, "ADD");
        check(4'b0010, 32'hFFFFFFFF, 1, 0, "ADDwr");     // wrap-around, zero flag
        check(4'b0110, 20, 5, 15, "SUB");
        check(4'b0110, 5, 5, 0, "SUB0");                 // zero flag
        check(4'b0110, 3, 5, 32'hFFFFFFFE, "SUBneg");
        check(4'b0000, 32'hFF00, 32'h0F0F, 32'h0F00, "AND");
        check(4'b0001, 32'hFF00, 32'h0F0F, 32'hFF0F, "OR");
        check(4'b0011, 32'hFF00, 32'h0F0F, 32'hF00F, "XOR");
        check(4'b0100, 1, 31, 32'h80000000, "SLL");
        check(4'b0100, 1, 32, 1, "SLL32");               // shamt uses b[4:0]
        check(4'b0101, 32'h80000000, 31, 1, "SRL");
        check(4'b1000, 32'h80000000, 31, 32'hFFFFFFFF, "SRA");
        check(4'b1000, 32'h40000000, 30, 1, "SRApos");
        check(4'b0111, 32'hFFFFFFFF, 1, 1, "SLT");       // -1 < 1
        check(4'b0111, 1, 32'hFFFFFFFF, 0, "SLT2");
        check(4'b1001, 32'hFFFFFFFF, 1, 0, "SLTU");      // big > 1 unsigned
        check(4'b1001, 1, 32'hFFFFFFFF, 1, "SLTU2");
        check(4'b1111, 32'h1234, 32'h5678, 0, "DFLT");
        if (errors == 0) $display("ALL TESTS PASSED (tb_alu)");
        else             $display("TESTS FAILED: %0d error(s) (tb_alu)", errors);
        $finish;
    end
endmodule
