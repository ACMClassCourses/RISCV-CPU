# Yet Another (useless) Debug Method

1. Use the `risc_top.v`, `Basys-3-Master.xdc`, `testbench.v`, `display_ctrl.v` in the folder.
2. Bind the wanted output to the `dbgreg_dout` of the `cpu` module.
3. Turn on `SW1` to turn on the display.
4. Turn on `SW0` to turn on manual control of `rdy`.
5. With `SW0` on, press `btnU` to step forward to the next `clk` period.
6. Set `DBG` in `testbench.v` to use in simulation.

It's just what I did last year and may shed a light on what `Basys-3-Master.xdc` is used for. You may try modifying the control logic to realize breakpoints and more functions.