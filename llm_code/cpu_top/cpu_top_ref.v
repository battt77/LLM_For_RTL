module ysyx_23060235_cpu1(
	input clk,reset,
	output reg [31:0]pc=32'h8000_0000
);
	reg [31:0]inst;
	//reg [31:0]pc=32'h8000_0000;
	wire [6:0]op={inst[6:0]};
	wire [14:12]func3={inst[14:12]};
	wire [31:12]func7={inst[31:12]};
	wire [19:15]rs1={inst[19:15]};
	wire [24:20]rs2={inst[24:20]};
	wire [11:7]rd={inst[11:7]};
	wire [31:0]rd1;
	wire [31:0]rd2;
	wire [31:0]imm;
	wire [2:0]ExtOP;
	wire [3:0]ALUctr;
	wire [31:0]ALUresult;
	wire [0:0]Wen;
	wire [0:0]ALUAsrc;
	wire [0:0]ALUBsrc;
	wire [3:0]pcctr;
	wire [2:0]wdctr;
	//datamem
	wire [0:0]datawen;
	wire [0:0]valid;
	wire [7:0]datamask;
	wire [31:0] dataout;
	//alu
	wire [31:0]MUX_ALUina;
	wire [31:0]MUX_ALUinb;
	wire [31:0]wd;
	reg [31:0]nextpc=32'h8000_0000;
	wire [31:0]addpc;
	wire [31:0]jalr;
	reg zf,cf,of,sf;
	reg [31:0]rd1com;
	reg [31:0]rd2com;

	//inst wire
	wire [31:0]beqinst;
	wire [31:0]bneinst;
	wire [31:0]bltuinst;
	wire [31:0]bltinst;
	wire [31:0]bgeinst;
	wire [31:0]bgeuinst;
	wire [31:0]sltiuinst;
	wire [31:0]sltuinst;
	wire [31:0]sltinst;
	
	//csr
	wire        csr_rs;
	wire [31:0] csr_mask;
	wire [31:0] csr_wdata;
	wire        csr_write;
	wire        csr_read;
	wire        ecall;
	wire        mret;
	wire [31:0] entry;
	wire [31:0] csr_rdata;


	//补码标志
	reg [0:0] rd1flag=0;
	reg [0:0] rd2flag=0;

	//lflag
	wire [31:0]lflag;
	assign lflag={29'b0,inst[14:12]};

	//jalr
	assign jalr = ALUresult & 32'hFFFFFFFE;

	//Btype inst
	assign bneinst=(rd1==rd2)?addpc : imm+pc;
	assign beqinst=(rd1==rd2)?imm+pc: addpc;
	assign bltuinst=(rd1<rd2)?imm+pc:addpc;
	assign bltinst=(((rd1flag==0 && rd2flag==0)&&(rd1com<rd2com))||(rd1flag>rd2flag)||((rd1flag==1 && rd2flag==1)&&(rd1com>rd2com)))?imm+pc:addpc;
	assign bgeinst=(((rd1flag==0 && rd2flag==0)&&(rd1com>=rd2com))||(rd1flag<rd2flag)||((rd1flag==1 && rd2flag==1)&&(rd1com<=rd2com)))?imm+pc:addpc;
	assign bgeuinst=(rd1>=rd2)?imm+pc:addpc;

	//I,Rtype inst
	assign sltiuinst=(rd1<imm)?32'b1:32'b0;
	assign sltuinst=(rd1<rd2)?32'b1:32'b0;
	assign sltinst=(((rd1flag==0 && rd2flag==0)&&(rd1com<rd2com))||(rd1flag>rd2flag)||((rd1flag==1 && rd2flag==1)&&(rd1com>rd2com)))?32'b1:32'b0;


	//csr
	//csrr rd,csr 读一个csr中的值到rd中，相当于 csrrs rd,csr,zero
	//csrs csr, rs1 根据rs1的值按位对csr的值置1 ; csrw csr ,rs1 写rs1寄存器的值到csr中，相当于
	assign csr_mask = csr_rs? rd1 : 32'hffffffff;
	assign csr_wdata = csr_rs?  32'hffffffff: rd1;

	

	//ebreak
	reg [0:0] a0zero;

	//补码生成
	always @(rd1,rd2) begin
		if(rd1[31]==1) begin rd1com=~rd1+1; rd1flag=1;end
		else begin rd1com=rd1;rd1flag=0;end
		if(rd2[31]==1) begin rd2com=~rd2+1; rd2flag=1;end
		else begin rd2com=rd2;rd2flag=0;end
	end

	instmem instmem(.pc(pc),.reset(reset),.inst(inst));
	idu idu(.op(op),.func3(func3),.func7(func7),.inst(inst),.ExtOP(ExtOP),.ALUctr(ALUctr),.Wen(Wen),.ALUAsrc(ALUAsrc),.ALUBsrc(ALUBsrc),.pcctr(pcctr),.wdctr(wdctr),.datawen(datawen),.datamask(datamask),.valid(valid),.csr_rs(csr_rs),.ecall(ecall),.mret(mret),.csr_read(csr_read),.csr_write(csr_write));
	imm imm1(.immin(inst[31:7]),.ExtOP(ExtOP),.immout(imm));
	RegisterFile regfile(.clk(clk),.ra0(rs1),.ra1(rs2),.rd0(rd1),.rd1(rd2),.wd(wd),.wa(rd),.wen(Wen),.a0zero(a0zero));
	cpualu cpualu(.ina(MUX_ALUina),.inb(MUX_ALUinb),.sel(ALUctr),.out(ALUresult),.zf(zf),.cf(cf),.of(of),.sf(sf));
	pcadd pcadd(.pc(pc),.addpc(addpc));
	Datamem datamem(.clk(clk),.reset(reset),.addr(ALUresult),.mask(datamask),.lflag(lflag),.data(rd2),.valid(valid),.datawen(datawen),.readout(dataout));
	CSR csr(.clk(clk),.reset(reset),.csr_add(imm[11:0]),.csr_wdata(csr_wdata),.csr_write(csr_write),.csr_read(csr_read),.ecall(ecall),.mret(mret),.epc(pc),.csr_mask(csr_mask),.entry(entry),.csr_rdata(csr_rdata));

	MuxKeyWithDefault #(2,1,32) ALUina (MUX_ALUina,ALUAsrc,32'b0,{
		1'b0,pc,
		1'b1,rd1
		});
	MuxKeyWithDefault #(2,1,32) ALUinb (MUX_ALUinb,ALUBsrc,32'b0,{
		1'b0,imm,
		1'b1,rd2
		});	
	MuxKeyWithDefault #(8,3,32) wdsel (wd,wdctr,32'b0,{
		3'b000,ALUresult,
		3'b001,imm,
		3'b010,addpc,
		3'b011,dataout,
		3'b100,sltiuinst,
		3'b101,sltuinst,
		3'b110,sltinst,
		3'b111,csr_rdata
		});
	MuxKeyWithDefault #(11,4,32) pcsel (nextpc,pcctr,32'h8000_0000,{
		4'b0000,addpc,
		4'b0001,ALUresult,
		4'b0010,jalr,
		4'b0011,beqinst,
		4'b0100,bneinst,
		4'b0101,bltuinst,
		4'b0110,bltinst,
		4'b0111,bgeinst,
		4'b1000,bgeuinst,
		4'b1001,entry,
		4'b1010,csr_rdata
	 	});
	// import "DPI-C" function void dpic_ebreak();
	always @(posedge clk)begin 
		if(reset) pc<=32'h8000_0000;
		else if(inst==32'h00100073)begin
			dpic_ebreak();
			$display("\n----------EBREAK: HIT %s TRAP-----------\n",a0zero? "GOOD":"BAD");
			$finish;
		end
		else begin pc<=nextpc; 
			//$display("exec one inst %h\n",inst); 
			//$display("pc is %h\n",nextpc);
			end
	end
endmodule

