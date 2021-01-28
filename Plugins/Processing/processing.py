"""
Simple post-processing script for just add header
"""

class Processing:
    def __init__(self):
        self.open_processing = bytearray("[processing]")
        self.close_processing = bytearray("[/processing]")

    def pre_processing(self, data=None):
        if data is None:
            return 42
        data.replace(self.open_processing, "")
        data.replace(self.close_processing, "")
        return data

    def post_processing(self, data=None):
        if data is None:
            return 42
        data_end = self.open_processing + bytearray(data) + self.close_processing
        return data_end


def initialization():
    return Processing