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
    output reg oled_rst,
    output reg oled_e,
    output reg oled_dc,
    output reg [7:0] oled_dout
);

  localparam OLED_ROM_SIZE = 64;

  // states
  localparam IDLE = 0;
  localparam LOAD_COUNTER = 1;
  localparam LOAD_COMMAND = 2;
  localparam LATCH_COMMAND = 3;
  localparam LOAD_DATA = 4;
  localparam LATCH_DATA = 5;
  localparam DONE = 6;

  reg  [6:0] addr;
  reg  [2:0] state;
  reg  [5:0] counter;
  wire [7:0] rom_dout;

  assign oled_rst = !rst;
  assign done = addr == OLED_ROM_SIZE - 1;

  function [5:0] arity(input reg [7:0] cmd);
    case (cmd)
      8'h15:   arity = 2;
      8'h5C:   arity = 20;
      8'h75:   arity = 2;
      8'hA0:   arity = 2;
      8'hAE:   arity = 0;
      8'hAF:   arity = 0;
      8'hB4:   arity = 2;
      8'hD1:   arity = 2;
      default: arity = 1;
    endcase
  endfunction

  always @(posedge clk, posedge rst) begin
    if (rst) begin
      state <= IDLE;
      addr <= 0;
      oled_cs <= 1;
      oled_e <= 1;
      oled_dc <= 0;
    end else begin
      case (state)
        IDLE: begin
          state   <= LOAD_COUNTER;
          oled_cs <= 0;
        end
        LOAD_COUNTER: begin
          state   <= LOAD_COMMAND;
          counter <= arity(rom_dout);
        end
        LOAD_COMMAND: begin
          state <= LATCH_COMMAND;
          addr <= addr + 1;
          oled_dc <= 0;
          oled_e <= 1;
          oled_dout <= rom_dout;
        end
        LATCH_COMMAND: begin
          state  <= done ? DONE : counter > 0 ? LOAD_DATA : LOAD_COUNTER;
          oled_e <= 0;
        end
        LOAD_DATA: begin
          state <= LATCH_DATA;
          addr <= addr + 1;
          counter <= counter - 1;
          oled_e <= 1;
          oled_dc <= 1;
          oled_dout <= rom_dout;
        end
        LATCH_DATA: begin
          state  <= done ? DONE : counter > 0 ? LOAD_DATA : LOAD_COUNTER;
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
      .MEM_INIT_FILE("rom/oled.hex"),
      .DEPTH(OLED_ROM_SIZE),
      .DATA_WIDTH(8)
  ) oled_rom (
      .clk (clk),
      .addr(addr[5:0]),
      .dout(rom_dout)
  );

endmodule
