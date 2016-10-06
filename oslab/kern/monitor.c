// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
        { "backtrace", "Diaplay a backtrace of the stack", mon_backtrace },
        { "time", "Diaplay running time of command", time_cmd },

};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
	return 0;
}

int time_cmd(int args, char **argv, struct Trapframe *tf)
{
    if(args <= 1) {
        cprintf("no arg for time cmd!!!\n");
        return 0;
    }
    const char *cmdstr = argv[1];
    uint64_t st = read_tsc();
    if(strcmp(cmdstr, "kerninfo") == 0) {
        mon_kerninfo(args, argv, tf);
    }else if(strcmp(cmdstr, "help") == 0) {
        mon_help(args, argv, tf);
    }else if(strcmp(cmdstr, "backtrace") == 0) {
        mon_backtrace(args, argv, tf);
    }else {
        cprintf("invalid arg for time cmd!!!\n");
        return 0;
    }
    uint64_t ed = read_tsc();
    // cpu cycles
    cprintf("%s cycles: %llu\n", cmdstr, ed - st);
    return 0;
}

// Lab1 only
// read the pointer to the retaddr on the stack
static uint32_t
read_pretaddr() {
    uint32_t pretaddr;
    __asm __volatile("leal 4(%%ebp), %0" : "=r" (pretaddr)); 
    return pretaddr;
}

void
do_overflow(void)
{
    cprintf("Overflow success\n");
}

void
start_overflow(void)
{
	// You should use a techique similar to buffer overflow
	// to invoke the do_overflow function and
	// the procedure must return normally.

    // And you must use the "cprintf" function with %n specifier
    // you augmented in the "Exercise 9" to do this job.

    // hint: You can use the read_pretaddr function to retrieve 
    //       the pointer to the function call return address;

   // char str[256] = {};
   // int nstr = 0;
   // char *pret_addr;

   // uint32_t readd=read_pretaddr();

	// Your code here.
    static char str[256] = {};
    int nstr = 0;
    char *pret_addr;

    uint32_t ret_addr = *(int*)(read_pretaddr());
    uint32_t old_ebp = read_ebp();
    uint32_t old_esp = old_ebp + 4;
   
    char* esp_char = (char*)(&old_esp);
    char* ret_addr_char = (char*)(&ret_addr);
   
    // Your code here.
   
    // push   %ebp
    str[0] = 0x55;
    // mov    %esp,%ebp
    str[1] = 0x89;
    str[2] = 0xe5;
   
    // call do_overflow  f01008c9
    int delta =  (int)(&do_overflow) - (int)(str + 8);
    char* delta_char = (char*)(&delta);
    str[3] = 0xe8;
    str[4] = delta_char[0];
    str[5] = delta_char[1];
    str[6] = delta_char[2];
    str[7] = delta_char[3];

    // leave
    str[8] = 0xc9;
   
    // esp = esp - 4
    // bc 00 7c 00 00           mov    $0x7c00,%esp
    str[9] = 0xbc;
    str[10] = esp_char[0];
    str[11] = esp_char[1];
    str[12] = esp_char[2];
    str[13] = esp_char[3];


    // c7 04 24 b3 22 10 f0     movl   $0xf01022b3,(%esp)
    str[14] = 0xc7;
    str[15] = 0x04;
    str[16] = 0x24;
    str[17] = ret_addr_char[0];
    str[18] = ret_addr_char[1];
    str[19] = ret_addr_char[2];
    str[20] = ret_addr_char[3];

    // ret
    str[21] = 0xc3;
   
    // Update ret_addr
    *(int*)(old_ebp + 4) = (int)(&str);
   
//do_overflow();


}

void
overflow_me(void)
{
        start_overflow();
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
    cprintf("Stack backtrace\n");   
    uint32_t bp=read_ebp();
  //  cprintf("ebp: %08x\n",bp); 
  //  cprintf("eip: %08x\n",(int *)(bp+4)); 
   
    while(bp!=0){
    cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n", *((int *)(bp+4)),bp, *((int *)(bp+8)), *((int *)(bp+12)),
     *((int *)(bp+16)), *((int *)(bp+20)), *((int *)(bp+24)), *((int *)(bp+28)));
    struct Eipdebuginfo info;
    debuginfo_eip(*((int *)(bp+4)),&info);
    cprintf("\t%s:%d: ",info.eip_file,info.eip_line);
 //,   
int i=0;
for(i=0;i<info.eip_fn_namelen;i++){
 cprintf("%c",info.eip_fn_name[i]);

}  
 cprintf("+%u\n",*((int *)(bp+4))-info.eip_fn_addr);

   

    
    bp=*((int *) bp);
       

  
    }
    
    
    overflow_me();
    cprintf("Backtrace success\n");
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}

// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
	return callerpc;
}
