#include "include/include.h"

static int is_batch_mode = false;
extern NPCState npc_state;

//void init_regex();
//void init_wp_pool();
void cpu_exec(uint32_t n);
word_t vaddr_read(vaddr_t addr, int len);
/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
	npc_state.state=NPC_QUIT;
 	return -1;
}

static int cmd_help(char *args);

static int cmd_si(char *args){
	
	int ifnoinput=1,stepnum=0;
	if(args==NULL)
		cpu_exec(ifnoinput);
	else{
		sscanf(args,"%d",&stepnum);
		cpu_exec(stepnum);
	}
	return 0;
}

static int cmd_info(char *args){
	if(args==NULL)
		printf("need input\n");
	else if(strcmp(args,"r")==0){
		npc_isa_reg_display();
	}
  /*
	else if(strcmp(args,"w")==0){
		watchpoint_display();
	}*/
	return 0;	
}




static int cmd_x(char *args){
	if(args==NULL)
		printf("need input\n");
	else{
		int len=0;
		uint32_t addr;
		char *n=strtok(args," ");
		char *expr=strtok(NULL," ");
		printf("n=%s,expr=%s\n",n,expr);
		sscanf(n,"%d",&len);
//void isa_reg_display();		sscanf(expr,"%x",&addr);
		for (int i=0;i<len;i++){
			printf("memory 0x%x is %08x\n",addr,vaddr_read(addr,4));
			addr=addr+4;
		}
	}
	return 0;	
}


static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NPC", cmd_q },
	{"si","Single step execution",cmd_si},
	{"info","Print program status",cmd_info},
	{"x","Scan memory",cmd_x},

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}
/*
void sdb_set_batch_mode() {
  is_batch_mode = true;
}*/

void sdb_mainloop() {
  #ifdef BATCH_MODE
    cmd_c(NULL);
    return;
  #endif

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }


    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

/*
void init_sdb() {
  //Compile the regular expressions. 
  init_regex();

  // Initialize the watchpoint pool. 
  init_wp_pool();
}*/