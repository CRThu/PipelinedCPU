/*  Hazard Unit  */
module hu(
    output wire         stall_if,
    output wire         stall_id,
    input wire  [4:0]   rs_id,
    input wire  [4:0]   rt_id,
    output wire         flush_ex,
    input wire  [4:0]   rs_ex,
    input wire  [4:0]   rt_ex,
    output reg  [1:0]   forward_a,
    output reg  [1:0]   forward_b,
    input wire          cu_mem_to_reg_ex,
    input wire  [4:0]   write_reg_mem,
    input wire          cu_reg_write_mem,
    input wire  [4:0]   write_reg_wb,
    input wire          cu_reg_write_wb
);

    /*  Data Forwarding / when register waiting for writed in MEM and WB before being read  */
    /*  Port A  */
    always @(*)
    begin
        // if register will be read is waiting for write in MEM, mux to alu_result_mem
        if ((rs_ex != 5'b00000) & (rs_ex == write_reg_mem) & cu_reg_write_mem)
        begin
            forward_a = 2'b10;
        end
        // if register will be read is waiting for write in WB, mux to result_wb
        else
        if ((rs_ex != 5'b00000) & (rs_ex == write_reg_wb) & cu_reg_write_wb)
        begin
            forward_a = 2'b01;
        end
        else
        begin
            forward_a = 2'b00;
        end
    end

    /*  Port B  */
    always @(*)
    begin
        // if register will be read is waiting for write in MEM, mux to alu_result_mem
        if ((rt_ex != 5'b00000) & (rt_ex == write_reg_mem) & cu_reg_write_mem)
        begin
            forward_b = 2'b10;
        end
        // if register will be read is waiting for write in WB, mux to result_wb
        else
        if ((rt_ex != 5'b00000) & (rt_ex == write_reg_wb) & cu_reg_write_wb)
        begin
            forward_b = 2'b01;
        end
        else
        begin
            forward_b = 2'b00;
        end
    end

    /*  Stalling / when register waiting for loading word from RAM before being read  */
    wire lw_stall;
    assign lw_stall = ((rs_id == rt_ex) | (rt_id == rt_ex)) & cu_mem_to_reg_ex;
    assign stall_id = lw_stall;
    assign stall_if = lw_stall;
    assign flush_ex = lw_stall;

endmodule // hu