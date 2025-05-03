module ram #(
  parameter DEPTH = 16384,
  parameter ADDRESS_WIDTH = $clog2(DEPTH)
) (
  input clk,
  input we,
  input [1:0] mask,
  input [ADDRESS_WIDTH-1:1] addr,
  input [15:0] din,
  output reg [15:0] dout
);

reg [1:0][15:0] ram[0:DEPTH-1];

always @(posedge clk) begin
  if (we) begin
    if (mask[0]) ram[addr][0] <= din[7:0];
    if (mask[1]) ram[addr][1] <= din[15:8];
  end
  dout <= ram[addr];
end

endmodule
