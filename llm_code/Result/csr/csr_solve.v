module CSR(
    input wire clk,
    input wire reset,
    input wire [11:0] csr_add,
    input wire [31:0] csr_wdata,  // Data to be written to CSR
    input wire csr_write,         // Write enable signal
    input wire csr_read,          // Read enable signal
    input wire ecall,
    input wire mret,
    input wire [31:0] epc,
    input wire [31:0] csr_mask,
    output wire [31:0] entry,     // Entry address
    output reg [31:0] csr_rdata   // Data read from CSR
);

`define MEPC    12'h341
`define MSTATUS 12'h300
`define MTVEC   12'h305
`define MCAUSE  12'h342

reg [31:2] mtvec_BASE;
reg [1:0]  mtvec_MODE;
reg [31:0] mstatus;
reg [31:0] mepc;
reg        mcause_INTR;
reg [30:0] mcause_ECODE;

wire [31:0] mtvecout;  // Composed mtvec output
wire [31:0] mcauseout; // Composed mcause output
wire [30:0] ecode;

// Exception code logic
assign ecode = ecall ? 11 : 0;

// Exception handling and CSR operations
always @(posedge clk) begin
    if (reset) begin
        // Initialize registers during reset
        mepc <= 0;
        mcause_ECODE <= 0;
        mcause_INTR <= 0;
        mtvec_BASE <= 0;
        mtvec_MODE <= 0;
        mstatus <= 32'h00001800;
    end else begin
        if (ecall) begin
            mepc <= epc; 
            mcause_INTR <= 1'b0;
            mcause_ECODE <= ecode;
        end else begin 
            if (csr_write && csr_add == `MEPC)
                mepc <= (csr_mask & csr_wdata) | (~csr_mask & mepc);
            if (csr_write && csr_add == `MTVEC)
                mtvec_BASE <= (csr_mask[31:2] & csr_wdata[31:2]) | 
                              (~csr_mask[31:2] & mtvec_BASE);
        end
    end
end

assign entry = {mtvec_BASE, 2'b0};
assign mtvecout = {mtvec_BASE, mtvec_MODE};
assign mcauseout = {mcause_INTR, mcause_ECODE};

// CSR read logic
always @(csr_read or csr_add or mret) begin
    if (csr_read && csr_add == `MSTATUS)
        csr_rdata = mstatus;
    if ((csr_read && csr_add == `MEPC) || mret)
        csr_rdata = mepc;
    if (csr_read && csr_add == `MTVEC)
        csr_rdata = mtvecout;
    if (csr_read && csr_add == `MCAUSE)
        csr_rdata = mcauseout;
end

endmodule