
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 03 01 00 00       	call   f0100141 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
		monitor(NULL);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
f0100047:	8d 5d 14             	lea    0x14(%ebp),%ebx
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010004a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010004d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100051:	8b 45 08             	mov    0x8(%ebp),%eax
f0100054:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100058:	c7 04 24 40 1b 10 f0 	movl   $0xf0101b40,(%esp)
f010005f:	e8 e7 09 00 00       	call   f0100a4b <cprintf>
	vcprintf(fmt, ap);
f0100064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100068:	8b 45 10             	mov    0x10(%ebp),%eax
f010006b:	89 04 24             	mov    %eax,(%esp)
f010006e:	e8 a5 09 00 00       	call   f0100a18 <vcprintf>
	cprintf("\n");
f0100073:	c7 04 24 66 1c 10 f0 	movl   $0xf0101c66,(%esp)
f010007a:	e8 cc 09 00 00       	call   f0100a4b <cprintf>
	va_end(ap);
}
f010007f:	83 c4 14             	add    $0x14,%esp
f0100082:	5b                   	pop    %ebx
f0100083:	5d                   	pop    %ebp
f0100084:	c3                   	ret    

f0100085 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100085:	55                   	push   %ebp
f0100086:	89 e5                	mov    %esp,%ebp
f0100088:	56                   	push   %esi
f0100089:	53                   	push   %ebx
f010008a:	83 ec 10             	sub    $0x10,%esp
f010008d:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100090:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f0100097:	75 3d                	jne    f01000d6 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100099:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010009f:	fa                   	cli    
f01000a0:	fc                   	cld    
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
f01000a1:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01000ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000b2:	c7 04 24 5a 1b 10 f0 	movl   $0xf0101b5a,(%esp)
f01000b9:	e8 8d 09 00 00       	call   f0100a4b <cprintf>
	vcprintf(fmt, ap);
f01000be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000c2:	89 34 24             	mov    %esi,(%esp)
f01000c5:	e8 4e 09 00 00       	call   f0100a18 <vcprintf>
	cprintf("\n");
f01000ca:	c7 04 24 66 1c 10 f0 	movl   $0xf0101c66,(%esp)
f01000d1:	e8 75 09 00 00       	call   f0100a4b <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000dd:	e8 e7 07 00 00       	call   f01008c9 <monitor>
f01000e2:	eb f2                	jmp    f01000d6 <_panic+0x51>

f01000e4 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 14             	sub    $0x14,%esp
f01000eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f01000ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f2:	c7 04 24 72 1b 10 f0 	movl   $0xf0101b72,(%esp)
f01000f9:	e8 4d 09 00 00       	call   f0100a4b <cprintf>
	if (x > 0)
f01000fe:	85 db                	test   %ebx,%ebx
f0100100:	7e 0d                	jle    f010010f <test_backtrace+0x2b>
		test_backtrace(x-1);
f0100102:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100105:	89 04 24             	mov    %eax,(%esp)
f0100108:	e8 d7 ff ff ff       	call   f01000e4 <test_backtrace>
f010010d:	eb 1c                	jmp    f010012b <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010010f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100116:	00 
f0100117:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010011e:	00 
f010011f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100126:	e8 77 06 00 00       	call   f01007a2 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010012b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010012f:	c7 04 24 8e 1b 10 f0 	movl   $0xf0101b8e,(%esp)
f0100136:	e8 10 09 00 00       	call   f0100a4b <cprintf>
}
f010013b:	83 c4 14             	add    $0x14,%esp
f010013e:	5b                   	pop    %ebx
f010013f:	5d                   	pop    %ebp
f0100140:	c3                   	ret    

f0100141 <i386_init>:

void
i386_init(void)
{
f0100141:	55                   	push   %ebp
f0100142:	89 e5                	mov    %esp,%ebp
f0100144:	57                   	push   %edi
f0100145:	53                   	push   %ebx
f0100146:	81 ec 20 01 00 00    	sub    $0x120,%esp
	extern char edata[], end[];
   	// Lab1 only
	char chnum1 = 0, chnum2 = 0, ntest[256] = {};
f010014c:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
f0100150:	c6 45 f6 00          	movb   $0x0,-0xa(%ebp)
f0100154:	ba 00 01 00 00       	mov    $0x100,%edx
f0100159:	b8 00 00 00 00       	mov    $0x0,%eax
f010015e:	8d bd f6 fe ff ff    	lea    -0x10a(%ebp),%edi
f0100164:	66 ab                	stos   %ax,%es:(%edi)
f0100166:	83 ea 02             	sub    $0x2,%edx
f0100169:	89 d1                	mov    %edx,%ecx
f010016b:	c1 e9 02             	shr    $0x2,%ecx
f010016e:	f3 ab                	rep stos %eax,%es:(%edi)
f0100170:	f6 c2 02             	test   $0x2,%dl
f0100173:	74 02                	je     f0100177 <i386_init+0x36>
f0100175:	66 ab                	stos   %ax,%es:(%edi)
f0100177:	83 e2 01             	and    $0x1,%edx
f010017a:	85 d2                	test   %edx,%edx
f010017c:	74 01                	je     f010017f <i386_init+0x3e>
f010017e:	aa                   	stos   %al,%es:(%edi)

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010017f:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f0100184:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100189:	89 44 24 08          	mov    %eax,0x8(%esp)
f010018d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100194:	00 
f0100195:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f010019c:	e8 b5 14 00 00       	call   f0101656 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01001a1:	e8 f4 03 00 00       	call   f010059a <cons_init>

	cprintf("6828 decimal is %o octal!%n\n%n", 6828, &chnum1, &chnum2);
f01001a6:	8d 45 f6             	lea    -0xa(%ebp),%eax
f01001a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001ad:	8d 7d f7             	lea    -0x9(%ebp),%edi
f01001b0:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01001b4:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01001bb:	00 
f01001bc:	c7 04 24 f0 1b 10 f0 	movl   $0xf0101bf0,(%esp)
f01001c3:	e8 83 08 00 00       	call   f0100a4b <cprintf>
	cprintf("pading space in the right to number 22: %-8d.\n", 22);
f01001c8:	c7 44 24 04 16 00 00 	movl   $0x16,0x4(%esp)
f01001cf:	00 
f01001d0:	c7 04 24 10 1c 10 f0 	movl   $0xf0101c10,(%esp)
f01001d7:	e8 6f 08 00 00       	call   f0100a4b <cprintf>
	cprintf("chnum1: %d chnum2: %d\n", chnum1, chnum2);
f01001dc:	0f be 45 f6          	movsbl -0xa(%ebp),%eax
f01001e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01001e4:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
f01001e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01001ec:	c7 04 24 a9 1b 10 f0 	movl   $0xf0101ba9,(%esp)
f01001f3:	e8 53 08 00 00       	call   f0100a4b <cprintf>
	cprintf("%n", NULL);
f01001f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001ff:	00 
f0100200:	c7 04 24 c2 1b 10 f0 	movl   $0xf0101bc2,(%esp)
f0100207:	e8 3f 08 00 00       	call   f0100a4b <cprintf>
	memset(ntest, 0xd, sizeof(ntest) - 1);
f010020c:	c7 44 24 08 ff 00 00 	movl   $0xff,0x8(%esp)
f0100213:	00 
f0100214:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
f010021b:	00 
f010021c:	8d 9d f6 fe ff ff    	lea    -0x10a(%ebp),%ebx
f0100222:	89 1c 24             	mov    %ebx,(%esp)
f0100225:	e8 2c 14 00 00       	call   f0101656 <memset>
	cprintf("%s%n", ntest, &chnum1); 
f010022a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010022e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100232:	c7 04 24 c0 1b 10 f0 	movl   $0xf0101bc0,(%esp)
f0100239:	e8 0d 08 00 00       	call   f0100a4b <cprintf>
	cprintf("chnum1: %d\n", chnum1);
f010023e:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
f0100242:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100246:	c7 04 24 c5 1b 10 f0 	movl   $0xf0101bc5,(%esp)
f010024d:	e8 f9 07 00 00       	call   f0100a4b <cprintf>
	cprintf("show me the sign: %+d, %+d\n", 1024, -1024);
f0100252:	c7 44 24 08 00 fc ff 	movl   $0xfffffc00,0x8(%esp)
f0100259:	ff 
f010025a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
f0100261:	00 
f0100262:	c7 04 24 d1 1b 10 f0 	movl   $0xf0101bd1,(%esp)
f0100269:	e8 dd 07 00 00       	call   f0100a4b <cprintf>


	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f010026e:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100275:	e8 6a fe ff ff       	call   f01000e4 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010027a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100281:	e8 43 06 00 00       	call   f01008c9 <monitor>
f0100286:	eb f2                	jmp    f010027a <i386_init+0x139>
	...

f0100290 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100290:	55                   	push   %ebp
f0100291:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100293:	ba 84 00 00 00       	mov    $0x84,%edx
f0100298:	ec                   	in     (%dx),%al
f0100299:	ec                   	in     (%dx),%al
f010029a:	ec                   	in     (%dx),%al
f010029b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010029c:	5d                   	pop    %ebp
f010029d:	c3                   	ret    

f010029e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002a6:	ec                   	in     (%dx),%al
f01002a7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ae:	f6 c2 01             	test   $0x1,%dl
f01002b1:	74 09                	je     f01002bc <serial_proc_data+0x1e>
f01002b3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002b8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002b9:	0f b6 c0             	movzbl %al,%eax
}
f01002bc:	5d                   	pop    %ebp
f01002bd:	c3                   	ret    

f01002be <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002be:	55                   	push   %ebp
f01002bf:	89 e5                	mov    %esp,%ebp
f01002c1:	57                   	push   %edi
f01002c2:	56                   	push   %esi
f01002c3:	53                   	push   %ebx
f01002c4:	83 ec 0c             	sub    $0xc,%esp
f01002c7:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01002c9:	bb 44 25 11 f0       	mov    $0xf0112544,%ebx
f01002ce:	bf 40 23 11 f0       	mov    $0xf0112340,%edi
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002d3:	eb 1e                	jmp    f01002f3 <cons_intr+0x35>
		if (c == 0)
f01002d5:	85 c0                	test   %eax,%eax
f01002d7:	74 1a                	je     f01002f3 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002d9:	8b 13                	mov    (%ebx),%edx
f01002db:	88 04 17             	mov    %al,(%edi,%edx,1)
f01002de:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01002e1:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01002e6:	0f 94 c2             	sete   %dl
f01002e9:	0f b6 d2             	movzbl %dl,%edx
f01002ec:	83 ea 01             	sub    $0x1,%edx
f01002ef:	21 d0                	and    %edx,%eax
f01002f1:	89 03                	mov    %eax,(%ebx)
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002f3:	ff d6                	call   *%esi
f01002f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002f8:	75 db                	jne    f01002d5 <cons_intr+0x17>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002fa:	83 c4 0c             	add    $0xc,%esp
f01002fd:	5b                   	pop    %ebx
f01002fe:	5e                   	pop    %esi
f01002ff:	5f                   	pop    %edi
f0100300:	5d                   	pop    %ebp
f0100301:	c3                   	ret    

f0100302 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100302:	55                   	push   %ebp
f0100303:	89 e5                	mov    %esp,%ebp
f0100305:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100308:	b8 8a 06 10 f0       	mov    $0xf010068a,%eax
f010030d:	e8 ac ff ff ff       	call   f01002be <cons_intr>
}
f0100312:	c9                   	leave  
f0100313:	c3                   	ret    

f0100314 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100314:	55                   	push   %ebp
f0100315:	89 e5                	mov    %esp,%ebp
f0100317:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010031a:	83 3d 24 23 11 f0 00 	cmpl   $0x0,0xf0112324
f0100321:	74 0a                	je     f010032d <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100323:	b8 9e 02 10 f0       	mov    $0xf010029e,%eax
f0100328:	e8 91 ff ff ff       	call   f01002be <cons_intr>
}
f010032d:	c9                   	leave  
f010032e:	c3                   	ret    

f010032f <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010032f:	55                   	push   %ebp
f0100330:	89 e5                	mov    %esp,%ebp
f0100332:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100335:	e8 da ff ff ff       	call   f0100314 <serial_intr>
	kbd_intr();
f010033a:	e8 c3 ff ff ff       	call   f0100302 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010033f:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
f0100345:	b8 00 00 00 00       	mov    $0x0,%eax
f010034a:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f0100350:	74 21                	je     f0100373 <cons_getc+0x44>
		c = cons.buf[cons.rpos++];
f0100352:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100359:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010035c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100362:	0f 94 c1             	sete   %cl
f0100365:	0f b6 c9             	movzbl %cl,%ecx
f0100368:	83 e9 01             	sub    $0x1,%ecx
f010036b:	21 ca                	and    %ecx,%edx
f010036d:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f0100373:	c9                   	leave  
f0100374:	c3                   	ret    

f0100375 <getchar>:
	cons_putc(c);
}

