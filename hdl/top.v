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
wire wr_n;
wire rd_n;

wire [15:0] cpu_addr;
wire [7:0] cpu_dout;
wire [7:0] cpu_din;
wire [7:0] rom_dout;
wire [7:0] ram_dout;
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
tv80n cpu (
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
  .we(!wr_n),
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
  .rw_n(wr_n),
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
