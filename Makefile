DEVICE = 85k
PIN_DEF = ulx3s_v20.lpf
BUILDDIR = build

PROG = uart
PROG_ASM = rom/$(PROG).asm
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

$(PROG_BIN): $(PROG_ASM)
	mkdir -p $(BUILDDIR)
	z80asm $< -I rom -o $@

$(PROG_HEX): $(PROG_BIN)
	hexdump -v -e '/1 "%02x\n"' $< > $@

$(BUILDDIR)/%.json: $(SRC) $(FAKE_HEX)
	yosys -p "synth_ecp5 -abc9 -top top -json $@" $(SRC)

$(BUILDDIR)/%.config: $(PIN_DEF) $(BUILDDIR)/%.json
	 nextpnr-ecp5 --$(DEVICE) --package CABGA381 --freq 25 --textcfg $@ --json $(filter-out $<,$^) --lpf $<

$(BUILDDIR)/%.bit: $(BUILDDIR)/%.config $(PROG_HEX)
	ecpbram -f $(FAKE_HEX) -t $(PROG_HEX) -i $< -o $(BUILDDIR)/temp.config
	ecppack $(BUILDDIR)/temp.config $@ --compress