int
getchar(void)
{
f0100375:	55                   	push   %ebp
f0100376:	89 e5                	mov    %esp,%ebp
f0100378:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010037b:	e8 af ff ff ff       	call   f010032f <cons_getc>
f0100380:	85 c0                	test   %eax,%eax
f0100382:	74 f7                	je     f010037b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100384:	c9                   	leave  
f0100385:	c3                   	ret    

f0100386 <iscons>:

int
iscons(int fdnum)
{
f0100386:	55                   	push   %ebp
f0100387:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100389:	b8 01 00 00 00       	mov    $0x1,%eax
f010038e:	5d                   	pop    %ebp
f010038f:	c3                   	ret    

f0100390 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100390:	55                   	push   %ebp
f0100391:	89 e5                	mov    %esp,%ebp
f0100393:	57                   	push   %edi
f0100394:	56                   	push   %esi
f0100395:	53                   	push   %ebx
f0100396:	83 ec 2c             	sub    $0x2c,%esp
f0100399:	89 c7                	mov    %eax,%edi
f010039b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01003a0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01003a1:	a8 20                	test   $0x20,%al
f01003a3:	75 21                	jne    f01003c6 <cons_putc+0x36>
f01003a5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003aa:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01003af:	e8 dc fe ff ff       	call   f0100290 <delay>
f01003b4:	89 f2                	mov    %esi,%edx
f01003b6:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01003b7:	a8 20                	test   $0x20,%al
f01003b9:	75 0b                	jne    f01003c6 <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003bb:	83 c3 01             	add    $0x1,%ebx
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01003be:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01003c4:	75 e9                	jne    f01003af <cons_putc+0x1f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01003c6:	89 fa                	mov    %edi,%edx
f01003c8:	89 f8                	mov    %edi,%eax
f01003ca:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003d3:	b2 79                	mov    $0x79,%dl
f01003d5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003d6:	84 c0                	test   %al,%al
f01003d8:	78 21                	js     f01003fb <cons_putc+0x6b>
f01003da:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003df:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01003e4:	e8 a7 fe ff ff       	call   f0100290 <delay>
f01003e9:	89 f2                	mov    %esi,%edx
f01003eb:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003ec:	84 c0                	test   %al,%al
f01003ee:	78 0b                	js     f01003fb <cons_putc+0x6b>
f01003f0:	83 c3 01             	add    $0x1,%ebx
f01003f3:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01003f9:	75 e9                	jne    f01003e4 <cons_putc+0x54>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003fb:	ba 78 03 00 00       	mov    $0x378,%edx
f0100400:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100404:	ee                   	out    %al,(%dx)
f0100405:	b2 7a                	mov    $0x7a,%dl
f0100407:	b8 0d 00 00 00       	mov    $0xd,%eax
f010040c:	ee                   	out    %al,(%dx)
f010040d:	b8 08 00 00 00       	mov    $0x8,%eax
f0100412:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100413:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100419:	75 06                	jne    f0100421 <cons_putc+0x91>
		c |= 0x0700;
f010041b:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100421:	89 f8                	mov    %edi,%eax
f0100423:	25 ff 00 00 00       	and    $0xff,%eax
f0100428:	83 f8 09             	cmp    $0x9,%eax
f010042b:	0f 84 83 00 00 00    	je     f01004b4 <cons_putc+0x124>
f0100431:	83 f8 09             	cmp    $0x9,%eax
f0100434:	7f 0c                	jg     f0100442 <cons_putc+0xb2>
f0100436:	83 f8 08             	cmp    $0x8,%eax
f0100439:	0f 85 a9 00 00 00    	jne    f01004e8 <cons_putc+0x158>
f010043f:	90                   	nop
f0100440:	eb 18                	jmp    f010045a <cons_putc+0xca>
f0100442:	83 f8 0a             	cmp    $0xa,%eax
f0100445:	8d 76 00             	lea    0x0(%esi),%esi
f0100448:	74 40                	je     f010048a <cons_putc+0xfa>
f010044a:	83 f8 0d             	cmp    $0xd,%eax
f010044d:	8d 76 00             	lea    0x0(%esi),%esi
f0100450:	0f 85 92 00 00 00    	jne    f01004e8 <cons_putc+0x158>
f0100456:	66 90                	xchg   %ax,%ax
f0100458:	eb 38                	jmp    f0100492 <cons_putc+0x102>
	case '\b':
		if (crt_pos > 0) {
f010045a:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f0100461:	66 85 c0             	test   %ax,%ax
f0100464:	0f 84 e8 00 00 00    	je     f0100552 <cons_putc+0x1c2>
			crt_pos--;
f010046a:	83 e8 01             	sub    $0x1,%eax
f010046d:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100473:	0f b7 c0             	movzwl %ax,%eax
f0100476:	66 81 e7 00 ff       	and    $0xff00,%di
f010047b:	83 cf 20             	or     $0x20,%edi
f010047e:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100484:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100488:	eb 7b                	jmp    f0100505 <cons_putc+0x175>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010048a:	66 83 05 30 23 11 f0 	addw   $0x50,0xf0112330
f0100491:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100492:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f0100499:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010049f:	c1 e8 10             	shr    $0x10,%eax
f01004a2:	66 c1 e8 06          	shr    $0x6,%ax
f01004a6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004a9:	c1 e0 04             	shl    $0x4,%eax
f01004ac:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
f01004b2:	eb 51                	jmp    f0100505 <cons_putc+0x175>
		break;
	case '\t':
		cons_putc(' ');
f01004b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01004b9:	e8 d2 fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004be:	b8 20 00 00 00       	mov    $0x20,%eax
f01004c3:	e8 c8 fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01004cd:	e8 be fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d7:	e8 b4 fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e1:	e8 aa fe ff ff       	call   f0100390 <cons_putc>
f01004e6:	eb 1d                	jmp    f0100505 <cons_putc+0x175>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01004e8:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01004ef:	0f b7 c8             	movzwl %ax,%ecx
f01004f2:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f01004f8:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f01004fc:	83 c0 01             	add    $0x1,%eax
f01004ff:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100505:	66 81 3d 30 23 11 f0 	cmpw   $0x7cf,0xf0112330
f010050c:	cf 07 
f010050e:	76 42                	jbe    f0100552 <cons_putc+0x1c2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100510:	a1 2c 23 11 f0       	mov    0xf011232c,%eax
f0100515:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010051c:	00 
f010051d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100523:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100527:	89 04 24             	mov    %eax,(%esp)
f010052a:	e8 86 11 00 00       	call   f01016b5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010052f:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100535:	b8 80 07 00 00       	mov    $0x780,%eax
f010053a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100540:	83 c0 01             	add    $0x1,%eax
f0100543:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100548:	75 f0                	jne    f010053a <cons_putc+0x1aa>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010054a:	66 83 2d 30 23 11 f0 	subw   $0x50,0xf0112330
f0100551:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100552:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f0100558:	89 cb                	mov    %ecx,%ebx
f010055a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010055f:	89 ca                	mov    %ecx,%edx
f0100561:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100562:	0f b7 35 30 23 11 f0 	movzwl 0xf0112330,%esi
f0100569:	83 c1 01             	add    $0x1,%ecx
f010056c:	89 f0                	mov    %esi,%eax
f010056e:	66 c1 e8 08          	shr    $0x8,%ax
f0100572:	89 ca                	mov    %ecx,%edx
f0100574:	ee                   	out    %al,(%dx)
f0100575:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057a:	89 da                	mov    %ebx,%edx
f010057c:	ee                   	out    %al,(%dx)
f010057d:	89 f0                	mov    %esi,%eax
f010057f:	89 ca                	mov    %ecx,%edx
f0100581:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100582:	83 c4 2c             	add    $0x2c,%esp
f0100585:	5b                   	pop    %ebx
f0100586:	5e                   	pop    %esi
f0100587:	5f                   	pop    %edi
f0100588:	5d                   	pop    %ebp
f0100589:	c3                   	ret    

f010058a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010058a:	55                   	push   %ebp
f010058b:	89 e5                	mov    %esp,%ebp
f010058d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100590:	8b 45 08             	mov    0x8(%ebp),%eax
f0100593:	e8 f8 fd ff ff       	call   f0100390 <cons_putc>
}
f0100598:	c9                   	leave  
f0100599:	c3                   	ret    

f010059a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010059a:	55                   	push   %ebp
f010059b:	89 e5                	mov    %esp,%ebp
f010059d:	57                   	push   %edi
f010059e:	56                   	push   %esi
f010059f:	53                   	push   %ebx
f01005a0:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01005a3:	b8 00 80 0b f0       	mov    $0xf00b8000,%eax
f01005a8:	0f b7 10             	movzwl (%eax),%edx
	*cp = (uint16_t) 0xA55A;
f01005ab:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01005b0:	0f b7 00             	movzwl (%eax),%eax
f01005b3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005b7:	74 11                	je     f01005ca <cons_init+0x30>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005b9:	c7 05 28 23 11 f0 b4 	movl   $0x3b4,0xf0112328
f01005c0:	03 00 00 
f01005c3:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005c8:	eb 16                	jmp    f01005e0 <cons_init+0x46>
	} else {
		*cp = was;
f01005ca:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005d1:	c7 05 28 23 11 f0 d4 	movl   $0x3d4,0xf0112328
f01005d8:	03 00 00 
f01005db:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005e0:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f01005e6:	89 cb                	mov    %ecx,%ebx
f01005e8:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ed:	89 ca                	mov    %ecx,%edx
f01005ef:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f0:	83 c1 01             	add    $0x1,%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f3:	89 ca                	mov    %ecx,%edx
f01005f5:	ec                   	in     (%dx),%al
f01005f6:	0f b6 f8             	movzbl %al,%edi
f01005f9:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005fc:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100601:	89 da                	mov    %ebx,%edx
f0100603:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100604:	89 ca                	mov    %ecx,%edx
f0100606:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100607:	89 35 2c 23 11 f0    	mov    %esi,0xf011232c
	crt_pos = pos;
f010060d:	0f b6 c8             	movzbl %al,%ecx
f0100610:	09 cf                	or     %ecx,%edi
f0100612:	66 89 3d 30 23 11 f0 	mov    %di,0xf0112330
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100619:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010061e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100623:	89 da                	mov    %ebx,%edx
f0100625:	ee                   	out    %al,(%dx)
f0100626:	b2 fb                	mov    $0xfb,%dl
f0100628:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010062d:	ee                   	out    %al,(%dx)
f010062e:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100633:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100638:	89 ca                	mov    %ecx,%edx
f010063a:	ee                   	out    %al,(%dx)
f010063b:	b2 f9                	mov    $0xf9,%dl
f010063d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100642:	ee                   	out    %al,(%dx)
f0100643:	b2 fb                	mov    $0xfb,%dl
f0100645:	b8 03 00 00 00       	mov    $0x3,%eax
f010064a:	ee                   	out    %al,(%dx)
f010064b:	b2 fc                	mov    $0xfc,%dl
f010064d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b2 f9                	mov    $0xf9,%dl
f0100655:	b8 01 00 00 00       	mov    $0x1,%eax
f010065a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010065b:	b2 fd                	mov    $0xfd,%dl
f010065d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010065e:	3c ff                	cmp    $0xff,%al
f0100660:	0f 95 c0             	setne  %al
f0100663:	0f b6 f0             	movzbl %al,%esi
f0100666:	89 35 24 23 11 f0    	mov    %esi,0xf0112324
f010066c:	89 da                	mov    %ebx,%edx
f010066e:	ec                   	in     (%dx),%al
f010066f:	89 ca                	mov    %ecx,%edx
f0100671:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100672:	85 f6                	test   %esi,%esi
f0100674:	75 0c                	jne    f0100682 <cons_init+0xe8>
		cprintf("Serial port does not exist!\n");
f0100676:	c7 04 24 3f 1c 10 f0 	movl   $0xf0101c3f,(%esp)
f010067d:	e8 c9 03 00 00       	call   f0100a4b <cprintf>
}
f0100682:	83 c4 1c             	add    $0x1c,%esp
f0100685:	5b                   	pop    %ebx
f0100686:	5e                   	pop    %esi
f0100687:	5f                   	pop    %edi
f0100688:	5d                   	pop    %ebp
f0100689:	c3                   	ret    

f010068a <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010068a:	55                   	push   %ebp
f010068b:	89 e5                	mov    %esp,%ebp
f010068d:	53                   	push   %ebx
f010068e:	83 ec 14             	sub    $0x14,%esp
f0100691:	ba 64 00 00 00       	mov    $0x64,%edx
f0100696:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100697:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010069c:	a8 01                	test   $0x1,%al
f010069e:	0f 84 d9 00 00 00    	je     f010077d <kbd_proc_data+0xf3>
f01006a4:	b2 60                	mov    $0x60,%dl
f01006a6:	ec                   	in     (%dx),%al
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01006a7:	3c e0                	cmp    $0xe0,%al
f01006a9:	75 11                	jne    f01006bc <kbd_proc_data+0x32>
		// E0 escape character
		shift |= E0ESC;
f01006ab:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
f01006b2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01006b7:	e9 c1 00 00 00       	jmp    f010077d <kbd_proc_data+0xf3>
	} else if (data & 0x80) {
f01006bc:	84 c0                	test   %al,%al
f01006be:	79 32                	jns    f01006f2 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01006c0:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f01006c6:	f6 c2 40             	test   $0x40,%dl
f01006c9:	75 03                	jne    f01006ce <kbd_proc_data+0x44>
f01006cb:	83 e0 7f             	and    $0x7f,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01006ce:	0f b6 c0             	movzbl %al,%eax
f01006d1:	0f b6 80 80 1c 10 f0 	movzbl -0xfefe380(%eax),%eax
f01006d8:	83 c8 40             	or     $0x40,%eax
f01006db:	0f b6 c0             	movzbl %al,%eax
f01006de:	f7 d0                	not    %eax
f01006e0:	21 c2                	and    %eax,%edx
f01006e2:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
f01006e8:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01006ed:	e9 8b 00 00 00       	jmp    f010077d <kbd_proc_data+0xf3>
	} else if (shift & E0ESC) {
f01006f2:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f01006f8:	f6 c2 40             	test   $0x40,%dl
f01006fb:	74 0c                	je     f0100709 <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01006fd:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100700:	83 e2 bf             	and    $0xffffffbf,%edx
f0100703:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
	}

	shift |= shiftcode[data];
f0100709:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010070c:	0f b6 90 80 1c 10 f0 	movzbl -0xfefe380(%eax),%edx
f0100713:	0b 15 20 23 11 f0    	or     0xf0112320,%edx
f0100719:	0f b6 88 80 1d 10 f0 	movzbl -0xfefe280(%eax),%ecx
f0100720:	31 ca                	xor    %ecx,%edx
f0100722:	89 15 20 23 11 f0    	mov    %edx,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100728:	89 d1                	mov    %edx,%ecx
f010072a:	83 e1 03             	and    $0x3,%ecx
f010072d:	8b 0c 8d 80 1e 10 f0 	mov    -0xfefe180(,%ecx,4),%ecx
f0100734:	0f b6 1c 01          	movzbl (%ecx,%eax,1),%ebx
	if (shift & CAPSLOCK) {
f0100738:	f6 c2 08             	test   $0x8,%dl
f010073b:	74 1a                	je     f0100757 <kbd_proc_data+0xcd>
		if ('a' <= c && c <= 'z')
f010073d:	89 d9                	mov    %ebx,%ecx
f010073f:	8d 43 9f             	lea    -0x61(%ebx),%eax
f0100742:	83 f8 19             	cmp    $0x19,%eax
f0100745:	77 05                	ja     f010074c <kbd_proc_data+0xc2>
			c += 'A' - 'a';
f0100747:	83 eb 20             	sub    $0x20,%ebx
f010074a:	eb 0b                	jmp    f0100757 <kbd_proc_data+0xcd>
		else if ('A' <= c && c <= 'Z')
f010074c:	83 e9 41             	sub    $0x41,%ecx
f010074f:	83 f9 19             	cmp    $0x19,%ecx
f0100752:	77 03                	ja     f0100757 <kbd_proc_data+0xcd>
			c += 'a' - 'A';
f0100754:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100757:	f7 d2                	not    %edx
f0100759:	f6 c2 06             	test   $0x6,%dl
f010075c:	75 1f                	jne    f010077d <kbd_proc_data+0xf3>
f010075e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100764:	75 17                	jne    f010077d <kbd_proc_data+0xf3>
		cprintf("Rebooting!\n");
f0100766:	c7 04 24 5c 1c 10 f0 	movl   $0xf0101c5c,(%esp)
f010076d:	e8 d9 02 00 00       	call   f0100a4b <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100772:	ba 92 00 00 00       	mov    $0x92,%edx
f0100777:	b8 03 00 00 00       	mov    $0x3,%eax
f010077c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010077d:	89 d8                	mov    %ebx,%eax
f010077f:	83 c4 14             	add    $0x14,%esp
f0100782:	5b                   	pop    %ebx
f0100783:	5d                   	pop    %ebp
f0100784:	c3                   	ret    
	...

f0100790 <start_overflow>:
    cprintf("Overflow success\n");
}

