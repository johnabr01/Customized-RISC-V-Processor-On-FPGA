module program_counter(
    input clk,
    input reset_n,
    input pc_write,
    input [31:0] pc_next,
    output logic [31:0] pc
);

always_ff @(posedge clk) begin
    if(reset_n == 1'b0) begin
        pc <= 32'b0;
    end else if (pc_write) begin
        pc <= pc_next;
    end
end
endmodule
