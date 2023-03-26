`timescale  1ns / 1ps      
module tb_update_output;   

// update_output Parameters
parameter PERIOD  = 10;    


// update_output Inputs    
reg   clk_in                               = 0 ;
reg   rst_n                                = 0 ;
reg   [7:0]  queue_number                  = 0 ;
reg   [2:0]  queue_type                    = 0 ;
reg   [1:0]  port_i                        = 0 ;
reg   [15:0]  bm_address                   = 0 ;
reg   queue_vld_i                          = 0 ;
reg   [1:0]  port_o                        = 0 ;
reg   [6:0]  port_state                    = 0 ;

// update_output Outputs
wire  [23:0]  queue_o_rdy                  ;


initial
begin
    forever #(PERIOD/2)  clk_in=~clk_in;
end



update_output  u_update_output (
    .clk_in                  ( clk_in               ),
    .rst_n                   ( rst_n                ),
    .queue_number            ( queue_number  [7:0]  ),
    .queue_type              ( queue_type    [2:0]  ),
    .port_i                  ( port_i        [1:0]  ),
    .bm_address              ( bm_address    [15:0] ),
    .queue_vld_i             ( queue_vld_i          ),
    .port_o                  ( port_o        [1:0]  ),
    .port_state              ( port_state    [6:0]  ),

    .queue_o_rdy             ( queue_o_rdy   [23:0] )
);

initial
begin
    rst_n=0;
    queue_vld_i=1;
    #100;
    rst_n=1;



   
end

always@(posedge clk_in) begin
    if(queue_number[2:0]<3'b111)  begin
        queue_number<=queue_number+1'b1;
    end
    else begin
        queue_number[2:0]<=3'b000;
    end
end
always@(posedge clk_in) begin
    if(queue_type<3'b111)  begin
        queue_type<=queue_type+1'b1;
    end
    else begin
        queue_type<=3'b000;
    end
end
always@(posedge clk_in) begin
    if(bm_address<16'b1111111111111111)  begin
        bm_address<=bm_address+1'b1;
    end
    else begin
        bm_address<=16'b0;
    end
end


always@(posedge clk_in) begin
    if(bm_address<16'b1111111111111111)  begin
        bm_address<=bm_address+1'b1;
    end
    else begin
        bm_address<=16'b0;
    end
end


always@(posedge clk_in) begin
    if(port_o<2'b11)  begin
        port_o<=port_o+1'b1;
    end
    else begin
        port_o<=2'b00;
    end
end

always@(posedge clk_in) begin
    if(port_state<7'b1111111)  begin
        port_state<=port_state+1'b1;
    end
    else begin
        port_state<=7'b0;
    end
end

endmodule