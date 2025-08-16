\ A=data, C,F addr
hex
: em ( set EM for playing ) 	0 DDRA C! 0 PINA C! 0 DDRC C! 0 PORTC C! 3F DDRG C! 3F PORTG C! ff DDRF C! 0 PORTF C! ff DDRK C! ;
: dd ( drop 5 ) 		DROP2 DROP2 DROP ;

: LN 0d 0a EMIT EMIT ;
: CO ( corutines - cool word http://forum.6502.org/viewtopic.php?p=82648#p82648 ) R>D R>D SWAP2 D>R D>R ;
: RB ( -- ) ( Restore Base ) R>D BASE @ >R D>R ( base under return address )  CO ( rest after callers exit) R>  BASE ! ; 
: / ( -- ) 	( show PINs A C G ) RB  LN ." A:" DDRA C@ DUP 0= IF ." R " DROP ELSE DUP ff = IF ." W " DROP ELSE ." ?(" bin . ." ) " THEN THEN  ." 0b" PINA C@ DUP bin . SPACE hex .  ." h; C:" DDRC C@ DUP 0= IF ." R " DROP ELSE DUP ff = IF ." W " DROP ELSE ." ?(" bin . ." ) " THEN THEN  ." 0b" PINC C@ DUP bin . SPACE hex .  ." h; G:  0b" PING C@ DUP DUP2 DUP2 bin . SPACE hex .  ." h " bit3 AND IF ." A16=1 " ELSE ." A16=0 " THEN bit2 AND IF ." Latch=1 (follow) " ELSE ." Latch=0 (keep) " THEN bit1 AND IF ." RamRead=1 (blocked) " ELSE ." RamRead=0 (enabled) " THEN bit0 AND IF ." RamWrite=1 (blocked) " ELSE ." RamWrite=0 (writing) " THEN  ;

\ : / ( -- ) 	( show PINs A C G )  PINA C@ . SPACE PINC C@ . SPACE PINF C@ . SPACE PING C@ . ;


: setG ( value bit -- ) SWAP IF DUP ELSE 0 THEN ( bit norm_value )  OVER ( bvb ) PING C@ AND ( bv?) <> ( bf ) IF PING C! ELSE DROP THEN / ;
: xa16 bit3 setG ;
: xl bit2 setG ;
: xr bit1 setG ;
: xw bit0 setG ;

: xxa16 bit3 PING C! / ;
: xxl bit2 PING C! / ;
: xxr bit1 PING C! / ;
: xxw bit0 PING C! / ;
: >A ff DDRA C! PORTA C! / ;
: >C ff DDRC C! PORTC C! / ;


: w ( b -- ) 	( write b to EM ) ff DDRA C! PORTA C! 0 xw  / 1 xw 0 DDRA C! 0 PORTA C! / ;
: r ( -- ) 	( read actual memory )  0 xr  / 1 xr  ;
: l ( a -- ) 	( latch a to DLatch ) ff DDRA C! PORTA C!  1 xl 0 xl  0 DDRA C! 0 PORTA C! / ;
