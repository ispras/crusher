"""
Simple mutator for just duplicate data
"""


class DuplicateMutator:
    def __init__(self, init=None):
        if not init is None:
            self.init = True
        else:
            self.init = False

    def perform_mutation(self, data=None):
        if self.init:
            self.init = False
            return 42

        return data * 2


def initialization():
    info_mut_alg = {"mut_name": 'duplicate_mutator', "class": "DuplicateMutator", "method": "perform_mutation"}
    return info_mut_alg
