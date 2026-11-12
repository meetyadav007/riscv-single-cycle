`timescale 1ns / 1ps
// Self-checking control unit testbench.
module tb_control;
    reg  [6:0] opcode;
    wire branch, jal, jalr, mem_read, mem_write, alu_src, reg_write;
    wire [1:0] alu_op, wb_sel, a_sel;
    integer errors;

    control_unit uut (
        .opcode(opcode), .branch(branch), .jal(jal), .jalr(jalr),
        .mem_read(mem_read), .mem_write(mem_write), .alu_src(alu_src),
        .reg_write(reg_write), .alu_op(alu_op), .wb_sel(wb_sel), .a_sel(a_sel)
    );

    // expected = {branch,jal,jalr,mem_read,mem_write,alu_src,reg_write,alu_op[1:0],wb_sel[1:0],a_sel[1:0]}
    task check;
        input [6:0] op;
        input [11:0] expected;
        input [8*6-1:0] name;
        reg [11:0] got;
        begin
            opcode = op;
            #5;
            got = {branch, jal, jalr, mem_read, mem_write, alu_src, reg_write, alu_op, wb_sel, a_sel};
            if (got !== expected) begin
                $display("FAIL %0s: got %b, expected %b", name, got, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        //     opcode      br jal jalr mr mw src rw  op  wb  a
        check(7'b0110011, {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,2'b10,2'b00,2'b00}, "R");
        check(7'b0010011, {1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,2'b11,2'b00,2'b00}, "I");
        check(7'b0000011, {1'b0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,2'b00,2'b01,2'b00}, "LOAD");
        check(7'b0100011, {1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,2'b00,2'b00,2'b00}, "STORE");
        check(7'b1100011, {1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,2'b01,2'b00,2'b00}, "BRANCH");
        check(7'b1101111, {1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,2'b00,2'b10,2'b00}, "JAL");
        check(7'b1100111, {1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b1,2'b00,2'b10,2'b00}, "JALR");
        check(7'b0110111, {1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,2'b00,2'b00,2'b10}, "LUI");
        check(7'b0010111, {1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,2'b00,2'b00,2'b01}, "AUIPC");
        check(7'b1111111, 12'b0, "UNKNWN");
        if (errors == 0) $display("ALL TESTS PASSED (tb_control)");
        else             $display("TESTS FAILED: %0d error(s) (tb_control)", errors);
        $finish;
    end
endmodule
