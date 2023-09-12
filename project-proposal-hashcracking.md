# Hash Cracking

Password hashing is a security measure where a plaintext password (often along
with a random "salt") is "hashed" which is a mathematical function which maps a
certain input to a unique output and cannot be reversed.
Since the hashing function cannot be reversed, a brute-force methodology is
applied when "cracking" said hashes.
This can either be done with complete alphabetical exhaustion or with a word
list of possible passwords.

The hashing algorithms are made to be computationally expensive which makes
brute forcing resource intensive. Furthermore, there are many different hashing
algorithms - some are easier to compute than others (on different hardware).

The project proposal is to design and implement a hash cracking system using
FPGA's for slave systems and some master (for example Raspberry Pi) to delegate
plaintext values to hash and compare to the hash being cracked.
Traditionally, GPU clusters are used for this purpose, however such clusters
are in very high demand, have higher overhead (leading to higher power
consumption), and have suffered under supply chain issues.

# Example tasks for the project

- Choose hashing algorithm to target (based on usage and potential for hardware acceleration on an FPGA)
- Design protocol between master and slave subsystems (to optimize performance)
- Implement hash algorithm on slave subsystems (FPGA)
- Design and implement master subsystem for orchestration of slave subsystems
    - Load balancing between slaves
    - Keeping track of overall progress
- Performance test - Goal is to achieve as many hashes per time as possible
