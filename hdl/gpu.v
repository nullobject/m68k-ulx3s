/**
 * Renders primitives to a framebuffer.
 */
module gpu (
    input clk,
    input rst,

    // Character RAM
    input         char_ram_wr,
    input  [ 1:0] char_ram_mask,
    input  [ 7:0] char_ram_addr,
    input  [15:0] char_ram_data,
    output [15:0] char_ram_q,

    // Framebuffer
    input         framebuffer_wr,
    input  [ 1:0] framebuffer_mask,
    input  [11:0] framebuffer_addr,
    input  [15:0] framebuffer_data,
    output [15:0] framebuffer_q,

    // OLED
    output       oled_cs,
    output       oled_rst,
    output       oled_dc,
    output       oled_e,
    output [7:0] oled_dout
);

  wire [ 7:0] framebuffer_q_b;
  wire [ 7:0] char_ram_addr_b;
  wire [15:0] char_ram_q_b;
  wire [ 7:0] char_data;
  wire [12:0] pixel_addr;
  wire [ 7:0] pixel_data = framebuffer_q_b | char_data;

  dual_port_ram #(
      .DEPTH_A(4096),
      .DEPTH_B(8192)
  ) framebuffer (
      .clk(clk),

      // port A
      .wr_a(framebuffer_wr),
      .mask_a(framebuffer_mask),
      .addr_a(framebuffer_addr),
      .data_a(framebuffer_data),
      .q_a(framebuffer_q),

      // port B
      .addr_b(pixel_addr),
      .q_b(framebuffer_q_b)
  );

  dual_port_ram #(
      .DEPTH_A(256),
      .DEPTH_B(256)
  ) char_ram (
      .clk(clk),

      // port A
      .wr_a(char_ram_wr),
      .mask_a(char_ram_mask),
      .addr_a(char_ram_addr),
      .data_a(char_ram_data),
      .q_a(char_ram_q),

      // port B
      .addr_b(char_ram_addr_b),
      .q_b(char_ram_q_b)
  );

  layer_processor char_layer (
      .clk(clk),
      .ram_addr(char_ram_addr_b),
      .ram_data(char_ram_q_b),
      .pixel_addr(pixel_addr),
      .pixel_data(char_data)
  );

  oled oled (
      .clk(clk),
      .rst(rst),
      .pixel_addr(pixel_addr),
      .pixel_data(pixel_data),
      .oled_cs(oled_cs),
      .oled_rst(oled_rst),
      .oled_dc(oled_dc),
      .oled_e(oled_e),
      .oled_dout(oled_dout)
  );

endmodule
