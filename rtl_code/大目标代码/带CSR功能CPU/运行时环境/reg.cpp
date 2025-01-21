#include "include/include.h"
#include "verilated_dpi.h"
#include "Vysyx_23060235_cpu1__Dpi.h"
const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};  
uint32_t *cpu_gpr = NULL; 

void npc_isa_reg_display() {
	int length=sizeof(regs)/sizeof(regs[0]);
	for(int i=0;i<length;i++){
		printf("npc_gpr %s = %0x\n",regs[i],cpu_gpr[i]);
	}
}

word_t isa_reg_str2val(const char *s, bool *success) {
  if(strlen(s)!=2){
		*success=false;
		return 0;
	}
	for(int i=0;i<32;i++)
	{
		if(s[0]==regs[i][0] && s[1]==regs[i][1])
			return cpu_gpr[i];
	}
	*success=false;
	return 0;
}

extern "C" void get_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint32_t *)(((VerilatedDpiOpenVar*)r)->datap());
}