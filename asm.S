/* vim: set ft=asm showbreak=»\  noexpandtab fileencoding=utf-8 nomodified wrap textwidth=0 foldmethod=marker foldmarker={{{,}}} foldcolumn=4 ruler showcmd lcs=tab\:|- list: tabstop=8 linebreak  */
// ,,g = gcc, exactly one space after "set"
#if defined(__PC__)
	.section .note.GNU-stack,"",@progbits
	.intel_syntax noprefix
#endif

#include "flags.h"
#include "defines.h"
	.section .text

	.global here
here:
	.ascii "<###"
	.global RETX_0
RETX_0:
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega2560__)
	ret
#elif defined(__PC__)
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	ret
#else
	#error "unsupported"
#endif
	.global B3PTR
	.type B3PTR, @function
	.global B3U32
	.type B3U32, @function
	.global B3U32noRAM
	.type B3U32noRAM, @function
B3PTR:
B3U32:
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega2560__)
	clr	r25
	ret
#elif defined(__PC__)
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	ret
#else
	#error "unsupported"
#endif
B3U32noRAM:
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega2560__)
	cbr	r24,0x80
	clr	r25
	ret
#elif defined(__PC__)
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	ret
#else
	#error "unsupported"
#endif
	// extern uint8_t B1at(ptr24_t p);				; {{{
	//	takes pointer somewhere	(24bit/32bit value)
	//	read 1 byte (as __xload_1 does) and return it as uint8_t
	//
	.global B1at
	.type B1at, @function

B1at:
#if defined(__AVR_ATmega328P__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme tři bajty z adresy r22:r24
	movw r30, r22        //# ZL = r22, ZH = r23
	lpm	r25, Z
	sbrc	r24,7
	ld	r25, Z
	mov	r24,r25
	ret
#elif defined(__AVR_ATmega2560__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme tři bajty z adresy r22:r24
	movw r30, r22        //# ZL = r22, ZH = r23
	sbrc	r24,7
	rjmp	1f
	in	r25,0x3b
	out	0x3b,r24
	elpm	r24, Z
	out	0x3b,r25
	ret
1:
	ld	r24, Z
	ret
#elif defined(__PC__)
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	mov eax, [eax]
	and eax, 0xFF
	ret
#else
	#error "B1at  - supported only for ATmega328P and ATmega2560"
#endif
	// }}}
	// extern B2 B2at(ptr24_t p);				; {{{
	//	takes pointer somewhere	(24bit/32bit value)
	//	read 2 bytes (as __xload_2 does) and return it as uint32_t (4.byte cleared)
	//
	.global B2at		//# ptr24_t p=&w_someword_cw; uint32_t cw= B3at(p);
	.type B2at, @function

B2at:
#if defined(__AVR_ATmega328P__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme dva bajty z adresy r22:r24
	movw r30, r22        // ZL = r22, ZH = r23
	sbrc	r24,7
	rjmp	1f
	lpm	r24, Z+
	lpm	r25, Z+
	ret
1:
	ld	r24, Z+
	ld	r25, Z+
	ret
#elif defined(__AVR_ATmega2560__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme dva bajty z adresy r22:r24
	movw r30, r22        //# ZL = r22, ZH = r23
	sbrc	r24,7
	rjmp	1f
	in	r23,0x3b
	out	0x3b,r24
	elpm	r24, Z+
	elpm	r25, Z+
	out	0x3b,r23
	ret
1:
	ld	r24, Z+
	ld	r25, Z+
	ret
#elif defined(__PC__)
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	mov eax, [eax]
	and eax, 0xFFFF
	ret
#else
	#error "B2at  - supported only for ATmega328P and ATmega2560"
#endif
	// }}}
	// extern B3 B3at(ptr24_t p);				; {{{
	//	takes pointer somewhere	(24bit/32bit value)
	//	read 3 bytes (as __xload_3 does) and return it as uint32_t (4.byte cleared)
	//
	.global B3at		// ptr24_t p=&w_someword_cw; uint32_t cw= B3at(p);
	.type B3at, @function

