`define __QUARTUS__
`ifndef __QUARTUS__
    `include "./Src/alu.v"
    `include "./Src/cu.v"
    `include "./Src/ram.v"
    `include "./Src/register.v"
    `include "./Src/ioctl.v"
    `include "./Src/rom.v"
    `include "./Src/terminal.v"
    `include "./Src/hu.v"
`endif

module top(
	input   wire            clk,
	input   wire            reset_n,
    output  wire    [7:0]   terminal_bus
);

    /*  ROM  */
    wire    [31:0]  rom_dout        ;
    wire    [10:0]  rom_addr        ;
    wire            rom_stall       ;

    /*  Control Unit  */
    wire    [5:0]   cu_op           ;
    wire    [5:0]   cu_funct        ;
    wire            cu_reg_write    ;
    wire            cu_reg_dst      ;
    wire            cu_alu_src      ;
    wire            cu_branch       ;
    wire            cu_mem_write    ;
    wire            cu_mem_to_reg   ;
    wire    [2:0]   cu_alu_control  ;

    /*  Register Block  */
    wire    [4:0]   reg_addr1       ;
    wire    [31:0]  reg_read1       ;

    wire    [4:0]   reg_addr2       ;
    wire    [31:0]  reg_read2       ;

    wire            reg_we3         ;
    wire    [4:0]   reg_addr3       ;
    wire    [31:0]  reg_write3      ;
    
    /*  ALU  */
    wire    [31:0]  alu_A           ;
    wire    [31:0]  alu_B           ;
    wire    [2:0]   alu_F           ;
    wire    [31:0]  alu_result      ;
    //wire            alu_zero        ;

    /*  RAM  */
    wire            ram_we          ;
    wire    [31:0]  ram_addr        ;
    wire    [31:0]  ram_read        ;
    wire    [31:0]  ram_write       ;
    
    /*  Hazard Unit  */
    wire            hu_forward_a_id ;
    wire            hu_forward_b_id ;
    wire    [1:0]   hu_forward_a_ex ;
    wire    [1:0]   hu_forward_b_ex ;
    wire            hu_stall_if     ;
    wire            hu_stall_id     ;
    wire            hu_flush_ex     ;

    /*  I/O Control  */
    wire            ioctl_we        ;
    wire    [31:0]  ioctl_addr      ;
    wire            ioctl_ram_we    ;
    wire    [31:0]  ioctl_ram_addr  ;
    wire            ioctl_io_we     ;
    wire    [31:0]  ioctl_io_addr   ;
    wire            ioctl_read_mux  ;

    /*  terminal  */
    wire            terminal_we     ;
    wire    [31:0]  terminal_addr   ;
    wire    [31:0]  terminal_read   ;
    wire    [31:0]  terminal_write  ;
    // wire    [7:0]   terminal_bus    ;

    /*  IF Signal */
    wire [10:0] pc;
    reg [10:0] pc_if = 11'h0;
    wire [10:0] pc_plus4_if;
    wire [31:0] instr_if;

    /*  ID Signal  */
    reg [31:0] instr_id;
    reg [10:0] pc_plus4_id;
    wire cu_reg_write_id;
    wire cu_reg_dst_id;
    wire cu_alu_src_id;
    wire cu_branch_id;
    wire cu_mem_write_id;
    wire cu_mem_to_reg_id;
    wire [2:0] cu_alu_control_id;
    wire [31:0] reg_read1_id;
    wire [31:0] reg_read2_id;
    wire [4:0] rs_id;   // first source register
    wire [4:0] rt_id;   // second source register
    wire [4:0] rd_id;   // destination register
    wire [31:0] signimm_id;
    wire equal_id;      // early branch
    wire pc_src_id;     // early branch
    wire [10:0] pc_branch_adder_id;
    wire [10:0] pc_branch_id;
    
    /*  EX Signal  */
    reg cu_reg_write_ex;
    reg cu_reg_dst_ex;
    reg cu_alu_src_ex;
    //reg cu_branch_ex;
    reg cu_mem_write_ex;
    reg cu_mem_to_reg_ex;
    reg [2:0] cu_alu_control_ex;
    reg [31:0] reg_read1_ex;
    reg [31:0] reg_read2_ex;
    reg [4:0] rs_ex;
    reg [4:0] rt_ex;
    reg [4:0] rd_ex;
    reg [31:0] signimm_ex;
    //reg [10:0] pc_plus4_ex;
    reg [31:0] hu_forward_a_muxout;
    reg [31:0] hu_forward_b_muxout;
    wire [31:0] src_a_ex;
    wire [31:0] src_b_ex;
    wire [31:0] ram_write_data_ex;
    wire [4:0] write_reg_ex;
    //wire alu_zero_ex;
    wire [31:0] alu_result_ex;
    //wire [10:0] pc_branch_adder_ex;

    /*  MEM Signal  */
    reg cu_reg_write_mem;
    reg cu_mem_to_reg_mem;
    //reg cu_mem_write_mem;
    //reg cu_branch_mem;
    //reg alu_zero_mem;
    reg [31:0] alu_result_mem;
    //reg [31:0] ram_write_data_mem;
    reg [4:0] write_reg_mem;
    //reg [10:0] pc_branch_mem;
    //wire pc_src_mem;
    wire [31:0] ram_read_mem;

    /*  WB Signal  */
    reg cu_reg_write_wb;
    reg cu_mem_to_reg_wb;
    reg [31:0] alu_result_wb;
    reg [31:0] ram_read_wb;
    reg [4:0] write_reg_wb;
    wire [31:0] result_wb;

    /*  from hu / Register enable signal and clr signal  */
    wire pc_reg_stall = hu_stall_if;
    wire if_id_reg_stall = hu_stall_id;
    wire id_ex_reg_clr = hu_flush_ex;
    
    /*  early branch  */
    wire if_id_reg_clr = pc_src_id;

    /*  Instance  */
    rom  u_rom (
        .clk            (   clk      ),
        .aclr           (   ~reset_n        ),
        .dout           (   rom_dout        ),
        .addr           (   rom_addr        ),
        .stall_pc       (   rom_stall       )
    );
    
    cu  u_cu (
        .reset_n        (   reset_n         ),
        
        .op             (   cu_op           ),
        .funct          (   cu_funct        ),

        .reg_write      (   cu_reg_write    ),
        .reg_dst        (   cu_reg_dst      ),
        .alu_src        (   cu_alu_src      ),
        .branch         (   cu_branch       ),
        .mem_write      (   cu_mem_write    ),
        .mem_to_reg     (   cu_mem_to_reg   ),
        .alu_control    (   cu_alu_control  )
    );

    register  u_register (
        .clk            (   clk             ),
        .reset_n        (   reset_n         ),
        .addr1          (   reg_addr1       ),
        .read1          (   reg_read1       ),
        .addr2          (   reg_addr2       ),
        .read2          (   reg_read2       ),
        .we3            (   reg_we3         ),
        .addr3          (   reg_addr3       ),
        .write3         (   reg_write3      )
    );

    alu  u_alu (
        .A              (   alu_A           ),
        .B              (   alu_B           ),
        .F              (   alu_F           ),
        .Y              (   alu_result      ),
        .zero           (   /*alu_zero*/    )
    );

    ram  u_ram (
        .clk            (   clk             ),
        .we             (   ram_we          ),
        .addr           (   ram_addr        ),
        .data_read      (   ram_read        ),
        .data_write     (   ram_write       )
    );
    
    ioctl u_ioctl (
        .we             (   ioctl_we        ),
        .addr           (   ioctl_addr      ),
        .ram_we         (   ioctl_ram_we    ),
        .ram_addr       (   ioctl_ram_addr  ),
        .io_we          (   ioctl_io_we     ),
        .io_addr        (   ioctl_io_addr   ),
        .read_mux       (   ioctl_read_mux  )
    );

    terminal u_terminal (
        .clk            (   clk             ),
        .reset_n        (   reset_n         ),
        .we             (   terminal_we     ),
        .addr           (   terminal_addr   ),  
        .data_read      (   terminal_read   ),
        .data_write     (   terminal_write  ),
        .terminal_bus   (   terminal_bus    )
    );

    hu u_hu (
        .stall_if           (   hu_stall_if         ),
        .stall_id           (   hu_stall_id         ),
        .cu_branch_id       (   cu_branch_id        ),
        .forward_a_id       (   hu_forward_a_id     ),
        .forward_b_id       (   hu_forward_b_id     ),
        .rs_id              (   rs_id               ),
        .rt_id              (   rt_id               ),
        .flush_ex           (   hu_flush_ex         ),
        .rs_ex              (   rs_ex               ),
        .rt_ex              (   rt_ex               ),
        .forward_a_ex       (   hu_forward_a_ex     ),
        .forward_b_ex       (   hu_forward_b_ex     ),
        .write_reg_ex       (   write_reg_ex        ),
        .cu_mem_to_reg_ex   (   cu_mem_to_reg_ex    ),
        .cu_reg_write_ex    (   cu_reg_write_ex     ),
        .write_reg_mem      (   write_reg_mem       ),
        .cu_mem_to_reg_mem  (   cu_mem_to_reg_mem   ),
        .cu_reg_write_mem   (   cu_reg_write_mem    ),
        .write_reg_wb       (   write_reg_wb        ),
        .cu_reg_write_wb    (   cu_reg_write_wb     )
    );

    /*  pc branch mux  */
    //assign pc = pc_src_mem ? pc_branch_mem : pc_plus4_if;
    //assign pc = pc_src_id ? pc_branch_mem : pc_plus4_if;
    assign pc = pc_src_id ? pc_branch_id : pc_plus4_if;

    /*  PC Register  */
    always @(posedge clk or negedge reset_n)
	begin
        if(!reset_n)
            pc_if <= 11'h0;
        else
        begin
            if(!pc_reg_stall)
            begin
                pc_if <= pc;
            end
        end
    end

    /*  pc plus4 adder  */
    assign pc_plus4_if = pc_if + 11'h4;

    /*  rom  */
    // signal datapath changed : input before PC_Register
    assign rom_addr = pc;
    //assign rom_addr = pc_if;
    assign instr_if = rom_dout;
    
    // new for bug in pipeline 20191204
    assign rom_stall = pc_reg_stall;

    /*  IF/ID Register  */
    always @(posedge clk or negedge reset_n)
	begin
        if(!reset_n)
        begin
            instr_id <= 32'h0;
            pc_plus4_id <= 11'h0;
        end
        else
        begin
            if(if_id_reg_clr)
            begin
                instr_id <= 32'h0;
                pc_plus4_id <= 11'h0;
            end
            else
            if(!if_id_reg_stall)
            begin
                instr_id <= instr_if;
                pc_plus4_id <= pc_plus4_if;
            end
        end
    end

    /*  cu  */
    assign cu_op    = instr_id[31:26];
    assign cu_funct = instr_id[5:0];
    assign cu_reg_write_id = cu_reg_write;
    assign cu_mem_to_reg_id = cu_mem_to_reg;
    assign cu_mem_write_id = cu_mem_write;
    assign cu_branch_id = cu_branch;
    assign cu_alu_control_id = cu_alu_control;
    assign cu_alu_src_id = cu_alu_src;
    assign cu_reg_dst_id = cu_reg_dst;

    /*  reg  */
    assign reg_addr1    = instr_id[25:21];
    assign reg_addr2    = instr_id[20:16];
    assign reg_addr3    = write_reg_wb;
    assign reg_we3      = cu_reg_write_wb;
    assign reg_write3   = result_wb;
    assign reg_read1_id = reg_read1;
    assign reg_read2_id = reg_read2;
    
    /*  early branch  */
    assign equal_id = ((hu_forward_a_id ? alu_result_mem : reg_read1_id) == (hu_forward_b_id ? alu_result_mem : reg_read2_id));
    assign pc_src_id = equal_id & cu_branch_id;

    /*  write address mux signal  */
    assign rs_id = instr_id[25:21];
    assign rt_id = instr_id[20:16];
    assign rd_id = instr_id[15:11];

    /*  sign extend  */
    assign signimm_id = {{16{instr_id[15]}},instr_id[15:0]};

    /*  ID/EX Register  */
    always @(posedge clk or negedge reset_n)
	begin
        if(!reset_n)
        begin
            cu_reg_write_ex <= 1'b0;
            cu_mem_to_reg_ex <= 1'b0;
            cu_mem_write_ex <= 1'b0;
            //cu_branch_ex <= 1'b0;
            cu_alu_control_ex <= 3'b0;
            cu_alu_src_ex <= 1'b0;
            cu_reg_dst_ex <= 1'b0;
            reg_read1_ex <= 32'b0;
            reg_read2_ex <= 32'b0;
            rs_ex <= 5'b0;
            rt_ex <= 5'b0;
            rd_ex <= 5'b0;
            signimm_ex <= 32'b0;
            //pc_plus4_ex <= 11'b0;
        end
        else
        begin
            if(id_ex_reg_clr)
            begin
                cu_reg_write_ex <= 1'b0;
                cu_mem_to_reg_ex <= 1'b0;
                cu_mem_write_ex <= 1'b0;
                //cu_branch_ex <= 1'b0;
                cu_alu_control_ex <= 3'b0;
                cu_alu_src_ex <= 1'b0;
                cu_reg_dst_ex <= 1'b0;
                reg_read1_ex <= 32'b0;
                reg_read2_ex <= 32'b0;
                rs_ex <= 5'b0;
                rt_ex <= 5'b0;
                rd_ex <= 5'b0;
                signimm_ex <= 32'b0;
                //pc_plus4_ex <= 11'b0;
            end
            else
            begin
                cu_reg_write_ex <= cu_reg_write_id;
                cu_mem_to_reg_ex <= cu_mem_to_reg_id;
                cu_mem_write_ex <= cu_mem_write_id;
                //cu_branch_ex <= cu_branch_id;
                cu_alu_control_ex <= cu_alu_control_id;
                cu_alu_src_ex <= cu_alu_src_id;
                cu_reg_dst_ex <= cu_reg_dst_id;
                reg_read1_ex <= reg_read1_id;
                reg_read2_ex <= reg_read2_id;
                rs_ex <= rs_id;
                rt_ex <= rt_id;
                rd_ex <= rd_id;
                signimm_ex <= signimm_id;
                //pc_plus4_ex <= pc_plus4_id;
            end
        end
    end

    /*  reg address destination mux  */
    assign write_reg_ex = cu_reg_dst_ex ? rd_ex : rt_ex;

    /*  hazard unit / data fowarding mux  */
    always@(*)
    begin
        case(hu_forward_a_ex)
            2'b00: begin hu_forward_a_muxout = reg_read1_ex; end
            2'b01: begin hu_forward_a_muxout = result_wb; end
            2'b10: begin hu_forward_a_muxout = alu_result_mem; end
            default: begin hu_forward_a_muxout = 32'h0; end
        endcase

        case(hu_forward_b_ex)
            2'b00: begin hu_forward_b_muxout = reg_read2_ex; end
            2'b01: begin hu_forward_b_muxout = result_wb; end
            2'b10: begin hu_forward_b_muxout = alu_result_mem; end
            default: begin hu_forward_b_muxout = 32'h0; end
        endcase
    end
    
    /*  alu src mux  */
    //assign src_a_ex = reg_read1_ex;
    assign src_a_ex = hu_forward_a_muxout;
    //assign src_b_ex = cu_alu_src_ex ? signimm_ex : reg_read2_ex;
    assign src_b_ex = cu_alu_src_ex ? signimm_ex : hu_forward_b_muxout;

    /*  alu  */
    assign alu_A = src_a_ex;
    assign alu_B = src_b_ex;
    assign alu_F = cu_alu_control_ex;
    //assign alu_zero_ex = alu_zero;
    assign alu_result_ex = alu_result;

    /*  ram write data signal  */
    // new for bug in pipeline 20191204
    assign ram_write_data_ex = hu_forward_b_muxout;

    /*  branch adder  */
    //assign pc_branch_adder_ex = pc_plus4_ex + (signimm_ex << 2'd2);
    assign pc_branch_adder_id = pc_plus4_id + (signimm_id << 2'd2);
    assign pc_branch_id = pc_branch_adder_id;

    /*  EX/MEM Register  */
    always @(posedge clk or negedge reset_n)
	begin
        if(!reset_n)
        begin
            cu_reg_write_mem <= 1'b0;
            cu_mem_to_reg_mem <= 1'b0;
            //cu_mem_write_mem <= 1'b0;
            //cu_branch_mem <= 1'b0;
            //alu_zero_mem <= 1'b0;
            alu_result_mem <= 32'h0;
            //ram_write_data_mem <= 32'h0;
            write_reg_mem <= 5'h0;
            //pc_branch_mem <= 11'h0;
        end
        else
        begin
            cu_reg_write_mem <= cu_reg_write_ex;
            cu_mem_to_reg_mem <= cu_mem_to_reg_ex;
            //cu_mem_write_mem <= cu_mem_write_ex;
            //cu_branch_mem <= cu_branch_ex;
            //alu_zero_mem <= alu_zero_ex;
            alu_result_mem <= alu_result_ex;
            //ram_write_data_mem <= ram_write_data_ex;
            write_reg_mem <= write_reg_ex;
            //pc_branch_mem <= pc_branch_adder_ex;
        end
    end

    /*  pc branch mux control AND   */
    //assign pc_src_mem = cu_branch_mem & alu_zero_mem;

    /*  ioctl  */
    // add ram address mux
    assign ioctl_we = cu_mem_write_ex;
    assign ioctl_addr = alu_result_ex;
    /*  ram  */
    assign ram_we = ioctl_ram_we;
    assign ram_addr = ioctl_ram_addr;
    assign ram_write = ram_write_data_ex;
    /*  terminal  */
    assign terminal_we = ioctl_io_we;
    assign terminal_addr = ioctl_io_addr;
    assign terminal_write = ram_write_data_ex;
    /*  read_mux  */
    assign ram_read_mem = ioctl_read_mux ? terminal_read : ram_read;
    
    
    /*  ram  */
    // signal datapath changed : input before EX/MEM Register
    //assign ram_we = cu_mem_write_ex;
    //assign ram_addr = alu_result_ex;
    //assign ram_write = ram_write_data_ex;
    //assign ram_read_mem = ram_read;
    
    /*  terminal  */
    //assign terminal_we = cu_mem_write_ex;
    //assign terminal_addr = alu_result_ex;
    //assign terminal_write = ram_write_data_ex;
    

    /*  MEM/WB Register  */
    always @(posedge clk or negedge reset_n)
	begin
        if(!reset_n)
        begin
            cu_reg_write_wb <= 1'b0;
            cu_mem_to_reg_wb <= 1'b0;
            alu_result_wb <= 32'b0;
            ram_read_wb <= 32'h0;
            write_reg_wb <= 5'h0;
        end
        else
        begin
            cu_reg_write_wb <= cu_reg_write_mem;
            cu_mem_to_reg_wb <= cu_mem_to_reg_mem;
            alu_result_wb <= alu_result_mem;
            ram_read_wb <= ram_read_mem;
            write_reg_wb <= write_reg_mem;
        end
    end

    /*  writeback result mux  */
    assign result_wb = cu_mem_to_reg_wb ? ram_read_wb : alu_result_wb;

endmodule // top