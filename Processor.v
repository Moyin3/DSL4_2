module Processor(
    input CLK,
    input RESET,

    inout [7:0] BUS_DATA,
    output [7:0] BUS_ADDR,
    output BUS_WE,

    output [7:0] ROM_ADDRESS,
    input [7:0] ROM_DATA,

    input [1:0] BUS_INTERRUPTS_RAISE,
    output [1:0] BUS_INTERRUPTS_ACK
);

// ============================
// Registers (current state)
// ============================
reg [7:0] CurrPC, NextPC;
reg [7:0] CurrRegA, NextRegA;
reg [7:0] CurrRegB, NextRegB;
reg [7:0] CurrContext, NextContext;

reg [7:0] CurrState, NextState;

reg [7:0] CurrBusAddr, NextBusAddr;
reg [7:0] CurrBusOut, NextBusOut;
reg CurrBusWE, NextBusWE;

reg [1:0] CurrInterruptAck, NextInterruptAck;

reg [3:0] CurrOpcode, NextOpcode;

// ============================
// Tristate bus
// ============================
assign BUS_DATA = CurrBusWE ? CurrBusOut : 8'hZZ;
assign BUS_ADDR = CurrBusAddr;
assign BUS_WE   = CurrBusWE;
assign BUS_INTERRUPTS_ACK = CurrInterruptAck;
assign ROM_ADDRESS = CurrPC;

wire [7:0] BusDataIn = BUS_DATA;
wire [3:0] Opcode = CurrOpcode;       // registered in DECODE from instruction byte
wire [3:0] AluOp  = ROM_DATA[7:4];   // combinatorial: correct during DECODE when ALU latches

// ============================
// ALU
// ============================
wire [7:0] AluOut;

ALU alu(
    .CLK(CLK),
    .RESET(RESET),
    .IN_A(CurrRegA),
    .IN_B(CurrRegB),
    .ALU_Op_Code(AluOp),
    .OUT_RESULT(AluOut)
);

// ============================
// States
// ============================
parameter FETCH     = 8'h00;
parameter DECODE    = 8'h01;
parameter EXECUTE   = 8'h02;
parameter MEM_WAIT  = 8'h03;


// ============================
// Sequential block
// ============================
always @(posedge CLK) begin
    if (RESET) begin
        CurrState <= FETCH;
        CurrPC <= 8'h00;
        CurrRegA <= 8'h00;
        CurrRegB <= 8'h00;
        CurrContext <= 8'h00;
        CurrBusAddr <= 8'h00;
        CurrBusOut <= 8'h00;
        CurrBusWE <= 1'b0;
        CurrInterruptAck <= 2'b00;
        CurrOpcode <= 4'h0;
    end else begin
        CurrState <= NextState;
        CurrPC <= NextPC;
        CurrRegA <= NextRegA;
        CurrRegB <= NextRegB;
        CurrContext <= NextContext;
        CurrBusAddr <= NextBusAddr;
        CurrBusOut <= NextBusOut;
        CurrBusWE <= NextBusWE;
        CurrInterruptAck <= NextInterruptAck;
        CurrOpcode <= NextOpcode;
    end
end

// ============================
// Combinational block
// ============================
always @* begin

    // Default assignments
    NextState = CurrState;
    NextPC = CurrPC;
    NextRegA = CurrRegA;
    NextRegB = CurrRegB;
    NextContext = CurrContext;

    NextBusAddr = 8'h00;
    NextBusOut  = CurrBusOut;
    NextBusWE   = 1'b0;

    NextInterruptAck = 2'b00;
    NextOpcode = CurrOpcode;

    case (CurrState)

    // ------------------------
    // FETCH: check for timer interrupt, otherwise move to DECODE
    FETCH: 
    begin
        if (BUS_INTERRUPTS_RAISE[1]) begin
            // Save return address, jump to interrupt handler at 0x40
            NextContext = CurrPC;
            NextPC = 8'h40; // interrupt handler
            NextInterruptAck = 2'b10;
            NextState = FETCH;
        end else begin
            NextState = DECODE;
        end
    end

    // ------------------------
    // DECODE: advance PC so ROM outputs the operand byte by EXECUTE
    
    DECODE:
    begin
        NextOpcode = ROM_DATA[3:0]; // latch instruction opcode before PC advances
        NextPC = CurrPC + 8'h01;
        NextState = EXECUTE;
    end

    // ------------------------
    EXECUTE:
    begin
        case (Opcode)

        4'h0: begin // READ -> A
            NextBusAddr = ROM_DATA; // operand = RAM/peripheral address
            NextState = MEM_WAIT;
        end

        4'h1: begin // READ -> B
            NextBusAddr = ROM_DATA;
            NextState = MEM_WAIT;
        end

        4'h2: begin // WRITE A
            NextBusAddr = ROM_DATA;
            NextBusOut = CurrRegA;
            NextBusWE = 1'b1;
            NextState = MEM_WAIT;
        end

        4'h3: begin // WRITE B
            NextBusAddr = ROM_DATA;
            NextBusOut = CurrRegB;
            NextBusWE = 1'b1;
            NextState = MEM_WAIT;
        end

        4'h4: begin // ALU -> A
            NextRegA = AluOut;
            NextState = FETCH;
        end

        4'h5: begin // ALU -> B
            NextRegB = AluOut;
            NextState = FETCH;
        end

        4'h6: begin // IF A==B GOTO
            if (CurrRegA == CurrRegB)
                NextPC = ROM_DATA;
            else
                NextPC = CurrPC + 8'h01;
            NextState = FETCH;
        end

        4'h7: begin // GOTO addr
            NextPC = ROM_DATA;
            NextState = FETCH;
        end
        
        4'h8: begin // Load Immediate -> A
            NextRegA = ROM_DATA;
            NextPC = CurrPC + 8'h01;
            NextState = FETCH;
        end
        
        4'h9: begin // Load Immediate -> B
            NextRegB = ROM_DATA;
            NextPC = CurrPC + 8'h01;
            NextState = FETCH;
        end

        4'hA: begin // RETURN from interrupt
            NextPC = CurrContext;
            NextState = FETCH;
        end

        default: begin
            NextPC = CurrPC + 1;
            NextState = FETCH;
        end

        endcase
    end

    // ------------------------
    // MEM_WAIT: latch bus read result, advance PC past operand byte
    MEM_WAIT:
    begin
        if (Opcode == 4'h0)
            NextRegA = BusDataIn;
        else if (Opcode == 4'h1)
            NextRegB = BusDataIn;

        NextPC = CurrPC + 8'h01;
        NextState = FETCH;
    end
    
    default: NextState = FETCH;

    endcase
end

endmodule