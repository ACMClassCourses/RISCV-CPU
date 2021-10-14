In this note, we proffer some naïve methods to debug.  

##### Use testcases

The first is to compile a testcase and use the compiled `test.data` to debug. Here are some typical testcases: 

1. gcd. This is very easy and short. 
2. expr, a bit larger. 
3. heart, pi. Only simulating some steps is enough. 
4. Bulgarian, especially for FPGA test. 

##### Hand-writing test.data

Write your own  `test.data`. It is nothing but a sequence of RISCV instructions. For example, if the file is: 

```
@00000000
83 20 00 00
```

Since the instruction is `8h'00002083=32b'000000000000 00000 010 00001 0000011`, which means `ld r1, r0(0)`, it loads a word from address `0x00000000` to register 1, after executing this file, the value in register 1 should be 0x2083. 

##### Testbench

Writing a testbench can be a good idea when you want to test a single module. What you need is a testbench like `/riscv/sim/testbench`. Here we provide a testbench file of the Verilog practice homework `diff8r`: 

```
module test_bench;
    reg clk = 0;
	always #5 clk = ~clk; // Create clock with period=10
    reg [7:0] d;
    wire [7:0] q, ans;
    
	integer i = 0;
    reg wrong = 0, wrong2 = 0, rst = 1;
	
    top_module ff0( .clk(clk), .reset(rst), .d(d), .q(q));
	std ff1( .clk(clk), .reset(rst), .d(d), .q(ans));
	
    initial begin
        #10;
		if (d != q) wrong = 1;
        rst = 0;
		#200;
        if (wrong | wrong2) begin
            $display("Wrong Answer");
        end else begin
            $display("Accepted");
        end
        $finish;
	end
	always @(posedge clk) begin
		if (rst) begin
			d <= 0;
		end else begin
			$display("%d", d);
			d <= d - 1;
		end
	end
	
	always @(*) begin
		if (rst) begin
			wrong2 = 0;
		end else begin
			wrong2 |= q != ans;
		end
	end
endmodule
```

You can read `/riscv/sim/testbench.v` for more. In all, a testbench has: 

1. connection with tested module. In this file, it is the `top_module`. 
2. simulated clock. In this file, it is `always #5 clk=~clk;`. In `/riscv/sim/testbench.v` it is the `forever(10) #1 clk=!clk;`
3. `$finish` in correct time. 
4. A sophisticated designed input, which can be more flexible than a `test.data`. 
5. Optional, `$display` as a hint. 