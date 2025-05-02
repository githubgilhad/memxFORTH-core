/* vim: set ft=cpp noexpandtab fileencoding=utf-8 nomodified wrap textwidth=0 foldmethod=marker foldmarker={{{,}}} foldcolumn=4 ruler showcmd lcs=tab\:|- list: tabstop=8 linebreak showbreak=»\   */
// ,,g = gcc, exactly one space after "set"
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
// #include "4.test.0001.def"
#include "flags.h"
#include "ptr24.h"
#include "io.h"
#include "debug.h"
extern uint8_t B1at(uint32_t p);			// asm.S	read 1 byte at address p (somewhere), return 1 byte
extern uint16_t B2at(uint32_t p);			// asm.S	read 2 bytes at address p (somewhere), return 2 bytes
extern uint32_t B3at(uint32_t p);			// asm.S	read 3 bytes at address p (somewhere), return 4 bytes (top cleared)
extern const __memx void * B3PTR(uint32_t p);		// asm.S	typecast, get 3 bytes, return 4 bytes (top cleared)
extern uint32_t B3U32(const __memx void * p);		// asm.S	typecast, get 3 bytes, return 4 bytes (top cleared)
extern void jmp_indirect_24(uint32_t p);		// asm.S	call function, which byte_address is at address p (somewhere) (converts bytes to words)

/*
 * Decision:
 * 	cell = uint16_t
 * 	pointer = uint32_t, but only 3B used, 4.B always zero
 */

_Static_assert(sizeof(uint32_t) == 4, "uint32_t must be 32 bits");
_Static_assert(sizeof(const __memx void *) == 3, "const __memx void * must be 24 bits");

/** {{{ Intro
 * Lets start programming FORTH
 * My idea is 
 * 	* Indirect Threading
 * 	* long names for words 
 * 		* well, possibly more than just 3 (of nano Forth)
 * 		* strictly less then 32 (so Pascal Length can be found backward)
 * 		* only ASCII chars allowed (from space=0x20 upt to tilda=0x7F)
 * 		* 
 * 	* some FORTH words will be in FLASH
 * 		* so 3+ bytes pointers are needed
 * 		* 3 bytes pointers are problematic and __memx is tricky, so let use uint32_t instead and few asm utils
 * the header is divided into two parts, first is for dictionary, followed second, which is for runing words
 * C discourse
 * 	* first we need 3bytes pointer to something
 * 		* it will be memory, but maybe RAM, maybe FLASH
 * 		* it will be
 * 			* byte in memory - uint8_t (just the memory itself after all)
 * 			* 3bytes pointer in memory (usually pointer to some other word)
 * 			* const char (for easy string manipulation)
 * 			* 3B pointer to function in FLASH (well it could be 2B on 328, but not on 2560, and we will use it together with other 3B pointers, so make ++/-- easy)
 * 			* anything else, which can be (type casted) at will
 * */ // }}}
/*
typedef const __memx void(*CodeWord_t)();	// CodeWord_t is 2B pointer to function (in FLASH) (*CodeWord_t)() calls the function.
typedef const __memx CodeWord_t (*Data_t);	// Data_t is 3B pointer to CodeWord_t "somewhere"
typedef const __memx Data_t (* InstrPoint_t);	// InstrPoint_t is 3B pointer to Data_t "somewhere"
typedef void const __memx *PTR_t;	// universal 3B pointer to any data "somewhere"
typedef uint16_t CELL_t;	// cell on data stack 2B

typedef const __memx char *xpC;	// 3B pointer 1B target	pointer "somewhere" to char "somewhere"
typedef const __memx uint8_t *xpB;	// 3B pointer 1B target	pointer "somewhere" to byte "somewhere"
typedef const __memx uint32_t *xpD;


typedef struct head1_t {	// {{{
	const __memx struct head1_t *next;		// 3B: pointer to next header "somewhere"
	uint8_t fill; // to 4B pointer
	uint8_t flags;		// 1B: 
	uint8_t len;		// 1B: up to 31 (=5bits)
	const char name[];	// len B:name of WORD
} head1_t;	// }}}
typedef const __memx head1_t	*xpHead1;	// 3B pointer to head1 "somewhere"
*/
/*
 * typedef struct head2 {	// {{{
 * 	CodeWord_t codepoint;	// 3B: pointer to function to interpret data
 * 	Data_t data[];	// 3B: pointer to 2B pointer "somewhere" to function to interpret data - pointer to head2 "somewhere"
 * 	} head2;	// }}}
 */

