/*  Hazard Unit  */
module hu(
    input wire  [4:0]   rs_ex,
    input wire  [4:0]   rt_ex,
    output wire [1:0]  forward_a,
    output wire [1:0]  forward_b,
    input wire  [4:0]   write_reg_mem,
    input wire          cu_reg_write_mem,
    input wire  [4:0]   write_reg_wb,
    input wire          cu_reg_write_wb
);

    /*  Data Forwarding  */
    // TODO


endmodule // hu