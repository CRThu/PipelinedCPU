`timescale 1ns/100ps

`define __QUARTUS__
`ifdef __QUARTUS__
    `define __IP_PLL__
`endif

module pll(
        input   wire    clk_in,
        input   wire    reset_n,
        output  wire    pll_locked,
        output  wire    clk_out_0,
        output  wire    clk_out_1
    );
    
    // clkin = 50MHz
    // clkout_0 = 100MHz
    // clkout_1 = 50MHz
    
    `ifndef __IP_PLL__
        wire clk_in_delay;
        wire locked_delay;
        
        assign #5 clk_in_delay = clk_in;
        assign #5 locked_delay = reset_n;   // #90
        assign pll_locked = locked_delay & reset_n;
        
        assign clk_out_0 = (clk_in ^ clk_in_delay) & pll_locked ;
        assign clk_out_1 = clk_in & pll_locked;
        
    `else
        ip_pll	u_ip_pll (
        .areset ( ~reset_n      ),
        .inclk0 ( clk_in        ),
        .c0     ( clk_out_0     ),
        .c1     ( clk_out_1     ),
        .locked ( pll_locked    )
        );
    `endif

endmodule 