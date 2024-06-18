/*
CO224 - Computer Architecture
Lab 06 - Part 3 Instruction cache
Group 32
*/

`timescale 1ns/100ps
module instruction_cache (
    clock, reset, cpu_address, cpu_instruction,cpu_busywait, 
    mem_read, mem_address, mem_instruction, mem_busywait
);

//input port declaration
input clock;
input reset;

//inputs to instruction cache from CPU
input [9:0] cpu_address;

// outputs from instruction cache to CPU
output reg cpu_busywait;
output reg [31:0] cpu_instruction;

// inputs to instruction cache from Memory
input mem_busywait;
input [127:0] mem_instruction;

// outputs from instruction cache to Memory
output reg mem_read;
output reg [5:0] mem_address;

// wires and registers to send and store signals
reg tagMatch;   // checking if the tags match
wire [2:0] tag;     //wire for the tag
wire [2:0] index;   //wire for the index
wire [2:0] cache_tag;   //wire for the cache tag
wire [1:0] offset;  //wire for the offset
wire isHit;    // wire for is hit
reg [31:0] loaded_instruction;  // wire for instruction word delection 

// Arrays for the cache
reg validBitArray [7:0];    //array to store the valid bit
reg [2:0] tagArray [7:0];    //array to store the tag array
reg [127:0] instructionBlockArray [7:0];    //array to store the data block array

// decoding the address to get tag, index, and offset
assign #1 tag = cpu_address[9:7];
assign #1 index = cpu_address[6:4];
assign #1 offset = cpu_address[3:2];

// setting the busywait signal when there is a read 
always @(cpu_address) begin
    cpu_busywait = 1'b1;
end

// assigning the cache tag
assign cache_tag = tagArray[index];

// Doing the tag comparison
always @(index, cache_tag, tag) begin
    #0.9 // delay for tag comparison
    if (tag == cache_tag) begin
        tagMatch = 1;
    end
    else begin
        tagMatch = 0;
    end
end

// checking for a hit or a miss
assign isHit = tagMatch & validBitArray[index];

// reading the corresponding data value from the cache 
always @(*) begin
    case (offset)
        0: cpu_instruction = #1 instructionBlockArray[index][31:0];
        1: cpu_instruction = #1 instructionBlockArray[index][63:32];
        2: cpu_instruction = #1 instructionBlockArray[index][95:64];
        3: cpu_instruction = #1 instructionBlockArray[index][127:96];
    endcase
end

// changing the control signals when there is a hit
always @(clock) begin
    if (isHit) begin
        cpu_busywait = 0;   // de-asserting busywait signal to prevent CPU from stalling
    end
end

/* Cache Controller FSM Start */

// Defining the 2 states, IDLE, MEM_READ 
parameter IDLE = 3'b000, MEM_READ = 3'b001;
reg [2:0] state;    //register to hold the current state 
reg[2:0] next_state;    //register to hold the next state

// combinational next state logic
always @(*) begin
    case (state)
        IDLE:
            if (!isHit)  //condition for the transition to MEM_READ state
                next_state = MEM_READ;
            else
                next_state = IDLE;  //otherwise remaining in IDLE state
            
        MEM_READ:
            if (!mem_busywait)
                next_state = IDLE;  //moving back to IDLE when memory is not busy
            else    
                next_state = MEM_READ;  //otherwise remain in MEM_READ state
    endcase
end

// combinational output logic
//To determine the control signals and actions based on the current state
always @(*) begin
    case(state)
        IDLE: begin
            mem_read = 0;
            mem_address = 8'dx;
        end
         
        MEM_READ: begin
            mem_read = 1;   //to initiate a memory read
            mem_address = {tag, index}; // memory address set using tag and index values
            cpu_busywait = 1;   // to stall the cpu

            // when memory read is complete, cache is updated
            #1 if (mem_busywait == 0) begin
                instructionBlockArray[index] = mem_instruction;
                if (mem_instruction != 32'dx) validBitArray[index] = 1;
                tagArray[index] = tag;
            end
        end

    endcase
end

// sequential logic for state transitioning 
integer i;
always @(posedge clock or posedge reset) begin
    // when reset is asserted FSM transitions to the IDLE state
    // all entries in validBitArray are set to zero
    if (reset) begin
        state = IDLE;
        for (i = 0; i < 8; i = i + 1) begin
            validBitArray[i] = 0;
        end
    end
    else
        state = next_state; // otherwise FSM transitions to the next state
end

/* Cache Controller FSM End */
endmodule