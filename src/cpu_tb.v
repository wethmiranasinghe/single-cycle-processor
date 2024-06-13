// Computer Architecture (CO224) - Lab 06
// Design: Testbench of Integrated CPU of Simple Processor
// Author: Isuru Nawinne

`timescale 1ns/100ps
`include "cpu.v"
`include "dmem.v"
`include "data_cache.v"

module cpu_tb;

    //Wires and registers for the modules
    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    wire CPU_READ, CPU_WRITE, CPU_BUSYWAIT;
    wire MEM_READ, MEM_WRITE, MEM_BUSYWAIT;
    wire [7:0] CPU_READDATA, CPU_WRITEDATA, CPU_ADDRESS;
    wire [31:0] MEM_WRITEDATA, MEM_READDATA;
    wire [5:0] MEM_ADDRESS;

    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory
    
    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    reg [7:0] instr_mem [1023:0];
    assign #2 INSTRUCTION = {instr_mem[PC+3], instr_mem[PC+2], instr_mem[PC+1], instr_mem[PC]};

    initial
    begin
        // Initialize instruction memory with the set of instructions you need execute on CPU
        
        // METHOD 1: manually loading instructions to instr_mem
        //{instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000000000001000000000000000101;
        //{instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000000000000100000000000001001;
        //{instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00000010000001100000010000000010;
        
        // METHOD 2: loading instr_mem content from instr_mem.mem file
        $readmemb("instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    //Taking an instance of CPU module
    cpu mycpu(PC, INSTRUCTION, CLK, RESET, CPU_READ, CPU_WRITE, CPU_ADDRESS, CPU_WRITEDATA, CPU_READDATA, CPU_BUSYWAIT);
    
    /* 
    -----
     DATA CACHE
    -----
    */
    //Taking an instance of data cache module
    data_cache my_Datacache(CLK, RESET, CPU_READ, CPU_WRITE, CPU_ADDRESS, CPU_WRITEDATA, CPU_READDATA, CPU_BUSYWAIT, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA, MEM_BUSYWAIT);

    /* 
    -----
     DATA MEMORY
    -----
    */
    //Taking an instance of data memory module
    data_memory my_DataMem(CLK, RESET, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA, MEM_BUSYWAIT);

    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        RESET = 1'b1;
		#5
		RESET = 1'b0;
        // finish simulation after some time
        #1000
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
endmodule