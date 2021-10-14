module display_ctrl
#(
	parameter SYS_CLK_FREQ         = 100000000,
	parameter DISPLAY_REFRESH_RATE =   5000000
)
(
	input  wire        clk,
	input  wire        rst,
	input  wire        en,
	input  wire [15:0] val,
	output reg  [ 6:0] seg,
	output reg         dp,
	output reg  [ 3:0] an
);

reg [19:0] cnt;

always @(posedge clk or posedge rst) begin 
	if(rst)
		cnt <= 0;
	else
		cnt <= cnt + 1;
end 

reg  [3:0] digit;
wire [1:0] d_num;
assign d_num[1:0] = cnt[19:18];

always @(*) begin
	if (rst || !en) begin
		digit = 4'b0;
	end else begin
		case (d_num)
			2'b00: digit = val[ 3: 0];
			2'b01: digit = val[ 7: 4];
			2'b10: digit = val[11: 8];
			2'b11: digit = val[15:12];
		endcase
	end
end

always @(*) begin
    if (rst || !en) begin
		an = 4'b1111;
	end else begin
		case (d_num)
			2'b00: an = 4'b1110;
			2'b01: an = 4'b1101;
			2'b10: an = 4'b1011;
			2'b11: an = 4'b0111;
		endcase
	end
end

always @(*) begin
    if (rst || !en) begin
      	{seg, dp} = 8'b11111111;
	end else begin
		case (digit)
			4'h0: {seg, dp} = 8'b10000001;
			4'h1: {seg, dp} = 8'b11110011;
			4'h2: {seg, dp} = 8'b01001001;
			4'h3: {seg, dp} = 8'b01100001;
			4'h4: {seg, dp} = 8'b00110011;
			4'h5: {seg, dp} = 8'b00100101;
			4'h6: {seg, dp} = 8'b00000101;
			4'h7: {seg, dp} = 8'b11110001;
			4'h8: {seg, dp} = 8'b00000001;
			4'h9: {seg, dp} = 8'b00100001;
			4'ha: {seg, dp} = 8'b00010001;
			4'hb: {seg, dp} = 8'b00000111;
			4'hc: {seg, dp} = 8'b10001101;
			4'hd: {seg, dp} = 8'b01000011;
			4'he: {seg, dp} = 8'b00001101;
			4'hf: {seg, dp} = 8'b00011101;
		endcase
	end
end

endmodule : display_ctrl
