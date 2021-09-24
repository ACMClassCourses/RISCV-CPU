/***************************************************************************************************
*
*  Copyright (c) 2012, Brian Bennett
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, this list of conditions
*     and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright notice, this list of
*     conditions and the following disclaimer in the documentation and/or other materials provided
*     with the distribution.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
*  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
*  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*  Host communication interface.  Accepts packets over a serial connection, interacts with the rest
*  of the hw system as specified, and returns the specified data.
***************************************************************************************************/

// modification allowed for debugging purposes

module hci
#(
  parameter SYS_CLK_FREQ = 100000000,
  parameter RAM_ADDR_WIDTH = 17,
  parameter BAUD_RATE = 115200
)
(
  input   wire                        clk,              // system clock signal
  input   wire                        rst,              // reset signal
  output  wire                        tx,               // rs-232 tx signal
  input   wire                        rx,               // rs-232 rx signal
  output  wire                        active,           // dbg block is active (disable CPU)
  output  reg                         ram_wr,           // memory write enable signal
  output  wire  [RAM_ADDR_WIDTH-1:0]  ram_a,            // memory address
  input   wire  [ 7:0]                ram_din,          // memory data bus [input]
  output  wire  [ 7:0]                ram_dout,         // memory data bus [output]
  input   wire  [ 2:0]                io_sel,           // I/O port select
  input   wire                        io_en,            // I/O enable signal
  input   wire  [ 7:0]                io_din,           // I/O data input bus
  output  wire  [ 7:0]                io_dout,          // I/O data output bus
  input   wire                        io_wr,            // I/O write/read select
  output  wire                        io_full,          // I/O buffer full signal 

  output  reg                         program_finish,   // program finish signal

  input   wire  [31:0]                cpu_dbgreg_din    // cpu debug register read bus
);

// Debug packet opcodes.
localparam [7:0] OP_ECHO                 = 8'h00,
                 OP_CPU_REG_RD           = 8'h01,
                 OP_CPU_REG_WR           = 8'h02,
                 OP_DBG_BRK              = 8'h03,
                 OP_DBG_RUN              = 8'h04,
                 OP_IO_IN                = 8'h05,
                 OP_QUERY_DBG_BRK        = 8'h07,
                 OP_QUERY_ERR_CODE       = 8'h08,
                 OP_MEM_RD               = 8'h09,
                 OP_MEM_WR               = 8'h0A,
                 OP_DISABLE              = 8'h0B;

// Error code bit positions.
localparam DBG_UART_PARITY_ERR = 0,
           DBG_UNKNOWN_OPCODE  = 1;

// Symbolic state representations.
localparam [4:0] S_DISABLED             = 5'h00,
                 S_DECODE               = 5'h01,
                 S_ECHO_STG_0           = 5'h02,
                 S_ECHO_STG_1           = 5'h03,
                 S_IO_IN_STG_0          = 5'h04,
                 S_IO_IN_STG_1          = 5'h05,
                 S_CPU_REG_RD_STG0      = 5'h06,
                 S_CPU_REG_RD_STG1      = 5'h07,
                 S_QUERY_ERR_CODE       = 5'h08,
                 S_MEM_RD_STG_0         = 5'h09,
                 S_MEM_RD_STG_1         = 5'h0A,
                 S_MEM_WR_STG_0         = 5'h0B,
                 S_MEM_WR_STG_1         = 5'h0C,
                 S_DISABLE              = 5'h10;

reg [ 4:0]                  q_state,            d_state;
reg [ 2:0]                  q_decode_cnt,       d_decode_cnt;
reg [16:0]                  q_execute_cnt,      d_execute_cnt;
reg [RAM_ADDR_WIDTH-1:0]    q_addr,             d_addr;
reg [ 1:0]                  q_err_code,         d_err_code;

// UART output buffer FFs.
reg  [7:0] q_tx_data, d_tx_data;
reg        q_wr_en,   d_wr_en;

// UART input signals.
reg        rd_en;
wire [7:0] rd_data;
wire       rx_empty;
wire       tx_full;
wire       parity_err;

