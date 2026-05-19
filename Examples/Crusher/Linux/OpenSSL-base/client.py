import sys
import socket
import fcntl
import os
import errno
import traceback
from time import sleep
import argparse
import os

if __name__ == '__main__':
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.connect(("127.0.0.1", 2000))
    fcntl.fcntl(s, fcntl.F_SETFL, os.O_NONBLOCK)

    f = open(sys.argv[1], "rb")
    data = f.read()
    f.close()

    s.send(data)
    s.close()
