module dual_port_ram #(
    parameter DEPTH_A = 16384,
    parameter DEPTH_B = 16384,
    parameter ADDRESS_WIDTH_A = $clog2(DEPTH_A),
    parameter ADDRESS_WIDTH_B = $clog2(DEPTH_B)
) (
    input clk,

    // port A
    input wr_a,
    input [ADDRESS_WIDTH_A-1:0] addr_a,
    input [3:0] data_a,

    // port B
    input [ADDRESS_WIDTH_B-1:0] addr_b,
    output reg [7:0] q_b
);

  reg [3:0] ram[0:DEPTH_A-1];

  always @(posedge clk) begin
    if (we_a) begin
      ram[addr] <= data_a;
    end
    q_b <= {ram[{addr_b, 1}], ram[{addr_b, 0}]};
  end

endmodule
