/*
* @input[31:0] alu_in1 - first 32-bit input register to alu
* @input[31:0] alu_in2 - second 32-bit input register to alu
* @input[3:0] alu_op_ctrl - 4-bit ALU control signal (specify what operation
* to perform). alu_op_ctrl signal is based on ALU control unit
* @output[31:0] alu_out - 32-bit output register
* @output zero - 1-bit control signal used for branch instructions
*/

import alu_op_pkg::*;

module alu(input [31:0] alu_in1,
	input [31:0] alu_in2,
	input  alu_op_pkg::alu_op_t alu_op_ctrl,   // use enum type	
	input [4:0] shamt,
    input branch,
    input [2:0] branch_type,
	output logic[31:0] alu_out,
	output logic pc_src
	);

	always_comb begin	 
		pc_src = 0; //default value to prevent inferred latch
		
        unique case (alu_op_ctrl)	//unique case will give us a warning if mulitple cases could match.
            alu_op_pkg::ADD: alu_out = alu_in1 + alu_in2;                       // ADD
            alu_op_pkg::SUB: alu_out = alu_in1 - alu_in2;                       // SUB
            alu_op_pkg::XOR: alu_out = alu_in1 ^ alu_in2;                       // XOR
            alu_op_pkg::OR: alu_out = alu_in1 | alu_in2;                       // OR
            alu_op_pkg::AND: alu_out = alu_in1 & alu_in2;                       // AND
            alu_op_pkg::SLL: alu_out = alu_in1 << shamt;                 // SLL, only 5 bits because u can shift only 32 times, 
            alu_op_pkg::SRL: alu_out = alu_in1 >> shamt;                 // SRL (logical right shift)
            alu_op_pkg::SRA: alu_out = $signed(alu_in1) >>> shamt;       // SRA (arithmetic right shift), the reference sheet said MSB-extends 
                                                                        // so its signed extension, >>> does signed arithmetic extension.
            alu_op_pkg::SLT: alu_out = ($signed(alu_in1) < $signed(alu_in2)) ? 32'd1 : 32'd0; // SLT (signed compare)
            alu_op_pkg::SLTU: alu_out = (alu_in1 < alu_in2) ? 32'd1 : 32'd0;     // SLTU (unsigned compare)
            default: alu_out = 32'd0; //to prevent inferred latches
        endcase
    
        if (branch) begin
            case(branch_type)
                //0: beq
                3'b000:
                begin
                    if (alu_in1 == alu_in2) pc_src = 1;
                end
                //1: bne
                3'b001:
                begin
                    if (alu_in1 != alu_in2) pc_src = 1;
                end
                //4: blt
                3'b100:
                begin
                    if ($signed(alu_in1) < $signed(alu_in2)) pc_src = 1;
                end
                //5: bge
                3'b101:
                begin
                    if ($signed(alu_in1) >= $signed(alu_in2)) pc_src = 1;
                end
                //6: bltu
                3'b110:
                begin
                    if ($unsigned(alu_in1) < $unsigned(alu_in2)) pc_src = 1;
                end
                //7: bgeu
                3'b111:
                begin
                    if ($unsigned(alu_in1) >= $unsigned(alu_in2)) pc_src = 1;
                end
                default: pc_src = 0;
            endcase
        end
    end

endmodule
