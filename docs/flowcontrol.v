/*
CO224 - Computer Architecture
Lab 06 - Part 1 Flow control module
Group 32
*/
`timescale 1ns/100ps

module flowControl(JUMP, BRANCH, ZERO, BNE, OUT);
    //declaring input ports
    input JUMP, BRANCH, ZERO, BNE; 
    // declaring output ports
    output OUT; 

    assign OUT = (JUMP & ~BRANCH) | ((~JUMP & BRANCH) & (BNE ^ ZERO)); 

endmodule

module offsetAdder(PC, OFFSET, TARGET);
    //declaring input  ports
    input [31:0] PC;
    input [7:0] OFFSET;
    //declaring output ports
    output [31:0] TARGET;

    wire [21:0] signBits;

    assign signBits = {22{OFFSET[7]}};
    // getting the target
    assign #2 TARGET = PC + {signBits, OFFSET, 2'b0};
endmodule