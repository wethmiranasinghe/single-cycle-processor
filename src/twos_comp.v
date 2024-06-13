/*
CO224 Computer Architecture
Lab 6 Part 1 twos complement
Group 32
*/
`timescale 1ns/100ps
//Twos complement module to be used inside the CPU

module twosComp(IN, OUT); 
	//Declaring the input port
	input [7:0] IN;
    
    //Declaring the output port
	output [7:0] OUT;

	//assigning two's complement value of input to output after a delay of #1
	assign #1 OUT = ~IN + 1;
endmodule

