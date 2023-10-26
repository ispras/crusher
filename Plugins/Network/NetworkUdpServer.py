"""
Network features
"""

import socket
import time


class PyNetwork(object):
    def __init__(self, ip, port, delay):
        self.ip = ip
        self.port = port
        self.delay = delay  # milliseconds

    def send_data(self, data=None, delay=None):
        if data is None:
            return 42

        self.delay = delay

        time.sleep(float(self.delay) / 1000)
        # Create socket
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        except Exception as exc:
            print("Exception create socket: %s" % str(exc))
            return False

        # Set socket options
        try:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            sock.connect((self.ip, self.port))
        except socket.error as exc:
            sock.close()
            print("Failed set socket options: %s" % str(exc))
            print("Failed 'send_data'!")
            return False
        try:
            sock.sendall(data)
        except Exception as exc:
            print("Exception send packet: %s" % exc)
            return False

        # Close socket
        try:
            sock.close()
        except socket.error as exc:
            sock = None
            print("Exception close socket: %s" % str(exc))
            return False
        return True


def initialization():
    return PyNetwork
