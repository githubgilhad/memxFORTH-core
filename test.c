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
_Static_assert(sizeof(uint32_t) == 4, "uint32_t must be 32 bits");
_Static_assert(sizeof(__memx const void *) == 3, "__memx const void * must be 24 bits");

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
 * 		* so 3 bytes pointers are needed
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
typedef void(*CodeWord_t)();	// CodeWord_t is 2B pointer to function (in FLASH) (*CodeWord_t)() calls the function.
typedef __memx const CodeWord_t (*Data_t);	// Data_t is 3B pointer to CodeWord_t "somewhere"
typedef __memx const Data_t (* InstrPoint_t);	// InstrPoint_t is 3B pointer to Data_t "somewhere"
typedef void __memx const *PTR_t;	// universal 3B pointer to any data "somewhere"
typedef uint16_t CELL_t;	// cell on data stack 2B

typedef __memx const char *xpC;	// 3B pointer 1B target	pointer "somewhere" to char "somewhere"
typedef __memx const uint8_t *xpB;	// 3B pointer 1B target	pointer "somewhere" to byte "somewhere"
typedef __memx const uint32_t *xpD;


extern __memx const char w_test_data;
extern __memx const char w_quit_data;
typedef struct head1_t {	// {{{
	__memx const struct head1_t *next;		// 3B: pointer to next header "somewhere"
	uint8_t flags;		// 1B: 
	uint8_t len;		// 1B: up to 31 (=5bits)
	const char name[];	// len B:name of WORD
} head1_t;	// }}}
typedef __memx const head1_t	*xpHead1;	// 3B pointer to head1 "somewhere"
/*
 * typedef struct head2 {	// {{{
 * 	CodeWord_t codepoint;	// 3B: pointer to function to interpret data
 * 	Data_t data[];	// 3B: pointer to 2B pointer "somewhere" to function to interpret data - pointer to head2 "somewhere"
 * 	} head2;	// }}}
 */

const __memx InstrPoint_t		*IP;
const __memx Data_t			*DT;	// Value of last data pointed by IP before NEXT (= address of codepoint to exec) (used by f_docol to know, from where it was called)
#define STACK_LEN	10
#define RAM_LEN 	100	// 8B + name + 3B * (# words in definition)
CELL_t stck[STACK_LEN];
CELL_t *stack=&stck[STACK_LEN];
PTR_t Rstck[STACK_LEN];
PTR_t *Rstack=&Rstck[STACK_LEN];

char RAM[RAM_LEN];
char *HERE=&RAM[0];
CM head1_t *LAST;

extern const __flash xpHead1		top_head;	// pointer to last header in asm module
extern const __flash CodeWord_t		w_lit_cw;
extern const __flash CodeWord_t		w_quit_cw;
extern const __flash xpHead1		w_double;

void track(const __memx char * label) {	 // {{{
	info(label);
	write_str("IP= ");
	write_hex24(p24u32((cmvp)IP));
	write_str(" *IP= ");
	write_hex24(p24u32((cmvp)*IP));
//	write_str(" **IP= ");
//	write_hex24(p24u32((cmvp)**IP));
	write_str(" DT= ");
	write_hex24(p24u32((cmvp)DT));
	write_str(" *DT= ");
	write_hex24(p24u32((cmvp)*DT));
	write_str(" stck[");
	write_hex24(&stck[STACK_LEN]-stack);
	write_str("]= ");
	write_hex24(*stack);
	write_str("\r\n");
debug_dump(IP,"IP	");
//debug_dump(**IP,"**IP	");
debug_dump(DT,"DT	");
debug_dump(*DT,"*DT	");
//debug_dump(**DT,"**DT	");
debug_dump(stack,"stack	");
debug_dump(Rstack,"Rstack	");
}	// }}}
extern void RETX_0();
//	#define NEXT (*(*(*IP++)))()
#define NEXT f_next()
void f_next(){
	info("f_next");
	DT=*IP;
debug_dump(IP,"IP old	");
debug_dump(DT,"DT old	");
//	track("f_next ");
//	error("Press ANY key to continue");
//	RETX_0();
//	wait_for_char();
	asm volatile ("" ::: "memory");
//	__asm__ __volatile__ ("nop");
//	__asm__ __volatile__ ("nop");
	DT=*IP++;
debug_dump(IP,"IP new	");
debug_dump(DT,"DT new	");
debug_dump(*DT,"*DT	");
//	(*(*DT))();
volatile CodeWord_t fx;
fx=u32p24(p24u32(*DT)/2);
//debug_dump((cmvp)fx,"fx");
debug_dump(fx,"fx	");
(*fx)();
//	(*(*(*IP++)))();
}
//	void f_next(){(*(*(*IP++)))();}