typedef const __memx void(*CodeWord_t)();	// CodeWord_t is 2B pointer to function (in FLASH) (*CodeWord_t)() calls the function.
typedef const __memx CodeWord_t (*Data_t);	// Data_t is 3B pointer to CodeWord_t "somewhere"
typedef const __memx char *xpC;	// 3B pointer 1B target	pointer "somewhere" to char "somewhere"
typedef struct head1_t {	// {{{
	const __memx struct head1_t *next;		// 3B: pointer to next header "somewhere"
	uint8_t fill; // to 4B pointer
	uint8_t flags;		// 1B: 
	uint8_t len;		// 1B: up to 31 (=5bits)
	const char name[];	// len B:name of WORD
} head1_t;	// }}}
typedef const __memx head1_t	*xpHead1;	// 3B pointer to head1 "somewhere"


typedef uint32_t PTR_t; 	// universal "3B pointer" to any data "somewhere" - use B1at, B3at for dereferencing
typedef uint16_t CELL_t;	// cell on data stack 2B
typedef uint8_t  BYTE_t;	// something for pointers to points to

PTR_t		IP;	// pointer to element of data[], which should be next
PTR_t		DT;	// NEXT is **(IP++)() - so DT=*IP as internal step. DT is value of last data pointed by IP before NEXT (= address of codepoint to exec) (used by f_docol to know, from where it was called) -  f_docol= { Rpush(IP);IP=DT + x; NEXT} x=sizeof(codeword)
/*
 * STACKS:
 *   for now I will use array and index, as it is easy to check range and only pop/push should be affected
 *   also lets start with small value, so it can be tested for both under- and over- flow
 *   also let push grow up and pop go down and 0 is empty stack (so push(x){stck[stack++]=x;}
 */
#define STACK_LEN	10
#define RSTACK_LEN	10
CELL_t		stck[STACK_LEN];
uint16_t	stack=0;
PTR_t		Rstck[RSTACK_LEN];
uint16_t	Rstack=0;

/*
 * RAM:
 * now let it be just small array too
 * and test it until all works
 */
#define RAM_LEN 	100	// word ~ 10B + name + 4 * words called - for start some 5 words should be enought
uint8_t RAM[RAM_LEN];
uint8_t *HERE=&RAM[0];

/*
 * LAST
 * pointer to begin of last header
 */
PTR_t LAST;

extern const __memx BYTE_t		top_head;	// pointer to last header in asm module
extern const __memx BYTE_t		w_lit_cw;
extern const __memx BYTE_t		w_quit_cw;
extern const __memx BYTE_t		w_double;
extern const __memx char w_test_data;
extern const __memx char w_quit_data;

#define NEXT f_next()
void f_next(){
	info("f_next");
	DT=B3at(IP);
debug_dump(IP,"IP old	");
//	error("Press ANY key to continue");
//	wait_for_char();
	IP+=4;		// IP++ but 4 bytes everytime 
debug_dump(IP,"IP new	");
debug_dump(DT,"DT new	");
debug_dump(B3at(DT),"*DT	");
	jmp_indirect_24(DT);
}

