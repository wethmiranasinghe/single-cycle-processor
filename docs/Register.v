/*
CO224 Computer Architecture
Lab 6 Part 1 register
Group 32
*/

`timescale 1ns/100ps
// Module function for register file
module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS,OUT2ADDRESS,WRITE,CLK, RESET, BUSYWAIT);
    
    // input port declarations
    input signed[7:0] IN;
    input [2:0] INADDRESS, OUT1ADDRESS, OUT2ADDRESS;    
    input WRITE, CLK, RESET, BUSYWAIT; 

    // OUTput port declarations
    output reg signed[7:0] OUT1, OUT2;   
             
    // Array of 8 registers
    reg [7:0] regfile[7:0];  

    integer i; 
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            // Synchronous reset
            for (i = 0; i < 8; i = i + 1) begin
                regfile[i] <= 8'b0; // For clearing all registers
            end
        end
        else if (WRITE && !BUSYWAIT) begin
            // Synchronous write operation
            #1; 
            regfile[INADDRESS] <= IN; // Write data to the specified register
        end
    end

    // Combinational logic for register file
    always @(*) begin
        #2; // Read latency
        OUT1 = regfile[OUT1ADDRESS]; 
        OUT2 = regfile[OUT2ADDRESS]; 
    end

    initial begin
    //monitor changes in reg file content and print
        #5;
        $display("\n\t\t\t==============================================================");
        $display("\n\t\t\t Change of Register Content starting from Time #5");
        $display("\n\t\t\t==============================================================");
        $display("\n\t\ttime\treg0\treg1\treg2\treg3\treg4\treg5\treg6\treg7");
        $display("\n\t\t\t--------------------------------------------------------------------------------------");
        $monitor($time, "\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", regfile[0], regfile[1], regfile[2], regfile[3],regfile[4], regfile[5], regfile[6], regfile[7]);
    end

    initial
    begin
        $dumpfile("cpu_wavedata.vcd");
        for (i = 0; i < 8; i++)
            $dumpvars(1,regfile[i]);
    end
endmodule

