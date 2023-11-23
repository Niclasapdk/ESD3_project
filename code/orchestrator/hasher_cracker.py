#!/usr/bin/env python3
import serial
import argparse
import struct
import logging

BR_PKT_LEN = 5
BR_DATA_IDX = 3
BR_ADDR_IDX = 2
BR_ACTION_IDX = 1
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
    def __init__(self, port: str, baudrate: int, proto_spec: dict, wordlist: str, hashlist: str, ceiling: int, nodes: list):
        self.noserial = True if port == "/dev/null" else False
        if not self.noserial:
            self.serial = serial.Serial(port, baudrate=baudrate, timeout=0.5)
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
            disc = self.serial.read(size=self.serial.out_waiting) # silencio? ;>
            if len(disc) != 0:
                logging.debug(f"Discarding output buffer: {disc}")
            txpkt = self.prep_pkt(self.proto_spec["read"], str(node_addr).encode(), b"\xff")
            self.serial.write(txpkt)
            self.serial.read_until(self.proto_spec["start"])
            pkt = self.proto_spec["start"] + self.serial.read_until(self.proto_spec["stop"])
            if len(pkt) == BR_PKT_LEN:
                if self.cmp_byte_with_data(pkt[BR_ADDR_IDX], node_addr) and self.cmp_byte_with_data(pkt[BR_ACTION_IDX], self.proto_spec["slave"]):
                    data = pkt[BR_DATA_IDX]
                    logging.debug(f"recv from {node_addr} data {hex(data)}")
            return data
        else:
            return None

    def sha256_pad(self, passwd: bytes):
        l = 8*len(passwd)
        k = (512-64-8-l)
        k_bytes = k//8
        return passwd + b"\x80" + b"\x00"*k_bytes + struct.pack(">Q", l)

    def fuck(self, dm="Youuusa make big dooo doo this time"):
        logging.critical(dm)
        exit(-69)

    def cmp_byte_with_data(self, x, y):
        if isinstance(x, bytes):
            x = ord(x)
        if isinstance(y, bytes):
            y = ord(y)
        return x == y

    def escape_passwd(self, passwd: bytes):
        passwd = passwd.replace(self.proto_spec["dle"], self.proto_spec["dle"] + self.proto_spec["dle"])
        passwd = passwd.replace(self.proto_spec["stx"], self.proto_spec["dle"] + self.proto_spec["stx"])
        passwd = passwd.replace(self.proto_spec["etx"], self.proto_spec["dle"] + self.proto_spec["etx"])
        return passwd

    def schick_passwort(self, node_addr: int, passwd: bytes, salz: bytes):
        if len(passwd) > 39 or len(salz) != 16:
            logging.error("Too long password oder du hasst salz")
            return
        padded_passwd = self.sha256_pad(passwd+salz)
        passwd_pkt = self.proto_spec["stx"] + self.escape_passwd(padded_passwd) + self.proto_spec["etx"]
        logging.info(f"Sending password packet: {passwd_pkt.hex()} to node {node_addr}")
        self.send_to_node(node_addr, passwd_pkt)

    def check_flags_and_find_ready_node(self):
        ready_node = None
        while not ready_node:
            for node in self.nodes:
                data = self.read_from_node(node)
                if data != None:
                    if data & FLAGS_MASK == FLAGS_IDENTIFIER:
                        logging.debug(f"Flags from node {node}: ready for passwd:{data&READY_FOR_PASSWD_MASK!=0}")
                        if data & READY_FOR_PASSWD_MASK:
                            logging.debug(f"Node {node} is ready for new password")
                            ready_node = node
                    elif self.cmp_byte_with_data(data, self.proto_spec["stx"]):
                        self.receive_passwd(node)
        return ready_node

    def receive_passwd(self, node_addr: int):
        if self.noserial:
            return None

        passwd = b""
        data = self.read_from_node(node_addr)
        while not self.cmp_byte_with_data(data, self.proto_spec["etx"]):
            if self.cmp_byte_with_data(data, 0x80) or data is None:
                self.fuck("pls reset fpga cuz it's acting up")
            passwd += bytes([data])
            data = self.read_from_node(node_addr)
        passwd = passwd[:-16] # Remove salt from received passwd
        logging.info(f"\033[92m\U0001F9a7Password found: {passwd.decode()}\033[0m")
        return passwd

    def ruuuuuunnn(self):
        for salz in self.salts:
            for p in self.wordlist:
                logging.info(f"Password candidate: {p.decode()}")
                node = self.check_flags_and_find_ready_node()
                self.schick_passwort(node, p, salz)

def main():
    parser = argparse.ArgumentParser(description="PlusBUS Inc. hasher cracker orchestrator 9000")
    parser.add_argument("-p", "--port", required=True, help="Serial port name (e.g., COM1 or /dev/ttyUSB0)")
    parser.add_argument("-b", "--baudrate", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("-w", "--wordlist", required=False, default="wordlist.txt", help="Wordlist (e.g., rockyou.txt)")
    parser.add_argument("-t", "--hashlist", required=False, default="hashlist.txt", help="File containing list of hashes")
    parser.add_argument("-l", "--loglevel", help="log level", required=False, choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], default='INFO')
    parser.add_argument("-c", "--ceiling", help="txQueue wait ceiling in bytes (default: 10)", default=10, type=int)
    parser.add_argument("-a", "--addrs", nargs="*", help="Slave addresses (default: 2)", default=[2], type=int)

    args = parser.parse_args()

    logging.basicConfig(level=args.loglevel)
    orch = Orchestrator(args.port, args.baudrate, proto_spec, args.wordlist, args.hashlist, args.ceiling, args.addrs)
    orch.ruuuuuunnn()
    #while True:
        #for node in args.addrs:
            #orch.read_from_node(node)

if __name__ == "__main__":
    main()
