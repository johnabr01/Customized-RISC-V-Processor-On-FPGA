module sign_extension(
    input [11:0] imm_in,
    output logic [31:0] imm_out
);

    assign imm_out = {{20{imm_in[11]}}, imm_in};

endmodule