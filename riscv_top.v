`timescale 1ns / 1ps
// Single-cycle RV32I processor (integer subset, no CSRs/fences/ecall).
//
//   Arithmetic : ADD SUB AND OR XOR SLL SRL SRA SLT SLTU (+ immediate forms), LUI, AUIPC
//   Memory     : LB LH LW LBU LHU SB SH SW
//   Branch     : BEQ BNE BLT BGE BLTU BGEU
//   Jump       : JAL JALR
//
// Parameters let the same RTL be pointed at a different program file
// (INIT_FILE) from a testbench or from Vivado.
module riscv_top #(
    parameter INIT_FILE = "program.hex",
    parameter IMEM_AW = 8,
    parameter DMEM_AW = 8
) (
    input         clk,
    input         rst,           // synchronous, active high
    output [31:0] alu_result
);

    // ---------------- Wires ----------------
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] instruction;
    wire [31:0] rd1, rd2, imm_ext;
    wire [31:0] alu_a, alu_b;
    wire [31:0] mem_rdata;
    reg  [31:0] wb_data;
    wire        zero_flag, branch_taken;
    wire [3:0]  alu_ctrl_signal;

    // Control signals
    wire       branch, jal, jalr, mem_read, mem_write, alu_src, reg_write;
    wire [1:0] alu_op, wb_sel, a_sel;

    // ---------------- Fetch ----------------
    inst_mem #(.INIT_FILE(INIT_FILE), .AW(IMEM_AW)) imem (
        .address(pc), .instruction(instruction)
    );

    // ---------------- Control ----------------
    control_unit ctrl (
        .opcode(instruction[6:0]),
        .branch(branch), .jal(jal), .jalr(jalr),
        .mem_read(mem_read), .mem_write(mem_write),
        .alu_src(alu_src), .reg_write(reg_write),
        .alu_op(alu_op), .wb_sel(wb_sel), .a_sel(a_sel)
    );

    // ---------------- Register file / immediate ----------------
    reg_file rf (
        .clk(clk), .rst(rst), .we(reg_write),
        .rd_addr(instruction[11:7]),
        .rs1_addr(instruction[19:15]),
        .rs2_addr(instruction[24:20]),
        .w_data(wb_data),
        .r_data1(rd1), .r_data2(rd2)
    );

    imm_gen ig (.inst(instruction), .imm_out(imm_ext));

    // ---------------- Execute ----------------
    assign alu_a = (a_sel == 2'b01) ? pc :
                   (a_sel == 2'b10) ? 32'b0 : rd1;
    assign alu_b = alu_src ? imm_ext : rd2;

    alu_dec decoder (
        .alu_op(alu_op),
        .funct3(instruction[14:12]),
        .funct7(instruction[30]),
        .op_5(instruction[5]),
        .alu_control(alu_ctrl_signal)
    );

    alu main_alu (
        .a(alu_a), .b(alu_b),
        .alu_control(alu_ctrl_signal),
        .result(alu_result), .zero(zero_flag)
    );

    branch_unit bru (
        .rs1(rd1), .rs2(rd2),
        .funct3(instruction[14:12]),
        .taken(branch_taken)
    );

    // ---------------- Memory ----------------
    data_mem #(.AW(DMEM_AW)) dmem (
        .clk(clk),
        .mem_write(mem_write), .mem_read(mem_read),
        .funct3(instruction[14:12]),
        .addr(alu_result),
        .wdata(rd2),
        .rdata(mem_rdata)
    );

    // ---------------- Write back ----------------
    always @(*) begin
        case (wb_sel)
            2'b01:   wb_data = mem_rdata;
            2'b10:   wb_data = pc_plus4;
            default: wb_data = alu_result;
        endcase
    end

    // ---------------- Next PC ----------------
    wire [31:0] branch_target = pc + imm_ext;               // BEQ.., JAL
    wire [31:0] jalr_target   = {alu_result[31:1], 1'b0};   // JALR clears bit 0
    wire        take_rel      = jal | (branch & branch_taken);

    always @(posedge clk) begin
        if (rst)           pc <= 32'b0;
        else if (jalr)     pc <= jalr_target;
        else if (take_rel) pc <= branch_target;
        else               pc <= pc_plus4;
    end

endmodule