B3at:
#if defined(__AVR_ATmega328P__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme tři bajty z adresy r22:r24
	movw r30, r22        // ZL = r22, ZH = r23
	sbrc	r24,7
	rjmp	1f
	lpm	r22, Z+
	lpm	r23, Z+
	lpm	r24, Z+
	clr	r25
	ret
1:
	ld	r22, Z+
	ld	r23, Z+
	ld	r24, Z+
	clr	r25
	ret
#elif defined(__AVR_ATmega2560__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme tři bajty z adresy r22:r24
	movw r30, r22        // ZL = r22, ZH = r23
	sbrc	r24,7
	rjmp	1f
	in	r25,0x3b
	out	0x3b,r24
	elpm	r22, Z+
	elpm	r23, Z+
	elpm	r24, Z+
	out	0x3b,r25
	clr	r25
	ret
1:
	ld	r22, Z+
	ld	r23, Z+
	ld	r24, Z+
	clr	r25
	ret
#elif defined(__PC__)
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	mov eax, [eax]
	ret
#else
	#error "B3at  - supported only for ATmega328P and ATmega2560"
#endif
	// }}}
	// extern B4 B4at(ptr24_t p);				; {{{
	//	takes pointer somewhere	(24bit/32bit value)
	//	read 4 bytes (as __xload_3 does) and return it as uint32_t
	//
	.global B4at		// ptr24_t p=&w_someword_cw; uint32_t cw= B4at(p);
	.type B4at, @function

B4at:
#if defined(__AVR_ATmega328P__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme čtyři bajty z adresy r22:r24
	movw r30, r22        // ZL = r22, ZH = r23
	sbrc	r24,7
	rjmp	1f
	lpm	r22, Z+
	lpm	r23, Z+
	lpm	r24, Z+
	lpm	r25, Z+
	ret
1:
	ld	r22, Z+
	ld	r23, Z+
	ld	r24, Z+
	ld	r25, Z+
	ret
#elif defined(__AVR_ATmega2560__)
	// Adresa (__memx) je v r24:r22 (r22 = LSB)
	// Vyčteme tři bajty z adresy r22:r24
	movw r30, r22        // ZL = r22, ZH = r23
	sbrc	r24,7
	rjmp	1f
	in	r21,0x3b
	out	0x3b,r24
	elpm	r22, Z+
	elpm	r23, Z+
	elpm	r24, Z+
	elpm	r25, Z+
	out	0x3b,r21
	ret
1:
	ld	r22, Z+
	ld	r23, Z+
	ld	r24, Z+
	ld	r25, Z+
	ret
#elif defined(__PC__)
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	mov eax, [eax]
	ret
#else
	#error "B4at  - supported only for ATmega328P and ATmega2560"
#endif
	// }}}
	// extern void jmp_indirect_24(ptr24_t p);				; {{{
	//	takes pointer to codeword somewhere	(24bit/32bit value)
	//	read the codeword
	//	divide by two (byte address -> word address)
	//	jumps there
	//
	.global jmp_indirect_24		// ptr24_t p=&w_someword_cw; jmp_indirect_24(p);
	.type jmp_indirect_24, @function

jmp_indirect_24:
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega2560__)
	call B3at
	// Dělení 2 (>>1) pro přechod z byte addr na word addr
	lsr r24
	ror r23
	ror r22
#endif
#if defined(__AVR_ATmega328P__)
	// Pushujeme cílovou adresu na zásobník (2 bajty PC pro 328P)
	push r22
	push r23
	ret			// Skok na cílovou adresu
#elif defined(__AVR_ATmega2560__)
	// Pushujeme cílovou adresu na zásobník (3 bajty PC pro 2560)
	push r22
	push r23
	push r24
	ret			// Skok na cílovou adresu
