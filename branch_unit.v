`timescale 1ns / 1ps
// Branch comparator: decides whether a conditional branch is taken.
// funct3: 000 BEQ, 001 BNE, 100 BLT, 101 BGE, 110 BLTU, 111 BGEU
module branch_unit (
    input      [31:0] rs1,
    input      [31:0] rs2,
    input      [2:0]  funct3,
    output reg        taken
);

    wire signed [31:0] rs1_s = rs1;
    wire signed [31:0] rs2_s = rs2;

    always @(*) begin
        case (funct3)
            3'b000:  taken = (rs1 == rs2);      // BEQ
            3'b001:  taken = (rs1 != rs2);      // BNE
            3'b100:  taken = (rs1_s <  rs2_s);  // BLT
            3'b101:  taken = (rs1_s >= rs2_s);  // BGE
            3'b110:  taken = (rs1   <  rs2);    // BLTU
            3'b111:  taken = (rs1   >= rs2);    // BGEU
            default: taken = 1'b0;
        endcase
    end

endmodule
