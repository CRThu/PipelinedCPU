`define __QUARTUS__
`ifdef __QUARTUS__
    `define __IP_SPROM__
`endif

module rom(
        input   wire            clk,
        input   wire            aclr,
        output  wire    [31:0]  dout,
        input   wire    [10:0]  addr,
        input   wire            stall_pc
    );

    // signal datapath changed : input before PC_Register
    // use 256 words rom
    // TODO: TO BE UPDATED stall_pc!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    `ifndef __IP_SPROM__
        reg [31:0] rom_block [255:0];
        
        // input register
        reg [10:0] q_addr=11'h0;
        always@(posedge clk or posedge aclr)
        begin
            if(aclr)
                q_addr <= 11'h0;
            else
                q_addr <= addr;
        end
        
        // ROM Block
        reg [31:0] q_dout=32'b0;
        always@(*)
        begin
            q_dout= rom_block[q_addr[9:2]];
        end
        assign dout = q_dout;
        
    `else
        // use ip_sprom
        ip_sprom u_ip_sprom (
            .aclr       ( aclr      ),
            .address    ( addr[9:2] ),
            .addressstall_a ( stall_pc ),
            .clock      ( clk       ),
            .q          ( dout      )
        );
    `endif
    
endmodule // rom