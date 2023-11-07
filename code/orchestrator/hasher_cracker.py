import serial
import argparse

proto_spec = {
        "start": b"A",
        "stop":  b"B",
        "read":  b"R",
        "write": b"W"
        }

class Orchestrator:
    def __init__(self, port: str, baudrate: int, proto_spec: dict, wordlist: str):
        self.serial = serial.Serial(port, baudrate=baudrate)
        self.proto_spec = proto_spec
        self.wordlist = self.read_wordlist(wordlist)
        self.prep_pkt()

    def read_wordlist(self, wordlist):
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
            self.pkt[self.data_idx] = chr(b).encode()
            self.pkt[self.addr_idx] = f"{node_addr}".encode()
            self.serial.write(b"".join(self.pkt))

def main():
    parser = argparse.ArgumentParser(description="PlusBUS Inc. hasher cracker orchestrator 9000")
    parser.add_argument("-p", "--port", required=True, help="Serial port name (e.g., COM1 or /dev/ttyUSB0)")
    parser.add_argument("-b", "--baudrate", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("-w", "--wordlist", required=False, default="/etc/passwd", help="Wordlist (e.g., rockyou.txt)")

    args = parser.parse_args()

    orch = Orchestrator(args.port, args.baudrate, proto_spec, args.wordlist)
    orch.send_to_node(2, b"HLO")

if __name__ == "__main__":
    main()
