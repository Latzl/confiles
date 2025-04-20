# confiles

VERSION=$(shell cat VERSION)
THIS_OS=$(shell uname -s)
THIS_ARCH=$(shell uname -m)

BUILD_DIR=build
PACKAGE_DIR=$(BUILD_DIR)/package

.PHONY: clean pack_confiles-bin

clean:
	@rm -rvf $(BUILD_DIR)

pack_confiles-bin:
	@mkdir -p $(PACKAGE_DIR)
	@tar -czvf $(PACKAGE_DIR)/confiles-bin-$(VERSION)-$(THIS_OS)-$(THIS_ARCH).tar.gz -C mods/ confiles-bin/
