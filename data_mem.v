`timescale 1ns / 1ps
// Data memory: synchronous write, combinational read.
// Supports LB/LH/LW/LBU/LHU and SB/SH/SW, selected by funct3
// (instruction[14:12]). Accesses are expected to be naturally aligned;
// the byte address wraps modulo the memory size.
module data_mem #(
    parameter AW = 8                       // 2^AW words (default 1 KiB)
) (
    input             clk,
    input             mem_write,
    input             mem_read,
    input      [2:0]  funct3,
    input      [31:0] addr,                // byte address
    input      [31:0] wdata,
    output reg [31:0] rdata
);

    localparam WORDS = 1 << AW;

    reg [31:0] mem [0:WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            mem[i] = 32'b0;
    end

    wire [AW-1:0] idx = addr[AW+1:2];
    wire [1:0]    off = addr[1:0];

    // ---------------- Write ----------------
    // Read-modify-write of the addressed word (kept simple so every
    // simulator/synthesis tool accepts it).
    reg [31:0] wr_word;
    always @(*) begin
        wr_word = mem[idx];
        case (funct3[1:0])
            2'b00: begin // SB
                case (off)
                    2'd0: wr_word[7:0]   = wdata[7:0];
                    2'd1: wr_word[15:8]  = wdata[7:0];
                    2'd2: wr_word[23:16] = wdata[7:0];
                    default: wr_word[31:24] = wdata[7:0];
                endcase
            end
            2'b01: begin // SH
                if (off[1]) wr_word[31:16] = wdata[15:0];
                else        wr_word[15:0]  = wdata[15:0];
            end
            default: wr_word = wdata; // SW
        endcase
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[idx] <= wr_word;
    end

    // ---------------- Read ----------------
    wire [31:0] word  = mem[idx];
    reg  [7:0]  byte_sel;
    reg  [15:0] half_sel;

    always @(*) begin
        case (off)
            2'd0:    byte_sel = word[7:0];
            2'd1:    byte_sel = word[15:8];
            2'd2:    byte_sel = word[23:16];
            default: byte_sel = word[31:24];
        endcase
        half_sel = off[1] ? word[31:16] : word[15:0];

        if (!mem_read)
            rdata = 32'b0;
        else begin
            case (funct3)
                3'b000:  rdata = {{24{byte_sel[7]}},  byte_sel};  // LB
                3'b001:  rdata = {{16{half_sel[15]}}, half_sel};  // LH
                3'b010:  rdata = word;                            // LW
                3'b100:  rdata = {24'b0, byte_sel};               // LBU
                3'b101:  rdata = {16'b0, half_sel};               // LHU
                default: rdata = word;
            endcase
        end
    end

endmodule
