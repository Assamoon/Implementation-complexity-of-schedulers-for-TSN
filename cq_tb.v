`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/10 22:59:16
// Design Name: 
// Module Name: cq_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cq_tb;

reg clk;
reg rst;
integer cnt;
reg time_slice;
wire cq_vld;
wire cq_rdy;
wire cq_eop;
wire [7:0] cq_in_data;
wire [1:0] cq_st;
wire [7:0] cq_out_data;
wire cq_req;
wire cq_ack;


initial begin
    rst = 1;
    clk = 0;
    #100;
    rst = 0;
end

always #5 clk = ~clk;

always@(posedge clk) begin
    if(rst) begin
        cnt <= 0;
    end else begin
        if(cnt == 'd2047)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end
end

always@(posedge clk) begin
    if(rst) begin
        time_slice <= 0;
    end else if(cnt == 'd2047) begin
        time_slice <= ~time_slice;
    end
end

assign cq_vld = ((cnt >= 'd10) & (cnt <= 'd1033));
assign cq_eop = (cnt == 'd1033);
assign cq_in_data = time_slice ? (~cnt[7:0]) : (cnt[7:0]);
assign cq_req = 1'b1;

cq_management cq_management(
	.clk_i(clk),
	.rst_i(rst),
    .fifo_sel_i(time_slice),
	.eop_i(cq_eop),
	.vld_i(cq_vld),
	.rdy_o(cq_rdy),
	.data_i(cq_in_data),
	
	.req_i(cq_req),
	.ack_o(cq_ack),
	.data_o(cq_out_data),
	.status_o(cq_st)		
);

endmodule
