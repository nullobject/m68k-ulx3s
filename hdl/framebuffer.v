module framebuffer #(
    parameter DEPTH_A = 4096,
    parameter DEPTH_B = 8192,
    parameter ADDRESS_WIDTH_A = $clog2(DEPTH_A),
    parameter ADDRESS_WIDTH_B = $clog2(DEPTH_B)
) (
    input clk,

    // port A
    input wr_a,
    input [1:0] mask_a,
    input [ADDRESS_WIDTH_A-1:0] addr_a,
    input [15:0] data_a,
    output reg [15:0] q_a,

    // port B
    input [ADDRESS_WIDTH_B-1:0] addr_b,
    output reg [7:0] q_b
);

  reg [7:0] ram_hi[0:DEPTH_A-1];
  reg [7:0] ram_lo[0:DEPTH_A-1];

  always @(posedge clk) begin
    if (wr_a) begin
      if (mask_a[1]) ram_hi[addr_a] <= data_a[15:8];
      if (mask_a[0]) ram_lo[addr_a] <= data_a[7:0];
    end
    q_a <= {ram_hi[addr_a], ram_lo[addr_a]};
    q_b <= addr_b[0] ? ram_hi[addr_b[ADDRESS_WIDTH_B-1:1]] : ram_lo[addr_b[ADDRESS_WIDTH_B-1:1]];
  end

endmodule
