`timescale 1ns / 1ps
// Self-checking ALU decoder testbench.
module tb_alu_dec;
    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg        funct7, op_5;
    wire [3:0] alu_control;
    integer errors;

    alu_dec uut (.alu_op(alu_op), .funct3(funct3), .funct7(funct7), .op_5(op_5), .alu_control(alu_control));

    task check;
        input [1:0] op;
        input [2:0] f3;
        input f7, o5;
        input [3:0] expected;
        begin
            alu_op = op; funct3 = f3; funct7 = f7; op_5 = o5;
            #5;
            if (alu_control !== expected) begin
                $display("FAIL: alu_op=%b f3=%b f7=%b op5=%b -> %b, expected %b", op, f3, f7, o5, alu_control, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check(2'b00, 3'b111, 1, 1, 4'b0010);  // load/store: always ADD
        check(2'b01, 3'b000, 0, 0, 4'b0110);  // branch: SUB
        // R-type
        check(2'b10, 3'b000, 0, 1, 4'b0010);  // ADD
        check(2'b10, 3'b000, 1, 1, 4'b0110);  // SUB
        check(2'b10, 3'b001, 0, 1, 4'b0100);  // SLL
        check(2'b10, 3'b010, 0, 1, 4'b0111);  // SLT
        check(2'b10, 3'b011, 0, 1, 4'b1001);  // SLTU
        check(2'b10, 3'b100, 0, 1, 4'b0011);  // XOR
        check(2'b10, 3'b101, 0, 1, 4'b0101);  // SRL
        check(2'b10, 3'b101, 1, 1, 4'b1000);  // SRA
        check(2'b10, 3'b110, 0, 1, 4'b0001);  // OR
        check(2'b10, 3'b111, 0, 1, 4'b0000);  // AND
        // I-type: funct7 bit must NOT turn ADDI into SUB
        check(2'b11, 3'b000, 1, 0, 4'b0010);  // ADDI (imm bit 30 set)
        check(2'b11, 3'b101, 1, 0, 4'b1000);  // SRAI
        check(2'b11, 3'b101, 0, 0, 4'b0101);  // SRLI
        check(2'b11, 3'b111, 0, 0, 4'b0000);  // ANDI
        if (errors == 0) $display("ALL TESTS PASSED (tb_alu_dec)");
        else             $display("TESTS FAILED: %0d error(s) (tb_alu_dec)", errors);
        $finish;
    end
endmodule
