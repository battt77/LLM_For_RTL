#include "include/include.h"

#define SEXT(x, len) ({ struct { int64_t n : len; } __x = { .n = x }; (uint64_t)__x.n; })
#define BITMASK(bits) ((1ull << (bits)) - 1)
#define BITS(x, hi, lo) (((x) >> (lo)) & BITMASK((hi) - (lo) + 1)) // similar to x[hi:lo] in verilog


uint8_t pmem[PMEMSIZE]={};
extern uint32_t *vgactl_port_base;
extern void *vmem;
uint32_t key_dequeue();
extern uint32_t screen_size();

void difftest_skip_ref();

uint8_t* guest_to_host(uint32_t paddr) { return pmem + paddr - PMEMBASE; }
uint32_t host_to_guest(uint8_t *haddr) { return haddr - pmem + PMEMBASE; }

// void init_mem() {
//   uint32_t *p = (uint32_t *)pmem;
//   int i;
//   for (i = 0; i < (int)(PMEMSIZE / sizeof(p[0])); i++) {
//     p[i] = rand();
//   }
// }


void init_mem(){
  return ;
}

static bool out_of_bound(uint32_t addr) {
    if(addr >= PMEMBASE && addr < PMEMEND)
        return 0;
    else{
        printf("addr out of bound: %0x at pc: %0x\n", addr, npc_cpu.pc);
        npc_state.state = NPC_ABORT;
        return 1;
    }
}

word_t paddr_read(paddr_t addr, int len) {
  if(addr >= PMEMBASE && addr < PMEMEND)
    return pmem_read(addr, len,0);
  else{
    printf("addr out of bound: %0x at pc: %0x\n", addr, npc_cpu.pc);
    npc_state.state = NPC_ABORT;
    return 1;
  }
}

word_t vaddr_read(vaddr_t addr, int len) {
  return paddr_read(addr, len);
}

void host_write(void *addr, int len, uint32_t data) {

   switch (len) {
     case 1: *(uint8_t  *)addr = data; return;
     case 2: *(uint16_t *)addr = data; return;
     case 4: *(uint32_t *)addr = data; return;
   }
}


void pmem_write(uint32_t addr, int len, uint32_t data) {
    //printf("pmem_write: data=%x\n,len=%d",data,len);
  #ifdef CONFIG_DEVICE
  if(addr==SERIAL_PORT){
      #ifdef CONFIG_DIFFTEST
            difftest_skip_ref();
      #endif
    putchar((char)data);
    return;
  }
  if(addr==0xa0000104){
      #ifdef CONFIG_DIFFTEST
            difftest_skip_ref();
      #endif
    vgactl_port_base[1]=(uint32_t)data;
    return;
  }
  if(addr>=FB_ADDR && addr<FB_ADDR+screen_size()){
      #ifdef CONFIG_DIFFTEST
            difftest_skip_ref();
      #endif
    *(uint32_t *)((uint8_t *)vmem + addr - FB_ADDR) = data;
    return;
  }
  #endif
    host_write(guest_to_host(addr), len, data);
    //printf("pmem_write: addr=%x,len=%d\n",guest_to_host(addr),len);
}   

uint32_t host_read(void *addr, int len,int uflag) {
  if(uflag==0){
    switch (len) {
      case 1: return *(uint8_t  *)addr;
      case 2: return *(uint16_t *)addr;;
      case 4: return *(uint32_t *)addr;
    }}
  if(uflag==1){
    switch (len) {
      case 1: return SEXT(*(int8_t  *)addr,32);
      case 2: return SEXT(*(int16_t *)addr,32);
      case 4: return *(uint32_t *)addr;
    }}
}
uint32_t pmem_read(uint32_t addr, uint32_t len,int uflag) {
  //check if is device  
  //printf("pmem_read: paddr=%x\n",guest_to_host(addr));
  //printf("pmem_read len=%d\n",len);
  #ifdef CONFIG_DEVICE
  if(addr==RTC_ADDR){
      #ifdef CONFIG_DIFFTEST
          difftest_skip_ref();
      #endif
    uint64_t time=get_time();
    return (uint32_t)time;
  }
  if(addr==RTC_ADDR+4){
      #ifdef CONFIG_DIFFTEST
          difftest_skip_ref();
      #endif
    uint64_t time=get_time();
    uint32_t hightime=time>>32;
    return hightime;
  }
  if(addr==KBD_ADDR){
      #ifdef CONFIG_DIFFTEST
        difftest_skip_ref();
      #endif
    return key_dequeue();
  }
  if(addr==VGACTL_ADDR){
      #ifdef CONFIG_DIFFTEST
        difftest_skip_ref();
      #endif
    return vgactl_port_base[0];
    //printf("in VGACTR_ADDR\n");
  }
  if(addr==VGACTL_ADDR+4){
      #ifdef CONFIG_DIFFTEST
        difftest_skip_ref();
      #endif
    return vgactl_port_base[1];
  }
  
  #endif
  uint32_t ret=0;
  int32_t ret1=0;
  if(uflag==0){ret = host_read(guest_to_host(addr), len,uflag);}
  else if(uflag==1){ret1 = host_read(guest_to_host(addr), len,uflag);
                    ret=ret1;}

  //printf("pmem_read: pdata=%x\n",ret);
  return ret;
}

/*
uint32_t pmem_read(uint32_t addr, int len) {
  uint8_t * paddr = (uint8_t*) guest_to_host(addr);
  switch (len) {
    case 1: return *(uint8_t  *)paddr;
    case 2: return *(uint16_t *)paddr;
    case 4: printf("pmem_read: paddr=%x\n",(uint32_t *)paddr);
            return *(uint32_t *)paddr;
  }
  return *(uint32_t *)paddr;
}*/

/*
extern "C" void datamem_pmem_read(uint32_t raddr,uint32_t* rdata,int ren) {
  if(ren)
    *rdata= *(uint32_t *)guest_to_host(raddr & ~0x3u);
  // 总是读取地址为`raddr & ~0x3u`的4字节返回
}
extern "C" void datamem_pmem_write(int waddr, int wdata, char wmask) {
  if((uint8_t)wmask ==0)
    return;
  uint32_t addr = waddr & ~0x3u;
  for (int i=0;i<4;i++){
    if (wmask & 0x01) {
      host_write(guest_to_host(addr+i),1,wdata);
      wdata >>= 8;
      }
      
    wmask >>= 1;
    }
  return; 
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
}
*/

