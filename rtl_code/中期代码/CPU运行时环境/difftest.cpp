#include "include/include.h"

void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;
uint8_t* guest_to_host(uint32_t paddr);
void isa_reg_display();

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;

extern uint64_t *cpu_gpr;
////////////////////  to skip some inst //////////////////////

void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.
  skip_dut_nr_inst = 0;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
void difftest_skip_dut(int nr_ref, int nr_dut) {
  skip_dut_nr_inst += nr_dut;

  while (nr_ref -- > 0) {
    ref_difftest_exec(1);
  }
}

/////////////////////// difftest main code /////////////////////
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void (*)(paddr_t, void *, size_t, bool))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void *, bool))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  printf("Differential testing: ON\n");
  printf("The result of every instruction will be compared with %s.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&npc_cpu, DIFFTEST_TO_REF);
}

static inline const char* reg_name(int idx) {
  extern const char* regs[];
  return regs[idx];
}
static inline bool difftest_check_reg(const char *name, vaddr_t pc, word_t ref, word_t dut) {
  if (ref != dut) {
    printf("difftest error\n");
    printf("%s is different after executing instruction at pc = " FMT_WORD
        ", right = " FMT_WORD ", wrong = " FMT_WORD ", diff = " FMT_WORD,
        name, pc, ref, dut, ref ^ dut);
    return false;
  }
  return true;
}
bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
	int i=0;
    //printf("bool checkregs\n");

  for(i=0;i<32;i++){
    //printf("npc_cpu.gpr[%d]=%0x\n",i,npc_cpu.gpr[i]);
		if(difftest_check_reg(reg_name(i),pc,ref_r->gpr[i],npc_cpu.gpr[i])==false)
			return false;
	}
	if(ref_r->pc != pc){
				printf("ref_pc:%0x\n", ref_r->pc);
				printf("npc_pc:%0x\n", pc);
				return false;
		}
	return true;
}


static void checkregs(CPU_state *ref, vaddr_t pc) {
   //printf("checkregs\n"); 
  if (!isa_difftest_checkregs(ref, pc)) {
    printf("difftest find error\n");
    npc_state.state = NPC_ABORT;
    npc_state.halt_pc = pc;
    npc_isa_reg_display();
  }
}

void difftest_step(vaddr_t pc, vaddr_t npc) {
    CPU_state ref_r;
    //printf("in difftest_step\n");
  if (skip_dut_nr_inst > 0) {
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    if (ref_r.pc == npc) {
      skip_dut_nr_inst = 0;
      checkregs(&ref_r, npc);
      return;
    }
    skip_dut_nr_inst --;
    if (skip_dut_nr_inst == 0)
      printf("can not catch up with ref.pc = " FMT_WORD " at pc = " FMT_WORD, ref_r.pc, pc);
    return;
  }
    
  if (is_skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    ref_difftest_regcpy(&npc_cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
    return;
  }
 
  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  checkregs(&ref_r, pc);
}