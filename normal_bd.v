module normal_bd(
	input			clk_i,
	input			rst_i,

	input			sop_i,
	input			eop_i,
	input			vld_i,
	input	[7:0]	data_i,
	input	[4:0]   port_num_i,
	input   [10:0]  frame_len_i,

	input			req_i,
	output			vld_o,
	output  [7:0]	data_o
);

//4*16KByte  link-list RAM
reg	[7:0] bd_mm  [0:65535];

reg [15:0] bd_waddr;
wire       bd_wr;
wire	   bd_rd;

assign bd_wr = vld_i;
assign bd_rd = req_i;

reg [5:0] bd_waddr_offset;
always@(posedge clk_i) begin
	if(rst_i) begin
		bd_waddr_offset <= 0;
	end else if(vld_i) begin
		if(eop_i)
			bd_waddr_offset <= 0;
		else
			bd_waddr_offset <= bd_waddr_offset + 1'b1;
	end
end

reg [9:0] bd_waddr_base;
always@(posedge clk_i) begin
	if(rst_i) begin
		bd_waddr_base <= 0;
	end else if(vld_i & eop_i) begin
		bd_waddr_base <= bd_waddr_base + 1'b1;
	end else if(vld_i & (&bd_waddr_offset)) begin
		bd_waddr_base <= bd_waddr_base + 1'b1;
	end
end

always@(*) begin
	bd_waddr = {bd_waddr_base, bd_waddr_offset};
end

//将普通队列送入链表RAM中
always@(posedge clk_i) begin
	if(bd_wr) begin
		bd_mm[bd_waddr] <= data_i;
	end
end

reg [15:0] start_addr;
always@(posedge clk_i) begin
	if(rst_i) begin
		start_addr <= 0;
	end else if(sop_i & vld_i) begin
		start_addr <= bd_waddr;
	end else if(bd_fifo_wr) begin
		start_addr <= bd_info[31:16];
	end
end

//将BD信息送入FIFO
reg        bd_fifo_wr;
wire       bd_fifo_full;
reg [39:0] bd_info;
reg [4:0]  bd_total;
always@(*) begin
	bd_fifo_wr  = (sop_i & vld_i) | (bd_total != 0);
	bd_info[39] = sop_i & vld_i;
	bd_info[38] = (bd_total == 5'd1);
	bd_info[37:32] = (bd_total == 5'd1) ? frame_len_i[5:0] : 6'd63;
	bd_info[31:16] = (sop_i & vld_i) ? (bd_waddr) : (start_addr + 16'd64);
	bd_info[15:11] = port_num_i;
	bd_info[10:0]  = frame_len_i;
end

always@(posedge clk_i) begin
	if(rst_i) begin
		bd_total <= 0;
	end else if(sop_i & vld_i) begin
		bd_total <= frame_len_i[10:6] + (|frame_len_i[5:0]) - 1'b1;
	end else if(bd_total != 0) begin
		bd_total <= bd_total - 1'b1;
	end
end

//FIFO 64*40bit
bd_info_fifo bd_info_fifo(
	.wrclk(clk_i),
	.data(bd_info),
	.wrreq(bd_fifo_wr),
	.wrfull(bd_fifo_full),

	.rdclk(clk_i),
	.rdreq(),
	.rdempty(),
	.q()
);



endmodule
