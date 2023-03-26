//`resetall
//`timescale 1 ns / 1 ps
//`default_nettype none

module Enqueue_logic

#(     parameter threshold_max_1 = 12'b 000101001010 ,   //512  //threshold max public   memory for  cyclic queue 
       parameter threshold_max_2 = 12'b 000101001010 ,  //512  //threshold max public   memory for  general queue
	     parameter threshold_min_1 = 12'b 000000110100 ,  //64  //threshold min private  memory for  cyclic queue  
       parameter threshold_min_2 = 12'b 000000110100 ,  //64   //threshold min private  memory for  general queue 
       parameter WIDTH=40                  // width of the input and output signals
 )
  (
       
      input                     clk_in,
      input                     rst_n, 
      input                     enqueue_busy_n,//if the module start tp receive the queue;

   //Input frame parameter 
      input			sop_in,   //start  bm label
      input			eop_in,   //end    bm label       
      input     [7:0]           queue_number,
      input     [1:0]           port_in,
      input     [10:0]          frame_length,

// Judge parameter
 
      input       [10:0]        queue_length,      
      input       [10:0]        free_cache,       //free bm number from queue information control module . 

      output      [31:0]        front_update,
      output      [16:0]        rear_update ,
      output      [16:0]        bm_num_update,
      output                    enqueue_rdy,
      output                    type_cur

  );



// machine state decode
  localparam  INIT = 3'b000 ;
  localparam  IDLE = 3'b001 ;
  localparam  READ_QUEUE_INFO = 3'b010 ;
  localparam  CYCLIC_QUEUE_JUDGE = 3'b011 ;
  localparam  GENERAL_QUEUE_JUDGE = 3'b100 ;
  localparam  JUDGE_FAIL = 3'b101 ;
  localparam  WR_ENQUEUE_RESULT = 3'b110 ; // update 
  localparam  ENQUEUE_FINISH =3'b111;



// state transfer
  reg[2:0]    st_next;
  reg[2:0]    st_cur;


   always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            st_cur     <= INIT;
        end
        else begin
            st_cur      <= st_next ;
        end
    end

// 

// state switch, using block assignment for combination-logic  
    reg   [2:0]         frame_type_r;
    reg   [10:0]        frame_length_r;
    reg   [10:0]        queue_length_r;
    reg   [11:0]        total_length ;

  always @(posedge clk_in) begin  
    case(st_cur) 
      INIT:begin
           frame_type_r<=queue_number[2:0];
           queue_length_r<=queue_length;
           st_next = IDLE ;
      end
             
      IDLE:begin
         
          if(!enqueue_busy_n) begin
             st_next  = INIT; 
          end else begin
            st_next=READ_QUEUE_INFO;
            total_length<=queue_length+frame_length;
          end
      end


    //read the queue's information 
      READ_QUEUE_INFO:begin

            case(frame_type_r)

                  3'b000: begin   st_next =GENERAL_QUEUE_JUDGE; end
 
                  3'b001: begin   st_next =GENERAL_QUEUE_JUDGE; end

                  3'b010: begin  st_next=GENERAL_QUEUE_JUDGE; end
 
                  3'b011: begin  st_next=GENERAL_QUEUE_JUDGE; end

                  3'b100: begin  st_next=GENERAL_QUEUE_JUDGE; end

                  3'b101: begin  st_next =GENERAL_QUEUE_JUDGE; end

                  3'b110: begin  st_next =CYCLIC_QUEUE_JUDGE; end

                  3'b111: begin  st_next =CYCLIC_QUEUE_JUDGE; end


                   default:begin  st_next<= IDLE; end

             endcase 
      end     
 
      CYCLIC_QUEUE_JUDGE:begin

          if(free_cache>frame_length) begin
            st_next=WR_ENQUEUE_RESULT;
          end else begin
            st_next=JUDGE_FAIL;
          end
      end
  
      GENERAL_QUEUE_JUDGE:begin
            if(total_length<=threshold_min_2) begin
                      st_next=WR_ENQUEUE_RESULT;
              end else if(total_length>threshold_max_2) begin
                st_next=JUDGE_FAIL;
              end else if((total_length-threshold_min_2)>free_cache) begin
                st_next=JUDGE_FAIL;
              end else begin
                st_next=WR_ENQUEUE_RESULT;
              end
      end

      JUDGE_FAIL:begin
              st_next<=IDLE;
      end

      WR_ENQUEUE_RESULT:begin
              st_next<=ENQUEUE_FINISH;
      end

      ENQUEUE_FINISH:begin
              st_next<=IDLE;
      end


      default: begin  
              st_next = IDLE ;
      end

endcase
end

  //(3) output logic, using non-block assignment
   
reg               Enqueue_ready_r;
reg               Enqueue_success_r;
reg               Enqueue_fail_r;
reg               Enqueue_JUDGE_r;
reg               type_cur_r;
reg     [31:0]    front_r;
reg     [15:0]    front_address_r;
reg     [15:0]    rear_r;
reg     [10:0]    occupied_bm_r;
reg     [10:0]    frame_length_rr;
reg     [10:0]    queue_length_rr;

always @(posedge clk_in ) begin
  case(st_cur)

    3'b001:begin
            Enqueue_ready_r<=1'b0;
    end
        
    3'b010:begin
            Enqueue_JUDGE_r<=1'b1;
    end

    3'b011: begin
            Enqueue_JUDGE_r<=1'b0;
            type_cur_r<=1'b1;
    end

    1'b100 : begin
           Enqueue_JUDGE_r<=1'b0;
           type_cur_r<=1'b0;
           front_address_r<=queue_number[7:3]<<4;
           rear_r<=front_address_r+frame_length;
           frame_length_rr<=frame_length;
           queue_length_rr<=queue_length;
    end

    3'b101 :    begin
           Enqueue_fail_r<=1'b1;
    end

        
    3'b110 : begin
            front_r<= {8'b00000000, queue_number,front_address_r+4'b1111};
            rear_r<=rear_r+4'b1111;
            occupied_bm_r<=frame_length_rr+queue_length_rr;
    end
          


    3'b111 : begin
             
    end

 
endcase

end

assign   front_update=front_r ;
assign   rear_update=rear_r ;
assign   bm_num_update=occupied_bm_r ;
assign   enqueue_rdy= Enqueue_ready_r ;
assign   type_cur=type_cur_r;


  endmodule