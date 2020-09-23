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

    def send_data(self, data=None):
        if data is None:
            return 42
        tries = 8
        # Create socket
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        except Exception as exc:
            print("Exception create socket: " + str(exc))
            return False

        # Set socket options
        try:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        except socket.error as exc:
            sock.close()
            print("Failed set socket options: " + str(exc))
            print("Failed 'send_data'!")
            return False
        # Connect
        sock.settimeout(self.delay)
        start = int(round(time.time() * 1000))
        while True:
            try:
                sock.connect((self.ip, self.port))
                break
            except Exception as exc:
                if int(round(time.time() * 1000)) - start >= self.delay:
                    print("Exception connect socket: %s" % str(exc))
                    return False
        sock.settimeout(None)

        # Read data from file and send
        try:
            sock.send(data)
        except Exception as exc:
            print("Exception send packet: " + str(exc))
            return False

        # Close socket
        try:
            sock.close()
        except socket.error as exc:
            print("Exception close socket: " + str(exc))
            return False
        return True


def initialization():
    return PyNetwork
