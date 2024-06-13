/*
CO224 Computer Architecture
Lab 6 Part 2 Data Cache 
Group 32
*/

`timescale 1ns/100ps
module data_cache (
    clock, reset, cpu_read, cpu_write, cpu_address, cpu_writedata, cpu_readdata, cpu_busywait,
mem_read, mem_write, mem_address, mem_writedata, mem_readdata, mem_busywait
);
    
    // port declaration
    input clock;
    input reset;

    // inputs to data cache from CPU
    input cpu_read;
    input cpu_write; 
    input [7:0] cpu_writedata;
    input [7:0] cpu_address; 

    // outputs from data cache to CPU
    output reg cpu_busywait;
    output reg [7:0] cpu_readdata;

    // inputs to data cache from Memory
    input mem_busywait;
    input [31:0] mem_readdata;

    // outputs from data cache to Memory
    output reg mem_read;
    output reg mem_write;
    output reg [31:0] mem_writedata;
    output reg [5:0] mem_address;

    // wires and registers to send and store signals
    reg tagMatch;   // checking if the tags match
    reg writeToCache; // checking writing to cache
    wire [2:0] tag;     //wire for the tag
    wire [2:0] index;   //wire for the index
    wire [2:0] cache_tag;   //wire for the cache tag
    wire [1:0] offset;  //wire for the offset
    wire isDirty;   // wire for dirty bit
    wire isHit;     // wire for is hit

    // Arrays for the cache
    reg validBitArray [7:0];    //array to store the valid bit
    reg dirtyBitArray [7:0];    //array to store the dirty bit
    reg [2:0] tagArray [7:0];    //array to store the tag array
    reg [31:0] dataBlockArray [7:0];    //array to store the data block array

    // decoding the address to get tag, index, and offset
    assign #1 tag = cpu_address[7:5];
    assign #1 index = cpu_address[4:2];
    assign #1 offset = cpu_address[1:0];

    // setting the busywait signal when there is a read or write
    always @* begin
        cpu_busywait = (cpu_read || cpu_write) ? 1 : 0;
    end

    // assigning the dirty bit
    assign #1 isDirty = dirtyBitArray[index];

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
            0: cpu_readdata = dataBlockArray[index][7:0];
            1: cpu_readdata = dataBlockArray[index][15:8];
            2: cpu_readdata = dataBlockArray[index][23:16];
            3: cpu_readdata = dataBlockArray[index][31:24];
        endcase
    end

    // changing the control signals when there is a hit
    always @(*) begin
        if (isHit) begin
            if (cpu_read && (!cpu_write)) begin
                cpu_busywait = 0;   // de-asserting busywait signal to prevent CPU from stalling
                tagMatch = 0;
            end
            else if (cpu_write && (!cpu_read)) begin
                cpu_busywait = 0;   // de-asserting busywait signal to prevent CPU from stalling
                writeToCache = 1;   // to show a write hit
            end
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            writeToCache = 0;
        end
        // writing data to the cache at the next positive egde of the clk cycle
        else if (writeToCache == 1) begin
            #1
            case (offset)
                0: dataBlockArray[index][7:0] = cpu_writedata;
                1: dataBlockArray[index][15:8] = cpu_writedata;
                2: dataBlockArray[index][23:16] = cpu_writedata;
                3: dataBlockArray[index][31:24] = cpu_writedata;
            endcase
            dirtyBitArray[index] = 1;   //because the cache is inconsistent with the memory now
            writeToCache = 0;
        end
    end



    /* Cache Controller FSM Start */

    // Defining the 3 states, IDLE, MEM_READ and MEM_WRITE
    parameter IDLE = 3'b000, MEM_READ = 3'b001, MEM_WRITE = 3'b010;
    reg [2:0] state;    //register to hold the current state 
    reg[2:0] next_state;    //register to hold the next state

    // combinational next state logic
    always @(*) begin
        case (state)
            IDLE:
                if ((cpu_read || cpu_write) && !isDirty && !isHit)  //condition for the transition to MEM_READ state
                    next_state = MEM_READ;
                else if ((cpu_read || cpu_write) && isDirty && !isHit)  //condition for the transition to MEM_WRITE state
                    next_state = MEM_WRITE;
                else
                    next_state = IDLE;  //otherwise remaining in IDLE state
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = IDLE;  //moving back to IDLE when memory is not busy
                else    
                    next_state = MEM_READ;  //otherwise remain in MEM_READ state
            MEM_WRITE:
                if (!mem_busywait)
                    next_state = MEM_READ;  //moving to MEM_READ state when memory is not busy
                else
                    next_state = MEM_WRITE; //otherwise remain in MEM_WRITE
        endcase
    end

    // combinational output logic
    //To determine the control signals and actions based on the current state
    always @(*) begin
        case(state)
            IDLE: begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 6'dx;
                mem_writedata = 32'dx;
            end
         
            MEM_READ: begin
                mem_read = 1;   //to initiate a memory read
                mem_write = 0;
                mem_address = {tag, index}; // memory address set using tag and index values
                mem_writedata = 32'dx;
                cpu_busywait = 1;   // to stall the cpu

                // when memory read is complete, cache is updated
                #1 if (mem_busywait == 0) begin 
                    dataBlockArray[index] = mem_readdata;
                    validBitArray[index] = 1;
                    tagArray[index] = tag;
                end
            end

            MEM_WRITE: begin
                mem_read = 0;
                mem_write = 1;  //to initiate a memory write
                mem_address = {cache_tag, index};   //memory address is set using cache_tag and index
                mem_writedata = dataBlockArray[index];  //set to the data from the cache
                cpu_busywait = 1;   // to stall the CPU

                // when memory write is complete, dirtybit array is cleared
                if (mem_busywait == 0) begin
                    dirtyBitArray[index] = 0;
                end
            end
        endcase
    end

    // sequential logic for state transitioning 
    integer i;
    always @(posedge clock or posedge reset) begin
        // when reset is asserted FSM transitions to the IDLE state
        // all entries in irtyBitArray and validBitArray are set to zero
        if (reset) begin
            state = IDLE;
            for (i = 0; i < 8; i = i + 1) begin
                dirtyBitArray[i] = 0;
                validBitArray[i] = 0;
            end
        end
        else
            state = next_state; // otherwise FSM transitions to the next state
    end

    /* Cache Controller FSM End */

endmodule
