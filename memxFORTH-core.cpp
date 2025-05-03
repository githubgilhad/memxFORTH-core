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
	Serial.println(F("memxFORTH 4.test.0001"));
	my_setup();
	Serial.println(F("Setup done"));
}

void loop(){
	write_char(read_char());
	my_loop();
}
