module rom(
        output  wire    [31:0]  dout,
        input   wire    [10:0]  addr
    );

    reg [7:0] rom_block [2047:0];

    assign dout = {rom_block[addr+0], rom_block[addr+1], rom_block[addr+2], rom_block[addr+3]};

endmodule // rom