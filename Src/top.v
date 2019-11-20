//`define __QUARTUS__
`ifndef __QUARTUS__
    `include "./Src/alu.v"
    `include "./Src/cu.v"
    `include "./Src/ram.v"
    `include "./Src/register.v"
    `include "./Src/rom.v"
    `include "./Src/terminal.v"
`endif

module top(
	input   wire            clk,
	input   wire            reset_n,
    output  wire    [7:0]   terminal_bus
);

    // ROM
    wire    [31:0]  rom_dout        ;
    wire    [10:0]  rom_addr        ;

    // CU
    wire    [5:0]   cu_op           ;
    wire    [5:0]   cu_funct        ;
    wire            cu_reg_write    ;
    wire            cu_reg_dst      ;
    wire            cu_alu_src      ;
    wire            cu_branch       ;
    wire            cu_mem_write    ;
    wire            cu_mem_to_reg   ;
    wire    [2:0]   cu_alu_control  ;

    // ALU
    wire    [31:0]  alu_A           ;
    wire    [31:0]  alu_B           ;
    wire    [2:0]   alu_F           ;
    wire    [31:0]  alu_result      ;
    wire            alu_zero        ;

    // register
    wire    [4:0]   reg_addr1       ;
    wire    [31:0]  reg_read1       ;

    wire    [4:0]   reg_addr2       ;
    wire    [31:0]  reg_read2       ;

    wire            reg_we3         ;
    wire    [4:0]   reg_addr3       ;
    wire    [31:0]  reg_write3      ;

    // RAM
    wire            ram_we          ;
    wire    [31:0]  ram_addr        ;
    wire    [31:0]  ram_read        ;
    wire    [31:0]  ram_write       ;

    // terminal
    // wire    [7:0]   terminal_bus    ;


    rom  u_rom (
        .dout           (   rom_dout        ),
        .addr           (   rom_addr        )
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
        .zero           (   alu_zero        )
    );

    ram  u_ram (
        .clk            (   clk             ),
        .reset_n        (   reset_n         ),
        .we             (   ram_we          ),
        .addr           (   ram_addr        ),
        .data_read      (   ram_read        ),
        .data_write     (   ram_write       )
    );

    terminal u_terminal (
        .clk            (   clk             ),
        .reset_n        (   reset_n         ),
        .we             (   ram_we          ),
        .addr           (   ram_addr        ),
        .data_write     (   ram_write       ),
        .terminal_bus   (   terminal_bus    )
    );

    wire [10:0] pc;
    reg [10:0] pc_d = 11'h0;
    wire pc_src;
    wire [10:0] pc_branch;
    wire [10:0] pc_plus4;

    // pc
    assign pc_src = cu_branch & alu_zero;
    assign pc = pc_src ? pc_branch : pc_plus4;
    assign pc_plus4 = pc_d + 11'h4;

    // pc_ff
    always @(posedge clk or negedge reset_n)
	begin
        if(!reset_n)
			pc_d <= 11'h0;
        else
			pc_d <= pc;
    end

    assign rom_addr = pc_d;

    wire [31:0] instr = rom_dout;

    // rom to cu
    assign cu_op    = instr[31:26];
    assign cu_funct = instr[5:0];

    // rom to reg
    wire [31:0] result;

    assign reg_addr1    = instr[25:21];
    assign reg_addr2    = instr[20:16];
    assign reg_addr3    = cu_reg_dst ? instr[15:11] : instr[20:16];
    assign reg_we3      = cu_reg_write;
    assign reg_write3   = result;

    // sign extend
    wire [31:0] signImm = {{16{instr[15]}},instr[15:0]};
    assign pc_branch = pc_plus4 + (signImm << 2'd2);

    // reg to alu
    assign alu_A = reg_read1;
    assign alu_B = cu_alu_src ? signImm : reg_read2;
    assign alu_F = cu_alu_control;

    // alu to ram
    assign ram_addr = alu_result;
    assign ram_write = reg_read2;
    assign ram_we = cu_mem_write;

    assign result = cu_mem_to_reg ? ram_read : alu_result;


endmodule // top