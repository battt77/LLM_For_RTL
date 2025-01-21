`timescale 1ns/100ps
module test ;
   reg          clk;
   reg          rstn;
   reg          en ;

   reg signed   [23:0]   x0_real;
   reg signed   [23:0]   x0_imag;
   reg signed   [23:0]   x1_real;
   reg signed   [23:0]   x1_imag;
   reg signed   [23:0]   x2_real;
   reg signed   [23:0]   x2_imag;
   reg signed   [23:0]   x3_real;
   reg signed   [23:0]   x3_imag;


   wire                  valid;
   wire signed  [23:0]   y0_real;
   wire signed  [23:0]   y0_imag;
   wire signed  [23:0]   y1_real;
   wire signed  [23:0]   y1_imag;
   wire signed  [23:0]   y2_real;
   wire signed  [23:0]   y2_imag;
   wire signed  [23:0]   y3_real;
   wire signed  [23:0]   y3_imag;


   initial begin
      clk = 0; //50MHz
      rstn = 1 ;
      #10 rstn = 1;
      forever begin
         #10 clk = ~clk; //50MHz
      end
   end


   RefModule u_fft (
      .clk        (clk    ),
      .rstn       (rstn    ),
      .en         (en     ),
      .x0_real    (x0_real),
      .x0_imag    (x0_imag),
      .x1_real    (x1_real),
      .x1_imag    (x1_imag),
      .x2_real    (x2_real),
      .x2_imag    (x2_imag),
      .x3_real    (x3_real),
      .x3_imag    (x3_imag),


      .yout_valid  (valid),
      .y0_real    (y0_real),
      .y0_imag    (y0_imag),
      .y1_real    (y1_real),
      .y1_imag    (y1_imag),
      .y2_real    (y2_real),
      .y2_imag    (y2_imag),
      .y3_real    (y3_real),
      .y3_imag    (y3_imag));


   //data input
   initial      begin
      en = 0 ;
      x0_real = 24'd1;
      x1_real = 24'd2;
      x2_real = 24'd3;
      x3_real = 24'd4;


      x0_imag = 24'd0;
      x1_imag = 24'd0;
      x2_imag = 24'd0;
      x3_imag = 24'd0;

      @(negedge clk) ;
      en = 1 ;

      forever begin
         @(negedge clk) ;
         x0_real = (x0_real > 22'h3F_ffff) ? 'b0 : x0_real + 1;
         x1_real = (x1_real > 22'h3F_ffff) ? 'b0 : x1_real + 1;
         x2_real = (x2_real > 22'h3F_ffff) ? 'b0 : x2_real + 31;
         x3_real = (x3_real > 22'h3F_ffff) ? 'b0 : x3_real + 1;
         x0_imag = (x0_imag > 22'h3F_ffff) ? 'b0 : x0_imag + 2;
         x1_imag = (x1_imag > 22'h3F_ffff) ? 'b0 : x1_imag + 5;
         x2_imag = (x2_imag > 22'h3F_ffff) ? 'b0 : x2_imag + 3;
         x3_imag = (x3_imag > 22'h3F_ffff) ? 'b0 : x3_imag + 6;

      end
   end
   
   initial begin
      $dumpfile("Result/fft4_(8guide4)/Result.vcd");
      $dumpvars;
   end
   
   // //finish simulation
   initial #1000     $finish ;

endmodule
