module cpualu(
	input [31:0] ina,inb,
	input [3:0] sel,
	output [31:0] out
);

	wire [31:0]addf,nof,andf,orf,xorf;
	wire [31:0]sll,srl;
	wire [31:0]srai;
	wire [31:0] sra;
	wire borrow;
	wire [31:0] inb1;
	
	assign andf=ina&inb;
	assign orf=ina|inb;
	assign xorf=ina^inb;
	assign inb1=inb^{32{sel[0]}};
	assign {borrow,addf}=ina+inb1+{{31{1'b0}},sel[0]};
	assign sll=ina<<inb[4:0];
	assign srl=ina>>inb[4:0];
	assign srai=({32{ina[31]}} << (6'd32-{1'b0,inb[4:0]}))|(ina>>inb[4:0]);
	assign sra=({32{ina[31]}} << (6'd32-{1'b0,inb[4:0]}))|(ina>>inb[4:0]);	
	MuxKeyWithDefault #(9,4,32) alu1 (out,sel,32'b0,{
		4'b0000,addf,
		4'b0001,addf,
		4'b0010,andf,
		4'b0011,orf,
		4'b0100,xorf,
		4'b0101,sll,
		4'b0110,srl,
		4'b0111,srai,
		4'b1110,sra
		});
endmodule
