module top (
  input clk_25mhz,
  input ftdi_txd,
  output ftdi_rxd,
  output wifi_gpio0,
  output reg [7:0] led
);

assign wifi_gpio0 = 1'b1;

reg rst_n = 0;
reg [3:0] cen_cnt = 0;
reg cen;
reg [7:0] baud_cnt = 0;
reg baud;

wire int_n;
wire m1_n;
wire mreq_n;
wire iorq_n;
wire cpu_rw;

wire [23:1] cpu_addr;
wire [15:0] cpu_dout;
wire [15:0] cpu_din;
wire [15:0] rom_dout;
wire [15:0] ram_dout;
wire [7:0] acia_dout;

wire rom_cs;
wire ram_cs;
wire led_cs;
wire acia_ctrl_cs;
wire acia_data_cs;
wire acia_cs;

// chip select
assign rom_cs = cpu_addr[15:12] == 4'h0 && !mreq_n;
assign ram_cs = cpu_addr[15:12] == 4'h1 && !mreq_n;
assign led_cs = cpu_addr[7:0] == 8'h00 && !iorq_n;
assign acia_ctrl_cs = cpu_addr[7:0] == 8'h80 && !iorq_n;
assign acia_data_cs = cpu_addr[7:0] == 8'h81 && !iorq_n;
assign acia_cs = acia_ctrl_cs || acia_data_cs;

// decode CPU input data bus
assign cpu_din = acia_cs ? acia_dout : (ram_cs ? ram_dout : (rom_cs ? rom_dout : 8'hff));

// reset
always @(posedge clk_25mhz) begin
  rst_n <= 1;
end

// clock enable
always @(posedge clk_25mhz) begin
  cen_cnt <= cen_cnt + 1;
  cen <= cen_cnt == 0;
end

// baud
always @(posedge clk_25mhz) begin
  baud_cnt <= baud_cnt + 1;
  baud <= baud_cnt > 81;
  if (baud_cnt > 162) baud_cnt <= 0;
end

// LED port
always @(posedge clk_25mhz) begin
  if (led_cs && !wr_n) led <= cpu_dout;
end

// CPU
fx68k cpu (
  .reset_n(rst_n),
  .clk(clk_25mhz),
  .cen(cen),
  .wait_n(1'b1),
  .int_n(int_n),
  .nmi_n(1'b1),
  .busrq_n(1'b1),
  .m1_n(m1_n),
  .mreq_n(mreq_n),
  .iorq_n(iorq_n),
  .wr_n(wr_n),
  .rd_n(rd_n),
  .A(cpu_addr),
  .di(cpu_din),
  .do(cpu_dout)
);

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
reg  berr_n = 1'b1;            // Bus error.
wire cpu_reset_n_o;            // Reset output signal
reg  dtack_n = !vpa_n;         // Data transfer ack (always ready)
wire bg_n;                     // Bus grant
reg  bgack_n = 1'b1;           // Bus grant ack
reg  ipl0_n = 1'b1;            // Interrupt request signals
reg  ipl1_n = 1'b1;
reg  ipl2_n = 1'b1;
wire [15:0] ram_dout;
wire [15:0] rom_dout;
wire [7:0]  vga_dout;
wire [15:0] cpu_din;           // Data to CPU
wire [15:0] cpu_dout;          // Data from CPU
wire [23:1] cpu_a;             // Address
reg [7:0] R_cpu_control = 4;   // SPI loader, initially HALT to
wire halt_n = ~R_cpu_control[2]; // prevent running SDRAM junk code
wire acia_cs  = !vma_n && cpu_a[3:2] == 0;
wire audio_cs = !vma_n && cpu_a[3:1] == 2;
wire keybd_cs = !vma_n && cpu_a[3:1] == 3;
wire [7:0] acia_dout;
wire [63:0] kbd_matrix;

// Address 0x600000 to 6fffff used for peripherals
assign vpa_n = !(cpu_a[23:18]==6'b011000) | cpu_as_n;

assign cpu_din = cpu_a[17:15] < 2  ? rom_dout : (cpu_a[17:15] == 2 ? vga_dout : (acia_cs ? {8'd0, acia_dout} : (keybd_cs ? kbd_matrix[{cpu_a[6:4], 3'b0} + 7 -: 8] : ram_dout)));

always @(posedge clk_cpu) begin
  fx68_phi1 <= ~fx68_phi1;
  fx68_phi2 <=  fx68_phi1;
end

fx68k fx68k (
  // input
  .clk(clk_25mhz),
  .HALTn(halt_n),
  .extReset(!btn[0] || !pwr_up_reset_n || R_cpu_control[0]),
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
  .BERRn(berr_n),
  .BRn(1'b1), // no bus request
  .BGACKn(1'b1),
  .IPL0n(ipl0_n),
  .IPL1n(ipl1_n),
  .IPL2n(ipl2_n),

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
  .addr(cpu_addr),
  .dout(rom_dout)
);

// RAM
ram #(
  .DEPTH(4096)
) work_ram (
  .clk(clk_25mhz),
  .cs(ram_cs),
  .we(!cpu_rw),
  .addr(cpu_addr),
  .din(cpu_dout),
  .dout(ram_dout)
);

// UART
acia uart (
  .reset(!rst_n),
  .clk(clk_25mhz),
  .cs(acia_cs),
  .e_clk(cen),
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
  .irq_n(int_n)
);

endmodule
