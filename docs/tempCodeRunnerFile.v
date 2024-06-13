/*
Module  : Data Cache 
Author  : Isuru Nawinne, Kisaru Liyanage
Date    : 25/05/2020

Description	:

This file presents a skeleton implementation of the cache controller using a Finite State Machine model. Note that this code is not complete.
*/

`timescale 1ns/100ps
module data_cache (clock, reset, cpu_read, cpu_write, cpu_address, cpu_writedata, cpu_readdata, cpu_busywait, mem_read, mem_write, mem_address, mem_writedata, mem_readdata, mem_busywait);
    
    //port declaration
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

    // Arrays for the cache
    reg validBitArray [7:0];
    reg dirtyBitArray [7:0];
    reg [2:0] tagArray [7:0];
    reg [31:0] dataBlockArray [7:0];

    // wires and registers to send and store signals
    reg tagMatch;   // checking if the tags match
    reg writeToCache; // checking writing to cache
    wire [2:0] tag;
    wire [2:0] index;
    wire [2:0] cache_tag;
    wire [1:0] offset;
    wire isDirty;   // wire for dirty bit
    wire isHit;     // wire for is hit


    // decoding the address to get tag, index and offset
    assign #1 tag = cpu_address[7:5];
    assign #1 index = cpu_address[4:2];
    assign #1 offset = cpu_address[1:0];

    // assigning the dirty bit
    assign #1 isDirty = dirtyBitArray[index];

    // setting the busywait signal when there is a read or write
    always @(cpu_read, cpu_write) begin
        cpu_busywait = (cpu_read || cpu_write)? 1 : 0;
    end

    // Doing the tag comparison
    always @(index, tagArray[index], tag) begin
        #0.9 // delay for  tag comparison
        if (tag == tagArray[index]) begin
            tagMatch = 1;
        end
        else begin
            tagMatch = 0;
        end
    end

    //checking for a hit or a miss
    assign isHit = tagMatch & validBitArray[index]; 

    // reading the corresponding data value from the cache parralley with the tag comprison
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

    always @(posedge clock) begin
        if (writeToCache == 1) begin
            #1
            case (offset)
                0: dataBlockArray[index][7:0] = cpu_readdata;
                1: dataBlockArray[index][15:8] = cpu_readdata;
                2: dataBlockArray[index][23:16] = cpu_readdata;
                3: dataBlockArray[index][31:24] = cpu_readdata;
            endcase
            dirtyBitArray[index] = 1;
        end
    end

    /* Cache Controller FSM Start */

    parameter IDLE = 3'b000, MEM_READ = 3'b001, MEM_WRITE = 3'b010;
    reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((cpu_read || cpu_write) && !isDirty && !isHit)  
                    next_state = MEM_READ;
                else if ((cpu_read || cpu_write) && isDirty && !isHit)
                    next_state = MEM_WRITE;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = IDLE;
                else    
                    next_state = MEM_READ;
            MEM_WRITE:
                if (!mem_busywait)
                    next_state = MEM_READ;
                else
                    next_state = MEM_WRITE;
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE: begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 8'dx;
                mem_writedata = 8'dx;
                //cpu_busywait = 0;
            end
         
            MEM_READ: begin
                mem_read = 1;
                mem_write = 0;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
                cpu_busywait = 1;

                #1 if(mem_busywait == 0) begin
                    dataBlockArray[index] = mem_readdata;
                    validBitArray[index] =1;
                    tagArray[index] = tag;
                end
            end

            MEM_WRITE: begin
                mem_read = 0;
                mem_write = 1;
                mem_address = {cache_tag, index};
                mem_writedata = dataBlockArray[index];
                cpu_busywait = 1;

                // setting the dirty bit to zero when mem_busywait becomes zero
                if (mem_busywait == 0) begin
                    dirtyBitArray[index] = 0;
                end
            end
        endcase
    end

    // sequential logic for state transitioning 
    integer i;
    always @(posedge clock, reset)
    begin
        if(reset) begin
            state = IDLE;
            for (i = 0; i < 7; i = i + 1) begin
                dirtyBitArray[i] = 0;
                validBitArray[i] = 0;
            end
        end
        else
            state = next_state;
    end

    /* Cache Controller FSM End */

endmodule