
/*
CO224 - Computer Architecture
Lab 06 - Part 1 Multiplier module
Group 32
*/
`timescale 1ns/100ps
`include "adder.v"

module MULT(DATA1, DATA2, RESULT);

    //port declaration
    input [7:0] DATA1, DATA2;
	output [7:0] RESULT;
    
    wire [7:0] C0,C1,C2,C3,C4,C5,C6,C7; //carry ins
    wire [7:0] S0,S1,S2,S3,S4,S5,S6;    //sums
    wire [7:0] TEMPORARY;   //to store the temporary output 

    assign TEMPORARY[0] = DATA1[0] & DATA2[0];

    // Full Adder array to calculate mult result
    //Layer 0
    half_adder ha0(DATA1[1] & DATA2[0],DATA1[0] & DATA2[1],TEMPORARY[1],C0[0]);
    full_adder fa0(DATA1[2] & DATA2[0],DATA1[1] & DATA2[1],C0[0],S0[0],C1[0]);
    full_adder fa1(DATA1[3] & DATA2[0],DATA1[2] & DATA2[1],C1[0],S1[0],C2[0]);
    full_adder fa2(DATA1[4] & DATA2[0],DATA1[3] & DATA2[1],C2[0],S2[0],C3[0]);
    full_adder fa3(DATA1[5] & DATA2[0],DATA1[4] & DATA2[1],C3[0],S3[0],C4[0]);
    full_adder fa4(DATA1[6] & DATA2[0],DATA1[5] & DATA2[1],C4[0],S4[0],C5[0]);
    full_adder fa5(DATA1[7] & DATA2[0],DATA1[6] & DATA2[1],C5[0],S5[0],C6[0]);
    
    //Layer 1
    half_adder ha2(S0[0],DATA1[0] & DATA2[2],TEMPORARY[2],C0[1]);
    full_adder fa6(S1[0],DATA1[1] & DATA2[2],C0[1],S0[1],C1[1]);
    full_adder fa7(S2[0],DATA1[2] & DATA2[2],C1[1],S1[1],C2[1]);
    full_adder fa8(S3[0],DATA1[3] & DATA2[2],C2[1],S2[1],C3[1]);
    full_adder fa9(S4[0],DATA1[4] & DATA2[2],C3[1],S3[1],C4[1]);
    full_adder fa10(S5[0],DATA1[5] & DATA2[2],C4[1],S4[1],C5[1]);
    
    //Layer 2
    half_adder ha4(S0[1],DATA1[0] & DATA2[3],TEMPORARY[3],C0[2]);
    full_adder fa12(S1[1],DATA1[1] & DATA2[3],C0[2],S0[2],C1[2]);
    full_adder fa13(S2[1],DATA1[2] & DATA2[3],C1[2],S1[2],C2[2]);
    full_adder fa14(S3[1],DATA1[3] & DATA2[3],C2[2],S2[2],C3[2]);
    full_adder fa15(S4[1],DATA1[4] & DATA2[3],C3[2],S3[2],C4[2]);
    
    //Layer 3
    half_adder ha6(S0[2],DATA1[0] & DATA2[4],TEMPORARY[4],C0[3]);
    full_adder fa18(S1[2],DATA1[1] & DATA2[4],C0[3],S0[3],C1[3]);
    full_adder fa19(S2[2],DATA1[2] & DATA2[4],C1[3],S1[3],C2[3]);
    full_adder fa20(S3[2],DATA1[3] & DATA2[4],C2[3],S2[3],C3[3]);
    
    // Layer 4
    half_adder ha8(S0[3],DATA1[0] & DATA2[5],TEMPORARY[5],C0[4]);
    full_adder fa24(S1[3],DATA1[1] & DATA2[5],C0[4],S0[4],C1[4]);
    full_adder fa25(S2[3],DATA1[2] & DATA2[5],C1[4],S1[4],C2[4]);
    
    // Layer 5
    half_adder ha10(S0[4],DATA1[0] & DATA2[6],TEMPORARY[6],C0[5]);
    full_adder fa30(S1[4],DATA1[1] & DATA2[6],C0[5],S0[5],C1[5]);
    
    // Layer 6
    half_adder ha12(S0[5],DATA1[0] & DATA2[7],TEMPORARY[7],C0[6]);
    
    // Sending out result after #3 delay
    assign #3 RESULT = TEMPORARY; 
endmodule