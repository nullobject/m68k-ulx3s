module top (
  input clk_25mhz,
  input ftdi_txd,
  output ftdi_rxd,
  output wifi_gpio0,
  output reg [7:0] led
);

assign wifi_gpio0 = 1'b1;

reg rst_n = 0;
reg [7:0] baud_cnt = 0;
reg baud;

wire [23:1] cpu_addr;
wire [15:0] cpu_dout;
wire [15:0] cpu_din;
wire [15:0] rom_dout;
wire [15:0] ram_dout;
wire [7:0] acia_dout;

// chip select
wire rom_cs = !vma_n && cpu_addr[15:12] == 4'h0;
wire ram_cs = !vma_n && cpu_addr[15:12] == 4'h1;
wire led_cs = !vma_n && cpu_addr[7:0] == 8'h00;
wire acia_ctrl_cs = !vma_n && cpu_addr[7:0] == 8'h80;
wire acia_data_cs = !vma_n && cpu_addr[7:0] == 8'h81;
wire acia_cs = acia_ctrl_cs || acia_data_cs;

// decode CPU input data bus
assign cpu_din = acia_cs ? {8'd0, acia_dout} : (ram_cs ? ram_dout : rom_dout);

// reset
always @(posedge clk_25mhz) begin
  rst_n <= 1;
end

// 9600 baud clock
always @(posedge clk_25mhz) begin
  baud_cnt <= baud_cnt + 1;
  baud <= baud_cnt > 81;
  if (baud_cnt > 162) baud_cnt <= 0;
end

// LED port
always @(posedge clk_25mhz) begin
  if (led_cs && !cpu_rw) led <= cpu_dout;
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
reg [7:0] R_cpu_control = 4;   // SPI loader, initially HALT to
wire halt_n = ~R_cpu_control[2]; // prevent running SDRAM junk code

// Address 0x600000 to 6fffff used for peripherals
assign vpa_n = !(cpu_addr[23:18]==6'b011000) | cpu_as_n;

always @(posedge clk_cpu) begin
  fx68_phi1 <= ~fx68_phi1;
  fx68_phi2 <=  fx68_phi1;
end

fx68k m68k (
  // input
  .clk(clk_25mhz),
  .HALTn(halt_n),
  .extReset(!rst_n),
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
  .addr(cpu_addr[15:1]),
  .dout(rom_dout)
);

// RAM
ram #(
  .DEPTH(4096)
) work_ram (
  .clk(clk_25mhz),
  .we(!cpu_rw),
  .mask({!cpu_uds_n, !cpu_lds_n}),
  .addr(cpu_addr[15:1]),
  .din(cpu_dout),
  .dout(ram_dout)
);

// UART
acia uart (
  .reset(!rst_n),
  .clk(clk_25mhz),
  .cs(acia_cs),
  .e_clk(cpu_E),
  .rw_n(cpu_rw),
  .rs(acia_data_cs),
  .data_in(cpu_dout),
  .data_out(acia_dout),
  .txclk(baud),
  .rxclk(baud),
  .txdata(ftdi_rxd),
  .rxdata(ftdi_txd),
  .cts_n(1'b0),
  .dcd_n(1'b0),
  .irq_n()
);

endmodule
