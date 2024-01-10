import os
import sys
import atheris

with atheris.instrument_imports():
    import torch

import torch

@atheris.instrument_func
def TestOneInput():
	try:
		model = torch.load(sys.argv[-1])

	except SyntaxError as e:
		pass


if __name__ == '__main__':
	atheris.Run(TestOneInput)
