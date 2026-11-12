`timescale 1ns / 1ps
// 32 x 32-bit register file: two asynchronous read ports, one synchronous
// write port, synchronous reset. x0 is hard-wired to zero.
module reg_file (
    input         clk,
    input         rst,        // synchronous, active high
    input         we,         // write enable
    input  [4:0]  rd_addr,    // write address
    input  [4:0]  rs1_addr,   // read address 1
    input  [4:0]  rs2_addr,   // read address 2
    input  [31:0] w_data,     // write data
    output [31:0] r_data1,
    output [31:0] r_data2
);

    reg [31:0] registers [0:31];
    integer i;

    // Start at zero in simulation as well (before the first reset edge)
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    assign r_data1 = (rs1_addr == 5'd0) ? 32'b0 : registers[rs1_addr];
    assign r_data2 = (rs2_addr == 5'd0) ? 32'b0 : registers[rs2_addr];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else if (we && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= w_data;
        end
    end

endmodule
