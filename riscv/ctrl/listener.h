#include <iostream>
#include <cstdio>
#include <string>
#include <vector>
#include <thread>
#include <chrono>

// UART port configuration, adjust according to implementation
int baud_rate = 115200;
serial::bytesize_t byte_size = serial::eightbits;
serial::parity_t parity = serial::parity_odd;
serial::stopbits_t stopbits = serial::stopbits_one;
int inter_byte_timeout = 50;
int read_timeout_constant = 50;
int read_timeout_multiplier = 10;
int write_timeout_constant = 50;
int write_timeout_multiplier = 10;

//methods
int on_init() {
    using namespace std::chrono_literals;
    byte junk[10];
    uart_read(junk,8);
    std::this_thread::sleep_for(std::chrono::seconds(1));
    byte init[10];
    byte recv[10]={0};
    init[0] = 0x00;
    int len = 4;
    *reinterpret_cast<word*>(init+1) = len;
    char test[10] = "UART";
    for (int i=0;i<len;++i) {
        init[3+i]=(byte)test[i];
        info("%02x ",init[3+i]);
    }
    info("\n");
    uart_send(init,3+len,recv,len);
    for (int i=0;i<len;++i) {
        info("%02x ",recv[i]);
    }
    info("\n");
    char *str = reinterpret_cast<char*>(recv);
    if (strcmp(str,test)) {
        error("UART assertion failed\n");
        return 1;
    }
    return 0;
}

void upload_ram(byte* ram_data, int ram_size) {
    if (!ram_size) return;
    const int short blk_size = 0x400;
    const int pld_size = 1+3+2+blk_size;
    byte payload[pld_size];
    int blk_cnt = (ram_size / blk_size);
    if (blk_cnt*blk_size<ram_size) ++blk_cnt;
    info("uploading RAM: %x blks:%d\n", ram_size, blk_cnt);
    for (int i=0; i<blk_cnt; ++i) {
        unsigned int offset = i * blk_size;
        unsigned int addr = offset;
        info("blk:%i ofs:%04x\n",i,offset);
        payload[0] = 0x0A;
        *reinterpret_cast<dword*>(payload+1) = addr;
        *reinterpret_cast<word*>(payload+4) = blk_size;
        for (int j=0;j<blk_size;++j) {
            payload[6+j] = (byte)ram_data[offset+j];
        }
        uart_send(payload,pld_size);
    }
    info("RAM uploaded\n");
    std::this_thread::sleep_for(std::chrono::seconds(1));
}

void upload_input(byte* in_data, int in_size) {
    if (!in_size) return;
    const int short blk_size = 0x40;
    byte payload[3+blk_size]={0};
    int blk_cnt = (in_size / blk_size);
    if (blk_cnt*blk_size<in_size) ++blk_cnt;
    info("uploading INPUT: %x blks:%d\n", in_size, blk_cnt);
    int pre_size = 2;
    payload[0] = 0x05;
    payload[3] = 0x20;
    payload[4] = 0x20;
    *reinterpret_cast<word*>(payload+1) = pre_size;
    uart_send(payload,1+2+pre_size);
    int rem_size = in_size;
    for (int i=0; i<blk_cnt; ++i) {
        unsigned int offset = i * blk_size;
        info("blk:%i ofs:%04x\n",i,offset);
        payload[0] = 0x05;
        int dat_size = (rem_size<blk_size) ? rem_size : blk_size;
        *reinterpret_cast<word*>(payload+1) = dat_size;
        for (int j=0;j<dat_size;++j) {
            payload[3+j] = (byte)in_data[offset+j];
        }
        uart_send(payload,1+2+dat_size);
        rem_size -= dat_size;
    }
    info("INPUT uploaded\n");
    std::this_thread::sleep_for(std::chrono::seconds(1));
}

void verify_ram(byte* ram_data, int ram_size) {
    const int short blk_size = 0x400;
    const int pld_size = 1+3+2;
    byte payload[pld_size];
    byte recv_data[blk_size];
    int blk_cnt = ram_size/blk_size;
    if (blk_cnt*blk_size<ram_size) ++blk_cnt;
    info("verifying RAM: %x blks:%d\n", ram_size, blk_cnt);
    for (int i=0; i<blk_cnt; ++i) {
        unsigned int offset = i * blk_size;
        unsigned int addr = offset;
        info("blk:%i ofs:%04x\n",i,offset);
        payload[0] = 0x09;
        *reinterpret_cast<dword*>(payload+1) = addr;
        *reinterpret_cast<word*>(payload+4) = blk_size;
        uart_send(payload,6,recv_data,blk_size);
        for (int j=0; j<blk_size; ++j) {
            if (ram_data[offset+j]!=recv_data[j]) {
                error("RAM error: addr:%08x data:%02x/%02x\n", offset+j, ram_data[offset+j], recv_data[j]);
            }
        }
    }
    info("RAM verification complete\n");
    std::this_thread::sleep_for(std::chrono::seconds(1));
}

int on_recv(byte data) {
    // info("recv: %02x %c\n",data,data);
    info("%c",data);
    fflush(stdout);
    return data == 0;
}