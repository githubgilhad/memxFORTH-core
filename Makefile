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

# Makro pro získání dat z gitu
GIT_DESCRIBE := $(shell git describe --tags --long 2>/dev/null || echo "v0.0.0-0-g0000000")
GIT_COMMIT_HASH := $(shell git rev-parse --short HEAD)
GIT_COMMIT_MESSAGE := $(shell git log -1 --pretty=%s)
VERSION_HEADER := version.h

# Cíl pro generování version.h
$(VERSION_HEADER): FORCE
	@echo "Checking version..."
	@TMPFILE=$$(mktemp) && \
	echo "#pragma once" > $$TMPFILE && \
	echo "#define VERSION_STRING \"$(GIT_DESCRIBE)++\"" >> $$TMPFILE && \
	echo "#define VERSION_COMMIT \"$(GIT_COMMIT_HASH)\"" >> $$TMPFILE && \
	echo "#define VERSION_MESSAGE \"$(GIT_COMMIT_MESSAGE)\"" >> $$TMPFILE && \
	if ! cmp -s $$TMPFILE $(VERSION_HEADER); then \
		echo "Updating $(VERSION_HEADER)"; \
		mv $$TMPFILE $(VERSION_HEADER); \
	else \
		echo "$(VERSION_HEADER) is up to date"; \
		rm $$TMPFILE; \
	fi


# Umožní vždy ověřit stav
FORCE:

# Cíl pro návrh nového tagu
new_tag:
	@LAST_TAG=$$(git tag --sort=-v:refname | head -n1); \
	if [ -z "$$LAST_TAG" ]; then \
		NEW_TAG="v0.0.1"; \
	else \
		IFS=. read -r MAJOR MINOR PATCH <<< "$$(echo $$LAST_TAG | sed 's/^v//')"; \
		PATCH=$$((PATCH + 1)); \
		NEW_TAG="v$${MAJOR}.$${MINOR}.$${PATCH}"; \
	fi; \
	echo "Suggested new tag:"; \
	echo "git tag -a $$NEW_TAG -m \"Release $$NEW_TAG\""; \
	echo "git push origin $$NEW_TAG"

# Cíl pro ruční vygenerování nové verze
version: $(VERSION_HEADER)

$(TARGET_ELF): $(VERSION_HEADER)

.PHONY: v_help FORCE new_tag version monitor
pico:
	picocom -b 115200 --flow n  --noreset --hangup --quiet /dev/ttyUSB0
help: v_help
v_help:
	@echo "Aditional targets:"
	@echo "  make pico              - open serial connection"
	@echo "  make version           - make/update version.h"
	@echo "  make new_tag           - suggest new tag for git"