assign io_full = tx_full;

// I/O
localparam  IO_IN_BUF_WIDTH = 10;
reg         io_in_rd_en;
reg         q_io_in_wr_en, d_io_in_wr_en;
reg  [ 7:0] q_io_in_wr_data, d_io_in_wr_data;
wire [ 7:0] io_in_rd_data;
wire        io_in_empty;
wire        io_in_full;
reg         q_io_en;
reg  [ 7:0] q_io_dout, d_io_dout;

// Input Buffer
fifo #(.DATA_BITS(8),
       .ADDR_BITS(IO_IN_BUF_WIDTH)) io_in_fifo
(
  .clk(clk),
  .reset(rst),
  .rd_en(io_in_rd_en),
  .wr_en(q_io_in_wr_en),
  .wr_data(q_io_in_wr_data),
  .rd_data(io_in_rd_data),
  .empty(io_in_empty),
  .full(io_in_full)
);

// CPU DBG REG
wire[7:0]    cpu_dbgreg_seg[3:0];
assign cpu_dbgreg_seg[3] = cpu_dbgreg_din[31:24];
assign cpu_dbgreg_seg[2] = cpu_dbgreg_din[23:16];
assign cpu_dbgreg_seg[1] = cpu_dbgreg_din[15:8];
assign cpu_dbgreg_seg[0] = cpu_dbgreg_din[7:0];

// CPU Cycle Counter
reg  [31:0] q_cpu_cycle_cnt;
wire [31:0] d_cpu_cycle_cnt;
assign d_cpu_cycle_cnt = active ? q_cpu_cycle_cnt : q_cpu_cycle_cnt + 1'b1;
reg d_program_finish;

// Update FF state.
always @(posedge clk)
  begin
    if (rst)
      begin
        q_state            <= S_DECODE;
        // q_state            <= S_DISABLED;
        q_decode_cnt       <= 0;
        q_execute_cnt      <= 0;
        q_addr             <= 0;
        q_err_code         <= 0;
        q_tx_data          <= 8'h00;
        q_wr_en            <= 1'b0;
        q_io_in_wr_en      <= 1'b0;
        q_io_in_wr_data    <= 8'h00;
        q_io_en            <= 1'b0;
        q_cpu_cycle_cnt    <= 8'h00;
        q_io_dout          <= 8'h00;
      end
    else
      begin
        q_state            <= d_state;
        q_decode_cnt       <= d_decode_cnt;
        q_execute_cnt      <= d_execute_cnt;
        q_addr             <= d_addr;
        q_err_code         <= d_err_code;
        q_tx_data          <= d_tx_data;
        q_wr_en            <= d_wr_en;
        q_io_in_wr_en      <= d_io_in_wr_en;
        q_io_in_wr_data    <= d_io_in_wr_data;
        q_io_en            <= io_en;
        q_cpu_cycle_cnt    <= d_cpu_cycle_cnt;
        q_io_dout          <= d_io_dout;
        program_finish     <= d_program_finish;
      end
  end

// Instantiate the serial controller block.
uart #(.SYS_CLK_FREQ(SYS_CLK_FREQ),
       .BAUD_RATE(BAUD_RATE),
       .DATA_BITS(8),
       .STOP_BITS(1),
       .PARITY_MODE(1)) uart_blk
(
  .clk(clk),
  .reset(rst),
  .rx(rx),
  .tx_data(q_tx_data),
  .rd_en(rd_en),
  .wr_en(q_wr_en),
  .tx(tx),
  .rx_data(rd_data),
  .rx_empty(rx_empty),
  .tx_full(tx_full),
  .parity_err(parity_err)
);

always @*
  begin
    d_io_dout = 8'h00;
    if (io_en & !io_wr)
      begin
        case (io_sel)
          3'h00: d_io_dout = io_in_rd_data;
          3'h04: d_io_dout = q_cpu_cycle_cnt[7:0];
          3'h05: d_io_dout = q_cpu_cycle_cnt[15:8];
          3'h06: d_io_dout = q_cpu_cycle_cnt[23:16];
          3'h07: d_io_dout = q_cpu_cycle_cnt[31:24];
        endcase
      end
  end

