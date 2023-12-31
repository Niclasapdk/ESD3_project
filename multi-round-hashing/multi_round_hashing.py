#!/usr/bin/env python3
import sys
import argparse
import hashlib
from tqdm import tqdm

def sha256_n_times(input_string, n):
    hashed_value = input_string.encode('utf-8')  # Convert the input string to bytes
    for _ in tqdm(range(n)):
        hashed_value = hashlib.sha256(hashed_value).digest()
    return hashed_value.hex()

def main():
    parser = argparse.ArgumentParser(description="PlusBUS Inc. hasher cracker orchestrator 9000")
    parser.add_argument("-r", "--rounds", type=int, default=5000, help="Number of rounds (default 5000)")

    args = parser.parse_args()

    inp = sys.stdin.read()

    result = sha256_n_times(inp, args.rounds)
    print(f"{args.rounds}${result}")

if __name__ == "__main__":
    main()
