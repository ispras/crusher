#!/usr/bin/env python3

import functools
import os

from qiling import Qiling
from qiling.const import QL_VERBOSE
from qiling.os.posix import stat

from crusher_qiling import QilingInstrumentation, read_path_arguments


class MyPipe:
    """Fake stdin to handle incoming fuzzed keystrokes."""

    def __init__(self):
        self.buf = b""

    def write(self, s: bytes):
        self.buf += s

    def read(self, size: int) -> bytes:
        ret = self.buf[:size]
        self.buf = self.buf[size:]

        return ret

    def fileno(self) -> int:
        return 0

    def show(self):
        pass

    def clear(self):
        pass

    def flush(self):
        pass

    def close(self):
        self.outpipe.close()

    def lseek(self, offset: int, origin: int):
        pass

    def fstat(self):
        return stat.Fstat(self.fileno())


def place_input_callback(instrumentation: QilingInstrumentation, stdin_mock: MyPipe):
    """Called with every newly generated input."""
    stdin_mock.write(instrumentation.cur_input)


stdin_mock = MyPipe()

ql = Qiling(
    ["./x8664_fuzz"],
    "./rootfs",
    verbose=QL_VERBOSE.OFF,  # keep qiling logging off
    console=False,  # thwart program output
    stdin=stdin_mock,  # redirect stdin to our fake one
    stdout=None,
    stderr=None,
)

args = read_path_arguments()
instrumentation = QilingInstrumentation(args.input_path, [ql.os.exit_point], args.lighthouse)

# get image base address
ba = ql.loader.images[0].base

# make process crash whenever __stack_chk_fail@plt is about to be called.
# this way afl will count stack protection violations as crashes
ql.hook_address(callback=lambda x: os.abort(), address=ba + 0x1225)

# set a hook on main() to let unicorn fork and start instrumentation
ql.hook_address(callback=instrumentation.start_fuzzing_hook, address=ba + 0x122C)

instrumentation.set_input_callback(functools.partial(place_input_callback, stdin_mock=stdin_mock))

# okay, ready to roll
instrumentation.run(ql)
