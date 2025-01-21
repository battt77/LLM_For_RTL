module pcadd(
    input [31:0] pc,
    output reg [31:0] addpc

);
//assign addpc=pc+32'h0000_0004;
always @(*) begin
    addpc=pc+32'h0000_0004;
end

endmodule