void
start_overflow(void)
{
f0100790:	55                   	push   %ebp
f0100791:	89 e5                	mov    %esp,%ebp

	// Your code here.
    


}
f0100793:	5d                   	pop    %ebp
f0100794:	c3                   	ret    

f0100795 <overflow_me>:

void
overflow_me(void)
{
f0100795:	55                   	push   %ebp
f0100796:	89 e5                	mov    %esp,%ebp
        start_overflow();
}
f0100798:	5d                   	pop    %ebp
f0100799:	c3                   	ret    

f010079a <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010079a:	55                   	push   %ebp
f010079b:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010079d:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01007a0:	5d                   	pop    %ebp
f01007a1:	c3                   	ret    

f01007a2 <mon_backtrace>:
        start_overflow();
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007a2:	55                   	push   %ebp
f01007a3:	89 e5                	mov    %esp,%ebp
f01007a5:	83 ec 18             	sub    $0x18,%esp
	// Your code here.
    overflow_me();
    cprintf("Backtrace success\n");
f01007a8:	c7 04 24 90 1e 10 f0 	movl   $0xf0101e90,(%esp)
f01007af:	e8 97 02 00 00       	call   f0100a4b <cprintf>
	return 0;
}
f01007b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b9:	c9                   	leave  
f01007ba:	c3                   	ret    

f01007bb <do_overflow>:
    return pretaddr;
}

void
do_overflow(void)
{
f01007bb:	55                   	push   %ebp
f01007bc:	89 e5                	mov    %esp,%ebp
f01007be:	83 ec 18             	sub    $0x18,%esp
    cprintf("Overflow success\n");
f01007c1:	c7 04 24 a3 1e 10 f0 	movl   $0xf0101ea3,(%esp)
f01007c8:	e8 7e 02 00 00       	call   f0100a4b <cprintf>
}
f01007cd:	c9                   	leave  
f01007ce:	c3                   	ret    

f01007cf <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007cf:	55                   	push   %ebp
f01007d0:	89 e5                	mov    %esp,%ebp
f01007d2:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007d5:	c7 04 24 b5 1e 10 f0 	movl   $0xf0101eb5,(%esp)
f01007dc:	e8 6a 02 00 00       	call   f0100a4b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e1:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01007e8:	00 
f01007e9:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01007f0:	f0 
f01007f1:	c7 04 24 40 1f 10 f0 	movl   $0xf0101f40,(%esp)
f01007f8:	e8 4e 02 00 00       	call   f0100a4b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007fd:	c7 44 24 08 25 1b 10 	movl   $0x101b25,0x8(%esp)
f0100804:	00 
f0100805:	c7 44 24 04 25 1b 10 	movl   $0xf0101b25,0x4(%esp)
f010080c:	f0 
f010080d:	c7 04 24 64 1f 10 f0 	movl   $0xf0101f64,(%esp)
f0100814:	e8 32 02 00 00       	call   f0100a4b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100819:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100820:	00 
f0100821:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100828:	f0 
f0100829:	c7 04 24 88 1f 10 f0 	movl   $0xf0101f88,(%esp)
f0100830:	e8 16 02 00 00       	call   f0100a4b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100835:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010083c:	00 
f010083d:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100844:	f0 
f0100845:	c7 04 24 ac 1f 10 f0 	movl   $0xf0101fac,(%esp)
f010084c:	e8 fa 01 00 00       	call   f0100a4b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100851:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100856:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f010085b:	89 c2                	mov    %eax,%edx
f010085d:	c1 fa 1f             	sar    $0x1f,%edx
f0100860:	c1 ea 16             	shr    $0x16,%edx
f0100863:	8d 04 02             	lea    (%edx,%eax,1),%eax
f0100866:	c1 f8 0a             	sar    $0xa,%eax
f0100869:	89 44 24 04          	mov    %eax,0x4(%esp)
f010086d:	c7 04 24 d0 1f 10 f0 	movl   $0xf0101fd0,(%esp)
f0100874:	e8 d2 01 00 00       	call   f0100a4b <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f0100879:	b8 00 00 00 00       	mov    $0x0,%eax
f010087e:	c9                   	leave  
f010087f:	c3                   	ret    

f0100880 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100880:	55                   	push   %ebp
f0100881:	89 e5                	mov    %esp,%ebp
f0100883:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100886:	a1 74 20 10 f0       	mov    0xf0102074,%eax
f010088b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010088f:	a1 70 20 10 f0       	mov    0xf0102070,%eax
f0100894:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100898:	c7 04 24 ce 1e 10 f0 	movl   $0xf0101ece,(%esp)
f010089f:	e8 a7 01 00 00       	call   f0100a4b <cprintf>
f01008a4:	a1 80 20 10 f0       	mov    0xf0102080,%eax
f01008a9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008ad:	a1 7c 20 10 f0       	mov    0xf010207c,%eax
f01008b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b6:	c7 04 24 ce 1e 10 f0 	movl   $0xf0101ece,(%esp)
f01008bd:	e8 89 01 00 00       	call   f0100a4b <cprintf>
	return 0;
}
f01008c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c7:	c9                   	leave  
f01008c8:	c3                   	ret    

f01008c9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008c9:	55                   	push   %ebp
f01008ca:	89 e5                	mov    %esp,%ebp
f01008cc:	57                   	push   %edi
f01008cd:	56                   	push   %esi
f01008ce:	53                   	push   %ebx
f01008cf:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008d2:	c7 04 24 fc 1f 10 f0 	movl   $0xf0101ffc,(%esp)
f01008d9:	e8 6d 01 00 00       	call   f0100a4b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008de:	c7 04 24 20 20 10 f0 	movl   $0xf0102020,(%esp)
f01008e5:	e8 61 01 00 00       	call   f0100a4b <cprintf>

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ea:	bf 70 20 10 f0       	mov    $0xf0102070,%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01008ef:	c7 04 24 d7 1e 10 f0 	movl   $0xf0101ed7,(%esp)
f01008f6:	e8 d5 0a 00 00       	call   f01013d0 <readline>
f01008fb:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008fd:	85 c0                	test   %eax,%eax
f01008ff:	74 ee                	je     f01008ef <monitor+0x26>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100901:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
f0100908:	be 00 00 00 00       	mov    $0x0,%esi
f010090d:	eb 06                	jmp    f0100915 <monitor+0x4c>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010090f:	c6 03 00             	movb   $0x0,(%ebx)
f0100912:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100915:	0f b6 03             	movzbl (%ebx),%eax
f0100918:	84 c0                	test   %al,%al
f010091a:	74 6f                	je     f010098b <monitor+0xc2>
f010091c:	0f be c0             	movsbl %al,%eax
f010091f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100923:	c7 04 24 db 1e 10 f0 	movl   $0xf0101edb,(%esp)
f010092a:	e8 cf 0c 00 00       	call   f01015fe <strchr>
f010092f:	85 c0                	test   %eax,%eax
f0100931:	75 dc                	jne    f010090f <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100933:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100936:	74 53                	je     f010098b <monitor+0xc2>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100938:	83 fe 0f             	cmp    $0xf,%esi
f010093b:	90                   	nop
f010093c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100940:	75 16                	jne    f0100958 <monitor+0x8f>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100942:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100949:	00 
f010094a:	c7 04 24 e0 1e 10 f0 	movl   $0xf0101ee0,(%esp)
f0100951:	e8 f5 00 00 00       	call   f0100a4b <cprintf>
f0100956:	eb 97                	jmp    f01008ef <monitor+0x26>
			return 0;
		}
		argv[argc++] = buf;
f0100958:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010095c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010095f:	0f b6 03             	movzbl (%ebx),%eax
f0100962:	84 c0                	test   %al,%al
f0100964:	75 0c                	jne    f0100972 <monitor+0xa9>
f0100966:	eb ad                	jmp    f0100915 <monitor+0x4c>
			buf++;
f0100968:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010096b:	0f b6 03             	movzbl (%ebx),%eax
f010096e:	84 c0                	test   %al,%al
f0100970:	74 a3                	je     f0100915 <monitor+0x4c>
f0100972:	0f be c0             	movsbl %al,%eax
f0100975:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100979:	c7 04 24 db 1e 10 f0 	movl   $0xf0101edb,(%esp)
f0100980:	e8 79 0c 00 00       	call   f01015fe <strchr>
f0100985:	85 c0                	test   %eax,%eax
f0100987:	74 df                	je     f0100968 <monitor+0x9f>
f0100989:	eb 8a                	jmp    f0100915 <monitor+0x4c>
			buf++;
	}
	argv[argc] = 0;
f010098b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100992:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100993:	85 f6                	test   %esi,%esi
f0100995:	0f 84 54 ff ff ff    	je     f01008ef <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010099b:	8b 07                	mov    (%edi),%eax
f010099d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009a4:	89 04 24             	mov    %eax,(%esp)
f01009a7:	e8 dd 0b 00 00       	call   f0101589 <strcmp>
f01009ac:	ba 00 00 00 00       	mov    $0x0,%edx
f01009b1:	85 c0                	test   %eax,%eax
f01009b3:	74 1d                	je     f01009d2 <monitor+0x109>
f01009b5:	a1 7c 20 10 f0       	mov    0xf010207c,%eax
f01009ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009be:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009c1:	89 04 24             	mov    %eax,(%esp)
f01009c4:	e8 c0 0b 00 00       	call   f0101589 <strcmp>
f01009c9:	85 c0                	test   %eax,%eax
f01009cb:	75 28                	jne    f01009f5 <monitor+0x12c>
f01009cd:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f01009d2:	6b d2 0c             	imul   $0xc,%edx,%edx
f01009d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01009d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009dc:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01009df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009e3:	89 34 24             	mov    %esi,(%esp)
f01009e6:	ff 92 78 20 10 f0    	call   *-0xfefdf88(%edx)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009ec:	85 c0                	test   %eax,%eax
f01009ee:	78 1d                	js     f0100a0d <monitor+0x144>
f01009f0:	e9 fa fe ff ff       	jmp    f01008ef <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009f5:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009fc:	c7 04 24 fd 1e 10 f0 	movl   $0xf0101efd,(%esp)
f0100a03:	e8 43 00 00 00       	call   f0100a4b <cprintf>
f0100a08:	e9 e2 fe ff ff       	jmp    f01008ef <monitor+0x26>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a0d:	83 c4 5c             	add    $0x5c,%esp
f0100a10:	5b                   	pop    %ebx
f0100a11:	5e                   	pop    %esi
f0100a12:	5f                   	pop    %edi
f0100a13:	5d                   	pop    %ebp
f0100a14:	c3                   	ret    
f0100a15:	00 00                	add    %al,(%eax)
	...

f0100a18 <vcprintf>:
    (*cnt)++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f0100a18:	55                   	push   %ebp
f0100a19:	89 e5                	mov    %esp,%ebp
f0100a1b:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a1e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a25:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a28:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a2f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a33:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a36:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a3a:	c7 04 24 65 0a 10 f0 	movl   $0xf0100a65,(%esp)
f0100a41:	e8 97 04 00 00       	call   f0100edd <vprintfmt>
	return cnt;
}
f0100a46:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a49:	c9                   	leave  
f0100a4a:	c3                   	ret    

f0100a4b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a4b:	55                   	push   %ebp
f0100a4c:	89 e5                	mov    %esp,%ebp
f0100a4e:	83 ec 18             	sub    $0x18,%esp
	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
f0100a51:	8d 45 0c             	lea    0xc(%ebp),%eax
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100a54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a58:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a5b:	89 04 24             	mov    %eax,(%esp)
f0100a5e:	e8 b5 ff ff ff       	call   f0100a18 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a63:	c9                   	leave  
f0100a64:	c3                   	ret    

f0100a65 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a65:	55                   	push   %ebp
f0100a66:	89 e5                	mov    %esp,%ebp
f0100a68:	53                   	push   %ebx
f0100a69:	83 ec 14             	sub    $0x14,%esp
f0100a6c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f0100a6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a72:	89 04 24             	mov    %eax,(%esp)
f0100a75:	e8 10 fb ff ff       	call   f010058a <cputchar>
    (*cnt)++;
f0100a7a:	83 03 01             	addl   $0x1,(%ebx)
}
f0100a7d:	83 c4 14             	add    $0x14,%esp
f0100a80:	5b                   	pop    %ebx
f0100a81:	5d                   	pop    %ebp
f0100a82:	c3                   	ret    
	...

f0100a90 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a90:	55                   	push   %ebp
f0100a91:	89 e5                	mov    %esp,%ebp
f0100a93:	57                   	push   %edi
f0100a94:	56                   	push   %esi
f0100a95:	53                   	push   %ebx
f0100a96:	83 ec 14             	sub    $0x14,%esp
f0100a99:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a9c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a9f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100aa2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100aa5:	8b 1a                	mov    (%edx),%ebx
f0100aa7:	8b 01                	mov    (%ecx),%eax
f0100aa9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0100aac:	39 c3                	cmp    %eax,%ebx
f0100aae:	0f 8f 9c 00 00 00    	jg     f0100b50 <stab_binsearch+0xc0>
f0100ab4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f0100abb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100abe:	01 d8                	add    %ebx,%eax
f0100ac0:	89 c7                	mov    %eax,%edi
f0100ac2:	c1 ef 1f             	shr    $0x1f,%edi
f0100ac5:	01 c7                	add    %eax,%edi
f0100ac7:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ac9:	39 df                	cmp    %ebx,%edi
f0100acb:	7c 33                	jl     f0100b00 <stab_binsearch+0x70>
f0100acd:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100ad0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100ad3:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0100ad8:	39 f0                	cmp    %esi,%eax
f0100ada:	0f 84 bc 00 00 00    	je     f0100b9c <stab_binsearch+0x10c>
f0100ae0:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f0100ae4:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f0100ae8:	89 f8                	mov    %edi,%eax
			m--;
