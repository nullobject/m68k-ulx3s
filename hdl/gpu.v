module gpu (
    input  clk,
    input  rst,
    output done,

    // VRAM
    input        vram_wr,
    input [13:0] vram_addr,
    input [ 3:0] vram_data,

    // OLED
    output       oled_cs,
    output       oled_rst,
    output       oled_e,
    output       oled_dc,
    output [7:0] oled_dout
);

  wire [12:0] vram_addr_b;
  wire [ 7:0] vram_q_b;

  always @(posedge clk, posedge rst) begin
    if (rst) begin
      state <= BOOT;
    end
  end

  dual_port_ram #(
      .DEPTH_A(16384),
      .DEPTH_B(8192),
  ) vram (
      .clk(clk),
      .wr_a(vram_wr),
      .addr_a(vram_addr),
      .data_a(vram_data),
      .addr_b(vram_addr_b),
      .q_b(vram_q_b)
  );

  oled oled (
      .clk(clk),
      .rst(rst),
      .vram_addr(vram_addr_b),
      .vram_q(vram_q_b),
      .oled_cs(oled_cs),
      .oled_rst(oled_rst),
      .oled_e(oled_e),
      .oled_dc(oled_dc),
      .oled_dout(oled_dout)
  );

endmodule
