module layer_processor (
    input clk,

    output [ 7:0] ram_addr,
    input  [15:0] ram_data,
    input  [12:0] pixel_addr,
    output [ 7:0] pixel_data
);

  reg  [ 5:0] tile_code;

  wire [ 2:0] row = pixel_addr[12:10];
  wire [ 4:0] col = pixel_addr[6:2];
  wire [ 2:0] offset_y = pixel_addr[9:7];
  wire [ 1:0] offset_x = pixel_addr[1:0];
  // wire [ 5:0] tile_code = 'h1F;
  wire [ 8:0] tile_rom_addr = {tile_code, offset_y};
  wire [31:0] tile_rom_q;

  assign ram_addr = {row, col + 1'h1};

  assign pixel_data =
      offset_x == 0 ? tile_rom_q[31:24] :
      offset_x == 1 ? tile_rom_q[23:16] :
      offset_x == 2 ? tile_rom_q[15:8] :
      tile_rom_q[7:0];

  always @(posedge clk) begin
    if (offset_x == 3) tile_code <= ram_data[5:0];
  end

  rom #(
      .MEM_INIT_FILE("rom/tiles.hex"),
      .DEPTH(512),
      .DATA_WIDTH(32)
  ) oled_rom (
      .clk (clk),
      .addr(tile_rom_addr),
      .dout(tile_rom_q)
  );

endmodule