f0100aea:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aed:	39 d8                	cmp    %ebx,%eax
f0100aef:	7c 0f                	jl     f0100b00 <stab_binsearch+0x70>
f0100af1:	0f b6 0a             	movzbl (%edx),%ecx
f0100af4:	83 ea 0c             	sub    $0xc,%edx
f0100af7:	39 f1                	cmp    %esi,%ecx
f0100af9:	75 ef                	jne    f0100aea <stab_binsearch+0x5a>
f0100afb:	e9 9e 00 00 00       	jmp    f0100b9e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100b00:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100b03:	eb 3c                	jmp    f0100b41 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100b05:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b08:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0100b0a:	8d 5f 01             	lea    0x1(%edi),%ebx
f0100b0d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100b14:	eb 2b                	jmp    f0100b41 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f0100b16:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b19:	76 14                	jbe    f0100b2f <stab_binsearch+0x9f>
			*region_right = m - 1;
f0100b1b:	83 e8 01             	sub    $0x1,%eax
f0100b1e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100b21:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100b24:	89 02                	mov    %eax,(%edx)
f0100b26:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100b2d:	eb 12                	jmp    f0100b41 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b2f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b32:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100b34:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b38:	89 c3                	mov    %eax,%ebx
f0100b3a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100b41:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100b44:	0f 8d 71 ff ff ff    	jge    f0100abb <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b4a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100b4e:	75 0f                	jne    f0100b5f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100b50:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b53:	8b 03                	mov    (%ebx),%eax
f0100b55:	83 e8 01             	sub    $0x1,%eax
f0100b58:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100b5b:	89 02                	mov    %eax,(%edx)
f0100b5d:	eb 57                	jmp    f0100bb6 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b5f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100b62:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b64:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b67:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b69:	39 c1                	cmp    %eax,%ecx
f0100b6b:	7d 28                	jge    f0100b95 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100b6d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b70:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100b73:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100b78:	39 f2                	cmp    %esi,%edx
f0100b7a:	74 19                	je     f0100b95 <stab_binsearch+0x105>
f0100b7c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100b80:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100b84:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b87:	39 c1                	cmp    %eax,%ecx
f0100b89:	7d 0a                	jge    f0100b95 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100b8b:	0f b6 1a             	movzbl (%edx),%ebx
f0100b8e:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b91:	39 f3                	cmp    %esi,%ebx
f0100b93:	75 ef                	jne    f0100b84 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b95:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b98:	89 02                	mov    %eax,(%edx)
f0100b9a:	eb 1a                	jmp    f0100bb6 <stab_binsearch+0x126>
	}
}
f0100b9c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b9e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ba1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100ba4:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100ba8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bab:	0f 82 54 ff ff ff    	jb     f0100b05 <stab_binsearch+0x75>
f0100bb1:	e9 60 ff ff ff       	jmp    f0100b16 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100bb6:	83 c4 14             	add    $0x14,%esp
f0100bb9:	5b                   	pop    %ebx
f0100bba:	5e                   	pop    %esi
f0100bbb:	5f                   	pop    %edi
f0100bbc:	5d                   	pop    %ebp
f0100bbd:	c3                   	ret    

f0100bbe <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100bbe:	55                   	push   %ebp
f0100bbf:	89 e5                	mov    %esp,%ebp
f0100bc1:	83 ec 28             	sub    $0x28,%esp
f0100bc4:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100bc7:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100bca:	8b 75 08             	mov    0x8(%ebp),%esi
f0100bcd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100bd0:	c7 03 88 20 10 f0    	movl   $0xf0102088,(%ebx)
	info->eip_line = 0;
