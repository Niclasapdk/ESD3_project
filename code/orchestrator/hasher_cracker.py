#!/usr/bin/env python3
import serial
import argparse
import struct

BR_PKT_LEN = 5
BR_DATA_IDX = 3
FLAGS_MASK = 0xc0
FLAGS_IDENTIFIER = 0x80
READY_FOR_PASSWD_MASK = 0x20

proto_spec = {
        # L2
        "start": b"A",
        "stop":  b"Z",
        # Action signals: Orchestrator -> Bridge
        "read":  b"R",
        "write": b"W",
        # Action signals: Bridge -> Orchestrator
        "bridge": b"B", # bridge data
        "slave": b"S", # slave data

        # L3
        "stx":   b"\x02",
        "etx":   b"\x03",
        "dle":   b"\x10"
        }

class Orchestrator:
    def __init__(self, port: str, baudrate: int, proto_spec: dict, wordlist: str, hashlist: str, verbose: bool, ceiling: int, nodes: list):
        self.verbose = True if verbose else False #Because python doesn't like types :((
        self.noserial = True if port == "/dev/null" else False
        if not self.noserial:
            self.serial = serial.Serial(port, baudrate=baudrate, timeout=0.05)
        self.proto_spec = proto_spec
        self.wordlist = self.read_wordlist(wordlist)
        self.hashlist = self.read_hashlist(hashlist)
        self.salts = [b"abcdefghjiklmnop"]
        self.txQueueCeiling = ceiling
        self.nodes = nodes

    def read_hashlist(self, hashlist: str):
        # TODO: parse hashlist
        with open(hashlist, "r") as f:
            return list(map(lambda x: x.strip().encode(), f.readlines()))

    def read_wordlist(self, wordlist: str):
        with open(wordlist, "r") as f:
            return list(map(lambda x: x.strip().encode(), f.readlines()))

    # Prepares a packet for the bridge
    # action: example self.proto_spec['write']
    # addr: byte string of 1-digit addr. Example b"2"
    # data: byte string of 1 byte. Example b"A"
    def prep_pkt(self, action: bytes, addr: bytes, data: bytes):
        return self.proto_spec["start"] + action + addr + data + self.proto_spec["stop"]

    def txQueueMsgsWaiting(self):
        if self.noserial:
            return 0
        data = self.serial.readline().decode().strip().split(": ")
        if data[0] == "txMsgsWaiting":
            return int(data[1])
        else:
            return 10**9

    def send_to_node(self, node_addr: int, data: bytes):
        for b in data:
            if not self.noserial:
                self.serial.write(self.prep_pkt(self.proto_spec["write"], str(node_addr).encode(), bytes([b])))
            else:
                pass

    def read_from_node(self, node_addr):
        if not self.noserial:
            data = None
            self.serial.write(self.prep_pkt(self.proto_spec["read"], str(node_addr).encode(), b"\xff"))
            self.serial.read_until(self.proto_spec["start"])
            pkt = self.proto_spec["start"] + self.serial.read_until(self.proto_spec["stop"])
            if len(pkt) == BR_PKT_LEN:
                data = pkt[BR_DATA_IDX]
            else:
                return None
            print(data)
            return data
        else:
            return None

    def sha256_pad(self, passwd: bytes):
        l = 8*len(passwd)
        k = (512-64-8-l)
        k_bytes = k//8
        return passwd + b"\x80" + b"\x00"*k_bytes + struct.pack(">Q", l)

    def fuck(self, dm="Youuusa make big dooo doo this time"):
        print(dm)
        self.fuckfuckfuck()

    def escape_passwd(self, passwd: bytes):
        passwd = passwd.replace(self.proto_spec["dle"], self.proto_spec["dle"] + self.proto_spec["dle"])
        passwd = passwd.replace(self.proto_spec["stx"], self.proto_spec["dle"] + self.proto_spec["stx"])
        passwd = passwd.replace(self.proto_spec["etx"], self.proto_spec["dle"] + self.proto_spec["etx"])
        return passwd

    def schick_passwort(self, node_addr: int, passwd: bytes, salz: bytes):
        if len(passwd) > 39 or len(salz) != 16:
            print("Too long password oder du hasst salz")
            self.fuck()
            return
        padded_passwd = self.sha256_pad(passwd+salz)
        passwd_pkt = self.proto_spec["stx"] + self.escape_passwd(padded_passwd) + self.proto_spec["etx"]
        if self.verbose:
            print(f"Sending password packet: {passwd_pkt.hex()} to node {node_addr}")
        self.send_to_node(node_addr, passwd_pkt)

    def check_flags_and_find_ready_node(self):
        ready_node = None
        while not ready_node:
            for node in self.nodes:
                data = self.read_from_node(node)
                if data != None:
                    if data & FLAGS_MASK == FLAGS_IDENTIFIER:
                        if data & READY_FOR_PASSWD_MASK:
                            ready_node = node
                    elif data == self.proto_spec["stx"]:
                        self.receive_passwd(node)
        return ready_node

    def receive_passwd(self, node_addr: int):
        if self.noserial:
            return None

        passwd = b""
        data = self.read_from_node(node_addr)
        while data != self.proto_spec["etx"]:
            passwd += data
            data = self.read_from_node(node_addr)
        print(f"Password found: {passwd}")
        return passwd

    def ruuuuuunnn(self):
        for salz in self.salts:
            for i, p in enumerate(self.wordlist):
                node = self.check_flags_and_find_ready_node()
                self.schick_passwort(node, p, salz)

def main():
    parser = argparse.ArgumentParser(description="PlusBUS Inc. hasher cracker orchestrator 9000")
    parser.add_argument("-p", "--port", required=True, help="Serial port name (e.g., COM1 or /dev/ttyUSB0)")
    parser.add_argument("-b", "--baudrate", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("-w", "--wordlist", required=False, default="wordlist.txt", help="Wordlist (e.g., rockyou.txt)")
    parser.add_argument("-t", "--hashlist", required=False, default="hashlist.txt", help="File containing list of hashes")
    parser.add_argument("-v", "--verbose", help="verbose mode", action="store_true")
    parser.add_argument("-c", "--ceiling", help="txQueue wait ceiling in bytes (default: 10)", default=10, type=int)
    parser.add_argument("-a", "--addrs", nargs="*", help="Slave addresses (default: 2)", default=[2], type=int)

    args = parser.parse_args()

    orch = Orchestrator(args.port, args.baudrate, proto_spec, args.wordlist, args.hashlist, args.verbose, args.ceiling, args.addrs)
    orch.ruuuuuunnn()

if __name__ == "__main__":
    main()
