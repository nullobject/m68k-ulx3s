// TODO:
// * Add framebuffer dual-port RAM
// * Add intial reset states
// * Change idle state to wait for a start signal
// * When start signal is received, write framebuffer to OLED
// * Send the set row/col commands by appending them to the ROM. Store the
// offsets in a localparam and play the sequence of bytes before writing to
// VRAM.
module oled (
    input clk,
    input rst,
    output done,
    output reg oled_cs,
    output reg oled_e,
    output reg oled_rw,
    output reg oled_dc,
    output reg [7:0] oled_dout
);

  localparam IDLE = 0, LOAD_COMMAND = 1, SEND_COMMAND = 2, LOAD_DATA = 3, SEND_DATA = 4, DONE = 5;

  localparam OLED_ROM_SIZE = 36;

  reg  [5:0] addr;
  reg  [2:0] state;
  wire [7:0] rom_dout;

  assign done = addr >= OLED_ROM_SIZE - 1;

  always @(posedge clk, posedge rst) begin
    if (rst) begin
      state <= IDLE;
      addr <= 0;
      oled_cs <= 1;
      oled_e <= 1;
      oled_rw <= 0;
      oled_dc <= 0;
    end else begin
      case (state)
        IDLE: begin
          state   <= LOAD_COMMAND;
          oled_cs <= 0;
        end
        LOAD_COMMAND: begin
          state <= SEND_COMMAND;
          addr <= addr + 1;
          oled_dc <= 0;
          oled_e <= 1;
          oled_dout <= rom_dout;
        end
        SEND_COMMAND: begin
          state  <= LOAD_DATA;
          oled_e <= 0;
        end
        LOAD_DATA: begin
          state <= SEND_DATA;
          addr <= addr + 1;
          oled_e <= 1;
          oled_dc <= 1;
          oled_dout <= rom_dout;
        end
        SEND_DATA: begin
          state  <= done ? DONE : LOAD_COMMAND;
          oled_e <= 0;
        end
        DONE: begin
          oled_cs <= 1;
          oled_e  <= 1;
        end
        default: state <= IDLE;
      endcase
    end
  end

  // Initialization ROM for the OLED display
  rom #(
      .MEM_INIT_FILE("oled.hex"),
      .DEPTH(OLED_ROM_SIZE),
      .DATA_WIDTH(8)
  ) oled_rom (
      .clk (clk),
      .addr(addr),
      .dout(rom_dout)
  );

endmodule