f0100bd6:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100bdd:	c7 43 08 88 20 10 f0 	movl   $0xf0102088,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100be4:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100beb:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100bee:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bf5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100bfb:	76 12                	jbe    f0100c0f <debuginfo_eip+0x51>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bfd:	b8 69 79 10 f0       	mov    $0xf0107969,%eax
f0100c02:	3d cd 5e 10 f0       	cmp    $0xf0105ecd,%eax
f0100c07:	0f 86 53 01 00 00    	jbe    f0100d60 <debuginfo_eip+0x1a2>
f0100c0d:	eb 1c                	jmp    f0100c2b <debuginfo_eip+0x6d>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100c0f:	c7 44 24 08 92 20 10 	movl   $0xf0102092,0x8(%esp)
f0100c16:	f0 
f0100c17:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100c1e:	00 
f0100c1f:	c7 04 24 9f 20 10 f0 	movl   $0xf010209f,(%esp)
f0100c26:	e8 5a f4 ff ff       	call   f0100085 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c2b:	80 3d 68 79 10 f0 00 	cmpb   $0x0,0xf0107968
f0100c32:	0f 85 28 01 00 00    	jne    f0100d60 <debuginfo_eip+0x1a2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c38:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c3f:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f0100c44:	2d c0 22 10 f0       	sub    $0xf01022c0,%eax
f0100c49:	c1 f8 02             	sar    $0x2,%eax
f0100c4c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c52:	83 e8 01             	sub    $0x1,%eax
f0100c55:	89 45 f0             	mov    %eax,-0x10(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c58:	8d 4d f0             	lea    -0x10(%ebp),%ecx
f0100c5b:	8d 55 f4             	lea    -0xc(%ebp),%edx
f0100c5e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c62:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c69:	b8 c0 22 10 f0       	mov    $0xf01022c0,%eax
f0100c6e:	e8 1d fe ff ff       	call   f0100a90 <stab_binsearch>
	if (lfile == 0)
f0100c73:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c76:	85 c0                	test   %eax,%eax
f0100c78:	0f 84 e2 00 00 00    	je     f0100d60 <debuginfo_eip+0x1a2>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c7e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	rfun = rfile;
f0100c81:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c84:	89 45 e8             	mov    %eax,-0x18(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c87:	8d 4d e8             	lea    -0x18(%ebp),%ecx
f0100c8a:	8d 55 ec             	lea    -0x14(%ebp),%edx
f0100c8d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c91:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c98:	b8 c0 22 10 f0       	mov    $0xf01022c0,%eax
f0100c9d:	e8 ee fd ff ff       	call   f0100a90 <stab_binsearch>

	if (lfun <= rfun) {
f0100ca2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100ca5:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100ca8:	7f 31                	jg     f0100cdb <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100caa:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cad:	8b 80 c0 22 10 f0    	mov    -0xfefdd40(%eax),%eax
f0100cb3:	ba 69 79 10 f0       	mov    $0xf0107969,%edx
f0100cb8:	81 ea cd 5e 10 f0    	sub    $0xf0105ecd,%edx
f0100cbe:	39 d0                	cmp    %edx,%eax
f0100cc0:	73 08                	jae    f0100cca <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100cc2:	05 cd 5e 10 f0       	add    $0xf0105ecd,%eax
f0100cc7:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100cca:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100ccd:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100cd0:	8b 80 c8 22 10 f0    	mov    -0xfefdd38(%eax),%eax
f0100cd6:	89 43 10             	mov    %eax,0x10(%ebx)
f0100cd9:	eb 06                	jmp    f0100ce1 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100cdb:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100cde:	8b 75 f4             	mov    -0xc(%ebp),%esi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ce1:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100ce8:	00 
f0100ce9:	8b 43 08             	mov    0x8(%ebx),%eax
f0100cec:	89 04 24             	mov    %eax,(%esp)
f0100cef:	e8 37 09 00 00       	call   f010162b <strfind>
f0100cf4:	2b 43 08             	sub    0x8(%ebx),%eax
f0100cf7:	89 43 0c             	mov    %eax,0xc(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f0100cfa:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100cfd:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100d00:	05 c8 22 10 f0       	add    $0xf01022c8,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d05:	eb 06                	jmp    f0100d0d <debuginfo_eip+0x14f>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d07:	83 ee 01             	sub    $0x1,%esi
f0100d0a:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d0d:	39 ce                	cmp    %ecx,%esi
f0100d0f:	7c 20                	jl     f0100d31 <debuginfo_eip+0x173>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d11:	0f b6 50 fc          	movzbl -0x4(%eax),%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d15:	80 fa 84             	cmp    $0x84,%dl
f0100d18:	74 5c                	je     f0100d76 <debuginfo_eip+0x1b8>
f0100d1a:	80 fa 64             	cmp    $0x64,%dl
f0100d1d:	75 e8                	jne    f0100d07 <debuginfo_eip+0x149>
f0100d1f:	83 38 00             	cmpl   $0x0,(%eax)
f0100d22:	74 e3                	je     f0100d07 <debuginfo_eip+0x149>
f0100d24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100d28:	eb 4c                	jmp    f0100d76 <debuginfo_eip+0x1b8>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d2a:	05 cd 5e 10 f0       	add    $0xf0105ecd,%eax
f0100d2f:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d31:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100d34:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100d37:	7d 2e                	jge    f0100d67 <debuginfo_eip+0x1a9>
		for (lline = lfun + 1;
f0100d39:	83 c0 01             	add    $0x1,%eax
f0100d3c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100d3f:	81 c2 c4 22 10 f0    	add    $0xf01022c4,%edx
f0100d45:	eb 07                	jmp    f0100d4e <debuginfo_eip+0x190>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d47:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100d4b:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d4e:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100d51:	7d 14                	jge    f0100d67 <debuginfo_eip+0x1a9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d53:	0f b6 0a             	movzbl (%edx),%ecx
f0100d56:	83 c2 0c             	add    $0xc,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d59:	80 f9 a0             	cmp    $0xa0,%cl
f0100d5c:	74 e9                	je     f0100d47 <debuginfo_eip+0x189>
f0100d5e:	eb 07                	jmp    f0100d67 <debuginfo_eip+0x1a9>
f0100d60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d65:	eb 05                	jmp    f0100d6c <debuginfo_eip+0x1ae>
f0100d67:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0100d6c:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100d6f:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100d72:	89 ec                	mov    %ebp,%esp
f0100d74:	5d                   	pop    %ebp
f0100d75:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d76:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100d79:	8b 86 c0 22 10 f0    	mov    -0xfefdd40(%esi),%eax
f0100d7f:	ba 69 79 10 f0       	mov    $0xf0107969,%edx
f0100d84:	81 ea cd 5e 10 f0    	sub    $0xf0105ecd,%edx
f0100d8a:	39 d0                	cmp    %edx,%eax
f0100d8c:	72 9c                	jb     f0100d2a <debuginfo_eip+0x16c>
f0100d8e:	eb a1                	jmp    f0100d31 <debuginfo_eip+0x173>

f0100d90 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d90:	55                   	push   %ebp
f0100d91:	89 e5                	mov    %esp,%ebp
f0100d93:	57                   	push   %edi
f0100d94:	56                   	push   %esi
f0100d95:	53                   	push   %ebx
f0100d96:	83 ec 4c             	sub    $0x4c,%esp
f0100d99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d9c:	89 d6                	mov    %edx,%esi
f0100d9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100da1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100da4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100da7:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100daa:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dad:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100db0:	8b 7d 18             	mov    0x18(%ebp),%edi
	// you can add helper function if needed.
	// your code here:


	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100db3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100db6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dbb:	39 d1                	cmp    %edx,%ecx
f0100dbd:	72 15                	jb     f0100dd4 <printnum+0x44>
f0100dbf:	77 07                	ja     f0100dc8 <printnum+0x38>
f0100dc1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100dc4:	39 d0                	cmp    %edx,%eax
f0100dc6:	76 0c                	jbe    f0100dd4 <printnum+0x44>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dc8:	83 eb 01             	sub    $0x1,%ebx
f0100dcb:	85 db                	test   %ebx,%ebx
f0100dcd:	8d 76 00             	lea    0x0(%esi),%esi
f0100dd0:	7f 61                	jg     f0100e33 <printnum+0xa3>
f0100dd2:	eb 70                	jmp    f0100e44 <printnum+0xb4>
	// your code here:


	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dd4:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100dd8:	83 eb 01             	sub    $0x1,%ebx
f0100ddb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100ddf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100de3:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100de7:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f0100deb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100dee:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100df1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100df4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100df8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100dff:	00 
f0100e00:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e03:	89 04 24             	mov    %eax,(%esp)
f0100e06:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e09:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e0d:	e8 ae 0a 00 00       	call   f01018c0 <__udivdi3>
f0100e12:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100e15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e18:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e1c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e20:	89 04 24             	mov    %eax,(%esp)
f0100e23:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e27:	89 f2                	mov    %esi,%edx
f0100e29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e2c:	e8 5f ff ff ff       	call   f0100d90 <printnum>
f0100e31:	eb 11                	jmp    f0100e44 <printnum+0xb4>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e33:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e37:	89 3c 24             	mov    %edi,(%esp)
f0100e3a:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e3d:	83 eb 01             	sub    $0x1,%ebx
f0100e40:	85 db                	test   %ebx,%ebx
f0100e42:	7f ef                	jg     f0100e33 <printnum+0xa3>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e44:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e48:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100e4c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e4f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e53:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e5a:	00 
f0100e5b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100e5e:	89 14 24             	mov    %edx,(%esp)
f0100e61:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e64:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100e68:	e8 83 0b 00 00       	call   f01019f0 <__umoddi3>
f0100e6d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e71:	0f be 80 ad 20 10 f0 	movsbl -0xfefdf53(%eax),%eax
f0100e78:	89 04 24             	mov    %eax,(%esp)
f0100e7b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e7e:	83 c4 4c             	add    $0x4c,%esp
f0100e81:	5b                   	pop    %ebx
f0100e82:	5e                   	pop    %esi
f0100e83:	5f                   	pop    %edi
f0100e84:	5d                   	pop    %ebp
f0100e85:	c3                   	ret    

f0100e86 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e86:	55                   	push   %ebp
f0100e87:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e89:	83 fa 01             	cmp    $0x1,%edx
f0100e8c:	7e 0e                	jle    f0100e9c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e8e:	8b 10                	mov    (%eax),%edx
f0100e90:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e93:	89 08                	mov    %ecx,(%eax)
f0100e95:	8b 02                	mov    (%edx),%eax
f0100e97:	8b 52 04             	mov    0x4(%edx),%edx
f0100e9a:	eb 22                	jmp    f0100ebe <getuint+0x38>
	else if (lflag)
f0100e9c:	85 d2                	test   %edx,%edx
f0100e9e:	74 10                	je     f0100eb0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ea0:	8b 10                	mov    (%eax),%edx
f0100ea2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ea5:	89 08                	mov    %ecx,(%eax)
f0100ea7:	8b 02                	mov    (%edx),%eax
f0100ea9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eae:	eb 0e                	jmp    f0100ebe <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100eb0:	8b 10                	mov    (%eax),%edx
f0100eb2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eb5:	89 08                	mov    %ecx,(%eax)
f0100eb7:	8b 02                	mov    (%edx),%eax
f0100eb9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ebe:	5d                   	pop    %ebp
f0100ebf:	c3                   	ret    

f0100ec0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ec0:	55                   	push   %ebp
f0100ec1:	89 e5                	mov    %esp,%ebp
f0100ec3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ec6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100eca:	8b 10                	mov    (%eax),%edx
f0100ecc:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ecf:	73 0a                	jae    f0100edb <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ed1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100ed4:	88 0a                	mov    %cl,(%edx)
f0100ed6:	83 c2 01             	add    $0x1,%edx
f0100ed9:	89 10                	mov    %edx,(%eax)
}
f0100edb:	5d                   	pop    %ebp
f0100edc:	c3                   	ret    

f0100edd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100edd:	55                   	push   %ebp
f0100ede:	89 e5                	mov    %esp,%ebp
f0100ee0:	57                   	push   %edi
f0100ee1:	56                   	push   %esi
f0100ee2:	53                   	push   %ebx
f0100ee3:	83 ec 5c             	sub    $0x5c,%esp
f0100ee6:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ee9:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100eec:	8b 5d 10             	mov    0x10(%ebp),%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100eef:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0100ef6:	eb 19                	jmp    f0100f11 <vprintfmt+0x34>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ef8:	85 c0                	test   %eax,%eax
f0100efa:	0f 84 12 04 00 00    	je     f0101312 <vprintfmt+0x435>
				return;
			putch(ch, putdat);
f0100f00:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f04:	89 04 24             	mov    %eax,(%esp)
f0100f07:	ff d7                	call   *%edi
f0100f09:	eb 06                	jmp    f0100f11 <vprintfmt+0x34>
f0100f0b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f0e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f11:	0f b6 03             	movzbl (%ebx),%eax
f0100f14:	83 c3 01             	add    $0x1,%ebx
f0100f17:	83 f8 25             	cmp    $0x25,%eax
f0100f1a:	75 dc                	jne    f0100ef8 <vprintfmt+0x1b>
f0100f1c:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100f20:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f27:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f2e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100f35:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f3a:	eb 06                	jmp    f0100f42 <vprintfmt+0x65>
f0100f3c:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0100f40:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f42:	0f b6 13             	movzbl (%ebx),%edx
f0100f45:	0f b6 c2             	movzbl %dl,%eax
f0100f48:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f4b:	8d 43 01             	lea    0x1(%ebx),%eax
f0100f4e:	83 ea 23             	sub    $0x23,%edx
f0100f51:	80 fa 55             	cmp    $0x55,%dl
f0100f54:	0f 87 9b 03 00 00    	ja     f01012f5 <vprintfmt+0x418>
f0100f5a:	0f b6 d2             	movzbl %dl,%edx
f0100f5d:	ff 24 95 3c 21 10 f0 	jmp    *-0xfefdec4(,%edx,4)
f0100f64:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0100f68:	eb d6                	jmp    f0100f40 <vprintfmt+0x63>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f6a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100f6d:	83 ea 30             	sub    $0x30,%edx
f0100f70:	89 55 d0             	mov    %edx,-0x30(%ebp)
				ch = *fmt;
f0100f73:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f76:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f79:	83 fb 09             	cmp    $0x9,%ebx
f0100f7c:	77 4c                	ja     f0100fca <vprintfmt+0xed>
f0100f7e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f81:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f84:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100f87:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f8a:	8d 4c 4a d0          	lea    -0x30(%edx,%ecx,2),%ecx
				ch = *fmt;
f0100f8e:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f91:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f94:	83 fb 09             	cmp    $0x9,%ebx
f0100f97:	76 eb                	jbe    f0100f84 <vprintfmt+0xa7>
f0100f99:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100f9c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f9f:	eb 29                	jmp    f0100fca <vprintfmt+0xed>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100fa1:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fa4:	8d 5a 04             	lea    0x4(%edx),%ebx
f0100fa7:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100faa:	8b 12                	mov    (%edx),%edx
f0100fac:	89 55 d0             	mov    %edx,-0x30(%ebp)
			goto process_precision;
f0100faf:	eb 19                	jmp    f0100fca <vprintfmt+0xed>

		case '.':
			if (width < 0)
f0100fb1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100fb4:	c1 fa 1f             	sar    $0x1f,%edx
f0100fb7:	f7 d2                	not    %edx
f0100fb9:	21 55 d4             	and    %edx,-0x2c(%ebp)
f0100fbc:	eb 82                	jmp    f0100f40 <vprintfmt+0x63>
f0100fbe:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f0100fc5:	e9 76 ff ff ff       	jmp    f0100f40 <vprintfmt+0x63>

		process_precision:
			if (width < 0)
f0100fca:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100fce:	0f 89 6c ff ff ff    	jns    f0100f40 <vprintfmt+0x63>
f0100fd4:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100fd7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100fda:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0100fdd:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100fe0:	e9 5b ff ff ff       	jmp    f0100f40 <vprintfmt+0x63>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fe5:	83 c1 01             	add    $0x1,%ecx
			goto reswitch;
f0100fe8:	e9 53 ff ff ff       	jmp    f0100f40 <vprintfmt+0x63>
f0100fed:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ff0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff3:	8d 50 04             	lea    0x4(%eax),%edx
f0100ff6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ff9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ffd:	8b 00                	mov    (%eax),%eax
f0100fff:	89 04 24             	mov    %eax,(%esp)
f0101002:	ff d7                	call   *%edi
f0101004:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			break;
f0101007:	e9 05 ff ff ff       	jmp    f0100f11 <vprintfmt+0x34>
f010100c:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f010100f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101012:	8d 50 04             	lea    0x4(%eax),%edx
f0101015:	89 55 14             	mov    %edx,0x14(%ebp)
f0101018:	8b 00                	mov    (%eax),%eax
f010101a:	89 c2                	mov    %eax,%edx
f010101c:	c1 fa 1f             	sar    $0x1f,%edx
f010101f:	31 d0                	xor    %edx,%eax
f0101021:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101023:	83 f8 06             	cmp    $0x6,%eax
f0101026:	7f 0b                	jg     f0101033 <vprintfmt+0x156>
f0101028:	8b 14 85 94 22 10 f0 	mov    -0xfefdd6c(,%eax,4),%edx
f010102f:	85 d2                	test   %edx,%edx
f0101031:	75 20                	jne    f0101053 <vprintfmt+0x176>
				printfmt(putch, putdat, "error %d", err);
f0101033:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101037:	c7 44 24 08 be 20 10 	movl   $0xf01020be,0x8(%esp)
f010103e:	f0 
f010103f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101043:	89 3c 24             	mov    %edi,(%esp)
f0101046:	e8 4f 03 00 00       	call   f010139a <printfmt>
f010104b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010104e:	e9 be fe ff ff       	jmp    f0100f11 <vprintfmt+0x34>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0101053:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101057:	c7 44 24 08 c7 20 10 	movl   $0xf01020c7,0x8(%esp)
f010105e:	f0 
f010105f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101063:	89 3c 24             	mov    %edi,(%esp)
f0101066:	e8 2f 03 00 00       	call   f010139a <printfmt>
f010106b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010106e:	e9 9e fe ff ff       	jmp    f0100f11 <vprintfmt+0x34>
f0101073:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101076:	89 c3                	mov    %eax,%ebx
f0101078:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010107b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010107e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101081:	8b 45 14             	mov    0x14(%ebp),%eax
f0101084:	8d 50 04             	lea    0x4(%eax),%edx
f0101087:	89 55 14             	mov    %edx,0x14(%ebp)
f010108a:	8b 00                	mov    (%eax),%eax
f010108c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010108f:	85 c0                	test   %eax,%eax
f0101091:	75 07                	jne    f010109a <vprintfmt+0x1bd>
f0101093:	c7 45 cc ca 20 10 f0 	movl   $0xf01020ca,-0x34(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f010109a:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f010109e:	7e 06                	jle    f01010a6 <vprintfmt+0x1c9>
f01010a0:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f01010a4:	75 13                	jne    f01010b9 <vprintfmt+0x1dc>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010a6:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01010a9:	0f be 02             	movsbl (%edx),%eax
f01010ac:	85 c0                	test   %eax,%eax
f01010ae:	0f 85 9f 00 00 00    	jne    f0101153 <vprintfmt+0x276>
f01010b4:	e9 8f 00 00 00       	jmp    f0101148 <vprintfmt+0x26b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010b9:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010bd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01010c0:	89 0c 24             	mov    %ecx,(%esp)
f01010c3:	e8 03 04 00 00       	call   f01014cb <strnlen>
f01010c8:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01010cb:	29 c2                	sub    %eax,%edx
f01010cd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01010d0:	85 d2                	test   %edx,%edx
f01010d2:	7e d2                	jle    f01010a6 <vprintfmt+0x1c9>
					putch(padc, putdat);
f01010d4:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f01010d8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01010db:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f01010de:	89 d3                	mov    %edx,%ebx
f01010e0:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010e7:	89 04 24             	mov    %eax,(%esp)
f01010ea:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010ec:	83 eb 01             	sub    $0x1,%ebx
f01010ef:	85 db                	test   %ebx,%ebx
f01010f1:	7f ed                	jg     f01010e0 <vprintfmt+0x203>
f01010f3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01010f6:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f01010fd:	eb a7                	jmp    f01010a6 <vprintfmt+0x1c9>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010ff:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101103:	74 1b                	je     f0101120 <vprintfmt+0x243>
f0101105:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101108:	83 fa 5e             	cmp    $0x5e,%edx
f010110b:	76 13                	jbe    f0101120 <vprintfmt+0x243>
					putch('?', putdat);
f010110d:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101110:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101114:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010111b:	ff 55 e0             	call   *-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010111e:	eb 0d                	jmp    f010112d <vprintfmt+0x250>
					putch('?', putdat);
				else
					putch(ch, putdat);
f0101120:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101123:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101127:	89 04 24             	mov    %eax,(%esp)
f010112a:	ff 55 e0             	call   *-0x20(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010112d:	83 ef 01             	sub    $0x1,%edi
f0101130:	0f be 03             	movsbl (%ebx),%eax
f0101133:	85 c0                	test   %eax,%eax
f0101135:	74 05                	je     f010113c <vprintfmt+0x25f>
f0101137:	83 c3 01             	add    $0x1,%ebx
f010113a:	eb 2e                	jmp    f010116a <vprintfmt+0x28d>
f010113c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010113f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101142:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101145:	8b 5d d0             	mov    -0x30(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101148:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010114c:	7f 33                	jg     f0101181 <vprintfmt+0x2a4>
f010114e:	e9 bb fd ff ff       	jmp    f0100f0e <vprintfmt+0x31>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101153:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101156:	83 c2 01             	add    $0x1,%edx
f0101159:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010115c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010115f:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0101162:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101165:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101168:	89 d3                	mov    %edx,%ebx
f010116a:	85 f6                	test   %esi,%esi
f010116c:	78 91                	js     f01010ff <vprintfmt+0x222>
f010116e:	83 ee 01             	sub    $0x1,%esi
f0101171:	79 8c                	jns    f01010ff <vprintfmt+0x222>
f0101173:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101176:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101179:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010117c:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010117f:	eb c7                	jmp    f0101148 <vprintfmt+0x26b>
f0101181:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101184:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101187:	89 74 24 04          	mov    %esi,0x4(%esp)
f010118b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101192:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101194:	83 eb 01             	sub    $0x1,%ebx
f0101197:	85 db                	test   %ebx,%ebx
f0101199:	7f ec                	jg     f0101187 <vprintfmt+0x2aa>
f010119b:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010119e:	e9 6e fd ff ff       	jmp    f0100f11 <vprintfmt+0x34>
f01011a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011a6:	83 f9 01             	cmp    $0x1,%ecx
f01011a9:	7e 16                	jle    f01011c1 <vprintfmt+0x2e4>
		return va_arg(*ap, long long);
f01011ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ae:	8d 50 08             	lea    0x8(%eax),%edx
f01011b1:	89 55 14             	mov    %edx,0x14(%ebp)
f01011b4:	8b 10                	mov    (%eax),%edx
f01011b6:	8b 48 04             	mov    0x4(%eax),%ecx
f01011b9:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01011bc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011bf:	eb 32                	jmp    f01011f3 <vprintfmt+0x316>
	else if (lflag)
f01011c1:	85 c9                	test   %ecx,%ecx
f01011c3:	74 18                	je     f01011dd <vprintfmt+0x300>
		return va_arg(*ap, long);
f01011c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c8:	8d 50 04             	lea    0x4(%eax),%edx
f01011cb:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ce:	8b 00                	mov    (%eax),%eax
f01011d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011d3:	89 c1                	mov    %eax,%ecx
f01011d5:	c1 f9 1f             	sar    $0x1f,%ecx
f01011d8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011db:	eb 16                	jmp    f01011f3 <vprintfmt+0x316>
	else
		return va_arg(*ap, int);
f01011dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e0:	8d 50 04             	lea    0x4(%eax),%edx
f01011e3:	89 55 14             	mov    %edx,0x14(%ebp)
f01011e6:	8b 00                	mov    (%eax),%eax
f01011e8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011eb:	89 c2                	mov    %eax,%edx
f01011ed:	c1 fa 1f             	sar    $0x1f,%edx
f01011f0:	89 55 dc             	mov    %edx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011f3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01011f6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011f9:	bb 0a 00 00 00       	mov    $0xa,%ebx
			if ((long long) num < 0) {
f01011fe:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101202:	0f 89 ab 00 00 00    	jns    f01012b3 <vprintfmt+0x3d6>
				putch('-', putdat);
f0101208:	89 74 24 04          	mov    %esi,0x4(%esp)
f010120c:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101213:	ff d7                	call   *%edi
				num = -(long long) num;
f0101215:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101218:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010121b:	f7 d8                	neg    %eax
f010121d:	83 d2 00             	adc    $0x0,%edx
f0101220:	f7 da                	neg    %edx
f0101222:	e9 8c 00 00 00       	jmp    f01012b3 <vprintfmt+0x3d6>
f0101227:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010122a:	89 ca                	mov    %ecx,%edx
f010122c:	8d 45 14             	lea    0x14(%ebp),%eax
f010122f:	e8 52 fc ff ff       	call   f0100e86 <getuint>
f0101234:	bb 0a 00 00 00       	mov    $0xa,%ebx
			base = 10;
			goto number;
f0101239:	eb 78                	jmp    f01012b3 <vprintfmt+0x3d6>
f010123b:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			// display a number in octal form and the form should begin with '0'
			putch('X', putdat);
f010123e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101242:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101249:	ff d7                	call   *%edi
			putch('X', putdat);
f010124b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010124f:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101256:	ff d7                	call   *%edi
			putch('X', putdat);
f0101258:	89 74 24 04          	mov    %esi,0x4(%esp)
f010125c:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101263:	ff d7                	call   *%edi
f0101265:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			break;
f0101268:	e9 a4 fc ff ff       	jmp    f0100f11 <vprintfmt+0x34>
f010126d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
f0101270:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101274:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010127b:	ff d7                	call   *%edi
			putch('x', putdat);
f010127d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101281:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101288:	ff d7                	call   *%edi
			num = (unsigned long long)
f010128a:	8b 45 14             	mov    0x14(%ebp),%eax
f010128d:	8d 50 04             	lea    0x4(%eax),%edx
f0101290:	89 55 14             	mov    %edx,0x14(%ebp)
f0101293:	8b 00                	mov    (%eax),%eax
f0101295:	ba 00 00 00 00       	mov    $0x0,%edx
f010129a:	bb 10 00 00 00       	mov    $0x10,%ebx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010129f:	eb 12                	jmp    f01012b3 <vprintfmt+0x3d6>
f01012a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01012a4:	89 ca                	mov    %ecx,%edx
f01012a6:	8d 45 14             	lea    0x14(%ebp),%eax
f01012a9:	e8 d8 fb ff ff       	call   f0100e86 <getuint>
f01012ae:	bb 10 00 00 00       	mov    $0x10,%ebx
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012b3:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f01012b7:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01012bb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01012be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01012c2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01012c6:	89 04 24             	mov    %eax,(%esp)
f01012c9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01012cd:	89 f2                	mov    %esi,%edx
f01012cf:	89 f8                	mov    %edi,%eax
f01012d1:	e8 ba fa ff ff       	call   f0100d90 <printnum>
f01012d6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			break;
f01012d9:	e9 33 fc ff ff       	jmp    f0100f11 <vprintfmt+0x34>
f01012de:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01012e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            break;
        }

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01012e8:	89 14 24             	mov    %edx,(%esp)
f01012eb:	ff d7                	call   *%edi
f01012ed:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			break;
f01012f0:	e9 1c fc ff ff       	jmp    f0100f11 <vprintfmt+0x34>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012f5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01012f9:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101300:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101302:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101305:	80 38 25             	cmpb   $0x25,(%eax)
f0101308:	0f 84 03 fc ff ff    	je     f0100f11 <vprintfmt+0x34>
f010130e:	89 c3                	mov    %eax,%ebx
f0101310:	eb f0                	jmp    f0101302 <vprintfmt+0x425>
				/* do nothing */;
			break;
		}
	}
}
f0101312:	83 c4 5c             	add    $0x5c,%esp
f0101315:	5b                   	pop    %ebx
f0101316:	5e                   	pop    %esi
f0101317:	5f                   	pop    %edi
f0101318:	5d                   	pop    %ebp
f0101319:	c3                   	ret    

f010131a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010131a:	55                   	push   %ebp
f010131b:	89 e5                	mov    %esp,%ebp
f010131d:	83 ec 28             	sub    $0x28,%esp
f0101320:	8b 45 08             	mov    0x8(%ebp),%eax
f0101323:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f0101326:	85 c0                	test   %eax,%eax
f0101328:	74 04                	je     f010132e <vsnprintf+0x14>
f010132a:	85 d2                	test   %edx,%edx
f010132c:	7f 07                	jg     f0101335 <vsnprintf+0x1b>
f010132e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101333:	eb 3b                	jmp    f0101370 <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101335:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101338:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f010133c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010133f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101346:	8b 45 14             	mov    0x14(%ebp),%eax
f0101349:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010134d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101350:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101354:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101357:	89 44 24 04          	mov    %eax,0x4(%esp)
f010135b:	c7 04 24 c0 0e 10 f0 	movl   $0xf0100ec0,(%esp)
f0101362:	e8 76 fb ff ff       	call   f0100edd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101367:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010136a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010136d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0101370:	c9                   	leave  
f0101371:	c3                   	ret    

f0101372 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101372:	55                   	push   %ebp
f0101373:	89 e5                	mov    %esp,%ebp
f0101375:	83 ec 18             	sub    $0x18,%esp

	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
f0101378:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f010137b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010137f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101382:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101386:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101389:	89 44 24 04          	mov    %eax,0x4(%esp)
f010138d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101390:	89 04 24             	mov    %eax,(%esp)
f0101393:	e8 82 ff ff ff       	call   f010131a <vsnprintf>
	va_end(ap);

	return rc;
}
f0101398:	c9                   	leave  
f0101399:	c3                   	ret    

f010139a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010139a:	55                   	push   %ebp
f010139b:	89 e5                	mov    %esp,%ebp
f010139d:	83 ec 18             	sub    $0x18,%esp
		}
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
f01013a0:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f01013a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013a7:	8b 45 10             	mov    0x10(%ebp),%eax
f01013aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b8:	89 04 24             	mov    %eax,(%esp)
f01013bb:	e8 1d fb ff ff       	call   f0100edd <vprintfmt>
	va_end(ap);
}
f01013c0:	c9                   	leave  
f01013c1:	c3                   	ret    
	...

f01013d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013d0:	55                   	push   %ebp
f01013d1:	89 e5                	mov    %esp,%ebp
f01013d3:	57                   	push   %edi
f01013d4:	56                   	push   %esi
f01013d5:	53                   	push   %ebx
f01013d6:	83 ec 1c             	sub    $0x1c,%esp
f01013d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013dc:	85 c0                	test   %eax,%eax
f01013de:	74 10                	je     f01013f0 <readline+0x20>
		cprintf("%s", prompt);
f01013e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e4:	c7 04 24 c7 20 10 f0 	movl   $0xf01020c7,(%esp)
f01013eb:	e8 5b f6 ff ff       	call   f0100a4b <cprintf>

	i = 0;
	echoing = iscons(0);
f01013f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f7:	e8 8a ef ff ff       	call   f0100386 <iscons>
f01013fc:	89 c7                	mov    %eax,%edi
f01013fe:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0101403:	e8 6d ef ff ff       	call   f0100375 <getchar>
f0101408:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010140a:	85 c0                	test   %eax,%eax
f010140c:	79 17                	jns    f0101425 <readline+0x55>
			cprintf("read error: %e\n", c);
f010140e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101412:	c7 04 24 b0 22 10 f0 	movl   $0xf01022b0,(%esp)
f0101419:	e8 2d f6 ff ff       	call   f0100a4b <cprintf>
f010141e:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f0101423:	eb 76                	jmp    f010149b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101425:	83 f8 08             	cmp    $0x8,%eax
f0101428:	74 08                	je     f0101432 <readline+0x62>
f010142a:	83 f8 7f             	cmp    $0x7f,%eax
f010142d:	8d 76 00             	lea    0x0(%esi),%esi
f0101430:	75 19                	jne    f010144b <readline+0x7b>
f0101432:	85 f6                	test   %esi,%esi
f0101434:	7e 15                	jle    f010144b <readline+0x7b>
			if (echoing)
f0101436:	85 ff                	test   %edi,%edi
f0101438:	74 0c                	je     f0101446 <readline+0x76>
				cputchar('\b');
f010143a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101441:	e8 44 f1 ff ff       	call   f010058a <cputchar>
			i--;
f0101446:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101449:	eb b8                	jmp    f0101403 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f010144b:	83 fb 1f             	cmp    $0x1f,%ebx
f010144e:	66 90                	xchg   %ax,%ax
f0101450:	7e 23                	jle    f0101475 <readline+0xa5>
f0101452:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101458:	7f 1b                	jg     f0101475 <readline+0xa5>
			if (echoing)
f010145a:	85 ff                	test   %edi,%edi
f010145c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101460:	74 08                	je     f010146a <readline+0x9a>
				cputchar(c);
f0101462:	89 1c 24             	mov    %ebx,(%esp)
f0101465:	e8 20 f1 ff ff       	call   f010058a <cputchar>
			buf[i++] = c;
f010146a:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101470:	83 c6 01             	add    $0x1,%esi
f0101473:	eb 8e                	jmp    f0101403 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101475:	83 fb 0a             	cmp    $0xa,%ebx
f0101478:	74 05                	je     f010147f <readline+0xaf>
f010147a:	83 fb 0d             	cmp    $0xd,%ebx
f010147d:	75 84                	jne    f0101403 <readline+0x33>
			if (echoing)
f010147f:	85 ff                	test   %edi,%edi
f0101481:	74 0c                	je     f010148f <readline+0xbf>
				cputchar('\n');
f0101483:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010148a:	e8 fb f0 ff ff       	call   f010058a <cputchar>
			buf[i] = 0;
f010148f:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
f0101496:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
			return buf;
		}
	}
}
f010149b:	83 c4 1c             	add    $0x1c,%esp
f010149e:	5b                   	pop    %ebx
f010149f:	5e                   	pop    %esi
f01014a0:	5f                   	pop    %edi
f01014a1:	5d                   	pop    %ebp
f01014a2:	c3                   	ret    
	...

