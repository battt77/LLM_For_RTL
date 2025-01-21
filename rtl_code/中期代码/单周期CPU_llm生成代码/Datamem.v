module Datamem(
    input clk,
    input reset,
    input [31:0]lflag,
    input [31:0] addr,
    input [31:0] data,
    input [7:0] mask,
    input valid,
    input datawen,
    output [31:0] readout
);

import "DPI-C" function void dpic_pmem_write(input int waddr,input byte wmask,input int wdata);
import "DPI-C" function void dpic_pmem_read(input int raddr, output int rdata, input bit ren,input int lflag);

always @(negedge clk) begin
  if (valid) begin // 有读写请求时
      //$display("valid=1\n");
      dpic_pmem_read(addr,readout,reset,lflag); 
      //$display("datamen pmem_read data= %h\n",readout);
      end
  if (datawen) begin // 有写请求时
      //$display("datawen=1\n");
      //$display("datamem pmem_write data= %h\n",data);
      dpic_pmem_write(addr, mask, data);
    end
  
  
  
  //else begin
  //  rdata = 0;
  //end
end
endmodule