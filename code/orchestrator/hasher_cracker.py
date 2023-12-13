#!/usr/bin/env python3
import serial
import argparse
import struct
import logging
from time import time, sleep
from datetime import datetime

BR_PKT_LEN = 5
BR_DATA_IDX = 3
BR_ADDR_IDX = 2
BR_ACTION_IDX = 1
FLAGS_MASK = 0xc0
FLAGS_IDENTIFIER = 0x80
READY_FOR_PASSWD_MASK = 0x20

proto_spec = {
        # Bridge protocol
        "start": b"A",
        "stop":  b"Z",
        "read":  b"R",
        "write": b"W",
        "slave": b"S",

        # PlusBUS protocol
        "stx":   b"\x02",
        "hsh":   b"\x1a",
        "rds":   b"\x07",
        "etx":   b"\x03",
        "dle":   b"\x10",
        "rst":   b"\x11",
        "nop":   b"\x12",
        }

def panic(dm="Youuusa make big fuck up"):
    logging.critical(dm)
    exit(-69)

class Orchestrator:
    def __init__(self, port: str, baudrate: int, proto_spec: dict, wordlist: str, hashlist: str, nodes: list):
        self.noserial = True if port == "/dev/null" else False
        if not self.noserial:
            self.serial = serial.Serial(port, baudrate=baudrate, timeout=0.5)
        self.proto_spec = proto_spec
        self.passwds = self.read_wordlist(wordlist)
        self.hashes = self.read_hashlist(hashlist)
        self.salts = [b"abcdefghjiklmnop"]
        self.nodes = nodes

    def reset_nodes(self):
        for node in self.nodes:
            logging.info(f"Resetting node {node}")
            self.send_to_node(node, self.proto_spec["rst"])
            self.send_to_node(node, self.proto_spec["nop"])

    def setup_nodes(self, rounds, hash):
        self.reset_nodes()
        for node in self.nodes:
            self.send_hash(node, hash)
            self.send_rounds(node, rounds)

    def read_hashlist(self, hashlist: str):
        with open(hashlist, "r") as f:
            return list(map(lambda x: (int(x.split("$")[0]), bytes.fromhex(x.split("$")[1].strip())), f.readlines()))

    def read_wordlist(self, wordlist: str):
        with open(wordlist, "r") as f:
            return list(map(lambda x: x.strip().encode(), f.readlines()))

    # Prepares a packet for the bridge
    # action: example self.proto_spec['write']
    # addr: byte string of 1-digit addr. Example b"2"
    # data: byte string of 1 byte. Example b"A"
    def prep_pkt(self, action: bytes, addr: bytes, data: bytes):
        return self.proto_spec["start"] + action + addr + data + self.proto_spec["stop"]

    def send_to_node(self, node_addr: int, data: bytes):
        for b in data:
            if not self.noserial:
                self.serial.write(self.prep_pkt(self.proto_spec["write"], str(node_addr).encode(), bytes([b])))
            else:
                pass

    # Will return None if no data is received
    def read_from_node(self, node_addr):
        if not self.noserial:
            data = None
            disc = self.serial.read(size=self.serial.out_waiting) # silencio?
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

    def cmp_byte_with_data(self, x, y):
        if isinstance(x, bytes):
            x = ord(x)
        if isinstance(y, bytes):
            y = ord(y)
        return x == y

    def escape_plusbus(self, data: bytes):
        data = data.replace(self.proto_spec["dle"], self.proto_spec["dle"] + self.proto_spec["dle"])
        data = data.replace(self.proto_spec["stx"], self.proto_spec["dle"] + self.proto_spec["stx"])
        data = data.replace(self.proto_spec["etx"], self.proto_spec["dle"] + self.proto_spec["etx"])
        data = data.replace(self.proto_spec["hsh"], self.proto_spec["dle"] + self.proto_spec["hsh"])
        data = data.replace(self.proto_spec["rds"], self.proto_spec["dle"] + self.proto_spec["rds"])
        data = data.replace(self.proto_spec["rst"], self.proto_spec["dle"] + self.proto_spec["rst"])
        return data

    def send_passwd(self, node_addr: int, passwd: bytes, salz: bytes):
        if len(passwd) > 39 or len(salz) != 16:
            logging.error("Too long password oder du hasst salz")
            return
        padded_passwd = self.sha256_pad(passwd+salz)
        passwd_pkt = self.proto_spec["stx"] + self.escape_plusbus(padded_passwd) + self.proto_spec["etx"]
        logging.info(f"Trying salted passwd: {padded_passwd}, {len(padded_passwd)}")
        logging.info(f"Sending password packet: {passwd_pkt.hex()} to node {node_addr}")
        self.send_to_node(node_addr, passwd_pkt)

    def send_hash(self, node_addr: int, hash: bytes):
        pkt = self.proto_spec["hsh"] + self.escape_plusbus(hash) + self.proto_spec["etx"]
        logging.info(f"Sending hash packet: {pkt.hex()} to node {node_addr}")
        self.send_to_node(node_addr, pkt)

    def send_rounds(self, node_addr: int, rounds: int):
        pkt = self.proto_spec["rds"] + self.escape_plusbus(rounds.to_bytes(4, "little")) + self.proto_spec["etx"]
        logging.info(f"Sending rounds packet: {pkt.hex()} to node {node_addr}")
        self.send_to_node(node_addr, pkt)

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
                        return -1
        return ready_node

    def wait_for_nodes(self, t):
        logging.info(f"Waiting {t} s for nodes to finish")
        tstart = time()
        while time() - tstart < t:
            sleep(0.1)
            for node in self.nodes:
                if self.receive_passwd(node) is not None:
                    return

    def receive_passwd(self, node_addr: int):
        if self.noserial:
            return None

        passwd = b""
        data = self.read_from_node(node_addr)
        while not self.cmp_byte_with_data(data, self.proto_spec["etx"]):
            if data is None:
                continue
            if data < 0x20 or data > 0x7f:
                return None
            if self.cmp_byte_with_data(data, 0x80) or data is None:
                panic("pls reset fpga cuz it's acting up")
            passwd += bytes([data])
            data = self.read_from_node(node_addr)
        passwd = passwd[:-16] # Remove salt from received passwd
        logging.info(f"\033[92m\U0001F9a7Password found: {passwd.decode()}\033[0m") #]]
        return passwd

    def run(self):
        for hash in self.hashes:
            (rounds, hashbytes) = hash
            passwd_found = False
            logging.info(f"Cracking hash: {hashbytes.hex()}")
            self.setup_nodes(rounds, hashbytes)
            for salz in self.salts:
                if passwd_found == True:
                    break
                for p in self.passwds:
                    logging.info(f"Password candidate: {p.decode()}")
                    node = self.check_flags_and_find_ready_node()
                    if node == -1:
                        passwd_found = True
                        break
                    self.send_passwd(node, p, salz)
                if not passwd_found:
                    self.wait_for_nodes(round(rounds * 4e-6, 2))

    def print_perftest_results(self, rounds, t_start, t_stop):
        logging.info(f"Performance test finished")
        t_diff = t_stop-t_start
        print(f"Start time: {t_start} s")
        print(f"Stop time: {t_stop} s")
        print(f"Time difference: {t_diff} s")
        f = rounds/t_diff
        print(f"Hash frequency: {round(f/1e3, 3)} KH/s")

    def perftest(self):
        passwd = b"NiclasErSej"
        #rounds = 100000000
        #hash = bytes.fromhex("6c34143607d27f4317536f81ad96b341bfa7203761231b4a7912a478aa13083b")
        #rounds = 1000000
        #hash = bytes.fromhex("f0b8e974674b8011bc99b0a3b23fe9af547214a2648827dfc77cb787c5418ae7")
        rounds = 1000000000
        hash = bytes.fromhex("856343c8a1a4ffcba38a758a0a4bcdcef7549d20864da8dbb44c0508a1d5d5b7")

        self.passwds = [passwd]
        self.hashes = [(rounds, hash)]
        logging.info(f"Running single-core performance test with {rounds:e} iterations")
        print("Performance test results")
        print(f"Date/Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("Cores: 1")
        print(f"Iterations: {rounds:e}")
        print(f"Hash: {hash.hex()}")
        print(f"Passwd: {passwd.decode()}")
        print(f"Salt: {self.salts[0].decode()}")
        t_start = time()
        self.run()
        t_stop = time()
        self.print_perftest_results(rounds, t_start, t_stop)

def main():
    parser = argparse.ArgumentParser(description="PlusBUS Inc. hasher cracker orchestrator 9000")
    parser.add_argument("-p", "--port", required=True, help="Serial port name (e.g., COM1 or /dev/ttyUSB0)")
    parser.add_argument("-b", "--baudrate", type=int, default=1500000, help="Baud rate (default: 1500000)")
    parser.add_argument("-w", "--wordlist", required=False, default="wordlist.txt", help="Wordlist (e.g., rockyou.txt)")
    parser.add_argument("-t", "--hashlist", required=False, default="hashlist.txt", help="File containing list of hashes")
    parser.add_argument("-l", "--loglevel", help="log level", required=False, choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], default='INFO')
    parser.add_argument("-a", "--addrs", nargs="*", help="Slave addresses (default: 2)", default=[2], type=int)
    parser.add_argument("--perf-test", help="Run performance test", action="store_const", dest="perftest", const=True)

    args = parser.parse_args()

    logging.basicConfig(level=args.loglevel)
    orch = Orchestrator(args.port, args.baudrate, proto_spec, args.wordlist, args.hashlist, args.addrs)
    if args.perftest:
        orch.perftest()
    else:
        orch.run()

if __name__ == "__main__":
    main()
