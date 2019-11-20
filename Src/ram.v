module ram(
        input   wire            clk,
        input   wire            reset_n,
        input   wire            we,
        input   wire    [31:0]  addr,
        output  wire    [31:0]  data_read,
        input   wire    [31:0]  data_write
    );

    reg [31:0] ram_block[255:0];

    /*  read  */
    assign data_read = ram_block[addr];

    integer i;
    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            /*  reset  */
            for(i=0;i<255;i=i+1)
                ram_block[i] = 32'h0;
        end
        else
        begin
            /*  write  */
            if(we && (addr[31:8] == 24'h0))
                ram_block[addr] <= data_write;
        end
    end

endmodule // ram