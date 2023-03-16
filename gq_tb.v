`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/09 23:31:13
// Design Name: 
// Module Name: gq_tb
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


module gq_tb;

reg clk;
reg rst;
reg gq_req;
wire gq_ack;
reg gq_vld;
wire gq_rdy;
reg [7:0] gq_data;
integer cnt;

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
        cnt <= cnt + 1;
    end
end

always@(posedge clk) begin
    if(rst) begin
        gq_req <= 0;
    end else if(cnt == 5) begin
        gq_req <= 1;
    end else if(gq_req & gq_ack) begin
        gq_req <= 0;        
    end
end

always@(posedge clk) begin
    if(rst) begin
        gq_vld <= 0;
    end else if(~gq_vld & (cnt == 5)) begin
        gq_vld <= 1;
    end else if(gq_vld & gq_ack & (gq_data=='d64)) begin
        gq_vld <= 0;        
    end
end


always@(posedge clk) begin
    if(rst) begin
        gq_data <= 0;
    end else if(gq_vld & gq_rdy) begin
        gq_data <= gq_data + 1;
    end
end

wire gq_output_vld;
wire gq_output_rdy;
wire [39:0] gq_output_info;
wire bm_rd;
reg [6:0] chain_idx;
reg [6:0] nxt_idx;
reg [6:0] bm_raddr0;
reg [5:0] bm_raddr1;
reg [5:0] bm_raddr1_last;
wire [7:0] bm_rdata;



gq_management gq_management(
	.clk_i(clk),
	.rst_i(rst),

	.gq_req_i(gq_req),
	.gq_ack_o(gq_ack),
	.port_no_i(0),
	.gq_len_i('d65),
	.gq_vld_i(gq_vld),
	.gq_rdy_o(gq_rdy),
	.gq_data_i(gq_data),

	.gq_vld_o(gq_output_vld),
	.gq_rdy_i(gq_output_rdy),
	.gq_info_o(gq_output_info),
	.bm_rd_i(bm_rd),
	.bm_raddr0_i(bm_raddr0),
	.bm_raddr1_i(bm_raddr1),
	.bm_rdata_o(bm_rdata)
);

localparam  IDLE = 2'b00,
            GET_INFO = 2'b01,
            GET_DATA = 2'b10;

reg [1:0] rd_cur_st;
reg [1:0] rd_nxt_st;

assign gq_output_rdy = (rd_cur_st==GET_DATA) && (bm_raddr1 == bm_raddr1_last);
assign bm_rd = (rd_cur_st == GET_DATA);

always@(posedge clk) begin
    if(rst) begin
        rd_cur_st <= IDLE;
    end else begin
        rd_cur_st <= rd_nxt_st;
    end
end

always@(*) begin
    case(rd_cur_st)
        IDLE: begin
            if(gq_output_vld) rd_nxt_st = GET_INFO;
            else rd_nxt_st = IDLE;
        end
        GET_INFO: begin
            rd_nxt_st = GET_DATA;
        end
        GET_DATA: begin
            if(bm_raddr1 == bm_raddr1_last) rd_nxt_st = IDLE;
            else                            rd_nxt_st = GET_DATA;            
        end
        default: begin
            rd_nxt_st = IDLE; 
        end
    endcase
end

always@(posedge clk) begin
    if(rst) begin
        chain_idx <= 0;
    end else if(rd_cur_st == GET_INFO) begin
        chain_idx <= bm_raddr1 + 1'b1; 
    end   
end

always@(posedge clk) begin
    if(rst) begin
        nxt_idx <= 0;
    end else if(rd_cur_st == GET_INFO) begin
        nxt_idx <= gq_output_info[31:16];
    end   
end

always@(posedge clk) begin
    if(rst) begin
        bm_raddr0 <= 0;
    end else if(rd_cur_st == GET_INFO) begin
        if(gq_output_info[39])
            bm_raddr0 <= chain_idx; 
        else
            bm_raddr0 <= nxt_idx;
    end   
end

always@(posedge clk) begin
    if(rst) begin
        bm_raddr1 <= 0;
        bm_raddr1_last <= 0;
    end else if(rd_cur_st == GET_INFO) begin
        bm_raddr1 <= 0;
        bm_raddr1_last <= gq_output_info[37:32];
    end else if(rd_cur_st == GET_DATA) begin
        bm_raddr1 <= bm_raddr1 + 1'b1; 
    end   
end

endmodule
