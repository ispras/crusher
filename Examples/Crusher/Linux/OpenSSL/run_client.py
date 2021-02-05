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
    parser = argparse.ArgumentParser(description="Sender")
    parser.add_argument("--ip", "-i", dest="ip", help="ip", required=True)
    parser.add_argument("--port", "-p", dest="port", help="port", required=True)
    parser.add_argument("--crash-path", "-c", dest="crash_path", help="crash file path", required=True)
    args = parser.parse_known_args(sys.argv)
    args = args[0]

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.connect((args.ip, int(args.port)))
    fcntl.fcntl(s, fcntl.F_SETFL, os.O_NONBLOCK)

    if not os.path.exists(args.crash_path):
        print("Path to crash file is incorrect")
    f = open(args.crash_path, "rb")
    data = f.read()
    f.close()

    s.send(data)
    s.close()
