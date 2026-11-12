`timescale 1ns / 1ps
// Self-checking system test. Runs tests/test_program.s (assembled into
// program.hex) on the full core and compares the final register file and data
// memory against expected values. Prints "ALL TESTS PASSED" or FAIL lines.
module tb_top;
    reg clk, rst;
    wire [31:0] alu_result;
    integer errors, cycles;
    reg [31:0] last_pc;

    riscv_top #(.INIT_FILE("program.hex")) uut (
        .clk(clk), .rst(rst), .alu_result(alu_result)
    );

    always #5 clk = ~clk;

    task check_reg;
        input integer n;
        input [31:0] expected;
        begin
            if (uut.rf.registers[n] !== expected) begin
                $display("FAIL: x%0d = %h, expected %h", n, uut.rf.registers[n], expected);
                errors = errors + 1;
            end
        end
    endtask

    task check_mem; // byte address
        input integer addr;
        input [31:0] expected;
        begin
            if (uut.dmem.mem[addr >> 2] !== expected) begin
                $display("FAIL: dmem[0x%0h] = %h, expected %h", addr, uut.dmem.mem[addr >> 2], expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
`ifdef DUMP_VCD
        $dumpfile("cpu.vcd");
        $dumpvars(0, tb_top);
`endif
        errors = 0; cycles = 0;
        clk = 0; rst = 1;
        repeat (2) @(posedge clk);
        #1 rst = 0;

        // Run until the program parks in its halt loop (PC stops changing)
        // or a timeout expires.
        last_pc = 32'hFFFFFFFF;
        while (uut.pc !== last_pc && cycles < 2000) begin
            last_pc = uut.pc;
            @(posedge clk); #1;
            cycles = cycles + 1;
        end
        if (cycles >= 2000) begin
            $display("FAIL: timeout, program never reached halt loop (pc=%h)", uut.pc);
            errors = errors + 1;
        end
        $display("Program halted at PC=0x%h after %0d cycles", uut.pc, cycles);

        // ---- Arithmetic ----
        check_reg(0,  32'h0);
        check_reg(1,  32'd10);
        check_reg(2,  32'd3);
        check_reg(3,  32'd13);
        check_reg(4,  32'd7);
        check_reg(5,  32'd2);
        check_reg(6,  32'd11);
        check_reg(7,  32'd9);
        check_reg(8,  32'd80);
        check_reg(9,  32'd1);
        check_reg(10, 32'hFFFFFFF0);
        check_reg(11, 32'hFFFFFFFE);
        check_reg(12, 32'h1FFFFFFE);
        check_reg(13, 32'd1);
        check_reg(14, 32'd0);
        check_reg(15, 32'd160);
        check_reg(16, 32'hFFFFFFFC);
        check_reg(17, 32'h12345678);
        check_reg(18, 32'h00000048);
        // ---- Memory ----
        check_reg(19, 32'h12345678);
        check_reg(20, 32'h00000078);
        check_reg(21, 32'h0000F000);
        check_reg(22, 32'hFFFFFFF0);
        check_reg(23, 32'h000000F0);
        check_reg(24, 32'hFFF00000);
        check_reg(25, 32'hFFFFFFF0);
        check_reg(26, 32'h0000FFF0);
        check_reg(27, 32'h00000056);
        check_reg(28, 32'h00001234);
        check_reg(29, 32'd10);
        check_mem(32'h00, 32'h12345678);
        check_mem(32'h04, 32'h0000F000);
        check_mem(32'h08, 32'hFFF00000);
        check_mem(32'h10, 32'd10);
        // ---- Branches: taken -> 0, not taken -> 5 ----
        check_mem(32'h40, 0);  check_mem(32'h44, 5);   // BEQ
        check_mem(32'h48, 0);  check_mem(32'h4C, 5);   // BNE
        check_mem(32'h50, 0);  check_mem(32'h54, 5);   // BLT
        check_mem(32'h58, 0);  check_mem(32'h5C, 5);   // BGE
        check_mem(32'h60, 0);  check_mem(32'h64, 5);   // BLTU
        check_mem(32'h68, 0);  check_mem(32'h6C, 5);   // BGEU
        check_mem(32'h70, 4);                          // backward-branch loop
        // ---- Jumps ----
        check_mem(32'h74, 77);                         // JAL call + JALR return
        check_mem(32'h78, 32'h0000010C);               // JAL link address
        check_mem(32'h7C, 32'h0000012C);               // JALR link address
        check_reg(30, 32'h00000124);
        check_reg(31, 32'h0000012C);

        if (errors == 0) $display("ALL TESTS PASSED (tb_top)");
        else             $display("TESTS FAILED: %0d error(s) (tb_top)", errors);
        $finish;
    end
endmodule
