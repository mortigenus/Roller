prefix ?= /usr/local
bindir = $(prefix)/bin

.PHONY: build
build:
	swift build -c release -Xswiftc -cross-module-optimization

.PHONY: install
install: build
	install .build/release/RollerMain "$(bindir)/roll"

.PHONY: clean
clean:
	swift package clean
