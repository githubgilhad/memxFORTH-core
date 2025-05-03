/* vim: set noexpandtab fileencoding=utf-8 nomodified wrap textwidth=0 foldmethod=marker foldmarker={{{,}}} foldcolumn=4 ruler showcmd lcs=tab\:|- list: tabstop=8 linebreak showbreak=»\  ft=cpp */
// ,,g = gcc, exactly one space after "set"

#include <Arduino.h>
#include "version.h"
//	 µFORTH
extern "C" {
	extern void my_setup();
	extern void my_loop();
	char read_char() {
		if (Serial.available()) {
			return Serial.read();
		} else {
			return 0;
		}
	}

	void write_char(char c) {
		Serial.write(c);
	}
	void write_charA(char c) {
		Serial.write(c < ' ' ? '.' : c);
	}
}
void setup(){
	Serial.begin(115200); //
	while (!Serial){;};
	Serial.println(F("1234567890."));
	Serial.println(F(VERSION_STRING ));
	Serial.println(F("  based on " VERSION_COMMIT " - " VERSION_MESSAGE ));
	Serial.println(F("---- ==== #### FORTH #### ==== ----"));
	Serial.println(F("Hint: 1 nodebug 1 noinfo LAST D@ 20 + dump "));
#if defined(__AVR_ATmega2560__)
	Serial.println(F("Hint: hex ff DRDF !C aa PINF !C : x ff  PINF !C ; x "));
#endif
	Serial.println(F("Test: : xx 0BRANCH [ 0 2 , ] 5 ; : xxx IF 1111 ELSE 2222 FI 3333 + ;")); 

	my_setup();
	Serial.println(F("Setup done"));
}

void loop(){
	write_char(read_char());
	my_loop();
}
