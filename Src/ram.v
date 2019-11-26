`define __QUARTUS__
`ifdef __QUARTUS__
    `define __IP_SPRAM__
`endif

module ram(
        input   wire            clk,
        input   wire            we,
        input   wire    [31:0]  addr,
        output  wire    [31:0]  data_read,
        input   wire    [31:0]  data_write
    );

    // signal datapath changed : input before EX/MEM Register
    // use 256 words ram
    
    `ifndef __IP_SPRAM__
        reg [31:0] ram_block[255:0];
        
        // input register
        reg q_we = 1'b0;
        reg [31:0] q_addr=32'h0;
        reg [31:0] q_data_write=32'h0;
        always @(posedge clk)
        begin
            q_we <= we;
            q_addr <= addr;
            q_data_write <= data_write;
        end
        
        // RAM Block
        reg [31:0] q_data_read=32'h0;
        always@(*)
        begin
            if(q_we && (q_addr[31:8] == 24'h0))
                ram_block[q_addr[7:0]] = q_data_write;
                
            q_data_read = ram_block[q_addr[7:0]];
        end
        assign data_read = q_data_read;
        
    `else
        // use ip_spram
        ip_spram	u_ip_spram (
        .address    (   addr[7:0]       ),
        .clock      (   clk             ),
        .data       (   data_write      ),
        .wren       (   we & (addr[31:8] == 24'h0) ),
        .q          (   data_read       )
        );
    `endif

endmodule // ram