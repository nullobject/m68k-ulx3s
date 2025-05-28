/**
 * Renders primitives to a framebuffer.
 */
module gpu (
    input clk,
    input rst,

    // VRAM
    input         vram_wr,
    input  [12:0] vram_addr,
    input  [ 3:0] vram_data,
    output [ 3:0] vram_q,

    // OLED
    output       oled_cs,
    output       oled_rst,
    output       oled_dc,
    output       oled_e,
    output [7:0] oled_dout
);

  wire [12:0] vram_addr_b;
  wire [ 7:0] vram_q_b;

  dual_port_ram #(
      .DEPTH_A(8192),
      .DEPTH_B(8192),
  ) vram (
      // port A
      .clk_a(clk),
      .en_a(1),
      .wr_a(vram_wr),
      .addr_a(vram_addr),
      .data_a(vram_data),
      .q_a(vram_q),

      // port B
      .clk_b(clk),
      .en_b(1),
      .addr_b(vram_addr_b),
      .q_b(vram_q_b)
  );

  wire [7:0] data = vram_addr_b[2:0] == 0 ? 'hFF : 'h0;

  oled oled (
      .clk(clk),
      .rst(rst),
      .vram_addr(vram_addr_b),
      // .vram_q(vram_q_b),
      .vram_q(data),
      .oled_cs(oled_cs),
      .oled_rst(oled_rst),
      .oled_dc(oled_dc),
      .oled_e(oled_e),
      .oled_dout(oled_dout)
  );

endmodule