// {{{ pop
CELL_t pop() {
	if (stack==0) {
		error(F("pop - Stack underflow"));
		return 0;
		};
	write_hex16(stck[stack-1]);
	info("pop");
	return stck[--stack];
}
void push(CELL_t x) {
	write_hex16(x);
	info("push");
	if(stack>STACK_LEN-1) {
		error(F("push - Stack owerlow"));
		return;
		};
	stck[stack++]=x;
}
CELL_t peek(){
	if (stack==0) {
		error(F("peek - No Stack left"));
		return 0;
		};
	write_hex16(stck[stack-1]);
	info("peek");
	return stck[stack-1];
}
// }}}
// {{{ pop
PTR_t Rpop() {
	if (Rstack==0) {
		error(F("Rpop - Stack underflow"));
		return 0;
		};
	write_hex32(Rstck[Rstack-1]);
	info("Rpop");
	return Rstck[--Rstack];
}
void Rpush(PTR_t x) {
	write_hex32(x);
	info("Rpush");
	if(Rstack>RSTACK_LEN-1) {
		error(F("Rpush - Stack owerlow"));
		return;
		};
	Rstck[Rstack++]=x;
}
PTR_t Rpeek(){
	if (Rstack==0) {
		error(F("Rpeek - No Stack left"));
		return 0;
		};
	write_hex32(Rstck[Rstack-1]);
	info("Rpeek");
	return Rstck[Rstack-1];
}
// }}}
// {{{ some internal functions
uint8_t word_buf_len=0;
char word_buf[32];
void get_word(){	 // {{{ WAITS for word and puts it into word_buf_len + word_buf
	uint8_t i=0;
	char c=' ';
	while (true){
		while (strchr(" \t\r\n",c)) c=wait_for_char();			// skip spaces
		if (c=='\\') { 
			while (!strchr("\r\n",c)) c=wait_for_char();
			continue;
			};	// skip \ comments to the end of line
		break;};	// finally word begins
	while ((!strchr(" \t\r\n",c)) && (i<sizeof(word_buf)-1)) {word_buf[i++]=c;c=wait_for_char();};
	word_buf[i]=0;
	word_buf_len=i;
}	// }}}
xpHead1 findHead(uint8_t len,const char *wordname, xpHead1 h) { 	// {{{
	len &= FLG_NOFLAG;
	if (len==0) return NULL;
	while (h) {	// internally it ends on .long 0
		if (h->flags & FLG_HIDDEN) { h=h->next;continue;};
		if (h->len != len) { h=h->next;continue;};
		const char *c=wordname;
		xpC hc=&(h->name[0]);
		int16_t l=len;
		while (l--) if(*c++!=*hc++) { break;};
		if (l==-1) return h;
		h=h->next;
	}
	return NULL;
}	// }}}
uint32_t get_codeword_addr(xpHead1 h){	 // {{{ // Data_t
	xpC c=&h->name[h->len];
	return B3U32(c);
}	// }}}
// }}}


#define VARfn(name)	void push_var_##name(){push(0x80);push((CELL_t)((uint16_t)(&name)));NEXT;}
#define VAR(name,value)	CELL_t name=(CELL_t)value;VARfn(name)
#define CONST(name,value)	void push_const_##name(){push(value); NEXT;}

