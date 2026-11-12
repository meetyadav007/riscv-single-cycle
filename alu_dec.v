`timescale 1ns / 1ps
// ALU decoder: turns the control unit's 2-bit alu_op plus funct3/funct7
// into the 4-bit ALU control code.
//
//   alu_op 00 : force ADD   (loads, stores, LUI, AUIPC, JALR address)
//   alu_op 01 : force SUB   (branches)
//   alu_op 10 : R-type      (decode funct3/funct7)
//   alu_op 11 : I-type ALU  (decode funct3, funct7 only matters for shifts)
module alu_dec (
    input      [1:0] alu_op,
    input      [2:0] funct3,   // instruction[14:12]
    input            funct7,   // instruction[30]
    input            op_5,     // opcode bit 5 (1 = R-type, 0 = I-type)
    output reg [3:0] alu_control
);

    always @(*) begin
        case (alu_op)
            2'b00:   alu_control = 4'b0010;  // ADD
            2'b01:   alu_control = 4'b0110;  // SUB
            default: begin                   // 10 / 11: decode funct3
                case (funct3)
                    3'b000: alu_control = (op_5 && funct7) ? 4'b0110  // SUB (R-type only)
                                                           : 4'b0010; // ADD / ADDI
                    3'b001: alu_control = 4'b0100;                    // SLL / SLLI
                    3'b010: alu_control = 4'b0111;                    // SLT / SLTI
                    3'b011: alu_control = 4'b1001;                    // SLTU / SLTIU
                    3'b100: alu_control = 4'b0011;                    // XOR / XORI
                    3'b101: alu_control = funct7 ? 4'b1000            // SRA / SRAI
                                                 : 4'b0101;           // SRL / SRLI
                    3'b110: alu_control = 4'b0001;                    // OR / ORI
                    3'b111: alu_control = 4'b0000;                    // AND / ANDI
                    default: alu_control = 4'b0010;
                endcase
            end
        endcase
    end

endmodule
