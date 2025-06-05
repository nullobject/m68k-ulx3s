module dual_port_ram #(
    parameter DEPTH = 16384,
    parameter ADDRESS_WIDTH = $clog2(DEPTH)
) (
    input clk,

    // port A
    input [1:0] we_a,
    input [ADDRESS_WIDTH-1:0] addr_a,
    input [15:0] data_a,
    output reg [15:0] q_a,

    // port B
    input [ADDRESS_WIDTH-1:0] addr_b,
    output reg [15:0] q_b
);

  reg [15:0] mem[0:DEPTH-1];

  always @(posedge clk) begin
    q_a <= mem[addr_a];
    q_b <= mem[addr_b];
    if (we_a[0]) mem[addr_a][7:0] <= data_a[7:0];
    if (we_a[1]) mem[addr_a][15:8] <= data_a[15:8];
  end

endmodule
