`timescale 1ns / 1ps
// Self-checking data memory testbench: word/half/byte stores and loads.
module tb_data_mem;
    reg         clk, mem_write, mem_read;
    reg  [2:0]  funct3;
    reg  [31:0] addr, wdata;
    wire [31:0] rdata;
    integer errors;

    data_mem uut (.clk(clk), .mem_write(mem_write), .mem_read(mem_read),
                  .funct3(funct3), .addr(addr), .wdata(wdata), .rdata(rdata));

    always #5 clk = ~clk;

    task store;
        input [2:0] f3;
        input [31:0] a, d;
        begin
            @(negedge clk);
            funct3 = f3; addr = a; wdata = d; mem_write = 1; mem_read = 0;
            @(negedge clk);
            mem_write = 0;
        end
    endtask

    task load;
        input [2:0] f3;
        input [31:0] a, expected;
        begin
            funct3 = f3; addr = a; mem_read = 1;
            #2;
            if (rdata !== expected) begin
                $display("FAIL: load f3=%b addr=%h -> %h, expected %h", f3, a, rdata, expected);
                errors = errors + 1;
            end
            mem_read = 0;
        end
    endtask

    initial begin
`ifdef DUMP_VCD
        $dumpfile("dmem_wave.vcd");
        $dumpvars(0, tb_data_mem);
`endif
        errors = 0; clk = 0; mem_write = 0; mem_read = 0;
        funct3 = 0; addr = 0; wdata = 0;
        #1;
        store(3'b010, 32'h00, 32'hA1B2C3D4);                // SW
        load (3'b010, 32'h00, 32'hA1B2C3D4);                // LW
        load (3'b000, 32'h00, 32'hFFFFFFD4);                // LB  byte0 (sign-ext)
        load (3'b000, 32'h01, 32'hFFFFFFC3);                // LB  byte1
        load (3'b000, 32'h03, 32'hFFFFFFA1);                // LB  byte3
        load (3'b100, 32'h02, 32'h000000B2);                // LBU byte2
        load (3'b001, 32'h00, 32'hFFFFC3D4);                // LH  low
        load (3'b001, 32'h02, 32'hFFFFA1B2);                // LH  high
        load (3'b101, 32'h02, 32'h0000A1B2);                // LHU high
        store(3'b000, 32'h01, 32'h000000EE);                // SB  byte1
        load (3'b010, 32'h00, 32'hA1B2EED4);
        store(3'b001, 32'h02, 32'h00001234);                // SH  high half
        load (3'b010, 32'h00, 32'h1234EED4);
        store(3'b000, 32'h07, 32'h00000055);                // SB  word1 byte3
        load (3'b010, 32'h04, 32'h55000000);                // other bytes untouched
        // no store while mem_write = 0
        funct3 = 3'b010; addr = 32'h00; wdata = 32'hDEADBEEF; #12;
        load (3'b010, 32'h00, 32'h1234EED4);
        // mem_read = 0 -> reads as zero
        mem_read = 0; addr = 0; #2;
        if (rdata !== 32'b0) begin $display("FAIL: rdata not zero when mem_read=0"); errors = errors + 1; end
        if (errors == 0) $display("ALL TESTS PASSED (tb_data_mem)");
        else             $display("TESTS FAILED: %0d error(s) (tb_data_mem)", errors);
        $finish;
    end
endmodule
