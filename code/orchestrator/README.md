# Multi Rounds Hashing script

This [Python script](../../multi-round-hashing/multi_round_hashing.py) will take plaintext from stdin and output the hash after a number of iterations.
```sh
# Example usage
echo "mypassword123" | ../../multi-round-hashing/multi_round_hashing.py -r 5000
# output: 5000$d7c76d7620eeb1fdb7fd2074d6bf28e0cb193240e69a1d9bfe1f06c3000566a6
```

The [hash list](hashlist.txt) is computed using different number of rounds and hardcoded salt "abcdefghjiklmnop".
```sh
# hash list generation
ROUNDS=100000; while read -r line; do echo -n "${line}abcdefghjiklmnop" | ../../multi-round-hashing/multi_round_hashing.py -r $ROUNDS; done < wordlist.txt
```
