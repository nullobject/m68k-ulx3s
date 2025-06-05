module ram #(
    parameter DEPTH = 16384,
    parameter ADDRESS_WIDTH = $clog2(DEPTH)
) (
    input clk,
    input [1:0] we,
    input [ADDRESS_WIDTH-1:0] addr,
    input [15:0] data,
    output reg [15:0] q
);

  reg [15:0] mem[0:DEPTH-1];

  always @(posedge clk) begin
    q <= mem[addr];
    if (we[0]) mem[addr][7:0] <= data[7:0];
    if (we[1]) mem[addr][15:8] <= data[15:8];
  end

endmodule