typedef enum { st_executing, st_compiling} st_STATE;
VARfn(LAST)	// LAST is in RAM, just points "somewhere"
st_STATE STATE=st_executing;
VARfn(STATE)
//uint8_t *HERE;
VARfn(HERE)
VAR(BASE,10)
// {{{ dup, plus, ...
void f_dup(){	// {{{
	info(F("f_dup"));
	push(peek());
	NEXT;
}	// }}}
void f_plus(){	// {{{
	info(F("f_plus"));
	push(pop()+pop());
	NEXT;
}	// }}}
// }}}
void f_key(){	 // {{{ WAITS for char and puts it on stack
	push(wait_for_char());
	NEXT;
}	// }}}
void f_word() {	 // {{{ Put address and size of buff to stack
	get_word();
	push((CELL_t)&word_buf);
	push(word_buf_len);
	NEXT;
}	// }}}
void f_docol() {	// {{{
	info(F("f_docol"));
//	track("f_docol ");
// error("Press ANY key to continue");wait_for_char();
	Rpush(IP);
	IP=DT+4;	// README: DT points to 4B codeword, so next address is DT+4B and now it is on Data[0] in the target header
	debug_dump(IP,"IP in f_docol	");
	debug_dump(DT,"DT in f_docol	");
	NEXT;
}	// }}}
void f_exit(){	// {{{
	info("f_exit");
	IP=Rpop();
	NEXT;
}	// }}}
void f_lit(){	// {{{ README: LIT takes the next 4B pointer as 2B integer, ignores the top byte. This is done for taking the same 4B alingment in data
	info(F("f_lit"));
	push(B2at(IP));
	IP+=4;
	NEXT;
}	// }}}
void comma(uint32_t d) {	// {{{
	info(F("comma"));
	*(uint32_t*)HERE=d;
	HERE+=4;
}	// }}}
/*
void comma(Data_t d) {	// {{{
	info(F("comma"));
	*(Data_t*)HERE=d;
	HERE+=4;
}	// }}}
*/
void f_comma() {	// {{{ take 3B address (2 CELLs) from datastack and put it to HERE
	info(F("f_comma"));
	CELL_t c=pop();
	*(CELL_t *)HERE=c;
	HERE+=2;
	c=pop();
	*(CELL_t *)HERE=c;
	HERE+=2;
	NEXT;
}	// }}}
void f_dot() { 	 // {{{
	info(F("f_dot"));
	CELL_t c=pop();
	char buf[32];
	itoa(c, buf, BASE);
	write_str(&buf[0]);
	NEXT;
}	// }}}
void f_number() {	// {{{ (addr n -- val rest ) rest= #neprevedenych znaku
	info(F("f_number"));
	CELL_t i=pop();
	char *buf=(char *)pop();
	char *end;CELL_t c=strtoul(buf,&end,BASE);
	push(c);push(i-(end-buf));
	NEXT;
}	// }}}
void f_branch(){ 	 // {{{
	info(F("f_branch"));
	int16_t c=B2at(IP);
	int32_t cc=4*c;
	IP+=cc;
	NEXT;
}	// }}}
void f_interpret(){	 // {{{
	info(F("f_interpret"));
	write_str("?> ");
	get_word();
	info(" got: ");info(&word_buf[0]);
	xpHead1 h=findHead(word_buf_len,&word_buf[0],B3PTR(LAST));
//	write_str(" head found? ");
//	debug_dump((cmvp)h,"head?");
	if (h!=NULL) { // WORD
//		write_str("yes");
		if ((STATE==st_executing) || (h->len & FLG_IMMEDIATE)) {
			jmp_indirect_24(get_codeword_addr(h));
		} else {
			comma(get_codeword_addr(h));
		};
	} else {
		// Number ?
//		write_str("no");
		char *end;CELL_t c=strtoul(&word_buf[0],&end,BASE);
		if((word_buf_len-(end-&word_buf[0])) ==0) {
			// it is number (c)
			if (STATE==st_executing) {
				push(c);
			} else {
				comma(B3U32(&w_lit_cw));
//				comma((Data_t)(char *)c);	// README: overtype from 2B data - 2B pointer - 3B pointer works
				comma(c);	// README: overtype from 2B data - 2B pointer - 3B pointer works
			};
		} else {
			// it is not
			error("What is this?");error(&word_buf[0]);
		}
	info("end of f_interpret");
	NEXT;
	};
	
	// XXX
}	// }}}
void f_debug(void) {	// {{{ // === f_debug: return from FOTH or what ===
	error(F("f_debug"));
	// f_next();	// No, simply no, return back to caler ...
}	// }}}
void print_words(void) {	// {{{ // === print all wocabulary
	error(F("print_words"));
	xpHead1 h=B3PTR(LAST);
	while (h) {
//write_str(F("\r\n\r\n\r\n"));
//		debug_dump(h,F("h	"));
//write_str(F("\r\n\r\n\r\n"));
		if (h->flags & FLG_HIDDEN) write_str(F(CLR_GREY));
		for (uint8_t i = 0; i < h->len; ++i) write_char(h->name[i]);
		if (h->flags & FLG_HIDDEN) write_str(F(CLR_RESET));
		write_char(' ');
		h= h->next;
		};
	write_eoln();
	error(F("print_words out"));
}	// }}}
void f_words(void) {	// {{{ print all words
	error(F("f_words"));
	print_words();
	NEXT;
}	// }}}

