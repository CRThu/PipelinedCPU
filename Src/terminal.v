module terminal(
        input   wire            clk,
        input   wire            reset_n,
        input   wire            we,
        input   wire    [31:0]  addr,
        output  reg     [31:0]  data_read,
        input   wire    [31:0]  data_write,
        output  reg     [7:0]   terminal_bus = 8'h0
);
    
    // addr = 0 : terminal_bus  (8bit, [7:0])
    // addr = 1 : uart_tx       (8bit, [7:0])
    // addr = 2 : uart_tx_en    (1bit, [0:0])
    // addr = 3 : uart_rx       (8bit, [7:0])
    // addr = 4 : uart_rx_done  (1bit, [0:0])
    
    
    // reg [7:0] terminal_bus;
    reg [127:0] terminal_block = 128'h0;
    
    
    //wire terminal_data_changed;
    //reg [7:0] uart_tx_buf = 8'h0;
    //reg terminal_data_changed = 1'b0;
    reg [7:0] uart_rx_buf = 8'hCC;  // for test,  8'hCC
    reg uart_rx_done_flag = 1'b1;   // for test,  1'b1
    
    //assign data_read = 32'hFFFFFFFF;
    
    //assign terminal_data_changed = reset_n && we && (addr[31:8] == 24'h0) && clk;

    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            terminal_bus <= 8'h0;
            terminal_block <= 128'h0;
            //terminal_data_changed <= 1'b0;
        end
        else
        begin
            /*  write  */
            if(we/* && (addr[31:8] == 24'h0)*/)
            begin
                case(addr)
                    32'h0:
                    begin
                        terminal_bus <= data_write[7:0];
                        terminal_block <= (terminal_block << 8) + data_write[7:0];
                    end
                    //32'h1:
                    //begin
                        //uart_tx_buf <= data_write[7:0];
                    //end
                    //32'h2:
                    //begin
                        //if(data_write == 32'b1)
                            //terminal_data_changed <= 1'b1;
                    //end
                    32'h4:
                    begin
                        uart_rx_done_flag <= data_write[0];
                    end
                    default:
                    begin
                        
                    end
                endcase
            end
            //if(terminal_data_changed)
                //terminal_data_changed <= 1'b0;
        end
    end
    
    always@(*)
    begin
        /*  read  */
        case(addr)
            32'h3:
            begin
                data_read <= {24'b0,uart_rx_buf};
            end
            32'h4:
            begin
                data_read <= {31'b0, uart_rx_done_flag};
            end
            default:
            begin
                data_read <= 32'b0;
            end
        endcase
    end
    
    //always@(negedge clk)
    //begin
        //terminal_data_changed <= 1'b0;
    //end

endmodule // terminal