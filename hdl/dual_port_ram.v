module dual_port_ram #(
    parameter DEPTH = 16384,
    parameter ADDRESS_WIDTH = $clog2(DEPTH)
) (
    input clk,

    // port A
    input wr_a,
    input [1:0] mask_a,
    input [ADDRESS_WIDTH-1:0] addr_a,
    input [15:0] data_a,
    output reg [15:0] q_a,

    // port B
    input [ADDRESS_WIDTH-1:0] addr_b,
    output reg [15:0] q_b
);

  reg [7:0] ram_hi[0:DEPTH-1];
  reg [7:0] ram_lo[0:DEPTH-1];

  always @(posedge clk) begin
    if (wr_a) begin
      if (mask_a[1]) ram_hi[addr_a] <= data_a[15:8];
      if (mask_a[0]) ram_lo[addr_a] <= data_a[7:0];
    end
    q_a <= {ram_hi[addr_a], ram_lo[addr_a]};
    q_b <= {ram_hi[addr_b], ram_lo[addr_b]};
  end

endmodule
