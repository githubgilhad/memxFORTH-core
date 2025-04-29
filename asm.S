/* vim: set ft=asm noexpandtab fileencoding=utf-8 nomodified wrap textwidth=0 foldmethod=marker foldmarker={{{,}}} foldcolumn=4 ruler showcmd lcs=tab\:|- list: tabstop=8 linebreak showbreak=»\   */
// ,,g = gcc, exactly one space after "set"
#include "flags.h"
	.section .text

	.global here
here:
	.ascii "<###"
	.global RETX_0
RETX_0:
	ret
.macro FLASH_PTR addr	; {{{
	.word \addr
	.byte 0x00	; if this is 0x80+ (7.bit set) it is RAM, else it is FLASH
.endm	; }}}
.macro DEFWORD lbl, attr, name, codeword	; {{{
	.global \lbl
	.global \lbl\()_head
\lbl\():
\lbl\()_head:
	FLASH_PTR 1b-3	; prev header
1:
	.byte  \attr	; attributes
	.byte len\@ 	; name len 
	name_start_\@:
	.ascii "\name"				; name without \0
	.equ len\@,(. - name_start_\@)
	
	.global \lbl\()_cw
\lbl\()_cw:
	.extern \codeword
	FLASH_PTR \codeword				; 3B address of function in FLASH
	.global \lbl\()_data
\lbl\()_data:
	; more payload may be outside macro
.endm	; }}}
.macro DEFVAR name	; {{{
	DEFWORD var_\name,0,"\name",push_var_\name
.endm	; }}}
.macro DEFCONST name	; {{{
	DEFWORD const_\name,0,"\name",push_const_\name
.endm	; }}}

;;;; trick for STOP value for search: 0.header with none data
	.byte 0,0,0 ; prev header none
1:
	.byte 0+FLG_HIDDEN ;len 0 + FLG_HIDDEN = impossible to find
	FLASH_PTR  0		; emty codeword

;;;; word definitions

DEFVAR LAST
DEFVAR STATE
DEFVAR BASE
;DEFCONST DOCOL
DEFWORD w_lit, 0, "LIT", f_lit
;DEFWORD w_docol,0,"DOCOL",f_docol
;DEFWORD w_semicol,0,";",f_semicol
DEFWORD w_dup, 0, "DUP", f_dup
DEFWORD w_plus,0, "+", f_plus
DEFWORD w_exit, 0, "EXIT", f_exit
DEFWORD w_key,0, "KEY", f_key
DEFWORD w_word,0,"WORD",f_word
DEFWORD w_comma,0,",",f_comma
DEFWORD w_number,0,"NUMBER",f_number
DEFWORD w_dot,0,".",f_dot
DEFWORD w_branch,0,"BRANCH",f_branch
DEFWORD w_interpret,0,"INTERPRET",f_interpret
DEFWORD w_quit,0,"QUIT",f_docol
	FLASH_PTR w_interpret_cw
	FLASH_PTR w_branch_cw
	FLASH_PTR -2
DEFWORD w_double, 0, "DOUBLE", f_docol
	FLASH_PTR w_dup_cw
	FLASH_PTR w_plus_cw
	FLASH_PTR w_exit_cw
DEFWORD w_trouble, FLG_HIDDEN + FLG_IMMEDIATE, "TROUBLE", f_plus
DEFWORD w_debug, 0, "DEBUG", f_debug	; primitivum, kde se opet zmocnim vlady
DEFWORD w_test, 0, "TEST", f_docol
	FLASH_PTR w_double_cw
	FLASH_PTR w_debug_cw
	FLASH_PTR w_exit_cw

	.global top_head
	.EQU	top_head,1b-3

.balign 2
	.ascii "###>"
	.global end
end:
