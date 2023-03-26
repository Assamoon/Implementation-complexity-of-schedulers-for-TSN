`timescale 1ns / 1ps

module async_fifo #(parameter DATASIZE = 41,
				    parameter ADDRSIZE = 64     //parameter DEEP  = 32
						 
						 )
(
input  wire					wclk,
input  wire					rclk,
input  wire					wrst_n,
input  wire					rrst_n,
input  wire					din_vld,
input  wire	[DATASIZE-1:0]	din_data,
output reg					rempty,
output reg					ral_empty,

output wire					dout_vld,
output reg					wfull,
output reg					wal_full,
output wire	[DATASIZE-1:0] dout_data
					
);
wire	[ADDRSIZE-1:0]		waddr			;
wire	[ADDRSIZE-1:0]		raddr			;
reg	[ADDRSIZE  :0]    	waddr_bin	;
reg	[ADDRSIZE  :0]		raddr_bin	;
wire                    wfull_val	;
wire 					rempty_val	;
reg   [ADDRSIZE  :0]     rptr			;
reg   [ADDRSIZE  :0]	 wq1_rptr		;
reg   [ADDRSIZE  :0]		wq2_rptr		;

reg 	[ADDRSIZE  :0]     wptr			;
reg 	[ADDRSIZE  :0]		rq1_wptr		;
reg	[ADDRSIZE  :0]		rq2_wptr		;

wire	[ADDRSIZE  :0]     rgray_next	;
wire	[ADDRSIZE  :0]     wgray_next	;

wire	[ADDRSIZE  :0]		wbin_next		;
wire	[ADDRSIZE  :0]		rbin_next		;


localparam DEPTH = 1 << ADDRSIZE;
reg   [DATASIZE-1 :0] ram [0: DEPTH - 1];

//write and read data from ram
assign dout_data = ram[raddr];

always @(posedge wclk)
	if(din_vld && !wfull) ram[waddr] <= din_data;


//radr_gary syco to write clk
always @(posedge wclk or negedge wrst_n)
begin
if(!wrst_n)
begin
	wq1_rptr <= 0;
	wq2_rptr <= 0;
end
else 
begin
	wq1_rptr <= rptr;
	wq2_rptr <= wq1_rptr;
end
end

//wadr_gray syco to read clk
always @(posedge rclk or negedge rrst_n)
begin
if(!rrst_n)
begin
	rq1_wptr <= 0;
	rq2_wptr <= 0;
end
else 
begin
	rq1_wptr <= wptr;
	rq2_wptr <= rq1_wptr;
end
end

//generating empty 
assign rempty_val = (rgray_next == rq2_wptr);
always @(posedge rclk or negedge rrst_n)
	if(!rrst_n) rempty <= 1'b1;
	else			rempty <= rempty_val;
	
//generating  full 
//assign wfull_val = ((wgnext[DATASIZE : DATASIZE-1] != wq2_rptr[DATASIZE : DATASIZE-1]) &&
//						 (wgnext[DATASIZE-2 : 0]     == wq2_rptr[DATASIZE-2 : 0]));
assign wfull_val = (wgray_next == {~wq2_rptr[ADDRSIZE : ADDRSIZE-1],
						  wq2_rptr[ADDRSIZE-2 : 0]});
always @(posedge wclk or negedge wrst_n)
	if(!wrst_n) wfull <= 1'b0;
	else			wfull <= wfull_val;


//read point
always @(posedge rclk or negedge rrst_n)
begin
	if(!rrst_n) begin
	raddr_bin <= 0;
	rptr      <= 0;
	end
	else begin
	raddr_bin <= rbin_next;
	rptr      <= rgray_next;
	end
end

assign raddr = raddr_bin[ADDRSIZE-1 : 0];

assign rbin_next  = raddr_bin + (din_vld && ~rempty);
assign rgray_next = (rbin_next>>1) ^ rbin_next; 

//write point
always @(posedge wclk or negedge wrst_n)
begin
	if(!wrst_n)	begin
	waddr_bin <= 0;
	wptr      <= 0;
	end
	else begin
	waddr_bin <= wbin_next;
	wptr		 <= wgray_next;
	end
end

assign waddr     = waddr_bin[ADDRSIZE-1 : 0]			;

	
assign wbin_next  = waddr_bin + (din_vld && ~wfull) ;
//bin to gray
assign wgray_next = (wbin_next >>1 ) ^ wbin_next      ;





endmodule

