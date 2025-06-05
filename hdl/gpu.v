/**
 * Renders tilemap layers.
 */
module gpu (
    input clk,
    input rst_n,

    // character RAM
    input  [ 1:0] char_ram_we,
    input  [ 7:0] char_ram_addr,
    input  [15:0] char_ram_data,
    output [15:0] char_ram_q,

    // OLED
    output       oled_cs,
    output       oled_rst,
    output       oled_dc,
    output       oled_e,
    output [7:0] oled_dout
);

  wire [7:0] char_ram_addr_b;
  wire [15:0] char_ram_q_b;
  wire [7:0] char_data;
  wire pixel_re;
  wire [12:0] pixel_addr;
  wire [7:0] pixel_data = char_data;

  dual_port_ram #(
      .DEPTH(256)
  ) char_ram (
      .clk(clk),

      // port A
      .we_a(char_ram_we),
      .addr_a(char_ram_addr),
      .data_a(char_ram_data),
      .q_a(char_ram_q),

      // port B
      .addr_b(char_ram_addr_b),
      .q_b(char_ram_q_b)
  );

  layer_processor char_layer (
      .clk(clk),
      .en(pixel_re),
      .ram_addr(char_ram_addr_b),
      .ram_data(char_ram_q_b),
      .pixel_addr(pixel_addr),
      .pixel_data(char_data)
  );

  oled oled (
      .clk(clk),
      .rst_n(rst_n),
      .pixel_re(pixel_re),
      .pixel_addr(pixel_addr),
      .pixel_data(pixel_data),
      .oled_cs(oled_cs),
      .oled_rst(oled_rst),
      .oled_dc(oled_dc),
      .oled_e(oled_e),
      .oled_dout(oled_dout)
  );

endmodule