#elif defined(__PC__)
	
	// eax = [esp + 4] = argument ptr
	mov eax, [esp + 4]	// načti argument (ukazatel na uint32_t)
	jmp [eax]
/*
	mov eax, [eax]		// načti hodnotu z toho místa = cílová adresa
	
	add esp, 8		// "ukliď" návratovou adresu ze zásobníku a argument
				// (funkce nikdy nevrací, tak ručně posuň ESP)
	jmp eax			// skok na novou adresu
*/

#else
	#error "jmp_indirect_24  - supported only for ATmega328P and ATmega2560"
#endif
	// }}}
.macro DEFWORD lbl, attr, name, codeword	// {{{
	.global \lbl
	.global \lbl\()_head
\lbl\():
\lbl\()_head:
	.long 1b-4
1:
	.byte  \attr	// attributes
	.byte len\@ 	// name len
	name_start_\@:
	.ascii "\name"				// name without \0
	.equ len\@,(. - name_start_\@)
	
	.global \lbl\()_cw
\lbl\()_cw:
	.extern \codeword
	.long \codeword				// 3B address of function in FLASH
	.global \lbl\()_data
\lbl\()_data:
	// more payload may be outside macro
.endm	// }}}
.macro DEFVAR name	// {{{
	DEFWORD var_\name,0,"\name",push_var_\name
.endm	// }}}
.macro DEFCONST name	// {{{
	DEFWORD const_\name,0,"\name",push_const_\name
.endm	// }}}
.macro DEFCONST1 name, value	// {{{
	DEFWORD const_\name,0,"\name",f_doconst
	.long \value
.endm	// }}}
.macro DEFCONST2 name, value	// {{{
	DEFWORD const_\name,0,"\name",f_doconst2
	.long \value
.endm	// }}}
	//  :s@DEFWORD [^,]*,[^,]*,\s*"\([^"]*\)"\s*,\s*\([^ 	;#/]*\)[^;#/]*\(.*\)@void \2() {	// {{{ \3\r	INFO("\1");\r	\r	NEXT;\r}	// }}}
	// ;;; trick for STOP value for search: 0.header with none data
	.long 0		// prev header none
1:
	.byte FLG_HIDDEN
	.byte 0 //len 0 + FLG_HIDDEN = impossible to find
	// zero bytes of name here
	.long 0		// emty codeword

	// ;;; word definitions
DEFWORD w_firtsbuildinword,0,"firtsbuildinword",f_firtsbuildinword	// ( -- h ) firts build in word - put its header addr on stack

