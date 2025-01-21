`timescale 1ns / 1ps

module RegisterFile_tb;

  parameter ADDR_WIDTH = 5;
  parameter DATA_WIDTH = 32;

  reg clk;
  reg [ADDR_WIDTH-1:0] ra0;
  reg [ADDR_WIDTH-1:0] ra1;
  reg [DATA_WIDTH-1:0] wd;
  reg [ADDR_WIDTH-1:0] wa;
  reg wen;

  wire [DATA_WIDTH-1:0] rd0;
  wire [DATA_WIDTH-1:0] rd1;
  wire a0zero;
  
  reg mismatch_flag=0;

  RegisterFile #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) uut (
    .clk(clk), 
    .ra0(ra0), 
    .ra1(ra1), 
    .rd0(rd0), 
    .rd1(rd1), 
    .wd(wd), 
    .wa(wa), 
    .wen(wen), 
    .a0zero(a0zero)
  );

  function [DATA_WIDTH-1:0] random_data();
    return $random;
  endfunction

  initial begin
    clk = 0;
    ra0 = 0;
    ra1 = 0;
    wd = 0;
    wa = 0;
    wen = 0;

    #100;
    
    repeat (30) begin
      mismatch_flag =0;
      ra0 = $random % (1 << ADDR_WIDTH);
      ra1 = $random % (1 << ADDR_WIDTH);
      wa = $random % (1 << ADDR_WIDTH);
      
      wd = random_data();
      //wd = $random;
      wen = $random % 2;
      
      #10;
      
      if (wen && wa != 0) begin
        #10;
        if (uut.rf[wa] !== wd) begin
          $display("Write data mismatch at address %d", wa);
          mismatch_flag=1;
        end
      end
      #10;
      if (uut.rf[ra0] !== rd0) begin
        $display("ra0 mismatch at address %d, expected %h, got %h", ra0, uut.rf[ra0], rd0);
        mismatch_flag=1;
      end
      if (uut.rf[ra1] !== rd1) begin
        $display("ra1 mismatch at address %d, expected %h, got %h", ra1, uut.rf[ra1], rd1);
        mismatch_flag=1;
      end
      if ((ra0 == 10 && uut.rf[10] === 0 && !a0zero) || (ra0 == 10 && uut.rf[10] !== 0 && a0zero)) begin
        $display("a0zero is not asserted when register 10 is zero");
        mismatch_flag=1;
      end
      if(mismatch_flag==0)begin
        $display("Test passed");
      end
    end
    
    $finish;
  end

  always #5 clk = ~clk; 

//   initial begin
//     $monitor("Time = %t, clk = %b, ra0 = %d, ra1 = %d, rd0 = %h, rd1 = %h, wa = %d, wd = %h, wen = %b, a0zero = %b",
//              $time, clk, ra0, ra1, rd0, rd1, wa, wd, wen, a0zero);
//   end

endmodule