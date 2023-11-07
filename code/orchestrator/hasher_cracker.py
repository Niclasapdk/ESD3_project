import serial
import argparse
import struct

proto_spec = {
        # L2
        "start": b"A",
        "stop":  b"B",
        "read":  b"R",
        "write": b"W",
        # L3
        "stx":   b"\x02",
        "etx":   b"\x03",
        "dle":   b"\x10"
        }

class Orchestrator:
    def __init__(self, port: str, baudrate: int, proto_spec: dict, wordlist: str, hashlist: str):
        self.serial = serial.Serial(port, baudrate=baudrate)
        self.proto_spec = proto_spec
        self.wordlist = self.read_wordlist(wordlist)
        self.hashlist = self.read_hashlist(hashlist)
        self.salts = [b"abcdefghjiklmnop"]
        self.prep_pkt()

    def read_hashlist(self, hashlist: str):
        # TODO: parse hashlist
        with open(hashlist, "r") as f:
            return list(map(lambda x: x.strip().encode(), f.readlines()))

    def read_wordlist(self, wordlist: str):
        with open(wordlist, "r") as f:
            return list(map(lambda x: x.strip().encode(), f.readlines()))

    # Should be called once in the constructor
    # not called every time data is sent in order to increase speed
    def prep_pkt(self):
        self.pkt = [
                self.proto_spec["start"],
                self.proto_spec["write"],
                b"ADDR",
                b"DATA",
                self.proto_spec["stop"]
                ]
        self.data_idx = self.pkt.index(b"DATA")
        self.addr_idx = self.pkt.index(b"ADDR")

    def send_to_node(self, node_addr: int, data: bytes):
        for b in data:
            self.pkt[self.data_idx] = bytes([b])
            self.pkt[self.addr_idx] = f"{node_addr}".encode()
            self.serial.write(b"".join(self.pkt))

    def sha256_pad(self, passwd: bytes):
        l = 8*len(passwd)
        k = (512-64-8-l)
        k_bytes = k//8
        return passwd + b"\x80" + b"\x00"*k_bytes + struct.pack(">Q", l)

    def escape_passwd(self, passwd: bytes):
        passwd = passwd.replace(self.proto_spec["dle"], self.proto_spec["dle"] + self.proto_spec["dle"])
        passwd = passwd.replace(self.proto_spec["stx"], self.proto_spec["dle"] + self.proto_spec["stx"])
        passwd = passwd.replace(self.proto_spec["etx"], self.proto_spec["dle"] + self.proto_spec["etx"])
        return passwd

    def schick_passwort(self, node_addr: int, passwd: bytes, salz: bytes):
        if len(passwd) > 39 or len(salz) != 16:
            print("Too long password oder du hasst salz")
            print("Youuusa make big dooo doo this time")
            return
        padded_passwd = self.sha256_pad(passwd+salz)
        passwd_pkt = self.proto_spec["stx"] + self.escape_passwd(padded_passwd) + self.proto_spec["etx"]
        self.send_to_node(node_addr, passwd_pkt)

    def ruuuuuunnn(self, nodes: list):
        for salz in self.salts:
            for i, p in enumerate(self.wordlist):
                self.schick_passwort(nodes[i%len(nodes)], p, salz)

def main():
    parser = argparse.ArgumentParser(description="PlusBUS Inc. hasher cracker orchestrator 9000")
    parser.add_argument("-p", "--port", required=True, help="Serial port name (e.g., COM1 or /dev/ttyUSB0)")
    parser.add_argument("-b", "--baudrate", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("-w", "--wordlist", required=False, default="wordlist.txt", help="Wordlist (e.g., rockyou.txt)")
    parser.add_argument("-t", "--hashlist", required=False, default="hashlist.txt", help="File containing list of hashes")

    args = parser.parse_args()

    orch = Orchestrator(args.port, args.baudrate, proto_spec, args.wordlist, args.hashlist)
    orch.ruuuuuunnn([2])

if __name__ == "__main__":
    main()
