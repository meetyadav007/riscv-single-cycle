`timescale 1ns / 1ps
// 32-bit ALU for the single-cycle RV32I core.
//
// alu_control encoding (shared with alu_dec.v):
//   0000 AND    0001 OR     0010 ADD    0011 XOR
//   0100 SLL    0101 SRL    0110 SUB    0111 SLT
//   1000 SRA    1001 SLTU
module alu (
    input      [31:0] a,           // Operand A
    input      [31:0] b,           // Operand B
    input      [3:0]  alu_control, // Function selector
    output reg [31:0] result,      // 32-bit result
    output            zero         // 1 when result == 0
);

    wire signed [31:0] a_s = a;
    wire signed [31:0] b_s = b;
    wire        [4:0]  shamt = b[4:0];

    always @(*) begin
        case (alu_control)
            4'b0000: result = a & b;                         // AND
            4'b0001: result = a | b;                         // OR
            4'b0010: result = a + b;                         // ADD
            4'b0011: result = a ^ b;                         // XOR
            4'b0100: result = a << shamt;                    // SLL
            4'b0101: result = a >> shamt;                    // SRL
            4'b0110: result = a - b;                         // SUB
            4'b0111: result = (a_s < b_s) ? 32'd1 : 32'd0;   // SLT
            4'b1000: result = a_s >>> shamt;                 // SRA
            4'b1001: result = (a < b) ? 32'd1 : 32'd0;       // SLTU
            default: result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
