module alu(
        input   wire    [31:0]  A,
        input   wire    [31:0]  B,
        input   wire    [2:0]   F,
        output  reg     [31:0]  Y,
        output  wire    	    zero
    );

    /*  Y  */
    always@(*)
    begin 
        case(F)
            3'b000:     Y = A & B;
            3'b001:     Y = A | B;
            3'b010:     Y = A + B;

            3'b100:     Y = A & (~B);
            3'b101:     Y = A | (~B);

            3'b110:     Y = A - B;
            3'b111:     Y = (A < B) ? 32'b1 : 32'b0;

            default:    Y = 32'hxxxxxxxx;
        endcase
    end

    /*  zero  */
    assign zero = (A == B) ? 1'b1 : 1'b0;

endmodule // alu