.macro PORT name,value	// {{{
DEFCONST2 PIN\name, 0x800000+\value
DEFCONST2 DDR\name, 0x800001+\value
DEFCONST2 PORT\name, 0x800002+\value
.endm	// }}}
#if OUTPUT_TARGET == OUTPUT_TARGET_vram
DEFCONST2 VRAM, vram
DEFCONST2 CRAM, cram
DEFWORD w_VRAM_yx, 	0,	"VRAM_yx",	f_VRAM_yx	// ( y x -- daddr ) y row, x column, daddr addr in VRAM
#endif
#if defined(__PORTABLE_GRAPHIC__)
DEFCONST1 "MAX_ROWS", MAX_ROWS
DEFCONST1 "MAX_COLS", MAX_COLS
DEFWORD w_CLS, 	0,	"CLS",	f_CLS
DEFWORD w_fetchVRAM_yx,	0,	"VRAM_yx@",	f_fetchVRAM_yx	// ( y x -- c ) y row, x column, c character in VRAM
DEFWORD w_storeVRAM_yx,	0,	"VRAM_yx!",	f_storeVRAM_yx	// ( y x c -- ) y row, x column, c character in VRAM
DEFWORD w_CUR_yx, 	0,	"CUR_yx",	f_CUR_yx	// ( y x -- ) move cursor to  y row, x column
DEFWORD w_KEYpress, 	0,	"KEYpress",	f_KEYpress	// ( -- c ) ascii of pressed key or 0
DEFWORD w_WAIT, 	0,	"WAIT",		f_WAIT		// ( c -- ) wait(c) ~ c * 1/50 s 
#endif
#if defined(__AVR_ATmega328P__)
PORT B, 0x23
PORT C, 0x26
PORT D, 0x29
#elif defined(__AVR_ATmega2560__)
PORT A, 0x20
PORT B, 0x23
PORT C, 0x26
PORT D, 0x29
PORT E, 0x2C
PORT F, 0x2F
PORT G, 0x32
PORT H, 0x100
PORT J, 0x103
PORT K, 0x106
PORT L, 0x109
#elif defined(__PC__)
DEFWORD w_memdump,	0,	"memdump",	f_memdump	// ( daddr len -- ) dump data to file
DEFWORD w_traceback,	0,	"traceback",	f_traceback	// ( daddr len -- ) dump traceback data to file
#endif
DEFCONST1 bit0, 0x01
DEFCONST1 bit1, 0x02
DEFCONST1 bit2, 0x04
DEFCONST1 bit3, 0x08
DEFCONST1 bit4, 0x10
DEFCONST1 bit5, 0x20
DEFCONST1 bit6, 0x40
DEFCONST1 bit7, 0x80
DEFWORD w_dump, 	0,	"dump",	f_dump
DEFWORD w_show, 	0,	"show",	f_show		// ( cw -- ) show  try to show definition of WORD addressed by codeword
DEFWORD w_export, 	0,	"export",	f_export	// ( cw -- ) try to export definition of WORD addressed by codeword for forth2inc.py
DEFWORD w_export_all, 	0,	"export_all",	f_export_all	// (  -- ) try to export definitions of all words for forth2inc.py
DEFWORD w_getword, 	0,	"getword",	f_getword	// ( addr -- h end ) return range of word, in which the addr is
DEFVAR HERE
DEFVAR LAST
DEFVAR STATE
DEFVAR BASE
DEFCONST2 DOCOL,f_docol
DEFCONST2 RAM,RAM
DEFCONST2 RAM_END,RAM+RAM_LEN
DEFCONST2 S0,stck
DEFCONST2 S_END,stck+STACK_LEN*2	// sizeof(CELL_t)
DEFCONST2 R0,Rstck
DEFCONST2 R_END,Rstck+RSTACK_LEN*4	// sizeof(PTR_t)
DEFCONST1 F_IMMEDIATE, FLG_IMMEDIATE
DEFCONST1 F_HIDDEN, FLG_HIDDEN
DEFWORD w_lit,	FLG_ARG,	"LIT",	f_lit
DEFWORD w_lit2,	FLG_ARG,	"LIT2",	f_lit2
DEFWORD w_Store,	0,	"!",	f_Store
DEFWORD w_StoreChar,	0,	"!C",	f_StoreChar
DEFWORD w_StoreDouble,	0,	"!D",	f_StoreDouble
DEFWORD w_CharStore,	0,	"C!",	f_StoreChar
DEFWORD w_DoubleStore,	0,	"D!",	f_StoreDouble
DEFWORD w_At,   	0,	"@",	f_At
DEFWORD w_CharAt,	0,	"C@",	f_CharAt
DEFWORD w_DoubleAt,	0,	"D@",	f_DoubleAt
DEFWORD w_ToR,		0,	">R",	f_ToR		// ( u -- ; R: -- r ) Move to Rstack
DEFWORD w_DoubleToR,	0,	"D>R",	f_DoubleToR	// ( D -- ; R: -- r ) Move Double to Rstack (still one position on R)
DEFWORD w_FromR,	0,	"R>",	f_FromR		// ( -- u ; R: r -- ) Move from Rstack
DEFWORD w_DoubleFromR,	0,	"R>D",	f_DoubleFromR	// ( -- D ; R: r -- ) Move Double from Rstack (still one position on R)
DEFWORD w_CellAtR,	0,	"@R",	f_CellAtR	// ( -- u ; R: r -- r ) Peek from Rstack
DEFWORD w_DoubleAtR,	0,	"D@R",	f_DoubleAtR	// ( -- D ; R: r -- r ) Peek from Rstack
DEFWORD w_StackAddress,	0,	"S?",	f_StackAddress	// ( -- D ) Address, where Stack points
DEFWORD w_SetStack,	0,	"S!",	f_SetStack	// ( D -- ?? ) Set Stack Address
DEFWORD w_RStackAddress,0,	"R?",	f_RStackAddress	// ( -- D ) Address, where Rstack points
DEFWORD w_SetRStack,	0,	"R!",	f_SetRStack	// ( D -- R: ?? ) Set Rstack Address
DEFWORD w_dup,  	0,	"DUP",	f_dup
DEFWORD w_drop, 	0,	"DROP",	f_drop
DEFWORD w_rdrop, 	0,	"RDROP",	f_rdrop	// Drop from Rstack
DEFWORD w_swap, 	0,	"SWAP",	f_swap
DEFWORD w_xor,   	0,	"XOR",	f_xor		// bitwise XOR
DEFWORD w_or,   	0,	"OR",	f_or		// bitwise OR
DEFWORD w_and,  	0,	"AND",	f_and		// bitwise AND
DEFWORD w_Lor,   	0,	"||",	f_Lor		// logical OR
DEFWORD w_Land,  	0,	"&&",	f_Land		// logical AND
DEFWORD w_plus, 	0,	"+",	f_plus
DEFWORD w_minus,	0,	"-",	f_minus
DEFWORD w_times,	0,	"*",	f_times
DEFWORD w_div,  	0,	"/",	f_div
DEFWORD w_div2, 	0,	"/2",	f_div2
DEFWORD w_div4, 	0,	"/4",	f_div4
DEFWORD w_plus21, 	0,	"+21",	f_plus21
DEFWORD w_minus21,	0,	"-21",	f_minus21
DEFWORD w_times21,	0,	"*21",	f_times21
DEFWORD w_div21,  	0,	"/21",	f_div21
DEFWORD w_dup_D,	0,	"DUP2",	f_dup_D
DEFWORD w_dup_3,	0,	"DUP3",	f_dup_3
DEFWORD w_dup_4,	0,	"DUP4",	f_dup_4
DEFWORD w_drop_D,	0,	"DROP2",	f_drop_D
DEFWORD w_swap_D,	0,	"SWAP2",	f_swap_D
DEFWORD w_swap_12,	0,	"SWAP12",	f_swap_12	// ( c d -- d c )
DEFWORD w_swap_21,	0,	"SWAP21",	f_swap_21	// ( d c -- c d )
DEFWORD w_plus_D,	0,	"+D",	f_plus_D
DEFWORD w_minus_D,	0,	"-D",	f_minus_D
DEFWORD w_times_D,	0,	"*D",	f_times_D
DEFWORD w_div_D,	0,	"/D",	f_div_D
DEFWORD w_div2_D,	0,	"/2D",	f_div2_D
DEFWORD w_div4_D,	0,	"/4D",	f_div4_D
DEFWORD w_c2C,  	0,	"c2C",	f_c2C	// cell -> 2 C
DEFWORD w_D4C,  	0,	"D4C",	f_D4C	// Double -> 4C
DEFWORD w_2Cc,  	0,	"2Cc",	f_2Cc	// 2 C -> cell
DEFWORD w_4CD,  	0,	"4CD",	f_4CD	// 4 C -> Double
DEFWORD w_1minus,	0,	"1-",	f_1minus	// decrement TOS by 1
DEFWORD w_4minus,	0,	"4-",	f_4minus	// decrement TOS by 4
DEFWORD w_1Dminus,	0,	"1D-",	f_1Dminus	// decrement Double TOS by 1
DEFWORD w_4Dminus,	0,	"4D-",	f_4Dminus	// decrement Double TOS by 4
DEFWORD w_1plus,	0,	"1+",	f_1plus		// increment TOS by 1
DEFWORD w_4plus,	0,	"4+",	f_4plus		// increment TOS by 4
DEFWORD w_1Dplus,	0,	"1D+",	f_1Dplus	// increment Double TOS by 1
DEFWORD w_4Dplus,	0,	"4D+",	f_4Dplus	// increment Double TOS by 4
DEFWORD w_exit, 	0,	"EXIT",	f_exit
DEFWORD w_return, 	0,	"RETURN",	f_exit	// synonymum EXIT, not detected by show (for exit in middle od WORD)
DEFWORD w_key,  	0,	"KEY",	f_key
DEFWORD w_emit, 	0,	"EMIT",	f_emit
DEFWORD w_word, 	0,	"WORD",	f_word
DEFWORD w_comma,	0,	",",	f_comma
DEFWORD w_number,	0,	"NUMBER",	f_number
DEFWORD w_dot,  	0,	".",	f_dot
DEFWORD w_branch,	FLG_ARG,	"BRANCH",	f_branch
DEFWORD w_0branch,	FLG_ARG,	"0BRANCH",	f_0branch	// branch if zero
DEFWORD w_interpret,	0,	"INTERPRET",	f_interpret
DEFWORD w_words,	0,	"WORDS",	f_words
# -------------------------------------------------------------------------------- tests
DEFWORD w_double, 0, "DOUBLE", f_docol
	.long w_dup_cw
	.long w_plus_cw
	.long w_exit_cw
