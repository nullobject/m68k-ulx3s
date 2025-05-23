module top (
  input clk_25mhz,
  input [6:0] btn,
  input ftdi_txd,
  output ftdi_rxd,
  output wifi_gpio0,
  output reg [7:0] led,
  output reg [3:0] gp,
  output reg [3:0] gn
);

assign wifi_gpio0 = 1'b1;

wire [23:0] cpu_addr;
wire [15:0] cpu_dout;
wire [15:0] cpu_din;
wire [15:0] rom_dout;
wire [15:0] ram_dout;
wire [7:0] acia_dout;

wire cpu_rw;    // read = 1, write = 0
wire cpu_as_n;  // address strobe
wire cpu_lds_n; // lower byte
wire cpu_uds_n; // upper byte
wire cpu_E;     // peripheral enable
wire vma_n;     // valid memory address
wire vpa_n;     // valid peripheral address

// address 0x2000 to 0x3fff used for peripherals
assign vpa_n = !(cpu_addr[15:12] > 1) | cpu_as_n;

// chip select
wire ram_cs = cpu_addr[15:12] == 1;
wire led_cs = !vma_n && cpu_addr == 16'h2000;
wire gpio_cs = !vma_n && cpu_addr == 16'h2002;
wire acia_cs = !vma_n && cpu_addr[15:12] == 3;

// reset
reg rst_n = 0;

always @(posedge clk_25mhz) begin
  rst_n <= 1;
end

// DTACK
reg dtack_n; // Data transfer ack (always ready)

always @(posedge clk_25mhz) begin
  dtack_n <= !vpa_n;
end

// LED
always @(posedge clk_25mhz) begin
  if (led_cs && !cpu_rw) led <= cpu_dout;
end

// GPIO
reg [7:0] gpio = 0;
assign gp = {gpio[6], gpio[4], gpio[2], gpio[0]};
assign gn = {gpio[7], gpio[5], gpio[3], gpio[1]};

always @(posedge clk_25mhz) begin
  if (gpio_cs && !cpu_rw) gpio <= cpu_dout;
end

// baud clock
reg [7:0] baud_cnt = 0;
reg baud_clk;

always @(posedge clk_25mhz) begin
  baud_cnt <= baud_cnt + 1;
  baud_clk <= baud_cnt > 81;
  if (baud_cnt > 162) baud_cnt <= 0;
end

// phi clock
reg fx68_phi1;
reg fx68_phi2;

always @(posedge clk_25mhz) begin
  fx68_phi1 <= ~fx68_phi1;
  fx68_phi2 <= fx68_phi1;
end

// decode CPU input data bus
assign cpu_din = acia_cs ? {acia_dout, 8'h0} : (gpio_cs ? {gpio, 8'h0} : (ram_cs ? ram_dout : rom_dout));

fx68k m68k (
  // clock/reset
  .clk(clk_25mhz),
  .HALTn(1'b1),
  .extReset(!rst_n || !btn[0]),
  .pwrUp(!rst_n),
  .enPhi1(fx68_phi1),
  .enPhi2(fx68_phi2),

  // output
  .eRWn(cpu_rw),
  .ASn(cpu_as_n),
  .LDSn(cpu_lds_n),
  .UDSn(cpu_uds_n),
  .E(cpu_E),
  .VMAn(vma_n),
  .FC0(),
  .FC1(),
  .FC2(),
  .BGn(),

  // input
  .DTACKn(dtack_n),
  .VPAn(vpa_n),
  .BERRn(1'b1),
  .BRn(1'b1),
  .BGACKn(1'b1),
  .IPL0n(1'b1),
  .IPL1n(1'b1),
  .IPL2n(1'b1),

  // busses
  .eab(cpu_addr[23:1]),
  .iEdb(cpu_din),
  .oEdb(cpu_dout)
);

// ROM
rom #(
  .MEM_INIT_FILE("../build/rom.hex"),
  .DEPTH(2048)
) prog_rom (
  .clk(clk_25mhz),
  .addr(cpu_addr[11:1]),
  .dout(rom_dout)
);

// RAM
ram #(
  .DEPTH(2048)
) work_ram (
  .clk(clk_25mhz),
  .we(ram_cs && !cpu_rw),
  .mask({!cpu_uds_n, !cpu_lds_n}),
  .addr(cpu_addr[11:1]),
  .din(cpu_dout),
  .dout(ram_dout)
);

// UART
acia uart (
  .clk(clk_25mhz),
  .reset(!rst_n),
  .cs(acia_cs),
  .e_clk(cpu_E),
  .rw_n(cpu_rw),
  .rs(cpu_addr[1]),
  .data_in(cpu_dout[7:0]),
  .data_out(acia_dout),
  .txclk(baud_clk),
  .rxclk(baud_clk),
  .txdata(ftdi_rxd),
  .rxdata(ftdi_txd),
  .cts_n(1'b0),
  .dcd_n(1'b0),
  .irq_n()
);

endmodule
