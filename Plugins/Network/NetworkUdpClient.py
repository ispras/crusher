"""
Network features
"""

import socket
import time


class PyNetwork(object):
    def __init__(self, ip, port, delay):
        self.ip = ip
        self.port = port
        self.delay = delay
        self.sock = None
        self.setup_listener()

    def setup_listener(self):
        # Create socket
        if self.sock is not None:
            self.sock.close()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        # Set socket options
        try:
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        except socket.error as exc:
            self.sock.close()
            print("Failed set socket options: %s" % str(exc))
            print("Failed 'setup_listener'!")
            exit(1)

        # Bind
        start = int(round(time.time() * 1000))
        while True:
            try:
                self.sock.bind((self.ip, self.port))
                break
            except socket.error as exc:
                if int(round(time.time() * 1000)) - start >= self.delay:
                    self.sock.close()
                    print("Failed binding: %s" % str(exc))
                    print("Failed 'setup_listener'!")
                    exit(1)
        print("Setup listener COMPLETE")

    def send_data(self, data=None):
        if data is None:
            return 42

        max_recv_buf_size = 1024

        # Receive packet
        self.sock.settimeout(self.delay)
        try:
            recv_data, addr = self.sock.recvfrom(max_recv_buf_size)
        except Exception as exc:
            print("Exception receive packet: %s" % exc)
            return False
        self.sock.settimeout(None)

        # Read data from file and send
        try:
            self.sock.sendto(data, addr)
        except Exception as exc:
            print("Exception send packet: %s" % str(exc))
            return False
        return True


def initialization():
    return PyNetwork
