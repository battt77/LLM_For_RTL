#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <verilated.h>
#include "Vysyx_23060235_cpu1.h"
#include <verilated_vcd_c.h>
#include <stdint.h>
#include "Vysyx_23060235_cpu1__Dpi.h"
#include "svdpi.h"
#include "include/include.h"
#include <dlfcn.h>
#include <readline/readline.h>
#include <readline/history.h>
/////////////global define/////////////////////

//#define CONFIG_DIFFTEST
//#define CONFIG_DEVICE

uint32_t cyclecount=0;

Vysyx_23060235_cpu1 *top;
vluint64_t main_time = 0; 
static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
///////////////function include////////////////////////
void isa_reg_display();
void init_mem();
uint8_t* guest_to_host(paddr_t paddr);
void sdb_mainloop();
long img_init();
#ifdef CONFIG_DIFFTEST
  void difftest_step(vaddr_t pc, vaddr_t npc);
  void init_difftest(char *ref_so_file, long img_size, int port);
#endif

void init_device();
void device_update();
////////////////variables define////////////////////////


extern uint32_t *cpu_gpr;
CPU_state npc_cpu = {.pc = RESET_VECTOR};
NPCState npc_state = {.state = NPC_STOP, .halt_ret = 0};
static int diffbegin = 0;

///////////////////////////cpu-exec////////////////////////////
void cpu_init(){
    top->clk=0;
    top->reset=1;
    top->eval();
    //tfp->dump(main_time);
    main_time++;
    top->clk=1;
    top->reset=1;
    top->eval();
    //tfp->dump(main_time);
    main_time++;
	//top->clk=0;
    top->reset=0;
	top->eval();
    //tfp->dump(main_time);
    //main_time++;
}
void exec_once(VerilatedVcdC* tfp){
    top->clk = !top->clk;
	top->eval();
  	//tfp->dump(main_time);
	main_time++;
	top->clk = !top->clk;
	top->eval();
  	//tfp->dump(main_time);
	main_time++;
	npc_cpu.pc = top->pc;
	//printf("npc-pc=%0x\n",npc_cpu.pc);
  	for(int i=0;i<32;i++){
    	npc_cpu.gpr[i] = cpu_gpr[i];
}
}
void cpu_exec(uint32_t n){
    switch (npc_state.state) {
    case NPC_END: case NPC_ABORT:
        printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
        return;
    default: npc_state.state = NPC_RUNNING;
    }
    for(int i=0;i<n;i++){
		exec_once(tfp); 
		cyclecount++;
		//npc_isa_reg_display();
		//printf("exec-once\n");
		#ifdef CONFIG_DIFFTEST
    			difftest_step(npc_cpu.pc, npc_cpu.pc+4);
  				// for(int j=0;j<32;j++){
    			// 	printf("npc_cpu.gpr[%d]=%0x\n",j,npc_cpu.gpr[j]);
				// 	}
        #endif
		#ifdef CONFIG_DEVICE
        device_update();
        #endif
        if(npc_state.state != NPC_RUNNING) break;
        if(npc_state.halt_ret){
			printf("--totle cycle=%d--\n",cyclecount);
            npc_state.state = NPC_END;
            break;
        }
    }
    switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;

    case NPC_END: case NPC_ABORT:
        if(npc_state.state == NPC_ABORT)
            printf("ABORT at pc = %0x \n", npc_state.halt_pc);
        else
            printf("END at pc = %0x \n", npc_state.halt_pc);

        if(npc_state.halt_ret){
            printf("Hit good trap!\n");
        }else{
            printf("Hit bad trap!\n");
        }
		#ifdef CONFIG_ITRACE_COND
		if(nemu_state.halt_ret!=0){
			printf("the insts before halt\n");
			if(flag)
			{
				int i=0;
				for(i=p;i<20;i++)printf("inst: %s\n",ringbuf[i]);
				for(int j=0;j<p;j++)printf("inst: %s\n",ringbuf[j]);
			}
			else{
				for(int i=0;i<p;i++){
					printf("inst: %s\n",ringbuf[i]);
				}
			}
		}
		#endif
      // fall through
    case NPC_QUIT: return;
  }
}
//////////////////////////cpu-exec////////////////////////////


int main(int argc, char *argv[]){
	contextp = new VerilatedContext;
	Verilated::traceEverOn(true);
  	contextp->commandArgs(argc, argv);
	tfp=new VerilatedVcdC;
	top=new Vysyx_23060235_cpu1{contextp};
	//top=new Vysyx_23060235_cpu1("top");
	
	top->trace(tfp,0);
	tfp->open("wave.vcd");

	/*
	top->reset=0;
	top->clk=0;
	top->eval();
	contextp->timeInc(1);
	tfp->dump(contextp->time());*/
	init_mem();
	long img_size = img_init();
	cpu_init();
	#ifdef CONFIG_DIFFTEST
		char diff_so_file[100] = "/home/qh/ysyx/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so";
	///////////////////// monitor.c ///////////////////////////
      	int difftest_port = 1234;
      	init_difftest(diff_so_file, img_size, difftest_port);
	#endif
	#ifdef CONFIG_DEVICE
  	init_device();
  	#endif
	sdb_mainloop();
	tfp->close();
	delete tfp;
	delete top;
	delete contextp;
	return 0;
}
