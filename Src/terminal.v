module terminal(
        input   wire            clk,
        input   wire            reset_n,
        input   wire            we,
        input   wire    [31:0]  addr,
        output  wire    [31:0]  data_read,
        input   wire    [31:0]  data_write,
        output  reg     [7:0]   terminal_bus = 8'h0
);

    // reg [7:0] terminal_bus;
    reg [127:0] terminal_block = 128'h0;
    reg terminal_data_changed = 1'b0;
    //wire terminal_data_changed;
    
    assign data_read = 32'hFFFFFFFF;
    
    //assign terminal_data_changed = reset_n && we && (addr[31:8] == 24'h0) && clk;

    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            terminal_bus <= 8'h0;
            terminal_block <= 128'h0;
            terminal_data_changed <= 1'b0;
        end
        else
        begin
            /*  write  */
            if(we && (addr[31:8] == 24'h0))
            begin
                terminal_bus <= data_write[7:0];
                terminal_block <= (terminal_block << 8) + data_write[7:0];
                terminal_data_changed <= 1'b1;
            end
            //if(terminal_data_changed)
                //terminal_data_changed <= 1'b0;
        end
    end
    
    always@(negedge clk)
    begin
        terminal_data_changed <= 1'b0;
    end

endmodule // terminal