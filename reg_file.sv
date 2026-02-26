// regfile_ff.sv
module regfile_ff #(
  parameter N = 32,            // number of registers
  parameter W = 32             // width
) (
  input logic                   clk,
  input logic                   reset_n,
  input logic                   wen,
  input logic [$clog2(N)-1:0]   waddr,
  input logic [W-1:0]           wdata,
  input logic [$clog2(N)-1:0]   raddr1,
  input logic [$clog2(N)-1:0]   raddr2,
  output logic [W-1:0]          rdata1,
  output logic [W-1:0]          rdata2
);

  // Register array as FFs
  logic [W-1:0] regs [0:N-1];

  // RV32I x0 must remain hardwired to zero
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      for (int i = 0; i < N; i++) begin
        regs[i] <= '0;
      end
    end else begin
      if (wen && (waddr != '0)) begin
        regs[waddr] <= wdata;
      end
      regs[0] <= '0;
    end
  end

  // Asynchronous read ports with x0 read-as-zero behavior
  always_comb begin
    rdata1 = (raddr1 == '0) ? '0 : regs[raddr1];
    rdata2 = (raddr2 == '0) ? '0 : regs[raddr2];
  end

endmodule
