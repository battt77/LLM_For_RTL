module CSR (
    input wire clk,
    input wire reset,
    input wire [11:0] csr_add,
    input wire [31:0] csr_wdata,
    input wire csr_write,
    input wire csr_read,
    input wire ecall,
    input wire mret,
    input wire [31:0] epc,
    input wire [31:0] csr_mask,
    output wire [31:0] entry,
    output reg [31:0] csr_rdata
);

    // CSR Addresses
    localparam MEPC    = 12'h341;
    localparam MSTATUS = 12'h300;
    localparam MTVEC   = 12'h305;
    localparam MCAUSE  = 12'h342;

    // Internal Registers
    reg [31:2] mtvec_BASE;
    reg [1:0] mtvec_MODE;
    reg [31:0] mstatus;
    reg [31:0] mepc;
    reg mcause_INTR;
    reg [30:0] mcause_ECODE;

    // Internal Wires
    wire [31:0] mtvecout;
    wire [31:0] mcauseout;
    wire [30:0] ecode;

    // Entry Calculation
    assign entry = {mtvec_BASE, 2'b00};

    // Assignments for readback
    assign mtvecout = {mtvec_BASE, mtvec_MODE};
    assign mcauseout = {mcause_INTR, mcause_ECODE};
    assign ecode = ecall ? 11 : 0;

    // Register Initialization and Reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mepc <= 32'b0;
            mcause_ECODE <= 31'b0;
            mcause_INTR <= 1'b0;
            mtvec_BASE <= 30'b0;
            mtvec_MODE <= 2'b0;
            mstatus <= 32'h00001800;
        end else begin
            if (ecall) begin
                mepc <= epc;
                mcause_INTR <= 1'b0;
                mcause_ECODE <= ecode;
            end else begin
                if (csr_write) begin
                    if (csr_add == MEPC) begin
                        mepc <= (csr_mask & csr_wdata) | (~csr_mask & mepc);
                    end
                    if (csr_add == MTVEC) begin
                        mtvec_BASE <= (csr_mask[31:2] & csr_wdata[31:2]) | (~csr_mask[31:2] & mtvec_BASE);
                        // mtvec_MODE is not changed
                    end
                end
            end
        end
    end

    // CSR Read Logic
    always @(csr_read or csr_add or mret) begin
        if (csr_read) begin
            case (csr_add)
                MSTATUS: csr_rdata = mstatus;
                MEPC: csr_rdata = mepc;
                MTVEC: csr_rdata = mtvecout;
                MCAUSE: csr_rdata = mcauseout;
                default: csr_rdata = 32'b0; // Default value
            endcase
        end else if (mret) begin
            csr_rdata = mepc;
        end
    end

endmodule