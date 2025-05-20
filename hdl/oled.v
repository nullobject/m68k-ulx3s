module oled (
  input clk,
  input rst,
  input start,
  input [7:0] command,
  input [7:0] data,
  output reg oled_cs,
  output reg oled_e,
  output reg oled_rw,
  output reg oled_dc,
  output reg [7:0] q
);

localparam
  IDLE = 0,
  LOAD_COMMAND = 1,
  LATCH_COMMAND = 2,
  LOAD_DATA = 3,
  LATCH_DATA = 4,
  DONE = 5;

reg [2:0] state;

always @(posedge clk, posedge rst) begin
  if (rst) begin
    state <= IDLE;
    oled_cs <= 1;
    oled_e <= 1;
    oled_rw <= 0;
    oled_dc <= 0;
  end else begin
    case (state)
      IDLE: begin
        if (start) begin
          state <= LOAD_COMMAND;
          oled_cs <= 0;
        end
      end
      LOAD_COMMAND: begin
        state <= LATCH_COMMAND;
        oled_dc <= 0;
        oled_e <= 1;
        q <= command;
      end
      LATCH_COMMAND: begin
        state <= LOAD_DATA;
        oled_e <= 0;
      end
      LOAD_DATA: begin
        state <= LATCH_DATA;
        oled_e <= 1;
        oled_dc <= 1;
        q <= data;
      end
      LATCH_DATA: begin
        state <= DONE;
        oled_e <= 0;
      end
      DONE: begin
        state <= IDLE;
        oled_cs <= 1;
        oled_e <= 1;
      end
      default: begin
        rcv_next_state = IDLE;
      end
    endcase
  end
end

// Initialization bytes for the OLED display
rom #(
  .MEM_INIT_FILE("OLED.hex"),
  .DEPTH(64),
  .DATA_WIDTH(8)
) init_rom (
  .clk(clk),
  .addr(),
  .dout()
);

endmodule
