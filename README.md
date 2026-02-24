# Customized RISC-V Processor on FPGA

This project implements a **custom single-cycle RISC-V processor** in SystemVerilog and deploys it on an FPGA.  
It includes the datapath, control logic, memory modules, and testbenches for verification.
We are currently working on getting the single-cycle processor on the MiniZed development board, in addition to pipelining our current design.

## Features
- Implements the **entire** RV32I instruction subset
- Modular SystemVerilog design (ALU, Register File, Control Unit, etc.)
- Instruction and data memory modules
- Testbenches for simulation
- Ready for FPGA synthesis and testing

## Project Structure
Top level: single_cycle_toplevel.sv
