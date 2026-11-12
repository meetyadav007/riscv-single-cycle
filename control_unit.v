`timescale 1ns / 1ps
// Main control unit (opcode decoder).
//
//   wb_sel : write-back source   00 ALU result, 01 data memory, 10 PC+4
//   a_sel  : ALU operand A       00 rs1,        01 PC,          10 zero
//   alu_op : 00 ADD, 01 SUB (branch), 10 R-type, 11 I-type ALU
module control_unit (
    input      [6:0] opcode,
    output reg       branch,
    output reg       jal,
    output reg       jalr,
    output reg       mem_read,
    output reg       mem_write,
    output reg       alu_src,     // 1 = immediate, 0 = rs2
    output reg       reg_write,
    output reg [1:0] alu_op,
    output reg [1:0] wb_sel,
    output reg [1:0] a_sel
);

    always @(*) begin
        // Defaults (also what an unknown opcode does: behave as a NOP)
        branch = 0; jal = 0; jalr = 0;
        mem_read = 0; mem_write = 0;
        alu_src = 0; reg_write = 0;
        alu_op = 2'b00; wb_sel = 2'b00; a_sel = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type ALU (ADDI, ANDI, SLLI, ...)
                reg_write = 1;
                alu_src   = 1;
                alu_op    = 2'b11;
            end
            7'b0000011: begin // Loads (LB, LH, LW, LBU, LHU)
                reg_write = 1;
                alu_src   = 1;
                mem_read  = 1;
                wb_sel    = 2'b01;
            end
            7'b0100011: begin // Stores (SB, SH, SW)
                alu_src   = 1;
                mem_write = 1;
            end
            7'b1100011: begin // Branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)
                branch    = 1;
                alu_op    = 2'b01;
            end
            7'b1101111: begin // JAL
                jal       = 1;
                reg_write = 1;
                wb_sel    = 2'b10;
            end
            7'b1100111: begin // JALR
                jalr      = 1;
                reg_write = 1;
                alu_src   = 1;
                wb_sel    = 2'b10;
            end
            7'b0110111: begin // LUI  : 0 + imm
                reg_write = 1;
                alu_src   = 1;
                a_sel     = 2'b10;
            end
            7'b0010111: begin // AUIPC: PC + imm
                reg_write = 1;
                alu_src   = 1;
                a_sel     = 2'b01;
            end
            default: ;
        endcase
    end

endmodule