always @*
  begin
    // Setup default FF updates.
    d_state        = q_state;
    d_decode_cnt   = q_decode_cnt;
    d_execute_cnt  = q_execute_cnt;
    d_addr         = q_addr;
    d_err_code     = q_err_code;

    rd_en         = 1'b0;
    d_tx_data     = 8'h00;
    d_wr_en       = 1'b0;

    // Setup default output regs.
    ram_wr    = 1'b0;
    io_in_rd_en = 1'b0;
    d_io_in_wr_en = 1'b0;
    d_io_in_wr_data = 8'h00;

    d_program_finish = 1'b0;

    if (parity_err)
      d_err_code[DBG_UART_PARITY_ERR] = 1'b1;

    if (~q_io_en & io_en) begin
      if (io_wr) begin
        case (io_sel)
          3'h00: begin      // 0x30000 write: output byte
            if (!tx_full && io_din!=8'h00) begin
              d_tx_data = io_din;
              d_wr_en   = 1'b1;
            end
            $write("%c", io_din);
          end
          3'h04: begin      // 0x30004 write: indicates program stop
            if (!tx_full) begin
              d_tx_data = 8'h00;
              d_wr_en = 1'b1;
            end
            d_state = S_DECODE; 
            d_program_finish = 1'b1;
            $display("IO:Return");
            $finish;
          end
        endcase
      end else begin
        case (io_sel)
          3'h00: begin      // 0x30000 read: read byte from input buffer
            if (!io_in_empty) begin
              io_in_rd_en = 1'b1;
            end
            // $display("IO:in:%c",io_dout);
            if (!rx_empty && !io_in_full) begin
              rd_en   = 1'b1;
              d_io_in_wr_data = rd_data;
              d_io_in_wr_en = 1'b1;
            end
          end
        endcase
      end
    end else begin
    case (q_state)
      S_DISABLED:
        begin
          if (!rx_empty)
            begin
              rd_en = 1'b1;  // pop opcode off uart fifo

              if (rd_data == OP_DBG_BRK)
                begin
                  d_state = S_DECODE;
                end
              else if (rd_data == OP_QUERY_DBG_BRK)
                begin
                  d_tx_data = 8'h00;  // Write "0" over UART to indicate we are not in a debug break
                  d_wr_en   = 1'b1;
                end
            end
        end
      S_DECODE:
        begin
          if (!rx_empty)
            begin
              rd_en        = 1'b1;  // pop opcode off uart fifo
              d_decode_cnt = 0;     // start decode count at 0 for decode stage

              // Move to appropriate decode stage based on opcode.
              case (rd_data)
                OP_ECHO:                 d_state = S_ECHO_STG_0;
                OP_IO_IN:                d_state = S_IO_IN_STG_0;
                OP_DBG_BRK:              d_state = S_DECODE;
                OP_QUERY_ERR_CODE:       d_state = S_QUERY_ERR_CODE;
                OP_MEM_RD:               d_state = S_MEM_RD_STG_0;
                OP_MEM_WR:               d_state = S_MEM_WR_STG_0;
                OP_CPU_REG_RD:           d_state = S_CPU_REG_RD_STG0;
                OP_DISABLE:              d_state = S_DISABLE;
                OP_DBG_RUN:
                  begin
                    d_state = S_DISABLED;
                  end
                OP_QUERY_DBG_BRK:
                  begin
                    d_tx_data = 8'h01;  // Write "1" over UART to indicate we are in a debug break
                    d_wr_en   = 1'b1;
                  end
                default:
                  begin
                    // Invalid opcode.  Ignore, but set error code.
                    d_err_code[DBG_UNKNOWN_OPCODE] = 1'b1;
                    d_state = S_DECODE;
                  end
              endcase
            end
        end

      // --- ECHO ---
      //   OP_CODE
      //   CNT_LO
      //   CNT_HI
      //   DATA
      S_ECHO_STG_0:
        begin
          if (!rx_empty)
            begin
              rd_en        = 1'b1;                 // pop packet byte off uart fifo
              d_decode_cnt = q_decode_cnt + 3'h1;  // advance to next decode stage
              if (q_decode_cnt == 0)
                begin
                  // Read CNT_LO into low bits of execute count.
                  d_execute_cnt = rd_data;
                end
              else
                begin
                  // Read CNT_HI into high bits of execute count.
                  d_execute_cnt = { rd_data, q_execute_cnt[7:0] };
                  d_state = (d_execute_cnt) ? S_ECHO_STG_1 : S_DECODE;
                end
            end
        end
      S_ECHO_STG_1:
        begin
          if (!rx_empty)
            begin
              rd_en         = 1'b1;                       // pop packet byte off uart fifo
              d_execute_cnt = q_execute_cnt - 17'h00001;  // advance to next execute stage

              // Echo packet DATA byte over uart.
              d_tx_data = rd_data;
              d_wr_en   = 1'b1;

              // After last byte of packet, return to decode stage.
              if (d_execute_cnt == 0)
                d_state = S_DECODE;
            end
        end

      S_IO_IN_STG_0:
        begin
          if (!rx_empty)
            begin
              rd_en        = 1'b1;                 // pop packet byte off uart fifo
              d_decode_cnt = q_decode_cnt + 3'h1;  // advance to next decode stage
              if (q_decode_cnt == 0)
                begin
                  // Read CNT_LO into low bits of execute count.
                  d_execute_cnt = rd_data;
                end
              else
                begin
                  // Read CNT_HI into high bits of execute count.
                  d_execute_cnt = { rd_data, q_execute_cnt[7:0] };
                  d_state = (d_execute_cnt) ? S_IO_IN_STG_1 : S_DECODE;
                end
            end
        end
      S_IO_IN_STG_1:
        begin
          if (!rx_empty)
            begin
              rd_en         = 1'b1;                       // pop packet byte off uart fifo
              d_execute_cnt = q_execute_cnt - 17'h00001;  // advance to next execute stage

              if (!io_in_full) begin
                d_io_in_wr_data = rd_data;
                d_io_in_wr_en = 1'b1;
              end

              if (d_execute_cnt == 0)
                d_state = S_DECODE;
            end
        end

      // --- QUERY_ERR_CODE ---
      //   OP_CODE
      S_QUERY_ERR_CODE:
        begin
          if (!tx_full)
            begin
              d_tx_data = q_err_code; // write current error code
              d_wr_en   = 1'b1;       // request uart write
              d_state   = S_DECODE;
            end
        end

      // --- CPU_REG_RD ---
      //   (demo)
      S_CPU_REG_RD_STG0:
        begin
          if (!tx_full)
            begin
              d_execute_cnt  = 3'h04;
              d_addr = 17'h00000;
              d_state = S_CPU_REG_RD_STG1;
            end
        end
      S_CPU_REG_RD_STG1:
        begin
          if (!tx_full)
            begin
              d_execute_cnt = q_execute_cnt - 1'b1;  // advance to next execute stage
              d_tx_data     = cpu_dbgreg_seg[q_addr];
              d_wr_en       = 1'b1;                       // request uart write
              d_addr        = q_addr + 17'h00001;

              // After last byte is written to uart, return to decode stage.
              if (d_execute_cnt == 0)
                d_state = S_DECODE;
            end
        end

      // --- MEM_RD ---
      //   OP_CODE
      //   ADDR_LO
      //   ADDR_HI
      //   BANK_SEL (ADDR_TOP)
      //   CNT_LO
      //   CNT_HI
      S_MEM_RD_STG_0:
        begin
          if (!rx_empty)
            begin
              rd_en        = 1'b1;                 // pop packet byte off uart fifo
              d_decode_cnt = q_decode_cnt + 3'h1;  // advance to next decode stage
              if (q_decode_cnt == 0)
                begin
                  // Read ADDR_LO into low bits of addr.
                  d_addr = rd_data;
                end
              else if (q_decode_cnt == 1)
                begin
                  // Read ADDR_HI into high bits of addr.
                  d_addr = { {(RAM_ADDR_WIDTH-16){1'b0}}, rd_data, q_addr[7:0] };
                end
              else if (q_decode_cnt == 2)
                begin
                  d_addr = { rd_data[RAM_ADDR_WIDTH-16-1:0], q_addr[15:0] };
                end
              else if (q_decode_cnt == 3)
                begin
                  // Read CNT_LO into low bits of execute count.
                  d_execute_cnt = rd_data;
                end
              else
                begin
                  // Read CNT_HI into high bits of execute count.  Execute count is shifted by 1:
                  // use 2 clock cycles per byte read.
                  d_execute_cnt = { rd_data, q_execute_cnt[7:0], 1'b0 };
                  d_state = (d_execute_cnt) ? S_MEM_RD_STG_1 : S_DECODE;
                end
            end
        end
      S_MEM_RD_STG_1:
        begin
          if (~q_execute_cnt[0])
            begin
              // Dummy cycle.  Allow memory read 1 cycle to return result, and allow uart tx fifo
              // 1 cycle to update tx_full setting.
              d_execute_cnt = q_execute_cnt - 17'h00001;
            end
          else
            begin
              if (!tx_full)
                begin
                  d_execute_cnt = q_execute_cnt - 17'h00001;  // advance to next execute stage
                  d_tx_data     = ram_din;               // write data from D bus
                  d_wr_en       = 1'b1;                       // request uart write

                  d_addr = q_addr + 17'h00001;                 // advance to next byte

                  // After last byte is written to uart, return to decode stage.
                  if (d_execute_cnt == 0)
                    d_state = S_DECODE;
                end
            end
        end

      // --- MEM_WR ---
      //   OP_CODE
      //   ADDR_LO
      //   ADDR_HI
      //   BANK_SEL (ADDR_TOP)
      //   CNT_LO
      //   CNT_HI
      //   DATA
      S_MEM_WR_STG_0:
        begin
          if (!rx_empty)
            begin
              rd_en        = 1'b1;                 // pop packet byte off uart fifo
              d_decode_cnt = q_decode_cnt + 3'h1;  // advance to next decode stage
              if (q_decode_cnt == 0)
                begin
                  // Read ADDR_LO into low bits of addr.
                  d_addr = rd_data;
                end
              else if (q_decode_cnt == 1)
                begin
                  // Read ADDR_HI into high bits of addr.
                  d_addr = { {(RAM_ADDR_WIDTH-16){1'b0}}, rd_data, q_addr[7:0] };
                end
              else if (q_decode_cnt == 2)
                begin
                  d_addr = { rd_data[RAM_ADDR_WIDTH-16-1:0], q_addr[15:0] };
                end
              else if (q_decode_cnt == 3)
                begin
                  // Read CNT_LO into low bits of execute count.
                  d_execute_cnt = rd_data;
                end
              else
                begin
                  // Read CNT_HI into high bits of execute count.
                  d_execute_cnt = { rd_data, q_execute_cnt[7:0] };
                  d_state = (d_execute_cnt) ? S_MEM_WR_STG_1 : S_DECODE;
                end
            end
        end
      S_MEM_WR_STG_1:
        begin
          if (!rx_empty)
            begin
              rd_en         = 1'b1;                       // pop packet byte off uart fifo
              d_execute_cnt = q_execute_cnt - 17'h00001;  // advance to next execute stage
              d_addr        = q_addr + 17'h00001;          // advance to next byte

              ram_wr   = 1'b1;

              // After last byte is written to memory, return to decode stage.
              if (d_execute_cnt == 0)
                d_state = S_DECODE;
            end
        end

    endcase
    end
    
  end

assign active      = (q_state != S_DISABLED);
assign ram_a       = q_addr;
assign ram_dout    = rd_data;
assign io_dout     = q_io_dout;

endmodule