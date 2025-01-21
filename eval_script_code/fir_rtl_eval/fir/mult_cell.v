module    mult_cell
  #(parameter N=4,
    parameter M=4)
 (
      input                     clk,
      input                     rstn,
      input                     en,
      input [M+N-1:0]           mult1,    //25b
      input [M-1:0]             mult2,   //12b
      input [M+N-1:0]           mult1_acci, //25b

      output reg [M+N-1:0]      mult1_o,     //25b
      output reg [M-1:0]        mult2_shift, //keep divisor for pipeline  12b
      output reg [N+M-1:0]      mult1_acco,   //keep acc results for pipeline 
      output reg                rdy
  );

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         rdy            <= 'b0 ;
         mult1_o        <= 'b0 ;
         mult1_acco     <= 'b0 ;
         mult2_shift    <= 'b0 ;
      end
      else if (en) begin
         rdy            <= 1'b1 ;
         mult2_shift    <= mult2 >> 1 ;
         mult1_o        <= mult1 << 1 ;
         if (mult2[0]) begin
            mult1_acco  <= mult1_acci + mult1 ;
         end
         else begin
            mult1_acco  <= mult1_acci ;
         end
      end
      else begin
         rdy            <= 'b0 ;
         mult1_o        <= 'b0 ;
         mult1_acco     <= 'b0 ;
         mult2_shift    <= 'b0 ;
      end
   end // always @ (posedge clk or negedge rstn)

endmodule