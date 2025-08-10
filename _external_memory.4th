\ A=data, C,F addr
: em ( set EM for playing ) 	0 DDRA C! 0 PINA C! 0 DDRC C! 0 PORTC C! 3F DDRG C! 3F PORTG C! ff DDRF C! 0 PORTF C! ff DDRK C! ;
: dd ( drop 5 ) 		DROP2 DROP2 DROP ;

: / ( -- ) 	( show PINs A C G )  PINA C@ . BL EMIT PINC C@ . BL EMIT PINF C@ . BL EMIT PING C@ . ;
: w ( b -- ) 	( write b to EM ) ff DDRA C! PORTA C! bit0 PING C! / BL EMIT bit0 PING C! 0 DDRA C! 0 PORTA C! / ;
: r ( -- ) 	( read actual memory )  bit1 PING C! / bit1 PING C! ;
\ : l ( a -- ) 	( latch a to DLatch ) ff DDRA C! PORTA C!  bit2 PING C! bit2 PING C!  0 DDRA C! 0 PORTA C! / ;