f01014b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014b0:	55                   	push   %ebp
f01014b1:	89 e5                	mov    %esp,%ebp
f01014b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01014bb:	80 3a 00             	cmpb   $0x0,(%edx)
f01014be:	74 09                	je     f01014c9 <strlen+0x19>
		n++;
f01014c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014c7:	75 f7                	jne    f01014c0 <strlen+0x10>
		n++;
	return n;
}
f01014c9:	5d                   	pop    %ebp
f01014ca:	c3                   	ret    

f01014cb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014cb:	55                   	push   %ebp
f01014cc:	89 e5                	mov    %esp,%ebp
f01014ce:	53                   	push   %ebx
f01014cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014d5:	85 c9                	test   %ecx,%ecx
f01014d7:	74 19                	je     f01014f2 <strnlen+0x27>
f01014d9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014dc:	74 14                	je     f01014f2 <strnlen+0x27>
f01014de:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01014e3:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014e6:	39 c8                	cmp    %ecx,%eax
f01014e8:	74 0d                	je     f01014f7 <strnlen+0x2c>
f01014ea:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f01014ee:	75 f3                	jne    f01014e3 <strnlen+0x18>
f01014f0:	eb 05                	jmp    f01014f7 <strnlen+0x2c>
f01014f2:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01014f7:	5b                   	pop    %ebx
f01014f8:	5d                   	pop    %ebp
f01014f9:	c3                   	ret    

f01014fa <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014fa:	55                   	push   %ebp
f01014fb:	89 e5                	mov    %esp,%ebp
f01014fd:	53                   	push   %ebx
f01014fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101501:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101504:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101509:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010150d:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101510:	83 c2 01             	add    $0x1,%edx
f0101513:	84 c9                	test   %cl,%cl
f0101515:	75 f2                	jne    f0101509 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101517:	5b                   	pop    %ebx
f0101518:	5d                   	pop    %ebp
f0101519:	c3                   	ret    

f010151a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010151a:	55                   	push   %ebp
f010151b:	89 e5                	mov    %esp,%ebp
f010151d:	56                   	push   %esi
f010151e:	53                   	push   %ebx
f010151f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101522:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101525:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101528:	85 f6                	test   %esi,%esi
f010152a:	74 18                	je     f0101544 <strncpy+0x2a>
f010152c:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101531:	0f b6 1a             	movzbl (%edx),%ebx
f0101534:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101537:	80 3a 01             	cmpb   $0x1,(%edx)
f010153a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010153d:	83 c1 01             	add    $0x1,%ecx
f0101540:	39 ce                	cmp    %ecx,%esi
f0101542:	77 ed                	ja     f0101531 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101544:	5b                   	pop    %ebx
f0101545:	5e                   	pop    %esi
f0101546:	5d                   	pop    %ebp
f0101547:	c3                   	ret    

f0101548 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101548:	55                   	push   %ebp
f0101549:	89 e5                	mov    %esp,%ebp
f010154b:	56                   	push   %esi
f010154c:	53                   	push   %ebx
f010154d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101550:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101553:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101556:	89 f0                	mov    %esi,%eax
f0101558:	85 c9                	test   %ecx,%ecx
f010155a:	74 27                	je     f0101583 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f010155c:	83 e9 01             	sub    $0x1,%ecx
f010155f:	74 1d                	je     f010157e <strlcpy+0x36>
f0101561:	0f b6 1a             	movzbl (%edx),%ebx
f0101564:	84 db                	test   %bl,%bl
f0101566:	74 16                	je     f010157e <strlcpy+0x36>
			*dst++ = *src++;
f0101568:	88 18                	mov    %bl,(%eax)
f010156a:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010156d:	83 e9 01             	sub    $0x1,%ecx
f0101570:	74 0e                	je     f0101580 <strlcpy+0x38>
			*dst++ = *src++;
f0101572:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101575:	0f b6 1a             	movzbl (%edx),%ebx
f0101578:	84 db                	test   %bl,%bl
f010157a:	75 ec                	jne    f0101568 <strlcpy+0x20>
f010157c:	eb 02                	jmp    f0101580 <strlcpy+0x38>
f010157e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101580:	c6 00 00             	movb   $0x0,(%eax)
f0101583:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101585:	5b                   	pop    %ebx
f0101586:	5e                   	pop    %esi
f0101587:	5d                   	pop    %ebp
f0101588:	c3                   	ret    

f0101589 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101589:	55                   	push   %ebp
f010158a:	89 e5                	mov    %esp,%ebp
f010158c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010158f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101592:	0f b6 01             	movzbl (%ecx),%eax
f0101595:	84 c0                	test   %al,%al
f0101597:	74 15                	je     f01015ae <strcmp+0x25>
f0101599:	3a 02                	cmp    (%edx),%al
f010159b:	75 11                	jne    f01015ae <strcmp+0x25>
		p++, q++;
f010159d:	83 c1 01             	add    $0x1,%ecx
f01015a0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01015a3:	0f b6 01             	movzbl (%ecx),%eax
f01015a6:	84 c0                	test   %al,%al
f01015a8:	74 04                	je     f01015ae <strcmp+0x25>
f01015aa:	3a 02                	cmp    (%edx),%al
f01015ac:	74 ef                	je     f010159d <strcmp+0x14>
f01015ae:	0f b6 c0             	movzbl %al,%eax
f01015b1:	0f b6 12             	movzbl (%edx),%edx
f01015b4:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015b6:	5d                   	pop    %ebp
f01015b7:	c3                   	ret    

