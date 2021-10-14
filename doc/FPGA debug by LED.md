This is a tutorial about how to debug your design on FPGA using LED: 

First see `/riscv/src/Basys-3-Master.xdc`. You can find lines as: 

```
#set_property PACKAGE_PIN E19 [get_ports {led[1]}]
	#set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
```

The meaning of the two line is to associate `led[1]`(as a wire) with LED no.1(which is named as `E19`) on FPGA. Uncomment the two lines to put them to use. 

Feel free to modify the name of the wire, you do not need to keep the name `led[1]`. 

The second step is to add the wire in your output of your top module. As an example, if I use: 

```
set_property PACKAGE_PIN E19 [get_ports {cpu_led_dbg}]
	set_property IOSTANDARD LVCMOS33 [get_ports {cpu_led_dbg}]
```

Then I need to modify the `riscv_top.v` as: 

```verilog
module riscv_top
#(
	parameter SIM = 0
)
(
	input wire 			EXCLK,
	input wire			btnC,
	output wire 		Tx,
	input wire 			Rx,
	output wire			led, 
    output wire			cpu_led_dbg	// I add this line
);
```

Now as soon as `cpu_led_dbg=1` , the LED is turned on. Otherwise it is off. 

Mention that, you are not advised to associate a bit of an address with an LED, since this may result in a flicker: the address is modified every cycle(10ns), you need very good eyesight to catch the light. 

Connecting to other ports has nothing different. You can refer to Basys3 manual to get the id of each port. 