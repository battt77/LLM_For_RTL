#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      //我们只有最高等级的M-mode（8,9,11都是ecall），也就是机器等级权限，编号是11。也就是说如果遇到ecall指令，首先往第0x342号csr状态寄存器写入11这个数字。
      case 11:
      {
        if(c->GPR1==-1){
          ev.event=EVENT_YIELD;//任务让出事件
        }
        else ev.event=EVENT_SYSCALL;//系统调用事件
        //同步异常中的ecall调用需要mepc寄存器的值+4，也就是中断返回后执行下一句指令，而不是继续执行ecall命令
        c->mepc=c->mepc+4;
        break;
      }
      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context *kernelcontext=(Context *)(kstack.end-sizeof(Context));
  memset(kernelcontext, 0, sizeof(Context));
  kernelcontext->mepc=(uintptr_t)entry;
  //在 RISC-V 中，常见的参数传递方式包括将参数放在通用寄存器中，通常是 a0 到 a7。
  kernelcontext->gpr[10]=(uintptr_t)arg;
  kernelcontext->mstatus=0x1800;
  kernelcontext->gpr[2]=(uintptr_t)kernelcontext;
  return kernelcontext;
  //return NULL
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
