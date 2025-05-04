DEVICE = 85k
PIN_DEF = ulx3s_v20.lpf
BUILDDIR = build

PROG = blink
PROG_C = rom/$(PROG).c
PROG_O = rom/$(PROG).o
PROG_BIN = $(BUILDDIR)/$(PROG).bin
PROG_HEX = $(BUILDDIR)/$(PROG).hex
FAKE_HEX = $(BUILDDIR)/rom.hex

SRC = $(wildcard hdl/*.v) $(wildcard lib/fx68k/*.v)

all: $(BUILDDIR)/toplevel.bit
.PHONY: all

program: $(BUILDDIR)/toplevel.bit
	fujprog $^
.PHONY: program

ftp: $(BUILDDIR)/toplevel.bit
	ftp -u ftp://ulx3s/fpga $^
.PHONY: ftp

tty:
	fujprog -t -b 9600
.PHONY: tty

clean:
	rm -rf $(BUILDDIR)
.PHONY: clean

$(FAKE_HEX):
	mkdir -p $(BUILDDIR)
	ecpbram -w 8 -d 512 -g $@

$(PROG_BIN): $(PROG_C)
	mkdir -p $(BUILDDIR)
	m68k-linux-gnu-gcc -Wall -m68000 -msoft-float -c $(PROG_C)
	m68k-linux-gnu-ld --defsym=_start=main -Ttext=0x2000 -Tdata=0x3000 -Tbss=0x4000 --section-start=.rodata=0x5000 $(PROG_O) `m68k-linux-gnu-gcc -m68000 -print-libgcc-file-name`
	m68k-linux-gnu-objcopy -I elf32-m68k -O binary a.out demo.run

$(PROG_HEX): $(PROG_BIN)
	hexdump -v -e '/1 "%02x\n"' $< > $@

$(BUILDDIR)/%.json: $(SRC) $(FAKE_HEX)
	yosys -p "synth_ecp5 -abc9 -top top -json $@" $(SRC)

$(BUILDDIR)/%.config: $(PIN_DEF) $(BUILDDIR)/%.json
	 nextpnr-ecp5 --$(DEVICE) --package CABGA381 --freq 25 --textcfg $@ --json $(filter-out $<,$^) --lpf $<

$(BUILDDIR)/%.bit: $(BUILDDIR)/%.config $(PROG_HEX)
	ecpbram -f $(FAKE_HEX) -t $(PROG_HEX) -i $< -o $(BUILDDIR)/temp.config
	ecppack $(BUILDDIR)/temp.config $@ --compress
