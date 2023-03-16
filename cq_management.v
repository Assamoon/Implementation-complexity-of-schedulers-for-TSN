module cq_management(
	input			clk_i,
	input			rst_i,

    input           fifo_sel_i,
	input			eop_i,
	input			vld_i,
	output			rdy_o,
	input	[7:0]	data_i,
	
	input			req_i,
	output			ack_o,
	output  [7:0]	data_o,
	output	[1:0]	status_o		
);


wire wr0, wr1;
wire rd0, rd1;
wire empty0, empty1;
wire rdy0, rdy1;
wire [7:0] data0;
wire [7:0] data1;

reg  fifo_sel;
reg [1:0] cq_status;
reg empty0_d;
reg empty1_d;

assign rdy_o = ~fifo_sel ? (~rdy0) : (~rdy1);
assign wr0 = ~fifo_sel & vld_i & (~rdy0);
assign wr1 = fifo_sel  & vld_i & (~rdy1);
assign rd0 = fifo_sel  & req_i & (~empty0);
assign rd1 = ~fifo_sel & req_i & (~empty1);
assign data_o = fifo_sel ? data0 : data1;
assign ack_o  = fifo_sel ? (~empty0) : (~empty1);
assign status_o = cq_status;

always@(*) begin
    fifo_sel = fifo_sel_i;
end
//always@(posedge clk_i) begin
//	if(rst_i) begin
//		fifo_sel <= 1'b0;
//	end else if((wr0|wr1) & eop_i) begin
//		fifo_sel <= ~fifo_sel;
//	end
//end

always@(posedge clk_i) begin
	if(rst_i) begin
		cq_status[0] <= 0;
	end else if(wr0 & eop_i) begin
		cq_status[0] <= 1'b1;
	end else if(empty0 & (~empty0_d) & cq_status[0]) begin
		cq_status[0] <= 0;
	end
end

always@(posedge clk_i) begin
	if(rst_i) begin
		cq_status[1] <= 0;
	end else if(wr1 & eop_i) begin
		cq_status[1] <= 1'b1;
	end else if(empty1 & (~empty1_d) & cq_status[1]) begin
		cq_status[1] <= 0;
	end
end

always@(posedge clk_i) begin
	if(rst_i) begin
		empty0_d <= 0;
		empty1_d <= 0;
	end else begin
		empty0_d <= empty0;
		empty1_d <= empty1;
	end
end

//FIFO 2K*8bit
fifo_generator_1 cq_a (
  .clk(clk_i),      // input wire clk
  .din(data_i),      // input wire [7 : 0] din
  .wr_en(wr0),  // input wire wr_en
  .rd_en(rd0),  // input wire rd_en
  .dout(data0),    // output wire [7 : 0] dout
  .full(rdy0),    // output wire full
  .empty(empty0)  // output wire empty
);

fifo_generator_1 cq_b (
  .clk(clk_i),      // input wire clk
  .din(data_i),      // input wire [7 : 0] din
  .wr_en(wr1),  // input wire wr_en
  .rd_en(rd1),  // input wire rd_en
  .dout(data1),    // output wire [7 : 0] dout
  .full(rdy1),    // output wire full
  .empty(empty1)  // output wire empty
);
//cq_fifo cq_a(
//	.wrclk(clk_i),
//	.data(data_i),
//	.wrreq(wr0),
//	.wrfull(rdy0),

//	.rdclk(clk_i),
//	.rdreq(rd0),
//	.rdempty(empty0),
//	.q(data0)
//);

//cq_fifo cq_b(
//	.wrclk(clk_i),
//	.data(data_i),
//	.wrreq(wr1),
//	.wrfull(rdy1),

//	.rdclk(clk_i),
//	.rdreq(rd1),
//	.rdempty(empty1),
//	.q(data1)
//);

endmodule