DEFWORD w_trouble, FLG_HIDDEN + FLG_IMMEDIATE, "TROUBLE", f_docol
	.long w_exit_cw
DEFWORD w_debug, 0, "DEBUG", f_debug	// primitivum, kde se opet zmocnim vlady
DEFWORD w_test, 0, "TEST", f_docol
	.long w_double_cw
	.long w_debug_cw
	.long w_exit_cw
DEFWORD w_nodebug,	0,	"nodebug",	f_nodebug
DEFWORD w_noinfo,	0,	"noinfo",	f_noinfo
DEFWORD w_notrace,	0,	"notrace",	f_notrace
DEFWORD w_hex,  	0,	"hex",	f_hex
DEFWORD w_dec,  	0,	"dec",	f_dec
DEFWORD w_bin,  	0,	"bin",	f_bin
DEFWORD w_cw2h, 	0,	"cw2h",	f_cw2h		// ( cw -- h ) convert codeword address to head address
DEFWORD w_h2cw, 	0,	"h2cw",	f_h2cw		// ( h -- cw ) convert head address to codeword address
DEFWORD w_ToCFA, 	0,	">CFA",	f_h2cw		// ( h -- cw ) convert head address to codeword address
DEFWORD w_h2da, 	0,	"h2da",	f_h2da		// ( h -- da ) convert head address to data address
DEFWORD w_ToDFA, 	0,	">DFA",	f_h2da		// ( h -- da ) convert head address to data address
DEFWORD w_stack,	0,	".s",	f_stack		// ( -- ) nonestructiove print of stack (for debug mainly)
DEFCONST1 ff,	0xFF
DEFCONST1 aa,	0xAA
# -------------------------------------------------------------------------------- more primitives
DEFWORD w_create,	0,	"CREATE",	f_create		// create head from WORD result
DEFWORD w_left_brac,	FLG_IMMEDIATE,	"[",	f_left_brac		// [ goes to immediate mode
DEFWORD w_right_brac,	0,	"]",	f_right_brac			// ] goes to compile mode
DEFWORD w_find, 	0,	"FIND",	f_find				// WORD FIND return Addr_of_header (or 0 0 )
DEFWORD w_hidden,	0,	"HIDDEN",	f_hidden		// Addr_of_header HIDE hide/unhide the word
DEFWORD w_tick, 	FLG_ARG,	"'",	f_tick				// push CW_address of next word to stack (and skip it)
DEFWORD w_immediate,	FLG_IMMEDIATE,	"IMMEDIATE",	f_immediate	//  IMMEDIATE make the  last word immediate
DEFWORD w_zero, 	0,	"0=",	f_zero				// true if zero
DEFWORD w_notzero,  	0,	"0<>",	f_notzero			// true if not zero
DEFWORD w_positive,	0,	"0>",	f_positive			// true if positive
DEFWORD w_positive0,	0,	"0>=",	f_positive0			// true if positive or zero
DEFWORD w_negative,	0,	"0<",	f_negative			// true if negative
DEFWORD w_negative0,	0,	"0<=",	f_negative0			// true if negative or zero
DEFWORD w_notequal, 	0,	"<>",	f_notequal			// (c1 c2 -- flag ) true if not equal
DEFWORD w_notequalD, 	0,	"<>D",	f_notequalD			// (d1 d2 -- flag ) true if not equal
DEFWORD w_equal, 	0,	"=",	f_equal				// (c1 c2 -- flag ) true if equal
DEFWORD w_equalD, 	0,	"=D",	f_equalD			// (d1 d2 -- flag ) true if equal
DEFWORD w_greater, 	0,	">",	f_greater			// (c1 c2 -- flag ) true if greater
DEFWORD w_greaterequal, 0,	">=",	f_greaterequal			// (c1 c2 -- flag ) true if greaterequal
DEFWORD w_less, 	0,	"<",	f_less				// (c1 c2 -- flag ) true if less
DEFWORD w_lessequal, 	0,	"<=",	f_lessequal			// (c1 c2 -- flag ) true if lessequal
DEFWORD w_greaterD, 	0,	">D",	f_greaterD			// (d1 d2 -- flag ) true if greater
DEFWORD w_greaterequalD, 0,	">=D",	f_greaterequalD			// (d1 d2 -- flag ) true if greaterequal
DEFWORD w_lessD, 	0,	"<D",	f_lessD				// (d1 d2 -- flag ) true if less
DEFWORD w_lessequalD, 	0,	"<=D",	f_lessequalD			// (d1 d2 -- flag ) true if lessequal
DEFWORD w_notnull,	0,	"NOTNULL", f_notnull			// (daddr -- flag ) true if daddr is not NULL
DEFWORD w_isnull,	0,	"ISNULL", f_isnull			// (daddr -- flag ) true if daddr is NULL
# ------------------------------------------------------------------------ more FORTH words from jonesforth
DEFWORD w_DIVMOD,	0,	"/MOD",	f_DIVMOD			// ( c1 c2 -- c1/c2 c1%c2 )
DEFWORD w_CHAR,		0,	"CHAR",	f_CHAR				// ( -- C) read one char
DEFWORD w_OVER,	0,	"OVER",	f_OVER			// ( c1 c2 -- c1 c2 c1 )
DEFWORD w_OVER2,	0,	"OVER2",	f_OVER2			// ( d1 d2 -- d1 d2 d1 )
DEFWORD w_OVER12,	0,	"OVER12",	f_OVER12			// ( c1 d2 -- c1 d2 c1 )
DEFWORD w_OVER21,	0,	"OVER21",	f_OVER21			// ( d1 c2 -- d1 c2 d1 )
DEFWORD w_ROT,	0,	"ROT",	f_ROT			// ( c1 c2 c3 -- c2 c3 c1 )
DEFWORD w_NROT, 0,	"-ROT",	f_NROT			// ( c1 c2 c3 -- c3 c1 c2 )
DEFWORD w_ROT4, 	0,	"ROT4",	f_ROT4			// ( c1 c2 c3 c4 -- c2 c3 c4 c1 )
DEFWORD w_NROT4,	0,	"-ROT4",	f_NROT4			// ( c1 c2 c3 c4 -- c4 c1 c2 c3 )
DEFWORD w_QDUP,	0,	"?DUP",	f_QDUP		// duplicate top of stack if non-zero
DEFWORD w_QDUPD,	0,	"?DUP2",	f_QDUPD		// duplicate Double top of stack if non-zero
DEFWORD w_INVERT, 	0,	"INVERT",	f_INVERT	 // this is the FORTH bitwise "NOT" function (cf. NEGATE and NOT)
DEFWORD w_ADDSTORE, 	0,	"+!",	f_ADDSTORE	// ( c Daddr -- ) [Daddr] += c
DEFWORD w_SUBSTORE, 	0,	"-!",	f_SUBSTORE	// ( c Daddr -- ) [Daddr] -= c
DEFWORD w_ADDSTORED, 	0,	"+!D",	f_ADDSTORED	// ( d Daddr -- ) [Daddr] += d Double
DEFWORD w_SUBSTORED, 	0,	"-!D",	f_SUBSTORED	// ( d Daddr -- ) [Daddr] -= d Double
DEFWORD w_CMOVE, 	0,	"CMOVE",	f_CMOVE	// ( saddr daddr len -- ) CharMove (len) from saddr to daddr
DEFWORD w_LITSTRING, 	FLG_PSTRING,	"LITSTRING",	f_LITSTRING	// ( -- daddr len ) push daddr and len of string on the stack - similar to LIT
DEFWORD w_TELL, 	0,	"TELL",	f_TELL			// ( daddr len -- ) prints out string
DEFWORD w_EXECUTE, 	0,	"EXECUTE",	f_EXECUTE	// ( xt -- ) execute xt (&cw)
DEFWORD w_ISINSTR,  	0,	"ISINSTR",	f_ISINSTR	// ( char addr len  -- flag ) if char is in string
DEFWORD w_POS,  	0,	"POS",	f_POS			// ( char addr len  -- (pos) flag ) return flag and if found also zero based position
DEFWORD w_RANDOM,	0,	"RANDOM",	f_RANDOM	// ( max -- rnd ) rnd 0..(max -1)