// {{{ pop
CELL_t pop() {
	write_hex24(*stack);
	info("pop");
	return *(stack++);
}
void push(CELL_t x) {
	write_hex24(x);
	info("push");
	*(--stack)=x;
}
CELL_t peek(){ return *(stack);}
// }}}
// {{{ Rpop
PTR_t Rpop() {
	write_hex24(p24u32(*Rstack));
	info("Rpop");
	return *(Rstack++);
}
void Rpush(PTR_t x) {
	write_hex24(p24u32(x));
	info("Rpush");
	*(--Rstack)=x;
}
PTR_t Rpeek(){ return *(Rstack);}
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
	// FIXME:
	while (h) {
		if ((h->len & FLG_NOFLAG) != len) { h=h->next;continue;};
		const char *c=wordname;
		xpC hc=&(h->name[0]);
		int16_t l=len;
		while (l--) if(*c++!=*hc++) { break;};
		if (l==-1) return h;
		h=h->next;
	}
	return NULL;
}	// }}}
Data_t get_codeword_addr(xpHead1 h){	 // {{{
	xpC c=&h->name[h->len];
	return (Data_t)c;
}	// }}}
void write_hex(uint16_t i) { 	// {{{
	write_str("0x");
	char buf[32];
	itoa(i, buf, 16);
	write_str(&buf[0]);
}	// }}}
// }}}


#define VARfn(name)	void push_var_##name(){push((CELL_t)&name); NEXT;}
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
	Rpush((PTR_t)IP);
	IP=(cmvp)(DT+1);	// README: DT points to 3B codeword, so DT+1 = DT+3B and now it is on Data[0] in the target header
	debug_dump(IP,"IP in f_docol	");
	debug_dump(DT,"DT in f_docol	");
	NEXT;
}	// }}}
void f_exit(){	// {{{
	info("f_exit");
	IP=(InstrPoint_t  __memx const *)Rpop();
	NEXT;
}	// }}}
void f_lit(){	// {{{ README: LIT takes the next 3B pointer as 2B integer, ignores the top byte. This is done for taking the same 3B alingment in data
	info(F("f_lit"));
	push(*((__memx const CELL_t *)IP));
	++IP;
	NEXT;
}	// }}}
void comma(Data_t d) {	// {{{
	info(F("comma"));
	*(Data_t*)HERE=d;
	HERE+=3;
}	// }}}
void f_comma() {	// {{{ take 3B address (2 CELLs) from datastack and put it to HERE
	info(F("f_comma"));
	CELL_t c=pop();
	*(CELL_t *)HERE=c;
	HERE+=2;
	c=pop();
	*HERE++=c;
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
void f_number() {	// {{{ (addr n -- rest val) rest= #neprevedenych znaku
	info(F("f_number"));
	CELL_t i=pop();
	char *buf=(char *)pop();
	char *end;CELL_t c=strtoul(buf,&end,BASE);
	push(c);push(i-(end-buf));
	NEXT;
}	// }}}
void f_branch(){ 	 // {{{
	info(F("f_branch"));
	int16_t c=*((__memx const int16_t *)IP);
	IP+=c;
	NEXT;
}	// }}}
void f_interpret(){	 // {{{
	info(F("f_interpret"));
	write_str("?> ");
	get_word();
	info(" got: ");info(&word_buf[0]);
	xpHead1 h=findHead(word_buf_len,&word_buf[0],LAST);
//	write_str(" head found? ");
//	debug_dump((cmvp)h,"head?");
	if (h!=NULL) { // WORD
//		write_str("yes");
		Data_t d=get_codeword_addr(h);
		if ((STATE==st_executing) || (h->len & FLG_IMMEDIATE)) {
			CodeWord_t c=u32p24(p24u32(*d)/2);
			debug_dump(c,"c()");
			c();
		} else {
			comma(d);
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
				comma(&w_lit_cw);
				comma((Data_t)(char *)c);	// README: overtype from 2B data - 2B pointer - 3B pointer works
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
	xpHead1 h=LAST;
	while (h) {
//		debug_dump(P24p(h),F("h"));
		if (h->flags & FLG_HIDDEN) write_str(F(CLR_GREY));
		for (uint8_t i = 0; i < h->len; ++i) write_char(h->name[i]);
		if (h->flags & FLG_HIDDEN) write_str(F(CLR_RESET));
		write_char(' ');
		h= h->next;
		};
	write_eoln();
}	// }}}
void f_words(void) {	// {{{ print all words
	error(F("f_words"));
	print_words();
	NEXT;
}	// }}}

const __memx char f_words_name[]="WORDS";
void my_setup(){	// {{{
	LAST=(cmvp)&top_head;
//	findHead(1,".",top_head);
	error("Test");
	xpHead1 temp_h=(xpHead1)HERE;
	*(ptr24_u*)HERE=V(P24p(LAST)); HERE+=3;		// 3B next ptr
	*HERE++=0;				// 1B attr
	uint8_t len=strlen_P(f_words_name);
	*HERE++=len;				// 1B len "words"
	strcpy_P(HERE,f_words_name); HERE+=len;// len Bytes (+\0, but we overwrite it next step)
	*(ptr24_u*)HERE=(ptr24_u){.u32=((uintptr_t)(&f_words)) * 2}; HERE+=3;	// codeword
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
//	nodebug=false;
	error(F("my_setup"));
	IP = (cmvp)&w_test_data;
//	IP=V(IP);
	debug_dump(IP,F("IP\t"));
	debug_dump(&f_docol,"&f_docol");
	push(0x21);
	print_words();
	NEXT;
	pop();
	error(F("Full run"));
	IP = (cmvp)&w_quit_data;
//	IP=V(IP);
	debug_dump(IP,F("IP\t"));
	debug_dump(&f_docol,"&f_docol");
	NEXT;
	error(F("the end"));
	while(1){;};

};	// }}}
void my_loop(){	// {{{
};// }}}
