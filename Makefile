DEVICE = 85k
PIN_DEF = ulx3s_v20.lpf
BUILDDIR = build

PROG = blink
PROG_OUT = $(BUILDDIR)/$(PROG).out
PROG_BIN = $(BUILDDIR)/$(PROG).bin
PROG_HEX = $(BUILDDIR)/$(PROG).hex
FAKE_HEX = $(BUILDDIR)/rom.hex

SRC = $(wildcard hdl/*.v) $(wildcard lib/fx68k/*.v)

all: $(BUILDDIR)/toplevel.bit

program: $(BUILDDIR)/toplevel.bit
	fujprog $^

ftp: $(BUILDDIR)/toplevel.bit
	ftp -u ftp://ulx3s/fpga $^

tty:
	fujprog -t -b 9600

sim:
	verilator --trace --exe --build --cc -j 0 -y hdl sim_main.cpp hdl/gpu.v
	$(MAKE) -j -C obj_dir -f Vgpu.mk
	obj_dir/Vgpu

clean:
	rm -rf $(BUILDDIR)

$(FAKE_HEX):
	mkdir -p $(BUILDDIR)
	ecpbram -w 16 -d 2048 -g $@

$(PROG_OUT): rom/$(PROG).c rom/start.s rom/linker_script.ld
	mkdir -p $(BUILDDIR)
	m68k-linux-gnu-gcc -Wall -ffreestanding -nostdlib -Wl,-Bstatic,-Trom/linker_script.ld,--strip-debug,--build-id=none,--no-warn-execstack -o $@ rom/start.s $<

$(PROG_BIN): $(PROG_OUT)
	m68k-linux-gnu-objcopy -O binary $< $@

$(PROG_HEX): $(PROG_OUT)
	m68k-linux-gnu-objcopy -O verilog --verilog-data-width=2 $< $@

$(BUILDDIR)/%.json: $(SRC) $(FAKE_HEX)
	yosys -p "synth_ecp5 -abc9 -top top -json $@" $(SRC)

$(BUILDDIR)/%.config: $(PIN_DEF) $(BUILDDIR)/%.json
	 nextpnr-ecp5 --$(DEVICE) --package CABGA381 --freq 25 --textcfg $@ --json $(filter-out $<,$^) --lpf $<

$(BUILDDIR)/%.bit: $(BUILDDIR)/%.config $(PROG_HEX)
	ecpbram -f $(FAKE_HEX) -t $(PROG_HEX) -i $< -o $(BUILDDIR)/temp.config
	ecppack $(BUILDDIR)/temp.config $@ --compress

.SECONDARY: $(BUILDDIR)/toplevel.config $(BUILDDIR)/toplevel.json
.PHONY: all clean ftp program sim tty
