# Orchestrator-Node protocol

## L1: Physical

- Data bus: 8 bit
- CLK
- R/W (Read active high, write inverted)
- Addr bus: 2 bit

### Header pinout
```
FPGA, GPIO, PLUSBUS
K16,  40,   D[0]
J17,  39,   D[1]
G12,  38,   D[2]
G13,  37,   D[3]
G15,  36,   D[4]
G16,  35,   D[5]
F12,  34,   D[6]
F13,  33,   D[7]
E16,  28,   A[0]
E15,  27,   A[1]
E14,  26,   R_NW
C15,  25,   CLK
GND,  12,   GND
```

## L2: Data-link

1. **Write**: Master drives data and addr bus and pulls Read/Write low (write).
2. **Read**: Master drives addr bus and sets Read/Write high (read). Slave drives data bus.
