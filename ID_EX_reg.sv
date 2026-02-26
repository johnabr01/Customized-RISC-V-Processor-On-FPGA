import alu_op_pkg::*;

module ID_EX_reg #(parameter DATA_WIDTH = 32)
(
    input logic clk,
    input logic rst_n,
    input logic flush,
    input logic Branch,
    input logic [2:0] BranchType,
    input logic MemRead,
    input logic MemtoReg,
    input alu_op_t ALUOp,
    input logic [3:0] MemWrite,
    input logic ALUSrc,
    input logic RegWrite,
    input logic MemReadSigned,
    input logic [1:0] MemReadSize,
    input logic JAL,
    input logic JALR,
    input logic auipc,
    input logic lui,
    input logic [4:0] shamt,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [31:0] pc,
    input logic [31:0] reg_read_data1,
    input logic [31:0] reg_read_data2,
    input logic [4:0] reg_write_addr,
    input logic [31:0] imm_extended,
    input logic [19:0] auipc_or_lui_addr,

    output logic Branch_out,
    output logic [2:0] BranchType_out,
    output logic MemRead_out,
    output logic MemtoReg_out,
    output alu_op_t ALUOp_out,
    output logic [3:0] MemWrite_out,
    output logic ALUSrc_out,
    output logic RegWrite_out,
    output logic MemReadSigned_out,
    output logic [1:0] MemReadSize_out,
    output logic JAL_out,
    output logic JALR_out,
    output logic auipc_out,
    output logic lui_out,
    output logic [4:0] shamt_out,
    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,
    output logic [31:0] pc_out,
    output logic [31:0] reg_read_data1_out,
    output logic [31:0] reg_read_data2_out,
    output logic [4:0] reg_write_addr_out,
    output logic [31:0] imm_extended_out,
    output logic [19:0] auipc_or_lui_addr_out
);

    always_ff @(posedge clk) begin
        if (!rst_n || flush) begin
            Branch_out <= 1'b0;
            BranchType_out <= 3'b0;
            MemRead_out <= 1'b0;
            MemtoReg_out <= 1'b0;
            ALUOp_out <= alu_op_t'(0);
            MemWrite_out <= 4'b0;
            ALUSrc_out <= 1'b0;
            RegWrite_out <= 1'b0;
            MemReadSigned_out <= 1'b0;
            MemReadSize_out <= 2'b0;
            JAL_out <= 1'b0;
            JALR_out <= 1'b0;
            auipc_out <= 1'b0;
            lui_out <= 1'b0;
            shamt_out <= 5'b0;
            rs1_out <= 5'b0;
            rs2_out <= 5'b0;
            pc_out <= 32'b0;
            reg_read_data1_out <= 32'b0;
            reg_read_data2_out <= 32'b0;
            reg_write_addr_out <= 5'b0;
            imm_extended_out <= 32'b0;
            auipc_or_lui_addr_out <= 20'b0;
        end else begin
            Branch_out <= Branch;
            BranchType_out <= BranchType;
            MemRead_out <= MemRead;
            MemtoReg_out <= MemtoReg;
            ALUOp_out <= ALUOp;
            MemWrite_out <= MemWrite;
            ALUSrc_out <= ALUSrc;
            RegWrite_out <= RegWrite;
            MemReadSigned_out <= MemReadSigned;
            MemReadSize_out <= MemReadSize;
            JAL_out <= JAL;
            JALR_out <= JALR;
            auipc_out <= auipc;
            lui_out <= lui;
            shamt_out <= shamt;
            rs1_out <= rs1;
            rs2_out <= rs2;
            pc_out <= pc;
            reg_read_data1_out <= reg_read_data1;
            reg_read_data2_out <= reg_read_data2;
            reg_write_addr_out <= reg_write_addr;
            imm_extended_out <= imm_extended;
            auipc_or_lui_addr_out <= auipc_or_lui_addr;
        end
    end

endmodule