# -------------------------------------------------------------------------------- more FORTH words

DEFWORD w_quit,0,"QUIT",f_docol // main loop
	.long w_interpret_cw
	.long w_branch_cw
	.long -8
DEFWORD w_colon,0,":",f_docol
	.long w_word_cw, w_create_cw			// create header
	.long w_lit2_cw, f_docol, w_comma_cw		// fill CW
	.long var_LAST_cw, w_DoubleAt_cw, w_hidden_cw	// hide until done
	.long w_right_brac_cw, w_exit_cw		// go to conpile

DEFWORD w_semicol,FLG_IMMEDIATE,";",f_docol
	.long w_lit2_cw, w_exit_cw, w_comma_cw		// end word
	.long var_LAST_cw, w_DoubleAt_cw, w_hidden_cw	// unhide it
	.long w_left_brac_cw, w_exit_cw			// back to immediate

#include "words.inc"
#include "jones.inc"


DEFWORD w_lastbuildinword,0,"lastbuildinword",f_lastbuildinword	// ( -- h ) last build in word - put its header addr on stack
	.global w_lastbuildinword_end
w_lastbuildinword_end:
	.global val_of_w_exit_cw, val_of_f_docol
val_of_w_exit_cw:
	.long w_exit_cw
val_of_f_docol:
	.long f_docol
	.global top_head
#	.EQU	top_head,1b-3
	.EQU	top_head,1b-4

.balign 2
	.ascii "###>"
	.global end
end:
//.balign 65536, 'F'
