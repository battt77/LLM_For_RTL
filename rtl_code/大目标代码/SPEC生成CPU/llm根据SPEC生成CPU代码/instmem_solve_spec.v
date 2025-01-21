module instmem(
    input [31:0] pc,
    //input clk,
    input reset,
    output reg [31:0]inst
);

import "DPI-C" function void dpic_pmem_read(input int raddr, output int rdata, input bit ren,input int lflag);

always @(*) begin
    dpic_pmem_read(pc,inst,reset,32'b00000000000000000000000000000010);
    //$display("instmem dpic_pmem_read exec\n");
end
endmodule