f01015b8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015b8:	55                   	push   %ebp
f01015b9:	89 e5                	mov    %esp,%ebp
f01015bb:	53                   	push   %ebx
f01015bc:	8b 55 08             	mov    0x8(%ebp),%edx
f01015bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015c2:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f01015c5:	85 c0                	test   %eax,%eax
f01015c7:	74 23                	je     f01015ec <strncmp+0x34>
f01015c9:	0f b6 1a             	movzbl (%edx),%ebx
f01015cc:	84 db                	test   %bl,%bl
f01015ce:	74 24                	je     f01015f4 <strncmp+0x3c>
f01015d0:	3a 19                	cmp    (%ecx),%bl
f01015d2:	75 20                	jne    f01015f4 <strncmp+0x3c>
f01015d4:	83 e8 01             	sub    $0x1,%eax
f01015d7:	74 13                	je     f01015ec <strncmp+0x34>
		n--, p++, q++;
f01015d9:	83 c2 01             	add    $0x1,%edx
f01015dc:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015df:	0f b6 1a             	movzbl (%edx),%ebx
f01015e2:	84 db                	test   %bl,%bl
f01015e4:	74 0e                	je     f01015f4 <strncmp+0x3c>
f01015e6:	3a 19                	cmp    (%ecx),%bl
f01015e8:	74 ea                	je     f01015d4 <strncmp+0x1c>
f01015ea:	eb 08                	jmp    f01015f4 <strncmp+0x3c>
f01015ec:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015f1:	5b                   	pop    %ebx
f01015f2:	5d                   	pop    %ebp
f01015f3:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015f4:	0f b6 02             	movzbl (%edx),%eax
f01015f7:	0f b6 11             	movzbl (%ecx),%edx
f01015fa:	29 d0                	sub    %edx,%eax
f01015fc:	eb f3                	jmp    f01015f1 <strncmp+0x39>

f01015fe <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015fe:	55                   	push   %ebp
f01015ff:	89 e5                	mov    %esp,%ebp
f0101601:	8b 45 08             	mov    0x8(%ebp),%eax
f0101604:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101608:	0f b6 10             	movzbl (%eax),%edx
f010160b:	84 d2                	test   %dl,%dl
f010160d:	74 15                	je     f0101624 <strchr+0x26>
		if (*s == c)
f010160f:	38 ca                	cmp    %cl,%dl
f0101611:	75 07                	jne    f010161a <strchr+0x1c>
f0101613:	eb 14                	jmp    f0101629 <strchr+0x2b>
f0101615:	38 ca                	cmp    %cl,%dl
f0101617:	90                   	nop
f0101618:	74 0f                	je     f0101629 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010161a:	83 c0 01             	add    $0x1,%eax
f010161d:	0f b6 10             	movzbl (%eax),%edx
f0101620:	84 d2                	test   %dl,%dl
f0101622:	75 f1                	jne    f0101615 <strchr+0x17>
f0101624:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f0101629:	5d                   	pop    %ebp
f010162a:	c3                   	ret    

f010162b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010162b:	55                   	push   %ebp
f010162c:	89 e5                	mov    %esp,%ebp
f010162e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101631:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101635:	0f b6 10             	movzbl (%eax),%edx
f0101638:	84 d2                	test   %dl,%dl
f010163a:	74 18                	je     f0101654 <strfind+0x29>
		if (*s == c)
f010163c:	38 ca                	cmp    %cl,%dl
f010163e:	75 0a                	jne    f010164a <strfind+0x1f>
f0101640:	eb 12                	jmp    f0101654 <strfind+0x29>
f0101642:	38 ca                	cmp    %cl,%dl
f0101644:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101648:	74 0a                	je     f0101654 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010164a:	83 c0 01             	add    $0x1,%eax
f010164d:	0f b6 10             	movzbl (%eax),%edx
f0101650:	84 d2                	test   %dl,%dl
f0101652:	75 ee                	jne    f0101642 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101654:	5d                   	pop    %ebp
f0101655:	c3                   	ret    

f0101656 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101656:	55                   	push   %ebp
f0101657:	89 e5                	mov    %esp,%ebp
f0101659:	83 ec 0c             	sub    $0xc,%esp
f010165c:	89 1c 24             	mov    %ebx,(%esp)
f010165f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101663:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101667:	8b 7d 08             	mov    0x8(%ebp),%edi
f010166a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010166d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101670:	85 c9                	test   %ecx,%ecx
f0101672:	74 30                	je     f01016a4 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101674:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010167a:	75 25                	jne    f01016a1 <memset+0x4b>
f010167c:	f6 c1 03             	test   $0x3,%cl
f010167f:	75 20                	jne    f01016a1 <memset+0x4b>
		c &= 0xFF;
f0101681:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101684:	89 d3                	mov    %edx,%ebx
f0101686:	c1 e3 08             	shl    $0x8,%ebx
f0101689:	89 d6                	mov    %edx,%esi
f010168b:	c1 e6 18             	shl    $0x18,%esi
f010168e:	89 d0                	mov    %edx,%eax
f0101690:	c1 e0 10             	shl    $0x10,%eax
f0101693:	09 f0                	or     %esi,%eax
f0101695:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101697:	09 d8                	or     %ebx,%eax
f0101699:	c1 e9 02             	shr    $0x2,%ecx
f010169c:	fc                   	cld    
f010169d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010169f:	eb 03                	jmp    f01016a4 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016a1:	fc                   	cld    
f01016a2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016a4:	89 f8                	mov    %edi,%eax
f01016a6:	8b 1c 24             	mov    (%esp),%ebx
f01016a9:	8b 74 24 04          	mov    0x4(%esp),%esi
f01016ad:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01016b1:	89 ec                	mov    %ebp,%esp
f01016b3:	5d                   	pop    %ebp
f01016b4:	c3                   	ret    

f01016b5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016b5:	55                   	push   %ebp
f01016b6:	89 e5                	mov    %esp,%ebp
f01016b8:	83 ec 08             	sub    $0x8,%esp
f01016bb:	89 34 24             	mov    %esi,(%esp)
f01016be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01016c5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f01016c8:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f01016cb:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f01016cd:	39 c6                	cmp    %eax,%esi
f01016cf:	73 35                	jae    f0101706 <memmove+0x51>
f01016d1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016d4:	39 d0                	cmp    %edx,%eax
f01016d6:	73 2e                	jae    f0101706 <memmove+0x51>
		s += n;
		d += n;
f01016d8:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016da:	f6 c2 03             	test   $0x3,%dl
f01016dd:	75 1b                	jne    f01016fa <memmove+0x45>
f01016df:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016e5:	75 13                	jne    f01016fa <memmove+0x45>
f01016e7:	f6 c1 03             	test   $0x3,%cl
f01016ea:	75 0e                	jne    f01016fa <memmove+0x45>
			asm volatile("std; rep movsl\n"
f01016ec:	83 ef 04             	sub    $0x4,%edi
f01016ef:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016f2:	c1 e9 02             	shr    $0x2,%ecx
f01016f5:	fd                   	std    
f01016f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016f8:	eb 09                	jmp    f0101703 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016fa:	83 ef 01             	sub    $0x1,%edi
f01016fd:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101700:	fd                   	std    
f0101701:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101703:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101704:	eb 20                	jmp    f0101726 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101706:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010170c:	75 15                	jne    f0101723 <memmove+0x6e>
f010170e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101714:	75 0d                	jne    f0101723 <memmove+0x6e>
f0101716:	f6 c1 03             	test   $0x3,%cl
f0101719:	75 08                	jne    f0101723 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f010171b:	c1 e9 02             	shr    $0x2,%ecx
f010171e:	fc                   	cld    
f010171f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101721:	eb 03                	jmp    f0101726 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101723:	fc                   	cld    
f0101724:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101726:	8b 34 24             	mov    (%esp),%esi
f0101729:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010172d:	89 ec                	mov    %ebp,%esp
f010172f:	5d                   	pop    %ebp
f0101730:	c3                   	ret    

f0101731 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101731:	55                   	push   %ebp
f0101732:	89 e5                	mov    %esp,%ebp
f0101734:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101737:	8b 45 10             	mov    0x10(%ebp),%eax
f010173a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010173e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101741:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101745:	8b 45 08             	mov    0x8(%ebp),%eax
f0101748:	89 04 24             	mov    %eax,(%esp)
f010174b:	e8 65 ff ff ff       	call   f01016b5 <memmove>
}
f0101750:	c9                   	leave  
f0101751:	c3                   	ret    

f0101752 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101752:	55                   	push   %ebp
f0101753:	89 e5                	mov    %esp,%ebp
f0101755:	57                   	push   %edi
f0101756:	56                   	push   %esi
f0101757:	53                   	push   %ebx
f0101758:	8b 75 08             	mov    0x8(%ebp),%esi
f010175b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010175e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101761:	85 c9                	test   %ecx,%ecx
f0101763:	74 36                	je     f010179b <memcmp+0x49>
		if (*s1 != *s2)
f0101765:	0f b6 06             	movzbl (%esi),%eax
f0101768:	0f b6 1f             	movzbl (%edi),%ebx
f010176b:	38 d8                	cmp    %bl,%al
f010176d:	74 20                	je     f010178f <memcmp+0x3d>
f010176f:	eb 14                	jmp    f0101785 <memcmp+0x33>
f0101771:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f0101776:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f010177b:	83 c2 01             	add    $0x1,%edx
f010177e:	83 e9 01             	sub    $0x1,%ecx
f0101781:	38 d8                	cmp    %bl,%al
f0101783:	74 12                	je     f0101797 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101785:	0f b6 c0             	movzbl %al,%eax
f0101788:	0f b6 db             	movzbl %bl,%ebx
f010178b:	29 d8                	sub    %ebx,%eax
f010178d:	eb 11                	jmp    f01017a0 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010178f:	83 e9 01             	sub    $0x1,%ecx
f0101792:	ba 00 00 00 00       	mov    $0x0,%edx
f0101797:	85 c9                	test   %ecx,%ecx
f0101799:	75 d6                	jne    f0101771 <memcmp+0x1f>
f010179b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f01017a0:	5b                   	pop    %ebx
f01017a1:	5e                   	pop    %esi
f01017a2:	5f                   	pop    %edi
f01017a3:	5d                   	pop    %ebp
f01017a4:	c3                   	ret    

f01017a5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017a5:	55                   	push   %ebp
f01017a6:	89 e5                	mov    %esp,%ebp
f01017a8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01017ab:	89 c2                	mov    %eax,%edx
f01017ad:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017b0:	39 d0                	cmp    %edx,%eax
f01017b2:	73 15                	jae    f01017c9 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017b4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01017b8:	38 08                	cmp    %cl,(%eax)
f01017ba:	75 06                	jne    f01017c2 <memfind+0x1d>
f01017bc:	eb 0b                	jmp    f01017c9 <memfind+0x24>
f01017be:	38 08                	cmp    %cl,(%eax)
f01017c0:	74 07                	je     f01017c9 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01017c2:	83 c0 01             	add    $0x1,%eax
f01017c5:	39 c2                	cmp    %eax,%edx
f01017c7:	77 f5                	ja     f01017be <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01017c9:	5d                   	pop    %ebp
f01017ca:	c3                   	ret    

f01017cb <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017cb:	55                   	push   %ebp
f01017cc:	89 e5                	mov    %esp,%ebp
f01017ce:	57                   	push   %edi
f01017cf:	56                   	push   %esi
f01017d0:	53                   	push   %ebx
f01017d1:	83 ec 04             	sub    $0x4,%esp
f01017d4:	8b 55 08             	mov    0x8(%ebp),%edx
f01017d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017da:	0f b6 02             	movzbl (%edx),%eax
f01017dd:	3c 20                	cmp    $0x20,%al
f01017df:	74 04                	je     f01017e5 <strtol+0x1a>
f01017e1:	3c 09                	cmp    $0x9,%al
f01017e3:	75 0e                	jne    f01017f3 <strtol+0x28>
		s++;
f01017e5:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017e8:	0f b6 02             	movzbl (%edx),%eax
f01017eb:	3c 20                	cmp    $0x20,%al
f01017ed:	74 f6                	je     f01017e5 <strtol+0x1a>
f01017ef:	3c 09                	cmp    $0x9,%al
f01017f1:	74 f2                	je     f01017e5 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01017f3:	3c 2b                	cmp    $0x2b,%al
f01017f5:	75 0c                	jne    f0101803 <strtol+0x38>
		s++;
f01017f7:	83 c2 01             	add    $0x1,%edx
f01017fa:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0101801:	eb 15                	jmp    f0101818 <strtol+0x4d>
	else if (*s == '-')
f0101803:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f010180a:	3c 2d                	cmp    $0x2d,%al
f010180c:	75 0a                	jne    f0101818 <strtol+0x4d>
		s++, neg = 1;
f010180e:	83 c2 01             	add    $0x1,%edx
f0101811:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101818:	85 db                	test   %ebx,%ebx
f010181a:	0f 94 c0             	sete   %al
f010181d:	74 05                	je     f0101824 <strtol+0x59>
f010181f:	83 fb 10             	cmp    $0x10,%ebx
f0101822:	75 18                	jne    f010183c <strtol+0x71>
f0101824:	80 3a 30             	cmpb   $0x30,(%edx)
f0101827:	75 13                	jne    f010183c <strtol+0x71>
f0101829:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010182d:	8d 76 00             	lea    0x0(%esi),%esi
f0101830:	75 0a                	jne    f010183c <strtol+0x71>
		s += 2, base = 16;
f0101832:	83 c2 02             	add    $0x2,%edx
f0101835:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010183a:	eb 15                	jmp    f0101851 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010183c:	84 c0                	test   %al,%al
f010183e:	66 90                	xchg   %ax,%ax
f0101840:	74 0f                	je     f0101851 <strtol+0x86>
f0101842:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0101847:	80 3a 30             	cmpb   $0x30,(%edx)
f010184a:	75 05                	jne    f0101851 <strtol+0x86>
		s++, base = 8;
f010184c:	83 c2 01             	add    $0x1,%edx
f010184f:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101851:	b8 00 00 00 00       	mov    $0x0,%eax
f0101856:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101858:	0f b6 0a             	movzbl (%edx),%ecx
f010185b:	89 cf                	mov    %ecx,%edi
f010185d:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101860:	80 fb 09             	cmp    $0x9,%bl
f0101863:	77 08                	ja     f010186d <strtol+0xa2>
			dig = *s - '0';
f0101865:	0f be c9             	movsbl %cl,%ecx
f0101868:	83 e9 30             	sub    $0x30,%ecx
f010186b:	eb 1e                	jmp    f010188b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f010186d:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f0101870:	80 fb 19             	cmp    $0x19,%bl
f0101873:	77 08                	ja     f010187d <strtol+0xb2>
			dig = *s - 'a' + 10;
