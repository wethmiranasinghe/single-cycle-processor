// Computer Architecture (CO224) - Lab 06
// Design: Testbench of Integrated CPU of Simple Processor
// Author: Isuru Nawinne

`timescale 1ns/100ps
`include "cpu.v"
`include "dmem.v"
`include "data_cache.v"
`include "imem.v"
`include "instruction_cache.v"

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
    
    wire INSTRUCTION_MEM_READ, INSTRUCTION_MEM_BUSYWAIT;
    wire INSTRUCTION_BUSYWAIT;
    wire [5:0] INSTRUCTION_MEM_ADDRESS;
    wire [127:0] INSTRUCTION_MEM_INSTRUCTION;


    /* 
    -----
     CPU
    -----
    */
    //Taking an instance of CPU module
    cpu mycpu(PC, INSTRUCTION, CLK, RESET, CPU_READ, CPU_WRITE, CPU_ADDRESS, CPU_WRITEDATA, CPU_READDATA, CPU_BUSYWAIT, INSTRUCTION_BUSYWAIT);
      
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
    
    /* 
    -----
    INSTRUCTION CACHE
    -----
    */
    //Taking an instance of instruction cache module
    instruction_cache my_InstructionCache(CLK, RESET, PC[9:0], INSTRUCTION, INSTRUCTION_BUSYWAIT, INSTRUCTION_MEM_READ, INSTRUCTION_MEM_ADDRESS,INSTRUCTION_MEM_INSTRUCTION, INSTRUCTION_MEM_BUSYWAIT);
    /* 
    -----
     INSTRUCTION MEMORY
    -----
    */
    //Taking an instance of instruction memory module
    instruction_memory my_InstructionMem(CLK, INSTRUCTION_MEM_READ, INSTRUCTION_MEM_ADDRESS, INSTRUCTION_MEM_INSTRUCTION, INSTRUCTION_MEM_BUSYWAIT);

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
        #5000
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
endmodule