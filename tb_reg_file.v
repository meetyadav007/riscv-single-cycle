`timescale 1ns / 1ps
// Self-checking register file testbench.
module tb_reg_file;
    reg clk, rst, we;
    reg [4:0]  rd_addr, rs1_addr, rs2_addr;
    reg [31:0] w_data;
    wire [31:0] r_data1, r_data2;
    integer errors;

    reg_file uut (.clk(clk), .rst(rst), .we(we), .rd_addr(rd_addr),
                  .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .w_data(w_data),
                  .r_data1(r_data1), .r_data2(r_data2));

    always #5 clk = ~clk;

    task expect1; input [31:0] e; input [8*10-1:0] name;
        begin #1; if (r_data1 !== e) begin
            $display("FAIL %0s: r_data1=%h expected %h", name, r_data1, e); errors = errors + 1; end end
    endtask
    task expect2; input [31:0] e; input [8*10-1:0] name;
        begin #1; if (r_data2 !== e) begin
            $display("FAIL %0s: r_data2=%h expected %h", name, r_data2, e); errors = errors + 1; end end
    endtask

    task write_reg; input [4:0] a; input [31:0] d;
        begin @(negedge clk); we = 1; rd_addr = a; w_data = d; @(negedge clk); we = 0; end
    endtask

    initial begin
`ifdef DUMP_VCD
        $dumpfile("reg_wave.vcd");
        $dumpvars(0, tb_reg_file);
`endif
        errors = 0; clk = 0; rst = 1; we = 0;
        rd_addr = 0; rs1_addr = 0; rs2_addr = 0; w_data = 0;
        repeat (2) @(posedge clk);
        #1 rst = 0;

        write_reg(5'd1, 32'd55);
        rs1_addr = 1;  expect1(32'd55, "write x1");

        write_reg(5'd0, 32'd99);                     // x0 must stay 0
        rs1_addr = 0;  expect1(32'd0, "x0 fixed");

        write_reg(5'd31, 32'hCAFEBABE);
        rs1_addr = 1; rs2_addr = 31;                  // dual read
        expect1(32'd55, "dual rs1"); expect2(32'hCAFEBABE, "dual rs2");

        // write disabled: value must not change
        @(negedge clk); we = 0; rd_addr = 5'd1; w_data = 32'hFFFFFFFF; @(negedge clk);
        rs1_addr = 1;  expect1(32'd55, "we=0");

        // reset clears everything
        @(negedge clk); rst = 1; @(negedge clk); rst = 0;
        rs1_addr = 1; rs2_addr = 31;
        expect1(32'd0, "reset x1"); expect2(32'd0, "reset x31");

        if (errors == 0) $display("ALL TESTS PASSED (tb_reg_file)");
        else             $display("TESTS FAILED: %0d error(s) (tb_reg_file)", errors);
        $finish;
    end
endmodule
