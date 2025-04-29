BOARD_TAG = nano
BOARD_SUB = atmega328
#BOARD_TAG = mega
#BOARD_SUB = atmega2560
MONITOR_BAUDRATE=115200
#MONITOR_BAUDRATE=9600
#TARGET = demo
ISP_PROG=usbasp
USER_LIB_PATH= $(ARDMK_DIR)/libs/
include ../Makefile
# include $(ARDMK_DIR)/Arduino.mk
