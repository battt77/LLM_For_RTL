#include "include/include.h"
#include "verilated_dpi.h"

extern "C" void dpic_pmem_read(uint32_t raddr,uint32_t *rdata,int ren,int32_t lflag){
    //printf("lflag=%d\n",lflag);
    //printf("dpic_pmem_read raddr=0x%x\n",raddr);
    if(raddr>=PMEMBASE && raddr<=(PMEMBASE+0x8000000)){
        uint32_t len=4;
        int uflag=0;
        if(lflag==0b00000000000000000000000000000000){
            len=1;uflag=1;}
        else if(lflag==0b00000000000000000000000000000001){
            len=2;uflag=1;}
        else if(lflag==0b00000000000000000000000000000010){
            len=4;uflag=0;}
        else if(lflag==0b00000000000000000000000000000100){
            len=1;uflag=0;}
        else if(lflag==5){
            len=2;uflag=0;}
        *rdata = pmem_read(raddr,len,uflag);
        //printf("dpic_pmem_read exec\n");
    //npc_cpu.pc = raddr;
    }
    else if((raddr==RTC_ADDR || raddr==RTC_ADDR+4 || raddr==KBD_ADDR || raddr==VGACTL_ADDR || raddr==VGACTL_ADDR+4)){
        //printf("in device addr!!!!!\n");
        #ifdef CONFIG_DIFFTEST
            difftest_skip_ref();
        #endif
        *rdata = pmem_read(raddr,4,0);
    }
    else{
        //printf("out addr range\n");
        *rdata = 0;}
}
extern "C" void dpic_pmem_write(uint32_t waddr,char wmask,uint32_t wdata){
    //printf("dpic_pmem_write data = %x\n",wdata);
    switch (wmask)
    {
        case 1:   pmem_write(waddr, 1,wdata); break; 
        case 3:   pmem_write(waddr, 2,wdata);break; 
        case 15:  pmem_write(waddr, 4,wdata);break; 
        default:  pmem_write(waddr, 4,wdata);break;
    }
}
extern "C" void dpic_ebreak(){
    npc_state.halt_ret = 1;
    npc_state.halt_pc = npc_cpu.pc;
}