module riscv_processor (
    input logic clk,
    input logic reset_n
);

    // ========================= IF stage =========================
    logic [31:0] pc_current, pc_next, pc_plus_4;
    logic [31:0] instruction;
    logic        pc_write;

    // ========================= ID stage =========================
    logic [31:0] instruction_ID, pc_ID;
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic Branch, MemRead_ID, MemtoReg_ID, ALUSrc_ID, RegWrite_ID;
    logic [1:0] MemReadSize_ID;
    logic [3:0] MemWrite_ID;
    logic MemReadSigned_ID;
    logic Sel_imm;
    logic Jal_ID, Jalr_ID, AuiPc_ID, Lui_ID;
    logic [2:0] BranchType;
    logic BranchSigned;
    alu_op_pkg::alu_op_t ALUOp_ID;

    logic [31:0] reg_write_data, reg_read_data1_ID, reg_read_data2_ID;
    logic [31:0] imm_extended_ID;
    logic [19:0] auipc_or_lui_addr_ID;
    logic [4:0] shamt_ID;

    logic if_id_enable, if_id_flush;

    // ========================= EX stage =========================
    logic Branch_EX, MemRead_EX, MemtoReg_EX, ALUSrc_EX, RegWrite_EX;
    logic [2:0] BranchType_EX;
    logic [1:0] MemReadSize_EX;
    logic [3:0] MemWrite_EX;
    logic MemReadSigned_EX;
    logic Jal_EX, Jalr_EX, auipc_EX, lui_EX;
    logic [4:0] shamt_EX, rs1_EX, rs2_EX, reg_write_addr_EX;
    logic [31:0] reg_read_data1_EX, reg_read_data2_EX, imm_extended_EX, pc_EX;
    logic [19:0] auipc_or_lui_addr_EX;
    alu_op_pkg::alu_op_t ALUOp_EX;

    logic [31:0] forward_a_EX, forward_b_EX;
    logic [31:0] alu_input2, alu_result_raw_EX, alu_result_EX;
    logic [31:0] branch_jump_target_EX;
    logic branch_taken_EX, control_redirect_EX;
    logic id_ex_flush;

    // ========================= MEM stage =========================
    logic MemtoReg_MEM, RegWrite_MEM, MemReadSigned_MEM, Jal_MEM, auipc_MEM, lui_MEM;
    logic [1:0] MemReadSize_MEM;
    logic [3:0] MemWrite_MEM;
    logic [31:0] alu_result_MEM, reg_read_data2_MEM, mem_read_data_MEM, reg_write_data_MEM;
    logic [4:0] reg_write_addr_MEM;
    logic [19:0] auipc_or_lui_addr_MEM;

    // ========================= WB stage =========================
    logic MemtoReg_WB, RegWrite_WB, MemReadSigned_WB;
    logic [1:0] MemReadSize_WB;
    logic [31:0] alu_result_WB, mem_read_data_WB, reg_write_data_WB;
    logic [4:0] reg_write_addr_WB;

    // Hazard detection helpers
    logic uses_rs1_ID;
    logic uses_rs2_ID;
    logic load_use_hazard;
    logic control_stall;

    // ========== Program Counter ==========
    program_counter pc_inst (
        .clk(clk),
        .reset_n(reset_n),
        .pc_write(pc_write),
        .pc_next(pc_next),
        .pc(pc_current)
    );

    adder #(.WIDTH(32)) pc_adder (
        .in0(pc_current),
        .in1(32'd4),
        .sum(pc_plus_4)
    );

    // ========== Instruction Memory ==========
    instruction_memory #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(32)
    ) instr_mem (
        .clk(clk),
        .we(1'b0),
        .addr(pc_current[11:2]),
        .write_data(32'b0),
        .read_data(instruction)
    );

    IF_ID_reg #(.DATA_WIDTH(32)) if_id_reg_inst (
        .clk(clk),
        .rst_n(reset_n),
        .enable(if_id_enable),
        .flush(if_id_flush),
        .instruction(instruction),
        .pc(pc_current),
        .instruction_out(instruction_ID),
        .pc_out(pc_ID)
    );

    // ========== Instruction Decode ==========
    assign opcode = instruction_ID[6:0];
    assign rd = instruction_ID[11:7];
    assign funct3 = instruction_ID[14:12];
    assign rs1 = instruction_ID[19:15];
    assign rs2 = instruction_ID[24:20];
    assign funct7 = instruction_ID[31:25];
    assign shamt_ID = instruction_ID[24:20];
    assign auipc_or_lui_addr_ID = instruction_ID[31:12];

    main_control_unit control_unit (
        .opcode(opcode),
        .funct7(funct7),
        .funct3(funct3),
        .Branch(Branch),
        .BranchType(BranchType),
        .BranchSigned(BranchSigned),
        .MemRead(MemRead_ID),
        .MemtoReg(MemtoReg_ID),
        .ALUOp(ALUOp_ID),
        .MemWrite(MemWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .RegWrite(RegWrite_ID),
        .MemReadSigned(MemReadSigned_ID),
        .MemReadSize(MemReadSize_ID),
        .Sel_imm(Sel_imm),
        .Jal(Jal_ID),
        .JalR(Jalr_ID),
        .AuiPc(AuiPc_ID),
        .Lui(Lui_ID)
    );

    regfile_ff #(
        .N(32),
        .W(32)
    ) reg_file (
        .clk(clk),
        .reset_n(reset_n),
        .wen(RegWrite_WB),
        .waddr(reg_write_addr_WB),
        .wdata(reg_write_data),
        .raddr1(rs1),
        .raddr2(rs2),
        .rdata1(reg_read_data1_ID),
        .rdata2(reg_read_data2_ID)
    );

    // Immediate generation for RV32I control-flow and ALU/memory operations
    logic signed [31:0] imm_i, imm_s, imm_b, imm_j;
    always_comb begin
        imm_i = {{20{instruction_ID[31]}}, instruction_ID[31:20]};
        imm_s = {{20{instruction_ID[31]}}, instruction_ID[31:25], instruction_ID[11:7]};
        imm_b = {{19{instruction_ID[31]}}, instruction_ID[31], instruction_ID[7], instruction_ID[30:25], instruction_ID[11:8], 1'b0};
        imm_j = {{11{instruction_ID[31]}}, instruction_ID[31], instruction_ID[19:12], instruction_ID[20], instruction_ID[30:21], 1'b0};

        case (opcode)
            7'b0100011: imm_extended_ID = imm_s; // store
            7'b1100011: imm_extended_ID = imm_b; // branch
            7'b1101111: imm_extended_ID = imm_j; // jal
            default:    imm_extended_ID = imm_i; // I-type/jalr/load
        endcase
    end

    // Hazard detection: stall on generic load-use dependency
    always_comb begin
        // Most instructions use rs1 except LUI/JAL/AUIPC and empty bubbles.
        uses_rs1_ID = ~(opcode == 7'b0110111 || // LUI
                        opcode == 7'b1101111 || // JAL
                        opcode == 7'b0010111 || // AUIPC
                        opcode == 7'b0000000);  // bubble/NOP from flush

        // Only R/S/B formats consume rs2 as source.
        uses_rs2_ID = (opcode == 7'b0110011 ||  // R-type
                       opcode == 7'b0100011 ||  // Store
                       opcode == 7'b1100011);   // Branch
    end

    assign load_use_hazard = MemRead_EX && (reg_write_addr_EX != 5'd0) &&
                             ((uses_rs1_ID && (reg_write_addr_EX == rs1)) ||
                              (uses_rs2_ID && (reg_write_addr_EX == rs2)));

    assign control_stall = load_use_hazard;
    assign pc_write = ~control_stall;
    assign if_id_enable = ~control_stall;

    ID_EX_reg #(.DATA_WIDTH(32)) id_ex_reg_inst (
        .clk(clk),
        .rst_n(reset_n),
        .flush(id_ex_flush),
        .Branch(Branch),
        .BranchType(BranchType),
        .MemRead(MemRead_ID),
        .MemtoReg(MemtoReg_ID),
        .ALUOp(ALUOp_ID),
        .MemWrite(MemWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .RegWrite(RegWrite_ID),
        .MemReadSigned(MemReadSigned_ID),
        .MemReadSize(MemReadSize_ID),
        .JAL(Jal_ID),
        .JALR(Jalr_ID),
        .auipc(AuiPc_ID),
        .lui(Lui_ID),
        .shamt(shamt_ID),
        .rs1(rs1),
        .rs2(rs2),
        .pc(pc_ID),
        .reg_read_data1(reg_read_data1_ID),
        .reg_read_data2(reg_read_data2_ID),
        .reg_write_addr(rd),
        .imm_extended(imm_extended_ID),
        .auipc_or_lui_addr(auipc_or_lui_addr_ID),

        .Branch_out(Branch_EX),
        .BranchType_out(BranchType_EX),
        .MemRead_out(MemRead_EX),
        .MemtoReg_out(MemtoReg_EX),
        .ALUOp_out(ALUOp_EX),
        .MemWrite_out(MemWrite_EX),
        .ALUSrc_out(ALUSrc_EX),
        .RegWrite_out(RegWrite_EX),
        .MemReadSigned_out(MemReadSigned_EX),
        .MemReadSize_out(MemReadSize_EX),
        .JAL_out(Jal_EX),
        .JALR_out(Jalr_EX),
        .auipc_out(auipc_EX),
        .lui_out(lui_EX),
        .shamt_out(shamt_EX),
        .rs1_out(rs1_EX),
        .rs2_out(rs2_EX),
        .pc_out(pc_EX),
        .reg_read_data1_out(reg_read_data1_EX),
        .reg_read_data2_out(reg_read_data2_EX),
        .reg_write_addr_out(reg_write_addr_EX),
        .imm_extended_out(imm_extended_EX),
        .auipc_or_lui_addr_out(auipc_or_lui_addr_EX)
    );

    // Forwarding in EX for branch/jump and ALU operands
    always_comb begin
        forward_a_EX = reg_read_data1_EX;
        forward_b_EX = reg_read_data2_EX;

        if (RegWrite_MEM && (reg_write_addr_MEM != 5'd0) && (reg_write_addr_MEM == rs1_EX) && !MemtoReg_MEM)
            forward_a_EX = reg_write_data_MEM;
        else if (RegWrite_WB && (reg_write_addr_WB != 5'd0) && (reg_write_addr_WB == rs1_EX))
            forward_a_EX = reg_write_data;

        if (RegWrite_MEM && (reg_write_addr_MEM != 5'd0) && (reg_write_addr_MEM == rs2_EX) && !MemtoReg_MEM)
            forward_b_EX = reg_write_data_MEM;
        else if (RegWrite_WB && (reg_write_addr_WB != 5'd0) && (reg_write_addr_WB == rs2_EX))
            forward_b_EX = reg_write_data;
    end

    logic [31:0] mux_inputs [2];
    assign mux_inputs[0] = forward_b_EX;
    assign mux_inputs[1] = imm_extended_EX;

    mux #(.NUM_INPUTS(2)) alu_src_mux2 (
        .data_in(mux_inputs),
        .sel(ALUSrc_EX),
        .data_out(alu_input2)
    );

    alu alu_inst (
        .alu_in1(forward_a_EX),
        .alu_in2(alu_input2),
        .alu_op_ctrl(ALUOp_EX),
        .shamt(shamt_EX),
        .alu_out(alu_result_raw_EX)
    );

    branch_comparator branch_comparator_ex (
        .reg_data1(forward_a_EX),
        .reg_data2(forward_b_EX),
        .branch(Branch_EX),
        .branch_type(BranchType_EX),
        .pc_src(branch_taken_EX)
    );

    assign alu_result_EX = Jal_EX ? (pc_EX + 32'd4) : alu_result_raw_EX;

    always_comb begin
        branch_jump_target_EX = pc_EX + imm_extended_EX;
        if (Jalr_EX)
            branch_jump_target_EX = (forward_a_EX + imm_extended_EX) & 32'hFFFFFFFE;
    end

    assign control_redirect_EX = branch_taken_EX | Jal_EX;
    assign if_id_flush = control_redirect_EX;
    assign id_ex_flush = control_stall | control_redirect_EX;

    EX_MEM_reg #(.DATA_WIDTH(32)) ex_mem_reg_inst (
        .clk(clk),
        .rst_n(reset_n),
        .alu_result(alu_result_EX),
        .reg_read_data2(forward_b_EX),
        .reg_write_addr(reg_write_addr_EX),
        .MemtoReg(MemtoReg_EX),
        .MemWrite(MemWrite_EX),
        .RegWrite(RegWrite_EX),
        .MemReadSigned(MemReadSigned_EX),
        .MemReadSize(MemReadSize_EX),
        .JAL(Jal_EX),
        .auipc(auipc_EX),
        .lui(lui_EX),
        .auipc_or_lui_addr(auipc_or_lui_addr_EX),

        .MemtoReg_out(MemtoReg_MEM),
        .MemWrite_out(MemWrite_MEM),
        .RegWrite_out(RegWrite_MEM),
        .MemReadSigned_out(MemReadSigned_MEM),
        .MemReadSize_out(MemReadSize_MEM),
        .JAL_out(Jal_MEM),
        .auipc_out(auipc_MEM),
        .lui_out(lui_MEM),
        .alu_result_out(alu_result_MEM),
        .reg_read_data2_out(reg_read_data2_MEM),
        .reg_write_addr_out(reg_write_addr_MEM),
        .auipc_or_lui_addr_out(auipc_or_lui_addr_MEM)
    );

    logic [3:0] MemStoreSize;
    write_control_shifter write_control_shifter_inst (
        .alu_result(alu_result_MEM[1:0]),
        .MemWrite(MemWrite_MEM),
        .MemStoreSize(MemStoreSize)
    );

    logic [31:0] mem_write_data_out;
    write_data_shifter write_data_shifter_inst(
        .alu_result(alu_result_MEM[1:0]),
        .mem_write_data_in(reg_read_data2_MEM),
        .mem_write_data_out(mem_write_data_out)
    );

    data_memory #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(32)
    ) data_mem (
        .clk(clk),
        .we(MemStoreSize),
        .addr((alu_result_MEM[11:2])),
        .write_data(mem_write_data_out),
        .read_data(mem_read_data_MEM)
    );

    // rd calculations in MEM stage
    logic [31:0] jal_rd_mux_inputs [2];
    logic [31:0] jal_rd_mux_out;
    assign jal_rd_mux_inputs[0] = alu_result_MEM;
    assign jal_rd_mux_inputs[1] = alu_result_MEM; // jal/jalr already forced to pc+4 in EX

    mux #(.NUM_INPUTS(2)) jal_rd_mux (
        .data_in(jal_rd_mux_inputs),
        .sel(Jal_MEM),
        .data_out(jal_rd_mux_out)
    );

    logic [31:0] auipc_rd_mux_inputs [2];
    logic [31:0] auipc_rd_mux_out;
    assign auipc_rd_mux_inputs[0] = jal_rd_mux_out;
    assign auipc_rd_mux_inputs[1] = pc_current + {auipc_or_lui_addr_MEM, {12{1'b0}}};

    mux #(.NUM_INPUTS(2)) auipc_rd_mux (
        .data_in(auipc_rd_mux_inputs),
        .sel(auipc_MEM),
        .data_out(auipc_rd_mux_out)
    );

    logic [31:0] lui_rd_mux_inputs [2];
    assign lui_rd_mux_inputs[0] = auipc_rd_mux_out;
    assign lui_rd_mux_inputs[1] = {auipc_or_lui_addr_MEM, {12{1'b0}}};

    mux #(.NUM_INPUTS(2)) lui_rd_mux (
        .data_in(lui_rd_mux_inputs),
        .sel(lui_MEM),
        .data_out(reg_write_data_MEM)
    );

    MEM_WB_reg #(.DATA_WIDTH(32)) mem_wb_reg_inst (
        .clk(clk),
        .rst_n(reset_n),
        .alu_result(alu_result_MEM),
        .mem_read_data(mem_read_data_MEM),
        .reg_write_data(reg_write_data_MEM),
        .reg_write_addr(reg_write_addr_MEM),
        .MemtoReg(MemtoReg_MEM),
        .RegWrite(RegWrite_MEM),
        .MemReadSigned(MemReadSigned_MEM),
        .MemReadSize(MemReadSize_MEM),

        .MemtoReg_out(MemtoReg_WB),
        .RegWrite_out(RegWrite_WB),
        .MemReadSigned_out(MemReadSigned_WB),
        .MemReadSize_out(MemReadSize_WB),
        .alu_result_out(alu_result_WB),
        .mem_read_data_out(mem_read_data_WB),
        .reg_write_data_out(reg_write_data_WB),
        .reg_write_addr_out(reg_write_addr_WB)
    );

    logic [15:0] halfword;
    data_indexer data_indexer_inst (
        .MemReadSize(MemReadSize_WB),
        .offset(alu_result_WB[1:0]),
        .mem_read_data(mem_read_data_WB),
        .indexed_data(halfword)
    );

    logic [31:0] byte_extended;
    extender #(.INPUT_WIDTH(8)) byte_extender (
        .in(halfword[7:0]),
        .sign(MemReadSigned_WB),
        .out(byte_extended)
    );

    logic [31:0] halfword_extended;
    extender #(.INPUT_WIDTH(16)) halfword_extender (
        .in(halfword),
        .sign(MemReadSigned_WB),
        .out(halfword_extended)
    );

    logic [31:0] mux_inputs4 [3];
    logic [31:0] mem_to_reg;
    assign mux_inputs4[0] = byte_extended;
    assign mux_inputs4[1] = halfword_extended;
    assign mux_inputs4[2] = mem_read_data_WB;

    mux #(.NUM_INPUTS(3)) extended_mux (
        .data_in (mux_inputs4),
        .sel(MemReadSize_WB),
        .data_out(mem_to_reg)
    );

    logic [31:0] mux_inputs2 [2];
    assign mux_inputs2[0] = reg_write_data_WB;
    assign mux_inputs2[1] = mem_to_reg;

    mux #(.NUM_INPUTS(2)) mem_to_reg_mux (
        .data_in (mux_inputs2),
        .sel(MemtoReg_WB),
        .data_out(reg_write_data)
    );

    // PC update: predict not taken, redirect on taken branch/jump in EX
    always_comb begin
        pc_next = pc_plus_4;
        if (control_redirect_EX)
            pc_next = branch_jump_target_EX;
    end

endmodule
