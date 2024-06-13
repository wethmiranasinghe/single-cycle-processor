/*
CO224 - Computer Architecture
Lab 06 - Part 6 MUX
Group 32
*/
`timescale 1ns/100ps
//2x1 MUX module to be used inside the CPU
module mux(IN1, IN2, SELECT, OUT);

	//Declaring the input ports
	input [7:0] IN1, IN2;
	input SELECT;

    //Declaring the output port
	output reg signed[7:0] OUT;
	
	//changing the output value according to the input
	always @ (IN1, IN2, SELECT)
	begin
		if (SELECT == 1'b1)		//Selecting 2nd input if HIGH
		begin
			OUT = IN2;
		end
		else					//Selecting the 1st input if LOW
		begin
			OUT = IN1;
		end
	end

endmodule

//MUX module to use in the cpu
module mux32bit(OUTPUT , DATA1 , DATA2 , SELECT);

    //input ports
    input [31:0] DATA1 , DATA2;
    input SELECT;

    //output port
    output reg [31:0] OUTPUT;

    always @(DATA1 , DATA2 , SELECT)
    begin
        case(SELECT) //selectig the output port by select case
            0 : assign OUTPUT = DATA1;
            1 : assign OUTPUT = DATA2;
        endcase
    end
endmodule


