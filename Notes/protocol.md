# Orchestrator-Node protocol

## L1: Physical

- Data bus: 8 bit
- CLK
- R/W (Read active high, write inverted)
- Addr bus: 2 bit

## L2: Data-link

1. **Write**: Master drives data and addr bus and pulls Read/Write low (write).
2. **Read**: Master drives addr bus and sets Read/Write high (read). Slave drives data bus.
