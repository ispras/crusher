"""
Network features
"""

import socket
import time


class PyNetwork(object):
    def __init__(self, ip, port, delay):
        self.ip = ip
        self.port = port
        self.delay = float(delay) / 1000

        self.sock = None
        self.setup_listener()

    def setup_listener(self):
        # Create socket
        if self.sock is not None:
            self.sock.close()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

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
                    print("Failed 'setup_listener'!")
                    exit(1)

        # Listen
        start = int(round(time.time() * 1000))
        while True:
            try:
                self.sock.listen(1)
                break
            except socket.error as exc:
                if int(round(time.time() * 1000)) - start >= self.delay:
                    print("Failed listening: %s" % str(exc))
                    self.sock.close()
                    print("Failed 'setup_listener'!")
                    exit(1)
        print("Setup listener COMPLETE")

    def send_data(self, data=None):
        if data is None:
            return 42

        tries = 8
        max_recv_buf_size = 1024

        # Accept connection
        self.sock.settimeout(self.delay)
        start = int(round(time.time() * 1000))
        for i in range(tries):
            try:
                conn, addr = self.sock.accept()
                break
            except Exception as exc:
                if int(round(time.time() * 1000)) - start >= self.delay:
                    print('Cannot accept connection: %s' % str(exc))
                    self.sock.close()
                    return False
        # Receive packet
        try:
            recv_data = conn.recv(max_recv_buf_size)
            if not recv_data:
                return False
        except Exception as exc:
            print("Exception receive packet: %s" % str(exc))
            return False
        self.sock.settimeout(None)

        # Send data
        try:
            conn.send(data)
        except Exception as exc:
            print("Exception send packet: %s" % str(exc))
            self.sock.close()
            return False

        # Close connection
        conn.close()

        return True


def initialization():
    return PyNetwork
