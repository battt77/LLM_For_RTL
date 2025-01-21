`timescale 1ps/1ps

module test ;
   //input
   reg          clk ;
   reg          rst_n ;
   reg          xin_en ;
   reg [11:0]   xin ;
   //output
   wire         yout_valid ;
   wire [28:0]  yout ;

   parameter    SIMU_CYCLE   = 64'd2000 ;
   parameter    SIN_DATA_NUM = 200 ;
//=====================================
// 50MHz clk generating
   localparam   TCLK_HALF     = 10_000;
   initial begin
      clk = 1'b0 ;
      forever begin
         # TCLK_HALF ;
         clk = ~clk ;
      end
   end

//============================
//  reset and finish

   initial begin
      rst_n = 1'b0 ;
      # 30 ;
      rst_n = 1'b1 ;
      # (TCLK_HALF * 2 * SIMU_CYCLE) ;
      $finish ;
   end

//=======================================
// read sinx.txt to get sin data into register
   reg          [11:0] stimulus [0: SIN_DATA_NUM-1] ;
   integer      i ;
   initial begin
      $readmemh("fir16/cosx0p25m7p5m12bit.txt", stimulus) ;
      i = 0 ;
      xin_en = 0 ;
      xin = 0 ;
      # 200 ;
      forever begin
         @(negedge clk) begin
            xin_en          = 1'b1 ;
            xin         = stimulus[i] ;
            if (i == SIN_DATA_NUM-1) begin
               i = 0 ;
            end
            else begin
               i = i + 1 ;
            end
         end
      end // forever begin
   end // initial begin

   initial begin
      $dumpfile("Result/fir16/Result.vcd");
      $dumpvars(0);
   end

RefModule u_fir_paral (
    .xin         (xin),
    .clk         (clk),
    .xin_en      (xin_en),
    .rstn        (rst_n),
    .yout_valid  (yout_valid),
    .yout        (yout));

endmodule // test
