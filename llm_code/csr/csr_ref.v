module CSR(
    input wire clk,
    input wire reset,
    input wire [11:0] csr_add,
    input wire [31:0] csr_wdata,  // 写入CSR的数据
    input wire csr_write,         // 写使能信号
    input wire csr_read,          // 读使能信号
    input wire ecall,
    input wire mret,
    input wire [31:0] epc,
    input wire [31:0] csr_mask,
    output [31:0] entry, // 改成wire
    output reg [31:0] csr_rdata  // 从CSR读出的数据
);
`define MEPC    12'h341
`define MSTATUS 12'h300
`define MTVEC   12'h305
`define MCAUSE  12'h342

//mtvec 31-2为base 1-0为mode,用于设置中断模式
//mstatus 为difftest设置为1800
//mepc 在ecall时设置为此时的pc，在需要csr写入时完成按mask的写入
//mcause 最高位用来判断是中断还是异常，剩下位表示具体类型

reg [31:2] mtvec_BASE;
reg [1:0]  mtvec_MODE;
reg [31:0] mstatus;
reg [31:0] mepc;
reg        mcause_INTR;
reg [30:0] mcause_ECODE;

wire [31:0] mtvecout;  // 改成wire
wire [31:0] mcauseout; // 改成wire

wire [30:0] ecode;
assign ecode = ecall? 11:0;
// 异常处理逻辑
always @(posedge clk) begin
    if (reset) begin
        // 复位时初始化寄存器
        mepc <= 0;
        mcause_ECODE <= 0;
        mcause_INTR <= 0;
        mtvec_BASE <= 0;
        mtvec_MODE <= 0;
        mstatus <= 32'h00001800;
    end 
    else begin
        if (ecall) begin
            mepc <= epc; 
            mcause_INTR <= 1'b0;
            mcause_ECODE <= ecode;
        end
        else begin 
            if(csr_write && csr_add== `MEPC)
                mepc <= (csr_mask & csr_wdata) | (~csr_mask & mepc);//更新mask的，保存非mask的原始值
            if(csr_write && csr_add== `MTVEC)
                mtvec_BASE <= (csr_mask[31:2] & csr_wdata[31:2]) | (~csr_mask[31:2] & mtvec_BASE);
        end
    end
end

assign entry = {mtvec_BASE,2'b0};
assign mtvecout = {mtvec_BASE,mtvec_MODE};
assign mcauseout = {mcause_INTR,mcause_ECODE};

always @(csr_read or csr_add or mret) begin
    if(csr_read && csr_add== `MSTATUS)
        csr_rdata=mstatus;
    if((csr_read && csr_add==`MEPC) || mret)
        csr_rdata=mepc;
    if(csr_read && csr_add==`MTVEC)
        csr_rdata=mtvecout;
    if(csr_read && csr_add==`MCAUSE)
        csr_rdata=mcauseout;
    //$display("csr_rdata=0x%h\n",csr_rdata);
end

endmodule