const __flash char f_words_name[]="WORDS";
void my_setup(){	// {{{
	nodebug=false;
	RAM[0]='>';
	RAM[1]='>';
	RAM[2]='>';
	LAST=B3U32(&top_head);
//	findHead(1,".",top_head);
	error("Test");
	uint32_t temp_h=B3U32(HERE);
	*(uint32_t*)HERE=LAST; HERE+=4;		// 3B next ptr
	*(uint8_t*)HERE++ =0;			// 1B attr
	uint8_t len=strlen_P(f_words_name);
	*(uint8_t*)HERE++ =len;				// 1B len "words"
	strcpy_P((char*)HERE,f_words_name); HERE+=len;// len Bytes (+\0, but we overwrite it next step)
	uint16_t cw=(uint16_t)&f_words;
	*(uint32_t*)HERE=cw * 2; HERE+=4;	// codeword
	LAST=temp_h;
	/*
	xpC ac;
	ac=(xpC)0x00015B;
	write_hex24((uint32_t)ac);
	for (int i=0;i<16;i++) {write_hex24((uint32_t)ac);write_char(':');write_hex8(*ac);write_char(' ');write_charA(*ac++);write_str("\r\n");};
	ac=(xpC)0x80015B;
	write_hex24((uint32_t)ac);
	for (int i=0;i<16;i++) {write_hex24((uint32_t)ac);write_char(':');write_hex8(*ac);write_char(' ');write_charA(*ac++);write_str("\r\n");};
	*/
	/*
	debug_dump((cmvp)0x000253,"konec primitiv");
	error("Zaciname");
	write_eoln();
	CodeWord_t const __memx *cp=&w_quit_cw;
	debug_dump((cmvp)cp,"cp");
	Data_t const __memx *dt=&cp;
	debug_dump((cmvp)dt,"dt");
	IP=&dt;
	write_str(" IP= ");
	write_hex24(p24u32((cmvp)IP));
	write_str(" *IP= ");
	write_hex(p24u32((cmvp)*IP));
	write_str(" **IP= ");
	write_hex(p24u32((cmvp)**IP));
	write_str("\r\n");
debug_dump(stack,"stack");
debug_dump(&w_double,"&w_double");
debug_dump(&top_head,"&top_head");
debug_dump(&w_quit_cw,"&w_quit_cw");
debug_dump(&w_lit_cw,"&w_lit_cw");
debug_dump(f_docol,"f_docol");
debug_dump(u32p24(2*p24u32((cmvp)f_docol)),"2*f_docol");
	debug_dump(&w_quit_cw,"&w_quit_cw");
	debug_dump(&w_lit_cw,"&w_lit_cw");
	debug_dump(IP,"IP");
	debug_dump(*IP,"*IP");
//	debug_dump(**IP,"**IP");
	debug_dump(f_interpret,"f_interpret");
	debug_dump(dt,"dt");
	debug_dump(*dt,"*dt");
//	while(true){write_char(wait_for_char());write_str("cau ");};
	//f_interpret();
	error("sem jeste jo ");
	const __memx void *start=&w_quit_cw;
	IP=(cmvp)&start;
	NEXT;
	*/
	debug_dump(B3U32(&RAM[0]),"RAM	");
	debug_dump(B3U32(HERE),"HERE	");
	debug_dump(LAST,"LAST	");
	error(F("my_setup"));
	IP = B3U32(&w_test_data);
//	IP=V(IP);
	debug_dump(IP,F("IP\t"));
	debug_dump(B3U32(&f_docol),"&f_docol");
	push(0x21);
	print_words();
	NEXT;
	pop();
	error(F("Full run"));
	IP = B3U32(&w_quit_data);
//	IP=V(IP);
	debug_dump(IP,F("IP\t"));
	debug_dump(B3U32(&f_docol),"&f_docol");
	Rpush(IP);
	IP=B3U32(&f_docol);
	debug_dump(IP,"(cmvp)&f_docol");
	IP=Rpop();
	
	NEXT;
	error(F("the end"));
	while(1){;};

};	// }}}
void my_loop(){	// {{{
};// }}}
