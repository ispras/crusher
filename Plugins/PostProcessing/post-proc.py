"""
Simple post-processing script for just add header
"""


class PostProcess:
    def __init__(self):
        self.data = None

    def post_processing(self, data=None):
        if data is None:
            return 42

        return bytearray('HEADER\n') + data


def initialization():
    return PostProcess
