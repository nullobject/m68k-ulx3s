/**
 * Renders primitives to a framebuffer.
 */
module gpu (
    input clk,
    input rst,

    // framebuffer
    input         framebuffer_wr,
    input  [ 1:0] framebuffer_mask,
    input  [12:1] framebuffer_addr,
    input  [15:0] framebuffer_data,
    output [15:0] framebuffer_q,

    // OLED
    output       oled_cs,
    output       oled_rst,
    output       oled_dc,
    output       oled_e,
    output [7:0] oled_dout
);

  wire [12:0] framebuffer_addr_b;
  wire [ 7:0] framebuffer_q_b;

  dual_port_ram #(
      .DEPTH_A(4096),
      .DEPTH_B(8192),
  ) framebuffer (
      .clk(clk),

      // port A
      .wr_a(framebuffer_wr),
      .mask_a(framebuffer_mask),
      .addr_a(framebuffer_addr[12:1]),
      .data_a(framebuffer_data),
      .q_a(framebuffer_q),

      // port B
      .addr_b(framebuffer_addr_b),
      .q_b(framebuffer_q_b)
  );

  oled oled (
      .clk(clk),
      .rst(rst),
      .pixel_addr(framebuffer_addr_b),
      .pixel_data(framebuffer_q_b),
      .oled_cs(oled_cs),
      .oled_rst(oled_rst),
      .oled_dc(oled_dc),
      .oled_e(oled_e),
      .oled_dout(oled_dout)
  );

endmodule
