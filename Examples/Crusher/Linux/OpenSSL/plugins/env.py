"""
Environment plugin - delete core dumps
"""

import json
import os
import random
from pathlib import Path

work_dir = None

# auxiliary functions
def clean():
    for f in work_dir.iterdir():
        # print(f'{str(f)}')
        if f.name[:5] == 'core.':
            print(f'delete {f}')
            os.remove(str(f))

# necessary functions
def init(json_options):
    global work_dir
    work_dir = Path(__file__).absolute().parent.parent
    clean()
    return True

def setup():
    if random.randint(0, 1000) == 0: clean()
    return True

def teardown():
    return True

def finish():
    clean()
    write_log("FINISH")
    return True

def write_log(message):
    return True

def get_error():
    return "error"
