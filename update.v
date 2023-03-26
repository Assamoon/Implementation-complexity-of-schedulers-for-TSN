module update_output(
input 			    clk_in,
input 			    rst_n,
input   [7:0]       queue_number,
input 	[2:0]		queue_type,
input   [1:0]       port_i,
input   [15:0]      bm_address,
input               queue_vld_i,
input   [1:0]       port_o,
input   [6:0]       port_state,
output  [23:0]       queue_o_rdy
);
localparam  IDLE=2'b00;
localparam  READ_INFO=2'b01;
localparam  JUDGE=2'b10;
localparam  WRITE=2'b11;


reg [1:0] st_cur;
reg [1:0] st_next;


  always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            st_cur     <= IDLE;
        end
        else begin
            st_cur      <= st_next ;
        end
  end

reg[2:0]   queue_type_r;
reg[1:0]   port_i_r;
reg[15:0]  address_r;
reg[1:0]   info_port_r;
reg[6:0]   info_port_state_r;


always @(posedge clk_in) begin 
  case(st_cur)

	IDLE:begin
     if(!queue_vld_i) begin
	 	st_next=READ_INFO;
	 end
	 else begin
		st_next=IDLE;
	 end
	end

	READ_INFO:begin

	 st_next=JUDGE;
	end

	JUDGE:begin
    if(queue_type>3'b101) begin
    		if(port_state>7'b0) begin
				st_next=WRITE;
			end
			else begin
				st_next=READ_INFO;
			end
	end
	else begin
		if(port_state>7'b0) begin
				st_next=WRITE;
			end
			else begin
				st_next=READ_INFO;
			end
     	
	 end


	end

    WRITE:begin
     
    
	st_next=IDLE;
		  
	end

    default: st_next = IDLE;

  endcase
end
reg[23:0]   queue_o_rdy_r;
always @(posedge clk_in) begin 
		if (st_cur==WRITE) begin
			queue_o_rdy_r<= {queue_number,address_r};
		end
		else if(st_cur==READ_INFO) begin
		     queue_type_r<=queue_type;
	         port_i_r<=port_i_r;
	         address_r<=bm_address;
	         info_port_r<=port_o;
             info_port_state_r<=port_state;
        end
end

assign queue_o_rdy=queue_o_rdy_r;

endmodule