# Builds every microbenchmark as <name>/<name>.exe.
# The callee lives in lib.c and is compiled as a separate TU without LTO.
CC      := clang
CFLAGS  ?= -O2 -g0
LDFLAGS ?= -Wl,--emit-relocs -fuse-ld=lld
BENCHES := bufwrite memo trace pool unsafe compute mixed

all: $(foreach b,$(BENCHES),$(b)/$(b).exe)

%.exe:
	$(CC) $(CFLAGS) -c $(dir $@)lib.c -o $(dir $@)lib.o
	$(CC) $(CFLAGS) -c $(dir $@)main.c -o $(dir $@)main.o
	$(CC) $(CFLAGS) $(dir $@)main.o $(dir $@)lib.o -o $@ $(LDFLAGS)

clean:
	rm -f */*.o */*.exe

.PHONY: all clean
