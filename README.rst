
.. image:: MemxFORTHChipandColorfulStack.png
	:width: 250
	:target: MemxFORTHChipandColorfulStack.png

memxFORTH-core
==============

A minimal Forth-like core for AVR (ATmega328P), designed to experiment with unified RAM and FLASH word handling
using `__memx` pointers in C. This project should result in small tool for pin manipulation on both atmega328P and atmega2560.
Based on `memxFORTH-init <https://github.com/githubgilhad/memxFORTH-init>`__

Project Goals
-------------
- Unified handling of dictionary words in both RAM and FLASH
- Explore low-footprint interpreter design in C
- Use `__memx` for flexible word list chaining and execution
- Small tool for HW testing - mainly pin manipulation
- Targets: atmega328P and atmega2560


Current Features
----------------
- Dictionary traversal using `__memx` pointers / uint32_t
- Execution of basic hardcoded words in FLASH and RAM
- Basic words for building new words ( : ; CREATE )
- Basic structures ( IF ELSE THEN FI )
- debugging tools ( dump show noinfo nodebug )
- PORTx, PINx, DDRx for all x on platform
- Modular, small codebase suitable for embedded hardware debugging
- Uses C and AVR-GCC (also Arduino IDE compatible)

Build
-----

Compile as usual with `avr-gcc`, tested on ATmega328P.

**Arduino IDE:**

- Open `memxFORTH-core.ino`
- Select "Arduino Nano" with ATmega328P
- Upload as usual

Usage
-----
- Developed for ANSI terminal on a wide monitor
- Serial speed: 115200 baud
- Colors can be disabled in **colors.h**
- After upload, the program:
  - Show some hints for copy-paste
  - Runs internal test on DOUBLE and show WORDS
  - Run classical loop on INTERPRETER

- This project is attempt to build small usable tool

Interesting words
-----------------
- **show** (xt -- ) "disasseble" a word - ' DOUBLE show
- **dump** (Daddr -- ) dump some memory around given address - LATEST @ 20 - dump
- **ff** ( -- 0xFF ) - constant
- **aa** ( -- 0xAA ) - constant
- **PORTx** **PINx** **DDRx** - A..H on atmega2560 A..C on atmega328P - ff DDRD !C aa PORTD !C ff PINC !C 
- **nodebug** (bool -- ) set debugging prints on(true)/off(false)
- **noinfo** (bool -- ) set info level on(true)/off(false)
- **cw2h** (Dcw -- Dh) convert pointer to codeword to pointer to head
- **bin** **dec** **hex** (--) set BASE to 2 10 16 respectively


Classical words
---------------
- **BRANCH** 0BRANCH - branch, branch if zero - next field is offset in pointer increases - -2=prev instruction, -1=loop(self), 0=crash (jump inside instruction),  +1=nop(next instruction), +2=skip next instruction
- **WORDS2** - WORDS but in RAM
- **ELSE** **THEN** **FI** **IF**  -  THEN is synonymum for FI
- **:** ; 
- **HIDE** (--) \ HIDE WORD hide given word
- **HIDDEN** (Daddr -- ) hide/unhide word at address
- **QUIT** - loops INTERPRETER
- **<=0** <0 >=0 >0 !=0 ==0 - tests
- **IMMEDIATE** (Daddr -- ) make word at address IMMEDIATE
- **'** - "TICK" read next word and push address of its codeword
- **FIND** (str n -- Daddr) find word in vocabulary
- **]** (--) STATE=st_compiling
- **[** (--) STATE=st_executing
- **CREATE** (str n --) create head from WORD result
- **WORDS** (--) print all words. Immediate words have red background, hidden words have grey text.
- **INTERPRET** - read word from input and execute it
- **.** (n -- ) print number
- **NUMBER** (str n -- num bad) decode string for number, return decoded number and count of unconverted chars
- **,** (Daddr--) - "COMMA" put address to \*HERE and increments HERE
- **WORD** (-- str n) read word from input to data stack
- **KEY** (-- c) read character from input
- **EXIT** end words definition

Stack:

- **/4D** (D -- D/4)
- **/2D** (D -- D/2)
- **/D** (D1 D2 -- D1/D2)
- **\*D** (D1 D2 -- D1*D2)
- **-D** (D1 D2 -- D1-D2)
- **+D** (D1 D2 -- D1+D2)
- **SWAP2** (D1 D2 -- D2 D1)
- **DUP2** (D1 -- D1 D1)
- **/4** (n -- n/4)
- **/2** (n -- n/2)
- **/** (n1 n2 -- n1/n2)
- **\*** (n1 n2 -- n1*n2)
- **-** (n1 n2 -- n1-n2)
- **+** (n1 n2 -- n1+n2) 
- **SWAP**  (n1 n2 -- n2 n1) 
- **DUP**  (n1 -- n1 n1) 
- **D@** (Daddr -- D) "DOUBLE AT"
- **C@** (Daddr -- c) "Char AT"
- **@** (Daddr -- n) "AT"
- **!D** (D Daddr --) "SET DOUBLE"
- **!C** (c Daddr --) "SET Char"
- **!** (n Daddr --) "SET"
- **LIT2** (-- D) push next pointer to datastack as DOUBLE
- **LIT** (-- n) push next pointer to datastack as single CELL
- **DOCOL** (-- &f_docol) constant = codeword for words
- **BASE** (-- Daddr) variable = numerical base 
- **STATE** (-- Daddr) variable = STATE
- **LAST** (-- Daddr) variable = start of latest head
- **HERE** (-- Daddr) variable = first unused character in RAM
- **PORTx** **DDRx** **PINx** - addreses for pin manipulation (x=A..L for atmega2560, x=B..C for atmega328P)


License
-------
GPL 2 or GPL 3 - choose the one that suits your needs.

Author
------
Gilhad - 2025
