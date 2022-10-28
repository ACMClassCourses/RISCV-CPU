#include <cstdio>
#include <fstream>
#include <serial/serial.h>
#include <vector>
#include <ctime>
#include <cstring>

int run_mode;

#define error(msg...) printf(msg)
#define info(msg...) do{if(run_mode) printf(msg);}while(0)

typedef std::uint8_t byte;
typedef std::uint16_t word;
typedef std::uint32_t dword;

serial::Serial serPort;

void uart_send(const byte *data, int send_count, byte* recv, int return_count) {
    serPort.write(data,send_count);
    if (!return_count) return;
    try {
        serPort.read(recv,return_count);
    } catch (std::exception &e) {
        error("recv error: %s\n",e.what());
    }
}
void uart_send(const std::vector<byte> data, byte* recv, int return_count) {
    uart_send(data.data(),data.size(),recv,return_count);
}
void uart_send(const std::string &data) { serPort.write(data); }
void uart_send(const byte *data, int size) { serPort.write(data,size); }
void uart_send(const std::vector<byte> &data) { serPort.write(data); }
void uart_read(byte *data, int size) { serPort.read(data, size); }

#include "listener.h"

int init_port(char* port) {
    serPort.setPort(port);
    serPort.setBaudrate(baud_rate);
    serPort.setBytesize(byte_size);
    serPort.setParity(parity);
    serPort.setStopbits(stopbits);
    serPort.setTimeout(
        inter_byte_timeout,
        read_timeout_constant,
        read_timeout_multiplier,
        write_timeout_constant,
        write_timeout_multiplier
        );
    try {
        serPort.open();
    } catch (std::exception &e) {
        error("failed to open port: %s\n",e.what());
        return 1;
    }
    info("initialized UART port on: %s\n",port);
    return 0;
}

byte ram_data[0x40000];
byte in_data[0x400];

int load_ram(char* rom_path) {
    std::ifstream fin(rom_path);
    if (!fin.is_open()) return 0;
    fin.seekg(0, std::ios_base::end);
    int ram_size = fin.tellg();
    info("RAM size: %x\n", ram_size);
    fin.seekg(0, std::ios_base::beg);
    fin.read(reinterpret_cast<char*>(ram_data), ram_size);
    for (int i=0;i<0x40; ++i) {
        info("%02x ", (byte)ram_data[i+0x1000]);
        if (!((i+1)%16)) info("\n");
    }
    fin.close();
    return ram_size;
}

int load_input(char* in_path) {
    if (!in_path) return 0;
    std::ifstream fin(in_path);
    if (!fin.is_open()) return 0;
    fin.seekg(0, std::ios_base::end);
    int in_size = fin.tellg();
    info("INPUT size: %x\n", in_size);
    fin.seekg(0, std::ios_base::beg);
    fin.read(reinterpret_cast<char*>(in_data), in_size);
    for (int i=0;i<0x10; ++i) {
        info("%02x ", (byte)in_data[i]);
        if (!((i+1)%16)) info("\n");
    }
    fin.close();
    return in_size;
}

clock_t start_tm;
clock_t end_tm;

void run() {
    // demo

    // debug packet format: see hci.v or README.md
    // send[0] is always OPCODE
    // to send debug packets, use uart_send(send,send_count)
    // to receive data after send, use uart_send(send,send_count,recv,recv_count)
    char c;
    int run = 0;
    while (1){
        info("Enter r to run, q to quit, p to get cpu PC(demo)\n");
        c=getchar();
        if (c=='q') {
            break;
        }
        else if (c=='p') {
            // demo for debugging cpu
            // add support in hci.v to allow more debug operations
            byte send[6]={0};
            byte recv[64]={0};
            send[0]=0x01;
            uart_send(send,1,recv,4);
            int pc = *reinterpret_cast<int*>(recv);
            info("pc:%08x\n",pc);
            send[0] = 0x09;
            int get_size = 16;
            *reinterpret_cast<dword*>(send+1)=pc;
            *reinterpret_cast<word*>(send+4)=get_size;
            uart_send(send,6,recv,get_size);
            for (int i=0;i<16;++i) {
                info("%02x ",recv[i]);
            }
            info("\n");
        }
        else if (c=='r') {
            // run or pause cpu
            byte send[2];
            send[0]=(run?0x03:0x04);
            run = !run;
            info("CPU start\n");
            uart_send(send,1);
            start_tm = clock();
            // receive output bytes from fpga
            while (1) {
                byte data;
                // to debug cpu at the same time, implement separate thread
                while (!serPort.available());
                uart_read(&data,1);
                if (on_recv(data)) break;
            }
            end_tm = clock();
            info("\nCPU returned with running time: %f\n",(double)(end_tm - start_tm) / CLOCKS_PER_SEC);

            // manually pressing reset button is recommended

            // or pause and reset cpu through uart (TODO)
            // send[0]=(run?0x03:0x04);
            // run = !run;
            // uart_send(send,1);

            return;
        }
    }
}

void run_auto() {
    byte send[2];
    send[0]=(0x04);
    uart_send(send,1);
    start_tm = clock();
    while (1) {
        byte data;
        while (!serPort.available());
        uart_read(&data,1);
        if (data==0) break;
        putchar(data);
    }
    end_tm = clock();
}

int main(int argc, char** argv) {
    if (argc<4) {
        error("usage: path-to-ram [path-to-input] com-port -I(interactive)/-T(testing)\n");
        return 1;
    }
    char* ram_path = argv[1];
    int no_input = argc<5;
    char* input_path = no_input ? NULL : argv[2];
    char* comport = argv[argc-2];
    char param = argv[argc-1][1];
    if (param=='I') {
        run_mode = 1;
    } else if (param=='T') {
        run_mode = 0;
    }
    int ram_size = 0, in_size = 0;
    if (!(ram_size=load_ram(ram_path))) {
        error("failed to read ram file\n");
        return 1;
    }
    if (!no_input && !(in_size=load_input(input_path))){
        info("input file not found, skipping\n");
    }
    if (init_port(comport)) return 1;
    if (on_init()) return 1;
    upload_ram(ram_data, ram_size);
    upload_input(in_data, in_size);
    // verify_ram(ram_data, ram_size);
    if (run_mode) run();
    else run_auto();
    serPort.close();
}
