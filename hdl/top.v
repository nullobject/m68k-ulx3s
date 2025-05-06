module top (
  input clk_25mhz,
  input ftdi_txd,
  output ftdi_rxd,
  output wifi_gpio0,
  output reg [7:0] led = 0
);

assign wifi_gpio0 = 1'b1;

reg rst_n = 0;

wire [23:1] cpu_addr;
wire [15:0] cpu_dout;
wire [15:0] cpu_din;
wire [15:0] rom_dout;
wire [15:0] ram_dout;

// chip select
wire rom_cs = !vma_n && cpu_addr[15:12] == 4'h0;
wire ram_cs = !vma_n && cpu_addr[15:12] == 4'h1;
wire led_cs = !vma_n && cpu_addr[15:12] == 4'h2;

// decode CPU input data bus
assign cpu_din = ram_cs ? ram_dout : rom_dout;

// reset
always @(posedge clk_25mhz) begin
  rst_n <= 1;
end

reg [15:0] pwr_up_reset_counter = 0;
wire       pwr_up_reset_n = &pwr_up_reset_counter;

always @(posedge clk_25mhz) begin
  if (!pwr_up_reset_n)
    pwr_up_reset_counter <= pwr_up_reset_counter + 1;
end

// LED port
always @(posedge clk_25mhz) begin
  if (led_cs && !cpu_rw) led <= cpu_dout;
  // led <= cpu_addr[8:1];
end

// ===============================================================
// 68000 CPU
// ===============================================================
reg  fx68_phi1;                // Phi 1 enable
reg  fx68_phi2;                // Phi 2 enable (for slow cpu)
wire cpu_rw;                   // Read = 1, Write = 0
wire cpu_as_n;                 // Address strobe
wire cpu_lds_n;                // Lower byte
wire cpu_uds_n;                // Upper byte
wire cpu_E;                    // Peripheral enable
wire vma_n;                    // Valid memory address
wire vpa_n;                    // Valid peripheral address
wire cpu_fc0;                  // Processor state
wire cpu_fc1;
wire cpu_fc2;
reg  dtack_n = !vpa_n;         // Data transfer ack (always ready)
wire bg_n;                     // Bus grant

// Address 0x600000 to 6fffff used for peripherals
assign vpa_n = !(cpu_addr[23:18]==6'b011000) | cpu_as_n;

always @(posedge clk_25mhz) begin
  fx68_phi1 <= ~fx68_phi1;
  fx68_phi2 <=  fx68_phi1;
end

fx68k m68k (
  // input
  .clk(clk_25mhz),
  .HALTn(1'b1),
  .extReset(!pwr_up_reset_n),
  .pwrUp(!pwr_up_reset_n),
  .enPhi1(fx68_phi1),
  .enPhi2(fx68_phi2),

  // output
  .eRWn(cpu_rw),
  .ASn(cpu_as_n),
  .LDSn(cpu_lds_n),
  .UDSn(cpu_uds_n),
  .E(cpu_E),
  .VMAn(vma_n),
  .FC0(cpu_fc0),
  .FC1(cpu_fc1),
  .FC2(cpu_fc2),
  .BGn(bg_n),
  .oRESETn(rst_n),
  .oHALTEDn(),

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
  .eab(cpu_addr),
  .iEdb(cpu_din),
  .oEdb(cpu_dout)
);

// ROM
rom #(
  .MEM_INIT_FILE("../build/rom.hex"),
  .DEPTH(512)
) prog_rom (
  .clk(clk_25mhz),
  .addr(cpu_addr[8:1]),
  .dout(rom_dout)
);

// RAM
ram #(
  .DEPTH(4096)
) work_ram (
  .clk(clk_25mhz),
  .we(!cpu_rw),
  .mask({!cpu_uds_n, !cpu_lds_n}),
  .addr(cpu_addr[11:1]),
  .din(cpu_dout),
  .dout(ram_dout)
);

endmodule
