`timescale 1ns / 1ps
// Immediate generator: I, S, B, U and J formats, selected by opcode.
module imm_gen (
    input      [31:0] inst,
    output reg [31:0] imm_out
);

    always @(*) begin
        case (inst[6:0])
            7'b0100011:                                   // S-type (stores)
                imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            7'b1100011:                                   // B-type (branches)
                imm_out = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            7'b0110111, 7'b0010111:                       // U-type (LUI, AUIPC)
                imm_out = {inst[31:12], 12'b0};
            7'b1101111:                                   // J-type (JAL)
                imm_out = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            default:                                      // I-type (ALU-imm, loads, JALR)
                imm_out = {{20{inst[31]}}, inst[31:20]};
        endcase
    end

endmodule
