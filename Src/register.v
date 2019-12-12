module register(
        input   wire            clk,
        input   wire            reset_n,

        input   wire    [4:0]   addr1,
        output  reg     [31:0]  read1,

        input   wire    [4:0]   addr2,
        output  reg     [31:0]  read2,

        input   wire            we3,
        input   wire    [4:0]   addr3,
        input   wire    [31:0]  write3
    );

    reg [31:0] register_block [31:0];

    /*  Read  */
    //assign read1 = (addr1==5'b00000) ? 32'h0 : register_block[addr1];
    //assign read2 = (addr2==5'b00000) ? 32'h0 : register_block[addr2];
    always@(*)
    begin
        if(addr1 == 5'b00000)
        begin
            read1 = 32'h0;
        end
        else
        if(addr1 == addr3 && we3)
        begin
            read1 = write3;
        end
        else
        begin
            read1 = register_block[addr1];
        end
        
        if(addr2 == 5'b00000)
        begin
            read2 = 32'h0;
        end
        else
        if(addr2 == addr3 && we3)
        begin
            read2 = write3;
        end
        else
        begin
            read2 = register_block[addr2];
        end
    end
    
    integer i;
    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            /*  reset  */
            for(i=0;i<32;i=i+1)
                register_block[i] = 32'h0;
        end
        else
        begin
            /*  write  */
            if(we3 && (addr3 != 5'b00000))
                register_block[addr3] <= write3;
        end
    end

endmodule // register