f0101875:	0f be c9             	movsbl %cl,%ecx
f0101878:	83 e9 57             	sub    $0x57,%ecx
f010187b:	eb 0e                	jmp    f010188b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f010187d:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101880:	80 fb 19             	cmp    $0x19,%bl
f0101883:	77 15                	ja     f010189a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101885:	0f be c9             	movsbl %cl,%ecx
f0101888:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010188b:	39 f1                	cmp    %esi,%ecx
f010188d:	7d 0b                	jge    f010189a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f010188f:	83 c2 01             	add    $0x1,%edx
f0101892:	0f af c6             	imul   %esi,%eax
f0101895:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101898:	eb be                	jmp    f0101858 <strtol+0x8d>
f010189a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f010189c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018a0:	74 05                	je     f01018a7 <strtol+0xdc>
		*endptr = (char *) s;
f01018a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01018a5:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01018a7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01018ab:	74 04                	je     f01018b1 <strtol+0xe6>
f01018ad:	89 c8                	mov    %ecx,%eax
f01018af:	f7 d8                	neg    %eax
}
f01018b1:	83 c4 04             	add    $0x4,%esp
f01018b4:	5b                   	pop    %ebx
f01018b5:	5e                   	pop    %esi
f01018b6:	5f                   	pop    %edi
f01018b7:	5d                   	pop    %ebp
f01018b8:	c3                   	ret    
f01018b9:	00 00                	add    %al,(%eax)
f01018bb:	00 00                	add    %al,(%eax)
f01018bd:	00 00                	add    %al,(%eax)
	...

f01018c0 <__udivdi3>:
f01018c0:	55                   	push   %ebp
f01018c1:	89 e5                	mov    %esp,%ebp
f01018c3:	57                   	push   %edi
f01018c4:	56                   	push   %esi
f01018c5:	83 ec 10             	sub    $0x10,%esp
f01018c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01018cb:	8b 55 08             	mov    0x8(%ebp),%edx
f01018ce:	8b 75 10             	mov    0x10(%ebp),%esi
f01018d1:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01018d4:	85 c0                	test   %eax,%eax
f01018d6:	89 55 f0             	mov    %edx,-0x10(%ebp)
f01018d9:	75 35                	jne    f0101910 <__udivdi3+0x50>
f01018db:	39 fe                	cmp    %edi,%esi
f01018dd:	77 61                	ja     f0101940 <__udivdi3+0x80>
f01018df:	85 f6                	test   %esi,%esi
f01018e1:	75 0b                	jne    f01018ee <__udivdi3+0x2e>
f01018e3:	b8 01 00 00 00       	mov    $0x1,%eax
f01018e8:	31 d2                	xor    %edx,%edx
f01018ea:	f7 f6                	div    %esi
f01018ec:	89 c6                	mov    %eax,%esi
f01018ee:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f01018f1:	31 d2                	xor    %edx,%edx
f01018f3:	89 f8                	mov    %edi,%eax
f01018f5:	f7 f6                	div    %esi
f01018f7:	89 c7                	mov    %eax,%edi
f01018f9:	89 c8                	mov    %ecx,%eax
f01018fb:	f7 f6                	div    %esi
f01018fd:	89 c1                	mov    %eax,%ecx
f01018ff:	89 fa                	mov    %edi,%edx
f0101901:	89 c8                	mov    %ecx,%eax
f0101903:	83 c4 10             	add    $0x10,%esp
f0101906:	5e                   	pop    %esi
f0101907:	5f                   	pop    %edi
f0101908:	5d                   	pop    %ebp
f0101909:	c3                   	ret    
f010190a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101910:	39 f8                	cmp    %edi,%eax
f0101912:	77 1c                	ja     f0101930 <__udivdi3+0x70>
f0101914:	0f bd d0             	bsr    %eax,%edx
f0101917:	83 f2 1f             	xor    $0x1f,%edx
f010191a:	89 55 f4             	mov    %edx,-0xc(%ebp)
f010191d:	75 39                	jne    f0101958 <__udivdi3+0x98>
f010191f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101922:	0f 86 a0 00 00 00    	jbe    f01019c8 <__udivdi3+0x108>
f0101928:	39 f8                	cmp    %edi,%eax
f010192a:	0f 82 98 00 00 00    	jb     f01019c8 <__udivdi3+0x108>
f0101930:	31 ff                	xor    %edi,%edi
f0101932:	31 c9                	xor    %ecx,%ecx
f0101934:	89 c8                	mov    %ecx,%eax
f0101936:	89 fa                	mov    %edi,%edx
f0101938:	83 c4 10             	add    $0x10,%esp
f010193b:	5e                   	pop    %esi
f010193c:	5f                   	pop    %edi
f010193d:	5d                   	pop    %ebp
f010193e:	c3                   	ret    
f010193f:	90                   	nop
f0101940:	89 d1                	mov    %edx,%ecx
f0101942:	89 fa                	mov    %edi,%edx
f0101944:	89 c8                	mov    %ecx,%eax
f0101946:	31 ff                	xor    %edi,%edi
f0101948:	f7 f6                	div    %esi
f010194a:	89 c1                	mov    %eax,%ecx
f010194c:	89 fa                	mov    %edi,%edx
f010194e:	89 c8                	mov    %ecx,%eax
f0101950:	83 c4 10             	add    $0x10,%esp
f0101953:	5e                   	pop    %esi
f0101954:	5f                   	pop    %edi
f0101955:	5d                   	pop    %ebp
f0101956:	c3                   	ret    
f0101957:	90                   	nop
f0101958:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010195c:	89 f2                	mov    %esi,%edx
f010195e:	d3 e0                	shl    %cl,%eax
f0101960:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101963:	b8 20 00 00 00       	mov    $0x20,%eax
f0101968:	2b 45 f4             	sub    -0xc(%ebp),%eax
f010196b:	89 c1                	mov    %eax,%ecx
f010196d:	d3 ea                	shr    %cl,%edx
f010196f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101973:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101976:	d3 e6                	shl    %cl,%esi
f0101978:	89 c1                	mov    %eax,%ecx
f010197a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f010197d:	89 fe                	mov    %edi,%esi
f010197f:	d3 ee                	shr    %cl,%esi
f0101981:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101985:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101988:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010198b:	d3 e7                	shl    %cl,%edi
f010198d:	89 c1                	mov    %eax,%ecx
f010198f:	d3 ea                	shr    %cl,%edx
f0101991:	09 d7                	or     %edx,%edi
f0101993:	89 f2                	mov    %esi,%edx
f0101995:	89 f8                	mov    %edi,%eax
f0101997:	f7 75 ec             	divl   -0x14(%ebp)
f010199a:	89 d6                	mov    %edx,%esi
f010199c:	89 c7                	mov    %eax,%edi
f010199e:	f7 65 e8             	mull   -0x18(%ebp)
f01019a1:	39 d6                	cmp    %edx,%esi
f01019a3:	89 55 ec             	mov    %edx,-0x14(%ebp)
f01019a6:	72 30                	jb     f01019d8 <__udivdi3+0x118>
f01019a8:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01019ab:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f01019af:	d3 e2                	shl    %cl,%edx
f01019b1:	39 c2                	cmp    %eax,%edx
f01019b3:	73 05                	jae    f01019ba <__udivdi3+0xfa>
f01019b5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f01019b8:	74 1e                	je     f01019d8 <__udivdi3+0x118>
f01019ba:	89 f9                	mov    %edi,%ecx
f01019bc:	31 ff                	xor    %edi,%edi
f01019be:	e9 71 ff ff ff       	jmp    f0101934 <__udivdi3+0x74>
f01019c3:	90                   	nop
f01019c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c8:	31 ff                	xor    %edi,%edi
f01019ca:	b9 01 00 00 00       	mov    $0x1,%ecx
f01019cf:	e9 60 ff ff ff       	jmp    f0101934 <__udivdi3+0x74>
f01019d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019d8:	8d 4f ff             	lea    -0x1(%edi),%ecx
f01019db:	31 ff                	xor    %edi,%edi
f01019dd:	89 c8                	mov    %ecx,%eax
f01019df:	89 fa                	mov    %edi,%edx
f01019e1:	83 c4 10             	add    $0x10,%esp
f01019e4:	5e                   	pop    %esi
f01019e5:	5f                   	pop    %edi
f01019e6:	5d                   	pop    %ebp
f01019e7:	c3                   	ret    
	...

f01019f0 <__umoddi3>:
f01019f0:	55                   	push   %ebp
f01019f1:	89 e5                	mov    %esp,%ebp
f01019f3:	57                   	push   %edi
f01019f4:	56                   	push   %esi
f01019f5:	83 ec 20             	sub    $0x20,%esp
f01019f8:	8b 55 14             	mov    0x14(%ebp),%edx
f01019fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019fe:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101a01:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101a04:	85 d2                	test   %edx,%edx
f0101a06:	89 c8                	mov    %ecx,%eax
f0101a08:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f0101a0b:	75 13                	jne    f0101a20 <__umoddi3+0x30>
f0101a0d:	39 f7                	cmp    %esi,%edi
f0101a0f:	76 3f                	jbe    f0101a50 <__umoddi3+0x60>
f0101a11:	89 f2                	mov    %esi,%edx
f0101a13:	f7 f7                	div    %edi
f0101a15:	89 d0                	mov    %edx,%eax
f0101a17:	31 d2                	xor    %edx,%edx
f0101a19:	83 c4 20             	add    $0x20,%esp
f0101a1c:	5e                   	pop    %esi
f0101a1d:	5f                   	pop    %edi
f0101a1e:	5d                   	pop    %ebp
f0101a1f:	c3                   	ret    
f0101a20:	39 f2                	cmp    %esi,%edx
f0101a22:	77 4c                	ja     f0101a70 <__umoddi3+0x80>
f0101a24:	0f bd ca             	bsr    %edx,%ecx
f0101a27:	83 f1 1f             	xor    $0x1f,%ecx
f0101a2a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101a2d:	75 51                	jne    f0101a80 <__umoddi3+0x90>
f0101a2f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f0101a32:	0f 87 e0 00 00 00    	ja     f0101b18 <__umoddi3+0x128>
f0101a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a3b:	29 f8                	sub    %edi,%eax
f0101a3d:	19 d6                	sbb    %edx,%esi
f0101a3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101a42:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a45:	89 f2                	mov    %esi,%edx
f0101a47:	83 c4 20             	add    $0x20,%esp
f0101a4a:	5e                   	pop    %esi
f0101a4b:	5f                   	pop    %edi
f0101a4c:	5d                   	pop    %ebp
f0101a4d:	c3                   	ret    
f0101a4e:	66 90                	xchg   %ax,%ax
f0101a50:	85 ff                	test   %edi,%edi
f0101a52:	75 0b                	jne    f0101a5f <__umoddi3+0x6f>
f0101a54:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a59:	31 d2                	xor    %edx,%edx
f0101a5b:	f7 f7                	div    %edi
f0101a5d:	89 c7                	mov    %eax,%edi
f0101a5f:	89 f0                	mov    %esi,%eax
f0101a61:	31 d2                	xor    %edx,%edx
f0101a63:	f7 f7                	div    %edi
f0101a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a68:	f7 f7                	div    %edi
f0101a6a:	eb a9                	jmp    f0101a15 <__umoddi3+0x25>
f0101a6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a70:	89 c8                	mov    %ecx,%eax
f0101a72:	89 f2                	mov    %esi,%edx
f0101a74:	83 c4 20             	add    $0x20,%esp
f0101a77:	5e                   	pop    %esi
f0101a78:	5f                   	pop    %edi
f0101a79:	5d                   	pop    %ebp
f0101a7a:	c3                   	ret    
f0101a7b:	90                   	nop
f0101a7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a80:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101a84:	d3 e2                	shl    %cl,%edx
f0101a86:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101a89:	ba 20 00 00 00       	mov    $0x20,%edx
f0101a8e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101a91:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101a94:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101a98:	89 fa                	mov    %edi,%edx
f0101a9a:	d3 ea                	shr    %cl,%edx
f0101a9c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101aa0:	0b 55 f4             	or     -0xc(%ebp),%edx
f0101aa3:	d3 e7                	shl    %cl,%edi
f0101aa5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101aa9:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101aac:	89 f2                	mov    %esi,%edx
f0101aae:	89 7d e8             	mov    %edi,-0x18(%ebp)
f0101ab1:	89 c7                	mov    %eax,%edi
f0101ab3:	d3 ea                	shr    %cl,%edx
f0101ab5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101ab9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101abc:	89 c2                	mov    %eax,%edx
f0101abe:	d3 e6                	shl    %cl,%esi
f0101ac0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101ac4:	d3 ea                	shr    %cl,%edx
f0101ac6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101aca:	09 d6                	or     %edx,%esi
f0101acc:	89 f0                	mov    %esi,%eax
f0101ace:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101ad1:	d3 e7                	shl    %cl,%edi
f0101ad3:	89 f2                	mov    %esi,%edx
f0101ad5:	f7 75 f4             	divl   -0xc(%ebp)
f0101ad8:	89 d6                	mov    %edx,%esi
f0101ada:	f7 65 e8             	mull   -0x18(%ebp)
f0101add:	39 d6                	cmp    %edx,%esi
f0101adf:	72 2b                	jb     f0101b0c <__umoddi3+0x11c>
f0101ae1:	39 c7                	cmp    %eax,%edi
f0101ae3:	72 23                	jb     f0101b08 <__umoddi3+0x118>
f0101ae5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101ae9:	29 c7                	sub    %eax,%edi
f0101aeb:	19 d6                	sbb    %edx,%esi
f0101aed:	89 f0                	mov    %esi,%eax
f0101aef:	89 f2                	mov    %esi,%edx
f0101af1:	d3 ef                	shr    %cl,%edi
f0101af3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101af7:	d3 e0                	shl    %cl,%eax
f0101af9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101afd:	09 f8                	or     %edi,%eax
f0101aff:	d3 ea                	shr    %cl,%edx
f0101b01:	83 c4 20             	add    $0x20,%esp
f0101b04:	5e                   	pop    %esi
f0101b05:	5f                   	pop    %edi
f0101b06:	5d                   	pop    %ebp
f0101b07:	c3                   	ret    
f0101b08:	39 d6                	cmp    %edx,%esi
f0101b0a:	75 d9                	jne    f0101ae5 <__umoddi3+0xf5>
f0101b0c:	2b 45 e8             	sub    -0x18(%ebp),%eax
f0101b0f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f0101b12:	eb d1                	jmp    f0101ae5 <__umoddi3+0xf5>
f0101b14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b18:	39 f2                	cmp    %esi,%edx
f0101b1a:	0f 82 18 ff ff ff    	jb     f0101a38 <__umoddi3+0x48>
f0101b20:	e9 1d ff ff ff       	jmp    f0101a42 <__umoddi3+0x52>
