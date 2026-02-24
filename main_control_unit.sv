import alu_op_pkg::*;
/*
* @input[6:0] funct7 - 7 most significant bits coming from instruction field
* funct3 - 3 bit input coming from instruction field specifying operation
* @input[6:0] opcode - 7-bit opcode input from 7 least signifcant bits from
* instruction
* @output Branch - 1-bit signal indicating we might want to branch (assuming
* ALU Zero signal = 1)
* @output MemRead - 1-bit signal specifying if we want to read from memory
* @output MemtoReg - 1-bit control signal for mux deciding to take output from
* ALU or data memory
* @output[3:0] ALUOp - 4-bit control signal to signify ALU operation
* 00: ADD (for LW, SW, etc.)
* 01: SUB (for branches)
* 10: Use funct3/funct7 (R-type and I-type)
* 11: Not defined yet
* @output MemWrite - 4-bit control signal for writing to memory (I believe it is negative
* edge triggered, but need verification from Milder)
* @output ALUSrc - 1-bit control signal to read register from the register
* file or extended immediate
* @output RegWrite - 1-bit control signal to specify if we are writing to
* register file or not
*/
module main_control_unit(input [6:0] opcode,
			input [6:0] funct7,
			input [2:0] funct3,
			output logic Branch,
			output logic [2:0] BranchType,
			output logic BranchSigned,
			output logic MemRead,
			output logic MemtoReg,
			output alu_op_t ALUOp,
			output logic [3:0] MemWrite,
			output logic ALUSrc,
			output logic RegWrite,
			output logic [1:0] MemReadSize,
			output logic MemReadSigned,
			output logic Sel_imm,
			output logic Jal,
			output logic JalR,
			output logic AuiPc,
			output logic Lui
			);

	//logic funct6 = funct7[6:1]; //6 most significang bits for immediate-type instructions
	always_comb begin
		Branch = 1'bx;
		BranchType = 3'bx;
		BranchSigned = 1'bx;
		MemRead = 1'bx;
		MemtoReg = 1'bx;
		//Note: ALUOp have following values:
		//0: ADD (for LW, SW, add, addi, etc.)
		//1: SUB (for branches, sub, etc.)
		//...other types
		ALUOp = alu_op_t'(4'hx); //Default to unknown
		MemWrite = 4'bx;
		ALUSrc = 1'bx;
		RegWrite = 1'bx;
		MemReadSigned = 1'bx;
		MemReadSize = 2'bx;
		Sel_imm = 1'bx;
		Jal = 1'bx;
		JalR = 1'bx;
		AuiPc = 1'bx;
		Lui = 1'bx;

		case(opcode)
			//Load from memory instruction 
			7'b0000011 : 
			begin
				Branch = 0; //We don't want to consider branching
				MemRead = 1; //We want to read from memory
				MemtoReg = 1; //Load value from memory to register
				ALUOp = ADD; //Add ALU function
				MemWrite = 4'b0; //Not writing to memory
				ALUSrc = 1; //Use 32-bit immediate
				RegWrite = 1; //Write loaded memory data into register file
				Sel_imm = 0;
				Jal = 0;
				JalR = 0;
				AuiPc = 0;
				Lui = 0;
				case(funct3)
					//0 : LB
					3'b000:
					begin
						MemReadSize = 0;
						MemReadSigned = 1;
					end		
					//1 : LH
					3'b001:
					begin
						MemReadSize = 1;
						MemReadSigned = 1;
					end	
					//2 : LW
					3'b010:
					begin
						MemReadSize = 2;
					end	
					//4 : LBU
					3'b100:
					begin
						MemReadSize = 0;
						MemReadSigned = 0;
					end	
					//5 : LHU
					3'b101:
					begin
						MemReadSize = 1;
						MemReadSigned = 0;
					end		
				endcase
			end
			//Store to memory instruction
			7'b0100011 : 
			begin
				Branch = 0; //Don't branch
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't write to register
				ALUOp = ADD; //Add ALU function
				MemWrite = 4'b1; //Write to memory
				ALUSrc = 1; //Use 32-bit immediate to add to base address
				RegWrite = 0; //Don't write anything to register file
				Sel_imm = 1; //select the store immediate
				Jal = 0;
				JalR = 0;
				AuiPc = 0;
				Lui = 0;
				case(funct3)
					//0 : SB
					3'b000:
					begin
						MemWrite = 4'b0001;
					end		
					//1 : SH
					3'b001:
					begin
						MemWrite = 4'b0011;
					end	
					//2 : SW
					3'b010:
					begin
						MemWrite = 4'b1111;
					end	
					
				endcase
			end
			//Branch instruction
			7'b1100011 : 
			begin
				Branch = 1; //Consider branching
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't consider writing from memory
				ALUOp = SUB; //Subtract ALU function
				MemWrite = 4'b0; //Don't write to memory
				ALUSrc = 0; //Don't use an immediate (use the values specified in the registers)
				RegWrite = 0; //Don't write anything to register file
				Sel_imm = 0;
				Jal = 0;
				JalR = 0;
				AuiPc = 0;
				Lui = 0;
				case(funct3)
					//0: beq
					3'b000:
					begin
						BranchType = 0;
						BranchSigned = 1;
					end
					//1: bne
					3'b001:
					begin
						BranchType = 1;
						BranchSigned = 1;
					end
					//4: blt
					3'b100:
					begin
						BranchType = 4;
						BranchSigned = 1;
					end
					//5: bge
					3'b101:
					begin
						BranchType = 5;
						BranchSigned = 1;
					end
					//6: bltu
					3'b110:
					begin
						BranchType = 6;
						BranchSigned = 0;
					end
					//7: bgeu
					3'b111:
					begin
						BranchType = 7;
						BranchSigned = 0;
					end
				endcase
			end
			//R-type instructions
			7'b0110011 : 
			begin
				Branch = 0;
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't consider writing from memory
				ALUOp = ADD; //Default ALU operation
				MemWrite = 4'b0; //Don't write to memory
				ALUSrc = 0; //Use the value specified in the register (R-type)
				RegWrite = 1; //Write to the register file
				Sel_imm = 0;
				Jal = 0;
				JalR = 0;
				AuiPc = 0;
				Lui = 0;
				case(funct3)
					//0 : Add or Subtract
					3'b000:
					begin
						case(funct7)
							7'h00 : ALUOp = ADD; //Add ALU Function
							7'h20 : ALUOp = SUB; //Subtract ALU function
							//NOTE: DO WE Need default here? Don't
							//think so because ALUOp already
							//assigned at start
						endcase
					end		
					//1 : SLL
					3'b001 :
					begin
						case(funct7) 
							7'h00 : ALUOp = SLL;
						endcase
					end
					//2 : SLT
					3'b010 :
					begin
						case(funct7) 
							7'h00 : ALUOp = SLT;
						endcase
					end
					//3 : SLTU
					3'b011 :
					begin
						case(funct7) 
							7'h00 : ALUOp = SLTU;
						endcase
					end
					//4 : XOR
					3'b100 :
					begin
						case(funct7) 
							7'h00 : ALUOp = XOR;
						endcase
					end
					//5 : SRL or SRA
					3'b101 :
					begin
						case(funct7) 
							7'h00 : ALUOp = SRL;
							7'h20 : ALUOp = SRA;
						endcase
					end
					//6 : OR
					3'b110 :
					begin
						case(funct7) 
							7'h00 : ALUOp = OR;
						endcase
					end
					//7 : AND
					3'b111 :
					begin
						case(funct7)
							7'h00 : ALUOp = AND;
						endcase
					end
				endcase
			end
			//I-type instructions (not including jalr or memory)
			//instructions)
			7'b0010011 :
			begin
				Branch = 0;
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't consider writing from memory
				ALUOp = ADD; //Default to ADD operation
				MemWrite = 4'b0; //Don't write to memory
				ALUSrc = 1; //Use the value specified in the immediate (I-type)
				RegWrite = 1; //Write to the register file
				Sel_imm = 0;
				Jal = 0;
				JalR = 0;
				AuiPc = 0;
				Lui = 0;
				case(funct3)
					//0 : Add
					3'b000: ALUOp = ADD; //Add ALU Function
					//1 : SLL
					3'b001 :
					begin
						if(funct7 == 0) begin
							ALUOp = SLL;
						end
					end
					//2 : SLT
					3'b010 : ALUOp = SLT;
					//3 : SLTU
					3'b011 : ALUOp = SLTU;
					//4 : XOR
					3'b100 : ALUOp = XOR;
					//5 : SRL or SRA
					3'b101 :
					begin
						case(funct7) 
							7'h00 : ALUOp = SRL;
							7'h20 : ALUOp = SRA;
						endcase
					end
					//6 : OR
					3'b110 : ALUOp = OR;
					//7 : AND
					3'b111 : ALUOp = AND;
				endcase
			end
			//jump and link (jal)
			7'b1101111 : begin
				Branch = 0;
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't consider writing from memory
				ALUOp = ADD; //Default ALU operation
				MemWrite = 4'b0; //Don't write to memory
				ALUSrc = 0; //Use the value specified in the register (R-type)
				RegWrite = 1; //Write to the register file
				Sel_imm = 0;
				Jal = 1;
				JalR = 0;
				AuiPc = 0;
				Lui = 0;
			end
			//jump and link register (jalr)
			7'b1100111 : begin
				Branch = 0;
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't consider writing from memory
				ALUOp = ADD; //Default to ADD operation
				MemWrite = 4'b0; //Don't write to memory
				ALUSrc = 1; //Use the value specified in the immediate (I-type)
				RegWrite = 1; //Write to the register file
				Sel_imm = 0;
				Jal = 1;
				JalR = 1;
				AuiPc = 0;
				Lui = 0;
			end

			//load upper immediate (lui)
			7'b0110111 : begin
				Branch = 0;
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't consider writing from memory
				ALUOp = ADD; //Default to ADD operation
				MemWrite = 4'b0; //Don't write to memory
				ALUSrc = 1; //Use the value specified in the immediate (I-type)
				RegWrite = 1; //Write to the register file
				Sel_imm = 0;
				Jal = 0;
				JalR = 0;
				AuiPc = 0;
				Lui = 1;   
			end	
				//AUIPC
			7'b0010111 : begin
				Branch = 0;
				MemRead = 0; //Don't read from memory
				MemtoReg = 0; //Don't consider writing from memory
				ALUOp = ADD; //Default to ADD operation
				MemWrite = 4'b0; //Don't write to memory
				ALUSrc = 1; //Use the value specified in the immediate (I-type)
				RegWrite = 1; //Write to the register file
				Sel_imm = 0;
				Jal = 0;
				JalR = 0;
				AuiPc = 1;	
				Lui = 0;
			end

		endcase
		
	end
endmodule
