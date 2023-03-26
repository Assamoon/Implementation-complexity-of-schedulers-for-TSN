`timescale  1ns / 1ps

module tb_Enqueue_logic;

// Enqueue_logic Parameters
parameter PERIOD           = 10               ;
parameter threshold_max_1  = 12'b 000101001010;
parameter threshold_max_2  = 12'b 000101001010;
parameter threshold_min_1  = 12'b 000000110100;
parameter threshold_min_2  = 12'b 000000110100;
parameter WIDTH            = 40               ;

// Enqueue_logic Inputs
reg   clk_in                               = 0 ;
reg   rst_n                                = 0 ;
reg   enqueue_busy_n                       = 0 ;
reg   [7:0]  queue_number                  = 0 ;
reg   [1:0]  port_in                       = 0 ;
reg   [10:0]  frame_length                 = 0 ;
reg   [10:0]  queue_length                 = 0 ;
reg   [10:0]  free_cache                   = 0 ;

// Enqueue_logic Outputs
wire  [31:0]  front_update                 ;
wire  [16:0]  rear_update                  ;
wire  [16:0]  bm_num_update                ;
wire  enqueue_rdy                          ;
wire  type_cur                             ;


initial begin
    rst_n = 0;
    clk_in = 0;
    enqueue_busy_n=0;
    #100;
    rst_n = 1;
    #100;
    enqueue_busy_n=1;
    queue_number=8'b00000000;
    port_in=2'b00;
    frame_length=11'b00000000001;
    queue_length=11'b00010000001;
    free_cache  =11'b11111111111;
    
end

always #5 clk_in = ~clk_in;



Enqueue_logic #(
    .threshold_max_1 ( threshold_max_1 ),
    .threshold_max_2 ( threshold_max_2 ),
    .threshold_min_1 ( threshold_min_1 ),
    .threshold_min_2 ( threshold_min_2 ),
    .WIDTH           ( WIDTH           ))
 u_Enqueue_logic (
    .clk_in                  ( clk_in                      ),
    .rst_n                   ( rst_n                       ),
    .enqueue_busy_n          ( enqueue_busy_n              ),
    .sop_in                  ( sop_in                      ),
    .eop_in                  ( eop_in                      ),
    .queue_number            ( queue_number    [7:0]       ),
    .port_in                 ( port_in         [1:0]       ),
    .frame_length            ( frame_length    [10:0]      ),
    .queue_length            ( queue_length    [10:0]      ),
    .free_cache              ( free_cache      [10:0]      ),

    .front_update            ( front_update    [31:0]      ),
    .rear_update             ( rear_update     [16:0]      ),
    .bm_num_update           ( bm_num_update   [16:0]      ),
    .enqueue_rdy             ( enqueue_rdy                 ),
    .type_cur                ( type_cur                    )
);


    always@(posedge clk_in) begin
    if(!rst_n) begin
        queue_number=8'b00000000;
        port_in=2'b00;
        frame_length=11'b00000000011;
        queue_length=11'b00001100000;
        free_cache  =11'b11111111111;

    end else if(enqueue_busy_n) begin
        free_cache=free_cache-queue_length-frame_length;
    end
    end

    always@(posedge clk_in) begin

       if (queue_number[7:3]<5'b11111) begin
        queue_number[7:3]=queue_number[7:3]+1'b1;
       end
       if (queue_number[2:0]<3'b111) begin
        queue_number[2:0]=queue_number[2:0]+1'b1;
       end
    end
       
      always@(posedge clk_in) begin

       if(port_in<=2'b11) begin
        port_in=port_in+1'b1;
       end
       else begin
        port_in=2'b00;
       end
    end


     always@(posedge clk_in) begin

        if (queue_length<11'b11111111111)begin
        queue_length=11'b00000000011+queue_length;
       end
       else begin
        queue_length=11'b11111111111;
       end
    end
      
     

   
   
  



endmodule