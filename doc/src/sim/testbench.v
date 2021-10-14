// testbench top module file
// for simulation only

//`timescale 1ns/1ps
module testbench;

localparam DBG = 1'b0;

reg clk;
reg rst;
reg manual_clk;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .btnU(manual_clk),
    .sw(DBG),
    .Tx(),
    .Rx(),
    .led(),
    .seg(),
    .dp(),
    .an()
);

initial begin
  clk=0;
  manual_clk=0;
  rst=1;
  repeat(50) #1 clk=!clk;
  rst=0; 
  forever begin
    #1 clk=!clk;
    #1 clk=!clk;
    #1 clk=!clk;
    #1 clk=!clk;
    #1 clk=!clk;
    #1 clk=!clk;
    manual_clk=!manual_clk;
  end

  $finish;
end

endmodule