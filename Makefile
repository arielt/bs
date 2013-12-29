.PHONY: all install

INST_DIR     = "debian/tmp"
INST_BIN_DIR = $(INST_DIR)/usr/sbin
INST_OPT_DIR = $(INST_DIR)/opt/bs

all:

clean:
	rm -rf $(INST_DIR)

install:
	mkdir -p $(INST_BIN_DIR)
	cp bin/bs $(INST_BIN_DIR)

	mkdir -p $(INST_OPT_DIR)
	cp -r lib $(INST_OPT_DIR)/
	cp -r files $(INST_OPT_DIR)/

	mkdir -p $(INST_OPT_DIR)/tasks
	mkdir -p $(INST_OPT_DIR)/config
	mkdir -p $(INST_OPT_DIR)/log
	mv $(INST_OPT_DIR)/files/bs.yml $(INST_OPT_DIR)/config

