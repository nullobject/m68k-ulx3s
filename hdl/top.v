module top (
    input clk_25mhz,
    input [6:0] btn,
    input ftdi_txd,
    output ftdi_rxd,
    output wifi_gpio0,
    output reg [7:0] led,
    output [7:0] gp,
    output [7:0] gn
);

  assign wifi_gpio0 = 1'b1;

  wire [23:0] cpu_addr;
  wire [15:0] cpu_dout;
  wire [15:0] cpu_din;
  wire [15:0] rom_dout;
  wire [15:0] ram_dout;
  wire [15:0] char_ram_dout;
  wire [ 7:0] acia_dout;

  wire cpu_rw;    // read = 1, write = 0
  wire cpu_as_n;  // address strobe
  wire cpu_lds_n; // lower byte
  wire cpu_uds_n; // upper byte
  wire cpu_E;     // peripheral enable
  wire vma_n;     // valid memory address
  wire vpa_n;     // valid peripheral address

  // address 0x4000 to 0xffff used for peripherals
  assign vpa_n = !(cpu_addr[15:12] >= 5) | cpu_as_n;

  // chip select
  //
  // 0000-0FFF ROM
  // 1000-1FFF RAM
  // 2000-2100 CHAR RAM
  // 3000      ACIA
  // 4000      LED
  always @(addr) begin
    {ram_cs, char_ram_cs, acia_cs, led_cs} = 0;
    casez (cpu_addr[15:12])
      4'b0001: ram_cs = 1;
      4'b0010: char_ram_cs = 1;
      4'b0011: acia_cs = 1;
      4'b0100: led_cs = 1;
      default: {ram_cs, char_ram_cs, acia_cs, led_cs} = 0;
    endcase
  end

  // reset
  reg [5:0] reset_cnt = 0;
  wire rst_n = &reset_cnt & btn[0];
  always @(posedge clk_25mhz) reset_cnt <= reset_cnt + !rst_n;

  // DTACK
  reg dtack_n;  // Data transfer ack (always ready)

  always @(posedge clk_25mhz) dtack_n <= !vpa_n;

  // LED
  always @(posedge clk_25mhz) if (led_cs && !cpu_rw) led <= cpu_dout;

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
  assign cpu_din =
  acia_cs ? {acia_dout, 8'h0} :
  char_ram_cs ? char_ram_dout :
  ram_cs ? ram_dout :
  rom_dout;

  fx68k m68k (
      // clock/reset
      .clk(clk_25mhz),
      .HALTn(1'b1),
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
      .eab (cpu_addr[23:1]),
      .iEdb(cpu_din),
      .oEdb(cpu_dout)
  );

  // ROM
  rom #(
      .MEM_INIT_FILE("build/rom.hex"),
      .DEPTH(2048)
  ) prog_rom (
      .clk(clk_25mhz),
      .addr(cpu_addr[11:1]),
      .q(rom_dout)
  );

  // RAM
  ram #(
      .DEPTH(2048)
  ) work_ram (
      .clk(clk_25mhz),
      .we(ram_cs && !cpu_rw ? {!cpu_uds_n, !cpu_lds_n} : 0),
      .addr(cpu_addr[11:1]),
      .data(cpu_dout),
      .q(ram_dout)
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

  // GPU
  gpu gpu (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .char_ram_we(char_ram_cs && !cpu_rw ? {!cpu_uds_n, !cpu_lds_n} : 0),
      .char_ram_addr(cpu_addr[8:1]),
      .char_ram_data(cpu_dout),
      .char_ram_q(char_ram_dout),
      .oled_cs(gp[0]),
      .oled_rst(gp[1]),
      .oled_dc(gp[3]),
      .oled_e(gp[2]),
      .oled_dout(gn)
  );

endmodule
