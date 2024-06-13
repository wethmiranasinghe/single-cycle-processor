
/*
CO224 - Computer Architecture
Lab 06 - Part 2 Adder module
Group 32
*/

`timescale 1ns/100ps
//Full adder module
module full_adder (firstBit, secondBit, Cin, Sum ,Cout);

    //Port declaration
    input  firstBit, secondBit, Cin;     
    output  Sum, Cout; 

    // Internal wire for intermediate calculations
    wire firstBit_xor_secondBit, firstBit_AND_secondBit, firstBit_AND_Cin, secondBit_AND_Cin;

    // Calculate Sum and Cout
    assign firstBit_xor_secondBit = firstBit ^ secondBit;
    assign Sum = firstBit_xor_secondBit ^ Cin;
    assign firstBit_AND_secondBit = firstBit & secondBit;
    assign firstBit_AND_Cin = firstBit & Cin;
    assign secondBit_AND_Cin = secondBit & Cin;
    assign Cout = firstBit_AND_secondBit | firstBit_AND_Cin | secondBit_AND_Cin;

endmodule

// Half adder module
module half_adder(firstBit, secondBit, Sum, Carry);
    //port declaration
    input firstBit, secondBit;
    output Sum, Carry;

    //implementation
    xor x1(Sum, firstBit, secondBit);
    and a1(Carry, firstBit, secondBit);

endmodule