#include <stdio.h>
#include <stdlib.h>
#include "Vysyx_23060235_cpu1.h"
#include "debug.h"
#include "difftest.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
//#include "Vysyx_23060235_cpu1__Dpi.h"
#include "svdpi.h"
#include <dlfcn.h>
#include <readline/readline.h>
#include <readline/history.h>


#define PMEMBASE 0x80000000
#define PMEMEND 0x87ffffff
#define RESET_VECTOR 0x80000000
#define PMEMSIZE (PMEMEND+1-PMEMBASE)
//enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
//////////////////////// utils.h //////////////////////////
enum { NPC_RUNNING, NPC_STOP, NPC_END, NPC_ABORT, NPC_QUIT };
typedef struct {
  int state;
  vaddr_t halt_pc;
  uint32_t halt_ret;
} NPCState;

extern NPCState npc_state;

typedef struct {
  word_t gpr[32];
  vaddr_t pc;
} CPU_state;

extern CPU_state npc_cpu;

///////////////////// function include ///////////////////
uint8_t* guest_to_host(uint32_t paddr);
uint32_t host_to_guest(uint8_t *haddr);
void pmem_write(uint32_t addr, int len, uint32_t data);
void host_write(void *addr, int len, uint32_t data);
uint32_t pmem_read(uint32_t addr, uint32_t len,int uflag);
long img_init();
//void npc_init(int argc,char *argv[]);
void cpu_init();
void exec_once(VerilatedVcdC* tfp);
void cpu_exec(uint32_t n);
word_t isa_reg_str2val(const char *s, bool *success);
void npc_isa_reg_display();
extern "C" void set_gpr_ptr(const svOpenArrayHandle r);
word_t paddr_read(paddr_t addr, int len);
word_t vaddr_read(vaddr_t addr, int len);
void sdb_mainloop();


///////////////// macro.h //////////////////////////////
#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))

//////////////////device.h//////////////////////////////
#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000
#define TIMER_HZ 60
#define MAP(c, f) c(f)
#define CONFIG_HAS_KEYBOARD

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0000200)
#define DISK_ADDR       (DEVICE_BASE + 0x0000300)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

uint64_t get_time();
void update_screen();
void vga_update_screen();
void init_screen();
#define PGSIZE    4096

