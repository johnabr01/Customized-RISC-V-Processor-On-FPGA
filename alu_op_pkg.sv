package alu_op_pkg;

  typedef enum logic [3:0] {
    ADD,
    SUB,
    XOR,
    OR,
    AND,
    SLL,
    SRL,
    SRA,
    SLT,
    SLTU
  } alu_op_t;

endpackage
