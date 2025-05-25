// TODO:
// * Perform boot sequence on reset
// * Enter IDLE state and wait for a start signal
// * When start signal is received, sent commands and frame buffer to the OLED
// * Return to the IDLE state
module oled (
    input clk,
    input rst,

    input  start,
    output ready,

    // VRAM
    output reg [12:0] vram_addr,
    /* verilator lint_off UNUSEDSIGNAL */
    input      [ 7:0] vram_q,
    /* verilator lint_on UNUSEDSIGNAL */

    // OLED
    output reg       oled_cs,
    output reg       oled_rst,
    output reg       oled_e,
    output reg       oled_dc,
    output reg [7:0] oled_dout
);

  localparam OLED_ROM_SIZE = 43;

  // states
  localparam IDLE = 0;
  localparam LOAD_COUNTER = 1;
  localparam LOAD_COMMAND = 2;
  localparam LATCH_COMMAND = 3;
  localparam LOAD_DATA = 4;
  localparam LATCH_DATA = 5;
  localparam DONE = 6;

  reg [2:0] state;
  reg [13:0] addr;
  reg [13:0] counter;
  reg blit;
  wire [7:0] rom_q;

  assign vram_addr = 0;
  assign oled_rst  = !rst;
  wire done = addr == OLED_ROM_SIZE - 1;
  assign ready = state == IDLE;

  function [13:0] arity(input reg [7:0] cmd);
    case (cmd)
      'h15: arity = 2;
      'h5C: arity = 8192;
      'h75: arity = 2;
      'hA0: arity = 2;
      'hAE: arity = 0;
      'hAF: arity = 0;
      'hB4: arity = 2;
      'hD1: arity = 2;
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
          state <= LOAD_COMMAND;
          counter <= arity(rom_q);
          blit <= rom_q == 8'h5C;
        end
        LOAD_COMMAND: begin
          state <= LATCH_COMMAND;
          addr <= blit ? 0 : addr + 1;
          oled_e <= 1;
          oled_dc <= 0;
          oled_dout <= rom_q;
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
          oled_dout <= blit ? vram_q : rom_q;
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

  // Command ROM for the SSD1322 OLED display
  rom #(
      .MEM_INIT_FILE("rom/oled.hex"),
      .DEPTH(64),
      .DATA_WIDTH(8)
  ) oled_rom (
      .clk (clk),
      .addr(addr[5:0]),
      .dout(rom_q)
  );

endmodule
