# <img src="README.assets/cpu.png" width="40" align=center /> RISCV-CPU 2022

## 引言

![wechat_screenshot](README.assets/wechat_screenshot.jpg)

## 项目说明

在本项目中，你需要使用 Verilog 语言完成一个简单的 RISC-V CPU 电路设计。Verilog 代码会以软件仿真和 FPGA 板两种方式运行。你设计的电路将运行若干测试程序并可能有输入数据，执行得到的输出数据将与期望结果比较，从而判定你的 Verilog 代码的正确性。你需要实现 CPU 的运算器与控制器，而内存等部件题面已提供代码。具体而言，你可以从 [`riscv/src/cpu.v`](https://github.com/ACMClassCourses/RISCV-CPU/blob/main/riscv/src/cpu.v) 文件开始阅读题面代码，题面项目结构详见[附录 B](#附录-B)。



### 项目阶段

- 完成 Speculative CPU 所支持的所有模块

- 在本地 Simulation 通过可执行的测试

  >  在本地 Simulation 时，部分样例运行时间可能会非常非常长，如 `heart.c` 与 `pi.c`。这些样例不会被算入 Simulation 的测试范围，但会在 FPGA 检查阶段纳入测试范围。

- 在 FPGA 上通过所有测试



### 时间安排

每 2 周一次检查，检查时间为每周日 22:00 后，下表为检查形式与标准：

| 时间        | 检查内容                                              |
| ----------- | ----------------------------------------------------- |
| **Week 6**  | 仓库创建                                              |
| **Week 8**  | 完成电路设计草稿 / 各个 CPU 模块文件创建              |
| **Week 10** | 完成 Instruction Fetch 部分代码，尝试仿真运行         |
| **Week 12** | 各个 CPU 模块文件基本完成，完成 `cpu.v` 连线          |
| **Week 14** | Simulation 通过 `gcd`                                 |
| **Week 16** | Simulation 通过除 `tak`，`heart`，`pi` 之外的所有样例 |
| **Week 18** | FPGA 通过所有样例                                     |


### 最终提交

你需要向助教单独提交由 Vivado Synthesis 生成出的 `.bit` 文件，截止时间为第 18 周前（2023.1.8 23:59）。



## 实现说明

### 概述

1. 根据 `cpu.v` 提供的接口自顶向下完成代码，其余题面代码尽量不要改动
2. 设计并实现**支持乱序执行**的 Tomasulo 架构 CPU
3. 使用 iVerilog 进行本地仿真测试（结果为 `.vcd` 文件）
4. 依照助教安排，将 Verilog 代码烧录至 FPGA 板上进行所有测试数据的测试

### 指令集

> 可参考资料见 [RISC-V 指令集](#RISC-V-指令集)

本项目使用 **RV32I 指令集**

基础测试内容不包括 Doubleword 和 Word 相关指令、Environment 相关指令和 CSR 相关等指令。

必须要实现的指令为以下 37 个：`LUI`, `AUIPC`, `JAL`, `JALR`, `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW`, `ADDI`, `SLLI`, `SLTI`, `SLTIU`, `XORI`, `SRLI`, `SRAI`, `ORI`, `ANDI`, `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`

## 帮助

> **这可能对你来说非常重要。**

### 文档

- Vivado 不支持 MacOS 系统，故如果使用 Mac 则必须使用虚拟机，推荐 Ubuntu Desktop。此外对于使用 Windows 电脑的同学，RISC-V Toolchain 也推荐在 Linux 系统上安装。
- 更多题面补充文档参见 [本仓库 `doc` 分支](https://github.com/ACMClassCourses/RISCV-CPU/tree/doc)
- 题面附录与 README 以外内容包含上文未提及信息，可能有助于你完成项目，请记得阅读



### Q & A

1. **我的CPU会从哪里读取指令并执行？**

   从 `0x0000000` 地址处开始执行。

2. **我的CPU执行如何终止？**

   见 `cpu.v` 中 `Specification` 部分。

3. **我的寄存器堆（Register File）需要多少个寄存器？**

   Unprivileged CPU: 32

   Privileged CPU: 32 + 8 (CSR)

4. **To be continued...**



----

> 以下为附录内容。

## 附录 A

### RISC-V 指令集

- 官网 https://riscv.org/
- [官方文档下载页面](https://riscv.org/technical/specifications/)
  - 基础内容见 Volume 1, Unprivileged Spec
  - 特权指令集见 Volume 2, Privileged Spec
- 非官方 [Read the Docs 文档](https://msyksphinz-self.github.io/riscv-isadoc/html/index.html)

- 非官方 Green Card，[PDF 下载链接](https://inst.eecs.berkeley.edu/~cs61c/fa17/img/riscvcard.pdf)

### RISC-V C and C++ Cross-compiler

- https://github.com/riscv-collab/riscv-gnu-toolchain Release 中编译结果，将其下载并解压至自选安装路径
- 配置环境变量：在 `~/.bashrc` 末添加 `export PATH=$PATH:$HOME/toolchain/riscv/bin` (路径按照实际解压位置为准)
- 将 C / C++ 源文件编译至 RISC-V 的 `.o` 文件请参考 [riscv/build_test.sh](https://github.com/ACMClassCourses/RISCV-CPU/blob/main/riscv/build_test.sh)
- 其他可能需要安装的包
  - `sudo apt install gcc-multilib`
  - `sudo apt install llvm`

### Vivado

- 你需要该软件将 Verilog 代码编译为可以烧录至 FPGA 板的二进制文件
- Vivado 安装后软件整体大小达 30G 左右，请准备足够硬盘空间

## 附录 B

> 附录 B 为 2021 年旧题面

### Repo Structure

```
|--riscv/
|  |--ctrl/             Interface with FPGA
|  |--sim/              Testbench, add to Vivado project only in simulation
|  |--src/              Where your code should be
|  |  |--common/                Provided UART and RAM
|  |  |--Basys-3-Master.xdc     constraint file
|  |  |--cpu.v                  Fill it. 
|  |  |--hci.v                  A bus between UART/RAM and CPU
|  |  |--ram.v                  RAM
|  |  |--riscv_top.v            Top design
|  |--sys/              Help compile
|  |--testcase/         Testcases
|  |--autorun_fpga.sh   Autorun Testcase on FPGA
|  |--build_test.sh     Run it to build test.data from test.c
|  |--FPGA_test.py      Test correctness on FPGA
|  |--pd.tcl            Program device the bitstream onto FPGA
|  |--run_test.sh       Run test
|  |--run_test_fpga.sh  Run test on FPGA
|--serial/              A third-party library for interfacing with FPGA ports
```

### Requirement

#### Basic Requirement

- Use Verilog to implement a CPU supporting part of RV32I Instruction set(2.1-2.6 in [RISC-V user manual](https://riscv.org//wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)), with the provided code in this repository. 

#### Grading Policy

- A design meeting part of a requirement can get part of its corresponding points. 
- The course project assignment is not mature yet. Please give practical suggestions or bug fixes for next year's project if you feel somewhere uncomfortable with current project. You should prepare a short note or presentation for your findings. You will get extra 2% for this. If you implement your suggestion and it's meaningful in both educational purpose and project perfection purpose, the extra credit will be raised up -- up to 10%. It will be a complement for your bonus part, or extra 1 point in the final grading if you get full mark in the project.

### Details

#### RISCV-Toolchain

For prerequisites, go to see https://github.com/riscv/riscv-gnu-toolchain to install necessary packages.
The configure is: 

```
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
sudo make
```
**DO NOT** use `sudo make linux` which you may use in PPCA. If you have made it, just rerun `sudo make` without any deletion and everything will be ok.
(BTW, you may use arch rv32gc for your compiler project, so keep the installation package)

The following are some common problems you may meet when make

###### `make failed`

Please first check whether you use `sudo` before `make` due to default permission setting of linux.

###### `checking for sysdeps preconfigure fragments... aarch64 alpha arm csky hppa i386 m68k microblaze mips nios2 powerpc riscv glibc requires the A extension`

Use configuration `./configure --prefix=/opt/riscv --with-arch=rv32ia --with-abi=ilp32`

###### `xxx-ld: cannot find -lgcc`

Go to see https://github.com/riscv/riscv-gnu-toolchain/issues/522.

#### Custom

In this project, the size of memory(ram) is 128K, so only address lower than 0x20000 is available. However, reading and writing from 0x30000 and 0x30004 have special meaning, you can see `riscv/src/cpu.v` for more details. 

#### Simulation using iverilog

```
cd ./riscv/src
iverilog *.v common/*/*.v
vvp a.out
```

#### Serial

Serial( [wjwwood/serial](https://github.com/wjwwood/serial)) is a cross-platform serial port library to help your design working on FPGA when receiving from UART. Build it by: 

```bash
git submodule init
git submodule update
cd serial
make
make install
```

#### Build test

Use the following command to build a test, it will be a `test.data` file in folder `/riscv/test/`: 

```bash
cd riscv
./build_test.sh testname
```

You can see all tests in `/riscv/testcase/` folder. 

#### FPGA

We'll provide you with Basys3 FPGA board. Use Vivado to generate bitstream and program the FPGA device. Then:

In directory 'ctrl', build the controller by

```
./build.sh
```

Modify and run the script

```
./run_test_fpga.sh testname
```

One thing need to be modified is the USB port number of the script. For example in Windows you could find it in Devices and Printers -> Digilent USB Device -> Hardware. The number X that presented in the last line of Device Functions 'USB Serial Port (COMX)' is the port you need. The port format should be like:

```
on Linux: /dev/ttyUSBX
on WSL: /dev/ttySX
on Windows: COMX
```

Your Vivado may be unable to discover your FPGA, this may be caused by the lack of corresponding driver, install it by(use your own version to replace `2018.2`): 

```bash
cd $PATH_TO_VIVADO/2018.2/data/xicom/cable_drivers/lin64
sudo cp -i -r install_script /opt
cd /opt/install_script/install_drivers
sudo ./install_drivers
```

Then restart Vivado. 

To run your bitstream on FPGA, you can run: 

```bash
cd riscv
python FPGA_test.py
```

You need to modify the `path_of_bit` in `FPGA_test.py` first. 

### Update Note

For some strong students that start project early based on last year's assignment, here are some changes we've made this year:

1. Fixed a bug in  `riscv_top.v`  that may cause you get wrong return value when two consecutive readings are from different data sources.

2. A new `input wire io_buffer_full`  that will show the UART output buffer is full and you should stall -- otherwise some output will be missing when output requests are intensive. You can ignore the problem in the beginning stage.

   Note: you will receive `io_buffer_full` in the SECOND NEXT CYCLE from your write cycle since the FIFO module's limitation. To ensure FIFO is not full you have to stall one cycle when there are two consecutive writes to 0x30000 in two consecutive clock, especially when i-cache is on. This problem will be detected in the testcase `uartboom`. 

   You're welcome to fix this problem by modifying preset code. Elegant implementation will be counted as bonus.

### Q&A

1. `rdy_in` and `rst_in`

   The `rst_in` has higher priority with `rdy_in`, and you CANNOT DO ANYTING when `rdy_in` is zero. `rdy_in` does not affect the result of simulation, but has effect when running on FPGA. 

2. Write twice in simulation

   This is often OK in simulation, because it uses `$write()` in a combinational circuit to simulate a write(you can find it in `hci.v`), and by the property of combinational circuit, this instruction may be executed twice. 

   In FPGA if everything you write is correct this will not happen. 

3. connect with FPGA

   Use the micro USB port on the FPGA, since we use RS232 to transmit data. 

You may meet various problems, especially when start testing on FPGA. Feel free to contact any TA for help.

### Known issues (2021.2.3)

1. Some will fail to run the second time on FPGA. One quick solution is to let `rst = rst_in | ~rdy_in`, however it's somehow incorrect. We hope the future TAs to investigate the phenomenon and give a correct solution.

2. There's not a quick simulation check test case. One possible way is to mix up some test cases that can check those CPUs failed to run on FPGA using tolerable time while not to be much easier than passing all test cases. We didn't write one yet. Also, it may be hard to design, since some failures occur with only a few strange and specific conditions.

3. Our updated version of `hcl` and `top` are not good enough, since it requires combinational circuits not to consider `rst` --- or timing loop will occur since `rst` is connected to `program_finish` driven by combinational circuits. Better design may be required.
