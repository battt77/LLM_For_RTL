module idu(
	input	   [6:0]   op,
	input      [14:12] func3,
	input      [31:12] func7,
	input      [31:0]  inst,
	output reg [2:0]   ExtOP,
	output reg [3:0]   ALUctr,//考虑独热
	output reg         Wen,
	output reg [0:0]   ALUAsrc,
	output reg [0:0]   ALUBsrc,
	output reg [2:0]   wdctr,
	output reg [3:0]   pcctr,
	output reg         datawen,
	output reg         valid,
	output reg [7:0]   datamask,
	
	output wire        csr_rs,
	output wire        ecall,
	output wire        mret,
	output wire        csr_read,
	output wire        csr_write
	
);
	reg [7:0] mask;
	MuxKeyWithDefault #(5,3,8) masksel (mask,func3,8'b00000000,{
		3'b010,8'b00001111, //sw lw
		3'b001,8'b00000011, //sh lh
		3'b000,8'b00000001, //sb lb
		3'b100,8'b00000001, //lbu
		3'b101,8'b00000011  //lhu
		});
	reg [3:0] alusel;
	MuxKeyWithDefault #(3,3,4) andsel (alusel,func3,4'b0010,{
		3'b111,4'b0010, //and andi
		3'b110,4'b0011, //or ori
		3'b100,4'b0100 //xor xori
		});

	//csr
	reg [3:0] csr_sel;
	always @(csr_sel)begin
		case(csr_sel)
			4'b0000:begin
				csr_rs=0;ecall=0;mret=0;csr_read=0;csr_write=0;
			end
			4'b0001:begin//ecall
				csr_rs=0;ecall=1;mret=0;csr_read=0;csr_write=0;
			end
			4'b0010:begin//mret
				csr_rs=0;ecall=0;mret=1;csr_read=0;csr_write=0;
			end
			4'b0011:begin//csrrw
				csr_rs=0;ecall=0;mret=0;csr_read=1;csr_write=1;
			end
			4'b0100:begin//csrrs
				csr_rs=1;ecall=0;mret=0;csr_read=1;csr_write=1;
			end
			default :begin csr_rs=0;ecall=0;mret=0;csr_read=0;csr_write=0; end
		endcase
	end


	always @(*) begin
		case(op)
			7'b1110011:begin
				case(func3)
					3'b000 :begin
						case(inst)
							32'b00000000000000000000000001110011:begin//ecall
								ExtOP=3'b000;
								Wen=0;
								ALUAsrc=1;
								ALUBsrc=0;
								ALUctr=4'b0000;
								wdctr=3'b000;
								pcctr=4'b1001;
								datawen=0;
								valid=0;
								csr_sel=4'b0001;
								datamask=8'b00000000;
							end
							32'b00110000001000000000000001110011:begin//mret
								ExtOP=3'b000;
								Wen=0;
								ALUAsrc=1;
								ALUBsrc=0;
								ALUctr=4'b0000;
								wdctr=3'b000;
								pcctr=4'b1010;
								datawen=0;
								valid=0;
								csr_sel=4'b0010;
								datamask=8'b00000000;
							end
							default:begin
								ExtOP=3'b000;Wen=0;ALUAsrc=1;ALUBsrc=0;	ALUctr=4'b0000;	wdctr=3'b000;pcctr=4'b0000;	datawen=0;valid=0;csr_sel=4'b0000;datamask=8'b00000000;
							end
						endcase
					end
					3'b001:begin//csrrw
						//$display("in csrrw\n");
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0000;
						wdctr=3'b111;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0011;
						datamask=8'b00000000;
					end
					3'b010:begin//csrrs
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0000;
						wdctr=3'b111;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0100;
						datamask=8'b00000000;
					end
					default:begin
								ExtOP=3'b000;Wen=0;ALUAsrc=1;ALUBsrc=0;	ALUctr=4'b0000;	wdctr=3'b000;pcctr=4'b0000;	datawen=0;valid=0;csr_sel=4'b0000;datamask=8'b00000000;
							end
				endcase

			end
			7'b0110111,7'b0010111:begin //U-type
				ExtOP=3'b001;
				Wen=1;
				ALUAsrc=0;
				ALUBsrc=0;
				ALUctr=4'b0000;
				wdctr={1'b0,op[6:5]};
				pcctr=4'b0000;
				datawen=0;
				valid=0;
				datamask=8'b00000000;
				csr_sel=4'b0000;
				
			end
			7'b0010011:begin //I-type
				case(func3)
					3'b000:begin //addi
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0000;
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b101:begin //srli，srai
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr={3'b011,func7[30]};
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000;
					end
					3'b001:begin //slli
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0101;
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000;
					end
					3'b011:begin //sltiu 伪指令 seqz
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0000;
						wdctr=3'b100;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000;
					end
					3'b111,3'b110,3'b100:begin //andi ori xori
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=alusel;
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000;
					end
					default:begin //addi
						ExtOP=3'b000;Wen=1;	ALUAsrc=1;ALUBsrc=0;ALUctr=4'b0000;	wdctr=3'b000;pcctr=4'b0000;datawen=0;valid=0;csr_sel=4'b0000;datamask=8'b00000000; end
				endcase
			end

			7'b0000011:begin //I-type l
				case(func3)
					3'b000,3'b001,3'b010:begin //lb lh lw
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0000;
						wdctr=3'b011;
						pcctr=4'b0000;
						datawen=0;
						valid=1;
						csr_sel=4'b0000;
						datamask=mask; end
					3'b100:begin //lbu
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0000;
						wdctr=3'b011;
						pcctr=4'b0000;
						datawen=0;
						valid=1;
						csr_sel=4'b0000;
						datamask=mask; end
					3'b101:begin //lhu
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=0;
						ALUctr=4'b0000;
						wdctr=3'b011;
						pcctr=4'b0000;
						datawen=0;
						valid=1;
						csr_sel=4'b0000;
						datamask=mask; end
					default:begin
						ExtOP=3'b000;Wen=1;	ALUAsrc=1;ALUBsrc=0;ALUctr=4'b0000;	wdctr=3'b011;pcctr=4'b0000;	datawen=0;valid=1;csr_sel=4'b0000;datamask=mask; end
				endcase
			end
			7'b0100011:begin //S-type
				ExtOP=3'b010;
				Wen=0;
				ALUAsrc=1;
				ALUBsrc=0;
				ALUctr=4'b0000;
				wdctr=3'b000;
				pcctr=4'b0000;
				datawen=1;
				valid=1;
				csr_sel=4'b0000;
				datamask=mask;
			end
			7'b0110011:begin //R-type
				case(func3)
					3'b000:begin //add or sub
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr={3'b000,func7[30]};
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b010:begin //slt
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=0;
						ALUBsrc=0;
						ALUctr=4'b0010;
						wdctr=3'b110;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b001:begin //sll
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=4'b0101;
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b101:begin //srl,sra
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr={func7[30],3'b110};
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b011:begin //sltu
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=0;
						ALUBsrc=0;
						ALUctr=0010;
						wdctr=3'b101;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b111,3'b110,3'b100:begin //and or xor
						ExtOP=3'b000;
						Wen=1;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=alusel;
						wdctr=3'b000;
						pcctr=4'b0000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					default:begin //add
						ExtOP=3'b000;Wen=1;	ALUAsrc=1;ALUBsrc=1;ALUctr=4'b0000;	wdctr=3'b000;pcctr=4'b0000;	datawen=0;valid=0;csr_sel=4'b0000;datamask=8'b00000000; end
				endcase
			end
			7'b1100011:begin //B-type
				case(func3)
					3'b000:begin //beq
						ExtOP=3'b011;
						Wen=0;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=4'b0000;
						wdctr=3'b000;
						pcctr=4'b0011;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b001:begin //bne
						ExtOP=3'b011;
						Wen=0;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=4'b0000;
						wdctr=3'b000;
						pcctr=4'b0100;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b100:begin //blt
						ExtOP=3'b011;
						Wen=0;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=4'b0000;
						wdctr=3'b000;
						pcctr=4'b0110;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b101:begin //bge
						ExtOP=3'b011;
						Wen=0;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=4'b0000;
						wdctr=3'b000;
						pcctr=4'b0111;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b110:begin //bltu
						ExtOP=3'b011;
						Wen=0;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=4'b0000;
						wdctr=3'b000;
						pcctr=4'b0101;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end
					3'b111:begin //bgeu
						ExtOP=3'b011;
						Wen=0;
						ALUAsrc=1;
						ALUBsrc=1;
						ALUctr=4'b0000;
						wdctr=3'b000;
						pcctr=4'b1000;
						datawen=0;
						valid=0;
						csr_sel=4'b0000;
						datamask=8'b00000000; end	
					default:begin //beq
						ExtOP=3'b011;Wen=0;	ALUAsrc=1;	ALUBsrc=1;ALUctr=4'b0000;wdctr=3'b000;pcctr=4'b0011;datawen=0;valid=0;csr_sel=4'b0000;datamask=8'b00000000; end
				endcase
			end
			7'b1100111:begin //jalr
				ExtOP=3'b000;
				Wen=1;
				ALUAsrc=1;
				ALUBsrc=0;
				ALUctr=4'b0000;
				wdctr=3'b010;
				pcctr=4'b0010;
				datawen=0;
				valid=0;
				csr_sel=4'b0000;
				datamask=8'b00000000;
			end
			7'b1101111:begin //jal

				ExtOP=3'b100;
				Wen=1;
				ALUAsrc=0;
				ALUBsrc=0;
				ALUctr=4'b0000;
				wdctr=3'b010;
				pcctr=4'b0001;
				datawen=0;
				valid=0;
				csr_sel=4'b0000;
				datamask=8'b00000000;
			end
			default:begin
				ExtOP=3'b000;Wen=0;	ALUAsrc=1;ALUBsrc=0;ALUctr=4'b0000;wdctr=3'b010;pcctr=4'b0000;datawen=0;valid=0;csr_sel=4'b0000;datamask=8'b00000000;end
		endcase
	end
	//wire [31:20] q={func7[31:20]};
endmodule
