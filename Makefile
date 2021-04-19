
.PHONY: all
all: build

.PHONY: build
build:
	swift build -c release -Xswiftc -cross-module-optimization
	cp .build/release/RollerMain /usr/local/bin/roll
