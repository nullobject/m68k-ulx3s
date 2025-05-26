/* verilator lint_off DECLFILENAME */

module oled (
    input clk,
    input rst,

    output ready,

    output [13:0] vram_addr,
    /* verilator lint_off UNUSEDSIGNAL */
    input  [ 7:0] vram_q,
    /* verilator lint_on UNUSEDSIGNAL */

    // OLED
    output       oled_cs,
    output       oled_rst,
    output       oled_dc,
    output       oled_e,
    output [7:0] oled_dout
);

  // states
  localparam INIT = 0;
  localparam INIT_START = 1;
  localparam INIT_WAIT = 2;
  localparam IDLE = 3;

  reg [2:0] state;
  reg [13:0] addr;
  reg [13:0] addr_end;

  wire [7:0] rom_q;
  wire start = state == INIT_START;
  wire tx_ready;
  wire next;

  assign ready = state == IDLE;
  assign vram_addr = addr;
  assign oled_cs = state == INIT || state == IDLE;
  assign oled_rst = !rst;

  always @(posedge clk, posedge rst) begin
    if (rst) begin
      addr <= 0;
    end else begin
      if (next) addr <= addr + 1;
    end
  end

  always @(posedge clk, posedge rst) begin
    if (rst) begin
      state <= INIT;
    end else begin
      case (state)
        INIT: begin
          state <= INIT_START;
          addr_end <= 47;
        end
        INIT_START: begin
          state <= INIT_WAIT;
        end
        INIT_WAIT: begin
          if (tx_ready) begin
            if (addr == addr_end) state <= IDLE;
            else state <= INIT_START;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end

  oled_tx oled_tx (
      .clk(clk),
      .rst(rst),
      .start(start),
      .ready(tx_ready),
      .next(next),
      .data(rom_q),
      .oled_dc(oled_dc),
      .oled_e(oled_e),
      .oled_dout(oled_dout)
  );

  // ROM containing initialisation sequence for the OLED display
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

module oled_tx (
    input clk,
    input rst,

    // control signals
    input  start,
    output ready,
    output next,

    // data bus
    input [7:0] data,

    // OLED
    output reg oled_dc,
    output reg oled_e,
    output [7:0] oled_dout
);

  // states
  localparam IDLE = 0;
  localparam LOAD_COMMAND = 1;
  localparam LATCH_COMMAND = 2;
  localparam LOAD_DATA = 3;
  localparam LATCH_DATA = 4;

  reg [ 2:0] state;
  reg [13:0] counter;

  assign ready = state == IDLE;
  assign next = state == LATCH_COMMAND || state == LATCH_DATA;
  assign oled_dout = data;

  function [13:0] arity(input reg [7:0] cmd);
    case (cmd)
      'h15: arity = 2;
      // 'h5C: arity = 8192;
      'h5C: arity = 4;
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
      state   <= IDLE;
      oled_dc <= 0;
      oled_e  <= 1;
    end else begin
      case (state)
        IDLE: begin
          if (start) state <= LOAD_COMMAND;
        end
        LOAD_COMMAND: begin
          state   <= LATCH_COMMAND;
          counter <= arity(data);
          oled_dc <= 0;
          oled_e  <= 1;
        end
        LATCH_COMMAND: begin
          state  <= counter > 0 ? LOAD_DATA : IDLE;
          oled_e <= 0;
        end
        LOAD_DATA: begin
          state   <= LATCH_DATA;
          counter <= counter - 1;
          oled_dc <= 1;
          oled_e  <= 1;
        end
        LATCH_DATA: begin
          state  <= counter > 0 ? LOAD_DATA : IDLE;
          oled_e <= 0;
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule
