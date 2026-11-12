`timescale 1ns / 1ps
// Demo testbench: runs demo.hex and prints every instruction as it executes,
// then checks the final register values. Also exposes readable signals
// (asm text, x1..x16) for the waveform viewer.
module tb_demo;
    reg clk, rst;
    wire [31:0] alu_result;
    integer cycle, errors;

    riscv_top #(.INIT_FILE("demo.hex")) uut (.clk(clk), .rst(rst), .alu_result(alu_result));

    always #5 clk = ~clk;

    // ---------- Readable instruction text (shows as ASCII in the waveform) ----------
    reg [8*24-1:0] asm;
    reg [8*6-1:0]  mn;
    reg [8*40-1:0] effect;
    wire [31:0] inst = uut.instruction;
    wire [4:0]  rd  = inst[11:7], rs1 = inst[19:15], rs2 = inst[24:20];
    wire [2:0]  f3  = inst[14:12];
    wire [31:0] imm = uut.imm_ext;

    always @(*) begin
        case (inst[6:0])
            7'b0110011: begin
                case ({inst[30], f3})
                    4'b0000: mn = "add";  4'b1000: mn = "sub";
                    4'b0001: mn = "sll";  4'b0010: mn = "slt";
                    4'b0011: mn = "sltu"; 4'b0100: mn = "xor";
                    4'b0101: mn = "srl";  4'b1101: mn = "sra";
                    4'b0110: mn = "or";   4'b0111: mn = "and";
                    default: mn = "?";
                endcase
                $sformat(asm, "%0s x%0d,x%0d,x%0d", mn, rd, rs1, rs2);
            end
            7'b0010011: begin
                case (f3)
                    3'b000: mn = "addi"; 3'b010: mn = "slti"; 3'b011: mn = "sltiu";
                    3'b100: mn = "xori"; 3'b110: mn = "ori";  3'b111: mn = "andi";
                    3'b001: mn = "slli"; 3'b101: mn = inst[30] ? "srai" : "srli";
                    default: mn = "?";
                endcase
                $sformat(asm, "%0s x%0d,x%0d,%0d", mn, rd, rs1, $signed(imm));
            end
            7'b0000011: begin
                case (f3)
                    3'b000: mn = "lb"; 3'b001: mn = "lh"; 3'b010: mn = "lw";
                    3'b100: mn = "lbu"; 3'b101: mn = "lhu"; default: mn = "?";
                endcase
                $sformat(asm, "%0s x%0d,%0d(x%0d)", mn, rd, $signed(imm), rs1);
            end
            7'b0100011: begin
                case (f3)
                    3'b000: mn = "sb"; 3'b001: mn = "sh"; default: mn = "sw";
                endcase
                $sformat(asm, "%0s x%0d,%0d(x%0d)", mn, rs2, $signed(imm), rs1);
            end
            7'b1100011: begin
                case (f3)
                    3'b000: mn = "beq"; 3'b001: mn = "bne"; 3'b100: mn = "blt";
                    3'b101: mn = "bge"; 3'b110: mn = "bltu"; 3'b111: mn = "bgeu";
                    default: mn = "?";
                endcase
                $sformat(asm, "%0s x%0d,x%0d,%0d", mn, rs1, rs2, $signed(imm));
            end
            7'b1101111: $sformat(asm, "jal x%0d,%0d", rd, $signed(imm));
            7'b1100111: $sformat(asm, "jalr x%0d,%0d(x%0d)", rd, $signed(imm), rs1);
            7'b0110111: $sformat(asm, "lui x%0d,0x%0h", rd, imm[31:12]);
            7'b0010111: $sformat(asm, "auipc x%0d,0x%0h", rd, imm[31:12]);
            default:    $sformat(asm, "(unknown)");
        endcase
    end

    // ---------- Registers as plain signals (easy to add to the waveform) ----------
    wire [31:0] x1 = uut.rf.registers[1],   x2  = uut.rf.registers[2],
                x3 = uut.rf.registers[3],   x4  = uut.rf.registers[4],
                x5 = uut.rf.registers[5],   x6  = uut.rf.registers[6],
                x7 = uut.rf.registers[7],   x8  = uut.rf.registers[8],
                x9 = uut.rf.registers[9],   x10 = uut.rf.registers[10],
                x11 = uut.rf.registers[11], x12 = uut.rf.registers[12],
                x13 = uut.rf.registers[13], x14 = uut.rf.registers[14],
                x15 = uut.rf.registers[15], x16 = uut.rf.registers[16];
    wire [31:0] pc = uut.pc;
    wire        branch_taken = uut.branch & uut.branch_taken;

    // ---------- Console trace: one line per instruction ----------
    always @(negedge clk) if (!rst) begin
        if (uut.branch) begin
            if (uut.branch_taken) $sformat(effect, "branch TAKEN -> PC=0x%0h", uut.branch_target[11:0]);
            else                  $sformat(effect, "branch not taken");
        end
        else if ((uut.jal | uut.jalr) && rd == 0)
            $sformat(effect, "jump -> PC=0x%0h (stop loop)", uut.branch_target[11:0]);
        else if (uut.jal | uut.jalr)
            $sformat(effect, "jump, x%0d <= 0x%0h (return addr)", rd, uut.pc_plus4[11:0]);
        else if (uut.mem_write)
            $sformat(effect, "mem[%0d] <= %0d", uut.alu_result, uut.rd2);
        else if (uut.mem_read)
            $sformat(effect, "x%0d <= mem[%0d] = %0d", rd, uut.alu_result, uut.wb_data);
        else if (uut.reg_write)
            $sformat(effect, "x%0d <= %0d", rd, uut.wb_data);
        else
            $sformat(effect, "-");
        $display("cycle %2d | PC=0x%02h | %-20s | %0s", cycle, uut.pc[7:0], asm, effect);
        cycle = cycle + 1;
    end

    task check_reg;
        input integer n;
        input [31:0] expected;
        begin
            if (uut.rf.registers[n] !== expected) begin
                $display("FAIL: x%0d = %0d, expected %0d", n, uut.rf.registers[n], expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
`ifdef DUMP_VCD
        $dumpfile("demo.vcd");
        $dumpvars(0, tb_demo);
`endif
        errors = 0; cycle = 0;
        clk = 0; rst = 1;
        repeat (2) @(posedge clk);
        #1 rst = 0;
        $display("");
        $display("cycle    | PC      | instruction          | effect");
        $display("---------+---------+----------------------+------------------------------");
        repeat (21) @(posedge clk);   // 20 instructions executed + the final stop instruction
        #1;
        $display("---------+---------+----------------------+------------------------------");
        check_reg(1, 10);  check_reg(2, 3);   check_reg(3, 13);  check_reg(4, 7);
        check_reg(5, 2);   check_reg(6, 11);  check_reg(7, 80);  check_reg(8, 13);
        check_reg(9, 7);   check_reg(10, 1);  check_reg(11, 2);  check_reg(12, 32'h48);
        check_reg(13, 3);  check_reg(14, 32'h50); check_reg(15, 32'h58); check_reg(16, 4);
        if (errors == 0) $display("DEMO PASSED: all 16 register values match");
        else             $display("DEMO FAILED: %0d mismatch(es)", errors);
        $finish;
    end
endmodule
