module IF_ID_reg #(parameter DATA_WIDTH =32)
(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  enable,
    input  logic                  flush,
    input  logic [DATA_WIDTH-1:0] instruction,
    input  logic [DATA_WIDTH-1:0] pc,
    output logic [DATA_WIDTH-1:0] instruction_out,
    output logic [DATA_WIDTH-1:0] pc_out
);

    logic [DATA_WIDTH-1:0] instr_reg;
    logic [DATA_WIDTH-1:0] pc_reg;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            instr_reg <= '0;
            pc_reg <= '0;
        end else if (flush) begin
            instr_reg <= '0;
            pc_reg <= '0;
        end else if (enable) begin
            instr_reg <= instruction;
            pc_reg <= pc;
        end
    end

    assign instruction_out = instr_reg;
    assign pc_out = pc_reg;
endmodule
