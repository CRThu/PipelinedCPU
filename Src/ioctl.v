/*  I/O Control  */

`define RAM_ADDR_BEGIN  32'h0000_0000
`define RAM_ADDR_END    32'h0000_00FF
`define IO_ADDR_BEGIN   32'h0000_0100
`define IO_ADDR_END     32'h0000_01FF

module ioctl(
    /*  input we/addr  */
    input   wire            we,
    input   wire    [31:0]  addr,
    /*  ram we/addr  */
    output  reg             ram_we,
    output  reg     [31:0]  ram_addr,
    /*  io we/addr  */
    output  reg             io_we,
    output  reg     [31:0]  io_addr,
    /*  read mux  */
    output  reg     [1:0]   read_mux
);

    always@(*)
    begin
        io_we = 1'b0;
        io_addr = 32'hx;
        ram_we = 1'b0;
        ram_addr = 32'hx;
        read_mux = 2'bxx;
        if(addr >= `RAM_ADDR_BEGIN && addr <= `RAM_ADDR_END)
        begin
            ram_we = we;
            ram_addr = addr - `RAM_ADDR_BEGIN;
            read_mux = 2'b00;
        end
        else
        if(addr >= `IO_ADDR_BEGIN && addr <= `IO_ADDR_END)
        begin
            io_we = we;
            io_addr = addr - `IO_ADDR_BEGIN;
            read_mux = 2'b01;
        end
        else
        begin
            ram_we = 1'bx;
            io_we = 1'bx;
            ram_addr = 32'hx;
            io_addr = 32'hx;
            read_mux = 2'bxx;
        end
    end
    
endmodule