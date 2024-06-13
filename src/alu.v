/*
CO224 Computer Architecture
Lab 6 Part 2 alu
Group 32
*/
`timescale 1ns/100ps
`include "multiplier.v"
`include "mux.v"

// The alu module
module alu(DATA1, DATA2, RESULT, ZERO, SELECT);
    // port declaration
    input signed [7:0] DATA1, DATA2;
    input [2:0] SELECT;
    output reg signed [7:0] RESULT;
    output ZERO;

    // Wires to connect instances
    wire [7:0] FORWARD, ADD, AND, OR, MULT, SHIFT_LEFT, ARITHMATICRIGHT_SHIFT, ROTATE_RIGHT;

    // Instantiating modules
    FORWARD forward_unit(
        .DATA2(DATA2), 
        .RESULT(FORWARD)
    );

    ADD add_uni(
        .DATA1(DATA1),
        .DATA2(DATA2),
        .RESULT(ADD)
    );

    AND and_uni(
        .DATA1(DATA1), 
        .DATA2(DATA2), 
        .RESULT(AND)
    );

    OR or_uni(
        .DATA1(DATA1), 
        .DATA2(DATA2), 
        .RESULT(OR)
    );
    
    MULT mult_uni(
        .DATA1(DATA1), 
        .DATA2(DATA2), 
        .RESULT(MULT)
    );

    SHIFT_LEFT shiftLeft_uni(
        .OPERAND(DATA1), 
        .SHAMT(DATA2), 
        .RESULT (SHIFT_LEFT)
    );

    ARITHMATICRIGHT_SHIFT arithShiftRight_uni(
        .OPERAND(DATA1), 
        .SHAMT(DATA2), 
        .RESULT(ARITHMATICRIGHT_SHIFT)
    ); 

    ROTATE_RIGHT rotateRight_uni(
        .OPERAND(DATA1), 
        .SHAMT(DATA2), 
        .RESULT(ROTATE_RIGHT)
    ); 


    // Selecting the modules
    always @* begin
        case(SELECT)
            3'b000: RESULT <= FORWARD;
            3'b001: RESULT <= ADD;
            3'b010: RESULT <= AND;
            3'b011: RESULT <= OR;
            3'b100: RESULT <= MULT;
            3'b101: RESULT <= SHIFT_LEFT;
            3'b110: RESULT <= ARITHMATICRIGHT_SHIFT;
            3'b111: RESULT <= ROTATE_RIGHT;
        endcase
    end
    // generating ZERO output
    assign ZERO = (RESULT == 8'b00000000);
endmodule


//Seperate modules for functional units
// forward module
module FORWARD(DATA2, RESULT);
    // port declaration
    input [7:0] DATA2;
    output reg [7:0] RESULT;


    // forward operation
    always @* begin
        #1 // Unit's delay
        RESULT = DATA2;
    end
endmodule

// add module
module ADD(DATA1, DATA2, RESULT);
    // port declaration
    input [7:0] DATA1, DATA2;
    output reg [7:0] RESULT;


    // add operation
    always @* begin
        #2 // Unit's delay
        RESULT = DATA1 + DATA2;
    end
endmodule

// and module
module AND(DATA1, DATA2, RESULT);
    // port declaration
    input [7:0] DATA1, DATA2;
    output reg [7:0] RESULT;


    // and operation
    always @* begin
        #1 // Unit's delay
        RESULT = DATA1 & DATA2;
    end
endmodule

// or module
module OR(DATA1, DATA2, RESULT);
    // port declaration
    input [7:0] DATA1, DATA2;
    output reg [7:0] RESULT;


    // or operation
    always @* begin
        #1 // Unit's delay
        RESULT = DATA1 | DATA2;
    end
endmodule


module SHIFT_LEFT(OPERAND, SHAMT, RESULT);
    // port declaration
    input [7:0] OPERAND, SHAMT;
    output reg signed [7:0] RESULT;

    wire [7:0] out1, out2, out3; //Intermediate wires to hold the values after each stage of shifting

    mux mux1(OPERAND, {OPERAND[6:0], 1'b0}, SHAMT[0], out1);
    mux mux2(out1, {OPERAND[5:0], 2'b0}, SHAMT[1], out2);
    mux mux3(out2, {OPERAND[3:0], 4'b0}, SHAMT[2], out3);

    always @(*) begin
        // Unit's delay
        #1 RESULT = out3;
    end
endmodule


module ARITHMATICRIGHT_SHIFT(OPERAND, SHAMT, RESULT);
    // Port declaration
    input signed [7:0] OPERAND, SHAMT;
    output reg signed [7:0] RESULT;

    wire signed [7:0] out1, out2, out3; //Intermediate wires to hold the values after each stage of shifting

    // Arithmetic right shift operations
    mux mux1(OPERAND, {OPERAND[7], OPERAND[7:1]}, SHAMT[0], out1);
    mux mux2(out1, {{2{out1[7]}}, out1[7:2]}, SHAMT[1], out2);
    mux mux3(out2, {{4{out2[7]}}, out2[7:4]}, SHAMT[2], out3);

    always @(*) begin
        // Unit's delay
        #1 RESULT = out3;
    end
endmodule


module ROTATE_RIGHT(OPERAND, SHAMT, RESULT);
    // Port declaration
    input signed [7:0] OPERAND, SHAMT;
    output reg signed[7:0] RESULT;

    wire signed[7:0] out1, out2, out3; //Intermediate wires to hold the values after each stage of rotating

    // Right rotation operations
    mux mux1(OPERAND, {OPERAND[0], OPERAND[7:1]}, SHAMT[0], out1);
    mux mux2(out1, {out1[1:0], out1[7:2]}, SHAMT[1], out2);
    mux mux3(out2, {out2[3:0], out2[7:4]}, SHAMT[2], out3);

    always @(*) begin
        // Unit's delay
        #1 RESULT = out3;
    end
endmodule


/*
//Using for loops
// multiplication module
module MULT(DATA1, DATA2, RESULT);
    // port declaration
    input signed [7:0] DATA1, DATA2;
    output signed [7:0] RESULT;

    //using a stack of adders to fint the mult result
    reg [2:0] CARRY; 
    reg [3:0] SUM; 
    integer i, j; 
    
    reg [7:0] KEEPRESULT; 
    always @(DATA1, DATA2) begin
        SUM  = 0;
        CARRY = 0;
        for (i = 0; i < 8; i += 1) begin
            SUM = {1'b0, CARRY};
            for (j = 0; j < i + 1; j += 1) begin
                SUM += DATA1[i-j] & DATA2[j];
            end
            KEEPRESULT[i] = SUM[0];
            CARRY = SUM[3:1];
        end
    end

    assign #3 RESULT = KEEPRESULT;
endmodule



// shiftleft module
module SHIFTLEFT(OPERAND, SHAMT, RESULT);
    // port declaration
    input [7:0] OPERAND, SHAMT;
    output reg [7:0] RESULT;

    //shifting
    integer  i;
    always @(OPERAND, SHAMT) begin
        #1
        RESULT = OPERAND;
        for (i = 0; i < SHAMT; i++)
            RESULT = {RESULT[6:0], 1'b0};
    end
endmodule


// shifright module
module SHIFTRIGHT(OPERAND, SHAMT, RESULT);
    // port declaration
    input [7:0] OPERAND, SHAMT;
    output reg [7:0] RESULT;

    //shifting
    integer  i;
    always @(OPERAND, SHAMT) begin
        #1
        RESULT = OPERAND;
        for (i = 0; i < SHAMT; i++)
            RESULT = {1'b0, RESULT[7:1], };
    end
endmodule


// arithmatic_shiftRight module
module ARITHMATIC_SHIFTRIGHT(OPERAND, SHAMT, RESULT);
    // port declaration
    input [7:0] OPERAND, SHAMT;
    output reg [7:0] RESULT;

    //shifting
    integer  i;
    always @(OPERAND, SHAMT) begin
        #1
        RESULT = OPERAND;
        for (i = 0; i < SHAMT; i++)
            RESULT = { RESULT[7], RESULT[7:1]};
    end
endmodule

// rotateRight module
module ROTATE_RIGHT(OPERAND, SHAMT, RESULT);
    // port declaration
    input [7:0] OPERAND, SHAMT;
    output reg [7:0] RESULT;

    //shifting
    integer  i;
    always @(OPERAND, SHAMT) begin
        #1
        RESULT = OPERAND;
        for (i = 0; i < SHAMT; i++)
            RESULT = { RESULT[0], RESULT[7:1]};
    end
endmodule
*/


