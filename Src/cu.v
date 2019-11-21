module cu(
        input   wire            reset_n,

        input   wire    [5:0]   op,
        input   wire    [5:0]   funct,

        output  reg             reg_write,
        output  reg             reg_dst,
        output  reg             alu_src,
        output  reg             branch,
        output  reg             mem_write,
        output  reg             mem_to_reg,
        output  reg     [2:0]   alu_control
    );

    reg [1:0] alu_op;

    always @(*)
    begin
		if(!reset_n)
		begin
            reg_write       = 0;
            reg_dst         = 0;
            alu_src         = 0;
            branch          = 0;
            mem_write       = 0;
            mem_to_reg      = 0;
            alu_op          = 2'h0;
        end
        else
        begin
            /*  main decoder  */
            case(op)
                /*  R-type instructions  */
                6'b000000:
                begin
                    reg_write = 1;
                    reg_dst = 1;
                    alu_src = 0;
                    branch = 0;
                    mem_write = 0;
                    mem_to_reg = 0;
                    alu_op = 2'b10;
                end

                /*  Memory instructions - lw  */ 
                6'b100011:
                begin
                    reg_write = 1;
                    reg_dst = 0;
                    alu_src = 1;
                    branch = 0;
                    mem_write = 0;
                    mem_to_reg = 1;
                    alu_op = 2'b00;
                end

                /*  Memory instructions - sw  */ 
                6'b101011:
                begin
                    reg_write = 0;
                    reg_dst = 0;    // X
                    alu_src = 1;
                    branch = 0;
                    mem_write = 1;
                    mem_to_reg = 0; // X
                    alu_op = 2'b00;
                end

                /*  Branch instructions - beq  */ 
                6'b000100:
                begin
                    reg_write = 0;
                    reg_dst = 0;    // X
                    alu_src = 0;
                    branch = 1;
                    mem_write = 0;
                    mem_to_reg = 0; // X
                    alu_op = 2'b01;
                end
                
                /*  NEW : addi  */
                6'b001000:
                begin
                    reg_write = 1;
                    reg_dst = 0;
                    alu_src = 1;
                    branch = 0;
                    mem_write = 0;
                    mem_to_reg = 0;
                    alu_op = 2'b00;
                end
                
                /*  NEW : NOP  */
                6'b111111:
                begin
                    reg_write = 0;
                    reg_dst = 0;    // X
                    alu_src = 0;    // X
                    branch = 0;
                    mem_write = 0;
                    mem_to_reg = 0; // X
                    alu_op = 2'b00; // X
                end
                
                default:
                begin
                    reg_write = 1'hx;
                    reg_dst = 1'hx;
                    alu_src = 1'hx;
                    branch = 1'hx;
                    mem_write = 1'hx;
                    mem_to_reg = 1'hx;
                    alu_op = 2'bxx;
                end	 
            endcase
        end
    end

    /*  ALU Decoder  */
    always@(*)
    begin
        case (alu_op)
            2'b00: 
            begin
                alu_control = 3'b010;   // add
            end

            2'b01: 
            begin
                alu_control = 3'b110;   // sub
            end

            2'b10: 
            begin
                case(funct)
                    6'b100000:  alu_control = 3'b010;   // add
                    6'b100010:  alu_control = 3'b110;   // sub
                    6'b100100:  alu_control = 3'b000;   // and
                    6'b100101:  alu_control = 3'b001;   // or
                    6'b101010:  alu_control = 3'b111;   // slt
                    default:    alu_control = 3'bxxx;
                endcase
            end

            default: 
            begin
                alu_control = 3'bxxx;
            end
        endcase
    end
endmodule // cu