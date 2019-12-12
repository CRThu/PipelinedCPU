`timescale 1ns/100ps

`define __QUARTUS__
`ifndef __QUARTUS__
    `include "./Src/top.v"
`else
    `define __IP_SPROM__
`endif

`define __ROM_TEST_INSTR__
//`define __ROM_WAWEI_TERMINAL__



module top_tb;

    reg clk = 1'b0;
    reg reset_n = 1'b1;
    wire [7:0] terminal_bus;

    /*  Instance  */
    top u_top(clk,reset_n,terminal_bus);

    always
        #10 clk = ~clk;

    integer i;
    initial
    begin
        $dumpfile("top.vcd");
        $dumpvars(0,top_tb);

        // load file
        `ifndef __QUARTUS__
            `ifdef __ROM_TEST_INSTR__
                $readmemh("../Sim/rom_test_instr.dat",u_top.u_rom.rom_block);
            `else
            `ifdef __ROM_WAWEI_TERMINAL__
                $readmemh("../Sim/rom_wawei_terminal.dat",u_top.u_rom.rom_block);
            `endif
            `endif
        `else
            `ifndef __IP_SPROM__
                `ifdef __ROM_TEST_INSTR__
                    $readmemh("../../../../Sim/rom_test_instr.dat",u_top.u_rom.rom_block);
                `else
                `ifdef __ROM_WAWEI_TERMINAL__
                    $readmemh("../../../../Sim/rom_wawei_terminal.dat",u_top.u_rom.rom_block);
                `endif
                `endif
             `endif
        `endif

        #20 reset_n = 1'b0;
        #20 reset_n = 1'b1;

        `ifndef __QUARTUS__
            `ifdef __ROM_TEST_INSTR__
                #500 $finish;
            `else
            `ifdef __ROM_WAWEI_TERMINAL__
                #2000 $finish;
            `endif
            `endif
        `else
            `ifdef __ROM_TEST_INSTR__
                #500 $stop;
            `else
            `ifdef __ROM_WAWEI_TERMINAL__
                #2000 $stop;
            `endif
            `endif
        `endif
    end
endmodule