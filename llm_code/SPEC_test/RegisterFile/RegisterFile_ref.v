module RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
  input clk,
	input [ADDR_WIDTH-1:0] ra0, ra1,
	output [DATA_WIDTH-1:0] rd0, rd1,
  input [DATA_WIDTH-1:0] wd,
  input [ADDR_WIDTH-1:0] wa,
  input wen,
  output [0:0] a0zero
);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  // import "DPI-C" function void get_gpr_ptr(input logic [63:0] a []);
  // initial get_gpr_ptr(rf); 
	assign rd0=rf[ra0];
	assign rd1=rf[ra1];
  assign a0zero = ~|rf[10]; 
  always @(posedge clk) begin
    if (wen&&wa!=0) rf[wa] <= wd;
    //$display("write to reg:wa=%d,data=%h\n",wa,wd);
  end
endmodule
