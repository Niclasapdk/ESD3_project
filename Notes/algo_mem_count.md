# Bcrypt 
(In Bits)

- $6$ (Cost input)
- $16 \cdot 8$ (salt input)
- $72 \cdot 8$ (passwdinput)
- $24 \cdot 8$ (ctext/digest)
- $18 \cdot 32$ (subkeys)
- $4 \cdot 256 \cdot 32$ (s boxes)
- $18 \cdot 32 + 4 \cdot 256 \cdot 32$ (PI)(ROM rarely used)
- $18 \cdot 32 + 4 \cdot 256 \cdot 32$ (subkey and s box buffers)
- $2 \cdot 64$ (block)(2 copies for buffer)
- $3 \cdot 2 \cdot 32$ (blowfish encrypt)
- Total: $~68000$ Bits
- BRAM: $33344$ Bits 

# SHA 2
(In Bits times 32)

- $8$ (H0-H7)
- $64$ (Primes)
- $64$ (w)
- $8$ (a-h)
- $6$ (comp loop)
- $8$ (a-h buffers)
- $32$ (digest)
- Total: $6080$ bits

# SHA 3
(In Bytes)

- $128$ (Input)
- $input + n \cdot 100 + 24$ (n: number of hashes)
- Total: $252$ 