// implements 128KB of on-board RAM

module ram
#(
  parameter ADDR_WIDTH = 17
)
(
  input  wire                   clk_in,   // system clock
  input  wire                   en_in,    // chip enable
  input  wire                   r_nw_in,  // read/write select (read: 1, write: 0)
  input  wire  [ADDR_WIDTH-1:0] a_in,     // memory address
  input  wire  [ 7:0]           d_in,     // data input
  output wire  [ 7:0]           d_out     // data output
);

wire       ram_bram_we;
wire [7:0] ram_bram_dout;

single_port_ram_sync #(.ADDR_WIDTH(ADDR_WIDTH),
                       .DATA_WIDTH(8)) ram_bram(
  .clk(clk_in),
  .we(ram_bram_we),
  .addr_a(a_in),
  .din_a(d_in),
  .dout_a(ram_bram_dout)
);

assign ram_bram_we = (en_in) ? ~r_nw_in      : 1'b0;
assign d_out       = (en_in) ? ram_bram_dout : 8'h00;

endmodule