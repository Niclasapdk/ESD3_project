# Raspberry Pi Hashcat benchmarks

All benchmarks are run with the command

```sh
hashcat -m $HASH_MODE -w 4 -a 3 hash.txt
```

# Hardware

Raspberry Pi 4 model B.
The output of `lscpu` can be found [here](lscpu).

# Benchmarks

## SHA-2-256

- Hash mode: 1400
- Performance: 5330.7 kH/s
- Efficiency: 740.4 kH/Ws

### Hash generation

```sh
echo "hejhejhej" | sha256sum | cut -d' ' -f1 > hash.txt
```

### Hashcat performance

```
Session..........: hashcat
Status...........: Running
Hash.Name........: SHA2-256
Hash.Target......: 66d2d11753be2f4216fdce2502dae77fd9e1963a98f62623afa...9967fe
Time.Started.....: Thu Sep 21 09:07:52 2023 (19 secs)
Time.Estimated...: Thu Sep 21 09:08:11 2023 (0 secs)
Guess.Mask.......: ?1?2?2?2?2 [5]
Guess.Charset....: -1 ?l?d?u, -2 ?l?d, -3 ?l?d*!$@_, -4 Undefined
Guess.Queue......: 5/15 (33.33%)
Speed.#1.........:  5330.7 kH/s (45.18ms) @ Accel:1024 Loops:62 Thr:1 Vec:1
Recovered........: 0/1 (0.00%) Digests
Progress.........: 102596608/104136192 (98.52%)
Rejected.........: 0/102596608 (0.00%)
Restore.Point....: 1654784/1679616 (98.52%)
Restore.Sub.#1...: Salt:0 Amplifier:0-62 Iteration:0-62
Candidates.#1....: s2ifq -> Xqxdq
```

### Power consumption

- Hashcat running: 7.2 W

## SHA-3-256

- Hash mode: 17400
- Performance: 1345.9 kH/s
- Efficiency: 172.6 kH/Ws

### Hash generation

```sh
echo "hejhejhej" | openssl dgst -sha3-256 | cut -d' ' -f2 > hash.txt
```

### Hashcat performance

```
Session..........: hashcat
Status...........: Running
Hash.Name........: SHA3-256
Hash.Target......: 610222ddc6ead4fa111c50d3a2202696f4de6b55f410b922486...bbf2be
Time.Started.....: Thu Sep 21 09:26:15 2023 (56 secs)
Time.Estimated...: Thu Sep 21 09:27:32 2023 (21 secs)
Guess.Mask.......: ?1?2?2?2?2 [5]
Guess.Charset....: -1 ?l?d?u, -2 ?l?d, -3 ?l?d*!$@_, -4 Undefined
Guess.Queue......: 5/15 (33.33%)
Speed.#1.........:  1345.9 kH/s (185.94ms) @ Accel:1024 Loops:62 Thr:1 Vec:1
Recovered........: 0/1 (0.00%) Digests
Progress.........: 75169792/104136192 (72.18%)
Rejected.........: 0/75169792 (0.00%)
Restore.Point....: 1212416/1679616 (72.18%)
Restore.Sub.#1...: Salt:0 Amplifier:0-62 Iteration:0-62
Candidates.#1....: s2lx6 -> Xqorv
```

### Power consumption

- Hashcat running: 7.8 W

## Bcrypt

- Hash mode: 3200
- Performance: 11 H/s
- Efficiency: 1.67 H/Ws

### Hash generation

```sh
pip3 install bcrypt
python3 -c 'import bcrypt; print(bcrypt.hashpw(b"hejhejhej", bcrypt.gensalt(12)).decode())' > hash.txt
```

### Hashcat performance

```
Session..........: hashcat
Status...........: Exhausted
Hash.Name........: bcrypt $2*$, Blowfish (Unix)
Hash.Target......: $2b$12$RVAvCclc/mCIWtsBZztxE.HiE7oYwr8l259TW1I8qAzP...nv/JUG
Time.Started.....: Thu Sep 21 09:43:26 2023 (3 mins, 28 secs)
Time.Estimated...: Thu Sep 21 09:46:54 2023 (0 secs)
Guess.Mask.......: ?1?2 [2]
Guess.Charset....: -1 ?l?d?u, -2 ?l?d, -3 ?l?d*!$@_, -4 Undefined
Guess.Queue......: 2/15 (13.33%)
Speed.#1.........:       11 H/s (46.96ms) @ Accel:8 Loops:512 Thr:1 Vec:1
Recovered........: 0/1 (0.00%) Digests
Progress.........: 2232/2232 (100.00%)
Rejected.........: 0/2232 (0.00%)
Restore.Point....: 36/36 (100.00%)
Restore.Sub.#1...: Salt:0 Amplifier:61-62 Iteration:3584-4096
Candidates.#1....: Xf -> Xq
```

### Power consumption

- Hashcat running: 6.6 W
