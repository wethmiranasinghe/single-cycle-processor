/*
CO224 - Computer Architecture
Lab 06 - Part 1 cpu
Group 32
*/

`timescale 1ns/100ps
`include "alu.v"
`include "Register.v"
`include "twos_comp.v"
`include "flowcontrol.v"


module cpu(PC, INSTRUCTION, CLK, RESET, READ_MEMORY, WRITE_MEMORY, ADDRESS, WRITEDATA, READDATA, BUSYWAIT);

	//Declaring input ports
	input [31:0] INSTRUCTION;
	input CLK, RESET, BUSYWAIT;
	input [7:0] READDATA;
	
	//Declaring output ports
	output reg [31:0] PC;
	output reg READ_MEMORY, WRITE_MEMORY;
	output [7:0] ADDRESS, WRITEDATA;

	//wires for connecting instances in register
	reg [2:0] READREG1, READREG2, WRITEREG;
	wire signed[7:0] REGOUT1, REGOUT2, WRITEDATA_REG;
	reg WRITEENABLE; // to select write
	
	//wires for connecting instances in ALU
	wire signed[7:0] OPERAND1, OPERAND2, ALURESULT;
	reg [2:0] ALUOP; // to select ALU operation
	wire ZERO;
	
	//wires for connecting instances in negation MUX
	wire [7:0] TwosComOp;
	wire [7:0] muxNegOp;
	reg signSelect;
	
	//wires for connecting instances in the MUX which gets the immediate value
	reg [7:0] IMMEDIATE;
	reg immediateSelect;

	//wires for connecting instances in the MUX which selects which Data to be written to the register
	// i.e data from data memory or ALU result
	reg WRITEDATA_TOREG_SELECT;
	
	//reg to store the PC value
	wire [31:0] PCFinal;
	reg [31:0] PCAdd;

	// registers for flow control
	reg JUMP, BRANCH;
	reg BNE = 0;

	//PCadder connections
	wire [31:0] TARGET;
	reg [7:0] OFFSET;

	//flowcontrol MUX connections
	wire flowselect;
	
	//Current OPCODE stored in CPU
	reg [7:0] OPCODE;
	
	//Instantiation of CPU modules
    // Taking an instance of the reg module
	reg_file my_reg(WRITEDATA_REG, REGOUT1, REGOUT2, WRITEREG, READREG1, READREG2, WRITEENABLE, CLK, RESET, BUSYWAIT);
	// Taking an instance of the ALU module
	alu my_alu(REGOUT1, OPERAND2, ALURESULT, ZERO, ALUOP);
	// Taking an instance of the twoscomp module
	twosComp my_twosComp(REGOUT2, TwosComOp);
	// Taking an instance of the mux negation module
	mux negationMUX(REGOUT2, TwosComOp, signSelect, muxNegOp);
	// Taking an instance of the immediatemux module
	mux immediateMUX(muxNegOp, IMMEDIATE, immediateSelect, OPERAND2);
	// Taking an instance of the offsetAdder module
	offsetAdder offsetadder(PCAdd, OFFSET, TARGET);
	// Taking an instance of the flowcontrol module
    flowControl flowcontrol(JUMP, BRANCH, ZERO, BNE, flowselect);
	// Taking an instance of the 32 bit MUX module
    mux32bit MUX32bit(PCFinal, PCAdd, TARGET, flowselect);
	// Taking an instance of the mux which selcts which data to be sent to the register to write
	mux my_writeDataToReg(ALURESULT, READDATA, WRITEDATA_TOREG_SELECT,WRITEDATA_REG);


	//Assigning values in the Data memory
	assign WRITEDATA = REGOUT1;
	assign ADDRESS = ALURESULT;

	// Control unit
	//PC Update
	always @ ( posedge CLK)
	begin
		if (RESET == 1'b1) 
		begin
			#1  // giving a one time unit delay for simulation
			PC = 0;		//If RESET signal is HIGH, set PC to zero
		end
		else if (~BUSYWAIT) begin
			#1 PC = PCFinal;		//Else, write new PC value
		end
	end

	//PC+4 Adder
	always @ (PC)
	begin
		#1 PCAdd = PC + 4;
	end
	
	//CONTROL UNIT
	
	//clearing the MEMREAD and MEMWRITE control signals when the BUSYWAIT signal goes low 
	always @(BUSYWAIT)  begin
		if(~BUSYWAIT) begin
			READ_MEMORY = 0;
			WRITE_MEMORY = 0;
		end
	end

	//Decoding the instruction
	always @ (INSTRUCTION)
	begin
		OPCODE = INSTRUCTION[31:24];	//Mapping the OP-CODE section
		READREG1 = INSTRUCTION[15:8];
		IMMEDIATE = INSTRUCTION[7:0];
		READREG2 = INSTRUCTION[7:0];
		WRITEREG = INSTRUCTION[18:16];
		OFFSET = INSTRUCTION[23:16];
		
		#1			                    //Delay for Decoding process
		case (OPCODE)
			8'b00000000:	begin   // loadi instruction
								ALUOP = 3'b000;			//forward
								immediateSelect = 1'b1;		//selecting immediate value
								signSelect = 1'b0;		//Setting sign select MUX to high
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;

							end
		
			8'b00000001:	begin   //mov instruction
								ALUOP = 3'b000;			//forward
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b0;		//Setting sign select MUX to high
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end
			
			8'b00000010:	begin   //add instruction
								ALUOP = 3'b001;			//ADD
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
                            end

			8'b00000011:	begin   //sub instruction
								ALUOP = 3'b001;			//ADD
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b1;		//Setting sign select MUX to high
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00000100:	begin   //and instruction
								ALUOP = 3'b010;			//AND
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end
							
			8'b00000101:	begin   //or operation
								ALUOP = 3'b011;			//OR
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00000110:	begin   //j operation
								WRITEENABLE = 1'b0;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b1;		//Selecting jump
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00000111:	begin   //beq operation
								ALUOP = 3'b001;			//Selecting ADD operation from alu
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b1;		//Setting sign select MUX to high
								WRITEENABLE = 1'b0;		//Disable write
								BRANCH = 1'b1;		//Selecting branch
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00001000:	begin   //bne operation
								ALUOP = 3'b001;			//Selecting ADD operation from alu
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b1;		//Setting sign select MUX to high
								WRITEENABLE = 1'b0;		//Disable write
								BRANCH = 1'b1;		//Selecting branch
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b1;		
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00001001:	begin	//mult instruction
								ALUOP = 3'b100;			//MULT
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00001010:	begin	//sll instruction
								ALUOP = 3'b101;			//SHIFTLEFT
								immediateSelect = 1'b1;		//Selecting the immediate value
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		//setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00001011:	begin	//srl instruction
								ALUOP = 3'b101;			//SHIFTRIGHT
								immediateSelect = 1'b1;		//Selecting the immediate value
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		////setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00001100:	begin	//sra instruction
								ALUOP = 3'b110;			//ARITHMATIC_SHIFTRIGHT
								immediateSelect = 1'b1;		//Selecting the immediate value
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		////setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00001101:	begin	//ror instruction
								ALUOP = 3'b111;			//ROTATE_RIGHT
								immediateSelect = 1'b1;		//Selecting the immediate value
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		////setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting from memory signal to low
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b0;
							end

			8'b00001110:	begin	//lwd instruction
								ALUOP = 3'b000;			//Selecting Forward operation from ALU 
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		////setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b1;		//Allowing read from memory
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b1;	// Sending the Readdata value to the register
							end

			8'b00001111:	begin	//lwi instruction
								ALUOP = 3'b000;			//Selecting Forward operation from ALU 
								immediateSelect = 1'b1;		//Selecting the immedite value
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b1;		//Enable write
								BRANCH = 1'b0;		////setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b1;		//Allowing read from memory
								WRITE_MEMORY = 1'b0;	// Setting write to memory signal low
								WRITEDATA_TOREG_SELECT = 1'b1;	// Sending the Readdata value to the register
							end

			8'b00010000:	begin	//swd instruction
								ALUOP = 3'b000;			//Selecting Forward operation from ALU 
								immediateSelect = 1'b0;		//Selecting the register input
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b0;		//Setting writeenable low
								BRANCH = 1'b0;		////setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting read from memory signal low
								WRITE_MEMORY = 1'b1;	// Allowing write to memory
								WRITEDATA_TOREG_SELECT = 1'b0;	
							end

			8'b00010001:	begin	//swi instruction
								ALUOP = 3'b000;			//Selecting Forward operation from ALU 
								immediateSelect = 1'b1;		//Selecting the immediate value
								signSelect = 1'b0;		//Setting sign select MUX to low
								WRITEENABLE = 1'b0;		//Setting writeenable low
								BRANCH = 1'b0;		////setting branch to low
								JUMP = 1'b0;		//setting jump to low
								BNE = 1'b0;		// setting branch if not equal to Low
								READ_MEMORY = 1'b0;		//Setting read from memory signal low
								WRITE_MEMORY = 1'b1;	// Allowing write to memory
								WRITEDATA_TOREG_SELECT = 1'b0;	
							end
		endcase
	end
endmodule



