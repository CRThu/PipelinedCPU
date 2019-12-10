module terminal(
        input   wire            clk,
        input   wire            reset_n,
        input   wire            we,
        input   wire    [31:0]  addr,
        input   wire    [31:0]  data_write,
        output  reg     [7:0]   terminal_bus
);

    // reg [7:0] terminal_bus;
    reg [127:0] terminal_block;

    integer i;
    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            terminal_bus = 8'h0;
            terminal_block = 128'h0;
        end
        else
        begin
            /*  write  */
            if(we && (addr[31:8] == 24'h0))
            begin
                terminal_bus <= data_write[7:0];
                terminal_block <= (terminal_block << 8) + data_write[7:0];
            end
        end
    end


endmodule // terminal