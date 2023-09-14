# Bcrypt 
(In Bits)

- 6 (Cost input)
- 16*8 (salt input)
- 72*8 (passwdinput)
- 24*8 (ctext/digest)
- 18*32 (subkeys)
- 4*256*32 (s boxes)
- 18*32+4*256*32 (PI)(ROM rarely used)
- 18*32+4*256*32 (subkey and s box buffers)
- 2*64 (block)(2 copies for buffer)
- 3*2*32 (blowfish encrypt)
- Total: ~68000 bits
- BRAM: 33344 bits 

# SHA 2
(In Bits times 32)

- 8 (H0-H7)
- 64 (Primes)
- 64 (w)
- 8 (a-h)
- 6 (comp loop)
- 8 (a-h buffers)
- 32 (digest)
- Total: 6080 bits

# SHA 3
(In Bytes)

- 128 (Input)
- input + n*100+24 (n: number of hashes)
- Total: 252